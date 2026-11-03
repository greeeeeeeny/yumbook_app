from datetime import datetime

from django.db.models import Q
from rest_framework import exceptions, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.response import Response

from reservations.authentication import SupabaseAuthentication

from .models import (
    AdminRestaurantExceptionDay,
    AdminRestaurantMeta,
    AdminRestaurantSeatInventory,
    AdminRestaurantSeatType,
    Region,
    Restaurant,
)
from .serializers import RegionSerializer, RestaurantSerializer

# 관리자 CMS(yumbook_admin) 노출 상태 필터.
# admin_restaurant_meta row 가 없거나 status == "active" 인 식당만
# 사용자 앱 목록/검색/상세에 노출한다. draft/inactive/archived 는 숨김.
ADMIN_VISIBLE_Q = Q(admin_meta__isnull=True) | Q(
    admin_meta__status=AdminRestaurantMeta.STATUS_ACTIVE
)

# Explore 화면 정렬 허용값. 그 외 값은 무시하고 기본 정렬(name) 사용.
ALLOWED_ORDERING = {
    "rating",
    "-rating",
    "created_at",
    "-created_at",
    "name",
    "-name",
}


def _parse_int_param(params, key):
    """정수 쿼리 파라미터 파싱. 값이 없으면 None, 잘못된 값이면 400."""
    raw = params.get(key)
    if raw is None or raw == "":
        return None
    try:
        return int(raw)
    except (TypeError, ValueError):
        raise exceptions.ValidationError({key: f"{key} must be an integer."})


def _parse_bbox(raw):
    """'min_lng,min_lat,max_lng,max_lat' → (min_lng, min_lat, max_lng, max_lat). 잘못되면 400."""
    parts = [p.strip() for p in raw.split(",")]
    if len(parts) != 4:
        raise exceptions.ValidationError(
            {"bbox": "bbox must be 'min_lng,min_lat,max_lng,max_lat'."}
        )
    try:
        min_lng, min_lat, max_lng, max_lat = (float(p) for p in parts)
    except ValueError:
        raise exceptions.ValidationError({"bbox": "bbox values must be numbers."})

    if min_lng > max_lng or min_lat > max_lat:
        raise exceptions.ValidationError(
            {"bbox": "bbox min values must not exceed max values."}
        )
    if not (-180 <= min_lng <= 180 and -180 <= max_lng <= 180):
        raise exceptions.ValidationError({"bbox": "longitude must be within [-180, 180]."})
    if not (-90 <= min_lat <= 90 and -90 <= max_lat <= 90):
        raise exceptions.ValidationError({"bbox": "latitude must be within [-90, 90]."})

    return min_lng, min_lat, max_lng, max_lat


class RegionViewSet(viewsets.ReadOnlyModelViewSet):
    # 홈 화면 지역 탭 목록. 활성 지역만 노출(Meta ordering 적용).
    permission_classes = [AllowAny]
    serializer_class = RegionSerializer
    queryset = Region.objects.filter(is_active=True)


