from django.contrib import admin

from .models import (
    DiningPreferences,
    NotificationSettings,
    PaymentMethod,
    SavedRestaurant,
    Transaction,
    UserProfile,
)


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "name", "email", "mobile_number")
    search_fields = ("user", "name", "email")


@admin.register(DiningPreferences)
class DiningPreferencesAdmin(admin.ModelAdmin):
    list_display = ("id", "user")
    search_fields = ("user",)


@admin.register(NotificationSettings)
class NotificationSettingsAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "push_enabled", "email_enabled")
    search_fields = ("user",)


@admin.register(SavedRestaurant)
class SavedRestaurantAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "restaurant", "created_at")
    search_fields = ("user",)


@admin.register(PaymentMethod)
class PaymentMethodAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "brand",
        "last4",
        "expiry_month",
        "expiry_year",
        "is_default",
    )
    list_filter = ("brand", "is_default")
    search_fields = ("user", "holder_name")


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "transaction_type",
        "status",
        "title",
        "amount",
        "currency",
        "created_at",
    )
    list_filter = ("transaction_type", "status", "currency")
    search_fields = ("user", "title", "provider_transaction_id")
