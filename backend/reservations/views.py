from rest_framework import status, viewsets
from rest_framework.decorators import (
    api_view,
    authentication_classes,
    permission_classes,
)
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .authentication import SupabaseAuthentication
from .models import Reservation
from .serializers import ReservationSerializer


class ReservationViewSet(viewsets.ModelViewSet):
    authentication_classes = [SupabaseAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = ReservationSerializer

    def get_queryset(self):
        queryset = Reservation.objects.filter(user=self.request.user.id)
        date = self.request.query_params.get("date")

        if date:
            queryset = queryset.filter(date=date)

        return queryset.order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user.id)


@api_view(["GET"])
@authentication_classes([SupabaseAuthentication])
@permission_classes([IsAuthenticated])
def get_reservations(request):
    reservations = Reservation.objects.filter(user=request.user.id).order_by(
        "-created_at"
    )
    serializer = ReservationSerializer(reservations, many=True)
    return Response(serializer.data)


def _get_supabase_client():
    try:
        from supabase_client import get_supabase_client
    except ImportError as exc:
        raise RuntimeError("Supabase client is not configured.") from exc
    return get_supabase_client()


@api_view(["POST"])
@authentication_classes([])
@permission_classes([AllowAny])
def signup(request):
    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response(
            {"error": "email과 password가 필요합니다."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        supabase = _get_supabase_client()
        result = supabase.auth.sign_up({"email": email, "password": password})
    except RuntimeError as exc:
        return Response({"error": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    if result.user:
        return Response({"message": "가입 성공!"})
    return Response({"error": "가입 실패"}, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"])
@authentication_classes([])
@permission_classes([AllowAny])
def login(request):
    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response(
            {"error": "email과 password가 필요합니다."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        supabase = _get_supabase_client()
        result = supabase.auth.sign_in_with_password(
            {"email": email, "password": password}
        )
    except RuntimeError as exc:
        return Response({"error": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    if result.user:
        return Response(
            {
                "message": "로그인 성공!",
                "access_token": result.session.access_token,
            }
        )
    return Response({"error": "이메일/비밀번호 확인"}, status=status.HTTP_401_UNAUTHORIZED)
