"""Canonical JSON vectors shared with the Java verifier (test-vectors/canonical-json-v1.json)."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.canonical import (
    CanonicalJsonError,
    apply_instant_keys,
    canonical_bytes,
    canonical_dumps,
    canonical_instant,
)

VECTORS_PATH = Path(__file__).resolve().parent.parent / "test-vectors" / "canonical-json-v1.json"


def load_vectors() -> dict:
    with open(VECTORS_PATH, "r", encoding="utf-8") as fh:
        return json.load(fh)


@pytest.mark.parametrize("case_index", range(3))
def test_shared_canonical_vectors(case_index):
    vectors = load_vectors()
    case = vectors["cases"][case_index]
    converted = apply_instant_keys(case["input"], case["instantKeys"])
    produced = canonical_bytes(converted)
    expected = case["expectedCanonical"].encode("utf-8")
    assert produced == expected, f"case '{case['name']}' diverged from Java expected bytes"


def test_vector_count_and_name():
    vectors = load_vectors()
    assert vectors["name"] == "canonical-json-v1"
    assert len(vectors["cases"]) == 3


def test_canonicalization_is_idempotent():
    vectors = load_vectors()
    for case in vectors["cases"]:
        parsed = json.loads(case["expectedCanonical"])
        assert canonical_dumps(parsed) == case["expectedCanonical"]


def test_integral_float_and_instant_normalization():
    # Java renders integral floats without a decimal point; instants are UTC Z.
    payload = {"quota": 5.0, "issuedAt": "2026-08-31T00:00:00Z"}
    converted = apply_instant_keys(payload, ["issuedAt"])
    assert canonical_dumps(converted) == '{"issuedAt":"2026-08-31T00:00:00Z","quota":5}'


def test_non_integral_float_rejected():
    with pytest.raises(CanonicalJsonError):
        canonical_dumps({"ratio": 0.5})


def test_null_handling_matches_java():
    # null map entries are omitted; nulls elsewhere are rejected.
    assert canonical_dumps({"a": 1, "b": None}) == '{"a":1}'
    with pytest.raises(CanonicalJsonError):
        canonical_dumps([None])
    with pytest.raises(CanonicalJsonError):
        canonical_dumps(None)


def test_offset_instants_normalized_to_utc():
    assert canonical_instant("2026-08-31T08:00:00+08:00") == "2026-08-31T00:00:00Z"
    assert canonical_instant("2026-08-31T00:00:00.750Z") == "2026-08-31T00:00:00Z"


def test_control_characters_escaped_like_java():
    assert canonical_dumps({"note": "a\nb\tc"}) == '{"note":"a\\nb\\tc"}'
