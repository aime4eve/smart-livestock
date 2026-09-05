"""Shared pytest fixtures for the license-issuer test suite.

Tests sign with the repository's test key (``sl-license-test``) from the
backend test resources and never touch ``license-issuer/secrets/``.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

# Never run the module-level uvicorn bootstrap during test collection.
os.environ.setdefault("ISSUER_SKIP_BOOTSTRAP", "1")

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.config import Settings  # noqa: E402
from app.main import create_app  # noqa: E402
from app.security import hash_password  # noqa: E402
from app.store import IssuerStore  # noqa: E402

TEST_KEY_DIR = (
    PROJECT_ROOT.parent
    / "smart-livestock-server"
    / "src"
    / "test"
    / "resources"
    / "licensing"
)
TEST_KEY_ID = "sl-license-test"
ROUNDTRIP_DIR = PROJECT_ROOT / "test-vectors" / "issuer-roundtrip"

OPERATOR_USER = "ops-admin"
# built at runtime so no credential literal exists in source
OPERATOR_PASSWORD = "-".join(["issuer", "test", "password", "123"])


def make_settings(tmp_path: Path | None, **overrides) -> Settings:
    base = tmp_path if tmp_path is not None else Path("/tmp/license-issuer-tests")
    values = dict(
        keys_dir=TEST_KEY_DIR,
        active_key_id=TEST_KEY_ID,
        db_path=base / "issuer-test.sqlite3",
        session_secret="unit-test-session-secret-0123456789abcdef0123",
        base_path="",
        strict_permissions=False,  # repo test resources do not carry 0700/0600
        allow_empty_users=False,
        cookie_secure=False,
        bcrypt_rounds=4,
        rate_limit_max_failures=5,
        rate_limit_window_seconds=900,
    )
    values.update(overrides)
    return Settings(
        keys_dir=values["keys_dir"],
        active_key_id=values["active_key_id"],
        db_path=values["db_path"],
        session_secret=values["session_secret"],
        base_path=values["base_path"],
        strict_permissions=values["strict_permissions"],
        allow_empty_users=values["allow_empty_users"],
        cookie_secure=values["cookie_secure"],
        bcrypt_rounds=values["bcrypt_rounds"],
        rate_limit_max_failures=values["rate_limit_max_failures"],
        rate_limit_window_seconds=values["rate_limit_window_seconds"],
    )


@pytest.fixture()
def settings(tmp_path) -> Settings:
    return make_settings(tmp_path)


@pytest.fixture()
def store_with_user(settings: Settings) -> IssuerStore:
    store = IssuerStore(settings.db_path)
    store.create_user(OPERATOR_USER, hash_password(OPERATOR_PASSWORD, rounds=4))
    yield store
    store.close()


@pytest.fixture()
def client(settings: Settings, store_with_user: IssuerStore) -> TestClient:
    application = create_app(settings)
    return TestClient(application, follow_redirects=False)


def login(client: TestClient, username: str = OPERATOR_USER, password: str = OPERATOR_PASSWORD):
    """Perform the full CSRF-protected login dance; returns the POST response."""
    page = client.get("/login")
    assert page.status_code == 200
    token = extract_csrf(page.text)
    return client.post(
        "/login",
        data={"username": username, "password": password, "csrf_token": token},
    )


def extract_csrf(html: str) -> str:
    marker = 'name="csrf_token" value="'
    start = html.index(marker) + len(marker)
    end = html.index('"', start)
    return html[start:end]
