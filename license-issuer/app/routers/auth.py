"""Authentication pages: login and logout (server-rendered session + CSRF)."""
from __future__ import annotations

from fastapi import APIRouter, Form, Request
from fastapi.responses import RedirectResponse

from app.security import SESSION_COOKIE_NAME, SESSION_MAX_AGE_SECONDS, new_csrf_token
from app.webutil import (
    render_page,
    base_path,
    current_user,
    page_context,
    read_session,
    require_csrf,
)

router = APIRouter()


@router.get("/login")
async def login_page(request: Request):
    user = current_user(request)
    if user:
        return RedirectResponse(url=base_path(request) + "/licenses", status_code=303)
    templates = request.app.state.templates
    # Anonymous bootstrap session carries the CSRF token for the login form.
    signer = request.app.state.sessions
    session = read_session(request) or {"csrf": new_csrf_token()}
    response = render_page(templates, 
        "login.html",
        page_context(request, None) | {"error": None, "csrf_token": session.get("csrf", "")},
    )
    if not read_session(request):
        response.set_cookie(
            SESSION_COOKIE_NAME,
            signer.dumps(session),
            max_age=SESSION_MAX_AGE_SECONDS,
            httponly=True,
            samesite="lax",
            secure=request.app.state.settings.cookie_secure,
        )
    return response


@router.post("/login")
async def login_submit(request: Request, username: str = Form(default=""), password: str = Form(default=""), csrf_token: str = Form(default="")):
    form = {"username": username, "password": password, "csrf_token": csrf_token}
    templates = request.app.state.templates

    def render_error(message: str, status_code: int):
        session = read_session(request) or {"csrf": new_csrf_token()}
        response = render_page(templates, 
            "login.html",
            page_context(request, None) | {"error": message, "csrf_token": session.get("csrf", "")},
            status_code=status_code,
        )
        return response

    # CSRF first: a login POST without a token is rejected outright.
    try:
        await require_csrf(request, form)
    except PermissionError:
        return render_error("会话已过期或 CSRF 校验失败，请重新打开登录页。", 403)

    store = request.app.state.store
    limiter = request.app.state.rate_limiter
    client_ip = request.client.host if request.client else "unknown"
    identity = f"{username}|{client_ip}"

    if limiter.is_blocked(identity):
        return render_error("失败次数过多，请稍后再试。", 429)

    user = store.get_user(username or "")
    from app.security import verify_password

    if user is None or not verify_password(password, user["password_hash"]):
        limiter.record_failure(identity)
        store.add_audit(
            "login.failed",
            username or "(empty)",
            {"ip": client_ip, "reason": "bad credentials"},
        )
        return render_error("用户名或密码错误。", 401)

    limiter.reset(identity)
    store.add_audit("login.success", username, {"ip": client_ip})
    # Fresh session on login (fixation defence) with a new CSRF token.
    signer = request.app.state.sessions
    session = {"user": username, "csrf": new_csrf_token()}
    response = RedirectResponse(url=base_path(request) + "/licenses", status_code=303)
    response.set_cookie(
        SESSION_COOKIE_NAME,
        signer.dumps(session),
        max_age=SESSION_MAX_AGE_SECONDS,
        httponly=True,
        samesite="lax",
        secure=request.app.state.settings.cookie_secure,
    )
    return response


@router.post("/logout")
async def logout(request: Request):
    form = await request.form()
    try:
        session = await require_csrf(request, form)
    except PermissionError:
        return RedirectResponse(url=base_path(request) + "/licenses", status_code=303)
    request.app.state.store.add_audit("logout", session.get("user", "unknown"), {})
    response = RedirectResponse(url=base_path(request) + "/login", status_code=303)
    response.delete_cookie(SESSION_COOKIE_NAME)
    return response
