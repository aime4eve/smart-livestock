"""Security primitives: bcrypt, signed sessions, CSRF, login rate limiting,
and startup configuration fail fast."""
from __future__ import annotations

import pytest

from app.config import IssuerConfigError, Settings
from app.main import create_app
from app.security import (
    CSRF_FIELD_NAME,
    LoginRateLimiter,
    SessionError,
    SessionSigner,
    csrf_matches,
    hash_password,
    new_csrf_token,
    verify_password,
)

from tests.conftest import OPERATOR_PASSWORD, OPERATOR_USER, TEST_KEY_DIR, TEST_KEY_ID, make_settings


# ── bcrypt ───────────────────────────────────────────────────────────


def test_password_hash_and_verify_roundtrip():
    hashed = hash_password("correct-horse-battery", rounds=4)
    assert hashed != "correct-horse-battery"
    assert verify_password("correct-horse-battery", hashed) is True
    assert verify_password("wrong-password", hashed) is False


def test_short_password_rejected():
    with pytest.raises(ValueError):
        hash_password("short", rounds=4)


# ── sessions ─────────────────────────────────────────────────────────


def test_session_roundtrip_and_tamper_rejection():
    signer = SessionSigner("unit-test-session-secret-0123456789abcdef0123")
    token = signer.dumps({"user": "ops", "csrf": "t" * 43})
    assert signer.loads(token)["user"] == "ops"

    tampered = token[:-4] + "AAAA"
    with pytest.raises(SessionError):
        signer.loads(tampered)

    other = SessionSigner("another-secret-0123456789abcdef0123456789")
    with pytest.raises(SessionError):
        other.loads(token)

    assert signer.loads(None) is None
    assert signer.loads("garbage") is None


# ── CSRF ─────────────────────────────────────────────────────────────


def test_csrf_validation():
    session = {"csrf": new_csrf_token()}
    assert csrf_matches(session, session["csrf"]) is True
    assert csrf_matches(session, "wrong-token") is False
    assert csrf_matches(session, None) is False
    assert csrf_matches(None, session["csrf"]) is False
    assert csrf_matches({"csrf": ""}, "x") is False
    assert CSRF_FIELD_NAME == "csrf_token"


# ── login rate limiter ───────────────────────────────────────────────


def test_rate_limiter_blocks_after_max_failures():
    limiter = LoginRateLimiter(max_failures=3, window_seconds=900)
    assert limiter.is_blocked("ops|10.0.0.1") is False
    limiter.record_failure("ops|10.0.0.1")
    limiter.record_failure("ops|10.0.0.1")
    assert limiter.is_blocked("ops|10.0.0.1") is False
    limiter.record_failure("ops|10.0.0.1")
    assert limiter.is_blocked("ops|10.0.0.1") is True
    limiter.reset("ops|10.0.0.1")
    assert limiter.is_blocked("ops|10.0.0.1") is False
    # other identities unaffected
    assert limiter.is_blocked("ops|10.0.0.2") is False


# ── configuration fail fast ──────────────────────────────────────────


def test_missing_session_secret_rejected(tmp_path, monkeypatch):
    for name in ("SESSION_SECRET",):
        monkeypatch.setenv(name, "")
    with pytest.raises(IssuerConfigError, match="SESSION_SECRET"):
        Settings.from_env()


def test_short_session_secret_rejected(tmp_path, monkeypatch):
    monkeypatch.setenv("KEYS_DIR", str(TEST_KEY_DIR))
    monkeypatch.setenv("ACTIVE_KEY_ID", TEST_KEY_ID)
    monkeypatch.setenv("DB_PATH", str(tmp_path / "db.sqlite3"))
    monkeypatch.setenv("SESSION_SECRET", "too-short")
    with pytest.raises(IssuerConfigError, match="too short"):
        Settings.from_env()


def test_base_path_must_start_with_slash(tmp_path, monkeypatch):
    monkeypatch.setenv("KEYS_DIR", str(TEST_KEY_DIR))
    monkeypatch.setenv("DB_PATH", str(tmp_path / "db.sqlite3"))
    monkeypatch.setenv("SESSION_SECRET", "unit-test-session-secret-0123456789abcdef0123")
    monkeypatch.setenv("ISSUER_BASE_PATH", "issuer")
    with pytest.raises(IssuerConfigError, match="ISSUER_BASE_PATH"):
        Settings.from_env()


def test_create_app_fails_fast_without_private_key(tmp_path):
    empty_keys = tmp_path / "no-keys"
    empty_keys.mkdir()
    settings = make_settings(tmp_path, keys_dir=empty_keys, allow_empty_users=True)
    with pytest.raises(Exception, match="not found"):
        create_app(settings)


def test_create_app_fails_fast_without_users(tmp_path):
    settings = make_settings(tmp_path, allow_empty_users=False)
    with pytest.raises(IssuerConfigError, match="create_user"):
        create_app(settings)


def test_create_app_allows_empty_users_in_bootstrap_mode(tmp_path):
    settings = make_settings(tmp_path, allow_empty_users=True)
    app = create_app(settings)
    assert app.state.active_key.key_id == "sl-license-test"
