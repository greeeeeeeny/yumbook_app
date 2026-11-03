from rest_framework import serializers

from .models import Reservation, ReservationChangeRequest


class AuthCredentialsSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=6)


class SignupResponseSerializer(serializers.Serializer):
    message = serializers.CharField()


class LoginResponseSerializer(serializers.Serializer):
    message = serializers.CharField()
    access_token = serializers.CharField()


class ReservationChangeRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReservationChangeRequest
        fields = [
            "id",
            "requested_date",
            "requested_time",
            "requested_party_size",
            "status",
            "requested_at",
            "resolved_at",
        ]
        read_only_fields = ["id", "status", "requested_at", "resolved_at"]


class ChangeRequestInputSerializer(serializers.Serializer):
    requested_date = serializers.DateField()
    requested_time = serializers.TimeField()
    requested_party_size = serializers.IntegerField(min_value=1)


class CancelReservationSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, default="")


class ReservationSerializer(serializers.ModelSerializer):
    user_id = serializers.CharField(source="user", read_only=True)
    # 클라이언트(Flutter)는 restaurant_id를 String으로 보내고 읽는다.
    # 이 값은 external_restaurant_id 컬럼에 저장/조회된다.
    # restaurant FK(정수)와는 독립적으로 동작한다.
    restaurant_id = serializers.CharField(
        source="external_restaurant_id",
        required=False,
        allow_null=True,
        allow_blank=True,
    )
    # 가장 최근 변경 요청을 pending_change로 노출한다(Flutter ReservationData.pendingChange).
    pending_change = serializers.SerializerMethodField()

    class Meta:
        model = Reservation
        fields = [
            "id",
            "user",
            "user_id",
            "restaurant",
            "restaurant_id",
            "external_restaurant_id",
            "restaurant_name",
            "date",
            "time",
            "party_size",
            "guest_name",
            "seat_type",
            "confirmation_code",
            "status",
            "cancel_reason",
            "payment_snapshot",
            "pending_change",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "user_id",
            # external_restaurant_id는 restaurant_id를 통해서만 기록한다(이중 write source 충돌 방지).
            "external_restaurant_id",
            "confirmation_code",
            # 상태/취소 사유는 전용 액션(cancel/approve/reject)으로만 변경한다.
            "status",
            "cancel_reason",
            "pending_change",
            "created_at",
            "updated_at",
        ]

    def get_pending_change(self, obj):
        change = (
            obj.change_requests.order_by("-requested_at").first()
            if hasattr(obj, "change_requests")
            else None
        )
        if change is None:
            return None
        return ReservationChangeRequestSerializer(change).data
