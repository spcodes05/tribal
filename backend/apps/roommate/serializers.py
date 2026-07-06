from rest_framework import serializers

from apps.users.models import Interest

from .models import (
    DrinkingPreference,
    FoodPreference,
    GenderPreference,
    GuestsPreference,
    PetsPreference,
    RoomTypePreference,
    RoommateProfile,
    SleepSchedule,
    SmokingPreference,
    StudyHabit,
)


class InterestSerializer(serializers.ModelSerializer):
    class Meta:
        model = Interest
        fields = ["id", "name"]


class RoommateProfileSerializer(serializers.ModelSerializer):
    interests = serializers.PrimaryKeyRelatedField(
        queryset=Interest.objects.all(),
        many=True,
        required=False,
    )
    interest_details = InterestSerializer(
        source="interests", many=True, read_only=True
    )

    class Meta:
        model = RoommateProfile
        fields = [
            "id",
            "user",
            "budget_min",
            "budget_max",
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
            "interests",
            "interest_details",
            "gender_preference",
            "room_type_preference",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]

    def validate_budget_max(self, value):
        budget_min = self.initial_data.get("budget_min")
        if budget_min is not None:
            try:
                budget_min = int(budget_min)
            except (TypeError, ValueError):
                budget_min = None
        if budget_min is not None and value < budget_min:
            raise serializers.ValidationError(
                "budget_max must be greater than or equal to budget_min."
            )
        return value

    def validate_sleep_schedule(self, value):
        valid = [c[0] for c in SleepSchedule.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value

    def validate_smoking(self, value):
        valid = [c[0] for c in SmokingPreference.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value

    def validate_drinking(self, value):
        valid = [c[0] for c in DrinkingPreference.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value

    def validate_guests_preference(self, value):
        valid = [c[0] for c in GuestsPreference.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value

    def validate_food_preference(self, value):
        valid = [c[0] for c in FoodPreference.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value

    def validate_pets(self, value):
        valid = [c[0] for c in PetsPreference.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value

    def validate_study_habit(self, value):
        valid = [c[0] for c in StudyHabit.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value

    def validate_gender_preference(self, value):
        valid = [c[0] for c in GenderPreference.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value

    def validate_room_type_preference(self, value):
        valid = [c[0] for c in RoomTypePreference.choices]
        if value not in valid:
            raise serializers.ValidationError(f"Must be one of {valid}.")
        return value


class RoommateProfileSummarySerializer(serializers.ModelSerializer):
    interest_details = InterestSerializer(
        source="interests", many=True, read_only=True
    )
    user_email = serializers.EmailField(source="user.email", read_only=True)
    user_full_name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = RoommateProfile
        fields = [
            "id",
            "user",
            "user_email",
            "user_full_name",
            "budget_min",
            "budget_max",
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
            "interest_details",
            "room_type_preference",
        ]


class ScoreBreakdownSerializer(serializers.Serializer):
    cleanliness = serializers.FloatField()
    budget = serializers.FloatField()
    sleep_schedule = serializers.FloatField()
    noise_level = serializers.FloatField()
    smoking = serializers.FloatField()
    guests = serializers.FloatField()
    interests = serializers.FloatField()
    study_habit = serializers.FloatField()
    food = serializers.FloatField()
    drinking = serializers.FloatField()


class RoommateMatchResultSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    profile = RoommateProfileSummarySerializer()
    score = serializers.FloatField()
    breakdown = ScoreBreakdownSerializer()
    deal_breaker = serializers.BooleanField(required=False, default=False)
    deal_breaker_reasons = serializers.ListField(
        child=serializers.CharField(), required=False, default=list
    )