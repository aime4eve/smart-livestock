"""License issuance flow (design section 4):

form -> validated draft (signed session) -> preview with payload digest and
explicit confirmation -> sign with the active key -> persist + audit -> done
page with a download link.

The in-progress draft travels inside the signed session cookie, so the
operator cannot silently alter the digest shown on the preview page after
seeing it: the confirm step signs exactly the previewed draft.
"""
from __future__ import annotations

from fastapi import APIRouter, Request
from fastapi.responses import RedirectResponse

from app.canonical import canonical_bytes
from app.issuance import DRAFT_SESSION_KEY, FormValidationError, parse_issue_form
from app.security import SESSION_COOKIE_NAME, SESSION_MAX_AGE_SECONDS, new_csrf_token
from app.signing import payload_sha256_hex, sign_envelope
from app.webutil import (
    render_page,
    base_path,
    page_context,
    read_session,
    require_csrf,
    require_user,
)

router = APIRouter()


def _set_session_cookie(request: Request, response, session: dict):
    signer = request.app.state.sessions
    response.set_cookie(
        SESSION_COOKIE_NAME,
        signer.dumps(session),
        max_age=SESSION_MAX_AGE_SECONDS,
        httponly=True,
        samesite="lax",
        secure=request.app.state.settings.cookie_secure,
    )
    return response


def _draft_from_session(request: Request) -> dict | None:
    session = read_session(request)
    if not session:
        return None
    draft = session.get(DRAFT_SESSION_KEY)
    if isinstance(draft, dict) and "payload" in draft and "payloadSha256" in draft:
        return draft
    return None


@router.get("/issue/new")
async def issue_new(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    session = read_session(request)
    response = None
    if session is None:
        session = {"user": user, "csrf": new_csrf_token()}
    elif "csrf" not in session:
        session["csrf"] = new_csrf_token()
    else:
        session = None  # unchanged; do not resend the cookie

    context = page_context(request, user) | {
        "errors": None,
        "form": {},
        "csrf_token": (session or read_session(request) or {}).get("csrf", ""),
    }
    rendered = render_page(templates, "issue_new.html", context)
    return _set_session_cookie(request, rendered, session) if session else rendered


@router.post("/issue/preview")
async def issue_preview(request: Request):
    user = require_user(request)
    form = await request.form()
    form_map = {k: str(v) for k, v in form.items()}
    templates = request.app.state.templates

    try:
        session = await require_csrf(request, form_map)
    except PermissionError:
        return render_page(templates, 
            "error.html",
            page_context(request, user) | {"message": "CSRF 校验失败，操作被拒绝。"},
            status_code=403,
        )

    active_key = request.app.state.active_key
    try:
        parsed = parse_issue_form(form_map, active_key.key_id)
    except FormValidationError as exc:
        return render_page(templates, 
            "issue_new.html",
            page_context(request, user) | {"errors": exc.errors, "form": form_map,
                                           "csrf_token": session.get("csrf", "")},
            status_code=400,
        )

    payload = parsed["payload"]
    session[DRAFT_SESSION_KEY] = {
        "payload": payload,
        "reason": parsed["reason"],
        "payloadSha256": payload_sha256_hex(canonical_bytes(payload)),
        "keyId": active_key.key_id,
    }
    return _set_session_cookie(
        request,
        RedirectResponse(url=base_path(request) + "/issue/preview", status_code=303),
        session,
    )


@router.get("/issue/preview")
async def issue_preview_page(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    draft = _draft_from_session(request)
    if draft is None:
        return RedirectResponse(url=base_path(request) + "/issue/new", status_code=303)
    session = read_session(request) or {}
    return render_page(templates, 
        "issue_preview.html",
        page_context(request, user)
        | {"draft": draft, "csrf_token": session.get("csrf", "")},
    )


@router.post("/issue/confirm")
async def issue_confirm(request: Request):
    user = require_user(request)
    form = await request.form()
    form_map = {k: str(v) for k, v in form.items()}
    templates = request.app.state.templates

    try:
        session = await require_csrf(request, form_map)
    except PermissionError:
        return render_page(templates, 
            "error.html",
            page_context(request, user) | {"message": "CSRF 校验失败，操作被拒绝。"},
            status_code=403,
        )

    draft = _draft_from_session(request)
    if draft is None:
        return RedirectResponse(url=base_path(request) + "/issue/new", status_code=303)

    payload = dict(draft["payload"])
    envelope = sign_envelope(payload, request.app.state.active_key)

    store = request.app.state.store
    store.insert_license(
        license_id=envelope.license_id,
        tenant_id=int(payload["tenantId"]),
        installation_id=str(payload["installationId"]),
        fingerprint_hash=str(payload["fingerprintHash"]),
        key_id=envelope.key_id,
        license_type=str(payload["licenseType"]),
        tier=str(payload["tier"]),
        effective_tier=str(payload["effectiveTier"]),
        issued_at=str(payload["issuedAt"]),
        expires_at=str(payload["expiresAt"]),
        payload_sha256=envelope.payload_sha256,
        issued_by=user,
        reason=draft["reason"],
        envelope_json=envelope.envelope_json,
    )
    store.add_audit(
        "license.issued",
        user,
        {
            "licenseId": envelope.license_id,
            "tenantId": payload["tenantId"],
            "keyId": envelope.key_id,
            "payloadSha256": envelope.payload_sha256,
            "reason": draft["reason"],
        },
    )

    session[DRAFT_SESSION_KEY] = {
        "payload": payload,
        "reason": draft["reason"],
        "payloadSha256": envelope.payload_sha256,
        "keyId": envelope.key_id,
        "licenseId": envelope.license_id,
    }
    session["issued_license_id"] = envelope.license_id
    return _set_session_cookie(
        request,
        RedirectResponse(
            url=f"{base_path(request)}/issue/{envelope.license_id}/done", status_code=303
        ),
        session,
    )


@router.get("/issue/{license_id}/done")
async def issue_done(request: Request, license_id: str):
    user = require_user(request)
    templates = request.app.state.templates
    license_row = request.app.state.store.get_license(license_id)
    if license_row is None:
        return render_page(templates, 
            "error.html",
            page_context(request, user) | {"message": "授权记录不存在。"},
            status_code=404,
        )
    session = read_session(request) or {}
    last_issued = (session.get(DRAFT_SESSION_KEY) or {}).get("licenseId")
    return render_page(templates, 
        "issue_done.html",
        page_context(request, user)
        | {"license": license_row, "just_issued": last_issued == license_id,
           "csrf_token": session.get("csrf", "")},
    )
