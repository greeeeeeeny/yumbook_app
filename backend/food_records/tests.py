from types import SimpleNamespace
from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from restaurants.models import Restaurant

from .models import FoodRecord, FoodRecordImage


def _supabase_client(token, user_id, is_admin=False):
    class FakeAuth:
        def get_user(self, access_token):
            if access_token != token:
                raise RuntimeError("invalid token")
            return SimpleNamespace(
                user=SimpleNamespace(
                    id=user_id,
                    email=f"{user_id}@example.com",
                    app_metadata={"role": "admin"} if is_admin else {},
                )
            )

    return SimpleNamespace(auth=FakeAuth())


class FoodRecordCrudTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.restaurant = Restaurant.objects.create(name="Cafe Um", location="Cheonan")

    @patch("reservations.authentication.get_supabase_client")
    def test_create_assigns_authenticated_user_and_handles_images(self, mock_client):
        mock_client.return_value = _supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")

        response = self.client.post(
            "/api/food-records/",
            {
                "restaurant": self.restaurant.id,
                "menu_name": "Brunch Plate",
                "rating": "4.5",
                "review": "Great brunch",
                "images": [
                    {"image_url": "https://cdn.example.com/a.jpg", "order": 0},
                    {"image_url": "https://cdn.example.com/b.jpg", "order": 1},
                ],
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201, response.data)
        record = FoodRecord.objects.get(id=response.data["id"])
        self.assertEqual(record.user, "user-a")
        self.assertEqual(record.images.count(), 2)

    @patch("reservations.authentication.get_supabase_client")
    def test_create_ignores_user_field_from_body(self, mock_client):
        mock_client.return_value = _supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")

        response = self.client.post(
            "/api/food-records/",
            {
                "user": "attacker",
                "rating": "5",
                "menu_name": "x",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(FoodRecord.objects.get().user, "user-a")

    @patch("reservations.authentication.get_supabase_client")
    def test_cannot_update_others_record(self, mock_client):
        record = FoodRecord.objects.create(user="user-a", rating=4)
        mock_client.return_value = _supabase_client("token-b", "user-b")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-b")

        response = self.client.patch(
            f"/api/food-records/{record.id}/",
            {"review": "hacked"},
            format="json",
        )

        self.assertEqual(response.status_code, 403)

    @patch("reservations.authentication.get_supabase_client")
    def test_cannot_delete_others_record(self, mock_client):
        record = FoodRecord.objects.create(user="user-a", rating=4)
        mock_client.return_value = _supabase_client("token-b", "user-b")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-b")

        response = self.client.delete(f"/api/food-records/{record.id}/")

        self.assertEqual(response.status_code, 403)
        self.assertTrue(FoodRecord.objects.filter(id=record.id).exists())


class FoodRecordFeedTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        FoodRecord.objects.create(user="user-a", rating=4, review="public a", is_public=True)
        FoodRecord.objects.create(user="user-a", rating=5, review="private a", is_public=False)
        FoodRecord.objects.create(user="user-b", rating=3, review="public b", is_public=True)

    def test_anonymous_sees_only_public(self):
        response = self.client.get("/api/food-records/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 2)

    @patch("reservations.authentication.get_supabase_client")
    def test_authenticated_sees_public_plus_own_private(self, mock_client):
        mock_client.return_value = _supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")

        response = self.client.get("/api/food-records/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 3)

    @patch("reservations.authentication.get_supabase_client")
    def test_mine_filter_returns_only_own(self, mock_client):
        mock_client.return_value = _supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")

        response = self.client.get("/api/food-records/", {"mine": "1"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 2)
        for item in response.data:
            self.assertEqual(item["user"], "user-a")

    def test_ordering_by_rating_desc(self):
        response = self.client.get("/api/food-records/", {"ordering": "-rating"})

        self.assertEqual(response.status_code, 200)
        ratings = [float(item["rating"]) for item in response.data]
        self.assertEqual(ratings, sorted(ratings, reverse=True))


class RestaurantAggregationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.restaurant = Restaurant.objects.create(name="Aggregate", location="Seoul")

    @patch("reservations.authentication.get_supabase_client")
    def test_create_updates_restaurant_rating_and_review_count(self, mock_client):
        mock_client.return_value = _supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")

        for rating in ("4.0", "5.0"):
            response = self.client.post(
                "/api/food-records/",
                {"restaurant": self.restaurant.id, "rating": rating},
                format="json",
            )
            self.assertEqual(response.status_code, 201)

        self.restaurant.refresh_from_db()
        self.assertEqual(self.restaurant.review_count, 2)
        self.assertAlmostEqual(float(self.restaurant.rating), 4.5)

    @patch("reservations.authentication.get_supabase_client")
    def test_delete_updates_restaurant_stats(self, mock_client):
        mock_client.return_value = _supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")

        record = FoodRecord.objects.create(
            user="user-a", restaurant=self.restaurant, rating=4
        )
        # initial create did not trigger aggregation; trigger via API delete
        FoodRecord.objects.filter(restaurant=self.restaurant).exclude(id=record.id).delete()
        self.client.delete(f"/api/food-records/{record.id}/")

        self.restaurant.refresh_from_db()
        self.assertEqual(self.restaurant.review_count, 0)
        self.assertEqual(float(self.restaurant.rating), 0.0)
