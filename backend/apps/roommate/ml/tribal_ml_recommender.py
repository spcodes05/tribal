"""
tribal_ml_recommender.py

Inference-only module for Tribal's K-Means roommate recommendation system.
Lives at backend/apps/roommate/ml/ alongside the trained artifacts:

    tribal_kmeans_model.pkl
    tribal_preprocessor.pkl
    tribal_cluster_data.pkl

This module does NOT retrain the model and does NOT use the old
rule-based scoring in backend/apps/roommate/scoring.py. Artifacts are
produced by train_kmeans_domain_weighted.py — NOT retrain_kmeans_k4.py,
which is stale (old K=4, flat/unweighted feature space) and must not be
used; see DEPRECATED_retrain_kmeans_k4.md.

════════════════════════════════════════════════════════════════════════
FEATURE SPACE — domain-weighted, block-normalized (feature_space_version
"domain_weighted_v1")
════════════════════════════════════════════════════════════════════════
Every one of the 47 trained features belongs to exactly one of 11
domains (budget, numeric, gender, sleep_schedule, smoking, drinking,
guests, food, pets, study, interests). At both training and inference:

  1. Each domain's block is built with its OWN fitted StandardScaler (for
     budget/numeric) or OneHotEncoder (one per categorical domain), or
     multi-hot vocabulary (interests) — exactly as before.
  2. The whole block is divided by a single RMS scalar
     (sqrt(mean(block ** 2)), computed ONCE at training time over ALL
     elements of the block and persisted in tribal_preprocessor.pkl) so a
     domain with many one-hot columns (e.g. interests, 12 columns) does
     not automatically dominate a domain with one or two continuous
     columns purely because it has more dimensions.
  3. The normalized block is multiplied by that domain's fixed importance
     weight.
  4. Weighted blocks are concatenated in a fixed order
     (`preprocessor["domain_order"]`) into the final (1, 47) vector. This
     IS the feature space the model was trained on — there is no
     separate "raw" feature space anywhere in this pipeline.

Domain weights (intentional, fixed — see project decision, not to be
changed here without a concrete implementation-bug justification):

    gender=5.0, budget=4.5, sleep_schedule=3.0, numeric=1.5,
    smoking=1.5, food=1.25, study=1.25, guests=1.0, interests=1.0,
    drinking=0.75, pets=0.5

IMPORTANT — read before assuming this is a "balanced" score: because of
these weights, `gender` and `budget` together account for ~100% of the
model's between-cluster separation (~62% / ~38% respectively) on the
training data; every other domain's contribution is <0.01%. Concretely,
this means the Euclidean distance (and therefore compatibility_score
below) between two users is overwhelmingly driven by whether they share
the same `gender` value and how close their budgets are — sleep
schedule, cleanliness, noise, smoking, food, drinking, interests,
guests, and study habits move the score only marginally, even though
they are all still present in the feature vector. This was a deliberate
product decision (gender is meant to dominate matching), not a
side-effect of an unrelated change — flag before altering the weights.

════════════════════════════════════════════════════════════════════════
COMPATIBILITY SCORE — how it's actually calculated
════════════════════════════════════════════════════════════════════════
The Euclidean distance between two users' final (domain-weighted) feature
vectors is a real, meaningful similarity measure — but it is NOT bounded
to [0, 1], so it cannot be turned into a percentage by a formula like
`1/(1+distance)`: that collapses to a low percentage far too quickly, and
has no natural interpretation.

Instead, `tribal_preprocessor.pkl` stores `max_distance`: the length of
the diagonal of the bounding box containing every training profile's
FINAL (domain-weighted) feature vector (per-dimension observed range,
combined via sqrt(sum-of-squares)). This is a real, data-derived upper
bound on how far apart any two profiles built from this encoding can be.
Compatibility is then:

    compatibility = 100 * max(0, 1 - distance / max_distance)

Properties (all deliberately required, not incidental):
  - identical profiles  -> distance = 0        -> compatibility = 100%
  - Euclidean distance is symmetric             -> compatibility(A,B) == compatibility(B,A)
  - deterministic (no randomness at inference)
  - bounded to [0, 100] (clipped; a live profile with values outside the
    training range could in theory push distance slightly past
    max_distance, which is clipped to 0% rather than going negative)

K-MEANS' ROLE: cluster membership is a real, materially-used ranking
signal — NOT just metadata, and NOT a hard filter. `compatibility_score`
itself is still computed purely from Euclidean distance (unchanged,
still deterministic/symmetric — see compatibility_from_distance()).
Separately, `find_matches_among()` computes a `recommendation_score`
used ONLY for sort order:

    recommendation_score = clip(compatibility_score + CLUSTER_SAME_BONUS
                                 if candidate_cluster == target_cluster
                                 else compatibility_score, 0, 100)

CLUSTER_SAME_BONUS (see constant below) is a small, fixed, documented
point bonus — not a learned weight — added when a candidate's predicted
cluster matches the target's predicted cluster. Candidates in a
DIFFERENT cluster from the target are never discarded — they remain
fully eligible and are returned as fallback, just without the bonus, so
the system never returns zero recommendations purely because of cluster
boundaries. This gives the three-stage architecture: hard eligibility
filters (services.py) -> K-Means cluster-based candidate prioritization
-> Euclidean feature-space compatibility ranking.

`gender_preference` and `room_type_preference` (who a user is WILLING to
live with) are NOT part of the trained feature set — see
tribal_preprocessor.pkl / train_kmeans_domain_weighted.py. They remain
hard eligibility filters in services.py (passes_gender_filter /
passes_room_type_filter), evaluated before ML scoring. A user's own
`gender` (not their preference) IS a trained ML feature, and — per the
domain weights above — the dominant one.

════════════════════════════════════════════════════════════════════════

The three .pkl files are loaded ONCE at module import time (module-level
globals below), not per-request.

Usage from Django (backend/apps/roommate/services.py):

    from .ml.tribal_ml_recommender import find_matches_among, predict_cluster

    matches = find_matches_among(target_user_data, candidates, top_n=50)
    # matches -> [{"user_id": ..., "compatibility_score": ..., "distance": ..., "cluster": ...}, ...]

`user_data` is a plain dict shaped like a RoommateProfile + the user's
gender, e.g.:

{
    "gender": "male",
    "budget_min": 11000,
    "budget_max": 16000,
    "sleep_schedule": "night_owl",
    "wake_time": "08:30",              # "HH:MM"/"HH:MM:SS" string OR datetime.time
    "smoking": "non_smoker",
    "drinking": "social",
    "cleanliness": 4,
    "noise_level": 2,
    "guests_preference": "sometimes",
    "food_preference": "vegetarian",
    "pets": "okay_with_pets",
    "study_habit": "quiet",
    "interests": ["Hiking", "Music"],   # list OR "Hiking|Music" string
}

`gender_preference` and `room_type_preference` may still be present in
the dict (services.py needs them for hard filtering) — this module simply
ignores them, same as `user_id`/`age`/`occupation`/`location`.

Hard eligibility filters are NOT applied here — that stays in services.py,
which has access to the full candidate RoommateProfile/User objects
needed to evaluate them. This module is only responsible for computing
the ML compatibility score.
"""

