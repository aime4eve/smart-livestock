"""Configuration for the internal license-issuer service (design section 4).

All configuration comes from environment variables so the service can run in a
container or bare-metal without a config file. Invalid configuration must fail
fast at startup, never at first request.
"""
from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

# Project root = the license-issuer directory (parent of the app package).
PROJECT_ROOT = Path(__file__).resolve().parent.parent

DEFAULT_ACTIVE_KEY_ID = "sl-license-2026q3"


class IssuerConfigError(RuntimeError):
    """Raised when startup configuration is invalid; the service must exit."""


def _env(name: str, default: str | None = None) -> str | None:
    value = os.environ.get(name)
    if value is None or value == "":
        return default
    return value


@dataclass(frozen=True)
class Settings:
    """Resolved startup settings."""

    keys_dir: Path
    active_key_id: str
    db_path: Path
    session_secret: str
    base_path: str
    strict_permissions: bool
    allow_empty_users: bool
    cookie_secure: bool
    bcrypt_rounds: int
    rate_limit_max_failures: int
    rate_limit_window_seconds: int

    @classmethod
    def from_env(cls, env: dict | None = None) -> "Settings":
        source = env if env is not None else os.environ

        def read(name: str, default: str | None = None) -> str | None:
            value = source.get(name)
            if value is None or value == "":
                return default
            return value

        keys_dir = Path(
            read("KEYS_DIR", str(PROJECT_ROOT / "secrets"))
        ).expanduser().resolve()
        active_key_id = read("ACTIVE_KEY_ID", DEFAULT_ACTIVE_KEY_ID)
        db_path = Path(read("DB_PATH", str(PROJECT_ROOT / "data" / "issuer.sqlite3"))).expanduser()

        session_secret = read("SESSION_SECRET")
        if not session_secret:
            raise IssuerConfigError(
                "SESSION_SECRET is required. Generate one with: "
                "python3 -c \"import secrets; print(secrets.token_hex(32))\""
            )
        if len(session_secret) < 32:
            raise IssuerConfigError(
                "SESSION_SECRET is too short (minimum 32 characters); "
                "it signs the issuer session cookie."
            )

        base_path = read("ISSUER_BASE_PATH", "").strip()
        if base_path and not base_path.startswith("/"):
            raise IssuerConfigError("ISSUER_BASE_PATH must start with '/' when set")
        base_path = base_path.rstrip("/")

        strict = (read("KEYS_STRICT_PERMISSIONS", "1") or "1").lower() not in ("0", "false", "no")
        allow_empty_users = (read("ISSUER_ALLOW_EMPTY_USERS", "0") or "0").lower() in ("1", "true", "yes")
        cookie_secure = (read("ISSUER_COOKIE_SECURE", "0") or "0").lower() in ("1", "true", "yes")

        try:
            bcrypt_rounds = int(read("ISSUER_BCRYPT_ROUNDS", "12"))
        except ValueError:
            raise IssuerConfigError("ISSUER_BCRYPT_ROUNDS must be an integer")
        if not (4 <= bcrypt_rounds <= 15):
            raise IssuerConfigError("ISSUER_BCRYPT_ROUNDS must be between 4 and 15")

        try:
            rate_max = int(read("ISSUER_RATE_LIMIT_MAX_FAILURES", "5"))
            rate_window = int(read("ISSUER_RATE_LIMIT_WINDOW_SECONDS", "900"))
        except ValueError:
            raise IssuerConfigError("rate limit settings must be integers")

        return cls(
            keys_dir=keys_dir,
            active_key_id=active_key_id,
            db_path=db_path,
            session_secret=session_secret,
            base_path=base_path,
            strict_permissions=strict,
            allow_empty_users=allow_empty_users,
            cookie_secure=cookie_secure,
            bcrypt_rounds=bcrypt_rounds,
            rate_limit_max_failures=max(1, rate_max),
            rate_limit_window_seconds=max(1, rate_window),
        )
