"""Issuance form parsing and payload construction (design section 4 flow).

Turns the operator-facing form into a validated canonical payload map plus an
issuance reason. All validation errors are collected and reported together so
the operator does not have to fix the form one field at a time.
"""
from __future__ import annotations

import uuid
from typing import Mapping

from app.canonical import CanonicalJsonError, canonical_instant
from app.signing import (
    LICENSE_TYPES,
    QUOTA_KEYS,
    TIERS,
    SigningError,
    build_payload,
    normalize_fingerprint_hash,
)

DRAFT_SESSION_KEY = "issue_draft"


class FormValidationError(ValueError):
    def __init__(self, errors: list[str]):
        self.errors = errors
        super().__init__("; ".join(errors))


def _required(form: Mapping[str, str], field: str, label: str, errors: list[str]) -> str:
    value = (form.get(field) or "").strip()
    if not value:
        errors.append(f"{label}为必填项")
    return value


def _parse_uuid(value: str, label: str, errors: list[str]) -> str:
    try:
        return str(uuid.UUID(value)).lower()
    except (ValueError, AttributeError, TypeError):
        errors.append(f"{label}必须是合法 UUID")
        return value


def parse_issue_form(form: Mapping[str, str], key_id: str) -> dict:
    """Validate the new-license form and return ``{"payload": ..., "reason": ...}``.

    Raises :class:`FormValidationError` with all field errors.
    """
    errors: list[str] = []

    license_id = str(uuid.uuid4())

    tenant_raw = _required(form, "tenantId", "租户 ID", errors)
    tenant_id: int | None = None
    if tenant_raw:
        try:
            tenant_id = int(tenant_raw)
            if tenant_id <= 0:
                errors.append("租户 ID 必须为正整数")
        except ValueError:
            errors.append("租户 ID 必须为整数")

    installation_raw = _required(form, "installationId", "安装 ID", errors)
    installation_id = _parse_uuid(installation_raw, "安装 ID", errors) if installation_raw else ""

    fingerprint_raw = _required(form, "fingerprintHash", "主机指纹哈希", errors)
    fingerprint_hash = ""
    if fingerprint_raw:
        try:
            fingerprint_hash = normalize_fingerprint_hash(fingerprint_raw)
        except SigningError:
            errors.append("主机指纹哈希必须是 64 位 sha256 十六进制串")

    license_type = (form.get("licenseType") or "").strip().upper() or "TRIAL"
    if license_type not in LICENSE_TYPES:
        errors.append("授权类型必须是 TRIAL 或 ACTIVE")

    tier = (form.get("tier") or "").strip().upper()
    if tier not in TIERS:
        errors.append("档位必须是 BASIC / PREMIUM / ENTERPRISE")

    effective_tier = (form.get("effectiveTier") or "").strip().upper() or tier
    if effective_tier not in TIERS:
        errors.append("生效档位必须是 BASIC / PREMIUM / ENTERPRISE")

    issued_raw = _required(form, "issuedAt", "生效时间", errors)
    expires_raw = _required(form, "expiresAt", "到期时间", errors)
    issued_at = expires_at = ""
    if issued_raw:
        try:
            issued_at = canonical_instant(issued_raw)
        except CanonicalJsonError:
            errors.append("生效时间格式无效")
    if expires_raw:
        try:
            expires_at = canonical_instant(expires_raw)
        except CanonicalJsonError:
            errors.append("到期时间格式无效")
    if issued_at and expires_at and expires_at <= issued_at:
        errors.append("到期时间必须晚于生效时间")

    quotas: dict[str, int] = {}
    for key in QUOTA_KEYS:
        raw = (form.get(f"quota_{key}") or "").strip()
        if not raw:
            continue
        try:
            value = int(raw)
            if value < 0:
                raise ValueError
            quotas[key] = value
        except ValueError:
            errors.append(f"配额 {key} 必须为非负整数")

    replaces_raw = (form.get("replacesLicenseId") or "").strip()
    replaces_license_id = ""
    if replaces_raw:
        replaces_license_id = _parse_uuid(replaces_raw, "被替换授权 ID", errors)

    reason = (form.get("reason") or "").strip()
    if len(reason) < 3:
        errors.append("请填写签发原因（至少 3 个字符），将进入审计记录")

    if errors:
        raise FormValidationError(errors)

    payload = build_payload(
        license_id=license_id,
        tenant_id=tenant_id,
        installation_id=installation_id,
        fingerprint_hash=fingerprint_hash,
        key_id=key_id,
        license_type=license_type,
        tier=tier,
        effective_tier=effective_tier,
        issued_at=issued_at,
        expires_at=expires_at,
        quotas=quotas,
        features={},
        replaces_license_id=replaces_license_id or None,
    )
    return {"payload": payload, "reason": reason}
