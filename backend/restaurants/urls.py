from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import RestaurantViewSet

router = DefaultRouter()
router.register("restaurants", RestaurantViewSet, basename="restaurant")

urlpatterns = [
    path("", include(router.urls)),
]
