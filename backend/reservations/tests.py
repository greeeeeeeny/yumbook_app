from datetime import timedelta
from types import SimpleNamespace
from unittest.mock import patch

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import Reservation, ReservationChangeRequest
from .serializers import ReservationChangeRequestSerializer, ReservationSerializer


def fake_supabase_client(token, user_id):
    class FakeAuth:
        def get_user(self, access_token):
            if access_token != token:
                raise RuntimeError("invalid token")
            return SimpleNamespace(
                user=SimpleNamespace(id=user_id, email=f"{user_id}@example.com")
            )

    return SimpleNamespace(auth=FakeAuth())


def future_date_time(**delta):
    """현재 시각 기준 미래의 (date, time) 문자열을 돌려준다(24h 규칙 테스트용)."""
    target = timezone.now() + timedelta(**delta)
    return target.date().isoformat(), target.time().strftime("%H:%M:%S")


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

    @patch("reservations.authentication.get_supabase_client")
    def test_create_with_restaurant_id_stores_external_restaurant_id(self, mock_client):
        # 클라이언트가 보낸 restaurant_id(String)가 external_restaurant_id에 저장돼야 한다.
        mock_client.return_value = self._supabase_client_for("token-a", "user-a")

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.post(
            "/api/reservations/",
            {
                "restaurant_id": "cafe_um_mock",
                "restaurant_name": "Cafe Um",
                "date": "2026-05-12",
                "time": "18:00",
                "party_size": 2,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["restaurant_id"], "cafe_um_mock")

        reservation = Reservation.objects.get(id=response.data["id"])
        self.assertEqual(reservation.external_restaurant_id, "cafe_um_mock")
        # restaurant FK는 건드리지 않는다.
        self.assertIsNone(reservation.restaurant_id)

    @patch("reservations.authentication.get_supabase_client")
    def test_read_returns_restaurant_id_from_external_restaurant_id(self, mock_client):
        # external_restaurant_id 값이 응답의 restaurant_id로 직렬화돼야 한다.
        mock_client.return_value = self._supabase_client_for("token-a", "user-a")
        Reservation.objects.create(
            user="user-a",
            external_restaurant_id="hongdae_bistro",
            restaurant_name="Hongdae Bistro",
            date="2026-05-12",
            time="18:00",
            party_size=2,
        )

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.get("/api/reservations/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["restaurant_id"], "hongdae_bistro")

    @patch("reservations.authentication.get_supabase_client")
    def test_restaurant_fk_behavior_is_preserved(self, mock_client):
        # 정수 restaurant FK는 restaurant_id 변경과 무관하게 그대로 동작해야 한다.
        from restaurants.models import Restaurant

        mock_client.return_value = self._supabase_client_for("token-a", "user-a")
        restaurant = Restaurant.objects.create(name="FK Diner")

        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        response = self.client.post(
            "/api/reservations/",
            {
                "restaurant": restaurant.id,
                "restaurant_id": "external-ref-1",
                "restaurant_name": "FK Diner",
                "date": "2026-05-12",
                "time": "18:00",
                "party_size": 2,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["restaurant"], restaurant.id)
        self.assertEqual(response.data["restaurant_id"], "external-ref-1")

        reservation = Reservation.objects.get(id=response.data["id"])
        self.assertEqual(reservation.restaurant_id, restaurant.id)
        self.assertEqual(reservation.external_restaurant_id, "external-ref-1")

    def _supabase_client_for(self, token, user_id):
        class FakeAuth:
            def get_user(self, access_token):
                if access_token != token:
                    raise RuntimeError("invalid token")
                return SimpleNamespace(
                    user=SimpleNamespace(id=user_id, email=f"{user_id}@example.com")
                )

        return SimpleNamespace(auth=FakeAuth())


class ReservationSerializerTests(TestCase):
    """Phase 1: 직렬화 레벨(HTTP 없이) 테스트."""

    def test_serializer_exposes_lifecycle_fields(self):
        reservation = Reservation.objects.create(
            user="user-a",
            restaurant_name="A",
            date="2026-05-12",
            time="18:00",
            party_size=2,
        )

        data = ReservationSerializer(reservation).data

        self.assertIn("status", data)
        self.assertIn("cancel_reason", data)
        self.assertIn("payment_snapshot", data)
        self.assertIn("pending_change", data)
        # 기본 상태는 pending, 변경 요청 없음.
        self.assertEqual(data["status"], Reservation.Status.PENDING)
        self.assertEqual(data["cancel_reason"], "")
        self.assertIsNone(data["pending_change"])

    def test_payment_snapshot_round_trips(self):
        snapshot = {
            "service_fee_per_guest": 5.0,
            "deposit_amount": 20.0,
            "currency": "USD",
            "processing_fee_rate": 0.04,
        }
        reservation = Reservation.objects.create(
            user="user-a",
            restaurant_name="A",
            date="2026-05-12",
            time="18:00",
            party_size=2,
            payment_snapshot=snapshot,
        )

        data = ReservationSerializer(reservation).data
        self.assertEqual(data["payment_snapshot"], snapshot)

    def test_pending_change_is_serialized(self):
        reservation = Reservation.objects.create(
            user="user-a",
            restaurant_name="A",
            date="2026-05-12",
            time="18:00",
            party_size=2,
        )
        ReservationChangeRequest.objects.create(
            reservation=reservation,
            requested_date="2026-05-20",
            requested_time="20:00",
            requested_party_size=4,
        )

        pending = ReservationSerializer(reservation).data["pending_change"]
        self.assertIsNotNone(pending)
        self.assertEqual(pending["requested_party_size"], 4)
        self.assertEqual(pending["status"], ReservationChangeRequest.Status.PENDING)

    def test_change_request_serializer_fields(self):
        reservation = Reservation.objects.create(
            user="user-a",
            restaurant_name="A",
            date="2026-05-12",
            time="18:00",
            party_size=2,
        )
        change = ReservationChangeRequest.objects.create(
            reservation=reservation,
            requested_date="2026-05-20",
            requested_time="20:00",
            requested_party_size=4,
        )

        data = ReservationChangeRequestSerializer(change).data
        self.assertEqual(
            set(data.keys()),
            {
                "id",
                "requested_date",
                "requested_time",
                "requested_party_size",
                "status",
                "requested_at",
                "resolved_at",
            },
        )


class ReservationLifecycleApiTests(TestCase):
    """Phase 1: cancel / request-change / approve-change / reject-change 엔드포인트."""

    def setUp(self):
        self.client = APIClient()

    def _auth(self, token="token-a", user_id="user-a"):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def _create_reservation(self, user="user-a", **overrides):
        defaults = dict(
            user=user,
            restaurant_name="A",
            date="2026-05-12",
            time="18:00",
            party_size=2,
            status=Reservation.Status.CONFIRMED,
        )
        defaults.update(overrides)
        return Reservation.objects.create(**defaults)

    # -------- cancel --------

    @patch("reservations.authentication.get_supabase_client")
    def test_cancel_sets_status_and_reason(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        reservation = self._create_reservation()

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/cancel/",
            {"reason": "change of plans"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["status"], Reservation.Status.CANCELLED)
        self.assertEqual(response.data["cancel_reason"], "change of plans")

        reservation.refresh_from_db()
        self.assertEqual(reservation.status, Reservation.Status.CANCELLED)
        self.assertEqual(reservation.cancel_reason, "change of plans")

    @patch("reservations.authentication.get_supabase_client")
    def test_cancel_rejects_already_cancelled(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        reservation = self._create_reservation(status=Reservation.Status.CANCELLED)

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/cancel/", {}, format="json"
        )

        self.assertEqual(response.status_code, 400)

    @patch("reservations.authentication.get_supabase_client")
    def test_cancel_scoped_to_owner(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        reservation = self._create_reservation(user="user-b")

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/cancel/", {}, format="json"
        )

        self.assertEqual(response.status_code, 404)

    # -------- request-change --------

    @patch("reservations.authentication.get_supabase_client")
    def test_request_change_creates_pending(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        date, time = future_date_time(days=30)
        reservation = self._create_reservation(date=date, time=time)
        new_date, new_time = future_date_time(days=31)

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/request-change/",
            {
                "requested_date": new_date,
                "requested_time": new_time,
                "requested_party_size": 4,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertIsNotNone(response.data["pending_change"])
        self.assertEqual(response.data["pending_change"]["requested_party_size"], 4)
        self.assertEqual(reservation.change_requests.count(), 1)

    @patch("reservations.authentication.get_supabase_client")
    def test_request_change_blocked_within_24h(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        date, time = future_date_time(hours=2)  # 24시간 미만
        reservation = self._create_reservation(date=date, time=time)
        new_date, new_time = future_date_time(days=30)

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/request-change/",
            {
                "requested_date": new_date,
                "requested_time": new_time,
                "requested_party_size": 4,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(reservation.change_requests.count(), 0)

    @patch("reservations.authentication.get_supabase_client")
    def test_request_change_blocked_when_pending_exists(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        date, time = future_date_time(days=30)
        reservation = self._create_reservation(date=date, time=time)
        ReservationChangeRequest.objects.create(
            reservation=reservation,
            requested_date=date,
            requested_time=time,
            requested_party_size=3,
        )
        new_date, new_time = future_date_time(days=31)

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/request-change/",
            {
                "requested_date": new_date,
                "requested_time": new_time,
                "requested_party_size": 4,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(reservation.change_requests.count(), 1)

    @patch("reservations.authentication.get_supabase_client")
    def test_request_change_validates_input(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        date, time = future_date_time(days=30)
        reservation = self._create_reservation(date=date, time=time)

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/request-change/",
            {"requested_party_size": 0},  # 누락 + 최소값 위반
            format="json",
        )

        self.assertEqual(response.status_code, 400)

    # -------- approve / reject --------

    @patch("reservations.authentication.get_supabase_client")
    def test_approve_change_applies_to_reservation(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        date, time = future_date_time(days=30)
        reservation = self._create_reservation(date=date, time=time)
        change = ReservationChangeRequest.objects.create(
            reservation=reservation,
            requested_date="2026-09-09",
            requested_time="20:30:00",
            requested_party_size=5,
        )

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/approve-change/", {}, format="json"
        )

        self.assertEqual(response.status_code, 200)
        reservation.refresh_from_db()
        change.refresh_from_db()
        self.assertEqual(reservation.date.isoformat(), "2026-09-09")
        self.assertEqual(reservation.party_size, 5)
        self.assertEqual(change.status, ReservationChangeRequest.Status.APPROVED)
        self.assertIsNotNone(change.resolved_at)

    @patch("reservations.authentication.get_supabase_client")
    def test_approve_change_without_pending_returns_400(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        reservation = self._create_reservation()

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/approve-change/", {}, format="json"
        )

        self.assertEqual(response.status_code, 400)

    @patch("reservations.authentication.get_supabase_client")
    def test_reject_change_keeps_reservation(self, mock_client):
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        reservation = self._create_reservation(party_size=2)
        change = ReservationChangeRequest.objects.create(
            reservation=reservation,
            requested_date="2026-09-09",
            requested_time="20:30:00",
            requested_party_size=5,
        )

        self._auth()
        response = self.client.post(
            f"/api/reservations/{reservation.id}/reject-change/", {}, format="json"
        )

        self.assertEqual(response.status_code, 200)
        reservation.refresh_from_db()
        change.refresh_from_db()
        # 예약 원본 유지
        self.assertEqual(reservation.party_size, 2)
        self.assertEqual(reservation.date.isoformat(), "2026-05-12")
        self.assertEqual(change.status, ReservationChangeRequest.Status.REJECTED)
        self.assertIsNotNone(change.resolved_at)

    # -------- contract preservation --------

    @patch("reservations.authentication.get_supabase_client")
    def test_create_defaults_to_pending_and_preserves_flutter_payload(
        self, mock_client
    ):
        # Flutter가 보내는 정확한 페이로드만으로 생성되며 status 기본값은 pending.
        mock_client.return_value = fake_supabase_client("token-a", "user-a")

        self._auth()
        response = self.client.post(
            "/api/reservations/",
            {
                "restaurant_id": "cafe_um_mock",
                "restaurant_name": "Cafe Um",
                "date": "2026-05-12",
                "time": "18:00",
                "party_size": 2,
                "guest_name": "Youri",
                "seat_type": "Table",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["status"], Reservation.Status.PENDING)
        self.assertEqual(response.data["restaurant_id"], "cafe_um_mock")
        self.assertEqual(response.data["confirmation_code"][:9], "Yumbook-B")


class AvailabilityEnforcementTests(TestCase):
    """Phase 5.1: yumbook_admin 좌석/재고/휴무일 데이터의 예약 생성 강제.

    admin_* 테이블은 로컬 sqlite 부트스트랩(마이그레이션 0006)으로 생성된
    읽기 전용 매핑이다. 설정이 없으면 fail-open.
    """

    def setUp(self):
        from restaurants.models import (
            AdminRestaurantExceptionDay,
            AdminRestaurantSeatInventory,
            AdminRestaurantSeatType,
            Restaurant,
        )

        self.AdminSeatType = AdminRestaurantSeatType
        self.AdminInventory = AdminRestaurantSeatInventory
        self.AdminExceptionDay = AdminRestaurantExceptionDay

        patcher = patch("reservations.authentication.get_supabase_client")
        mock_client = patcher.start()
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self.addCleanup(patcher.stop)

        self.client = APIClient()
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")
        self.restaurant = Restaurant.objects.create(name="Availability Diner")

    def post_reservation(self, **overrides):
        payload = {
            "restaurant": self.restaurant.id,
            "restaurant_name": self.restaurant.name,
            "date": "2026-10-01",
            "time": "18:00",
            "party_size": 2,
            "guest_name": "Guest",
            "seat_type": "table",
        }
        payload.update(overrides)
        return self.client.post("/api/reservations/", payload, format="json")

    def make_seat_type(self, code="table", **kwargs):
        return self.AdminSeatType.objects.create(
            restaurant=self.restaurant, code=code, **kwargs
        )

    def make_inventory(self, seat_type, capacity, slot_time="18:00", **kwargs):
        from datetime import time as time_cls

        parsed = None
        if slot_time is not None:
            hour, minute = (int(p) for p in slot_time.split(":"))
            parsed = time_cls(hour, minute)
        return self.AdminInventory.objects.create(
            restaurant=self.restaurant,
            seat_type=seat_type,
            date="2026-10-01",
            time=parsed,
            capacity=capacity,
            **kwargs,
        )

    def make_existing_reservation(self, status_value, seat_type="table", time_str="18:00"):
        return Reservation.objects.create(
            user="someone-else",
            restaurant=self.restaurant,
            restaurant_name=self.restaurant.name,
            date="2026-10-01",
            time=time_str,
            party_size=2,
            seat_type=seat_type,
            status=status_value,
        )

    # ----- fail-open 기본 동작 -----

    def test_reservation_succeeds_with_no_configuration(self):
        response = self.post_reservation()
        self.assertEqual(response.status_code, 201)

    def test_no_inventory_row_is_fail_open(self):
        self.make_seat_type("table")
        response = self.post_reservation(seat_type="table")
        self.assertEqual(response.status_code, 201)

    # ----- 휴무일 -----

    def test_blocked_on_closed_exception_day(self):
        self.AdminExceptionDay.objects.create(
            restaurant=self.restaurant, date="2026-10-01", is_closed=True
        )
        response = self.post_reservation()
        self.assertEqual(response.status_code, 400)
        self.assertIn("closed", str(response.data).lower())
        self.assertEqual(Reservation.objects.count(), 0)

    def test_blocked_outside_special_hours(self):
        from datetime import time as time_cls

        self.AdminExceptionDay.objects.create(
            restaurant=self.restaurant,
            date="2026-10-01",
            is_closed=False,
            open_time=time_cls(11, 0),
            close_time=time_cls(15, 0),
        )
        blocked = self.post_reservation(time="18:00")
        self.assertEqual(blocked.status_code, 400)
        self.assertIn("special opening hours", str(blocked.data))
        allowed = self.post_reservation(time="12:00")
        self.assertEqual(allowed.status_code, 201)

    # ----- 좌석 종류 -----

    def test_invalid_seat_type_blocked_when_active_types_exist(self):
        self.make_seat_type("table")
        response = self.post_reservation(seat_type="helipad")
        self.assertEqual(response.status_code, 400)
        self.assertIn("Invalid seat type", str(response.data))

    def test_valid_seat_type_accepted_case_insensitively(self):
        self.make_seat_type("table")
        response = self.post_reservation(seat_type="TABLE")
        self.assertEqual(response.status_code, 201)

    def test_inactive_seat_type_rejected(self):
        self.make_seat_type("table")
        self.make_seat_type("smoking", is_active=False)
        response = self.post_reservation(seat_type="smoking")
        self.assertEqual(response.status_code, 400)

    # ----- 재고 -----

    def test_blocked_when_capacity_full(self):
        seat_type = self.make_seat_type("table")
        self.make_inventory(seat_type, capacity=2)
        self.make_existing_reservation("pending")
        self.make_existing_reservation("confirmed")
        response = self.post_reservation()
        self.assertEqual(response.status_code, 400)
        self.assertIn("fully booked", str(response.data))
        self.assertEqual(Reservation.objects.count(), 2)

    def test_pending_and_confirmed_consume_capacity(self):
        seat_type = self.make_seat_type("table")
        self.make_inventory(seat_type, capacity=1)
        self.make_existing_reservation("pending")
        self.assertEqual(self.post_reservation().status_code, 400)

    def test_terminal_statuses_do_not_consume_capacity(self):
        seat_type = self.make_seat_type("table")
        self.make_inventory(seat_type, capacity=1)
        for status_value in ("cancelled", "rejected", "completed"):
            self.make_existing_reservation(status_value)
        response = self.post_reservation()
        self.assertEqual(response.status_code, 201)

    def test_all_day_inventory_row_applies_to_any_time(self):
        seat_type = self.make_seat_type("table")
        self.make_inventory(seat_type, capacity=1, slot_time=None)
        self.make_existing_reservation("confirmed", time_str="12:00")
        response = self.post_reservation(time="20:00")
        self.assertEqual(response.status_code, 400)

    def test_other_time_slot_not_affected_by_full_slot(self):
        seat_type = self.make_seat_type("table")
        self.make_inventory(seat_type, capacity=1, slot_time="18:00")
        self.make_existing_reservation("confirmed", time_str="18:00")
        response = self.post_reservation(time="20:00")
        self.assertEqual(response.status_code, 201)

    # ----- 과거 데이터 보존 -----

    def test_historical_free_text_seat_type_still_serializes(self):
        self.make_seat_type("table")  # 이제 좌석 종류가 강제되는 식당
        old = self.make_existing_reservation("completed", seat_type="Window VIP (old)")
        old.user = "user-a"
        old.save(update_fields=["user"])
        response = self.client.get("/api/reservations/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data[0]["seat_type"], "Window VIP (old)")


class AvailabilityEndpointTests(TestCase):
    """GET /api/restaurants/{id}/availability/ (공개 읽기)."""

    def setUp(self):
        from restaurants.models import (
            AdminRestaurantExceptionDay,
            AdminRestaurantMeta,
            AdminRestaurantSeatInventory,
            AdminRestaurantSeatType,
            Restaurant,
        )

        self.AdminSeatType = AdminRestaurantSeatType
        self.AdminInventory = AdminRestaurantSeatInventory
        self.AdminExceptionDay = AdminRestaurantExceptionDay
        self.AdminMeta = AdminRestaurantMeta
        self.client = APIClient()
        self.restaurant = Restaurant.objects.create(name="Availability Diner")
        self.url = f"/api/restaurants/{self.restaurant.id}/availability/"

    def test_requires_date_param(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 400)

    def test_closed_day_reports_closed_with_no_slots(self):
        self.AdminExceptionDay.objects.create(
            restaurant=self.restaurant, date="2026-10-01", is_closed=True
        )
        response = self.client.get(self.url, {"date": "2026-10-01"})
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["closed"])
        self.assertEqual(response.data["slots"], [])

    def test_slots_report_remaining_capacity(self):
        from datetime import time as time_cls

        seat_type = self.AdminSeatType.objects.create(
            restaurant=self.restaurant, code="table", name="Table"
        )
        self.AdminInventory.objects.create(
            restaurant=self.restaurant,
            seat_type=seat_type,
            date="2026-10-01",
            time=time_cls(18, 0),
            capacity=4,
        )
        Reservation.objects.create(
            user="u1",
            restaurant=self.restaurant,
            restaurant_name=self.restaurant.name,
            date="2026-10-01",
            time="18:00",
            party_size=2,
            seat_type="table",
            status="confirmed",
        )
        response = self.client.get(self.url, {"date": "2026-10-01"})
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["closed"])
        self.assertEqual(
            response.data["seat_types"], [{"code": "table", "name": "Table"}]
        )
        slot = response.data["slots"][0]
        self.assertEqual(slot["capacity"], 4)
        self.assertEqual(slot["booked"], 1)
        self.assertEqual(slot["remaining"], 3)

    def test_hidden_restaurant_availability_is_404(self):
        self.AdminMeta.objects.create(restaurant=self.restaurant, status="archived")
        response = self.client.get(self.url, {"date": "2026-10-01"})
        self.assertEqual(response.status_code, 404)


class ChangeApprovalAvailabilityTests(TestCase):
    """Phase 5.2: 변경 승인/예약 수정 경로도 가용성 규칙을 따른다."""

    def setUp(self):
        from restaurants.models import (
            AdminRestaurantExceptionDay,
            AdminRestaurantSeatInventory,
            AdminRestaurantSeatType,
            Restaurant,
        )

        self.AdminSeatType = AdminRestaurantSeatType
        self.AdminInventory = AdminRestaurantSeatInventory
        self.AdminExceptionDay = AdminRestaurantExceptionDay

        patcher = patch("reservations.authentication.get_supabase_client")
        mock_client = patcher.start()
        mock_client.return_value = fake_supabase_client("token-a", "user-a")
        self.addCleanup(patcher.stop)
        self.client = APIClient()
        self.client.credentials(HTTP_AUTHORIZATION="Bearer token-a")

        self.restaurant = Restaurant.objects.create(name="Consistency Diner")
        self.table = self.AdminSeatType.objects.create(
            restaurant=self.restaurant, code="table"
        )

    def make_reservation(self, user="user-a", **overrides):
        from datetime import time as time_cls

        defaults = dict(
            user=user,
            restaurant=self.restaurant,
            restaurant_name=self.restaurant.name,
            date="2026-10-01",
            time=time_cls(18, 0),
            party_size=2,
            seat_type="table",
            status=Reservation.Status.CONFIRMED,
        )
        defaults.update(overrides)
        return Reservation.objects.create(**defaults)

    def make_change(self, reservation, req_date="2026-10-02", req_time="19:00"):
        from datetime import time as time_cls

        hour, minute = (int(p) for p in req_time.split(":"))
        return ReservationChangeRequest.objects.create(
            reservation=reservation,
            requested_date=req_date,
            requested_time=time_cls(hour, minute),
            requested_party_size=4,
        )

    def inventory(self, capacity, on="2026-10-02", at="19:00"):
        from datetime import time as time_cls

        hour, minute = (int(p) for p in at.split(":"))
        return self.AdminInventory.objects.create(
            restaurant=self.restaurant,
            seat_type=self.table,
            date=on,
            time=time_cls(hour, minute),
            capacity=capacity,
        )

    def approve(self, reservation):
        return self.client.post(f"/api/reservations/{reservation.id}/approve-change/")

    def test_approve_blocked_on_closed_day(self):
        self.AdminExceptionDay.objects.create(
            restaurant=self.restaurant, date="2026-10-02", is_closed=True
        )
        reservation = self.make_reservation()
        change = self.make_change(reservation)
        response = self.approve(reservation)
        self.assertEqual(response.status_code, 400)
        reservation.refresh_from_db()
        change.refresh_from_db()
        self.assertEqual(reservation.date.isoformat(), "2026-10-01")
        self.assertEqual(change.status, ReservationChangeRequest.Status.PENDING)

    def test_approve_blocked_when_capacity_full(self):
        from datetime import time as time_cls

        self.inventory(capacity=1)
        self.make_reservation(
            user="someone-else", date="2026-10-02", time=time_cls(19, 0)
        )
        reservation = self.make_reservation()
        change = self.make_change(reservation)
        response = self.approve(reservation)
        self.assertEqual(response.status_code, 400)
        self.assertIn("fully booked", str(response.data))
        change.refresh_from_db()
        self.assertEqual(change.status, ReservationChangeRequest.Status.PENDING)

    def test_approve_excludes_existing_reservation_from_capacity(self):
        from datetime import time as time_cls

        # 예약이 이미 요청 슬롯에 있고 capacity=1 이어도, 자기 자신은
        # 수량에서 제외되므로 party_size 변경 승인은 성공해야 한다.
        self.inventory(capacity=1, on="2026-10-01", at="18:00")
        reservation = self.make_reservation(time=time_cls(18, 0))
        change = self.make_change(reservation, req_date="2026-10-01", req_time="18:00")
        response = self.approve(reservation)
        self.assertEqual(response.status_code, 200)
        change.refresh_from_db()
        reservation.refresh_from_db()
        self.assertEqual(change.status, ReservationChangeRequest.Status.APPROVED)
        self.assertEqual(reservation.party_size, 4)

    def test_approve_blocked_for_invalid_seat_type(self):
        # 활성 좌석 종류가 있는 식당에서 예약의 seat_type 이 유효하지
        # 않으면(과거 free-text) 승인 시점에 차단된다.
        reservation = self.make_reservation(seat_type="Old Window Text")
        self.make_change(reservation)
        response = self.approve(reservation)
        self.assertEqual(response.status_code, 400)
        self.assertIn("Invalid seat type", str(response.data))

    def test_guest_name_only_update_skips_availability(self):
        from datetime import time as time_cls

        # 슬롯이 (역사적으로) 초과 예약돼 있어도 guest_name 만 바꾸는
        # 수정은 가용성 검증을 타지 않는다.
        self.inventory(capacity=1, on="2026-10-01", at="18:00")
        self.make_reservation(user="someone-else", time=time_cls(18, 0))
        mine = self.make_reservation(time=time_cls(18, 0))
        response = self.client.patch(
            f"/api/reservations/{mine.id}/", {"guest_name": "Renamed"}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        mine.refresh_from_db()
        self.assertEqual(mine.guest_name, "Renamed")

    def test_owner_update_moving_to_full_slot_is_blocked(self):
        from datetime import time as time_cls

        self.inventory(capacity=1)
        self.make_reservation(
            user="someone-else", date="2026-10-02", time=time_cls(19, 0)
        )
        mine = self.make_reservation()
        response = self.client.patch(
            f"/api/reservations/{mine.id}/",
            {"date": "2026-10-02", "time": "19:00"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("fully booked", str(response.data))
        mine.refresh_from_db()
        self.assertEqual(mine.date.isoformat(), "2026-10-01")

    def test_owner_update_same_slot_excludes_self(self):
        from datetime import time as time_cls

        self.inventory(capacity=1, on="2026-10-01", at="18:00")
        mine = self.make_reservation(time=time_cls(18, 0))
        response = self.client.patch(
            f"/api/reservations/{mine.id}/", {"party_size": 5}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        mine.refresh_from_db()
        self.assertEqual(mine.party_size, 5)
