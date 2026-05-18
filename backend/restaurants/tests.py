from types import SimpleNamespace
from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from .models import Restaurant, RestaurantPolicy


def _supabase_client(token_to_user):
    class FakeAuth:
        def get_user(self, access_token):
            entry = token_to_user.get(access_token)
            if not entry:
                raise RuntimeError("invalid token")
            user_id, is_admin = entry
            return SimpleNamespace(
                user=SimpleNamespace(
                    id=user_id,
                    email=f"{user_id}@example.com",
                    app_metadata={"role": "admin"} if is_admin else {},
                )
            )

    return SimpleNamespace(auth=FakeAuth())


class RestaurantReadTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.r1 = Restaurant.objects.create(
            name="Cafe Um",
            location="Cheonan",
            description="Cozy brunch cafe.",
            tags=["Brunch", "Cafe"],
            raw_category="Brunch Cafe",
        )
        self.r2 = Restaurant.objects.create(
            name="Sourdough Pizza Lab",
            location="Seoul",
            description="Authentic sourdough pizza.",
            tags=["Italian"],
            raw_category="Italian",
        )

    def test_list_is_public(self):
        response = self.client.get("/api/restaurants/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 2)

    def test_retrieve_includes_policy_when_present(self):
        RestaurantPolicy.objects.create(restaurant=self.r1, deposit_type="fixed")

        response = self.client.get(f"/api/restaurants/{self.r1.id}/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["policy"]["deposit_type"], "fixed")

    def test_search_by_query_matches_name_or_description(self):
        response = self.client.get("/api/restaurants/", {"q": "pizza"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Sourdough Pizza Lab")

    def test_filter_by_location(self):
        response = self.client.get("/api/restaurants/", {"location": "Seoul"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["location"], "Seoul")

    def test_filter_by_category(self):
        response = self.client.get("/api/restaurants/", {"category": "Italian"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)


class RestaurantWriteTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    @patch("reservations.authentication.get_supabase_client")
    def test_non_admin_cannot_create(self, mock_client):
        mock_client.return_value = _supabase_client({"token-user": ("user-1", False)})

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-user")
        response = self.client.post(
            "/api/restaurants/",
            {"name": "New Place", "location": "Seoul"},
            format="json",
        )

        self.assertEqual(response.status_code, 403)

    def test_anonymous_cannot_create(self):
        response = self.client.post(
            "/api/restaurants/",
            {"name": "New Place", "location": "Seoul"},
            format="json",
        )

        self.assertEqual(response.status_code, 401)

    @patch("reservations.authentication.get_supabase_client")
    def test_admin_can_create(self, mock_client):
        mock_client.return_value = _supabase_client({"token-admin": ("admin-1", True)})

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-admin")
        response = self.client.post(
            "/api/restaurants/",
            {
                "name": "New Place",
                "location": "Seoul",
                "tags": ["Cafe"],
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertTrue(Restaurant.objects.filter(name="New Place").exists())
