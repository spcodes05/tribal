from rest_framework import serializers
from django.contrib.auth import get_user_model

# get_user_model() returns the model pointed to by AUTH_USER_MODEL in settings.
# Always use this instead of importing CustomUser directly — it's the Django-recommended
# pattern and keeps your code decoupled from the specific model class name.
User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    """
    Handles validation and creation of new users during signup.

    ModelSerializer automatically generates fields based on the model.
    We specify exactly which fields we want exposed.
    """

    password = serializers.CharField(
        write_only=True,
        # write_only=True means the password field is accepted as INPUT
        # but never included in the serializer's OUTPUT (response data).
        # This prevents the hashed password from ever being sent back to clients.
        min_length=8,
        # Enforces a minimum password length at the serializer level.
        style={"input_type": "password"},
        # 'style' is a hint for browsable API forms — not critical but good practice.
    )

    class Meta:
        model = User
        fields = ["id", "full_name", "email", "password"]
        # 'id' is read_only by default because it's the primary key.

    def validate_email(self, value):
        """
        Custom field-level validator for email.

        Django/DRF naming convention: validate_<fieldname>
        This method is automatically called by DRF when validating the 'email' field.

        The EmailField on the model handles format validation.
        This validator adds a case-insensitive uniqueness check.
        """
        # Normalize to lowercase for consistent storage and comparison.
        normalized = value.lower()
        if User.objects.filter(email__iexact=normalized).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return normalized

    def create(self, validated_data):
        """
        Called when serializer.save() is invoked in the view.

        We use our custom manager's create_user() method,
        which handles password hashing via set_password().

        NEVER do: User(password=validated_data['password'])
        That would store the plain-text password. Always use create_user().
        """
        user = User.objects.create_user(
            email=validated_data["email"],
            full_name=validated_data["full_name"],
            password=validated_data["password"],
        )
        return user


class UserDetailSerializer(serializers.ModelSerializer):
    """
    Read-only serializer for returning user profile data.
    Used by the /api/users/me/ endpoint.
    """

    class Meta:
        model = User
        fields = ["id", "full_name", "email"]
        # We intentionally exclude password, is_staff, is_superuser, etc.
        # Only expose what the client needs.