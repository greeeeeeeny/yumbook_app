from decimal import Decimal

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class FoodRecord(models.Model):
    user = models.CharField(max_length=255, db_index=True)
    restaurant = models.ForeignKey(
        "restaurants.Restaurant",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="food_records",
    )
    restaurant_name = models.CharField(max_length=255, blank=True)

    menu_name = models.CharField(max_length=255, blank=True)
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=1,
        validators=[MinValueValidator(Decimal("0")), MaxValueValidator(Decimal("5"))],
    )
    review = models.TextField(blank=True)
    price = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    tags = models.JSONField(default=list, blank=True)

    visited_at = models.DateField(null=True, blank=True)
    is_public = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["-created_at"]),
            models.Index(fields=["user", "-created_at"]),
            models.Index(fields=["restaurant", "-created_at"]),
        ]

    def __str__(self):
        return f"{self.user} - {self.menu_name or self.restaurant_name} ({self.rating})"


class FoodRecordImage(models.Model):
    record = models.ForeignKey(
        FoodRecord, on_delete=models.CASCADE, related_name="images"
    )
    image_url = models.URLField(max_length=500)
    order = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self):
        return self.image_url
