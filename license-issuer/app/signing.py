"""Ed25519 signing for .sllicense envelopes (design sections 3 and 4).

Fail fast rules: the private key file must exist, must be a PKCS#8 PEM Ed25519
key (no other algorithm is supported), directory/file permissions must be
0700/0600 when strict checks are on, and a sign+verify self-test runs at load
time so a broken trust root never reaches the first issuance.
"""
from __future__ import annotations

import base64
import hashlib
import json
import os
import stat
from dataclasses import dataclass
from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey,
)
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat

from app.canonical import canonical_bytes, canonical_instant

ENVELOPE_FORMAT = "SMART_LIVESTOCK_LICENSE_V1"
PAYLOAD_VERSION = 1
KEY_FILE_SUFFIX = ".pem"

LICENSE_TYPES = ("TRIAL", "ACTIVE")
TIERS = ("BASIC", "PREMIUM", "ENTERPRISE")
QUOTA_KEYS = (
    "livestock_management",
    "fence_management",
    "worker_management",
    "device_management",
)


class SigningError(RuntimeError):
    """Raised for any key loading, permission, algorithm, or signing failure."""


@dataclass(frozen=True)
class LoadedKey:
    """An active signing key plus the public material shown on the keys page."""

    key_id: str
    private_key: Ed25519PrivateKey
    public_key_b64: str  # raw 32-byte base64, matches license-public-keys.json
    public_key_fingerprint: str  # sha256 hex of the raw public key bytes
    pem_path: Path

    @property
    def public_key(self) -> Ed25519PublicKey:
        return self.private_key.public_key()


# ── Key loading ──────────────────────────────────────────────────────


def _check_permissions(directory: Path, pem_path: Path) -> None:
    dir_mode = stat.S_IMODE(os.stat(directory).st_mode)
    if dir_mode & 0o077:
        raise SigningError(
            f"private key directory {directory} must have permission 0700 "
            f"(got {oct(dir_mode)})"
        )
    file_mode = stat.S_IMODE(os.stat(pem_path).st_mode)
    if file_mode & 0o077:
        raise SigningError(
            f"private key file {pem_path} must have permission 0600 "
            f"(got {oct(file_mode)})"
        )


def load_signing_key(keys_dir: Path, key_id: str, strict_permissions: bool = True) -> LoadedKey:
    """Load the Ed25519 private key for ``key_id`` from ``keys_dir``.

    Layout: ``<keys_dir>/<keyId>.pem`` (PKCS#8 PEM). Raises :class:`SigningError`
    when anything is wrong so startup fails fast.
    """
    if not key_id or not key_id.strip():
        raise SigningError("ACTIVE_KEY_ID must not be empty")
    keys_dir = Path(keys_dir)
    if not keys_dir.is_dir():
        raise SigningError(f"private key directory does not exist: {keys_dir}")
    pem_path = keys_dir / f"{key_id}{KEY_FILE_SUFFIX}"
    if not pem_path.is_file():
        raise SigningError(
            f"active private key not found: {pem_path} "
            f"(expected <KEYS_DIR>/{key_id}{KEY_FILE_SUFFIX})"
        )
    if strict_permissions:
        _check_permissions(keys_dir, pem_path)

    try:
        pem_bytes = pem_path.read_bytes()
        loaded = serialization.load_pem_private_key(pem_bytes, password=None)
    except SigningError:
        raise
    except Exception as exc:
        raise SigningError(f"cannot parse private key {pem_path}: {exc}") from exc
    if not isinstance(loaded, Ed25519PrivateKey):
        raise SigningError(
            f"private key {pem_path} is {type(loaded).__name__}, "
            "only Ed25519 is supported"
        )

    raw_public = loaded.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw)
    return LoadedKey(
        key_id=key_id,
        private_key=loaded,
        public_key_b64=base64.b64encode(raw_public).decode("ascii"),
        public_key_fingerprint=hashlib.sha256(raw_public).hexdigest(),
        pem_path=pem_path,
    )


def self_test(key: LoadedKey) -> None:
    """Sign a fixed probe and verify it with the derived public key."""
    probe = b"license-issuer/selftest/v1"
    signature = key.private_key.sign(probe)
    try:
        key.public_key.verify(signature, probe)
    except Exception as exc:
        raise SigningError(
            "signing self-test failed: private key does not match its public key"
        ) from exc


# ── Payload and envelope ─────────────────────────────────────────────


def normalize_fingerprint_hash(value: str) -> str:
    """Normalize and validate a host fingerprint hash (lowercase 64-hex)."""
    normalized = (value or "").strip().lower()
    if len(normalized) != 64 or any(c not in "0123456789abcdef" for c in normalized):
        raise SigningError(
            "fingerprintHash must be a 64-character sha256 hex digest"
        )
    return normalized


def build_payload(
    *,
    license_id: str,
    tenant_id: int,
    installation_id: str,
    fingerprint_hash: str,
    key_id: str,
    license_type: str,
    tier: str,
    effective_tier: str,
    issued_at: str,
    expires_at: str,
    quotas: dict,
    features: dict | None = None,
    replaces_license_id: str | None = None,
) -> dict:
    """Build the fixed payload map (field set per design section 3).

    Instants are stored as canonical UTC strings so the canonical serialization
    is deterministic. ``replacesLicenseId`` is omitted when absent, matching the
    Java ``LicensePayload.toMap`` behavior.
    """
    payload = {
        "payloadVersion": PAYLOAD_VERSION,
        "licenseId": license_id,
        "tenantId": int(tenant_id),
        "installationId": installation_id,
        "fingerprintHash": normalize_fingerprint_hash(fingerprint_hash),
        "keyId": key_id,
        "licenseType": license_type,
        "tier": tier,
        "effectiveTier": effective_tier,
        "issuedAt": canonical_instant(issued_at),
        "expiresAt": canonical_instant(expires_at),
        "quotas": {str(k): int(v) for k, v in quotas.items()},
        "features": dict(features or {}),
    }
    if replaces_license_id:
        payload["replacesLicenseId"] = replaces_license_id
    return payload


def payload_sha256_hex(payload_bytes: bytes) -> str:
    return hashlib.sha256(payload_bytes).hexdigest()


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


@dataclass(frozen=True)
class Envelope:
    license_id: str
    key_id: str
    payload_b64url: str
    payload_sha256: str
    signature_b64url: str
    payload_bytes: bytes
    envelope_json: str  # compact single-line .sllicense content

    def verify_with(self, public_key: Ed25519PublicKey) -> bool:
        try:
            public_key.verify(
                base64.urlsafe_b64decode(self.signature_b64url + "=" * (-len(self.signature_b64url) % 4)),
                self.payload_bytes,
            )
            return True
        except Exception:
            return False


def sign_envelope(payload: dict, key: LoadedKey) -> Envelope:
    """Canonicalize, hash, sign, and assemble the envelope for a payload map."""
    payload_bytes = canonical_bytes(payload)
    digest = payload_sha256_hex(payload_bytes)
    signature = key.private_key.sign(payload_bytes)
    envelope = {
        "format": ENVELOPE_FORMAT,
        "keyId": key.key_id,
        "payload": _b64url(payload_bytes),
        "payloadSha256": digest,
        "signature": _b64url(signature),
    }
    license_id = payload["licenseId"]
    return Envelope(
        license_id=license_id,
        key_id=key.key_id,
        payload_b64url=envelope["payload"],
        payload_sha256=digest,
        signature_b64url=envelope["signature"],
        payload_bytes=payload_bytes,
        envelope_json=json_dumps_compact(envelope),
    )


def json_dumps_compact(value: dict) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
