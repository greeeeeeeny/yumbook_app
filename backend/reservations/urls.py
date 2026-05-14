from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import ReservationViewSet, login, signup

router = DefaultRouter()
router.register("reservations", ReservationViewSet, basename="reservation")

urlpatterns = [
    path("", include(router.urls)),
    path("signup/", signup, name="signup"),
    path("login/", login, name="login"),
]
