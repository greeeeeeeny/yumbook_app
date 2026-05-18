from django.db.models import Avg, Count, Q
from rest_framework import exceptions, viewsets
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly

from reservations.authentication import SupabaseAuthentication

from .models import FoodRecord
from .serializers import FoodRecordSerializer


class FoodRecordViewSet(viewsets.ModelViewSet):
    authentication_classes = [SupabaseAuthentication]
    serializer_class = FoodRecordSerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [IsAuthenticatedOrReadOnly()]
        return [IsAuthenticated()]

    def get_queryset(self):
        params = self.request.query_params
        user = self.request.user
        user_id = getattr(user, "id", None) if user and user.is_authenticated else None

        if params.get("mine") in ("1", "true"):
            if not user_id:
                raise exceptions.NotAuthenticated()
            queryset = FoodRecord.objects.filter(user=user_id)
        else:
            queryset = FoodRecord.objects.filter(
                Q(is_public=True) | Q(user=user_id) if user_id else Q(is_public=True)
            )

        target_user = params.get("user")
        if target_user:
            queryset = queryset.filter(user=target_user)

        restaurant = params.get("restaurant")
        if restaurant:
            queryset = queryset.filter(restaurant_id=restaurant)

        q = params.get("q")
        if q:
            queryset = queryset.filter(
                Q(review__icontains=q)
                | Q(menu_name__icontains=q)
                | Q(restaurant_name__icontains=q)
            )

        ordering = params.get("ordering") or "-created_at"
        allowed = {"-created_at", "created_at", "-rating", "rating", "-visited_at", "visited_at"}
        if ordering not in allowed:
            ordering = "-created_at"

        return queryset.prefetch_related("images").order_by(ordering)

    def perform_create(self, serializer):
        record = serializer.save(user=self.request.user.id)
        _refresh_restaurant_stats(record.restaurant_id)

    def perform_update(self, serializer):
        previous_restaurant_id = serializer.instance.restaurant_id
        record = serializer.save()
        if previous_restaurant_id and previous_restaurant_id != record.restaurant_id:
            _refresh_restaurant_stats(previous_restaurant_id)
        _refresh_restaurant_stats(record.restaurant_id)

    def perform_destroy(self, instance):
        if instance.user != self.request.user.id:
            raise exceptions.PermissionDenied()
        restaurant_id = instance.restaurant_id
        instance.delete()
        _refresh_restaurant_stats(restaurant_id)

    def update(self, request, *args, **kwargs):
        record = self.get_object()
        if record.user != request.user.id:
            raise exceptions.PermissionDenied()
        return super().update(request, *args, **kwargs)


def _refresh_restaurant_stats(restaurant_id):
    if not restaurant_id:
        return
    from restaurants.models import Restaurant

    stats = FoodRecord.objects.filter(restaurant_id=restaurant_id).aggregate(
        avg=Avg("rating"), total=Count("id")
    )
    Restaurant.objects.filter(pk=restaurant_id).update(
        rating=stats["avg"] or 0,
        review_count=stats["total"] or 0,
    )
