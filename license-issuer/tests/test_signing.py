"""Key loading (fail fast), envelope signing, and signature verification."""
from __future__ import annotations

import base64
import json

import pytest
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.serialization import (
    Encoding,
    NoEncryption,
    PrivateFormat,
)

from app.signing import (
    ENVELOPE_FORMAT,
    SigningError,
    build_payload,
    load_signing_key,
    normalize_fingerprint_hash,
    payload_sha256_hex,
    self_test,
    sign_envelope,
)

from tests.conftest import TEST_KEY_DIR, TEST_KEY_ID


def test_loads_test_key_and_matches_registered_public_key():
    key = load_signing_key(TEST_KEY_DIR, TEST_KEY_ID, strict_permissions=False)
    # The registry JSON in the same directory pins the raw public key.
    registry = json.loads((TEST_KEY_DIR / "license-public-keys.json").read_text())
    registered = {k["keyId"]: k["publicKey"] for k in registry["keys"]}
    assert registered[TEST_KEY_ID] == key.public_key_b64
    assert len(key.public_key_fingerprint) == 64


def test_self_test_passes_on_real_key():
    key = load_signing_key(TEST_KEY_DIR, TEST_KEY_ID, strict_permissions=False)
    self_test(key)


def test_missing_directory_fail_fast(tmp_path):
    with pytest.raises(SigningError, match="does not exist"):
        load_signing_key(tmp_path / "nope", TEST_KEY_ID)


def test_missing_key_file_fail_fast(tmp_path):
    (tmp_path / "empty").mkdir()
    with pytest.raises(SigningError, match="not found"):
        load_signing_key(tmp_path / "empty", TEST_KEY_ID)


def test_directory_permission_too_wide_fail_fast(tmp_path):
    keydir = tmp_path / "keys"
    keydir.mkdir()
    keydir.chmod(0o755)
    pem = keydir / f"{TEST_KEY_ID}.pem"
    pem.write_bytes((TEST_KEY_DIR / f"{TEST_KEY_ID}.pem").read_bytes())
    pem.chmod(0o600)
    with pytest.raises(SigningError, match="0700"):
        load_signing_key(keydir, TEST_KEY_ID, strict_permissions=True)
    # Lenient mode (tests / misconfigured mounts) still refuses nothing else.
    load_signing_key(keydir, TEST_KEY_ID, strict_permissions=False)


def test_file_permission_too_wide_fail_fast(tmp_path):
    keydir = tmp_path / "keys2"
    keydir.mkdir()
    keydir.chmod(0o700)
    pem = keydir / f"{TEST_KEY_ID}.pem"
    pem.write_bytes((TEST_KEY_DIR / f"{TEST_KEY_ID}.pem").read_bytes())
    pem.chmod(0o644)
    with pytest.raises(SigningError, match="0600"):
        load_signing_key(keydir, TEST_KEY_ID, strict_permissions=True)


def test_non_ed25519_algorithm_rejected(tmp_path):
    from cryptography.hazmat.primitives.asymmetric import rsa

    keydir = tmp_path / "rsa-keys"
    keydir.mkdir()
    keydir.chmod(0o700)
    rsa_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = keydir / f"{TEST_KEY_ID}.pem"
    pem.write_bytes(
        rsa_key.private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption())
    )
    pem.chmod(0o600)
    with pytest.raises(SigningError, match="only Ed25519 is supported"):
        load_signing_key(keydir, TEST_KEY_ID, strict_permissions=True)


def _payload(key_id: str = TEST_KEY_ID) -> dict:
    return build_payload(
        license_id="7f6c1a2e-3b4d-4e5f-8a9b-0c1d2e3f4a5b",
        tenant_id=42,
        installation_id="9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40",
        fingerprint_hash="A" * 64,  # upper case input is normalized
        key_id=key_id,
        license_type="ACTIVE",
        tier="PREMIUM",
        effective_tier="PREMIUM",
        issued_at="2026-09-01T00:00:00Z",
        expires_at="2027-09-01T00:00:00Z",
        quotas={"livestock_management": 1000, "device_management": 1000},
        features={},
    )


def test_envelope_structure_and_digest():
    key = load_signing_key(TEST_KEY_DIR, TEST_KEY_ID, strict_permissions=False)
    payload = _payload()
    envelope = sign_envelope(payload, key)

    assert json.loads(envelope.envelope_json) == {
        "format": ENVELOPE_FORMAT,
        "keyId": TEST_KEY_ID,
        "payload": envelope.payload_b64url,
        "payloadSha256": envelope.payload_sha256,
        "signature": envelope.signature_b64url,
    }
    assert len(envelope.payload_sha256) == 64
    assert envelope.payload_sha256 == payload_sha256_hex(envelope.payload_bytes)
    # single compact line
    assert "\n" not in envelope.envelope_json


def test_signature_verifies_with_derived_public_key():
    key = load_signing_key(TEST_KEY_DIR, TEST_KEY_ID, strict_permissions=False)
    envelope = sign_envelope(_payload(), key)
    assert envelope.verify_with(key.public_key) is True


def test_tampered_payload_fails_verification():
    key = load_signing_key(TEST_KEY_DIR, TEST_KEY_ID, strict_permissions=False)
    envelope = sign_envelope(_payload(), key)
    tampered = envelope.payload_bytes.replace(b'"tenantId":42', b'"tenantId":43')
    assert tampered != envelope.payload_bytes
    try:
        key.public_key.verify(
            base64.urlsafe_b64decode(envelope.signature_b64url + "=" * (-len(envelope.signature_b64url) % 4)),
            tampered,
        )
        raised = False
    except Exception:
        raised = True
    assert raised, "tampered payload must not verify"


def test_fingerprint_normalization():
    assert normalize_fingerprint_hash("A" * 64) == "a" * 64
    with pytest.raises(SigningError):
        normalize_fingerprint_hash("zz")
    with pytest.raises(SigningError):
        normalize_fingerprint_hash("a" * 63)


def test_payload_omits_replaces_license_id_when_absent():
    payload = _payload()
    assert "replacesLicenseId" not in payload
    payload2 = build_payload(
        **{
            "license_id": "7f6c1a2e-3b4d-4e5f-8a9b-0c1d2e3f4a5b",
            "tenant_id": 42,
            "installation_id": "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40",
            "fingerprint_hash": "a" * 64,
            "key_id": TEST_KEY_ID,
            "license_type": "TRIAL",
            "tier": "BASIC",
            "effective_tier": "BASIC",
            "issued_at": "2026-09-01T00:00:00Z",
            "expires_at": "2027-09-01T00:00:00Z",
            "quotas": {},
            "features": {},
            "replaces_license_id": "3f2b8a5e-0c1d-4e2f-9a8b-7c6d5e4f3a2b",
        }
    )
    assert payload2["replacesLicenseId"] == "3f2b8a5e-0c1d-4e2f-9a8b-7c6d5e4f3a2b"


def test_ed25519_private_key_type():
    key = load_signing_key(TEST_KEY_DIR, TEST_KEY_ID, strict_permissions=False)
    assert isinstance(key.private_key, Ed25519PrivateKey)
