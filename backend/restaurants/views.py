from django.db.models import Q
from rest_framework import viewsets
from rest_framework.permissions import AllowAny, IsAdminUser

from reservations.authentication import SupabaseAuthentication

from .models import Restaurant
from .serializers import RestaurantSerializer


class RestaurantViewSet(viewsets.ModelViewSet):
    authentication_classes = [SupabaseAuthentication]
    serializer_class = RestaurantSerializer
    queryset = Restaurant.objects.all().select_related("policy")

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [AllowAny()]
        return [IsAdminUser()]

    def get_queryset(self):
        queryset = super().get_queryset()
        params = self.request.query_params

        q = params.get("q")
        if q:
            queryset = queryset.filter(
                Q(name__icontains=q)
                | Q(description__icontains=q)
                | Q(location__icontains=q)
            )

        location = params.get("location")
        if location:
            queryset = queryset.filter(location__iexact=location)

        category = params.get("category")
        if category:
            queryset = queryset.filter(raw_category__iexact=category)

        return queryset
