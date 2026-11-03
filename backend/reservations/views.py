from datetime import datetime

from django.db import transaction
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import status, viewsets
from rest_framework.decorators import (
    action,
    api_view,
    authentication_classes,
    permission_classes,
)
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .authentication import SupabaseAuthentication
from .availability import validate_reservation_slot
from .models import Reservation, ReservationChangeRequest
from .serializers import (
    AuthCredentialsSerializer,
    CancelReservationSerializer,
    ChangeRequestInputSerializer,
    LoginResponseSerializer,
    ReservationSerializer,
    SignupResponseSerializer,
)

# 예약 변경 가능 시한(시간). Flutter canEditReservation(>= 24h)과 동일하게 맞춘다.
CHANGE_WINDOW_HOURS = 24


def reservation_datetime(reservation):
    """예약 날짜+시간을 현재 타임존 기준 aware datetime으로 합친다."""
    return timezone.make_aware(datetime.combine(reservation.date, reservation.time))


def hours_until(reservation):
    delta = reservation_datetime(reservation) - timezone.now()
    return delta.total_seconds() / 3600


class ReservationViewSet(viewsets.ModelViewSet):
    authentication_classes = [SupabaseAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = ReservationSerializer

    def get_queryset(self):
        queryset = Reservation.objects.filter(user=self.request.user.id)
        date = self.request.query_params.get("date")

        if date:
            queryset = queryset.filter(date=date)

        return queryset.order_by("-created_at")

    def perform_create(self, serializer):
        # Phase 5.1: yumbook_admin 이 관리하는 좌석 종류/재고/휴무일을
        # 예약 생성 시점에 강제한다(설정이 없으면 fail-open). 재고 행을
        # 잠근 채 카운트+저장해야 하므로 트랜잭션으로 감싼다.
        data = serializer.validated_data
        with transaction.atomic():
            validate_reservation_slot(
                restaurant=data.get("restaurant"),
                date=data.get("date"),
                time_value=data.get("time"),
                seat_type=data.get("seat_type"),
            )
            serializer.save(user=self.request.user.id)

    # 가용성에 영향을 주는 필드(이 중 하나라도 바뀌면 새 슬롯을 재검증).
    AVAILABILITY_FIELDS = {"restaurant", "date", "time", "party_size", "seat_type"}

    def perform_update(self, serializer):
        # Phase 5.2: 예약 수정(PATCH/PUT)도 생성과 같은 가용성 규칙을
        # 따른다. guest_name 등 비가용성 필드만 바뀌면 검증하지 않고,
        # 수량 계산에서는 자기 자신을 제외한다. 수량을 소비하지 않는
        # 상태(cancelled/rejected/completed)의 예약은 검증하지 않는다.
        instance = serializer.instance
        data = serializer.validated_data
        touches_availability = bool(self.AVAILABILITY_FIELDS & set(data.keys()))
        consuming = instance.status in (
            Reservation.Status.PENDING,
            Reservation.Status.CONFIRMED,
        )
        with transaction.atomic():
            if touches_availability and consuming:
                validate_reservation_slot(
                    restaurant=data.get("restaurant", instance.restaurant),
                    date=data.get("date", instance.date),
                    time_value=data.get("time", instance.time),
                    seat_type=data.get("seat_type", instance.seat_type),
                    exclude_reservation_id=instance.pk,
                )
            serializer.save()

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        reservation = self.get_object()

        if reservation.status in (
            Reservation.Status.CANCELLED,
            Reservation.Status.COMPLETED,
            Reservation.Status.REJECTED,
        ):
            return Response(
                {"detail": f"Cannot cancel a {reservation.status} reservation."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        input_serializer = CancelReservationSerializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)

        reservation.status = Reservation.Status.CANCELLED
        reservation.cancel_reason = input_serializer.validated_data.get("reason", "")
        reservation.save(update_fields=["status", "cancel_reason", "updated_at"])

        return Response(self.get_serializer(reservation).data)

    @action(detail=True, methods=["post"], url_path="request-change")
    def request_change(self, request, pk=None):
        reservation = self.get_object()

        if reservation.status not in (
            Reservation.Status.PENDING,
            Reservation.Status.CONFIRMED,
        ):
            return Response(
                {"detail": f"Cannot change a {reservation.status} reservation."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if reservation.change_requests.filter(
            status=ReservationChangeRequest.Status.PENDING
        ).exists():
            return Response(
                {"detail": "A pending change request already exists."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 백엔드 24시간 규칙 (Flutter canEditReservation과 동일)
        if hours_until(reservation) < CHANGE_WINDOW_HOURS:
            return Response(
                {
                    "detail": (
                        "Reservations can only be changed at least "
                        f"{CHANGE_WINDOW_HOURS} hours in advance."
                    )
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        input_serializer = ChangeRequestInputSerializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)

        ReservationChangeRequest.objects.create(
            reservation=reservation,
            requested_date=input_serializer.validated_data["requested_date"],
            requested_time=input_serializer.validated_data["requested_time"],
            requested_party_size=input_serializer.validated_data[
                "requested_party_size"
            ],
        )

        return Response(
            self.get_serializer(reservation).data, status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=["post"], url_path="approve-change")
    def approve_change(self, request, pk=None):
        reservation = self.get_object()
        change = self._pending_change(reservation)
        if change is None:
            return Response(
                {"detail": "No pending change request."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Phase 5.2: 승인으로 옮겨갈 새 슬롯도 생성과 같은 가용성 규칙을
        # 통과해야 한다(자기 자신은 수량에서 제외). 검증 실패면 400 이고
        # 예약/변경 요청 모두 그대로 남는다.
        with transaction.atomic():
            validate_reservation_slot(
                restaurant=reservation.restaurant,
                date=change.requested_date,
                time_value=change.requested_time,
                seat_type=reservation.seat_type,
                exclude_reservation_id=reservation.pk,
            )

            # 승인 시 실제 예약값에 반영(Flutter approveReservationChange와 동일)
            reservation.date = change.requested_date
            reservation.time = change.requested_time
            reservation.party_size = change.requested_party_size
            reservation.save(
                update_fields=["date", "time", "party_size", "updated_at"]
            )

            change.status = ReservationChangeRequest.Status.APPROVED
            change.resolved_at = timezone.now()
            change.save(update_fields=["status", "resolved_at"])

        return Response(self.get_serializer(reservation).data)

    @action(detail=True, methods=["post"], url_path="reject-change")
    def reject_change(self, request, pk=None):
        reservation = self.get_object()
        change = self._pending_change(reservation)
        if change is None:
            return Response(
                {"detail": "No pending change request."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 거절 시 예약 원본은 유지하고 요청만 rejected 처리(Flutter rejectReservationChange와 동일)
        change.status = ReservationChangeRequest.Status.REJECTED
        change.resolved_at = timezone.now()
        change.save(update_fields=["status", "resolved_at"])

        return Response(self.get_serializer(reservation).data)

    @staticmethod
    def _pending_change(reservation):
        return reservation.change_requests.filter(
            status=ReservationChangeRequest.Status.PENDING
        ).first()


def _get_supabase_client():
    try:
        from supabase_client import get_supabase_client
    except ImportError as exc:
        raise RuntimeError("Supabase client is not configured.") from exc
    return get_supabase_client()


@extend_schema(
    request=AuthCredentialsSerializer,
    responses={200: SignupResponseSerializer, 400: SignupResponseSerializer},
)
@api_view(["POST"])
@authentication_classes([])
@permission_classes([AllowAny])
def signup(request):
    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response(
            {"error": "email과 password가 필요합니다."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        supabase = _get_supabase_client()
        result = supabase.auth.sign_up({"email": email, "password": password})
    except RuntimeError as exc:
        return Response({"error": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    if result.user:
        return Response({"message": "가입 성공!"})
    return Response({"error": "가입 실패"}, status=status.HTTP_400_BAD_REQUEST)


@extend_schema(
    request=AuthCredentialsSerializer,
    responses={200: LoginResponseSerializer, 401: SignupResponseSerializer},
)
@api_view(["POST"])
@authentication_classes([])
@permission_classes([AllowAny])
def login(request):
    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response(
            {"error": "email과 password가 필요합니다."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        supabase = _get_supabase_client()
        result = supabase.auth.sign_in_with_password(
            {"email": email, "password": password}
        )
    except RuntimeError as exc:
        return Response({"error": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    if result.user:
        return Response(
            {
                "message": "로그인 성공!",
                "access_token": result.session.access_token,
            }
        )
    return Response({"error": "이메일/비밀번호 확인"}, status=status.HTTP_401_UNAUTHORIZED)
