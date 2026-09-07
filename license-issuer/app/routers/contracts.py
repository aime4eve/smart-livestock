"""NIX-191 contract registry page: cloud pull (online) + manual entry (offline).

- Online mode (CLOUD_BASE_URL/CLOUD_TOKEN configured): lists ACTIVE contracts
  from the cloud business API with a one-click "去签发" link that prefills the
  issue form.
- Offline mode: manual contract registry entries stored in the audited local
  registry, also linkable into the issue form.
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

from app.contracts import add_contract, list_contracts
from app.webutil import render_page, base_path, page_context, read_session, require_csrf, require_user

router = APIRouter()


def _cloud_get_contracts(request: Request) -> tuple[list[dict] | None, str | None]:
    """Fetch ACTIVE contracts from the cloud business API (best effort)."""
    settings = request.app.state.settings
    if not settings.cloud_base_url or not settings.cloud_token:
        return None, None  # offline mode: not an error
    parsed = urllib.parse.urlparse(settings.cloud_base_url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        return None, "CLOUD_BASE_URL 配置无效"
    if not settings.cloud_allow_private_ip:
        try:
            ip = socket.gethostbyname(parsed.hostname)
            addr = ipaddress.ip_address(ip)
            if addr.is_private or addr.is_loopback or addr.is_link_local or addr.is_reserved:
                return None, "云端地址解析到内网/保留 IP，需显式配置 CLOUD_ALLOW_PRIVATE_IP=1"
        except OSError as exc:
            return None, f"云端地址解析失败：{exc}"
    url = settings.cloud_base_url + "/api/v1/admin/contracts"
    headers = {"Authorization": f"Bearer {settings.cloud_token}"}
    if settings.cloud_tls_insecure and parsed.scheme == "https":
        # Beta: cloud boxes use the vendor local-CA certificate; install that
        # CA on the issuing machine and set CLOUD_TLS_INSECURE=0 to pin trust.
        context = ssl._create_unverified_context()
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15, context=context) as resp:
            body = json.loads(resp.read().decode("utf-8", "replace"))
    else:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            body = json.loads(resp.read().decode("utf-8", "replace"))
    data = body.get("data") or {}
    items = data.get("items") or []
    return [c for c in items if (c.get("status") or "").upper() == "ACTIVE"], None


@router.get("/contracts")
async def contracts_page(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    session = read_session(request) or {}
    cloud_contracts, cloud_error = _cloud_get_contracts(request)
    cloud_enabled = request.app.state.settings.cloud_base_url != ""
    manual = list_contracts(request.app.state.store)
    context = page_context(request, user) | {
        "cloud_enabled": cloud_enabled,
        "cloud_contracts": cloud_contracts,
        "cloud_error": cloud_error,
        "manual_contracts": manual,
        "csrf_token": session.get("csrf", ""),
    }
    return render_page(templates, "contracts.html", context)


@router.post("/contracts")
async def contracts_add(request: Request):
    user = require_user(request)
    form = await request.form()
    form_map = {k: str(v) for k, v in form.items()}
    try:
        session = await require_csrf(request, form_map)
    except PermissionError:
        return render_page(request.app.state.templates, "error.html",
                           page_context(request, user) | {"message": "CSRF 校验失败，操作被拒绝。"},
                           status_code=403)
    number = (form_map.get("contractNumber") or "").strip()
    if number:
        add_contract(request.app.state.store, user,
                     contract_number=number,
                     customer=(form_map.get("customer") or "").strip(),
                     tier=(form_map.get("tier") or "").strip().upper(),
                     note=(form_map.get("note") or "").strip())
    return RedirectResponse(url=base_path(request) + "/contracts", status_code=303)


@router.get("/contracts/{contract_number}/prefill")
async def contracts_prefill(request: Request, contract_number: str):
    """Legacy redirect kept for manual entries: jump to the issue form."""
    return RedirectResponse(
        url=base_path(request) + f"/issue/new?contractNumber={urllib.parse.quote(contract_number)}",
        status_code=303,
    )
