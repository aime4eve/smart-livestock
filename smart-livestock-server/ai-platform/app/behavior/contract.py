"""C0 behavior feature contract shared by rules and supervised models."""
from dataclasses import dataclass


FEATURE_VERSION_V1 = "v1"
FEATURE_SCHEMA_HASH_V1 = (
    "ed681cb289c0d9c7eb90d7e7a69e52663618af2f3004b71b4aa17db4ba95bfbc"
)

FEATURE_FIELDS = (
    "sample_count",
    "expected_sample_count",
    "missing_feature_mask",
    "accel_mean_x",
    "accel_mean_y",
    "accel_mean_z",
    "accel_std_x",
    "accel_std_y",
    "accel_std_z",
    "roll_mean",
    "roll_std",
    "pitch_mean",
    "pitch_std",
    "dominant_freq_hz",
    "spectral_power_ratio",
    "spectral_entropy",
    "burst_count",
    "zero_crossing_rate",
    "step_count",
    "distance_meters",
    "mean_speed_mps",
    "activity_class_counts.rest",
    "activity_class_counts.light",
    "activity_class_counts.active",
    "activity_class_counts.intense",
    "capsule_motility_mean",
    "capsule_motility_std",
    "posture_transition_count",
)


@dataclass(frozen=True)
class FeatureContract:
    version: str
    schema_hash: str


V1 = FeatureContract(FEATURE_VERSION_V1, FEATURE_SCHEMA_HASH_V1)


class FeatureContractError(ValueError):
    """Raised when a window does not satisfy the semantic C0 contract."""


def validate_contract(version: str, schema_hash: str, features: dict) -> None:
    if version != V1.version or schema_hash != V1.schema_hash:
        raise FeatureContractError("incompatible behavior feature contract")
    if not isinstance(features, dict):
        raise FeatureContractError("features must be an object")

    for name in FEATURE_FIELDS:
        if name not in features:
            raise FeatureContractError(f"missing feature: {name}")

    mask = _integer(features["missing_feature_mask"], "missing_feature_mask")
    for index, name in enumerate(FEATURE_FIELDS[3:]):
        marked_missing = bool(mask & (1 << index))
        value = features.get(name)
        if value is None:
            if not marked_missing:
                raise FeatureContractError(f"missing feature: {name}")
        elif marked_missing:
            raise FeatureContractError(f"present feature marked missing: {name}")

    sample_count = _integer(features["sample_count"], "sample_count")
    expected = _integer(features["expected_sample_count"], "expected_sample_count")
    if sample_count < 0 or expected < 0 or sample_count > expected:
        raise FeatureContractError("invalid sample coverage")


def numeric_vector(features: dict) -> list[float]:
    """Return the fixed semantic feature vector; unavailable fields become NaN."""
    import math

    vector: list[float] = []
    for name in FEATURE_FIELDS:
        value = features.get(name)
        vector.append(float(value) if value is not None else math.nan)
    return vector


def _integer(value, name: str) -> int:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise FeatureContractError(f"feature is not numeric: {name}")
    if isinstance(value, float) and not value.is_integer():
        raise FeatureContractError(f"feature is not integer: {name}")
    return int(value)
