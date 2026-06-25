from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth import get_user_model
from .models import Interest

User = get_user_model()


@admin.register(Interest)
class InterestAdmin(admin.ModelAdmin):
    list_display = ["id", "name"]
    search_fields = ["name"]


@admin.register(User)
class CustomUserAdmin(BaseUserAdmin):
    list_display = ["email", "full_name", "is_email_verified", "gender", "is_onboarding_complete", "is_staff"]
    list_filter = ["is_staff", "is_active", "is_email_verified", "is_onboarding_complete", "gender"]

    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal Info", {"fields": ("full_name",)}),
        ("Onboarding", {"fields": ("is_email_verified", "verification_token", "verification_token_expiry", "gender", "interests", "is_onboarding_complete")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important Dates", {"fields": ("last_login", "date_joined")}),
    )

    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("email", "full_name", "password1", "password2"),
        }),
    )

    search_fields = ["email", "full_name"]
    ordering = ["email"]
    filter_horizontal = ["interests"]
    # filter_horizontal renders the ManyToMany field as a dual-list widget in admin.
    readonly_fields = ["verification_token", "verification_token_expiry", "date_joined"]