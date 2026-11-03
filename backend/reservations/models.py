import uuid

from django.db import models


class Reservation(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        CONFIRMED = "confirmed", "Confirmed"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"
        REJECTED = "rejected", "Rejected"

    user = models.CharField(max_length=255)
    restaurant = models.ForeignKey(
        "restaurants.Restaurant",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reservations",
    )
    external_restaurant_id = models.CharField(max_length=100, blank=True, null=True)
    restaurant_name = models.CharField(max_length=255, blank=True)
    date = models.DateField()
    time = models.TimeField()
    party_size = models.PositiveIntegerField(default=1)
    guest_name = models.CharField(max_length=100, blank=True)
    seat_type = models.CharField(max_length=50, blank=True, null=True)
    confirmation_code = models.CharField(max_length=50, unique=True, blank=True)

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
    )
    cancel_reason = models.TextField(blank=True)
    # 예약 시점의 결제 스냅샷(ReservationPaymentSnapshot). 자유 형식 JSON으로 저장한다.
    payment_snapshot = models.JSONField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.confirmation_code:
            code = uuid.uuid4().hex[:8].upper()
            self.confirmation_code = f"Yumbook-B-{code}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.restaurant_name or 'Reservation'} - {self.date} {self.time}"


class ReservationChangeRequest(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    reservation = models.ForeignKey(
        Reservation,
        on_delete=models.CASCADE,
        related_name="change_requests",
    )
    requested_date = models.DateField()
    requested_time = models.TimeField()
    requested_party_size = models.PositiveIntegerField(default=1)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
    )
    requested_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-requested_at"]

    def __str__(self):
        return f"ChangeRequest({self.reservation_id}, {self.status})"