import datetime
import pickle
from pathlib import Path

import numpy as np
import pandas as pd

_ARTIFACT_DIR = Path(__file__).resolve().parent

_MODEL_PATH = _ARTIFACT_DIR / "tribal_kmeans_model.pkl"
_PREPROCESSOR_PATH = _ARTIFACT_DIR / "tribal_preprocessor.pkl"
_CLUSTER_DATA_PATH = _ARTIFACT_DIR / "tribal_cluster_data.pkl"

# Must match train_kmeans_domain_weighted.py's FEATURE_SPACE_VERSION.
# Any artifact set stamped with a different version (e.g. a leftover
# retrain_kmeans_k4.py-era model, or a preprocessor regenerated without
# retraining the model) fails loudly at import time instead of silently
# producing vectors the model was never trained to interpret.
_EXPECTED_FEATURE_SPACE_VERSION = "domain_weighted_v1"
_EXPECTED_N_FEATURES = 47

# Fixed, documented ranking bonus applied when a candidate's predicted
# K-Means cluster matches the target user's predicted cluster. This is
# what makes cluster membership materially affect final ranking instead
# of being metadata-only. Deliberately small relative to the 0-100
# compatibility_score scale (dominated by gender/budget domain weights,
# see docstring) so it acts as a same-cluster priority/tie-breaker on
# top of real profile similarity, not a replacement for it. Candidates
# in a different cluster are never dropped -- they simply don't receive
# the bonus and remain available as fallback.
CLUSTER_SAME_BONUS = 5.0

