"""Deterministic supervised behavior model training and inference."""
from __future__ import annotations

import hashlib
import json
import math
from dataclasses import dataclass
from pathlib import Path

import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score

from app.behavior.contract import (
    FEATURE_FIELDS,
    FEATURE_SCHEMA_HASH_V1,
    FEATURE_VERSION_V1,
    validate_contract,
)
from app.config import settings


@dataclass(frozen=True)
class TrainingWindow:
    window_id: str
    split: str
    dominant: str
    features: dict
    labels: dict[str, str]


class BehaviorModelStore:
    def __init__(self, root: Path | None = None):
        self.root = root or Path(settings.behavior_model_dir)

    def train(self, windows: list[TrainingWindow], model_name: str, model_version: str,
              dataset_id: str, definition_digest: str, generator_version: str,
              minimum_support: int, random_seed: int) -> tuple[str, dict]:
        train = [row for row in windows if row.split == "TRAIN"]
        validation = [row for row in windows if row.split == "VALIDATION"]
        if not train or not validation:
            raise ValueError("both TRAIN and VALIDATION splits are required")
        for row in windows:
            validate_contract(FEATURE_VERSION_V1, FEATURE_SCHEMA_HASH_V1, row.features)

        dominant_classes = sorted({row.dominant for row in train})
        if len(dominant_classes) < 2 or min(
            sum(row.dominant == label for row in train) for label in dominant_classes
        ) < minimum_support:
            raise ValueError("insufficient dominant class support")

        x_train = np.array([_vector(row.features) for row in train], dtype=float)
        x_validation = np.array([_vector(row.features) for row in validation], dtype=float)
        y_train = np.array([dominant_classes.index(row.dominant) for row in train])
        dominant_model = _classifier(random_seed)
        dominant_model.fit(x_train, y_train)

        facet_models: dict[str, dict] = {}
        for facet in ("POSTURE", "ORAL_ACTIVITY", "LOCOMOTION", "EVENT"):
            values = sorted({row.labels[facet] for row in train if facet in row.labels})
            eligible = [row for row in train if facet in row.labels]
            if len(values) < 1 or min(
                sum(row.labels.get(facet) == value for row in eligible) for value in values
            ) < minimum_support:
                raise ValueError(f"insufficient {facet} label support")
            y_facet = np.array([values.index(row.labels[facet]) for row in eligible])
            model = None if len(values) == 1 else _classifier(random_seed)
            if model is not None:
                model.fit(x_train, y_facet)
            facet_models[facet] = {"classes": values, "model": model}

        artifact = {
            "feature_fields": list(FEATURE_FIELDS),
            "dominant_classes": dominant_classes,
            "dominant_model": dominant_model,
            "facets": facet_models,
        }
        model_dir = self.root / model_name / model_version
        model_dir.mkdir(parents=True, exist_ok=True)
        artifact_path = model_dir / "model.joblib"
        manifest_path = model_dir / "manifest.json"
        if artifact_path.exists() or manifest_path.exists():
            raise FileExistsError("model version already exists")

        joblib.dump(artifact, artifact_path, compress=3)
        artifact_hash = _sha256(artifact_path)
        validation_prediction = dominant_model.predict(x_validation)
        metrics = {
            "dominant_accuracy": float(accuracy_score(
                [dominant_classes.index(row.dominant) for row in validation],
                validation_prediction,
            )),
            "dominant_weighted_f1": float(f1_score(
                [dominant_classes.index(row.dominant) for row in validation],
                validation_prediction,
                average="weighted",
                labels=list(range(len(dominant_classes))),
                zero_division=0,
            )),
        }
        manifest = {
            "dataset_id": dataset_id,
            "dataset_definition_digest": definition_digest,
            "generator_version": generator_version,
            "feature_version": FEATURE_VERSION_V1,
            "feature_schema_hash": FEATURE_SCHEMA_HASH_V1,
            "model_name": model_name,
            "model_version": model_version,
            "random_seed": random_seed,
            "minimum_support": minimum_support,
            "train_window_count": len(train),
            "validation_window_count": len(validation),
            "dominant_classes": dominant_classes,
            "artifact_hash": artifact_hash,
            "validation_metrics": metrics,
            "report_type": "PIPELINE_ONLY",
            "synthetic_pretraining": True,
        }
        manifest_path.write_text(json.dumps(manifest, sort_keys=True, indent=2))
        return artifact_hash, manifest

    def load(self, model_name: str, model_version: str,
             feature_version: str, schema_hash: str) -> tuple[dict, dict]:
        model_dir = self.root / model_name / model_version
        artifact_path = model_dir / "model.joblib"
        manifest_path = model_dir / "manifest.json"
        if not artifact_path.exists() or not manifest_path.exists():
            raise FileNotFoundError("behavior model artifact not found")
        manifest = json.loads(manifest_path.read_text())
        if (manifest.get("feature_version") != feature_version
                or manifest.get("feature_schema_hash") != schema_hash
                or manifest.get("model_name") != model_name
                or manifest.get("model_version") != model_version):
            raise ValueError("behavior model contract mismatch")
        actual_hash = _sha256(artifact_path)
        if actual_hash != manifest.get("artifact_hash"):
            raise ValueError("behavior model artifact hash mismatch")
        artifact = joblib.load(artifact_path)
        if artifact.get("feature_fields") != list(FEATURE_FIELDS):
            raise ValueError("behavior model feature order mismatch")
        return artifact, manifest


