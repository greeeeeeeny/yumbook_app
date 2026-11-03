"""예약 생성 시 좌석/재고/휴무일 가용성 검증 (Phase 5.1).

데이터 소스는 yumbook_admin 이 소유한 admin_* 테이블의 읽기 전용 매핑
(restaurants.AdminRestaurantSeatType / AdminRestaurantSeatInventory /
AdminRestaurantExceptionDay)이다. 이 모듈은 절대 그 테이블에 쓰지 않는다.

MVP 규칙 (fail-open 정책):
    1. 휴무일: is_closed=True 인 exception day 가 있으면 예약 차단.
       특별 영업시간이면 예약 시간이 open~close 범위 안이어야 한다.
       (재고가 없어도 휴무일은 항상 적용된다.)
    2. 좌석 종류: 해당 식당에 활성 SeatType 이 하나라도 있으면 요청
       seat_type 이 활성 code 와 (대소문자 무시) 일치해야 한다.
       설정된 좌석 종류가 없으면 검사하지 않는다(fail-open — 기존
       식당/과거 free-text 값이 깨지지 않도록).
    3. 재고: (restaurant, seat_type, date, time) 활성 재고 행이 있으면
       capacity 를 강제한다. 정확한 시간 행이 없으면 all-day(time NULL)
       행을 본다. capacity 는 "예약 건수" 기준이며 pending/confirmed 만
       소비한다(cancelled/rejected/completed 는 소비하지 않는다).
       재고 행이 없으면 fail-open.
    4. restaurant FK 가 없는 예약(레거시 external_restaurant_id 흐름)은
       검증하지 않는다(fail-open).

과거 예약은 절대 소급 수정/차단하지 않는다 — 검증은 생성 시점에만 실행.
동시성: 재고 행을 select_for_update() 로 잠근 뒤 카운트한다(호출자는
transaction.atomic 안에서 호출해야 한다; sqlite 에서는 잠금이 무시되고
Postgres 에서 실제 직렬화된다).
"""

from rest_framework import exceptions

from restaurants.models import (
    AdminRestaurantExceptionDay,
    AdminRestaurantSeatInventory,
    AdminRestaurantSeatType,
)

# 좌석 수량을 소비하는 상태. (완료는 과거 방문이므로 소비하지 않음)
CAPACITY_CONSUMING_STATUSES = ("pending", "confirmed")


def _blocked(message):
    return exceptions.ValidationError({"detail": message})


def check_exception_day(restaurant, date, time_value):
    day = AdminRestaurantExceptionDay.objects.filter(
        restaurant=restaurant, date=date
    ).first()
    if day is None:
        return
    if day.is_closed:
        raise _blocked("Restaurant is closed on this date.")
    if day.open_time and day.close_time and time_value is not None:
        if not (day.open_time <= time_value <= day.close_time):
            raise _blocked("Reservation time is outside special opening hours.")


def check_seat_type(restaurant, seat_type):
    """활성 좌석 종류가 설정된 식당이면 code 매칭을 강제한다."""
    active = AdminRestaurantSeatType.objects.filter(
        restaurant=restaurant, is_active=True
    )
    if not active.exists():
        return None  # fail-open: 좌석 종류 미설정 식당
    code = (seat_type or "").strip()
    matched = active.filter(code__iexact=code).first() if code else None
    if matched is None:
        raise _blocked("Invalid seat type for this restaurant.")
    return matched


def check_inventory(restaurant, seat_type_obj, date, time_value, exclude_reservation_id=None):
    """활성 재고 행이 있으면 잠그고 capacity 를 강제한다.

    반드시 transaction.atomic() 안에서 호출할 것 (select_for_update).
    """
    if seat_type_obj is None:
        return None  # 좌석 종류 미설정 → 재고도 검사하지 않음
    base = AdminRestaurantSeatInventory.objects.select_for_update().filter(
        restaurant=restaurant, seat_type=seat_type_obj, date=date, is_active=True
    )
    slot = base.filter(time=time_value).first() if time_value is not None else None
    if slot is None:
        slot = base.filter(time__isnull=True).first()
    if slot is None:
        return None  # fail-open: 재고 미설정 슬롯

    from .models import Reservation

    booked = Reservation.objects.filter(
        restaurant=restaurant,
        date=date,
        seat_type__iexact=seat_type_obj.code,
        status__in=CAPACITY_CONSUMING_STATUSES,
    )
    if slot.time is not None:
        booked = booked.filter(time=slot.time)
    if exclude_reservation_id is not None:
        # 기존 예약 자신은 수량에서 제외한다(수정/변경 승인 시 자기 자신
        # 때문에 만석 판정이 나지 않도록).
        booked = booked.exclude(pk=exclude_reservation_id)
    if booked.count() >= slot.capacity:
        raise _blocked("Selected time slot is fully booked.")
    return slot


def validate_reservation_slot(
    restaurant, date, time_value, seat_type, exclude_reservation_id=None
):
    """예약 생성/수정/변경 승인 전 가용성 검증. 차단 시 ValidationError(400).

    ``exclude_reservation_id`` 는 기존 예약을 새 슬롯으로 옮기거나 필드를
    수정할 때 그 예약 자신을 수량 계산에서 제외하기 위한 값이다.
    transaction.atomic() 안에서 호출해야 재고 잠금이 유효하다.
    """
    if restaurant is None or date is None:
        return  # 레거시(external_restaurant_id) 흐름 — 검증 없음
    check_exception_day(restaurant, date, time_value)
    seat_type_obj = check_seat_type(restaurant, seat_type)
    check_inventory(
        restaurant, seat_type_obj, date, time_value,
        exclude_reservation_id=exclude_reservation_id,
    )
