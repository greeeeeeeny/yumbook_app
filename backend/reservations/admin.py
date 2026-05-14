from django.contrib import admin

from .models import Reservation


@admin.register(Reservation)
class ReservationAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "restaurant_name",
        "date",
        "time",
        "party_size",
        "confirmation_code",
    )
    search_fields = ("user", "restaurant_name", "guest_name", "confirmation_code")
    list_filter = ("date", "seat_type")
