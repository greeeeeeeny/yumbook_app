from types import SimpleNamespace
from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from .models import AdminRestaurantMeta, Region, Restaurant, RestaurantPolicy


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
        self.insadong = Region.objects.create(
            slug="insadong", name="INSADONG", display_order=1
        )
        self.hongdae = Region.objects.create(
            slug="hongdae", name="HONGDAE", display_order=0
        )
        self.r1 = Restaurant.objects.create(
            name="Cafe Um",
            location="Cheonan",
            description="Cozy brunch cafe.",
            tags=["Brunch", "Cafe"],
            raw_category="Brunch Cafe",
            region=self.insadong,
        )
        self.r2 = Restaurant.objects.create(
            name="Sourdough Pizza Lab",
            location="Seoul",
            description="Authentic sourdough pizza.",
            tags=["Italian"],
            raw_category="Italian",
            region=self.hongdae,
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

    def test_filter_by_region(self):
        response = self.client.get("/api/restaurants/", {"region": "hongdae"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Sourdough Pizza Lab")
        self.assertEqual(response.data[0]["region"], "hongdae")

    def test_filter_by_region_is_case_insensitive(self):
        response = self.client.get("/api/restaurants/", {"region": "INSADONG"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["region"], "insadong")

    def test_filter_by_region_empty_returns_no_results(self):
        response = self.client.get("/api/restaurants/", {"region": "itaewon"})

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 0)


class RestaurantExploreFilterTests(TestCase):
    """Phase 5: Explore 화면용 cuisine/price/bbox/q/정렬 필터."""

    def setUp(self):
        self.client = APIClient()
        self.hongdae = Region.objects.create(slug="hongdae", name="HONGDAE")
        self.gangnam = Region.objects.create(slug="gangnam", name="GANGNAM")

        # 서울 중심 근처
        self.gogi = Restaurant.objects.create(
            name="1993 Gogi",
            location="Gangnam",
            description="Premium Korean BBQ.",
            raw_category="Korean BBQ",
            region=self.gangnam,
            lat="37.4979",
            lng="127.0276",
            price_level=4,
            rating="4.80",
        )
        self.pizza = Restaurant.objects.create(
            name="Sourdough Pizza Lab",
            location="Hongdae",
            description="Authentic sourdough pizza.",
            raw_category="Italian",
            region=self.hongdae,
            lat="37.5563",
            lng="126.9230",
            price_level=2,
            rating="4.20",
        )
        # 좌표 없는 식당(bbox 필터 시 크래시 없이 제외돼야 함)
        self.nolatlng = Restaurant.objects.create(
            name="Ghost Kitchen",
            location="Unknown",
            raw_category="Fusion",
            price_level=1,
        )

    def test_existing_list_still_works(self):
        response = self.client.get("/api/restaurants/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 3)

    def test_region_filter_still_works(self):
        response = self.client.get("/api/restaurants/", {"region": "gangnam"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "1993 Gogi")

    def test_cuisine_filter_matches_raw_category(self):
        # "Korean BBQ"는 cuisine=Korean에 부분 일치해야 한다.
        response = self.client.get("/api/restaurants/", {"cuisine": "Korean"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "1993 Gogi")

    def test_price_exact_filter(self):
        response = self.client.get("/api/restaurants/", {"price": "4"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "1993 Gogi")

    def test_price_range_filter(self):
        response = self.client.get(
            "/api/restaurants/", {"min_price": "1", "max_price": "2"}
        )
        self.assertEqual(response.status_code, 200)
        names = {r["name"] for r in response.data}
        self.assertEqual(names, {"Sourdough Pizza Lab", "Ghost Kitchen"})

    def test_invalid_price_returns_400(self):
        response = self.client.get("/api/restaurants/", {"price": "cheap"})
        self.assertEqual(response.status_code, 400)

    def test_bbox_filter(self):
        # 강남만 포함하는 박스(min_lng,min_lat,max_lng,max_lat)
        response = self.client.get(
            "/api/restaurants/", {"bbox": "127.0,37.4,127.1,37.52"}
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "1993 Gogi")

    def test_bbox_excludes_restaurants_without_coordinates(self):
        # 서울 전역을 덮는 큰 박스 → 좌표 있는 2곳만(Ghost Kitchen 제외)
        response = self.client.get(
            "/api/restaurants/", {"bbox": "126.0,37.0,128.0,38.0"}
        )
        self.assertEqual(response.status_code, 200)
        names = {r["name"] for r in response.data}
        self.assertEqual(names, {"1993 Gogi", "Sourdough Pizza Lab"})

    def test_invalid_bbox_returns_400(self):
        for bad in ("1,2,3", "a,b,c,d", "127.1,37.5,127.0,37.4"):
            response = self.client.get("/api/restaurants/", {"bbox": bad})
            self.assertEqual(response.status_code, 400, bad)

    def test_q_searches_category(self):
        response = self.client.get("/api/restaurants/", {"q": "fusion"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Ghost Kitchen")

    def test_combined_cuisine_and_price(self):
        # Italian + price 2 → 피자 1곳
        response = self.client.get(
            "/api/restaurants/", {"cuisine": "Italian", "price": "2"}
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Sourdough Pizza Lab")

    def test_ordering_by_rating_desc(self):
        response = self.client.get("/api/restaurants/", {"ordering": "-rating"})
        self.assertEqual(response.status_code, 200)
        ratings = [float(r["rating"]) for r in response.data]
        self.assertEqual(ratings, sorted(ratings, reverse=True))

    def test_unknown_filter_is_ignored(self):
        response = self.client.get("/api/restaurants/", {"bogus": "whatever"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 3)


class RegionReadTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.hongdae = Region.objects.create(
            slug="hongdae", name="HONGDAE", display_order=0
        )
        self.insadong = Region.objects.create(
            slug="insadong", name="INSADONG", display_order=1
        )
        # 비활성 지역은 목록에서 제외되어야 한다.
        self.itaewon = Region.objects.create(
            slug="itaewon", name="ITAEWON", display_order=2, is_active=False
        )

    def test_list_is_public(self):
        response = self.client.get("/api/regions/")
        self.assertEqual(response.status_code, 200)

    def test_list_returns_only_active_regions(self):
        response = self.client.get("/api/regions/")

        self.assertEqual(response.status_code, 200)
        slugs = [r["slug"] for r in response.data]
        self.assertEqual(slugs, ["hongdae", "insadong"])
        self.assertNotIn("itaewon", slugs)

    def test_list_is_ordered_by_display_order(self):
        response = self.client.get("/api/regions/")

        self.assertEqual(response.status_code, 200)
        orders = [r["display_order"] for r in response.data]
        self.assertEqual(orders, sorted(orders))

    def test_serializer_fields(self):
        response = self.client.get("/api/regions/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            set(response.data[0].keys()),
            {"id", "slug", "name", "display_order", "is_active"},
        )


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


class AdminVisibilityTests(TestCase):
    """yumbook_admin 의 admin_restaurant_meta 노출 상태를 사용자 API 가 존중하는지 검증.

    규칙: meta row 없음/active → 노출, draft/inactive/archived → 숨김.
    """

    def setUp(self):
        self.client = APIClient()
        self.region = Region.objects.create(slug="hongdae", name="HONGDAE")
        # meta row 가 아예 없는 식당 — 노출되어야 한다.
        self.no_meta = Restaurant.objects.create(
            name="No Meta Diner", region=self.region, description="hidden-keyword"
        )
        # status=active meta — 노출되어야 한다.
        self.active = Restaurant.objects.create(
            name="Active Diner", region=self.region
        )
        AdminRestaurantMeta.objects.create(
            restaurant=self.active, status=AdminRestaurantMeta.STATUS_ACTIVE
        )
        # 숨김 상태 3종.
        self.hidden = {}
        for hidden_status in AdminRestaurantMeta.HIDDEN_STATUSES:
            restaurant = Restaurant.objects.create(
                name=f"{hidden_status.title()} Diner",
                region=self.region,
                description="hidden-keyword",
            )
            AdminRestaurantMeta.objects.create(
                restaurant=restaurant, status=hidden_status
            )
            self.hidden[hidden_status] = restaurant

    def _names(self, response):
        return {row["name"] for row in response.data}

    def test_list_excludes_inactive_and_archived(self):
        response = self.client.get("/api/restaurants/")
        self.assertEqual(response.status_code, 200)
        names = self._names(response)
        self.assertIn("No Meta Diner", names)
        self.assertIn("Active Diner", names)
        self.assertNotIn("Inactive Diner", names)
        self.assertNotIn("Archived Diner", names)

    def test_draft_hidden_from_user_facing_list(self):
        response = self.client.get("/api/restaurants/")
        self.assertNotIn("Draft Diner", self._names(response))

    def test_search_excludes_hidden_restaurants(self):
        # q 검색이 숨김 식당의 이름/설명에 매칭되어도 결과에 나오면 안 된다.
        response = self.client.get("/api/restaurants/", {"q": "hidden-keyword"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self._names(response), {"No Meta Diner"})

    def test_region_filter_excludes_hidden_restaurants(self):
        response = self.client.get("/api/restaurants/", {"region": "hongdae"})
        names = self._names(response)
        self.assertEqual(names, {"No Meta Diner", "Active Diner"})

    def test_retrieve_hidden_restaurant_returns_404(self):
        for restaurant in self.hidden.values():
            response = self.client.get(f"/api/restaurants/{restaurant.id}/")
            self.assertEqual(response.status_code, 404)

    def test_retrieve_visible_restaurants_ok(self):
        for restaurant in (self.no_meta, self.active):
            response = self.client.get(f"/api/restaurants/{restaurant.id}/")
            self.assertEqual(response.status_code, 200)
