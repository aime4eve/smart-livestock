"""End-to-end HTTP flow tests: auth, CSRF, issuance, download, pages, audit."""
from __future__ import annotations

import base64
import json

from fastapi.testclient import TestClient

from app.main import create_app
from app.security import hash_password
from app.store import IssuerStore

from tests.conftest import (
    OPERATOR_PASSWORD,
    OPERATOR_USER,
    TEST_KEY_DIR,
    TEST_KEY_ID,
    extract_csrf,
    login,
    make_settings,
)

INSTALLATION_ID = "9e1c2b3a-4d5e-4f60-8a71-9b0c1d2e3f40"
FINGERPRINT = "c" * 64


def _issue_form(csrf_token: str) -> dict:
    return {
        "tenantId": "42",
        "installationId": INSTALLATION_ID,
        "fingerprintHash": FINGERPRINT,
        "licenseType": "ACTIVE",
        "tier": "PREMIUM",
        "effectiveTier": "PREMIUM",
        "issuedAt": "2026-09-01T00:00",
        "expiresAt": "2027-09-01T00:00",
        "quota_livestock_management": "1000",
        "quota_fence_management": "100",
        "quota_worker_management": "50",
        "quota_device_management": "1000",
        "replacesLicenseId": "",
        "reason": "market beta pilot issuance for tenant 42",
        "csrf_token": csrf_token,
    }


def test_unauthenticated_requests_redirect_to_login(client: TestClient):
    for path in ("/licenses", "/issue/new", "/audit", "/keys"):
        response = client.get(path)
        assert response.status_code == 303, path
        assert "/login" in response.headers["location"], path


def test_download_requires_login(client: TestClient):
    response = client.get("/licenses/00000000-0000-0000-0000-000000000000/download")
    assert response.status_code == 303


def test_login_page_renders_with_csrf(client: TestClient):
    page = client.get("/login")
    assert page.status_code == 200
    assert "name=\"csrf_token\"" in page.text
    assert extract_csrf(page.text)


def test_login_with_wrong_password_is_401_and_audited(client: TestClient):
    page = client.get("/login")
    token = extract_csrf(page.text)
    response = client.post(
        "/login",
        data={"username": OPERATOR_USER, "password": "definitely" + "-wrong", "csrf_token": token},
    )
    assert response.status_code == 401
    assert "用户名或密码错误" in response.text
    # unknown user gets the same generic message and is audited too
    response2 = client.post(
        "/login",
        data={"username": "ghost", "password": "whatever" + "-pass", "csrf_token": token},
    )
    assert response2.status_code == 401
    audit_page = login(client)
    assert audit_page.status_code == 303
    audit = client.get("/audit")
    assert "login.failed" in audit.text


def test_login_with_missing_csrf_rejected(client: TestClient):
    response = client.post(
        "/login",
        data={"username": OPERATOR_USER, "password": OPERATOR_PASSWORD},
    )
    assert response.status_code == 403


def test_login_rate_limit_returns_429(tmp_path):
    settings = make_settings(tmp_path, rate_limit_max_failures=3)
    store = IssuerStore(settings.db_path)
    store.create_user(OPERATOR_USER, hash_password(OPERATOR_PASSWORD, rounds=4))
    store.close()
    client = TestClient(create_app(settings), follow_redirects=False)

    page = client.get("/login")
    token = extract_csrf(page.text)
    for _ in range(3):
        bad = client.post(
            "/login",
            data={"username": OPERATOR_USER, "password": "bad" + "-password", "csrf_token": token},
        )
        assert bad.status_code == 401
    blocked = client.post(
        "/login",
        data={"username": OPERATOR_USER, "password": OPERATOR_PASSWORD, "csrf_token": token},
    )
    assert blocked.status_code == 429


