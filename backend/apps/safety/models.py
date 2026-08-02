from django.conf import settings
from django.db import models
from django.core.exceptions import ValidationError


class SafetySettings(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="safety_settings"
    )
    live_location_enabled = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"SafetySettings({self.user_id})"


class TrustedContact(models.Model):
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="trusted_contacts"
    )
    trusted_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="trusted_by"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["owner", "trusted_user"],
                name="unique_owner_trusted_user"
            ),
            models.CheckConstraint(
                condition=~models.Q(owner=models.F("trusted_user")),
                name="prevent_self_trusted_contact"
            ),
        ]

    def clean(self):
        if self.owner_id == self.trusted_user_id:
            raise ValidationError("You cannot add yourself as a trusted contact.")

    def __str__(self):
        return f"{self.owner_id} -> {self.trusted_user_id}"


class UserLocation(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="live_location"
    )
    latitude = models.DecimalField(max_digits=18, decimal_places=12)
    longitude = models.DecimalField(max_digits=18, decimal_places=12)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"UserLocation({self.user_id})"


class SOSSession(models.Model):
    class Status(models.TextChoices):
        ACTIVE = "ACTIVE", "Active"
        ENDED = "ENDED", "Ended"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sos_sessions"
    )
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.ACTIVE
    )
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"SOSSession({self.user_id}, {self.status})"