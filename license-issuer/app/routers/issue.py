"""License issuance flow (design section 4):

form -> validated draft (signed session) -> preview with payload digest and
explicit confirmation -> sign with the active key -> persist + audit -> done
page with a download link.

The in-progress draft travels inside the signed session cookie, so the
operator cannot silently alter the digest shown on the preview page after
seeing it: the confirm step signs exactly the previewed draft.

NIX-191: when the operator fills in the deployment administrator phone, a
one-time initial password is generated, its bcrypt hash is signed into the
payload, and the plaintext is shown exactly once on the done page (deliver it
through a separate channel from the certificate file). A selected cloud
contract gets the certificate id written back automatically.
"""
from __future__ import annotations

import ipaddress
import json
import socket
import ssl
import urllib.parse
import urllib.request

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


def _post_cloud_json(request: Request, path: str, body: dict) -> tuple[int, str]:
    """POST JSON to the configured cloud business API (fixed server-side base).

    The URL is assembled from startup configuration only (never from user
    input); ``path`` is a constant route joined onto it, and any dynamic id in
    ``body`` was digit-validated at form-parse time. Private/loopback targets
    require the explicit CLOUD_ALLOW_PRIVATE_IP opt-in (beta boxes live on a
    private network by design). CLOUD_TLS_INSECURE accepts the beta
    self-signed/local-CA cloud certificate.
    """
    settings = request.app.state.settings
    parsed = urllib.parse.urlparse(settings.cloud_base_url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        raise RuntimeError("CLOUD_BASE_URL 配置无效")
    if not settings.cloud_allow_private_ip:
        ip = socket.gethostbyname(parsed.hostname)
        addr = ipaddress.ip_address(ip)
        if (addr.is_private or addr.is_loopback or addr.is_link_local
                or addr.is_reserved):
            raise RuntimeError(
                f"云端地址解析到内网/保留 IP（{ip}）；如确属内网部署，"
                "请在签发机配置 CLOUD_ALLOW_PRIVATE_IP=1"
            )
    url = settings.cloud_base_url + path
    data = json.dumps(body).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {settings.cloud_token}",
    }
    if settings.cloud_tls_insecure and parsed.scheme == "https":
        # Beta: the cloud boxes use the vendor local-CA certificate; operators
        # can install that CA on the issuing machine and set CLOUD_TLS_INSECURE=0.
        context = ssl._create_unverified_context()
        req = urllib.request.Request(url, data=data, headers=headers, method="POST")
        with urllib.request.urlopen(req, timeout=15, context=context) as resp:
            return resp.status, resp.read().decode("utf-8", "replace")[:200]
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=15) as resp:
        return resp.status, resp.read().decode("utf-8", "replace")[:200]


def _write_back_to_cloud(request: Request, contract: dict | None, license_id: str) -> str | None:
    """Best-effort contract write-back; failures never block the issuance."""
    settings = request.app.state.settings
    if not contract or not contract.get("contractId"):
        return None
    if not settings.cloud_base_url or not settings.cloud_token:
        return None  # offline manual mode: no cloud contract behind the entry
    try:
        status, _body = _post_cloud_json(
            request,
            f"/api/v1/admin/contracts/{contract['contractId']}/license-issued",
            {"licenseId": license_id},
        )
        if status == 200:
            return f"已将证书 {license_id} 回写到合同 #{contract['contractId']}。"
        return f"合同回写返回非预期状态 {status}，请人工核对合同 #{contract['contractId']}。"
    except Exception as exc:  # network unreachable, TLS, HTTP error — report only
        return f"合同回写失败（{exc}），请人工在云端为合同 #{contract['contractId']} 补记证书编号。"


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

    # NIX-191: allow the contracts page to prefill the form via query params.
    prefill = {
        key: value
        for key, value in request.query_params.items()
        if key in ("contractId", "contractNumber", "tenantId", "tier", "effectiveTier", "adminPhone")
    }

    context = page_context(request, user) | {
        "errors": None,
        "form": prefill,
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
        # NIX-191: present only when the operator asked for an admin
        # bootstrap; the plaintext travels in the signed session and is
        # displayed exactly once on the done page.
        "oneTimePassword": parsed.get("oneTimePassword"),
        "adminPhone": parsed.get("adminPhone"),
        "contract": parsed.get("contract"),
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
    contract_info = draft.get("contract") or {}
    if contract_info:
        draft["reason"] += f"（合同: {contract_info.get('contractNumber') or contract_info.get('contractId')}）"
    store.add_audit(
        "license.issued",
        user,
        {
            "licenseId": envelope.license_id,
            "tenantId": payload["tenantId"],
            "keyId": envelope.key_id,
            "payloadSha256": envelope.payload_sha256,
            "reason": draft["reason"],
            "adminPhone": draft.get("adminPhone") or "",
            "contract": contract_info or None,
        },
    )
    writeback = _write_back_to_cloud(request, contract_info, envelope.license_id)

    session[DRAFT_SESSION_KEY] = {
        "payload": payload,
        "reason": draft["reason"],
        "payloadSha256": envelope.payload_sha256,
        "keyId": envelope.key_id,
        "licenseId": envelope.license_id,
        "oneTimePassword": draft.get("oneTimePassword"),
        "adminPhone": draft.get("adminPhone"),
        "contract": contract_info,
        "writebackNote": writeback,
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
    draft = session.get(DRAFT_SESSION_KEY) or {}
    just_issued = last_issued == license_id
    return render_page(templates, 
        "issue_done.html",
        page_context(request, user)
        | {"license": license_row, "just_issued": just_issued,
           # NIX-191: the one-time admin password is displayed exactly once,
           # only for the issuance this session just performed.
           "oneTimePassword": draft.get("oneTimePassword") if just_issued else None,
           "adminPhone": draft.get("adminPhone") if just_issued else None,
           "writebackNote": draft.get("writebackNote") if just_issued else None,
           "csrf_token": session.get("csrf", "")},
    )