def predict_l2(artifact: dict, window_id: str, feature_version: str,
               schema_hash: str, input_quality: str, sampling_mode: str,
               features: dict, model_name: str, model_version: str):
    validate_contract(feature_version, schema_hash, features)
    if input_quality == "UNKNOWN" or sampling_mode != "PROTOCOL_SUMMARY":
        raise ValueError("window is not model compatible")
    vector = np.array([_vector(features)], dtype=float)
    dominant_classes = artifact["dominant_classes"]
    probabilities = artifact["dominant_model"].predict_proba(vector)[0]
    index = int(np.argmax(probabilities))
    labels = {}
    for facet, item in artifact["facets"].items():
        facet_index = 0 if item["model"] is None else int(item["model"].predict(vector)[0])
        labels[facet] = item["classes"][facet_index]
    probability_vector = {
        label: float(probabilities[i]) if i < len(probabilities) else 0.0
        for i, label in enumerate(dominant_classes)
    }
    return {
        "window_id": window_id,
        "dominant_behavior": dominant_classes[index],
        "probability_vector": probability_vector,
        "predicted_labels": labels,
        "capability_level": "L2_SUPERVISED",
        "model_name": model_name,
        "model_version": model_version,
    }


def predict_l2_batch(artifact: dict, windows, model_name: str, model_version: str):
    """Predict a batch with one vectorized model call per output."""
    vectors = []
    prepared = []
    for window in windows:
        validate_contract(
            window.feature_version,
            window.feature_schema_hash,
            window.features,
        )
        if window.input_quality == "UNKNOWN" or window.sampling_mode != "PROTOCOL_SUMMARY":
            raise ValueError("window is not model compatible")
        vectors.append(_vector(window.features))
        prepared.append(window)

    matrix = np.array(vectors, dtype=float)
    dominant_classes = artifact["dominant_classes"]
    all_probabilities = artifact["dominant_model"].predict_proba(matrix)
    facet_predictions = {
        facet: [item["classes"][index] for index in item["model"].predict(matrix).tolist()]
        if item["model"] is not None
        else [item["classes"][0]] * len(prepared)
        for facet, item in artifact["facets"].items()
    }

    results = []
    for index, window in enumerate(prepared):
        probabilities = all_probabilities[index]
        predicted_index = int(np.argmax(probabilities))
        probability_vector = {
            label: float(probabilities[i]) if i < len(probabilities) else 0.0
            for i, label in enumerate(dominant_classes)
        }
        results.append({
            "window_id": window.window_id,
            "dominant_behavior": dominant_classes[predicted_index],
            "probability_vector": probability_vector,
            "predicted_labels": {
                facet: values[index]
                for facet, values in facet_predictions.items()
            },
            "capability_level": "L2_SUPERVISED",
            "model_name": model_name,
            "model_version": model_version,
        })
    return results


def _classifier(seed: int) -> RandomForestClassifier:
    return RandomForestClassifier(
        n_estimators=100,
        max_depth=8,
        min_samples_leaf=1,
        class_weight="balanced_subsample",
        random_state=seed,
        n_jobs=1,
    )


def _vector(features: dict) -> list[float]:
    return [float(features.get(name)) if features.get(name) is not None else math.nan
            for name in FEATURE_FIELDS]


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
