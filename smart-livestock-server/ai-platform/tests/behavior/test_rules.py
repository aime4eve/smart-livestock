import pytest
from fastapi.testclient import TestClient

from app.behavior.contract import FEATURE_FIELDS, FEATURE_SCHEMA_HASH_V1, FEATURE_VERSION_V1
from app.behavior.rules import predict_l1
from app.main import app


def full_features(**overrides):
    values = {name: 0 for name in FEATURE_FIELDS}
    values.update({
        "sample_count": 7500,
        "expected_sample_count": 7500,
        "missing_feature_mask": 0,
        "roll_mean": 0,
        "step_count": 0,
        "mean_speed_mps": 0,
        "activity_class_counts.rest": 7500,
        "posture_transition_count": 0,
    })
    values.update(overrides)
    return values


def test_l1_classifies_lying_without_oral_activity():
    result = predict_l1(
        "w-1", FEATURE_VERSION_V1, FEATURE_SCHEMA_HASH_V1,
        "FULL_0X40", "PROTOCOL_SUMMARY", full_features(roll_mean=65),
    )
    assert result.dominant_behavior == "LYING"
    assert result.labels == {"POSTURE": "LYING", "LOCOMOTION": "STATIONARY"}
    assert "ORAL_ACTIVITY" not in result.labels
    assert set(result.probability_vector) == {"LYING", "WALKING", "OTHER"}


def test_l1_classifies_walking_and_high_activity():
    walking = predict_l1(
        "w-2", FEATURE_VERSION_V1, FEATURE_SCHEMA_HASH_V1,
        "FULL_0X40", "PROTOCOL_SUMMARY", full_features(mean_speed_mps=0.8, step_count=500),
    )
    assert walking.dominant_behavior == "WALKING"
    assert walking.labels["LOCOMOTION"] == "WALKING"

    intense_features = full_features(posture_transition_count=3)
    intense_features["activity_class_counts.intense"] = 2000
    intense_features["activity_class_counts.rest"] = 5500
    intense = predict_l1(
        "w-3", FEATURE_VERSION_V1, FEATURE_SCHEMA_HASH_V1,
        "FULL_0X40", "PROTOCOL_SUMMARY", intense_features,
    )
    assert intense.labels == {"POSTURE": "TRANSITION", "LOCOMOTION": "HIGH_ACTIVITY"}


def test_l1_rejects_schema_and_missing_fields():
    with pytest.raises(ValueError):
        predict_l1(
            "w-4", "v2", FEATURE_SCHEMA_HASH_V1,
            "FULL_0X40", "PROTOCOL_SUMMARY", full_features(),
        )
    features = full_features()
    del features["roll_mean"]
    with pytest.raises(ValueError):
        predict_l1(
            "w-5", FEATURE_VERSION_V1, FEATURE_SCHEMA_HASH_V1,
            "FULL_0X40", "PROTOCOL_SUMMARY", features,
        )


def test_behavior_endpoint_returns_per_window_errors(client):
    response = client.post("/ai/behavior/analyze", json={
        "tenant_id": 1,
        "farm_id": 1,
        "windows": [{
            "window_id": "bad",
            "feature_version": "v1",
            "feature_schema_hash": "bad",
            "input_quality": "FULL_0X40",
            "sampling_mode": "PROTOCOL_SUMMARY",
            "features": full_features(),
        }],
    })
    assert response.status_code == 200
    body = response.json()
    assert body["results"] == []
    assert body["errors"][0]["window_id"] == "bad"


def test_behavior_endpoint_rejects_l2_before_implementation(client):
    response = client.post("/ai/behavior/analyze", json={
        "tenant_id": 1,
        "farm_id": 1,
        "requested_capability": "L2_SUPERVISED",
        "model_name": "missing",
        "model_version": "v1",
        "windows": [{
            "window_id": "w",
            "feature_version": FEATURE_VERSION_V1,
            "feature_schema_hash": FEATURE_SCHEMA_HASH_V1,
            "input_quality": "FULL_0X40",
            "sampling_mode": "PROTOCOL_SUMMARY",
            "features": full_features(),
        }],
    })
    assert response.status_code == 200
    assert response.json()["errors"][0]["message"] == "behavior model artifact not found"
