from django.contrib import admin

from .models import Reservation, ReservationChangeRequest


@admin.register(Reservation)
class ReservationAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "restaurant_name",
        "date",
        "time",
        "party_size",
        "status",
        "confirmation_code",
    )
    search_fields = ("user", "restaurant_name", "guest_name", "confirmation_code")
    list_filter = ("status", "date", "seat_type")


@admin.register(ReservationChangeRequest)
class ReservationChangeRequestAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "reservation",
        "requested_date",
        "requested_time",
        "requested_party_size",
        "status",
        "requested_at",
        "resolved_at",
    )
    list_filter = ("status",)
