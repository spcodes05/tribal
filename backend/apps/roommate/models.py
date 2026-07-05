from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class SleepSchedule(models.TextChoices):
    EARLY_BIRD = "early_bird", "Early Bird"
    NIGHT_OWL = "night_owl", "Night Owl"
    FLEXIBLE = "flexible", "Flexible"


class SmokingPreference(models.TextChoices):
    NON_SMOKER = "non_smoker", "Non-Smoker"
    SMOKER = "smoker", "Smoker"
    OCCASIONAL = "occasional", "Occasional"


class DrinkingPreference(models.TextChoices):
    NON_DRINKER = "non_drinker", "Non-Drinker"
    DRINKER = "drinker", "Drinker"
    SOCIAL = "social", "Social Drinker"


class GuestsPreference(models.TextChoices):
    RARELY = "rarely", "Rarely"
    SOMETIMES = "sometimes", "Sometimes"
    FREQUENTLY = "frequently", "Frequently"


class FoodPreference(models.TextChoices):
    VEGETARIAN = "vegetarian", "Vegetarian"
    NON_VEGETARIAN = "non_vegetarian", "Non-Vegetarian"
    VEGAN = "vegan", "Vegan"
    NO_PREFERENCE = "no_preference", "No Preference"


class PetsPreference(models.TextChoices):
    HAS_PETS = "has_pets", "Has Pets"
    NO_PETS = "no_pets", "No Pets"
    OKAY_WITH_PETS = "okay_with_pets", "Okay With Pets"
    NOT_OKAY_WITH_PETS = "not_okay_with_pets", "Not Okay With Pets"


class StudyHabit(models.TextChoices):
    QUIET = "quiet", "Needs Quiet"
    BACKGROUND_NOISE_OK = "background_noise_ok", "Background Noise Okay"
    GROUP_STUDY = "group_study", "Group Study"
    RARELY_STUDIES_AT_HOME = "rarely_studies_at_home", "Rarely Studies At Home"


class GenderPreference(models.TextChoices):
    MALE = "male", "Male"
    FEMALE = "female", "Female"
    NON_BINARY = "non_binary", "Non-Binary"
    ANY = "any", "Any"


class RoomTypePreference(models.TextChoices):
    PRIVATE_ROOM = "private_room", "Private Room"
    SHARED_ROOM = "shared_room", "Shared Room"
    ENTIRE_PLACE = "entire_place", "Entire Place"
    ANY = "any", "Any"


class RoommateProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="roommate_profile",
    )

    budget_min = models.PositiveIntegerField()
    budget_max = models.PositiveIntegerField()

    sleep_schedule = models.CharField(
        max_length=20,
        choices=SleepSchedule.choices,
    )
    wake_time = models.TimeField()

    smoking = models.CharField(
        max_length=20,
        choices=SmokingPreference.choices,
    )
    drinking = models.CharField(
        max_length=20,
        choices=DrinkingPreference.choices,
    )

    cleanliness = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    noise_level = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )

    guests_preference = models.CharField(
        max_length=20,
        choices=GuestsPreference.choices,
    )
    food_preference = models.CharField(
        max_length=20,
        choices=FoodPreference.choices,
    )
    pets = models.CharField(
        max_length=30,
        choices=PetsPreference.choices,
    )
    study_habit = models.CharField(
        max_length=30,
        choices=StudyHabit.choices,
    )

    # Points to the shared Interest model in apps.users.
    # We do NOT define our own Interest model to avoid duplicates.
    interests = models.ManyToManyField(
        "users.Interest",
        related_name="roommate_profiles",
        blank=True,
    )

    gender_preference = models.CharField(
        max_length=20,
        choices=GenderPreference.choices,
        default=GenderPreference.ANY,
    )
    room_type_preference = models.CharField(
        max_length=20,
        choices=RoomTypePreference.choices,
        default=RoomTypePreference.ANY,
    )

    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["sleep_schedule"]),
            models.Index(fields=["smoking"]),
            models.Index(fields=["is_active"]),
        ]

    def __str__(self):
        return f"RoommateProfile({self.user_id})"


class RoommateMatch(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="roommate_matches_made",
    )
    matched_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="roommate_matches_received",
    )
    compatibility_score = models.DecimalField(max_digits=5, decimal_places=2)
    score_breakdown = models.JSONField(default=dict, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("user", "matched_user")
        indexes = [
            models.Index(fields=["user", "compatibility_score"]),
        ]
        ordering = ["-compatibility_score"]

    def __str__(self):
        return f"{self.user_id} -> {self.matched_user_id}: {self.compatibility_score}"