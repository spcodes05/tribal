import uuid
from django.utils import timezone
from datetime import timedelta
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


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
        """
        Recalculates and saves is_onboarding_complete.
        Called after gender or interests are saved.

        Criteria:
          - Email verified
          - Gender selected
          - At least one interest selected
        """
        complete = (
            self.is_email_verified
            and bool(self.gender)
            and self.interests.exists()
        )

        def can_access_app(self):
         return (
        self.is_email_verified and
        self.gender and
        self.interests.exists()
          )
        
        if self.is_onboarding_complete != complete:
            self.is_onboarding_complete = complete
            self.save(update_fields=["is_onboarding_complete"])
        return complete