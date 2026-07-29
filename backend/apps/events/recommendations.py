"""
TRIBAL Recommendation Engine
==============================

Implements two algorithms:

1. People Matching  — who you should vibe with
   Score(u,v) = 0.50 × JaccardInterests
              + 0.30 × ActivityOverlap
              + 0.20 × LocationScore

2. Activity Recommendation  — what activities to show
   Score(u,a) = 0.70 × JaccardTags
              + 0.20 × PopularityScore
              + 0.10 × LocationScore

Both use Jaccard similarity for set-based comparisons because:
  - Interest/tag data is binary (either you have it or you don't)
  - Jaccard is naturally bounded [0,1], no normalisation needed
  - Jaccard is explainable in a project report
  - Cosine similarity over binary vectors ≈ Jaccard for our data size;
    not worth the added complexity

Location uses the Haversine formula (great-circle distance) which is
accurate enough for city-scale distances without PostGIS.
"""

import math
from typing import Optional


# ── Weights ───────────────────────────────────────────────────────────────────

PEOPLE_WEIGHTS = {
    'interests':         0.50,
    'activity_overlap':  0.30,
    'location':          0.20,
}

ACTIVITY_WEIGHTS = {
    'tags':       0.70,
    'popularity': 0.20,
    'location':   0.10,
}

# Beyond this distance (km) the location score is 0.
MAX_DISTANCE_KM = 50.0


# ── Core similarity functions ─────────────────────────────────────────────────

def jaccard(set_a: set, set_b: set) -> float:
    """
    Jaccard similarity between two sets.

    J(A, B) = |A ∩ B| / |A ∪ B|

    Returns 0.0 if both sets are empty (avoids division by zero).

    Example:
        User A interests = {Hiking, Music, Gaming}
        User B interests = {Hiking, Cooking, Gaming}
        J = 2/4 = 0.50
    """
    if not set_a and not set_b:
        return 0.0
    intersection = len(set_a & set_b)
    union = len(set_a | set_b)
    return intersection / union


