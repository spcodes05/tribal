"""
train_kmeans_domain_weighted.py

Trains the FINAL Tribal roommate K-Means model on a domain-weighted,
block-normalized 47-dimensional feature space. Supersedes
retrain_kmeans_k4.py (K=4, flat/unweighted feature space) — that script
and its artifacts are stale and should not be used; see
DEPRECATED_retrain_kmeans_k4.md.

════════════════════════════════════════════════════════════════════════
WHAT CHANGED FROM THE OLD (K=4, unweighted) PIPELINE
════════════════════════════════════════════════════════════════════════
1. K is fixed at 3 (not 4). Per explicit requirement.

2. Every feature belongs to exactly one of 11 domains. Each domain's
   engineered feature BLOCK is:
     a. built exactly as before (StandardScaler for continuous fields,
        OneHotEncoder per categorical domain, multi-hot for interests)
     b. RMS-normalized: the whole block is divided by
        sqrt(mean(block ** 2)) (a single scalar per domain, computed over
        ALL elements of the block, not per-column) so that a domain with
        many one-hot columns does not automatically out-weigh a domain
        with one or two continuous columns purely by dimension count.
     c. multiplied by that domain's fixed importance weight (below).
   The weighted blocks are concatenated in a fixed, deterministic order
   to form the final (n, 47) matrix. This is the ONLY feature space the
   model is trained or queried against.

3. `gender_preference` and `room_type_preference` remain EXCLUDED from
   the ML feature set (unchanged from before) — they are hard eligibility
   filters in services.py, not similarity features. A user's own
   `gender` (not their preference) was already a plain feature before;
   it is now a heavily-weighted one — see DOMAIN_WEIGHTS below and the
   module docstring in tribal_ml_recommender.py for what that implies for
   the compatibility score.

4. The preprocessor artifact now stores everything inference needs to
   exactly reproduce this transformation deterministically: per-domain
   fitted scaler/encoder, per-domain RMS normalization constant (fit on
   training data, NOT recomputed at inference), per-domain weight,
   domain concatenation order / column slices, and `max_distance`
   computed in this FINAL weighted 47-D space (not the old raw space).

5. A `feature_space_version` string is stamped onto the model object
   itself (as a plain attribute — pickled along with it) and duplicated
   in the preprocessor and cluster-data artifacts, so a stale artifact
   combination fails loudly at load time instead of silently producing
   nonsense vectors/predictions.
════════════════════════════════════════════════════════════════════════
"""

import pickle

import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import calinski_harabasz_score, davies_bouldin_score, silhouette_score
from sklearn.preprocessing import OneHotEncoder, StandardScaler

RANDOM_STATE = 42
N_CLUSTERS = 3  # FIXED per explicit requirement — not auto-selected
DATA_PATH = "dataset.csv"

FEATURE_SPACE_VERSION = "domain_weighted_v1"

# ─────────────────────────────────────────────────────────────────────────
# Feature groups (verified against dataset.csv: 47 total raw features)
# ─────────────────────────────────────────────────────────────────────────

NUMERIC_FEATURES = [
    "cleanliness", "noise_level", "wake_time_minutes", "wake_time_sin", "wake_time_cos",
]
BUDGET_FEATURES = ["budget_min", "budget_max"]

# domain -> source dataframe column(s) fed into a OneHotEncoder for that
# domain. Each domain gets its OWN encoder/block (not one shared
# multi-column encoder) so its RMS normalization and weight apply only to
# itself.
CATEGORICAL_DOMAIN_COLUMNS = {
    "gender": ["gender"],
    "sleep_schedule": ["sleep_schedule"],
    "smoking": ["smoking"],
    "drinking": ["drinking"],
    "guests": ["guests_preference"],
    "food": ["food_preference"],
    "pets": ["pets"],
    "study": ["study_habit"],
}

INTEREST_VOCAB = [
    "Board Games", "Book Club", "Cooking", "Futsal", "Gaming", "Hiking",
    "Language", "Music", "Photography", "Travel", "Treks", "Yoga",
]

# gender_preference / room_type_preference intentionally excluded — hard
# filters in services.py, not ML features. Kept as identifiers/exclusions
# only, same as user_id/age/occupation/location.
EXCLUDED_COLUMNS = [
    "user_id", "age", "occupation", "location",
    "gender_preference", "room_type_preference",
]

