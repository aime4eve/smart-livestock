"""FastAPI application factory for the internal license-issuer service.

Startup order is deliberately fail fast (design section 4):
1. resolve settings from the environment
2. load the active Ed25519 private key (permissions, algorithm, presence)
3. run a sign+verify self-test
4. open the SQLite store; refuse to boot with zero operator accounts unless
   ``ISSUER_ALLOW_EMPTY_USERS=1`` (bootstrap mode, e.g. first provisioning)

This service must only ever be deployed on an internal trusted network and
must never be shipped inside a customer release package.
"""
from __future__ import annotations

import os
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

from app.config import IssuerConfigError, Settings
from app.routers import auth, issue, views
from app.security import LoginRateLimiter, SessionSigner
from app.signing import LoadedKey, load_signing_key, self_test
from app.store import IssuerStore
from app.webutil import LoginRequired

TEMPLATES_DIR = Path(__file__).resolve().parent / "templates"


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings.from_env()

    # 1+2+3: signing trust root — fail fast on any problem.
    active_key: LoadedKey = load_signing_key(
        settings.keys_dir,
        settings.active_key_id,
        strict_permissions=settings.strict_permissions,
    )
    self_test(active_key)

    # 4: persistence + operator accounts.
    store = IssuerStore(settings.db_path)
    if store.count_users() == 0 and not settings.allow_empty_users:
        raise IssuerConfigError(
            "no operator accounts exist yet. Run `python3 -m app.create_user <username>` "
            "first, or set ISSUER_ALLOW_EMPTY_USERS=1 for controlled bootstrap."
        )

    app = FastAPI(
        title="SmartLivestock license-issuer",
        docs_url=None,
        redoc_url=None,
        openapi_url=None,
    )
    app.state.settings = settings
    app.state.store = store
    app.state.active_key = active_key
    app.state.sessions = SessionSigner(settings.session_secret)
    app.state.rate_limiter = LoginRateLimiter(
        max_failures=settings.rate_limit_max_failures,
        window_seconds=settings.rate_limit_window_seconds,
    )
    app.state.templates = Jinja2Templates(directory=str(TEMPLATES_DIR))

    prefix = settings.base_path
    app.include_router(auth.router, prefix=prefix)
    app.include_router(issue.router, prefix=prefix)
    app.include_router(views.router, prefix=prefix)

    @app.exception_handler(LoginRequired)
    async def login_required_handler(request: Request, exc: LoginRequired):
        return RedirectResponse(url=prefix + "/login", status_code=303)

    @app.exception_handler(PermissionError)
    async def csrf_rejected_handler(request: Request, exc: PermissionError):
        return JSONResponse(
            status_code=403,
            content={"error": "forbidden", "detail": str(exc)},
        )

    @app.get(prefix + "/")
    async def index(request: Request):
        return RedirectResponse(url=prefix + "/licenses", status_code=303)

    return app


# Module-level ASGI entry for `uvicorn app.main:app`. Tests disable the
# bootstrap via ISSUER_SKIP_BOOTSTRAP=1 because they build their own app
# instances through create_app().
if os.environ.get("ISSUER_SKIP_BOOTSTRAP") == "1":
    app = None  # type: ignore[assignment]
else:
    try:
        app = create_app()
    except Exception as exc:  # noqa: BLE001 - operator readable exit
        raise SystemExit(f"license-issuer startup failed: {exc}") from exc
