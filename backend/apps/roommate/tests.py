from datetime import time

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from apps.users.models import Interest

from .models import (
    FoodPreference,
    GuestsPreference,
    PetsPreference,
    RoommateMatch,
    RoommateProfile,
    SleepSchedule,
    SmokingPreference,
    StudyHabit,
)
from .scoring import (
    WEIGHTS,
    calculate_compatibility_score,
    score_budget,
    score_cleanliness,
    score_drinking,
    score_food,
    score_guests_preference,
    score_interests,
    score_noise_level,
    score_sleep_schedule,
    score_smoking,
    score_study_habit,
)
from .services import (
    RoommateProfileNotFoundError,
    find_best_matches,
    get_active_profile_for_user,
    persist_matches_for_user,
)

User = get_user_model()


def create_user(email, full_name="Test User", **kwargs):
    return User.objects.create_user(
        email=email,
        full_name=full_name,
        password="testpass123",
        is_email_verified=True,
        **kwargs,
    )


def create_profile(user, interests=None, **overrides):
    defaults = {
        "budget_min": 500,
        "budget_max": 800,
        "sleep_schedule": SleepSchedule.EARLY_BIRD,
        "wake_time": time(7, 0),
        "smoking": SmokingPreference.NON_SMOKER,
        "drinking": "non_drinker",
        "cleanliness": 4,
        "noise_level": 2,
        "guests_preference": GuestsPreference.SOMETIMES,
        "food_preference": FoodPreference.VEGETARIAN,
        "pets": PetsPreference.NO_PETS,
        "study_habit": StudyHabit.QUIET,
        "gender_preference": "any",
        "room_type_preference": "any",
    }
    defaults.update(overrides)
    profile = RoommateProfile.objects.create(user=user, **defaults)
    if interests:
        profile.interests.set(interests)
    return profile