# Fixed domain importance weights. Intentional — see project decision;
# do not change without a concrete implementation-bug justification.
DOMAIN_WEIGHTS = {
    "gender": 5.0,
    "budget": 4.5,
    "sleep_schedule": 3.0,
    "numeric": 1.5,
    "smoking": 1.5,
    "food": 1.25,
    "study": 1.25,
    "guests": 1.0,
    "interests": 1.0,
    "drinking": 0.75,
    "pets": 0.5,
}

# Deterministic concatenation order for the final (n, 47) matrix. This
# exact list (order matters) is also stored in the preprocessor artifact
# so inference never has to guess it.
DOMAIN_ORDER = [
    "budget", "numeric", "gender", "sleep_schedule", "smoking",
    "drinking", "guests", "food", "pets", "study", "interests",
]

EXPECTED_DOMAIN_DIMS = {
    "budget": 2, "numeric": 5, "gender": 4, "sleep_schedule": 3,
    "smoking": 3, "drinking": 3, "guests": 3, "food": 4, "pets": 4,
    "study": 4, "interests": 12,
}
EXPECTED_TOTAL_FEATURES = 47


def engineer_wake_time(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    parsed = pd.to_datetime(df["wake_time"], format="%H:%M")
    minutes = parsed.dt.hour * 60 + parsed.dt.minute
    df["wake_time_minutes"] = minutes
    df["wake_time_sin"] = np.sin(2 * np.pi * minutes / 1440)
    df["wake_time_cos"] = np.cos(2 * np.pi * minutes / 1440)
    return df


def build_interest_multihot(df: pd.DataFrame, vocab: list) -> pd.DataFrame:
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


def rms_normalize_fit(block: np.ndarray) -> tuple:
    """Whole-block RMS normalization (fit time): divide every element by
    a single scalar so the block's overall RMS (over ALL elements, not
    per-column) is 1. Returns (normalized_block, rms_scalar) — the scalar
    must be persisted and reused unchanged at inference."""
    rms = float(np.sqrt(np.mean(block ** 2)))
    if rms == 0.0:
        # Degenerate block (all zeros) — nothing to normalize by; leave
        # as-is and record rms=1.0 so inference divides by 1, not 0.
        return block, 1.0
    return block / rms, rms


def build_domain_blocks(df: pd.DataFrame, preprocessor: dict, fit: bool) -> dict:
    """Builds each domain's RAW (post-encode, pre-weight, but
    RMS-normalized) block. Returns {domain: (n, d) ndarray}."""
    blocks = {}

    # -- budget --
    if fit:
        scaler_budget = StandardScaler()
        budget_scaled = scaler_budget.fit_transform(df[BUDGET_FEATURES])
        preprocessor["scaler_budget"] = scaler_budget
    else:
        budget_scaled = preprocessor["scaler_budget"].transform(df[BUDGET_FEATURES])

    if fit:
        blocks["budget"], rms = rms_normalize_fit(budget_scaled)
        preprocessor.setdefault("domain_rms", {})["budget"] = rms
    else:
        blocks["budget"] = budget_scaled / preprocessor["domain_rms"]["budget"]

    # -- numeric (non-budget) --
    if fit:
        scaler_num = StandardScaler()
        numeric_scaled = scaler_num.fit_transform(df[NUMERIC_FEATURES])
        preprocessor["scaler_numeric"] = scaler_num
    else:
        numeric_scaled = preprocessor["scaler_numeric"].transform(df[NUMERIC_FEATURES])

    if fit:
        blocks["numeric"], rms = rms_normalize_fit(numeric_scaled)
        preprocessor["domain_rms"]["numeric"] = rms
    else:
        blocks["numeric"] = numeric_scaled / preprocessor["domain_rms"]["numeric"]

    # -- one categorical domain per encoder --
    if fit:
        preprocessor.setdefault("encoders", {})
    for domain, cols in CATEGORICAL_DOMAIN_COLUMNS.items():
        if fit:
            enc = OneHotEncoder(handle_unknown="ignore", sparse_output=False)
            encoded = enc.fit_transform(df[cols])
            preprocessor["encoders"][domain] = enc
            blocks[domain], rms = rms_normalize_fit(encoded)
            preprocessor["domain_rms"][domain] = rms
        else:
            enc = preprocessor["encoders"][domain]
            encoded = enc.transform(df[cols])
            blocks[domain] = encoded / preprocessor["domain_rms"][domain]

    # -- interests --
    interest_df = build_interest_multihot(df, INTEREST_VOCAB)
    interest_matrix = interest_df.values.astype(float)
    if fit:
        blocks["interests"], rms = rms_normalize_fit(interest_matrix)
        preprocessor["domain_rms"]["interests"] = rms
    else:
        blocks["interests"] = interest_matrix / preprocessor["domain_rms"]["interests"]

    return blocks


def assemble_final_matrix(blocks: dict, preprocessor: dict, fit: bool) -> np.ndarray:
    """Applies domain weights and concatenates in DOMAIN_ORDER, recording
    (once, at fit time) the column slice for every domain."""
    weighted = []
    col_cursor = 0
    domain_slices = {}
    feature_names = []
    for domain in DOMAIN_ORDER:
        w = DOMAIN_WEIGHTS[domain]
        wb = blocks[domain] * w
        weighted.append(wb)
        n_cols = wb.shape[1]
        domain_slices[domain] = (col_cursor, col_cursor + n_cols)
        if domain in CATEGORICAL_DOMAIN_COLUMNS:
            enc = preprocessor["encoders"][domain]
            names = list(enc.get_feature_names_out(CATEGORICAL_DOMAIN_COLUMNS[domain]))
        elif domain == "budget":
            names = list(BUDGET_FEATURES)
        elif domain == "numeric":
            names = list(NUMERIC_FEATURES)
        elif domain == "interests":
            names = [f"interest_{v.replace(' ', '_')}" for v in INTEREST_VOCAB]
        else:
            names = [f"{domain}_{i}" for i in range(n_cols)]
        feature_names.extend(names)
        col_cursor += n_cols

    X = np.hstack(weighted)

    if fit:
        preprocessor["domain_order"] = DOMAIN_ORDER
        preprocessor["domain_slices"] = domain_slices
        preprocessor["domain_weights"] = DOMAIN_WEIGHTS
        preprocessor["expected_domain_dims"] = EXPECTED_DOMAIN_DIMS
        preprocessor["feature_names"] = feature_names
        preprocessor["numeric_features"] = NUMERIC_FEATURES
        preprocessor["budget_features"] = BUDGET_FEATURES
        preprocessor["categorical_domain_columns"] = CATEGORICAL_DOMAIN_COLUMNS
        preprocessor["interest_vocab"] = INTEREST_VOCAB
        preprocessor["n_features_total"] = X.shape[1]
        preprocessor["feature_space_version"] = FEATURE_SPACE_VERSION

        # sanity: dims match spec exactly
        for d, expected in EXPECTED_DOMAIN_DIMS.items():
            lo, hi = domain_slices[d]
            actual = hi - lo
            assert actual == expected, (
                f"Domain '{d}' produced {actual} columns, expected {expected}. "
                f"Dataset category values may not match the assumed vocabulary."
            )
        assert X.shape[1] == EXPECTED_TOTAL_FEATURES, (
            f"Final feature matrix has {X.shape[1]} columns, expected "
            f"{EXPECTED_TOTAL_FEATURES}."
        )

    return X


def domain_between_cluster_contribution(X: np.ndarray, labels: np.ndarray, domain_slices: dict) -> dict:
    """% of total between-cluster sum-of-squares attributable to each
    domain's (already weighted) columns. Diagnostic only — matches the
    'domain separation audit' numbers."""
    global_mean = X.mean(axis=0)
    unique = np.unique(labels)
    per_domain_ss = {}
    total_ss = 0.0
    for domain, (lo, hi) in domain_slices.items():
        Xd = X[:, lo:hi]
        gmean_d = global_mean[lo:hi]
        ss = 0.0
        for k in unique:
            mask = labels == k
            ck = Xd[mask].mean(axis=0)
            ss += mask.sum() * np.sum((ck - gmean_d) ** 2)
        per_domain_ss[domain] = ss
        total_ss += ss
    return {d: (100.0 * ss / total_ss if total_ss else 0.0) for d, ss in per_domain_ss.items()}


def main():
    df = pd.read_csv(DATA_PATH)
    print(f"Loaded dataset: {df.shape[0]} rows, {df.shape[1]} columns")

    for col in EXCLUDED_COLUMNS:
        assert col in df.columns, f"expected column {col} missing from dataset"
    print(f"Excluded from ML features (hard filters / identifiers only): {EXCLUDED_COLUMNS}")

    user_ids = df["user_id"].values
    df = engineer_wake_time(df)

    preprocessor = {}
    blocks = build_domain_blocks(df, preprocessor, fit=True)
    X = assemble_final_matrix(blocks, preprocessor, fit=True)
    print(f"\nFinal feature matrix: {X.shape}")
    print("Domain raw (pre-weight) dims:", {d: blocks[d].shape[1] for d in DOMAIN_ORDER})
    print("Domain weights:", DOMAIN_WEIGHTS)

    # ── max_distance: bounding-box diagonal computed in the FINAL
    # weighted/normalized 47-D space (NOT the old raw space) ──
    feature_ranges = X.max(axis=0) - X.min(axis=0)
    max_distance = float(np.sqrt(np.sum(feature_ranges ** 2)))
    preprocessor["max_distance"] = max_distance
    print(f"\nComputed max_distance (final weighted space bounding-box diagonal): {max_distance:.4f}")

    # ── K FIXED at 3 ──
    final_model = KMeans(n_clusters=N_CLUSTERS, random_state=RANDOM_STATE, n_init=10)
    labels = final_model.fit_predict(X)

    # Stamp version/shape metadata directly onto the model object so a
    # stale model can never silently pair with a newer preprocessor (or
    # vice versa) — checked at load time in tribal_ml_recommender.py.
    final_model.feature_space_version = FEATURE_SPACE_VERSION
    final_model.n_features_expected = EXPECTED_TOTAL_FEATURES

    sil = silhouette_score(X, labels)
    ch = calinski_harabasz_score(X, labels)
    db = davies_bouldin_score(X, labels)
    print(f"\nSilhouette: {sil:.4f}")
    print(f"CH: {ch:.2f}")
    print(f"DB: {db:.4f}")
    print(f"Inertia: {final_model.inertia_:.2f}")

    unique, counts = np.unique(labels, return_counts=True)
    print("\nCluster sizes:")
    for u, c in zip(unique, counts):
        print(f"  cluster {u}: {c} users ({100 * c / len(labels):.2f}%)")

    print("\nDomain contribution to between-cluster separation:")
    contributions = domain_between_cluster_contribution(X, labels, preprocessor["domain_slices"])
    for d, pct in sorted(contributions.items(), key=lambda kv: -kv[1]):
        print(f"  {d:15s}: {pct:8.4f}%")

    # ── Sanity check: identical profile -> distance 0 -> compatibility 100% ──
    zero_distance = float(np.linalg.norm(X[0] - X[0]))
    compat_self = 100.0 * max(0.0, 1.0 - zero_distance / max_distance)
    print(f"\nSanity check — identical vector self-distance: {zero_distance} "
          f"-> compatibility: {compat_self:.2f}%")
    assert zero_distance == 0.0
    assert compat_self == 100.0

    cluster_data = {
        "user_ids": user_ids,
        "feature_matrix": X,
        "cluster_labels": labels,
        "k": N_CLUSTERS,
        "feature_space_version": FEATURE_SPACE_VERSION,
        "domain_contribution_pct": contributions,
        "metrics": {"silhouette": sil, "calinski_harabasz": ch, "davies_bouldin": db,
                    "inertia": float(final_model.inertia_)},
    }

    with open("tribal_kmeans_model.pkl", "wb") as f:
        pickle.dump(final_model, f)
    with open("tribal_preprocessor.pkl", "wb") as f:
        pickle.dump(preprocessor, f)
    with open("tribal_cluster_data.pkl", "wb") as f:
        pickle.dump(cluster_data, f)

    print("\nSaved: tribal_kmeans_model.pkl, tribal_preprocessor.pkl, tribal_cluster_data.pkl")
    print(f"feature_space_version = {FEATURE_SPACE_VERSION!r}")


if __name__ == "__main__":
    main()
