from datetime import time
from typing import Iterable

from .models import RoommateProfile

WEIGHTS = {
    "cleanliness": 20,
    "budget": 20,
    "sleep_schedule": 15,
    "noise_level": 12,
    "smoking": 10,
    "guests": 8,
    "interests": 6,
    "study_habit": 4,
    "food": 3,
    "drinking": 2,
}

SLEEP_SCHEDULE_COMPATIBILITY = {
    ("early_bird", "early_bird"): 1.0,
    ("early_bird", "night_owl"): 0.0,
    ("early_bird", "flexible"): 0.7,
    ("night_owl", "early_bird"): 0.0,
    ("night_owl", "night_owl"): 1.0,
    ("night_owl", "flexible"): 0.7,
    ("flexible", "early_bird"): 0.7,
    ("flexible", "night_owl"): 0.7,
    ("flexible", "flexible"): 1.0,
}

SMOKING_COMPATIBILITY = {
    ("non_smoker", "non_smoker"): 1.0,
    ("non_smoker", "smoker"): 0.0,
    ("non_smoker", "occasional"): 0.4,
    ("smoker", "non_smoker"): 0.0,
    ("smoker", "smoker"): 1.0,
    ("smoker", "occasional"): 0.7,
    ("occasional", "non_smoker"): 0.4,
    ("occasional", "smoker"): 0.7,
    ("occasional", "occasional"): 1.0,
}

DRINKING_COMPATIBILITY = {
    ("non_drinker", "non_drinker"): 1.0,
    ("non_drinker", "drinker"): 0.3,
    ("non_drinker", "social"): 0.6,
    ("drinker", "non_drinker"): 0.3,
    ("drinker", "drinker"): 1.0,
    ("drinker", "social"): 0.8,
    ("social", "non_drinker"): 0.6,
    ("social", "drinker"): 0.8,
    ("social", "social"): 1.0,
}

FOOD_COMPATIBILITY = {
    ("vegetarian", "vegetarian"): 1.0,
    ("vegetarian", "vegan"): 0.9,
    ("vegetarian", "non_vegetarian"): 0.3,
    ("vegetarian", "no_preference"): 0.8,
    ("vegan", "vegan"): 1.0,
    ("vegan", "vegetarian"): 0.9,
    ("vegan", "non_vegetarian"): 0.2,
    ("vegan", "no_preference"): 0.7,
    ("non_vegetarian", "non_vegetarian"): 1.0,
    ("non_vegetarian", "vegetarian"): 0.3,
    ("non_vegetarian", "vegan"): 0.2,
    ("non_vegetarian", "no_preference"): 0.9,
    ("no_preference", "no_preference"): 1.0,
    ("no_preference", "vegetarian"): 0.8,
    ("no_preference", "vegan"): 0.7,
    ("no_preference", "non_vegetarian"): 0.9,
}

GUESTS_ORDER = {"rarely": 0, "sometimes": 1, "frequently": 2}


def _safe_ratio(value: float, max_value: float) -> float:
    if max_value <= 0:
        return 0.0
    ratio = value / max_value
    if ratio < 0.0:
        return 0.0
    if ratio > 1.0:
        return 1.0
    return ratio


def is_hard_blocked(profile_a: RoommateProfile, profile_b: RoommateProfile) -> bool:
    return False


