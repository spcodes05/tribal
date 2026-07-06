from django.db import models
from django.conf import settings
from django.utils import timezone


class Activity(models.Model):
    """
    Represents an activity/event created by a TRIBAL user.

    Tags are stored as simple boolean fields rather than a ManyToMany
    because there are exactly 3 fixed tags from the UI design and they're
    unlikely to grow — a ManyToMany table would be over-engineering here.
    """

    # ── Core fields ──────────────────────────────────────────────────────────
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)

    # Creator / host of the activity
    host = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='hosted_activities',
    )

    # ── Location ─────────────────────────────────────────────────────────────
    location = models.CharField(max_length=255)          # e.g. "Shivapuri, Nepal"
    meeting_point = models.CharField(max_length=255, blank=True)  # e.g. "Mulhan Pokhari Gate"

    # ── Schedule ──────────────────────────────────────────────────────────────
    date = models.DateField()
    time = models.TimeField()

    # ── Tags (from the UI: Women-only, Accessible, Free) ─────────────────────
    is_women_only = models.BooleanField(default=False)
    is_accessible = models.BooleanField(default=False)
    is_free = models.BooleanField(default=True)

    # ── Capacity ─────────────────────────────────────────────────────────────
    max_members = models.PositiveIntegerField(default=20)

    # ── Cover image ───────────────────────────────────────────────────────────
    # Stored as a URL string (e.g. Supabase storage URL) — no FileField to
    # avoid serving media files from the Django process itself.
    image_url = models.URLField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['date', 'time']

    def __str__(self):
        return f"{self.title} ({self.date})"

    @property
    def member_count(self):
        return self.members.count()

    @property
    def is_full(self):
        return self.member_count >= self.max_members


class ActivityMember(models.Model):
    """
    Through-model tracking which users have joined which activities.
    Using an explicit through-model (instead of ManyToManyField with
    through=) gives us the joined_at timestamp and easy member_count queries.
    """
    activity = models.ForeignKey(
        Activity,
        on_delete=models.CASCADE,
        related_name='members',
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='joined_activities',
    )
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Prevent a user from joining the same activity twice.
        unique_together = ('activity', 'user')
        ordering = ['joined_at']

    def __str__(self):
        return f"{self.user.full_name} → {self.activity.title}"


class Notification(models.Model):
    """
    In-app notification for a user.
    Created by the backend when relevant events occur (someone joins
    your activity, a new activity matches your interests, etc.).
    """

    TYPES = [
        ('join', 'Someone joined your activity'),
        ('match', 'New activity matches your interests'),
        ('reminder', 'Activity reminder'),
    ]

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    notification_type = models.CharField(max_length=20, choices=TYPES)
    title = models.CharField(max_length=200)
    body = models.CharField(max_length=500)

    # Optional link to a related activity
    activity = models.ForeignKey(
        Activity,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications',
    )

    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.notification_type}] → {self.recipient.email}"