# Fields actually required to build a feature vector. gender_preference
# and room_type_preference are deliberately NOT in this list — they are
# hard filters, not ML features (see module docstring).
REQUIRED_FIELDS = [
    "gender",
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
]

# Fields that must NEVER be used as ML features, even if present in the
# input dict (a caller may pass a full user/profile dict that happens to
# include these — e.g. services.py's dict also carries gender_preference/
# room_type_preference for its own hard-filter use).
_EXCLUDED_FIELDS = {
    "user_id", "age", "occupation", "location",
    "gender_preference", "room_type_preference",
}


class TribalRecommenderError(Exception):
    pass


def _load_artifacts():
    if not _MODEL_PATH.exists():
        raise TribalRecommenderError(f"Missing model artifact: {_MODEL_PATH}")
    if not _PREPROCESSOR_PATH.exists():
        raise TribalRecommenderError(f"Missing preprocessor artifact: {_PREPROCESSOR_PATH}")
    if not _CLUSTER_DATA_PATH.exists():
        raise TribalRecommenderError(f"Missing cluster data artifact: {_CLUSTER_DATA_PATH}")

    try:
        with open(_MODEL_PATH, "rb") as f:
            model = pickle.load(f)
        with open(_PREPROCESSOR_PATH, "rb") as f:
            preprocessor = pickle.load(f)
        with open(_CLUSTER_DATA_PATH, "rb") as f:
            cluster_data = pickle.load(f)
    except ModuleNotFoundError as exc:
        raise TribalRecommenderError(
            "Failed to load ML artifacts — scikit-learn (and/or numpy/"
            "pandas) may not be installed in this environment. "
            f"Original error: {exc}"
        ) from exc

    if "max_distance" not in preprocessor or not preprocessor["max_distance"]:
        raise TribalRecommenderError(
            "tribal_preprocessor.pkl is missing 'max_distance' — it was "
            "trained with an older version of the training script. "
            "Retrain with train_kmeans_domain_weighted.py to regenerate it."
        )

    # ── artifact/version consistency checks — fail loudly rather than
    # silently producing bad recommendations ──
    required_preprocessor_keys = [
        "numeric_features", "budget_features", "categorical_domain_columns",
        "interest_vocab", "scaler_numeric", "scaler_budget", "encoders",
        "domain_order", "domain_slices", "domain_rms", "domain_weights",
        "expected_domain_dims", "feature_names", "n_features_total",
        "feature_space_version",
    ]
    missing_keys = [k for k in required_preprocessor_keys if k not in preprocessor]
    if missing_keys:
        raise TribalRecommenderError(
            "tribal_preprocessor.pkl is missing required keys "
            f"{missing_keys} — it was built by an incompatible/older "
            "training script. Retrain with train_kmeans_domain_weighted.py."
        )

    preprocessor_version = preprocessor["feature_space_version"]
    model_version = getattr(model, "feature_space_version", None)

    if preprocessor_version != _EXPECTED_FEATURE_SPACE_VERSION:
        raise TribalRecommenderError(
            f"tribal_preprocessor.pkl feature_space_version="
            f"{preprocessor_version!r} does not match the version this "
            f"module expects ({_EXPECTED_FEATURE_SPACE_VERSION!r}). "
            "Regenerate artifacts with train_kmeans_domain_weighted.py."
        )
    if model_version is None:
        raise TribalRecommenderError(
            "tribal_kmeans_model.pkl has no 'feature_space_version' "
            "attribute — it was likely trained by the stale "
            "retrain_kmeans_k4.py script. Retrain with "
            "train_kmeans_domain_weighted.py."
        )
    if model_version != preprocessor_version:
        raise TribalRecommenderError(
            f"Artifact mismatch: tribal_kmeans_model.pkl "
            f"feature_space_version={model_version!r} != "
            f"tribal_preprocessor.pkl feature_space_version="
            f"{preprocessor_version!r}. These artifacts were not produced "
            "by the same training run — regenerate both together with "
            "train_kmeans_domain_weighted.py."
        )

    cluster_data_version = cluster_data.get("feature_space_version")
    if cluster_data_version != preprocessor_version:
        raise TribalRecommenderError(
            f"Artifact mismatch: tribal_cluster_data.pkl "
            f"feature_space_version={cluster_data_version!r} != "
            f"tribal_preprocessor.pkl feature_space_version="
            f"{preprocessor_version!r}. Regenerate all three artifacts "
            "together with train_kmeans_domain_weighted.py."
        )

    n_features_total = preprocessor["n_features_total"]
    if n_features_total != _EXPECTED_N_FEATURES:
        raise TribalRecommenderError(
            f"tribal_preprocessor.pkl n_features_total={n_features_total} "
            f"!= expected {_EXPECTED_N_FEATURES}."
        )
    model_n_features = getattr(model, "n_features_in_", None)
    if model_n_features is not None and model_n_features != n_features_total:
        raise TribalRecommenderError(
            f"tribal_kmeans_model.pkl expects {model_n_features} features "
            f"but tribal_preprocessor.pkl produces {n_features_total}."
        )

    return model, preprocessor, cluster_data


