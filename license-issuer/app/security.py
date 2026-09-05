"""Security primitives: bcrypt passwords, signed session cookies, CSRF tokens,
and an in-memory login rate limiter (design section 4).

Only the Python standard library is used for session/CSRF so there is no
dependency on a specific framework security stack.
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
import secrets
import time
from collections import deque
from dataclasses import dataclass, field

import bcrypt

SESSION_COOKIE_NAME = "issuer_session"
CSRF_FIELD_NAME = "csrf_token"
SESSION_MAX_AGE_SECONDS = 8 * 3600


# ── Passwords ────────────────────────────────────────────────────────


def hash_password(password: str, rounds: int = 12) -> str:
    if not password or len(password) < 8:
        raise ValueError("password must be at least 8 characters")
    salt = bcrypt.gensalt(rounds=rounds)
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("ascii")


def verify_password(password: str, password_hash: str) -> bool:
    if not password or not password_hash:
        return False
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("ascii"))
    except (ValueError, TypeError):
        return False


# ── Sessions ─────────────────────────────────────────────────────────


class SessionError(ValueError):
    """Raised when a session cookie fails signature or format validation."""


class SessionSigner:
    """Compact signed-token session: ``base64url(json).hmac_sha256``.

    Stateless on the server side; the CSRF token rides inside the signed
    session so it cannot be rotated independently by a client.
    """

    def __init__(self, secret: str):
        if not secret:
            raise ValueError("session secret must not be empty")
        self._secret = secret.encode("utf-8")

    def _sign(self, body: bytes) -> str:
        digest = hmac.new(self._secret, body, hashlib.sha256).digest()
        return base64.urlsafe_b64encode(digest).decode("ascii").rstrip("=")

    def dumps(self, data: dict) -> str:
        body = json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        encoded = base64.urlsafe_b64encode(body).decode("ascii").rstrip("=")
        return f"{encoded}.{self._sign(encoded.encode('ascii'))}"

    def loads(self, token: str | None) -> dict | None:
        if not token or "." not in token:
            return None
        encoded, _, signature = token.rpartition(".")
        if not encoded or not signature:
            return None
        if not hmac.compare_digest(signature, self._sign(encoded.encode("ascii"))):
            raise SessionError("session signature mismatch")
        padding = "=" * (-len(encoded) % 4)
        try:
            body = base64.urlsafe_b64decode(encoded + padding)
            data = json.loads(body)
        except (ValueError, TypeError):
            raise SessionError("session body is corrupt")
        if not isinstance(data, dict):
            raise SessionError("session body must be an object")
        return data


def new_csrf_token() -> str:
    return secrets.token_urlsafe(32)


def csrf_matches(session: dict | None, submitted: str | None) -> bool:
    if not session or not submitted:
        return False
    expected = session.get("csrf")
    if not expected:
        return False
    return hmac.compare_digest(str(expected), str(submitted))


# ── Login rate limiting ──────────────────────────────────────────────


@dataclass
class LoginRateLimiter:
    """Fixed-window failure counter per key (username + client IP)."""

    max_failures: int = 5
    window_seconds: int = 900
    _failures: dict = field(default_factory=dict)

    def _key(self, identity: str) -> str:
        return (identity or "unknown").strip().lower()

    def _prune(self, key: str, now: float) -> None:
        window = self._failures.get(key)
        if window is None:
            return
        cutoff = now - self.window_seconds
        while window and window[0] <= cutoff:
            window.popleft()
        if not window:
            self._failures.pop(key, None)

    def is_blocked(self, identity: str) -> bool:
        now = time.monotonic()
        key = self._key(identity)
        with_ok = self._failures.get(key)
        if with_ok is None:
            return False
        self._prune(key, now)
        window = self._failures.get(key)
        return bool(window) and len(window) >= self.max_failures

    def record_failure(self, identity: str) -> None:
        key = self._key(identity)
        self._failures.setdefault(key, deque()).append(time.monotonic())

    def reset(self, identity: str) -> None:
        self._failures.pop(self._key(identity), None)
