from decimal import Decimal

from django.db import models


class Region(models.Model):
    # 홈 화면 지역 탭. slug는 소문자 키, name은 탭 라벨.
    # 예: slug "hongdae" / name "HONGDAE"
    slug = models.SlugField(max_length=50, unique=True)
    name = models.CharField(max_length=100)
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["display_order", "name"]

    def __str__(self):
        return self.name


class Restaurant(models.Model):
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    image_url = models.URLField(max_length=500, blank=True)
    tags = models.JSONField(default=list, blank=True)

    raw_category = models.CharField(max_length=100, blank=True)

    # 홈 화면 지역 탭 필터용 FK. Region.slug 기준으로 필터링한다.
    # 예: "insadong", "hongdae", "itaewon", "seongsu", "gangnam"
    region = models.ForeignKey(
        "Region",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="restaurants",
    )

    lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    # Explore 화면 가격 필터(₩~₩₩₩₩). Flutter PriceLevel w1~w4 == 1~4.
    price_level = models.PositiveSmallIntegerField(null=True, blank=True)

    rating = models.DecimalField(max_digits=3, decimal_places=2, default=Decimal("0"))
    review_count = models.PositiveIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]
        indexes = [
            models.Index(fields=["location"]),
            models.Index(fields=["raw_category"]),
        ]

    def __str__(self):
        return self.name


class RestaurantImage(models.Model):
    # 식당당 다중 이미지. Postgres에는 URL/스토리지 경로만 저장한다(바이너리 X).
    restaurant = models.ForeignKey(
        "Restaurant",
        on_delete=models.CASCADE,
        related_name="images",
    )
    image_url = models.URLField(max_length=500, blank=True)
    storage_path = models.CharField(max_length=500, blank=True)
    is_primary = models.BooleanField(default=False)
    sort_order = models.PositiveIntegerField(default=0)
    alt_text = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-is_primary", "sort_order", "id"]
        indexes = [
            models.Index(fields=["restaurant", "is_primary"]),
        ]

    def __str__(self):
        return f"Image({self.restaurant_id}, primary={self.is_primary})"


class RestaurantPolicy(models.Model):
    class DepositType(models.TextChoices):
        NONE = "none", "None"
        PER_GUEST = "perGuest", "Per guest"
        FIXED = "fixed", "Fixed"

    restaurant = models.OneToOneField(
        Restaurant,
        on_delete=models.CASCADE,
        related_name="policy",
    )
    deposit_type = models.CharField(
        max_length=20,
        choices=DepositType.choices,
        default=DepositType.NONE,
    )
    deposit_amount = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("0")
    )
    free_cancel_days = models.PositiveIntegerField(default=30)
    refund_within_window_rate = models.DecimalField(
        max_digits=3, decimal_places=2, default=Decimal("1.00")
    )
    refund_outside_window_rate = models.DecimalField(
        max_digits=3, decimal_places=2, default=Decimal("0.00")
    )
    no_show_refund_rate = models.DecimalField(
        max_digits=3, decimal_places=2, default=Decimal("0.00")
    )
    restaurant_cancel_refund_rate = models.DecimalField(
        max_digits=3, decimal_places=2, default=Decimal("1.00")
    )

    def __str__(self):
        return f"Policy({self.restaurant_id})"