def score_budget(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    a_min, a_max = profile_a.budget_min, profile_a.budget_max
    b_min, b_max = profile_b.budget_min, profile_b.budget_max

    overlap_start = max(a_min, b_min)
    overlap_end = min(a_max, b_max)

    if overlap_end < overlap_start:
        a_mid = (a_min + a_max) / 2
        b_mid = (b_min + b_max) / 2
        diff = abs(a_mid - b_mid)
        reference = max(a_mid, b_mid, 1)
        closeness = 1.0 - _safe_ratio(diff, reference)
        return max(closeness, 0.0) * WEIGHTS["budget"] * 0.5

    overlap_size = overlap_end - overlap_start
    union_size = max(a_max, b_max) - min(a_min, b_min)
    overlap_fraction = _safe_ratio(overlap_size, union_size) if union_size > 0 else 1.0

    return WEIGHTS["budget"] * (0.5 + 0.5 * overlap_fraction)


def score_smoking(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    key = (profile_a.smoking, profile_b.smoking)
    compatibility = SMOKING_COMPATIBILITY.get(key, 0.0)
    return WEIGHTS["smoking"] * compatibility


def score_drinking(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    key = (profile_a.drinking, profile_b.drinking)
    compatibility = DRINKING_COMPATIBILITY.get(key, 0.5)
    return WEIGHTS["drinking"] * compatibility


def score_sleep_schedule(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    key = (profile_a.sleep_schedule, profile_b.sleep_schedule)
    schedule_compatibility = SLEEP_SCHEDULE_COMPATIBILITY.get(key, 0.5)

    wake_a: time = profile_a.wake_time
    wake_b: time = profile_b.wake_time
    minutes_a = wake_a.hour * 60 + wake_a.minute
    minutes_b = wake_b.hour * 60 + wake_b.minute
    diff_minutes = abs(minutes_a - minutes_b)
    diff_minutes = min(diff_minutes, 1440 - diff_minutes)
    wake_time_closeness = 1.0 - _safe_ratio(diff_minutes, 360)

    combined = (0.7 * schedule_compatibility) + (0.3 * wake_time_closeness)
    return WEIGHTS["sleep_schedule"] * combined


def score_cleanliness(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    diff = abs(profile_a.cleanliness - profile_b.cleanliness)
    closeness = 1.0 - _safe_ratio(diff, 4)
    return WEIGHTS["cleanliness"] * closeness


def score_noise_level(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    diff = abs(profile_a.noise_level - profile_b.noise_level)
    closeness = 1.0 - _safe_ratio(diff, 4)
    return WEIGHTS["noise_level"] * closeness


def score_guests_preference(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    a_val = GUESTS_ORDER.get(profile_a.guests_preference, 1)
    b_val = GUESTS_ORDER.get(profile_b.guests_preference, 1)
    diff = abs(a_val - b_val)
    closeness = 1.0 - _safe_ratio(diff, 2)
    return WEIGHTS["guests"] * closeness


def score_interests(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    interests_a = set(profile_a.interests.values_list("id", flat=True))
    interests_b = set(profile_b.interests.values_list("id", flat=True))

    if not interests_a or not interests_b:
        return 0.0

    intersection = interests_a & interests_b
    union = interests_a | interests_b

    if not union:
        return 0.0

    jaccard = len(intersection) / len(union)
    return WEIGHTS["interests"] * jaccard


def score_study_habit(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    compatibility = 1.0 if profile_a.study_habit == profile_b.study_habit else 0.5
    return WEIGHTS["study_habit"] * compatibility


def score_food(profile_a: RoommateProfile, profile_b: RoommateProfile) -> float:
    key = (profile_a.food_preference, profile_b.food_preference)
    compatibility = FOOD_COMPATIBILITY.get(key, 0.5)
    return WEIGHTS["food"] * compatibility


def calculate_compatibility_score(
    profile_a: RoommateProfile,
    profile_b: RoommateProfile,
) -> dict:
    if is_hard_blocked(profile_a, profile_b):
        return {
            "total_score": 0.0,
            "breakdown": {
                "cleanliness": 0.0,
                "budget": 0.0,
                "sleep_schedule": 0.0,
                "noise_level": 0.0,
                "smoking": 0.0,
                "guests": 0.0,
                "interests": 0.0,
                "study_habit": 0.0,
                "food": 0.0,
                "drinking": 0.0,
            },
            "blocked": True,
            "block_reason": "hard_filter",
        }

    breakdown = {
        "cleanliness": round(score_cleanliness(profile_a, profile_b), 2),
        "budget": round(score_budget(profile_a, profile_b), 2),
        "sleep_schedule": round(score_sleep_schedule(profile_a, profile_b), 2),
        "noise_level": round(score_noise_level(profile_a, profile_b), 2),
        "smoking": round(score_smoking(profile_a, profile_b), 2),
        "guests": round(score_guests_preference(profile_a, profile_b), 2),
        "interests": round(score_interests(profile_a, profile_b), 2),
        "study_habit": round(score_study_habit(profile_a, profile_b), 2),
        "food": round(score_food(profile_a, profile_b), 2),
        "drinking": round(score_drinking(profile_a, profile_b), 2),
    }

    total_score = sum(breakdown.values())
    total_score = max(0.0, min(100.0, total_score))

    return {
        "total_score": round(total_score, 2),
        "breakdown": breakdown,
        "blocked": False,
        "block_reason": None,
    }


def rank_matches(
    target_profile: RoommateProfile,
    candidate_profiles: Iterable[RoommateProfile],
) -> list:
    results = []

    for candidate in candidate_profiles:
        if candidate.pk == target_profile.pk:
            continue

        result = calculate_compatibility_score(target_profile, candidate)

        if result["blocked"]:
            continue

        results.append(
            {
                "profile": candidate,
                "score": result["total_score"],
                "breakdown": result["breakdown"],
            }
        )

    results.sort(key=lambda item: item["score"], reverse=True)
    return results