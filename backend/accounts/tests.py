from types import SimpleNamespace
from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from reservations.models import Reservation
from restaurants.models import Restaurant

from .models import (
    DiningPreferences,
    NotificationSettings,
    PaymentMethod,
    SavedRestaurant,
    Transaction,
    UserProfile,
)


def fake_supabase_client(token, user_id, email=None):
    class FakeAuth:
        def get_user(self, access_token):
            if access_token != token:
                raise RuntimeError("invalid token")
            return SimpleNamespace(
                user=SimpleNamespace(
                    id=user_id,
                    email=email or f"{user_id}@example.com",
                )
            )

    return SimpleNamespace(auth=FakeAuth())


class AccountsAuthTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_endpoints_require_authentication(self):
        for path in (
            "/api/account/profile/",
            "/api/account/dining-preferences/",
            "/api/account/notification-settings/",
        ):
            self.assertEqual(self.client.get(path).status_code, 401, path)


class ProfileTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    @patch("reservations.authentication.get_supabase_client")
    def test_get_creates_with_defaults(self, mock_client):
        mock_client.return_value = fake_supabase_client(
            "token-a", "user-a", email="amy@example.com"
        )

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.get("/api/account/profile/")

        self.assertEqual(response.status_code, 200)
        # 최초 GET 시 행이 생성된다(get_or_create).
        self.assertEqual(UserProfile.objects.filter(user="user-a").count(), 1)
        # 인증 토큰 이메일이 기본값으로 채워진다.
        self.assertEqual(response.data["email"], "amy@example.com")
        self.assertEqual(response.data["name"], "")
        self.assertEqual(response.data["avatar_url"], "")

    @patch("reservations.authentication.get_supabase_client")
    def test_patch_updates_fields(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.patch(
            "/api/account/profile/",
            {
                "name": "Amy",
                "date_of_birth": "Jan 1, 1991",
                "mobile_number": "010-1010-1010",
                "avatar_url": "https://cdn.example.com/a.png",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["name"], "Amy")
        self.assertEqual(response.data["date_of_birth"], "Jan 1, 1991")
        self.assertEqual(response.data["mobile_number"], "010-1010-1010")
        self.assertEqual(response.data["avatar_url"], "https://cdn.example.com/a.png")

        profile = UserProfile.objects.get(user="user-a")
        self.assertEqual(profile.name, "Amy")

    @patch("reservations.authentication.get_supabase_client")
    def test_profile_is_owner_scoped(self, mock_client):
        # user-a 가 데이터를 넣어도 user-b 는 자기 빈 프로필만 본다.
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        self.client.patch(
            "/api/account/profile/", {"name": "Amy"}, format="json"
        )

        mock_client.return_value = fake_supabase_client("token-b", "user-b")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-b")
        response = self.client.get("/api/account/profile/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["name"], "")
        self.assertEqual(UserProfile.objects.get(user="user-a").name, "Amy")


class DiningPreferencesTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    @patch("reservations.authentication.get_supabase_client")
    def test_get_creates_with_defaults(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.get("/api/account/dining-preferences/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            DiningPreferences.objects.filter(user="user-a").count(), 1
        )
        self.assertEqual(response.data["favorite_cuisines"], [])
        self.assertEqual(response.data["dining_styles"], [])
        self.assertEqual(response.data["dietary_restrictions"], [])
        self.assertEqual(response.data["additional_notes"], "")

    @patch("reservations.authentication.get_supabase_client")
    def test_patch_updates_fields(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.patch(
            "/api/account/dining-preferences/",
            {
                "favorite_cuisines": ["Korean", "Italian"],
                "dining_styles": ["Casual"],
                "dietary_restrictions": ["Vegetarian"],
                "additional_notes": "No peanuts",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["favorite_cuisines"], ["Korean", "Italian"])
        self.assertEqual(response.data["dining_styles"], ["Casual"])
        self.assertEqual(response.data["dietary_restrictions"], ["Vegetarian"])
        self.assertEqual(response.data["additional_notes"], "No peanuts")

    @patch("reservations.authentication.get_supabase_client")
    def test_dining_preferences_owner_scoped(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        self.client.patch(
            "/api/account/dining-preferences/",
            {"favorite_cuisines": ["Korean"]},
            format="json",
        )

        mock_client.return_value = fake_supabase_client("token-b", "user-b")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-b")
        response = self.client.get("/api/account/dining-preferences/")

        self.assertEqual(response.data["favorite_cuisines"], [])


class NotificationSettingsTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    @patch("reservations.authentication.get_supabase_client")
    def test_get_creates_with_defaults(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.get("/api/account/notification-settings/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            NotificationSettings.objects.filter(user="user-a").count(), 1
        )
        # 기본값은 둘 다 True.
        self.assertTrue(response.data["push_enabled"])
        self.assertTrue(response.data["email_enabled"])

    @patch("reservations.authentication.get_supabase_client")
    def test_patch_updates_fields(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.patch(
            "/api/account/notification-settings/",
            {"push_enabled": False, "email_enabled": False},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["push_enabled"])
        self.assertFalse(response.data["email_enabled"])

        settings_row = NotificationSettings.objects.get(user="user-a")
        self.assertFalse(settings_row.push_enabled)

    @patch("reservations.authentication.get_supabase_client")
    def test_notification_settings_owner_scoped(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        self.client.patch(
            "/api/account/notification-settings/",
            {"push_enabled": False},
            format="json",
        )

        mock_client.return_value = fake_supabase_client("token-b", "user-b")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-b")
        response = self.client.get("/api/account/notification-settings/")

        # user-b 는 자기 기본값(True) 을 받는다.
        self.assertTrue(response.data["push_enabled"])


class SavedRestaurantTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.r1 = Restaurant.objects.create(name="Cafe Um")
        self.r2 = Restaurant.objects.create(name="Hongdae Bistro")

    def _auth(self, token="token-a"):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_requires_authentication(self):
        self.assertEqual(self.client.get("/api/saved-restaurants/").status_code, 401)

    @patch("reservations.authentication.get_supabase_client")
    def test_save_list_and_unsave(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        # save
        response = self.client.post(
            "/api/saved-restaurants/", {"restaurant": self.r1.id}, format="json"
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(str(response.data["id"]), str(self.r1.id))

        # list returns full restaurant object
        response = self.client.get("/api/saved-restaurants/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Cafe Um")

        # unsave by restaurant id
        response = self.client.delete(f"/api/saved-restaurants/{self.r1.id}/")
        self.assertEqual(response.status_code, 204)
        self.assertEqual(
            SavedRestaurant.objects.filter(user="user-a").count(), 0
        )

    @patch("reservations.authentication.get_supabase_client")
    def test_duplicate_save_is_prevented(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        first = self.client.post(
            "/api/saved-restaurants/", {"restaurant": self.r1.id}, format="json"
        )
        second = self.client.post(
            "/api/saved-restaurants/", {"restaurant": self.r1.id}, format="json"
        )

        self.assertEqual(first.status_code, 201)
        # 두 번째 저장은 새 행을 만들지 않고 200으로 반환.
        self.assertEqual(second.status_code, 200)
        self.assertEqual(
            SavedRestaurant.objects.filter(user="user-a", restaurant=self.r1).count(),
            1,
        )

    @patch("reservations.authentication.get_supabase_client")
    def test_unsave_nonexistent_returns_404(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()
        response = self.client.delete(f"/api/saved-restaurants/{self.r2.id}/")
        self.assertEqual(response.status_code, 404)

    @patch("reservations.authentication.get_supabase_client")
    def test_saved_restaurants_owner_scoped(self, mock_client):
        # user-a 저장
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth("token-a")
        self.client.post(
            "/api/saved-restaurants/", {"restaurant": self.r1.id}, format="json"
        )

        # user-b 는 자기 목록만(빈) 본다.
        mock_client.return_value = fake_supabase_client("token-b", "user-b")
        self._auth("token-b")
        listing = self.client.get("/api/saved-restaurants/")
        self.assertEqual(len(listing.data), 0)

        # user-b 가 user-a 저장을 지우려 해도 404(자기 것이 없음), a 데이터 유지.
        delete = self.client.delete(f"/api/saved-restaurants/{self.r1.id}/")
        self.assertEqual(delete.status_code, 404)
        self.assertEqual(
            SavedRestaurant.objects.filter(user="user-a").count(), 1
        )


class PaymentMethodTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def _auth(self, token="token-a"):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def _create(self, **overrides):
        body = {
            "brand": "Visa",
            "last4": "4242",
            "holder_name": "Amy",
            "expiry_month": 12,
            "expiry_year": 2027,
        }
        body.update(overrides)
        return self.client.post("/api/payment-methods/", body, format="json")

    def test_requires_authentication(self):
        self.assertEqual(self.client.get("/api/payment-methods/").status_code, 401)

    @patch("reservations.authentication.get_supabase_client")
    def test_create_and_list(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        response = self._create()
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["brand"], "Visa")
        self.assertEqual(response.data["last4"], "4242")
        self.assertEqual(response.data["expiry"], "12/27")  # 표시용 호환 필드
        # 첫 카드는 자동으로 기본 카드.
        self.assertTrue(response.data["is_default"])

        listing = self.client.get("/api/payment-methods/")
        self.assertEqual(len(listing.data), 1)

    @patch("reservations.authentication.get_supabase_client")
    def test_create_with_expiry_string_parses(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        response = self.client.post(
            "/api/payment-methods/",
            {"brand": "Mastercard", "last4": "5555", "expiry": "09/26"},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["expiry_month"], 9)
        self.assertEqual(response.data["expiry_year"], 2026)
        self.assertEqual(response.data["expiry"], "09/26")

    @patch("reservations.authentication.get_supabase_client")
    def test_patch_updates_method(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()
        card_id = self._create().data["id"]

        response = self.client.patch(
            f"/api/payment-methods/{card_id}/",
            {"holder_name": "Amy Kim"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["holder_name"], "Amy Kim")

    @patch("reservations.authentication.get_supabase_client")
    def test_delete_method(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()
        card_id = self._create().data["id"]

        response = self.client.delete(f"/api/payment-methods/{card_id}/")
        self.assertEqual(response.status_code, 204)
        self.assertEqual(PaymentMethod.objects.filter(user="user-a").count(), 0)

    @patch("reservations.authentication.get_supabase_client")
    def test_set_default_switches_default(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        first_id = self._create(last4="1111").data["id"]
        second_id = self._create(last4="2222").data["id"]

        # 첫 카드가 기본, 두 번째는 기본 아님.
        self.assertTrue(PaymentMethod.objects.get(id=first_id).is_default)
        self.assertFalse(PaymentMethod.objects.get(id=second_id).is_default)

        response = self.client.post(
            f"/api/payment-methods/{second_id}/set-default/", {}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["is_default"])
        self.assertTrue(PaymentMethod.objects.get(id=second_id).is_default)
        self.assertFalse(PaymentMethod.objects.get(id=first_id).is_default)

    @patch("reservations.authentication.get_supabase_client")
    def test_delete_default_promotes_remaining(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        first_id = self._create(last4="1111").data["id"]  # default
        second_id = self._create(last4="2222").data["id"]

        self.client.delete(f"/api/payment-methods/{first_id}/")
        # 기본 카드 삭제 후 남은 카드가 기본으로 승격.
        self.assertTrue(PaymentMethod.objects.get(id=second_id).is_default)

    @patch("reservations.authentication.get_supabase_client")
    def test_rejects_sensitive_card_data(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        for payload in (
            {"brand": "Visa", "last4": "4242", "card_number": "4242424242424242"},
            {"brand": "Visa", "last4": "4242", "cvv": "123"},
        ):
            response = self.client.post(
                "/api/payment-methods/", payload, format="json"
            )
            self.assertEqual(response.status_code, 400)

        self.assertEqual(PaymentMethod.objects.filter(user="user-a").count(), 0)

    @patch("reservations.authentication.get_supabase_client")
    def test_payment_methods_owner_scoped(self, mock_client):
        # user-a 카드 생성
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth("token-a")
        a_card_id = self._create().data["id"]

        # user-b 는 자기 목록(빈) 만 보고, a 카드에 접근하면 404.
        mock_client.return_value = fake_supabase_client("token-b", "user-b")
        self._auth("token-b")
        self.assertEqual(len(self.client.get("/api/payment-methods/").data), 0)
        self.assertEqual(
            self.client.patch(
                f"/api/payment-methods/{a_card_id}/",
                {"holder_name": "hacker"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(
            self.client.delete(f"/api/payment-methods/{a_card_id}/").status_code,
            404,
        )


class TransactionTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def _auth(self, token="token-a"):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def _create_tx(self, user="user-a", **overrides):
        body = {
            "title": "Reservation Deposit",
            "description": "1993 Gogi",
            "amount": "30.55",
            "currency": "USD",
            "transaction_type": "reservation",
            "status": "completed",
            "trailing_text": "- 30.55 $",
        }
        body.update(overrides)
        return Transaction.objects.create(user=user, **body)

    def test_requires_authentication(self):
        self.assertEqual(self.client.get("/api/transactions/").status_code, 401)
        self.assertEqual(self.client.post("/api/transactions/", {}).status_code, 401)

    @patch("reservations.authentication.get_supabase_client")
    def test_list_current_user_transactions(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._create_tx(user="user-a", title="A1")
        self._create_tx(user="user-b", title="B1")

        self._auth()
        response = self.client.get("/api/transactions/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["title"], "A1")
        # Flutter 별칭 노출 확인.
        self.assertEqual(response.data[0]["type"], "reservation")
        self.assertEqual(response.data[0]["subtitle"], "1993 Gogi")

    @patch("reservations.authentication.get_supabase_client")
    def test_retrieve_own_transaction(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        tx = self._create_tx(user="user-a")

        self._auth()
        response = self.client.get(f"/api/transactions/{tx.id}/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["id"], tx.id)

    @patch("reservations.authentication.get_supabase_client")
    def test_cannot_retrieve_another_users_transaction(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        tx = self._create_tx(user="user-b")

        self._auth()
        response = self.client.get(f"/api/transactions/{tx.id}/")

        self.assertEqual(response.status_code, 404)

    @patch("reservations.authentication.get_supabase_client")
    def test_create_transaction(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        response = self.client.post(
            "/api/transactions/",
            {
                "title": "Deposit Refund",
                "description": "1993 Gogi",
                "amount": "30.55",
                "transaction_type": "refund",
                "trailing_text": "+ 30.55 $",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["title"], "Deposit Refund")
        self.assertEqual(response.data["transaction_type"], "refund")
        # 소유자는 토큰에서 결정된다.
        tx = Transaction.objects.get(id=response.data["id"])
        self.assertEqual(tx.user, "user-a")

    @patch("reservations.authentication.get_supabase_client")
    def test_transaction_linked_to_reservation(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        reservation = Reservation.objects.create(
            user="user-a",
            restaurant_name="1993 Gogi",
            date="2026-07-01",
            time="19:00",
            party_size=2,
        )

        self._auth()
        response = self.client.post(
            "/api/transactions/",
            {
                "title": "Reservation Deposit",
                "transaction_type": "reservation",
                "reservation": reservation.id,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["reservation"], reservation.id)

    @patch("reservations.authentication.get_supabase_client")
    def test_transaction_linked_to_payment_method_snapshots_card(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        pm = PaymentMethod.objects.create(
            user="user-a", brand="MasterCard", last4="9918"
        )

        self._auth()
        response = self.client.post(
            "/api/transactions/",
            {
                "title": "Reservation Deposit",
                "transaction_type": "reservation",
                "payment_method": pm.id,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["payment_method"], pm.id)
        # 카드 표시 스냅샷이 결제수단에서 자동 복사된다.
        self.assertEqual(response.data["card_brand"], "MasterCard")
        self.assertEqual(response.data["card_last4"], "9918")

    @patch("reservations.authentication.get_supabase_client")
    def test_sensitive_payment_fields_rejected(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._auth()

        for payload in (
            {"title": "x", "card_number": "4242424242424242"},
            {"title": "x", "cvv": "123"},
            {"title": "x", "authorization_secret": "sk_live_abc"},
        ):
            response = self.client.post(
                "/api/transactions/", payload, format="json"
            )
            self.assertEqual(response.status_code, 400)

        self.assertEqual(Transaction.objects.filter(user="user-a").count(), 0)

    @patch("reservations.authentication.get_supabase_client")
    def test_filtering_by_type_and_status(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self._create_tx(user="user-a", transaction_type="reservation", status="completed")
        self._create_tx(user="user-a", transaction_type="refund", status="completed")
        self._create_tx(user="user-a", transaction_type="failed", status="failed")

        self._auth()
        self.assertEqual(
            len(self.client.get("/api/transactions/?transaction_type=refund").data), 1
        )
        # Flutter 별칭 type 으로도 필터.
        self.assertEqual(
            len(self.client.get("/api/transactions/?type=reservation").data), 1
        )
        self.assertEqual(
            len(self.client.get("/api/transactions/?status=failed").data), 1
        )

    @patch("reservations.authentication.get_supabase_client")
    def test_cannot_link_another_users_reservation(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        other_reservation = Reservation.objects.create(
            user="user-b",
            restaurant_name="X",
            date="2026-07-01",
            time="19:00",
            party_size=2,
        )

        self._auth()
        response = self.client.post(
            "/api/transactions/",
            {"title": "x", "reservation": other_reservation.id},
            format="json",
        )

        self.assertEqual(response.status_code, 403)
        self.assertEqual(Transaction.objects.count(), 0)
