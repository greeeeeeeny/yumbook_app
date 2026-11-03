from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import RegionViewSet, RestaurantViewSet

router = DefaultRouter()
router.register("restaurants", RestaurantViewSet, basename="restaurant")
router.register("regions", RegionViewSet, basename="region")

urlpatterns = [
    path("", include(router.urls)),
]
