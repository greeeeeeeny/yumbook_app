from types import SimpleNamespace
from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from .models import Reservation


class ReservationAuthTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_reservation_list_requires_authentication(self):
        response = self.client.get("/api/reservations/")

        self.assertEqual(response.status_code, 401)

    @patch("reservations.authentication.get_supabase_client")
    def test_reservation_list_is_scoped_to_authenticated_user(self, mock_client):
        mock_client.return_value = self._supabase_client_for("token-a", "user-a")
        Reservation.objects.create(
            user="user-a",
            restaurant_name="A",
            date="2026-05-12",
            time="18:00",
            party_size=2,
        )
        Reservation.objects.create(
            user="user-b",
            restaurant_name="B",
            date="2026-05-12",
            time="19:00",
            party_size=2,
        )

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.get("/api/reservations/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["user"], "user-a")

    @patch("reservations.authentication.get_supabase_client")
    def test_create_uses_authenticated_user_not_request_user_id(self, mock_client):
        mock_client.return_value = self._supabase_client_for("token-a", "user-a")

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.post(
            "/api/reservations/",
            {
                "user": "user-b",
                "user_id": "user-b",
                "restaurant_name": "A",
                "date": "2026-05-12",
                "time": "18:00",
                "party_size": 2,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        reservation = Reservation.objects.get(id=response.data["id"])
        self.assertEqual(reservation.user, "user-a")

    def _supabase_client_for(self, token, user_id):
        class FakeAuth:
            def get_user(self, access_token):
                if access_token != token:
                    raise RuntimeError("invalid token")
                return SimpleNamespace(
                    user=SimpleNamespace(id=user_id, email=f"{user_id}@example.com")
                )

        return SimpleNamespace(auth=FakeAuth())
