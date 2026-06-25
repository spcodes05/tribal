from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


class CustomUserManager(BaseUserManager):
    """
    Custom manager that uses email instead of username.
    Django's default manager expects a 'username' field.
    We override it so 'email' becomes the unique identifier.
    """

    def create_user(self, email, full_name, password=None, **extra_fields):
        if not email:
            raise ValueError("The Email field is required")
        if not full_name:
            raise ValueError("The Full Name field is required")

        # normalize_email lowercases the domain part of the email
        # e.g. "John@EXAMPLE.COM" → "John@example.com"
        email = self.normalize_email(email)

        user = self.model(email=email, full_name=full_name, **extra_fields)

        # set_password hashes the password using Django's PBKDF2 algorithm.
        # NEVER store plain-text passwords. Django handles this for you here.
        user.set_password(password)

        user.save(using=self._db)
        return user

    def create_superuser(self, email, full_name, password=None, **extra_fields):
        """
        create_superuser is required by Django's management commands.
        e.g. when you run: python manage.py createsuperuser
        """
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self.create_user(email, full_name, password, **extra_fields)


class CustomUser(AbstractBaseUser, PermissionsMixin):
    """
    Our custom user model.

    AbstractBaseUser gives us:
      - password field (hashed)
      - last_login field
      - is_active field
      - the authentication framework hooks

    PermissionsMixin gives us:
      - is_superuser
      - groups and user_permissions (needed for Django admin)
    """

    email = models.EmailField(unique=True)
    # EmailField validates email format automatically.
    # unique=True ensures no two users share the same email.

    full_name = models.CharField(max_length=255)

    is_active = models.BooleanField(default=True)
    # is_active=False is how Django "soft deletes" users (disables login)
    # without actually removing them from the database.

    is_staff = models.BooleanField(default=False)
    # is_staff=True allows access to the Django admin panel.

    date_joined = models.DateTimeField(auto_now_add=True)
    # auto_now_add=True sets this field automatically when the row is created.

    objects = CustomUserManager()
    # Attach our custom manager so Django knows how to create users.

    USERNAME_FIELD = "email"
    # This tells Django: "use email as the login identifier"
    # instead of the default 'username'.

    REQUIRED_FIELDS = ["full_name"]
    # These fields are required when using: python manage.py createsuperuser
    # USERNAME_FIELD (email) is always required, so don't repeat it here.

    def __str__(self):
        return self.email