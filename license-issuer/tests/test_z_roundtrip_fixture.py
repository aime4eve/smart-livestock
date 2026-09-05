"""Deterministic issuer roundtrip vectors for the Java test
``IssuerRoundtripVectorTest``.

Runs last (file name sorts after the other test modules). Writes:
- ``test-vectors/issuer-roundtrip/issuer-roundtrip.sllicense`` (signed with the
  repository test key ``sl-license-test``)
- ``test-vectors/issuer-roundtrip/expected-payload.json`` (binding assertions)

Fixed ids and timestamps keep the generated files byte-stable across runs, so
re-running pytest does not produce git noise (Ed25519 is deterministic).
"""
from __future__ import annotations

import json
from pathlib import Path

from app.canonical import canonical_bytes
from app.signing import (
    build_payload,
    load_signing_key,
    payload_sha256_hex,
    sign_envelope,
    self_test,
)

from tests.conftest import ROUNDTRIP_DIR, TEST_KEY_DIR, TEST_KEY_ID

FIXTURE_LICENSE_ID = "7f6c1a2e-3b4d-4e5f-8a9b-0c1d2e3f4a5b"
FIXTURE_TENANT_ID = 42
FIXTURE_INSTALLATION_ID = "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40"
FIXTURE_FINGERPRINT = "a" * 64
FIXTURE_ISSUED_AT = "2026-09-01T00:00:00Z"
FIXTURE_EXPIRES_AT = "2027-09-01T00:00:00Z"


def _build_payload() -> dict:
    return build_payload(
        license_id=FIXTURE_LICENSE_ID,
        tenant_id=FIXTURE_TENANT_ID,
        installation_id=FIXTURE_INSTALLATION_ID,
        fingerprint_hash=FIXTURE_FINGERPRINT,
        key_id=TEST_KEY_ID,
        license_type="ACTIVE",
        tier="PREMIUM",
        effective_tier="PREMIUM",
        issued_at=FIXTURE_ISSUED_AT,
        expires_at=FIXTURE_EXPIRES_AT,
        quotas={
            "livestock_management": 1000,
            "fence_management": 100,
            "worker_management": 50,
            "device_management": 1000,
        },
        features={},
    )


def test_generate_issuer_roundtrip_fixture():
    key = load_signing_key(TEST_KEY_DIR, TEST_KEY_ID, strict_permissions=False)
    self_test(key)

    payload = _build_payload()
    envelope = sign_envelope(payload, key)

    ROUNDTRIP_DIR.mkdir(parents=True, exist_ok=True)
    sllicense_path = ROUNDTRIP_DIR / "issuer-roundtrip.sllicense"
    sllicense_path.write_text(envelope.envelope_json + "\n", encoding="utf-8")

    expected = {
        "envelopeFile": "issuer-roundtrip.sllicense",
        "keyId": TEST_KEY_ID,
        "payloadSha256": envelope.payload_sha256,
        "payload": payload,
    }
    expected_path = ROUNDTRIP_DIR / "expected-payload.json"
    expected_path.write_text(
        json.dumps(expected, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    # sanity: the fixture verifies against the test public key
    assert envelope.verify_with(key.public_key) is True
    assert payload_sha256_hex(canonical_bytes(payload)) == envelope.payload_sha256
    assert sllicense_path.is_file() and expected_path.is_file()


def test_fixture_is_stable_across_regenerations():
    key = load_signing_key(TEST_KEY_DIR, TEST_KEY_ID, strict_permissions=False)
    envelope = sign_envelope(_build_payload(), key)
    current = (ROUNDTRIP_DIR / "issuer-roundtrip.sllicense").read_text(encoding="utf-8")
    assert current.strip() == envelope.envelope_json, (
        "regenerated envelope diverged; Ed25519 and fixture inputs must stay deterministic"
    )


def test_expected_payload_json_round_trips():
    expected_path = ROUNDTRIP_DIR / "expected-payload.json"
    parsed = json.loads(expected_path.read_text(encoding="utf-8"))
    rebuilt = canonical_bytes(parsed["payload"])
    import hashlib

    assert hashlib.sha256(rebuilt).hexdigest() == parsed["payloadSha256"]
    assert parsed["payload"]["tenantId"] == FIXTURE_TENANT_ID
    assert parsed["payload"]["installationId"] == FIXTURE_INSTALLATION_ID
    assert parsed["payload"]["fingerprintHash"] == FIXTURE_FINGERPRINT
    assert parsed["payload"]["expiresAt"] == FIXTURE_EXPIRES_AT
