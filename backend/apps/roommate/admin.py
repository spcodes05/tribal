from django.contrib import admin

from .models import RoommateMatch, RoommateProfile


@admin.register(RoommateProfile)
class RoommateProfileAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "user",
        "budget_min",
        "budget_max",
        "sleep_schedule",
        "smoking",
        "drinking",
        "cleanliness",
        "noise_level",
        "is_active",
        "updated_at",
    ]
    list_filter = [
        "sleep_schedule",
        "smoking",
        "drinking",
        "guests_preference",
        "food_preference",
        "pets",
        "study_habit",
        "gender_preference",
        "room_type_preference",
        "is_active",
    ]
    search_fields = ["user__email", "user__full_name"]
    readonly_fields = ["created_at", "updated_at"]
    filter_horizontal = ["interests"]

    fieldsets = (
        ("User", {"fields": ("user", "is_active")}),
        ("Budget", {"fields": ("budget_min", "budget_max")}),
        (
            "Lifestyle",
            {
                "fields": (
                    "sleep_schedule",
                    "wake_time",
                    "smoking",
                    "drinking",
                    "cleanliness",
                    "noise_level",
                    "guests_preference",
                    "food_preference",
                    "pets",
                    "study_habit",
                )
            },
        ),
        ("Interests", {"fields": ("interests",)}),
        (
            "Preferences",
            {"fields": ("gender_preference", "room_type_preference")},
        ),
        ("Timestamps", {"fields": ("created_at", "updated_at")}),
    )


@admin.register(RoommateMatch)
class RoommateMatchAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "user",
        "matched_user",
        "compatibility_score",
        "updated_at",
    ]
    list_filter = ["compatibility_score"]
    search_fields = ["user__email", "matched_user__email"]
    readonly_fields = ["created_at", "updated_at", "score_breakdown"]
    ordering = ["-compatibility_score"]