def haversine_km(lat1: Optional[float], lon1: Optional[float],
                 lat2: Optional[float], lon2: Optional[float]) -> Optional[float]:
    """
    Great-circle distance in km between two lat/lng points.
    Returns None if either point is missing coordinates.

    Uses the Haversine formula — accurate to ~0.3% for distances
    under 1000 km, which is more than enough for city-scale matching.
    """
    if None in (lat1, lon1, lat2, lon2):
        return None

    R = 6371.0  # Earth radius in km
    phi1, phi2 = math.radians(float(lat1)), math.radians(float(lat2))
    dphi = math.radians(float(lat2) - float(lat1))
    dlambda = math.radians(float(lon2) - float(lon1))

    a = (math.sin(dphi / 2) ** 2
         + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def location_score(lat1, lon1, lat2, lon2,
                   max_km: float = MAX_DISTANCE_KM) -> float:
    """
    Converts distance to a [0, 1] score using linear decay.

    score = 1 - (distance / max_km)   if distance <= max_km
    score = 0                          if distance > max_km or coords missing

    Linear decay is simple and fair:
      0 km  → 1.0  (same spot)
      25 km → 0.5
      50 km → 0.0  (cutoff)

    An exponential decay could be used for a sharper local bias,
    but linear is more explainable for a student project report.
    """
    dist = haversine_km(lat1, lon1, lat2, lon2)
    if dist is None:
        return 0.0
    if dist >= max_km:
        return 0.0
    return 1.0 - (dist / max_km)


# ── People recommendation ─────────────────────────────────────────────────────

def score_person_match(
    user_interests: set,
    user_activity_ids: set,
    user_lat, user_lon,
    candidate_interests: set,
    candidate_activity_ids: set,
    candidate_lat, candidate_lon,
) -> dict:
    """
    Computes the full people match score between two users.

    Parameters
    ----------
    user_interests        : set of interest name strings for the requesting user
    user_activity_ids     : set of activity IDs the requesting user has joined
    user_lat / user_lon   : requesting user's coordinates (may be None)
    candidate_*           : same fields for the candidate user

    Returns
    -------
    dict with individual component scores + final weighted score, e.g.:
    {
        'interest_sim':      0.67,
        'activity_overlap':  0.33,
        'location_score':    0.80,
        'final_score':       0.57,
        'match_percent':     57,
    }
    """
    interest_sim     = jaccard(user_interests, candidate_interests)
    activity_overlap = jaccard(user_activity_ids, candidate_activity_ids)
    loc_score        = location_score(user_lat, user_lon, candidate_lat, candidate_lon)

    final = (
        PEOPLE_WEIGHTS['interests']        * interest_sim
        + PEOPLE_WEIGHTS['activity_overlap'] * activity_overlap
        + PEOPLE_WEIGHTS['location']         * loc_score
    )

    return {
        'interest_sim':     round(interest_sim, 4),
        'activity_overlap': round(activity_overlap, 4),
        'location_score':   round(loc_score, 4),
        'final_score':      round(final, 4),
        'match_percent':    round(final * 100),
    }


def rank_people(requesting_user, candidates) -> list:
    """
    Ranks a queryset of candidate users by match score against requesting_user.

    Parameters
    ----------
    requesting_user : CustomUser instance
    candidates      : queryset of CustomUser instances
                      (should have interests + joined_activities prefetched)

    Returns
    -------
    List of dicts sorted by final_score descending:
    [
        {
            'user':          <CustomUser>,
            'match_percent': 72,
            'interest_sim':  0.67,
            ...
        },
        ...
    ]
    """
    # Build requesting user's data once (not inside the loop)
    u_interests    = set(requesting_user.interests.values_list('name', flat=True))
    u_activity_ids = set(requesting_user.joined_activities.values_list('activity_id', flat=True))
    u_lat = requesting_user.latitude
    u_lon = requesting_user.longitude

    results = []
    for candidate in candidates:
        c_interests    = set(candidate.interests.values_list('name', flat=True))
        c_activity_ids = set(candidate.joined_activities.values_list('activity_id', flat=True))
        c_lat = candidate.latitude
        c_lon = candidate.longitude

        scores = score_person_match(
            u_interests, u_activity_ids, u_lat, u_lon,
            c_interests, c_activity_ids, c_lat, c_lon,
        )
        results.append({'user': candidate, **scores})

    return sorted(results, key=lambda x: x['final_score'], reverse=True)


# ── Activity recommendation ───────────────────────────────────────────────────

def score_activity(
    user_interests: set,
    user_lat, user_lon,
    activity_tags: set,
    activity_member_count: int,
    activity_max_members: int,
    activity_lat, activity_lon,
) -> dict:
    """
    Computes the activity recommendation score for one (user, activity) pair.

    Parameters
    ----------
    user_interests          : set of interest name strings
    user_lat / user_lon     : user's coordinates (may be None)
    activity_tags           : set of tag name strings on the activity
    activity_member_count   : how many people have joined
    activity_max_members    : capacity
    activity_lat / lon      : activity's coordinates (may be None)

    Returns
    -------
    dict with component scores + final score, e.g.:
    {
        'tag_similarity':   0.60,
        'popularity_score': 0.40,
        'location_score':   0.90,
        'final_score':      0.65,
        'match_percent':    65,
    }
    """
    tag_sim = jaccard(user_interests, activity_tags)

    # Popularity: ratio of joined members to capacity, bounded [0, 1]
    # A full activity scores 1.0; an empty one scores 0.0.
    # This naturally surfaces trending / popular events.
    if activity_max_members > 0:
        popularity = min(1.0, activity_member_count / activity_max_members)
    else:
        popularity = 0.0

    loc_score = location_score(user_lat, user_lon, activity_lat, activity_lon)

    final = (
        ACTIVITY_WEIGHTS['tags']       * tag_sim
        + ACTIVITY_WEIGHTS['popularity'] * popularity
        + ACTIVITY_WEIGHTS['location']   * loc_score
    )

    return {
        'tag_similarity':   round(tag_sim, 4),
        'popularity_score': round(popularity, 4),
        'location_score':   round(loc_score, 4),
        'final_score':      round(final, 4),
        'match_percent':    round(final * 100),
    }


def rank_activities(requesting_user, activities) -> list:
    """
    Ranks a queryset of Activity instances by recommendation score.

    Parameters
    ----------
    requesting_user : CustomUser instance (needs interests + lat/lon)
    activities      : queryset with tags + members prefetched

    Returns
    -------
    List of dicts sorted by final_score descending:
    [
        {
            'activity':      <Activity>,
            'match_percent': 65,
            'tag_similarity': 0.60,
            ...
        },
        ...
    ]
    """
    u_interests = set(requesting_user.interests.values_list('name', flat=True))
    u_lat = requesting_user.latitude
    u_lon = requesting_user.longitude

    results = []
    for activity in activities:
        a_tags = set(activity.tags.values_list('name', flat=True))
        scores = score_activity(
            u_interests, u_lat, u_lon,
            a_tags,
            activity.member_count,
            activity.max_members,
            activity.latitude,
            activity.longitude,
        )
        results.append({'activity': activity, **scores})

    return sorted(results, key=lambda x: x['final_score'], reverse=True)