# Loaded once at import time.
_MODEL, _PREPROCESSOR, _CLUSTER_DATA = _load_artifacts()
_MAX_DISTANCE = _PREPROCESSOR["max_distance"]
_DOMAIN_ORDER = _PREPROCESSOR["domain_order"]
_DOMAIN_WEIGHTS = _PREPROCESSOR["domain_weights"]
_DOMAIN_RMS = _PREPROCESSOR["domain_rms"]
_CATEGORICAL_DOMAIN_COLUMNS = _PREPROCESSOR["categorical_domain_columns"]


def _normalize_interests(raw_interests) -> str:
    if raw_interests is None:
        return ""
    if isinstance(raw_interests, str):
        return raw_interests
    return "|".join(str(x) for x in raw_interests)


def _normalize_wake_time(raw_wake_time) -> str:
    if isinstance(raw_wake_time, (datetime.time, datetime.datetime)):
        return raw_wake_time.strftime("%H:%M")
    if isinstance(raw_wake_time, str):
        parts = raw_wake_time.split(":")
        return f"{int(parts[0]):02d}:{int(parts[1]):02d}"
    raise TribalRecommenderError(
        f"Unsupported wake_time type: {type(raw_wake_time)!r}"
    )


def _validate_user_data(user_data: dict) -> dict:
    missing = [f for f in REQUIRED_FIELDS if f not in user_data or user_data[f] is None]
    if missing:
        raise TribalRecommenderError(
            f"user_data is missing required roommate-profile fields: {missing}"
        )
    cleaned = {k: v for k, v in user_data.items() if k not in _EXCLUDED_FIELDS}
    cleaned["interests"] = _normalize_interests(cleaned.get("interests"))
    cleaned["wake_time"] = _normalize_wake_time(cleaned.get("wake_time"))
    return cleaned


