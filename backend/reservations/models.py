import uuid

from django.db import models


class Reservation(models.Model):
    user = models.CharField(max_length=255)
    restaurant_id = models.CharField(max_length=100, blank=True, null=True)
    restaurant_name = models.CharField(max_length=255, blank=True)
    date = models.DateField()
    time = models.TimeField()
    party_size = models.PositiveIntegerField(default=1)
    guest_name = models.CharField(max_length=100, blank=True)
    seat_type = models.CharField(max_length=50, blank=True, null=True)
    confirmation_code = models.CharField(max_length=50, unique=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.confirmation_code:
            code = uuid.uuid4().hex[:8].upper()
            self.confirmation_code = f"Yumbook-B-{code}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.restaurant_name or 'Reservation'} - {self.date} {self.time}"
