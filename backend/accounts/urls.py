from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    DiningPreferencesView,
    NotificationSettingsView,
    PaymentMethodViewSet,
    ProfileView,
    SavedRestaurantDetailView,
    SavedRestaurantView,
    TransactionViewSet,
)

router = DefaultRouter()
router.register("payment-methods", PaymentMethodViewSet, basename="payment-method")
router.register("transactions", TransactionViewSet, basename="transaction")

urlpatterns = [
    path("account/profile/", ProfileView.as_view(), name="account-profile"),
    path(
        "account/dining-preferences/",
        DiningPreferencesView.as_view(),
        name="account-dining-preferences",
    ),
    path(
        "account/notification-settings/",
        NotificationSettingsView.as_view(),
        name="account-notification-settings",
    ),
    path(
        "saved-restaurants/",
        SavedRestaurantView.as_view(),
        name="saved-restaurant-list",
    ),
    path(
        "saved-restaurants/<int:restaurant_id>/",
        SavedRestaurantDetailView.as_view(),
        name="saved-restaurant-detail",
    ),
    *router.urls,
]
