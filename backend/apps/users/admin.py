from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth import get_user_model

User = get_user_model()


@admin.register(User)
class CustomUserAdmin(BaseUserAdmin):
    """
    Registers CustomUser with the Django admin panel.

    We extend BaseUserAdmin to keep built-in admin features
    (password change form, permission management, etc.)
    while adapting the display for our custom fields.
    """

    # Columns shown in the user list page of the admin.
    list_display = ["email", "full_name", "is_staff", "is_active", "date_joined"]

    # Fields used to filter the list on the right sidebar.
    list_filter = ["is_staff", "is_active"]

    # Fields shown when viewing/editing an individual user.
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal Info", {"fields": ("full_name",)}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important Dates", {"fields": ("last_login", "date_joined")}),
    )

    # Fields shown when creating a new user in the admin.
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "full_name", "password1", "password2"),
            },
        ),
    )

    # Makes the user list searchable by these fields.
    search_fields = ["email", "full_name"]

    # Default sort order in the admin list.
    ordering = ["email"]
