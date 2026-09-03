"""Shared request-scoped helpers for the issuer web UI: session access,
login enforcement, and CSRF validation."""
from __future__ import annotations

from fastapi import Request
from fastapi.responses import RedirectResponse

from app.config import Settings
from app.security import (
    CSRF_FIELD_NAME,
    SESSION_COOKIE_NAME,
    SessionError,
    SessionSigner,
    csrf_matches,
)
from app.store import IssuerStore


class LoginRequired(Exception):
    """Raised when an unauthenticated request hits a protected page."""


def get_settings(request: Request) -> Settings:
    return request.app.state.settings


def get_store(request: Request) -> IssuerStore:
    store: IssuerStore = request.app.state.store
    return store


def base_path(request: Request) -> str:
    return request.app.state.settings.base_path


def read_session(request: Request) -> dict | None:
    """Parse the signed session cookie; a tampered cookie counts as logged out."""
    signer: SessionSigner = request.app.state.sessions
    token = request.cookies.get(SESSION_COOKIE_NAME)
    if not token:
        return None
    try:
        session = signer.loads(token)
    except SessionError:
        return None
    return session


def current_user(request: Request) -> str | None:
    session = read_session(request)
    if not session:
        return None
    user = session.get("user")
    return str(user) if user else None


def require_user(request: Request) -> str:
    user = current_user(request)
    if not user:
        raise LoginRequired()
    return user


async def require_csrf(request: Request, form) -> dict:
    """Validate the CSRF token of a submitted form against the signed session.

    Returns the parsed session (never None). Raises PermissionError on a
    missing or wrong token, which the app maps to 403.
    """
    session = read_session(request)
    submitted = form.get(CSRF_FIELD_NAME)
    if not csrf_matches(session, submitted if isinstance(submitted, str) else None):
        raise PermissionError("CSRF token missing or invalid")
    assert session is not None
    return session


def page_context(request: Request, user: str | None) -> dict:
    session = read_session(request) or {}
    return {
        "request": request,
        "user": user,
        "base": base_path(request),
        "active_key_id": request.app.state.active_key.key_id,
        # Every page embeds the session CSRF token (nav logout form needs it).
        "csrf_token": session.get("csrf", ""),
    }


def render_page(templates, template_name: str, context: dict, status_code: int = 200):
    """Render a template with the current starlette TemplateResponse signature
    (request as the first argument); every context dict carries ``request``."""
    return templates.TemplateResponse(
        context["request"], template_name, context, status_code=status_code
    )
