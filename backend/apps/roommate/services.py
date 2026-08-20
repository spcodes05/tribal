from typing import Optional

from django.contrib.auth import get_user_model
from django.db import transaction
from django.utils import timezone

from .models import RoommateMatch, RoommateProfile
from .ml.tribal_ml_recommender import find_matches_among

User = get_user_model()

# score_breakdown is stored/serialized through the same shape the old
# rule-based system used (ScoreBreakdownSerializer has these exact fields,
# required, no default) so the API contract and Flutter models don't need
# to change. The ML pipeline doesn't produce a per-category breakdown, so
# these are zero-filled; the real signal is RoommateMatch.compatibility_score
# itself (a bounded 0-100 value — see compatibility_from_distance() in
# tribal_ml_recommender.py), with raw ML debug info kept in
# score_breakdown under "_ml_distance"/"_ml_cluster".
_EMPTY_SCORE_BREAKDOWN = {
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
}

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


def _build_ml_user_data(profile: RoommateProfile) -> dict:
    """Builds the ML input dict for a single RoommateProfile, using the
    real Django field names/values. `gender` comes from the related User
    (CustomUser.gender), matching how the existing gender filter already
    reads it (see passes_gender_filter below) — it is NOT a RoommateProfile
    field. age/occupation/location/user_id are never included.

    CustomUser.gender is nullable (null=True, blank=True — it's only set
    partway through onboarding), so a user without it set yet falls back
    to "prefer_not_to_say", which is itself one of the real GENDER_CHOICES
    values and was present in the ML training data — this keeps such
    users matchable instead of raising/excluding them.
    """
    return {
        "gender": getattr(profile.user, "gender", None) or "prefer_not_to_say",
        "budget_min": profile.budget_min,
        "budget_max": profile.budget_max,
        "sleep_schedule": profile.sleep_schedule,
        "wake_time": profile.wake_time,
        "smoking": profile.smoking,
        "drinking": profile.drinking,
        "cleanliness": profile.cleanliness,
        "noise_level": profile.noise_level,
        "guests_preference": profile.guests_preference,
        "food_preference": profile.food_preference,
        "pets": profile.pets,
        "study_habit": profile.study_habit,
        "interests": list(profile.interests.values_list("name", flat=True)),
        "gender_preference": profile.gender_preference,
        "room_type_preference": profile.room_type_preference,
    }


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
    """
    Roommate ranking comes entirely from the trained K-Means-adjacent ML
    recommender (backend/apps/roommate/ml/tribal_ml_recommender.py) —
    NOT from the old rule-based calculate_compatibility_score(). The only
    scoring.py-equivalent logic still in play is the genuine hard
    eligibility filters (gender_preference / room_type_preference), which
    are pre-processing constraints, not part of the ML ranking — they are
    also deliberately excluded from the trained feature set itself (see
    tribal_ml_recommender.py docstring) to avoid double-counting the same
    signal.

    Compatibility is a bounded 0-100 score derived from normalized
    Euclidean distance in the trained feature space (see
    compatibility_from_distance() in the ML module) — identical profiles
    score 100%, and the score decays smoothly rather than collapsing.

    K-Means cluster membership is NOT used to filter candidates here —
    every eligible candidate (post hard-filter) is scored, not just
    same-cluster ones. Cluster is carried through as metadata only.
    """
    target_profile = get_active_profile_for_user(user)

    # Apply the existing hard eligibility filters BEFORE running anything
    # through the ML pipeline — cheaper, and keeps "hard filter" and
    # "compatibility ranking" clearly separated as required.
    eligible_candidates = [
        candidate
        for candidate in get_candidate_profiles(exclude_user_id=user.pk)
        if apply_hard_filters(target_profile, candidate)
    ]

    if not eligible_candidates:
        return []

    target_user_data = _build_ml_user_data(target_profile)
    candidate_lookup = {c.user_id: c for c in eligible_candidates}
    candidate_ml_data = [
        (c.user_id, _build_ml_user_data(c)) for c in eligible_candidates
    ]

    # Score every eligible candidate — no cluster-based pre-filtering, no
    # arbitrary pool-size sampling. Candidate pools for a roommate app are
    # not large enough (hundreds–low thousands of active profiles) for an
    # O(n) distance computation per request to be a real cost.
    ml_matches = find_matches_among(
        target_user_data, candidate_ml_data, top_n=len(candidate_ml_data)
    )

    scored_results = []
    for match in ml_matches:
        candidate_profile = candidate_lookup.get(match["user_id"])
        if candidate_profile is None:
            continue

        compatibility_percent = round(match["compatibility_score"], 2)
        if compatibility_percent < min_score:
            continue

        scored_results.append(
            {
                "user_id": match["user_id"],
                "profile": candidate_profile,
                "score": compatibility_percent,
                "breakdown": {
                    **_EMPTY_SCORE_BREAKDOWN,
                    "_ml_distance": match["distance"],
                    "_ml_cluster": match["cluster"],
                    "_ml_target_cluster": match["target_cluster"],
                },
                # The old smoking/budget/cleanliness "deal breaker" caps
                # were computed inside the removed weighted-scoring
                # formula (scoring.py) and are not reproduced here — only
                # the genuine hard filters above (gender/room type) are
                # preserved, and those already exclude non-matches rather
                # than flagging them.
                "deal_breaker": False,
                "deal_breaker_reasons": [],
            }
        )

    # ml_matches is already sorted by compatibility_score descending;
    # min_score filtering above preserves that order.
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
            score_breakdown={
                **match["breakdown"],
                "_deal_breaker": match.get("deal_breaker", False),
                "_deal_breaker_reasons": match.get("deal_breaker_reasons", []),
            },
        )
        for match in matches
    ]

    RoommateMatch.objects.bulk_create(match_objects)
    return matches


def get_saved_matches_for_user(user, limit: Optional[int] = 20) -> list:
    """
    Returns the same List[Dict] shape as find_best_matches(), so
    RoommateMatchResultSerializer never has to know whether matches came
    from a fresh computation or the RoommateMatch cache table.

    deal_breaker / deal_breaker_reasons were folded into score_breakdown
    at write time (see persist_matches_for_user) under the "_deal_breaker"
    and "_deal_breaker_reasons" keys — pull them back out here and strip
    them from the plain breakdown dict so ScoreBreakdownSerializer (which
    has a fixed set of fields) doesn't choke on the extra keys.
    """
    queryset = (
        RoommateMatch.objects.select_related(
            "matched_user", "matched_user__roommate_profile"
        )
        .filter(user=user)
        .order_by("-compatibility_score")
    )

    if limit is not None:
        queryset = queryset[:limit]

    results = []
    for match in queryset:
        matched_profile = getattr(match.matched_user, "roommate_profile", None)
        if matched_profile is None:
            # Matched user deactivated/deleted their roommate profile since
            # this match was cached — skip rather than serialize a None.
            continue

        stored_breakdown = dict(match.score_breakdown or {})
        deal_breaker = stored_breakdown.pop("_deal_breaker", False)
        deal_breaker_reasons = stored_breakdown.pop("_deal_breaker_reasons", [])

        results.append(
            {
                "user_id": match.matched_user_id,
                "profile": matched_profile,
                "score": match.compatibility_score,
                "breakdown": stored_breakdown,
                "deal_breaker": deal_breaker,
                "deal_breaker_reasons": deal_breaker_reasons,
            }
        )

    return results


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