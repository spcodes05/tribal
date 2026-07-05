from typing import Optional

from django.contrib.auth import get_user_model
from django.db import transaction
from django.utils import timezone

from .models import RoommateMatch, RoommateProfile
from .scoring import calculate_compatibility_score

User = get_user_model()

# Gender values on CustomUser that we treat as matching "non_binary"
# preference, plus the "prefer_not_to_say" case which we never filter out.
_GENDER_ANY = "any"
_GENDER_PREFER_NOT_TO_SAY = "prefer_not_to_say"


class RoommateProfileNotFoundError(Exception):
    pass


def get_active_profile_for_user(user) -> RoommateProfile:
    try:
        return (
            RoommateProfile.objects.select_related("user")
            .prefetch_related("interests")
            .get(user=user, is_active=True)
        )
    except RoommateProfile.DoesNotExist:
        raise RoommateProfileNotFoundError(
            f"No active roommate profile found for user_id={user.pk}"
        )


def get_candidate_profiles(exclude_user_id: int):
    return (
        RoommateProfile.objects.select_related("user")
        .prefetch_related("interests")
        .filter(is_active=True)
        .exclude(user_id=exclude_user_id)
    )


def passes_gender_filter(
    target_profile: RoommateProfile, candidate_profile: RoommateProfile
) -> bool:
    target_pref = target_profile.gender_preference

    # "any" preference matches everyone
    if target_pref == _GENDER_ANY:
        return True

    candidate_gender = getattr(candidate_profile.user, "gender", None)

    # If candidate has not set gender or chose "prefer_not_to_say",
    # we never exclude them — we can't know, so we let them through.
    if not candidate_gender or candidate_gender == _GENDER_PREFER_NOT_TO_SAY:
        return True

    # Direct match: target wants "male" → candidate must be "male", etc.
    # "non_binary" in GenderPreference matches "non_binary" on CustomUser.
    return candidate_gender == target_pref


def passes_room_type_filter(
    target_profile: RoommateProfile, candidate_profile: RoommateProfile
) -> bool:
    target_pref = target_profile.room_type_preference
    candidate_pref = candidate_profile.room_type_preference

    if target_pref == "any" or candidate_pref == "any":
        return True

    return target_pref == candidate_pref


def apply_hard_filters(
    target_profile: RoommateProfile, candidate_profile: RoommateProfile
) -> bool:
    if not passes_gender_filter(target_profile, candidate_profile):
        return False
    if not passes_room_type_filter(target_profile, candidate_profile):
        return False
    return True


def find_best_matches(
    user, limit: Optional[int] = 20, min_score: float = 0.0
) -> list:
    target_profile = get_active_profile_for_user(user)
    candidates = get_candidate_profiles(exclude_user_id=user.pk)

    scored_results = []

    for candidate_profile in candidates:
        if not apply_hard_filters(target_profile, candidate_profile):
            continue

        result = calculate_compatibility_score(target_profile, candidate_profile)

        if result["blocked"]:
            continue

        if result["total_score"] < min_score:
            continue

        scored_results.append(
            {
                "user_id": candidate_profile.user_id,
                "profile": candidate_profile,
                "score": result["total_score"],
                "breakdown": result["breakdown"],
            }
        )

    scored_results.sort(key=lambda item: item["score"], reverse=True)

    if limit is not None:
        scored_results = scored_results[:limit]

    return scored_results


@transaction.atomic
def persist_matches_for_user(
    user, limit: Optional[int] = 20, min_score: float = 0.0
) -> list:
    matches = find_best_matches(user, limit=limit, min_score=min_score)

    RoommateMatch.objects.filter(user=user).delete()

    match_objects = [
        RoommateMatch(
            user=user,
            matched_user_id=match["user_id"],
            compatibility_score=match["score"],
            score_breakdown=match["breakdown"],
        )
        for match in matches
    ]

    RoommateMatch.objects.bulk_create(match_objects)
    return matches


def get_saved_matches_for_user(user, limit: Optional[int] = 20):
    queryset = (
        RoommateMatch.objects.select_related(
            "matched_user", "matched_user__roommate_profile"
        )
        .filter(user=user)
        .order_by("-compatibility_score")
    )

    if limit is not None:
        queryset = queryset[:limit]

    return queryset


def refresh_matches_if_stale(
    user, max_age_minutes: int = 60, limit: Optional[int] = 20
):
    latest_match = (
        RoommateMatch.objects.filter(user=user).order_by("-updated_at").first()
    )

    if latest_match is None:
        return persist_matches_for_user(user, limit=limit)

    age_seconds = (timezone.now() - latest_match.updated_at).total_seconds()
    if age_seconds > max_age_minutes * 60:
        return persist_matches_for_user(user, limit=limit)

    return get_saved_matches_for_user(user, limit=limit)