class ScoringFunctionTests(TestCase):
    def setUp(self):
        self.user_a = create_user("alice@test.com", "Alice")
        self.user_b = create_user("bob@test.com", "Bob")
        self.interest_reading = Interest.objects.create(name="Reading")
        self.interest_gaming = Interest.objects.create(name="Gaming")
        self.interest_hiking = Interest.objects.create(name="Hiking")

    def test_weights_sum_to_100(self):
        self.assertEqual(sum(WEIGHTS.values()), 100)

    def test_score_budget_full_overlap(self):
        profile_a = create_profile(self.user_a, budget_min=500, budget_max=800)
        profile_b = create_profile(self.user_b, budget_min=500, budget_max=800)
        self.assertEqual(score_budget(profile_a, profile_b), WEIGHTS["budget"])

    def test_score_budget_no_overlap(self):
        profile_a = create_profile(self.user_a, budget_min=500, budget_max=600)
        profile_b = create_profile(self.user_b, budget_min=2000, budget_max=2500)
        score = score_budget(profile_a, profile_b)
        self.assertLess(score, WEIGHTS["budget"] / 2)
        self.assertGreaterEqual(score, 0)

    def test_score_budget_partial_overlap(self):
        profile_a = create_profile(self.user_a, budget_min=500, budget_max=800)
        profile_b = create_profile(self.user_b, budget_min=700, budget_max=1000)
        score = score_budget(profile_a, profile_b)
        self.assertGreater(score, WEIGHTS["budget"] / 2)
        self.assertLess(score, WEIGHTS["budget"])

    def test_score_smoking_same(self):
        profile_a = create_profile(self.user_a, smoking=SmokingPreference.NON_SMOKER)
        profile_b = create_profile(self.user_b, smoking=SmokingPreference.NON_SMOKER)
        self.assertEqual(score_smoking(profile_a, profile_b), WEIGHTS["smoking"])

    def test_score_smoking_incompatible(self):
        profile_a = create_profile(self.user_a, smoking=SmokingPreference.NON_SMOKER)
        profile_b = create_profile(self.user_b, smoking=SmokingPreference.SMOKER)
        self.assertEqual(score_smoking(profile_a, profile_b), 0)

    def test_score_drinking_same(self):
        profile_a = create_profile(self.user_a, drinking="non_drinker")
        profile_b = create_profile(self.user_b, drinking="non_drinker")
        self.assertEqual(score_drinking(profile_a, profile_b), WEIGHTS["drinking"])

    def test_score_drinking_mismatch(self):
        profile_a = create_profile(self.user_a, drinking="non_drinker")
        profile_b = create_profile(self.user_b, drinking="drinker")
        score = score_drinking(profile_a, profile_b)
        self.assertGreaterEqual(score, 0)
        self.assertLess(score, WEIGHTS["drinking"])

    def test_score_sleep_schedule_same(self):
        profile_a = create_profile(
            self.user_a, sleep_schedule=SleepSchedule.EARLY_BIRD, wake_time=time(6, 0)
        )
        profile_b = create_profile(
            self.user_b, sleep_schedule=SleepSchedule.EARLY_BIRD, wake_time=time(6, 30)
        )
        score = score_sleep_schedule(profile_a, profile_b)
        self.assertGreater(score, WEIGHTS["sleep_schedule"] * 0.8)
        self.assertLessEqual(score, WEIGHTS["sleep_schedule"])

    def test_score_sleep_schedule_opposite(self):
        profile_a = create_profile(
            self.user_a, sleep_schedule=SleepSchedule.EARLY_BIRD, wake_time=time(6, 0)
        )
        profile_b = create_profile(
            self.user_b, sleep_schedule=SleepSchedule.NIGHT_OWL, wake_time=time(13, 0)
        )
        score = score_sleep_schedule(profile_a, profile_b)
        self.assertLess(score, WEIGHTS["sleep_schedule"] * 0.35)

    def test_score_cleanliness_identical(self):
        profile_a = create_profile(self.user_a, cleanliness=5)
        profile_b = create_profile(self.user_b, cleanliness=5)
        self.assertEqual(score_cleanliness(profile_a, profile_b), WEIGHTS["cleanliness"])

    def test_score_cleanliness_max_difference(self):
        profile_a = create_profile(self.user_a, cleanliness=1)
        profile_b = create_profile(self.user_b, cleanliness=5)
        self.assertEqual(score_cleanliness(profile_a, profile_b), 0)

    def test_score_noise_level_identical(self):
        profile_a = create_profile(self.user_a, noise_level=3)
        profile_b = create_profile(self.user_b, noise_level=3)
        self.assertEqual(score_noise_level(profile_a, profile_b), WEIGHTS["noise_level"])

    def test_score_noise_level_max_difference(self):
        profile_a = create_profile(self.user_a, noise_level=1)
        profile_b = create_profile(self.user_b, noise_level=5)
        self.assertEqual(score_noise_level(profile_a, profile_b), 0)

    def test_score_guests_identical(self):
        profile_a = create_profile(
            self.user_a, guests_preference=GuestsPreference.SOMETIMES
        )
        profile_b = create_profile(
            self.user_b, guests_preference=GuestsPreference.SOMETIMES
        )
        self.assertEqual(
            score_guests_preference(profile_a, profile_b), WEIGHTS["guests"]
        )

    def test_score_guests_max_difference(self):
        profile_a = create_profile(
            self.user_a, guests_preference=GuestsPreference.RARELY
        )
        profile_b = create_profile(
            self.user_b, guests_preference=GuestsPreference.FREQUENTLY
        )
        self.assertEqual(score_guests_preference(profile_a, profile_b), 0)

    def test_score_study_habit_match(self):
        profile_a = create_profile(self.user_a, study_habit=StudyHabit.QUIET)
        profile_b = create_profile(self.user_b, study_habit=StudyHabit.QUIET)
        self.assertEqual(
            score_study_habit(profile_a, profile_b), WEIGHTS["study_habit"]
        )

    def test_score_study_habit_mismatch(self):
        profile_a = create_profile(self.user_a, study_habit=StudyHabit.QUIET)
        profile_b = create_profile(
            self.user_b, study_habit=StudyHabit.GROUP_STUDY
        )
        self.assertEqual(
            score_study_habit(profile_a, profile_b), WEIGHTS["study_habit"] * 0.5
        )

    def test_score_food_identical(self):
        profile_a = create_profile(
            self.user_a, food_preference=FoodPreference.VEGETARIAN
        )
        profile_b = create_profile(
            self.user_b, food_preference=FoodPreference.VEGETARIAN
        )
        self.assertEqual(score_food(profile_a, profile_b), WEIGHTS["food"])

    def test_score_interests_full_match(self):
        profile_a = create_profile(
            self.user_a,
            interests=[self.interest_reading, self.interest_gaming],
        )
        profile_b = create_profile(
            self.user_b,
            interests=[self.interest_reading, self.interest_gaming],
        )
        self.assertEqual(score_interests(profile_a, profile_b), WEIGHTS["interests"])

    def test_score_interests_no_match(self):
        profile_a = create_profile(self.user_a, interests=[self.interest_reading])
        profile_b = create_profile(self.user_b, interests=[self.interest_hiking])
        self.assertEqual(score_interests(profile_a, profile_b), 0)

    def test_score_interests_no_interests(self):
        profile_a = create_profile(self.user_a)
        profile_b = create_profile(self.user_b)
        self.assertEqual(score_interests(profile_a, profile_b), 0)

    def test_calculate_score_identical_profiles(self):
        profile_a = create_profile(
            self.user_a,
            interests=[self.interest_reading, self.interest_gaming],
        )
        profile_b = create_profile(
            self.user_b,
            interests=[self.interest_reading, self.interest_gaming],
        )
        result = calculate_compatibility_score(profile_a, profile_b)
        self.assertEqual(result["total_score"], 100.0)
        self.assertFalse(result["blocked"])

    def test_calculate_score_no_pets_key_in_breakdown(self):
        profile_a = create_profile(self.user_a)
        profile_b = create_profile(self.user_b)
        result = calculate_compatibility_score(profile_a, profile_b)
        self.assertNotIn("pets", result["breakdown"])

    def test_calculate_score_within_bounds(self):
        profile_a = create_profile(self.user_a, interests=[self.interest_reading])
        profile_b = create_profile(
            self.user_b,
            budget_min=5000,
            budget_max=6000,
            smoking=SmokingPreference.SMOKER,
            cleanliness=1,
            food_preference=FoodPreference.NON_VEGETARIAN,
            interests=[self.interest_hiking],
        )
        result = calculate_compatibility_score(profile_a, profile_b)
        self.assertGreaterEqual(result["total_score"], 0)
        self.assertLessEqual(result["total_score"], 100)


