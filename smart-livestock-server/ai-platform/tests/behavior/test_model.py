import pytest

from app.behavior.contract import FEATURE_FIELDS, FEATURE_SCHEMA_HASH_V1, FEATURE_VERSION_V1
from app.behavior.model import BehaviorModelStore, TrainingWindow, predict_l2


def features(kind: str) -> dict:
    values = {name: 0 for name in FEATURE_FIELDS}
    values.update({
        "sample_count": 7500,
        "expected_sample_count": 7500,
        "missing_feature_mask": 0,
        "activity_class_counts.rest": 7000,
    })
    if kind == "LYING":
        values["roll_mean"] = 65
    elif kind == "WALKING":
        values["mean_speed_mps"] = 0.8
        values["step_count"] = 600
    else:
        values["dominant_freq_hz"] = 1.2
    return values


def window(index: int, kind: str, split: str):
    labels = {
        "POSTURE": "LYING" if kind == "LYING" else "STANDING",
        "ORAL_ACTIVITY": "RUMINATING" if kind == "RUMINATING" else "NONE",
        "LOCOMOTION": "WALKING" if kind == "WALKING" else "STATIONARY",
        "EVENT": "NONE",
    }
    return TrainingWindow(
        window_id=f"{split.lower()}-{index}",
        split=split,
        dominant=kind,
        features=features(kind),
        labels=labels,
    )


def test_train_load_and_predict_l2(tmp_path):
    windows = []
    kinds = ("LYING", "RUMINATING", "WALKING")
    for index, kind in enumerate(kinds * 4):
        windows.append(window(index, kind, "TRAIN" if index < 6 else "VALIDATION"))
    store = BehaviorModelStore(tmp_path)

    artifact_hash, manifest = store.train(
        windows, "behavior-l2", "v1", "dataset", "digest", "generator-v1", 1, 149,
    )
    artifact, loaded = store.load(
        "behavior-l2", "v1", FEATURE_VERSION_V1, FEATURE_SCHEMA_HASH_V1,
    )

    assert artifact_hash == manifest["artifact_hash"] == loaded["artifact_hash"]
    assert manifest["report_type"] == "PIPELINE_ONLY"
    assert manifest["synthetic_pretraining"] is True
    result = predict_l2(
        artifact,
        "new-window",
        FEATURE_VERSION_V1,
        FEATURE_SCHEMA_HASH_V1,
        "FULL_0X40",
        "PROTOCOL_SUMMARY",
        features("WALKING"),
        "behavior-l2",
        "v1",
    )
    assert result["dominant_behavior"] in {"LYING", "RUMINATING", "WALKING"}
    assert set(result["predicted_labels"]) == {
        "POSTURE", "ORAL_ACTIVITY", "LOCOMOTION", "EVENT"
    }


def test_train_requires_both_splits_and_support(tmp_path):
    store = BehaviorModelStore(tmp_path)
    with pytest.raises(ValueError):
        store.train(
            [window(0, "LYING", "TRAIN")],
            "behavior-l2", "v1", "dataset", "digest", "generator-v1", 1, 149,
        )


def test_load_rejects_missing_or_changed_contract(tmp_path):
    store = BehaviorModelStore(tmp_path)
    with pytest.raises(FileNotFoundError):
        store.load("missing", "v1", FEATURE_VERSION_V1, FEATURE_SCHEMA_HASH_V1)
