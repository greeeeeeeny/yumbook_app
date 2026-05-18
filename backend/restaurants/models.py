from decimal import Decimal

from django.db import models


class Restaurant(models.Model):
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    image_url = models.URLField(max_length=500, blank=True)
    tags = models.JSONField(default=list, blank=True)

    raw_category = models.CharField(max_length=100, blank=True)
    lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

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
