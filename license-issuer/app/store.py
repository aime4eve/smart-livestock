"""SQLite persistence for issued licenses, audit log, and operator accounts.

A single connection guarded by a lock is sufficient for an internal tool with
a handful of operators; WAL mode keeps readers and writers from blocking.
"""
from __future__ import annotations

import json
import sqlite3
import threading
from datetime import datetime, timezone
from pathlib import Path

_SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
    username      TEXT PRIMARY KEY,
    password_hash TEXT NOT NULL,
    created_at    TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS licenses (
    license_id       TEXT PRIMARY KEY,
    tenant_id        INTEGER NOT NULL,
    installation_id  TEXT NOT NULL,
    fingerprint_hash TEXT NOT NULL,
    key_id           TEXT NOT NULL,
    license_type     TEXT NOT NULL,
    tier             TEXT NOT NULL,
    effective_tier   TEXT NOT NULL,
    issued_at        TEXT NOT NULL,
    expires_at       TEXT NOT NULL,
    payload_sha256   TEXT NOT NULL,
    issued_by        TEXT NOT NULL,
    reason           TEXT NOT NULL,
    created_at       TEXT NOT NULL,
    envelope_json    TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS audit (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    action       TEXT NOT NULL,
    operator     TEXT NOT NULL,
    details_json TEXT NOT NULL,
    occurred_at  TEXT NOT NULL
);
"""


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


class IssuerStore:
    def __init__(self, db_path: str | Path):
        db_path = Path(db_path)
        db_path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._conn = sqlite3.connect(str(db_path), check_same_thread=False)
        self._conn.row_factory = sqlite3.Row
        self._conn.execute("PRAGMA journal_mode=WAL")
        self._conn.executescript(_SCHEMA)
        self._conn.commit()

    def close(self) -> None:
        with self._lock:
            self._conn.close()

    # ── users ────────────────────────────────────────────────────────

    def count_users(self) -> int:
        with self._lock:
            row = self._conn.execute("SELECT COUNT(*) AS n FROM users").fetchone()
            return int(row["n"])

    def create_user(self, username: str, password_hash: str) -> bool:
        with self._lock:
            try:
                self._conn.execute(
                    "INSERT INTO users (username, password_hash, created_at) VALUES (?, ?, ?)",
                    (username, password_hash, utc_now_iso()),
                )
                self._conn.commit()
                return True
            except sqlite3.IntegrityError:
                return False

    def get_user(self, username: str) -> dict | None:
        with self._lock:
            row = self._conn.execute(
                "SELECT username, password_hash FROM users WHERE username = ?",
                (username,),
            ).fetchone()
            return dict(row) if row else None

    # ── licenses ─────────────────────────────────────────────────────

    def insert_license(
        self,
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
        payload_sha256: str,
        issued_by: str,
        reason: str,
        envelope_json: str,
    ) -> None:
        with self._lock:
            self._conn.execute(
                """
                INSERT INTO licenses (
                    license_id, tenant_id, installation_id, fingerprint_hash,
                    key_id, license_type, tier, effective_tier, issued_at,
                    expires_at, payload_sha256, issued_by, reason, created_at,
                    envelope_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    license_id, tenant_id, installation_id, fingerprint_hash,
                    key_id, license_type, tier, effective_tier, issued_at,
                    expires_at, payload_sha256, issued_by, reason, utc_now_iso(),
                    envelope_json,
                ),
            )
            self._conn.commit()

    def list_licenses(self) -> list[dict]:
        with self._lock:
            rows = self._conn.execute(
                """
                SELECT license_id, tenant_id, installation_id, license_type,
                       tier, effective_tier, issued_at, expires_at, key_id,
                       issued_by, created_at
                FROM licenses ORDER BY created_at DESC, license_id
                """
            ).fetchall()
            return [dict(row) for row in rows]

    def get_license(self, license_id: str) -> dict | None:
        with self._lock:
            row = self._conn.execute(
                "SELECT * FROM licenses WHERE license_id = ?",
                (license_id,),
            ).fetchone()
            return dict(row) if row else None

    # ── audit ────────────────────────────────────────────────────────

    def add_audit(self, action: str, operator: str, details: dict | None = None) -> None:
        with self._lock:
            self._conn.execute(
                "INSERT INTO audit (action, operator, details_json, occurred_at) VALUES (?, ?, ?, ?)",
                (action, operator, json.dumps(details or {}, ensure_ascii=False, separators=(",", ":")), utc_now_iso()),
            )
            self._conn.commit()

    def list_audit(self, limit: int = 200) -> list[dict]:
        with self._lock:
            rows = self._conn.execute(
                "SELECT id, action, operator, details_json, occurred_at "
                "FROM audit ORDER BY id DESC LIMIT ?",
                (int(limit),),
            ).fetchall()
            result = []
            for row in rows:
                item = dict(row)
                try:
                    item["details"] = json.loads(item.pop("details_json"))
                except (TypeError, ValueError):
                    item["details"] = {}
                result.append(item)
            return result
