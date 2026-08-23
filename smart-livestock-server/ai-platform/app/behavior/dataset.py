"""Read a governed synthetic behavior dataset from PostgreSQL."""
from __future__ import annotations

import json
import uuid

from app.behavior.contract import FEATURE_SCHEMA_HASH_V1, FEATURE_VERSION_V1
from app.behavior.model import TrainingWindow


def fetch_training_dataset(conn, dataset_id: str):
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id::text, data_source, definition_digest, generator_version
            FROM behavior_datasets WHERE id = %s
        """, (dataset_id,))
        dataset = cur.fetchone()
        if dataset is None:
            raise ValueError("behavior dataset not found")
        if dataset[1] != "DATAGEN":
            raise ValueError("behavior pretraining requires a DATAGEN dataset")

        cur.execute("""
            SELECT w.id::text, a.dataset_split, w.dominant_behavior,
                   w.feature_version, w.feature_schema_hash, w.input_quality,
                   w.sampling_mode, w.model_compatible, w.features
            FROM behavior_windows w
            JOIN behavior_episode_split_assignments a
              ON a.dataset_id = w.dataset_id AND a.episode_id = w.episode_id
            WHERE w.dataset_id = %s
            ORDER BY w.window_start, w.id
        """, (dataset_id,))
        window_rows = cur.fetchall()

        window_ids = [row[0] for row in window_rows]
        labels = {window_id: {} for window_id in window_ids}
        if window_ids:
            cur.execute("""
                SELECT window_id::text, facet, label_value
                FROM behavior_window_labels
                WHERE window_id = ANY(%s::uuid[])
            """, (window_ids,))
            for window_id, facet, value in cur.fetchall():
                labels[window_id][facet] = value

    windows = []
    for row in window_rows:
        if row[3] != FEATURE_VERSION_V1 or row[4] != FEATURE_SCHEMA_HASH_V1:
            raise ValueError("dataset feature contract mismatch")
        if not row[7]:
            continue
        windows.append(TrainingWindow(
            window_id=row[0],
            split=row[1],
            dominant=row[2],
            features=row[8] if isinstance(row[8], dict) else json.loads(row[8]),
            labels=labels[row[0]],
        ))
    return {
        "dataset_id": dataset[0],
        "definition_digest": dataset[2],
        "generator_version": dataset[3],
        "windows": windows,
    }
