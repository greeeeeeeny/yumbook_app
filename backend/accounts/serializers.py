from rest_framework import serializers

from restaurants.models import Restaurant

from .models import (
    DiningPreferences,
    NotificationSettings,
    PaymentMethod,
    SavedRestaurant,
    Transaction,
    UserProfile,
)

# 이 API에는 절대 들어와선 안 되는 민감 키(전체 카드번호/CVV 등). 방어적으로 거부한다.
SENSITIVE_CARD_KEYS = {
    "card_number",
    "cardnumber",
    "number",
    "pan",
    "cvv",
    "cvc",
    "cvc2",
    "cvv2",
    "security_code",
}


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = [
            "name",
            "date_of_birth",
            "mobile_number",
            "email",
            "avatar_url",
            "created_at",
            "updated_at",
        ]
        # user(소유자)는 항상 인증 토큰에서 결정한다. 클라이언트가 바꿀 수 없다.
        read_only_fields = ["created_at", "updated_at"]


class DiningPreferencesSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiningPreferences
        fields = [
            "favorite_cuisines",
            "dining_styles",
            "dietary_restrictions",
            "additional_notes",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]


class NotificationSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationSettings
        fields = [
            "push_enabled",
            "email_enabled",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at"]


class SavedRestaurantWriteSerializer(serializers.Serializer):
    # 클라이언트는 restaurant(정수 PK)만 보낸다. 응답은 RestaurantSerializer로 내려간다.
    restaurant = serializers.PrimaryKeyRelatedField(queryset=Restaurant.objects.all())


def _parse_expiry(raw):
    """'MM/YY' 또는 'MM/YYYY' 문자열을 (month, year)로 분해한다."""
    parts = str(raw).replace(" ", "").split("/")
    if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
        raise serializers.ValidationError(
            {"expiry": "expiry must look like 'MM/YY' or 'MM/YYYY'."}
        )
    month = int(parts[0])
    year = int(parts[1])
    if year < 100:
        year += 2000
    return month, year


class PaymentMethodSerializer(serializers.ModelSerializer):
    # Flutter PaymentMethodModel.expiry(단일 문자열) 호환용 입출력.
    # 저장은 expiry_month/expiry_year로 정규화한다.
    expiry = serializers.CharField(required=False, write_only=True)

    class Meta:
        model = PaymentMethod
        fields = [
            "id",
            "brand",
            "last4",
            "holder_name",
            "expiry_month",
            "expiry_year",
            "expiry",
            "is_default",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]
        extra_kwargs = {
            "expiry_month": {"required": False},
            "expiry_year": {"required": False},
        }

    def validate_last4(self, value):
        if value and (not value.isdigit() or len(value) > 4):
            raise serializers.ValidationError("last4 must be up to 4 digits.")
        return value

    def validate(self, attrs):
        # 1) 민감 정보(전체 카드번호/CVV)는 어떤 경우에도 거부한다.
        if isinstance(self.initial_data, dict):
            present = SENSITIVE_CARD_KEYS & {
                str(k).lower() for k in self.initial_data.keys()
            }
            if present:
                raise serializers.ValidationError(
                    {
                        "detail": (
                            "Full card number / CVV must never be sent to or "
                            "stored by this API."
                        )
                    }
                )

        # 2) expiry 'MM/YY' 문자열이 오면 month/year로 분해(명시 값이 없을 때만).
        raw_expiry = attrs.pop("expiry", None)
        if raw_expiry and not (attrs.get("expiry_month") and attrs.get("expiry_year")):
            month, year = _parse_expiry(raw_expiry)
            attrs["expiry_month"] = month
            attrs["expiry_year"] = year

        # 3) 만료 월 검증.
        month = attrs.get("expiry_month")
        if month is not None and not (1 <= month <= 12):
            raise serializers.ValidationError(
                {"expiry_month": "expiry_month must be between 1 and 12."}
            )

        return attrs

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if instance.expiry_month and instance.expiry_year:
            data["expiry"] = (
                f"{instance.expiry_month:02d}/{instance.expiry_year % 100:02d}"
            )
        else:
            data["expiry"] = ""
        return data


# 결제 원장에도 들어와선 안 되는 민감 키(인증 시크릿 포함).
SENSITIVE_TRANSACTION_KEYS = SENSITIVE_CARD_KEYS | {
    "authorization_secret",
    "auth_secret",
    "client_secret",
    "card_token_secret",
}


class TransactionSerializer(serializers.ModelSerializer):
    # Flutter TransactionModel 호환용 읽기 별칭.
    type = serializers.CharField(source="transaction_type", read_only=True)
    subtitle = serializers.CharField(source="description", read_only=True)

    class Meta:
        model = Transaction
        fields = [
            "id",
            "user",
            "reservation",
            "payment_method",
            "title",
            "description",
            "subtitle",
            "amount",
            "currency",
            "status",
            "transaction_type",
            "type",
            "provider",
            "provider_transaction_id",
            "card_brand",
            "card_last4",
            "trailing_text",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]

    def validate_card_last4(self, value):
        if value and (not value.isdigit() or len(value) > 4):
            raise serializers.ValidationError("card_last4 must be up to 4 digits.")
        return value

    def validate(self, attrs):
        # 민감 결제 정보(전체 카드번호/CVV/인증 시크릿)는 어떤 경우에도 거부한다.
        if isinstance(self.initial_data, dict):
            present = SENSITIVE_TRANSACTION_KEYS & {
                str(k).lower() for k in self.initial_data.keys()
            }
            if present:
                raise serializers.ValidationError(
                    {
                        "detail": (
                            "Sensitive payment data (full card number / CVV / "
                            "auth secrets) must never be sent to or stored by "
                            "this API."
                        )
                    }
                )
        return attrs
