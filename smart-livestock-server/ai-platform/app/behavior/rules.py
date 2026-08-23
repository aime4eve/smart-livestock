"""Deterministic L1 coarse behavior rules."""
from dataclasses import dataclass

from app.behavior.contract import validate_contract


@dataclass(frozen=True)
class RulePrediction:
    window_id: str
    dominant_behavior: str
    probability_vector: dict[str, float]
    labels: dict[str, str]
    capability: str = "L1_RULE"
    model_name: str = "behavior-rules"
    model_version: str = "v1"


def predict_l1(window_id: str, feature_version: str, schema_hash: str,
               input_quality: str, sampling_mode: str, features: dict) -> RulePrediction:
    validate_contract(feature_version, schema_hash, features)

    speed = _value(features, "mean_speed_mps", default=0.0)
    steps = _value(features, "step_count", default=0)
    roll = _value(features, "roll_mean", default=0.0)
    transitions = _value(features, "posture_transition_count", default=0)
    intense = _value(features, "activity_class_counts.intense", default=0)
    sample_count = _value(features, "sample_count", default=0)

    if input_quality == "UNKNOWN" or sample_count == 0:
        dominant = "OTHER"
        posture = "STANDING"
        locomotion = "STATIONARY"
        probabilities = {"LYING": 0.1, "WALKING": 0.1, "OTHER": 0.8}
    elif speed >= 0.3 or steps >= 100:
        dominant = "WALKING"
        posture = "STANDING"
        locomotion = "WALKING"
        probabilities = {"LYING": 0.1, "WALKING": 0.8, "OTHER": 0.1}
    elif abs(roll) >= 40 and speed < 0.15:
        dominant = "LYING"
        posture = "LYING"
        locomotion = "STATIONARY"
        probabilities = {"LYING": 0.8, "WALKING": 0.05, "OTHER": 0.15}
    else:
        dominant = "OTHER"
        posture = "TRANSITION" if transitions >= 2 else "STANDING"
        locomotion = "HIGH_ACTIVITY" if intense > sample_count * 0.15 else "STATIONARY"
        probabilities = {"LYING": 0.15, "WALKING": 0.1, "OTHER": 0.75}

    if sampling_mode not in {"PROTOCOL_SUMMARY", "SPARSE_SNAPSHOT"}:
        raise ValueError("invalid behavior sampling mode")
    return RulePrediction(
        window_id=window_id,
        dominant_behavior=dominant,
        probability_vector=probabilities,
        labels={"POSTURE": posture, "LOCOMOTION": locomotion},
    )


def _value(features: dict, name: str, default):
    value = features.get(name)
    return default if value is None else value