def test_issue_flow_signs_downloads_and_verifies(client: TestClient):
    # -- authenticated navigation
    assert login(client).status_code == 303

    # -- new issue form
    new_page = client.get("/issue/new")
    assert new_page.status_code == 200
    assert "tenantId" in new_page.text
    csrf = extract_csrf(new_page.text)

    # -- CSRF enforcement on the preview step
    no_csrf = client.post("/issue/preview", data=_issue_form(""))
    assert no_csrf.status_code == 403
    bad_csrf = client.post("/issue/preview", data=_issue_form("deadbeef"))
    assert bad_csrf.status_code == 403

    # -- valid preview stores the draft and shows the digest
    preview_redirect = client.post("/issue/preview", data=_issue_form(csrf))
    assert preview_redirect.status_code == 303
    assert "/issue/preview" in preview_redirect.headers["location"]

    preview_page = client.get("/issue/preview")
    assert preview_page.status_code == 200
    assert "payload SHA-256" in preview_page.text
    assert INSTALLATION_ID in preview_page.text
    assert "sl-license-test" in preview_page.text

    # -- confirm signs and redirects to done
    confirm = client.post("/issue/confirm", data={"csrf_token": csrf})
    assert confirm.status_code == 303
    done_location = confirm.headers["location"]
    assert "/done" in done_location
    license_id = done_location.rstrip("/").split("/")[-2]

    done_page = client.get(f"/issue/{license_id}/done")
    assert done_page.status_code == 200
    assert license_id in done_page.text

    # -- download: filename, single-line JSON envelope
    download = client.get(f"/licenses/{license_id}/download")
    assert download.status_code == 200
    assert download.headers["content-type"].startswith("application/octet-stream")
    assert download.headers["content-disposition"].endswith(f'{license_id}.sllicense"')
    envelope = json.loads(download.text)
    assert envelope["format"] == "SMART_LIVESTOCK_LICENSE_V1"
    assert envelope["keyId"] == TEST_KEY_ID
    assert "\n" not in download.text.strip()

    # -- verify the downloaded file with ONLY the registered public key
    registry = json.loads((TEST_KEY_DIR / "license-public-keys.json").read_text())
    public_raw = base64.b64decode(
        next(k["publicKey"] for k in registry["keys"] if k["keyId"] == TEST_KEY_ID)
    )
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    from cryptography.hazmat.primitives import hashes

    public_key = Ed25519PublicKey.from_public_bytes(public_raw)
    payload_bytes = base64.urlsafe_b64decode(envelope["payload"] + "=" * (-len(envelope["payload"]) % 4))
    digest = hashes.Hash(hashes.SHA256())
    digest.update(payload_bytes)
    assert digest.finalize().hex() == envelope["payloadSha256"]
    signature = base64.urlsafe_b64decode(envelope["signature"] + "=" * (-len(envelope["signature"]) % 4))
    public_key.verify(signature, payload_bytes)  # raises on mismatch

    # -- tampered payload no longer verifies
    try:
        public_key.verify(signature, payload_bytes.replace(b'"tenantId":42', b'"tenantId":43'))
        tamper_accepted = True
    except Exception:
        tamper_accepted = False
    assert tamper_accepted is False

    # -- list / detail / audit / keys pages
    licenses_page = client.get("/licenses")
    assert licenses_page.status_code == 200
    assert license_id in licenses_page.text

    detail_page = client.get(f"/licenses/{license_id}")
    assert detail_page.status_code == 200
    assert envelope["payloadSha256"] in detail_page.text
    assert FINGERPRINT in detail_page.text

    missing_detail = client.get("/licenses/00000000-0000-0000-0000-000000000000")
    assert missing_detail.status_code == 404

    audit_page = client.get("/audit")
    assert audit_page.status_code == 200
    assert "license.issued" in audit_page.text
    assert "license.downloaded" in audit_page.text
    assert license_id in audit_page.text

    keys_page = client.get("/keys")
    assert keys_page.status_code == 200
    assert TEST_KEY_ID in keys_page.text
    assert "active" in keys_page.text


def test_no_private_key_material_on_any_page(client: TestClient):
    login(client)
    for path in ("/licenses", "/issue/new", "/issue/preview", "/audit", "/keys", "/login"):
        page = client.get(path)
        assert "PRIVATE KEY" not in page.text, path


def test_invalid_issue_form_returns_400_with_errors(client: TestClient):
    login(client)
    new_page = client.get("/issue/new")
    csrf = extract_csrf(new_page.text)
    form = _issue_form(csrf)
    form["tenantId"] = "not-a-number"
    form["fingerprintHash"] = "tooshort"
    response = client.post("/issue/preview", data=form)
    assert response.status_code == 400
    assert "租户 ID" in response.text
    assert "64 位" in response.text


def test_logout_clears_session(client: TestClient):
    login(client)
    keys = client.get("/keys")
    csrf = extract_csrf(keys.text)
    logout = client.post("/logout", data={"csrf_token": csrf})
    assert logout.status_code == 303
    assert client.get("/licenses").status_code == 303  # session gone
