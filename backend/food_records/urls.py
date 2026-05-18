from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import FoodRecordViewSet

router = DefaultRouter()
router.register("food-records", FoodRecordViewSet, basename="food-record")

urlpatterns = [
    path("", include(router.urls)),
]