class AdminRestaurantMeta(models.Model):
    """yumbook_admin 이 소유한 admin_restaurant_meta 테이블의 읽기 전용 매핑.

    관리자 CMS(yumbook_admin)가 식당의 노출 상태를 이 테이블에 기록한다.
    이 앱에서는 절대 쓰지 않는다(READ ONLY) — 스키마 소유권은 yumbook_admin 에 있다.

    노출 규칙:
        - meta row 없음 또는 status == "active"  → 사용자 앱에 노출
        - draft / inactive / archived            → 사용자 앱 목록/검색/상세에서 숨김

    매핑은 필요한 컬럼만 부분 매핑한다(updated_by 등 admin 전용 컬럼 제외).
    로컬 sqlite 개발/테스트 환경에는 이 테이블이 없으므로 마이그레이션
    0005 가 sqlite 에서만 물리 테이블을 생성한다(Postgres 에서는 no-op).
    """

    STATUS_DRAFT = "draft"
    STATUS_ACTIVE = "active"
    STATUS_INACTIVE = "inactive"
    STATUS_ARCHIVED = "archived"
    # 사용자 앱에서 숨겨야 하는 상태 목록.
    HIDDEN_STATUSES = (STATUS_DRAFT, STATUS_INACTIVE, STATUS_ARCHIVED)

    restaurant = models.OneToOneField(
        Restaurant,
        on_delete=models.DO_NOTHING,
        db_constraint=False,
        related_name="admin_meta",
    )
    status = models.CharField(max_length=20, default=STATUS_ACTIVE)
    status_changed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)

    class Meta:
        managed = False
        db_table = "admin_restaurant_meta"

    def __str__(self):
        return f"AdminMeta({self.restaurant_id}: {self.status})"


class AdminRestaurantSeatType(models.Model):
    """yumbook_admin 이 소유한 admin_restaurant_seat_type 테이블의 읽기 전용 매핑.

    좌석 종류(테이블/바/테라스 등) 카탈로그. ``code`` 가
    Reservation.seat_type 이 가져야 하는 정식 값이다.
    이 앱에서는 절대 쓰지 않는다(READ ONLY) — 스키마 소유권은 yumbook_admin.
    로컬 sqlite 에는 마이그레이션 0006 이 테이블을 생성한다(Postgres no-op).
    """

    restaurant = models.ForeignKey(
        Restaurant,
        on_delete=models.DO_NOTHING,
        db_constraint=False,
        related_name="admin_seat_types",
    )
    code = models.CharField(max_length=50)
    name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    default_capacity = models.PositiveIntegerField(default=0)
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = "admin_restaurant_seat_type"

    def __str__(self):
        return f"AdminSeatType({self.restaurant_id}:{self.code})"


class AdminRestaurantSeatInventory(models.Model):
    """yumbook_admin 소유 admin_restaurant_seat_inventory 의 읽기 전용 매핑.

    (restaurant, seat_type, date, time) 슬롯별 예약 가능 수량.
    time NULL = 그 날짜 전체(all-day). READ ONLY.
    """

    restaurant = models.ForeignKey(
        Restaurant,
        on_delete=models.DO_NOTHING,
        db_constraint=False,
        related_name="admin_seat_inventories",
    )
    seat_type = models.ForeignKey(
        AdminRestaurantSeatType,
        on_delete=models.DO_NOTHING,
        db_constraint=False,
        related_name="inventories",
    )
    date = models.DateField()
    time = models.TimeField(null=True, blank=True)
    capacity = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    note = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = "admin_restaurant_seat_inventory"

    def __str__(self):
        return f"AdminSeatInventory({self.restaurant_id}:{self.seat_type_id} {self.date})"


class AdminRestaurantExceptionDay(models.Model):
    """yumbook_admin 소유 admin_restaurant_exception_day 의 읽기 전용 매핑.

    휴무일(is_closed=True) 또는 특별 영업시간(open/close_time). READ ONLY.
    """

    restaurant = models.ForeignKey(
        Restaurant,
        on_delete=models.DO_NOTHING,
        db_constraint=False,
        related_name="admin_exception_days",
    )
    date = models.DateField()
    is_closed = models.BooleanField(default=True)
    open_time = models.TimeField(null=True, blank=True)
    close_time = models.TimeField(null=True, blank=True)
    reason = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = "admin_restaurant_exception_day"

    def __str__(self):
        state = "closed" if self.is_closed else f"{self.open_time}-{self.close_time}"
        return f"AdminExceptionDay({self.restaurant_id} {self.date} {state})"
