from rest_framework import serializers

from .models import Reservation


class AuthCredentialsSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=6)


class SignupResponseSerializer(serializers.Serializer):
    message = serializers.CharField()


class LoginResponseSerializer(serializers.Serializer):
    message = serializers.CharField()
    access_token = serializers.CharField()


class ReservationSerializer(serializers.ModelSerializer):
    user_id = serializers.CharField(source="user", read_only=True)

    class Meta:
        model = Reservation
        fields = [
            "id",
            "user",
            "user_id",
            "restaurant",
            "external_restaurant_id",
            "restaurant_name",
            "date",
            "time",
            "party_size",
            "guest_name",
            "seat_type",
            "confirmation_code",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "user_id",
            "confirmation_code",
            "created_at",
            "updated_at",
        ]
