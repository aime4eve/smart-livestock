"""Operator account bootstrap CLI.

Usage (run from the license-issuer directory):

    python3 -m app.create_user <username>
    python3 -m app.create_user <username> --password <secret>   # non-interactive

Reads DB_PATH from the environment (same database as the web service) and
stores a bcrypt hash of the password. Passwords never touch disk in
plaintext form.
"""
from __future__ import annotations

import argparse
import getpass
import os
import sys

from app.config import PROJECT_ROOT, Settings
from app.security import hash_password
from app.store import IssuerStore


def create_user(store: IssuerStore, username: str, password: str, rounds: int = 12) -> None:
    if not username or not username.strip():
        raise ValueError("username must not be empty")
    password_hash = hash_password(password, rounds=rounds)
    if not store.create_user(username.strip(), password_hash):
        raise ValueError(f"user already exists: {username}")
    # Three-step verification habit (see AGENTS.md): verify what we just wrote.
    stored = store.get_user(username.strip())
    from app.security import verify_password

    if stored is None or not verify_password(password, stored["password_hash"]):
        raise RuntimeError("post-insert bcrypt verification failed; user not usable")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Create a license-issuer operator account")
    parser.add_argument("username")
    parser.add_argument("--password", help="provide non-interactively (prefer the prompt)")
    parser.add_argument("--rounds", type=int, default=None, help="bcrypt cost factor (default from ISSUER_BCRYPT_ROUNDS or 12)")
    args = parser.parse_args(argv)

    settings = Settings.from_env()
    rounds = args.rounds or settings.bcrypt_rounds

    password = args.password
    if not password:
        first = getpass.getpass(f"password for {args.username}: ")
        second = getpass.getpass("repeat password: ")
        if first != second:
            print("error: passwords do not match", file=sys.stderr)
            return 2
        password = first

    try:
        store = IssuerStore(settings.db_path)
        create_user(store, args.username, password, rounds=rounds)
    except (ValueError, RuntimeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    finally:
        try:
            store.close()
        except Exception:
            pass
    print(f"user created: {args.username} (db: {settings.db_path})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