class ServiceLayerTests(TestCase):
    def setUp(self):
        self.user_a = create_user("alice@test.com", "Alice")
        self.user_b = create_user("bob@test.com", "Bob")
        self.user_c = create_user("carol@test.com", "Carol")
        self.interest_reading = Interest.objects.create(name="Reading")

        self.profile_a = create_profile(
            self.user_a, interests=[self.interest_reading]
        )
        self.profile_b = create_profile(
            self.user_b, interests=[self.interest_reading]
        )
        self.profile_c = create_profile(
            self.user_c,
            budget_min=5000,
            budget_max=6000,
            smoking=SmokingPreference.SMOKER,
        )

    def test_get_active_profile_success(self):
        profile = get_active_profile_for_user(self.user_a)
        self.assertEqual(profile.pk, self.profile_a.pk)

    def test_get_active_profile_not_found(self):
        user_d = create_user("dave@test.com", "Dave")
        with self.assertRaises(RoommateProfileNotFoundError):
            get_active_profile_for_user(user_d)

    def test_get_active_profile_excludes_inactive(self):
        self.profile_a.is_active = False
        self.profile_a.save()
        with self.assertRaises(RoommateProfileNotFoundError):
            get_active_profile_for_user(self.user_a)

    def test_find_matches_excludes_self(self):
        matches = find_best_matches(self.user_a)
        matched_ids = [m["user_id"] for m in matches]
        self.assertNotIn(self.user_a.pk, matched_ids)

    def test_find_matches_sorted_descending(self):
        matches = find_best_matches(self.user_a)
        scores = [m["score"] for m in matches]
        self.assertEqual(scores, sorted(scores, reverse=True))

    def test_find_matches_respects_limit(self):
        matches = find_best_matches(self.user_a, limit=1)
        self.assertEqual(len(matches), 1)

    def test_persist_matches_creates_records(self):
        persist_matches_for_user(self.user_a)
        self.assertTrue(RoommateMatch.objects.filter(user=self.user_a).exists())

    def test_persist_matches_replaces_old_records(self):
        persist_matches_for_user(self.user_a)
        first_count = RoommateMatch.objects.filter(user=self.user_a).count()
        persist_matches_for_user(self.user_a)
        second_count = RoommateMatch.objects.filter(user=self.user_a).count()
        self.assertEqual(first_count, second_count)


class RoommateAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user_a = create_user("alice@test.com", "Alice")
        self.user_b = create_user("bob@test.com", "Bob")
        self.profile_a = create_profile(self.user_a)
        self.profile_b = create_profile(self.user_b)
        self.client.force_authenticate(user=self.user_a)

    def test_get_profile_requires_auth(self):
        anon = APIClient()
        response = anon.get(reverse("roommate:roommate-profile"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_get_profile_success(self):
        response = self.client.get(reverse("roommate:roommate-profile"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["budget_min"], 500)

    def test_get_profile_not_found(self):
        user_c = create_user("carol@test.com", "Carol")
        client = APIClient()
        client.force_authenticate(user=user_c)
        response = client.get(reverse("roommate:roommate-profile"))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_create_profile_rejected_if_exists(self):
        response = self.client.post(
            reverse("roommate:roommate-profile"),
            data={
                "budget_min": 400,
                "budget_max": 600,
                "sleep_schedule": "early_bird",
                "wake_time": "07:00:00",
                "smoking": "non_smoker",
                "drinking": "non_drinker",
                "cleanliness": 3,
                "noise_level": 3,
                "guests_preference": "sometimes",
                "food_preference": "vegetarian",
                "pets": "no_pets",
                "study_habit": "quiet",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_find_roommates_success(self):
        response = self.client.get(reverse("roommate:find-roommates"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)

    def test_find_roommates_no_profile(self):
        user_c = create_user("carol@test.com", "Carol")
        client = APIClient()
        client.force_authenticate(user=user_c)
        response = client.get(reverse("roommate:find-roommates"))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_find_roommates_invalid_limit(self):
        response = self.client.get(
            reverse("roommate:find-roommates"), {"limit": "abc"}
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_refresh_matches_success(self):
        response = self.client.post(reverse("roommate:refresh-matches"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(RoommateMatch.objects.filter(user=self.user_a).exists())