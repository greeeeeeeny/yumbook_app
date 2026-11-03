from django.db import models


class UserProfile(models.Model):
    # 소유자 식별은 Supabase user UUID(문자열). Django auth.User FK는 쓰지 않는다.
    user = models.CharField(max_length=255, unique=True, db_index=True)
    name = models.CharField(max_length=120, blank=True)
    # Flutter UserProfile.dateOfBirth는 표시용 문자열이라 CharField로 둔다.
    date_of_birth = models.CharField(max_length=40, blank=True)
    mobile_number = models.CharField(max_length=40, blank=True)
    email = models.EmailField(blank=True)
    # 아바타는 URL/스토리지 경로 문자열만 저장한다(바이너리 X).
    # 자산 경로/스토리지 경로도 허용하기 위해 URLField 대신 CharField를 쓴다.
    avatar_url = models.CharField(max_length=500, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"UserProfile({self.user})"


class DiningPreferences(models.Model):
    user = models.CharField(max_length=255, unique=True, db_index=True)
    favorite_cuisines = models.JSONField(default=list, blank=True)
    dining_styles = models.JSONField(default=list, blank=True)
    dietary_restrictions = models.JSONField(default=list, blank=True)
    additional_notes = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Dining preferences"

    def __str__(self):
        return f"DiningPreferences({self.user})"


class NotificationSettings(models.Model):
    user = models.CharField(max_length=255, unique=True, db_index=True)
    push_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Notification settings"

    def __str__(self):
        return f"NotificationSettings({self.user})"


class SavedRestaurant(models.Model):
    # 사용자(Supabase UUID)별 북마크. user+restaurant 유일.
    user = models.CharField(max_length=255, db_index=True)
    restaurant = models.ForeignKey(
        "restaurants.Restaurant",
        on_delete=models.CASCADE,
        related_name="saved_by",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "restaurant")
        ordering = ["-created_at"]

    def __str__(self):
        return f"SavedRestaurant({self.user}, {self.restaurant_id})"


class PaymentMethod(models.Model):
    # 보안: PAN(전체 카드번호)/CVV는 절대 저장하지 않는다. 표시용 메타데이터만 저장.
    user = models.CharField(max_length=255, db_index=True)
    brand = models.CharField(max_length=40, blank=True)
    last4 = models.CharField(max_length=4, blank=True)
    holder_name = models.CharField(max_length=120, blank=True)
    expiry_month = models.PositiveSmallIntegerField(null=True, blank=True)
    expiry_year = models.PositiveSmallIntegerField(null=True, blank=True)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        # 기본 카드가 맨 앞(Flutter primaryMethod == methods.first 와 일치).
        ordering = ["-is_default", "-created_at"]

    def __str__(self):
        return f"PaymentMethod({self.user}, {self.brand} ****{self.last4})"


class Transaction(models.Model):
    class Type(models.TextChoices):
        # Flutter TransactionType: reservation / refund / failed (+ 일반 결제)
        RESERVATION = "reservation", "Reservation"
        REFUND = "refund", "Refund"
        FAILED = "failed", "Failed"
        PAYMENT = "payment", "Payment"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        COMPLETED = "completed", "Completed"
        FAILED = "failed", "Failed"
        REFUNDED = "refunded", "Refunded"

    user = models.CharField(max_length=255, db_index=True)
    reservation = models.ForeignKey(
        "reservations.Reservation",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="transactions",
    )
    payment_method = models.ForeignKey(
        "accounts.PaymentMethod",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="transactions",
    )

    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)  # Flutter subtitle

    amount = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    currency = models.CharField(max_length=8, default="USD")
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.COMPLETED
    )
    transaction_type = models.CharField(
        max_length=20, choices=Type.choices, default=Type.PAYMENT
    )

    # 결제 게이트웨이 식별자(비밀키 아님). 민감정보(PAN/CVV/인증 시크릿)는 저장 금지.
    provider = models.CharField(max_length=40, blank=True)
    provider_transaction_id = models.CharField(max_length=200, blank=True)

    # 표시용 카드 스냅샷(불변 원장 보존용). last4/brand는 비민감 정보.
    card_brand = models.CharField(max_length=40, blank=True)
    card_last4 = models.CharField(max_length=4, blank=True)
    # Flutter trailingText (예: "+ 30.55 $", "Failed")
    trailing_text = models.CharField(max_length=60, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "-created_at"]),
        ]

    def __str__(self):
        return f"Transaction({self.user}, {self.transaction_type}, {self.title})"
