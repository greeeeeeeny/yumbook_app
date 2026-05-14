from rest_framework import serializers

from .models import Reservation


class ReservationSerializer(serializers.ModelSerializer):
    user_id = serializers.CharField(source="user", read_only=True)

    class Meta:
        model = Reservation
        fields = [
            "id",
            "user",
            "user_id",
            "restaurant_id",
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
