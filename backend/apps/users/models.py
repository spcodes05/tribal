import uuid
from pathlib import Path
from django.utils import timezone
from datetime import timedelta
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


def profile_image_upload_path(instance, filename):
    """
    Every upload gets a brand-new unique filename (UUID), regardless of the
    original filename. This guarantees the returned URL always changes on
    re-upload, so client-side image caches (Flutter's ImageCache included)
    can never serve a stale photo after a new one is uploaded.
    """
    ext = Path(filename).suffix.lower() or ".jpg"
    return f"profile_images/{instance.pk or 'new'}_{uuid.uuid4().hex}{ext}"


# ─────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────

GENDER_CHOICES = [
    ("male", "Male"),
    ("female", "Female"),
    ("non_binary", "Non-binary"),
    ("prefer_not_to_say", "Prefer not to say"),
]

# Predefined allowed interests. Stored as a separate model (ManyToMany).
# This gives us flexibility to add/remove interests later via admin.
PREDEFINED_INTERESTS = [
    "Hiking",
    "Futsal",
    "Board Games",
    "Book Club",
    "Photography",
    "Cooking",
    "Travel",
    "Music",
    "Gaming",
    "Yoga",
    "Language",
    "Treks",
]


# ─────────────────────────────────────────────
# INTEREST MODEL
# ─────────────────────────────────────────────

class Interest(models.Model):
    """
    Represents a predefined interest (e.g. "Hiking", "Music").

    Why a separate model instead of an ArrayField or CharField?
    - A separate model allows us to validate that only predefined
      interests are selected (foreign key constraint).
    - It's easy to manage via Django admin.
    - ManyToMany with a through table is the correct relational design
      when users can have many interests and interests can belong to many users.
    """
    name = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.name


# ─────────────────────────────────────────────
# CUSTOM USER MANAGER
# ─────────────────────────────────────────────

class CustomUserManager(BaseUserManager):

    def create_user(self, email, full_name, password=None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        if not full_name:
            raise ValueError("Full name is required")
        email = self.normalize_email(email)
        user = self.model(email=email, full_name=full_name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, full_name, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_email_verified", True)  # superusers skip verification
        return self.create_user(email, full_name, password, **extra_fields)


# ─────────────────────────────────────────────
# CUSTOM USER MODEL
# ─────────────────────────────────────────────

class CustomUser(AbstractBaseUser, PermissionsMixin):
    """
    Central user model for Tribal.

    Onboarding stages:
      1. Register → is_email_verified = False
      2. Verify email → is_email_verified = True
      3. Select gender → gender is set
      4. Select interests → interests are added (ManyToMany)
      5. All done → is_onboarding_complete = True (set automatically via signal or endpoint)
    """

    # ── Core fields ──────────────────────────
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=255)

    # ── Email verification ────────────────────
    is_email_verified = models.BooleanField(default=False)
    # UUID token sent in the verification email link.
    # UUIDField is cryptographically random and collision-resistant.
    verification_token = models.UUIDField(default=uuid.uuid4, editable=False, null=True, blank=True)
    # When the token expires. We'll set this to 24 hours after registration.
    verification_token_expiry = models.DateTimeField(null=True, blank=True)

    # ── Onboarding fields ─────────────────────
    gender = models.CharField(
        max_length=20,
        choices=GENDER_CHOICES,
        null=True,      # null=True in the DB (no row-level NOT NULL constraint)
        blank=True,     # blank=True in Django forms/serializers (optional field)
    )

    interests = models.ManyToManyField(
        Interest,
        blank=True,
        related_name="users",
        # blank=True makes the field optional (user may have no interests yet).
    )

    # ── Onboarding completion ─────────────────
    is_onboarding_complete = models.BooleanField(default=False)
    # Set to True only when email verified + gender set + interests selected.
    # Checked by protected endpoints to gate full app access.

    # ── Django required fields ────────────────
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    # ── Location (for proximity scoring) ─────
    # Stored as decimal degrees. null=True because existing users
    # won't have coordinates until they update their profile.
    latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )

    # ── Public profile fields (added for "Your Tribe Status" / "Other User Profile") ──
    # All optional/blank so existing users and existing endpoints are unaffected.
    username = models.CharField(max_length=30, unique=True, null=True, blank=True)
    profile_image = models.ImageField(upload_to=profile_image_upload_path, blank=True, default="")
    bio = models.CharField(max_length=280, blank=True, default="")
    age = models.PositiveSmallIntegerField(null=True, blank=True)
    occupation = models.CharField(max_length=150, blank=True, default="")
    university = models.CharField(max_length=150, blank=True, default="")
    location = models.CharField(max_length=150, blank=True, default="")  # free-text display location (distinct from lat/lng used by the recommendation engine)

    objects = CustomUserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]

    def __str__(self):
        return self.email

    # ── Helper methods ────────────────────────

    def generate_verification_token(self):
        """
        Generates a fresh UUID token and sets its expiry to 24 hours from now.
        Call this on registration and on resend-verification requests.
        """
        self.verification_token = uuid.uuid4()
        self.verification_token_expiry = timezone.now() + timedelta(hours=24)
        self.save(update_fields=["verification_token", "verification_token_expiry"])

    

    def verify_email(self):
        """
        Marks email as verified and clears the token so it can't be reused.
        """
        self.is_email_verified = True
        self.verification_token = None
        self.verification_token_expiry = None
        self.save(update_fields=["is_email_verified", "verification_token", "verification_token_expiry"])
        self.update_onboarding_status()
        
    def update_onboarding_status(self):
        self.is_onboarding_complete = bool(
            self.is_email_verified
            and self.gender
            and self.interests.exists()
        )
        self.save(update_fields=["is_onboarding_complete"])

    def check_onboarding_complete(self):
        complete = (
            self.is_email_verified
            and bool(self.gender)
            and self.interests.exists()
        )

        if self.is_onboarding_complete != complete:
            self.is_onboarding_complete = complete
            self.save(update_fields=["is_onboarding_complete"])

        return complete


    def can_access_app(self):
        return (
            self.is_email_verified
            and self.gender
            and self.interests.exists()
        )

# ─────────────────────────────────────────────
# SAFETY: BLOCK / REPORT
# ─────────────────────────────────────────────

class UserBlock(models.Model):
    """One user blocking another. Blocking is one-directional."""
    blocker = models.ForeignKey(
        "users.CustomUser", on_delete=models.CASCADE, related_name="blocking",
    )
    blocked = models.ForeignKey(
        "users.CustomUser", on_delete=models.CASCADE, related_name="blocked_by",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("blocker", "blocked")

    def __str__(self):
        return f"{self.blocker_id} blocked {self.blocked_id}"


class UserReport(models.Model):
    REASON_CHOICES = [
        ("harassment", "Harassment or bullying"),
        ("spam", "Spam"),
        ("fake_profile", "Fake profile"),
        ("inappropriate_content", "Inappropriate content"),
        ("safety_concern", "Safety concern"),
        ("other", "Other"),
    ]

    reporter = models.ForeignKey(
        "users.CustomUser", on_delete=models.CASCADE, related_name="reports_made",
    )
    reported_user = models.ForeignKey(
        "users.CustomUser", on_delete=models.CASCADE, related_name="reports_received",
    )
    reason = models.CharField(max_length=30, choices=REASON_CHOICES)
    details = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Report({self.reporter_id} -> {self.reported_user_id}: {self.reason})"