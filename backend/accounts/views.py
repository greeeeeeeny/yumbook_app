from rest_framework import exceptions, generics, mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from reservations.authentication import SupabaseAuthentication
from restaurants.serializers import RestaurantSerializer

from .models import (
    DiningPreferences,
    NotificationSettings,
    PaymentMethod,
    SavedRestaurant,
    Transaction,
    UserProfile,
)
from .serializers import (
    DiningPreferencesSerializer,
    NotificationSettingsSerializer,
    PaymentMethodSerializer,
    SavedRestaurantWriteSerializer,
    TransactionSerializer,
    UserProfileSerializer,
)


class OwnerSingletonView(generics.RetrieveUpdateAPIView):
    """현재 사용자(Supabase UUID) 1명당 1개 행을 다루는 GET/PATCH 싱글톤 뷰.

    URL에 id가 없고 항상 request.user.id로 조회/생성하므로 소유자 스코프가 보장된다.
    행이 없으면 기본값으로 생성한 뒤 반환한다(get_or_create).
    """

    authentication_classes = [SupabaseAuthentication]
    permission_classes = [IsAuthenticated]
    http_method_names = ["get", "patch", "head", "options"]
    model = None

    def get_defaults(self):
        """행 최초 생성 시 채울 기본값."""
        return {}

    def get_object(self):
        instance, _ = self.model.objects.get_or_create(
            user=self.request.user.id,
            defaults=self.get_defaults(),
        )
        return instance


class ProfileView(OwnerSingletonView):
    model = UserProfile
    serializer_class = UserProfileSerializer

    def get_defaults(self):
        # 가능하면 인증 토큰의 이메일로 기본값을 채운다.
        return {"email": getattr(self.request.user, "email", "") or ""}


class DiningPreferencesView(OwnerSingletonView):
    model = DiningPreferences
    serializer_class = DiningPreferencesSerializer


class NotificationSettingsView(OwnerSingletonView):
    model = NotificationSettings
    serializer_class = NotificationSettingsSerializer


class SavedRestaurantView(APIView):
    """GET: 현재 사용자의 저장 식당 목록(Restaurant 전체 객체). POST: 저장(멱등)."""

    authentication_classes = [SupabaseAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        saved = (
            SavedRestaurant.objects.filter(user=request.user.id)
            .select_related("restaurant", "restaurant__region", "restaurant__policy")
            .prefetch_related("restaurant__images")
        )
        restaurants = [s.restaurant for s in saved]
        return Response(RestaurantSerializer(restaurants, many=True).data)

    def post(self, request):
        serializer = SavedRestaurantWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        restaurant = serializer.validated_data["restaurant"]

        # 중복 저장 방지: 이미 있으면 새로 만들지 않고 그대로 반환한다.
        _, created = SavedRestaurant.objects.get_or_create(
            user=request.user.id, restaurant=restaurant
        )
        return Response(
            RestaurantSerializer(restaurant).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class SavedRestaurantDetailView(APIView):
    """DELETE /saved-restaurants/<restaurant_id>/ — restaurant_id 기준 unsave."""

    authentication_classes = [SupabaseAuthentication]
    permission_classes = [IsAuthenticated]

    def delete(self, request, restaurant_id):
        deleted, _ = SavedRestaurant.objects.filter(
            user=request.user.id, restaurant_id=restaurant_id
        ).delete()
        if not deleted:
            return Response(status=status.HTTP_404_NOT_FOUND)
        return Response(status=status.HTTP_204_NO_CONTENT)


class PaymentMethodViewSet(viewsets.ModelViewSet):
    authentication_classes = [SupabaseAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = PaymentMethodSerializer

    def get_queryset(self):
        return PaymentMethod.objects.filter(user=self.request.user.id)

    def perform_create(self, serializer):
        user_id = self.request.user.id
        wants_default = serializer.validated_data.get("is_default", False)
        first_card = not PaymentMethod.objects.filter(user=user_id).exists()
        instance = serializer.save(user=user_id)
        # 첫 카드이거나 default 요청이면 기본 카드로 지정(나머지는 해제).
        if first_card or wants_default:
            self._make_default(instance)

    def perform_update(self, serializer):
        instance = serializer.save()
        if serializer.validated_data.get("is_default"):
            self._make_default(instance)

    def perform_destroy(self, instance):
        was_default = instance.is_default
        user_id = instance.user
        instance.delete()
        # 기본 카드를 지웠으면 남은 카드 중 가장 최근 것을 기본으로 승격.
        if was_default:
            replacement = (
                PaymentMethod.objects.filter(user=user_id)
                .order_by("-created_at")
                .first()
            )
            if replacement:
                self._make_default(replacement)

    @action(detail=True, methods=["post"], url_path="set-default")
    def set_default(self, request, pk=None):
        instance = self.get_object()
        self._make_default(instance)
        return Response(self.get_serializer(instance).data)

    def _make_default(self, instance):
        PaymentMethod.objects.filter(user=instance.user).exclude(
            pk=instance.pk
        ).update(is_default=False)
        if not instance.is_default:
            instance.is_default = True
            instance.save(update_fields=["is_default"])


class TransactionViewSet(
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.ListModelMixin,
    viewsets.GenericViewSet,
):
    """결제/환불 원장. GET list, GET retrieve, POST create (수정/삭제 없음)."""

    authentication_classes = [SupabaseAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = TransactionSerializer

    def get_queryset(self):
        qs = Transaction.objects.filter(user=self.request.user.id)
        params = self.request.query_params

        status_param = params.get("status")
        if status_param:
            qs = qs.filter(status=status_param)

        # transaction_type 또는 Flutter 별칭 type 둘 다 허용.
        ttype = params.get("transaction_type") or params.get("type")
        if ttype:
            qs = qs.filter(transaction_type=ttype)

        reservation = params.get("reservation")
        if reservation:
            qs = qs.filter(reservation_id=reservation)

        return qs

    def perform_create(self, serializer):
        user_id = self.request.user.id
        reservation = serializer.validated_data.get("reservation")
        payment_method = serializer.validated_data.get("payment_method")

        # 연결되는 reservation/payment_method는 반드시 본인 소유여야 한다.
        if reservation is not None and reservation.user != user_id:
            raise exceptions.PermissionDenied(
                "Reservation does not belong to you."
            )
        if payment_method is not None and payment_method.user != user_id:
            raise exceptions.PermissionDenied(
                "Payment method does not belong to you."
            )

        # 카드 스냅샷 자동 채움(명시 값이 없을 때, 연결된 결제수단에서 복사).
        extra = {}
        if payment_method is not None:
            if not serializer.validated_data.get("card_brand"):
                extra["card_brand"] = payment_method.brand
            if not serializer.validated_data.get("card_last4"):
                extra["card_last4"] = payment_method.last4

        serializer.save(user=user_id, **extra)