class RestaurantViewSet(viewsets.ModelViewSet):
    authentication_classes = [SupabaseAuthentication]
    serializer_class = RestaurantSerializer
    queryset = (
        Restaurant.objects.all()
        .select_related("region", "policy")
        .prefetch_related("images")
    )

    def get_permissions(self):
        if self.action in ("list", "retrieve", "availability"):
            return [AllowAny()]
        return [IsAdminUser()]

    def get_queryset(self):
        queryset = super().get_queryset()

        # 사용자 대상 읽기(목록/검색/상세/가용성)에서는 관리자 CMS 에서
        # 숨긴 식당(draft/inactive/archived)을 제외한다. 관리자 쓰기
        # 액션은 숨긴 식당도 계속 수정할 수 있어야 하므로 필터하지 않는다.
        if self.action in ("list", "retrieve", "availability"):
            queryset = queryset.filter(ADMIN_VISIBLE_Q)

        params = self.request.query_params

        # q: 이름/설명/주소(location)/카테고리 검색
        q = params.get("q")
        if q:
            queryset = queryset.filter(
                Q(name__icontains=q)
                | Q(description__icontains=q)
                | Q(location__icontains=q)
                | Q(raw_category__icontains=q)
            )

        location = params.get("location")
        if location:
            queryset = queryset.filter(location__iexact=location)

        # category: 기존 정확 일치(하위호환 유지)
        category = params.get("category")
        if category:
            queryset = queryset.filter(raw_category__iexact=category)

        # cuisine: raw_category 부분 일치(Flutter parseCuisine이 카테고리 텍스트를 파싱하는 방식과 동일)
        cuisine = params.get("cuisine")
        if cuisine:
            queryset = queryset.filter(raw_category__icontains=cuisine)

        # 홈 화면 지역 탭: /api/restaurants/?region=hongdae (Region.slug 기준)
        region = params.get("region")
        if region:
            queryset = queryset.filter(region__slug__iexact=region)

        # price: 가격 티어(1~4) 정확/범위 필터
        price = _parse_int_param(params, "price")
        if price is not None:
            queryset = queryset.filter(price_level=price)
        min_price = _parse_int_param(params, "min_price")
        if min_price is not None:
            queryset = queryset.filter(price_level__gte=min_price)
        max_price = _parse_int_param(params, "max_price")
        if max_price is not None:
            queryset = queryset.filter(price_level__lte=max_price)

        # bbox: 지도 영역 검색. lat/lng가 없는 식당은 자동 제외(크래시 없음).
        bbox = params.get("bbox")
        if bbox:
            min_lng, min_lat, max_lng, max_lat = _parse_bbox(bbox)
            queryset = queryset.filter(
                lat__isnull=False,
                lng__isnull=False,
                lat__gte=min_lat,
                lat__lte=max_lat,
                lng__gte=min_lng,
                lng__lte=max_lng,
            )

        ordering = params.get("ordering")
        if ordering in ALLOWED_ORDERING:
            queryset = queryset.order_by(ordering)

        return queryset

    @action(detail=True, methods=["get"], url_path="availability")
    def availability(self, request, pk=None):
        """GET /api/restaurants/{id}/availability/?date=YYYY-MM-DD

        yumbook_admin 이 관리하는 좌석 종류/재고/휴무일(admin_* 테이블,
        읽기 전용)을 기준으로 해당 날짜의 예약 가능 정보를 돌려준다.
        재고가 설정되지 않은 슬롯은 목록에 없다(fail-open — 예약 생성은
        허용된다). pending/confirmed 예약만 수량을 소비한다.
        """
        restaurant = self.get_object()
        date_text = request.query_params.get("date") or ""
        try:
            date_value = datetime.strptime(date_text, "%Y-%m-%d").date()
        except ValueError:
            raise exceptions.ValidationError(
                {"date": "date query parameter is required (YYYY-MM-DD)."}
            )

        exception_day = AdminRestaurantExceptionDay.objects.filter(
            restaurant=restaurant, date=date_value
        ).first()
        seat_types = list(
            AdminRestaurantSeatType.objects.filter(
                restaurant=restaurant, is_active=True
            ).order_by("sort_order", "code")
        )

        slots = []
        if not (exception_day and exception_day.is_closed):
            from reservations.availability import CAPACITY_CONSUMING_STATUSES
            from reservations.models import Reservation

            inventory_rows = AdminRestaurantSeatInventory.objects.filter(
                restaurant=restaurant, date=date_value, is_active=True
            ).select_related("seat_type").order_by("time", "seat_type__code")
            for row in inventory_rows:
                booked_qs = Reservation.objects.filter(
                    restaurant=restaurant,
                    date=date_value,
                    seat_type__iexact=row.seat_type.code,
                    status__in=CAPACITY_CONSUMING_STATUSES,
                )
                if row.time is not None:
                    booked_qs = booked_qs.filter(time=row.time)
                booked = booked_qs.count()
                slots.append(
                    {
                        "seat_type": row.seat_type.code,
                        "time": row.time.strftime("%H:%M") if row.time else None,
                        "capacity": row.capacity,
                        "booked": booked,
                        "remaining": max(0, row.capacity - booked),
                    }
                )

        return Response(
            {
                "restaurant_id": restaurant.id,
                "date": date_text,
                "closed": bool(exception_day and exception_day.is_closed),
                "special_hours": (
                    {
                        "open_time": exception_day.open_time.strftime("%H:%M"),
                        "close_time": exception_day.close_time.strftime("%H:%M"),
                    }
                    if exception_day
                    and not exception_day.is_closed
                    and exception_day.open_time
                    and exception_day.close_time
                    else None
                ),
                "seat_types": [
                    {"code": st.code, "name": st.name or st.code} for st in seat_types
                ],
                "slots": slots,
            }
        )
