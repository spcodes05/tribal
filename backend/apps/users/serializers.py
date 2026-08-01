from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Interest,
    GENDER_CHOICES,
    PREDEFINED_INTERESTS,
    CustomUser,
    UserBlock,
    UserReport,
)

User = get_user_model()

# Build a set of valid interest names for O(1) lookup during validation.
VALID_INTEREST_NAMES = {name for name in PREDEFINED_INTERESTS}


# ─────────────────────────────────────────────
# REGISTRATION
# ─────────────────────────────────────────────

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={"input_type": "password"},
    )

    class Meta:
        model = User
        fields = ["id", "full_name", "email", "password"]

    def validate_email(self, value):
        normalized = value.lower().strip()
        if User.objects.filter(email__iexact=normalized).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return normalized

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data["email"],
            full_name=validated_data["full_name"],
            password=validated_data["password"],
        )
        # Generate the verification token immediately after creation.
        user.generate_verification_token()
        return user


# ─────────────────────────────────────────────
# EMAIL VERIFICATION
# ─────────────────────────────────────────────

class VerifyEmailSerializer(serializers.Serializer):
    """
    Accepts the UUID token submitted by the user.
    We use a plain Serializer (not ModelSerializer) because
    we're not creating/updating a model instance directly here —
    we're just validating an input field.
    """
    token = serializers.UUIDField()
    # UUIDField automatically validates that the value is a valid UUID format.


class ResendVerificationSerializer(serializers.Serializer):
    """
    Accepts an email address to resend the verification link to.
    """
    email = serializers.EmailField()


# ─────────────────────────────────────────────
# GENDER
# ─────────────────────────────────────────────

class GenderSerializer(serializers.ModelSerializer):
    gender = serializers.ChoiceField(choices=GENDER_CHOICES)
    # ChoiceField restricts the value to the allowed choices defined in the model.
    # If an invalid value is submitted, DRF automatically returns a 400 error.

    class Meta:
        model = User
        fields = ["gender"]


# ─────────────────────────────────────────────
# INTERESTS
# ─────────────────────────────────────────────

class InterestSerializer(serializers.ModelSerializer):
    class Meta:
        model = Interest
        fields = ["id", "name"]


class SaveInterestsSerializer(serializers.Serializer):
    """
    Accepts a list of interest names.
    Example input: { "interests": ["Hiking", "Music", "Gaming"] }
    """
    interests = serializers.ListField(
        child=serializers.CharField(),
        # ListField accepts a JSON array of strings.
        # child= defines the type of each item in the list.
        allow_empty=False,
        # Prevents submitting an empty list [].
        min_length=1,
    )

    def validate_interests(self, values):
        """
        Validates that every submitted interest name is in the predefined list.
        Rejects any interest not on our allowed list.
        """
        invalid = [v for v in values if v not in VALID_INTEREST_NAMES]
        if invalid:
            raise serializers.ValidationError(
                f"Invalid interests: {invalid}. "
                f"Allowed interests are: {sorted(VALID_INTEREST_NAMES)}"
            )
        return values


# ─────────────────────────────────────────────
# USER DETAIL (me endpoint)
# ─────────────────────────────────────────────

class UserDetailSerializer(serializers.ModelSerializer):
    interests = InterestSerializer(many=True, read_only=True)
    # many=True tells DRF this is a list of related objects (ManyToMany).
    # read_only=True means this field is for output only.

    class Meta:
        model = CustomUser
        fields = [
            "id",
            "full_name",
            "email",
            "is_email_verified",
            "latitude",
            "longitude",
            "gender",
            "interests",
            "is_onboarding_complete",
]

class UserSearchSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = [
            "id",
            "full_name",
            "email",
        ]


# ─────────────────────────────────────────────
# PUBLIC PROFILE (Your Tribe Status / Other User Profile)
# ─────────────────────────────────────────────

class PublicUserProfileSerializer(serializers.ModelSerializer):
    """
    Shared "core person" shape used both for the authenticated user's own
    Tribe Status page and for viewing someone else's profile. Only ever
    exposes information that's safe to show publicly.
    """
    interests = serializers.SerializerMethodField()

    def get_interests(self, obj):
        return list(obj.interests.values_list("name", flat=True))

    class Meta:
        model = CustomUser
        fields = [
            "id",
            "full_name",
            "username",
            "profile_image",
            "bio",
            "age",
            "occupation",
            "university",
            "location",
            "gender",
            "interests",
            "is_email_verified",
        ]


class ProfileUpdateSerializer(serializers.ModelSerializer):
    """PATCH /api/users/me/update/ — used by the Profile Settings screen."""

    class Meta:
        model = CustomUser
        fields = [
            "username",
            "bio",
            "age",
            "occupation",
            "university",
            "location",
            "profile_image",
        ]

    def validate_username(self, value):
        if not value:
            return value
        qs = CustomUser.objects.filter(username__iexact=value)
        if self.instance is not None:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError("That username is already taken.")
        return value

    def validate_age(self, value):
        if value is not None and (value < 13 or value > 100):
            raise serializers.ValidationError("Please enter a valid age.")
        return value


class ReportUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserReport
        fields = ["reason", "details"]
