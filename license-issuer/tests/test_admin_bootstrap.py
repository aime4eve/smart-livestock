"""NIX-191: deployment administrator bootstrap on issuance.

The issuing form births the customer's platform administrator: the phone
rides in the signed payload next to the bcrypt hash of a generated one-time
password, whose plaintext is returned exactly once to the operator.
"""
from __future__ import annotations

import re

import pytest

from app.issuance import FormValidationError, parse_issue_form
from app.security import verify_password


BASE_FORM = {
    "tenantId": "42",
    "installationId": "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40",
    "fingerprintHash": "a" * 64,
    "licenseType": "ACTIVE",
    "tier": "PREMIUM",
    "effectiveTier": "PREMIUM",
    "issuedAt": "2026-09-07T00:00:00Z",
    "expiresAt": "2027-09-07T00:00:00Z",
    "reason": "NIX-191 bootstrap issuance test",
}


def test_admin_phone_generates_one_time_password_and_hash():
    result = parse_issue_form({**BASE_FORM, "adminPhone": "13912345678"}, "test-key")
    payload = result["payload"]
    assert payload["adminPhone"] == "13912345678"
    assert payload["adminPasswordHash"].startswith("$2")
    password = result["oneTimePassword"]
    assert isinstance(password, str) and len(password) >= 10
    assert re.search(r"[A-Za-z]", password) and re.search(r"\d", password)
    # The plaintext verifies against the signed hash.
    assert verify_password(password, payload["adminPasswordHash"])


def test_renewal_without_admin_phone_omits_bootstrap_fields():
    result = parse_issue_form(dict(BASE_FORM), "test-key")
    assert "adminPhone" not in result["payload"]
    assert "adminPasswordHash" not in result["payload"]
    assert "oneTimePassword" not in result


def test_invalid_admin_phone_is_collected_as_form_error():
    with pytest.raises(FormValidationError) as exc:
        parse_issue_form({**BASE_FORM, "adminPhone": "13a-456"}, "test-key")
    assert any("手机号" in e for e in exc.value.errors)


def test_contract_fields_pass_through_into_result():
    form = {**BASE_FORM, "adminPhone": "13912345678", "contractId": "7",
            "contractNumber": "HT-2026-001"}
    result = parse_issue_form(form, "test-key")
    assert result["contract"] == {"contractId": "7", "contractNumber": "HT-2026-001"}


def test_non_numeric_contract_id_is_rejected():
    with pytest.raises(FormValidationError) as exc:
        parse_issue_form({**BASE_FORM, "contractId": "abc", "adminPhone": "13912345678"},
                         "test-key")
    assert any("合同 ID" in e for e in exc.value.errors)