def _engineer_wake_time(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    parsed = pd.to_datetime(df["wake_time"], format="%H:%M")
    minutes = parsed.dt.hour * 60 + parsed.dt.minute
    df["wake_time_minutes"] = minutes
    df["wake_time_sin"] = np.sin(2 * np.pi * minutes / 1440)
    df["wake_time_cos"] = np.cos(2 * np.pi * minutes / 1440)
    return df


def _build_interest_multihot(df: pd.DataFrame, vocab: list) -> pd.DataFrame:
    interest_sets = df["interests"].fillna("").apply(
        lambda s: set(x for x in s.split("|") if x)
    )
    data = {
        f"interest_{name.replace(' ', '_')}": interest_sets.apply(
            lambda s, n=name: 1 if n in s else 0
        )
        for name in vocab
    }
    return pd.DataFrame(data, index=df.index)


def _transform(user_data: dict) -> np.ndarray:
    """Applies the exact same domain-weighted, block-normalized
    preprocessing pipeline used at training time (loaded from
    tribal_preprocessor.pkl) to a single user's data, producing a
    (1, 47) vector in the FINAL feature space — the only feature space
    this model was trained on. See module docstring for the domain
    weights and what they imply for the resulting compatibility score."""
    cleaned = _validate_user_data(user_data)
    df = pd.DataFrame([cleaned])
    df = _engineer_wake_time(df)

    numeric_features = _PREPROCESSOR["numeric_features"]
    budget_features = _PREPROCESSOR["budget_features"]
    interest_vocab = _PREPROCESSOR["interest_vocab"]

    blocks = {}

    # budget
    budget_scaled = _PREPROCESSOR["scaler_budget"].transform(df[budget_features])
    blocks["budget"] = budget_scaled / _DOMAIN_RMS["budget"]

    # numeric (non-budget)
    numeric_scaled = _PREPROCESSOR["scaler_numeric"].transform(df[numeric_features])
    blocks["numeric"] = numeric_scaled / _DOMAIN_RMS["numeric"]

    # one categorical domain per fitted encoder
    for domain, cols in _CATEGORICAL_DOMAIN_COLUMNS.items():
        enc = _PREPROCESSOR["encoders"][domain]
        try:
            encoded = enc.transform(df[cols])
        except KeyError as exc:
            raise TribalRecommenderError(
                f"user_data is missing field(s) required for domain "
                f"'{domain}': {cols}"
            ) from exc
        blocks[domain] = encoded / _DOMAIN_RMS[domain]

    # interests
    interest_matrix = _build_interest_multihot(df, interest_vocab).values.astype(float)
    blocks["interests"] = interest_matrix / _DOMAIN_RMS["interests"]

    # apply domain weights and concatenate in the exact fitted order —
    # never guessed, never re-derived from dict/column ordering.
    weighted_blocks = [blocks[domain] * _DOMAIN_WEIGHTS[domain] for domain in _DOMAIN_ORDER]
    feature_vector = np.hstack(weighted_blocks)

    if feature_vector.shape[1] != _EXPECTED_N_FEATURES:
        raise TribalRecommenderError(
            f"Transformed feature vector has {feature_vector.shape[1]} "
            f"columns, expected {_EXPECTED_N_FEATURES}. This indicates a "
            "preprocessing/artifact inconsistency, not bad user input."
        )

    return feature_vector


def compatibility_from_distance(distance: float) -> float:
    """
    Converts a raw Euclidean distance in the trained feature space into a
    bounded, meaningful 0-100 compatibility percentage:

        compatibility = 100 * max(0, 1 - distance / max_distance)

    max_distance is the bounding-box diagonal, in the FINAL domain-weighted
    feature space, over the training data (stored in tribal_preprocessor.pkl
    at training time — see train_kmeans_domain_weighted.py).
    distance=0 -> 100.0 exactly. Distances beyond
    max_distance (possible if a live profile's numeric values fall
    outside the training range) are clipped to 0.0 rather than going
    negative.
    """
    raw = 100.0 * (1.0 - (distance / _MAX_DISTANCE))
    return float(np.clip(raw, 0.0, 100.0))


def predict_cluster(user_data: dict) -> int:
    """Predicts the K-Means cluster for a single user's roommate profile.
    Informational/grouping metadata only — NOT used to gate or weight the
    compatibility score (see module docstring)."""
    feature_vector = _transform(user_data)
    return int(_MODEL.predict(feature_vector)[0])


def transform_user(user_data: dict) -> np.ndarray:
    """Public wrapper around the preprocessing pipeline. Returns the raw
    feature vector (shape (1, n_features)) for a single user's roommate
    profile, using the exact same fitted scaler/encoder as training."""
    return _transform(user_data)


def pairwise_compatibility(user_data_a: dict, user_data_b: dict) -> dict:
    """
    Direct A-vs-B compatibility, useful for tests/spot checks and for
    verifying determinism/symmetry:

        pairwise_compatibility(A, B) == pairwise_compatibility(B, A)
        (same distance, same compatibility_score; cluster fields are
        each vector's own predicted cluster, so those are NOT symmetric
        — that's expected, they describe each person individually)

    Returns {"distance", "compatibility_score", "cluster_a", "cluster_b"}.
    """
    vec_a = _transform(user_data_a)
    vec_b = _transform(user_data_b)
    distance = float(np.linalg.norm(vec_a - vec_b))
    return {
        "distance": distance,
        "compatibility_score": compatibility_from_distance(distance),
        "cluster_a": int(_MODEL.predict(vec_a)[0]),
        "cluster_b": int(_MODEL.predict(vec_b)[0]),
    }


def find_matches_among(
    target_user_data: dict,
    candidates: list,
    top_n: int = 10,
) -> list:
    """
    Live recommendation path — operates over a caller-supplied list of
    REAL Tribal users (built from live RoommateProfile rows), NOT the
    static synthetic training pool in tribal_cluster_data.pkl.

    candidates: list of (user_id, user_data_dict) tuples.

        Ranking (cluster-aware, three-stage — see module docstring):
        1. Preprocess the target user's profile (same pipeline as training).
        2. Preprocess every candidate the same way.
        3. Predict the target's K-Means cluster and every candidate's
           K-Means cluster (trained model, loaded once at import time).
        4. Compute Euclidean distance from target to each candidate —
           across ALL candidates, not restricted to any single cluster.
        5. Convert distance -> bounded compatibility_score via
           compatibility_from_distance() (unchanged, pure-distance,
           deterministic — used as-is for display).
        6. Compute recommendation_score = compatibility_score, plus
           CLUSTER_SAME_BONUS when candidate_cluster == target_cluster,
           clipped to [0, 100]. This is the sort key.
        7. Sort descending by recommendation_score (ties broken by
           compatibility_score), return top N.

    Different-cluster candidates are NEVER filtered out — they remain
    fully eligible and are simply not boosted, so they still surface as
    fallback rather than the system returning zero recommendations.

    Returns: [{"user_id", "compatibility_score", "recommendation_score",
               "distance", "cluster", "target_cluster"}, ...]
    """
    target_vector = _transform(target_user_data)
    target_cluster = int(_MODEL.predict(target_vector)[0])

    if not candidates:
        return []

    candidate_ids = []
    candidate_vectors = []
    for user_id, user_data in candidates:
        try:
            vec = _transform(user_data)
        except TribalRecommenderError:
            # Skip candidates with malformed/incomplete profile data
            # rather than failing the whole recommendation request.
            continue
        candidate_ids.append(user_id)
        candidate_vectors.append(vec[0])

    if not candidate_ids:
        return []

        candidate_matrix = np.vstack(candidate_vectors)
    candidate_clusters = _MODEL.predict(candidate_matrix)

    distances = np.linalg.norm(candidate_matrix - target_vector, axis=1)

    results = []
    for uid, dist, cand_cluster in zip(candidate_ids, distances, candidate_clusters):
        compatibility_score = compatibility_from_distance(float(dist))
        cand_cluster = int(cand_cluster)
        same_cluster = cand_cluster == target_cluster
        recommendation_score = float(np.clip(
            compatibility_score + (CLUSTER_SAME_BONUS if same_cluster else 0.0),
            0.0, 100.0,
        ))
        results.append({
            "user_id": int(uid),
            "compatibility_score": compatibility_score,
            "recommendation_score": recommendation_score,
            "distance": float(dist),
            "cluster": cand_cluster,
            "target_cluster": target_cluster,
        })

    # Cluster-aware ranking: same-cluster candidates are prioritized via
    # recommendation_score; compatibility_score is the tie-breaker so
    # ordering within a cluster (and among fallback candidates) still
    # reflects real profile similarity.
    results.sort(key=lambda r: (r["recommendation_score"], r["compatibility_score"]), reverse=True)
    return results[:top_n]
