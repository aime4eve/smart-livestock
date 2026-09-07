"""NIX-191 follow-up: deployment TLS certificate page (company CA).

Create the vendor CA once, then issue per-deployment server certificates
(IP/domain SANs) with fullchain + key downloads. All issuances are audited
and re-downloadable by serial number.
"""
from __future__ import annotations

from fastapi import APIRouter, Request
from fastapi.responses import RedirectResponse, Response

import app.deploy_store as deploy_store
from app.deployca import ca_exists, create_ca, issue_server_cert, parse_sans
from app.webutil import (
    render_page,
    base_path,
    page_context,
    read_session,
    require_csrf,
    require_user,
)

router = APIRouter()


def _context(request: Request, user: str, extra: dict | None = None) -> dict:
    settings = request.app.state.settings
    session = read_session(request) or {}
    context = page_context(request, user) | {
        "ca_exists": ca_exists(settings.keys_dir),
        "csrf_token": session.get("csrf", ""),
        "deploy_certs": deploy_store.list_certs(request.app.state.store),
        "cloud_error": None,
    }
    if extra:
        context |= extra
    return context


@router.get("/deploy-certs")
async def deploy_certs_page(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    return render_page(templates, "deploycerts.html", _context(request, user))


@router.post("/deploy-certs/ca")
async def create_deploy_ca(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    form = await request.form()
    form_map = {k: str(v) for k, v in form.items()}
    try:
        session = await require_csrf(request, form_map)
    except PermissionError:
        return render_page(templates, "error.html",
                           page_context(request, user) | {"message": "CSRF 校验失败，操作被拒绝。"},
                           status_code=403)
    from app import deployca
    common_name = (form_map.get("commonName") or "").strip() or "Livestock Deployment CA"
    try:
        deployca.create_ca(request.app.state.settings.keys_dir, common_name=common_name)
    except ValueError as exc:
        return render_page(templates, "error.html",
                           page_context(request, user) | {"message": str(exc)},
                           status_code=400)
    request.app.state.store.add_audit("deployca.created", user,
                                      {"commonName": common_name})
    return render_page(templates, "deploycerts.html",
                       _context(request, user) | {"createdCa": True})


@router.post("/deploy-certs/issue")
async def issue_deploy_cert(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    form = await request.form()
    form_map = {k: str(v) for k, v in form.items()}
    try:
        session = await require_csrf(request, form_map)
    except PermissionError:
        return render_page(templates, "error.html",
                           page_context(request, user) | {"message": "CSRF 校验失败，操作被拒绝。"},
                           status_code=403)

    from app import deployca
    try:
        sans = parse_sans(form_map.get("sans", ""))
    except ValueError as exc:
        return render_page(templates, "deploycerts.html",
                           _context(request, user) | {"issueError": str(exc)},
                           status_code=400)
    if not ca_exists(request.app.state.settings.keys_dir):
        return render_page(templates, "deploycerts.html",
                           _context(request, user)
                           | {"issueError": "尚未创建公司 CA，请先创建。"},
                           status_code=400)

    days = 825
    raw_days = (form_map.get("days") or "").strip()
    if raw_days.isdigit() and 1 <= int(raw_days) <= 8250:
        days = int(raw_days)
    note = (form_map.get("note") or "").strip()

    bundle = deployca.issue_server_cert(request.app.state.settings.keys_dir,
                                        sans, days)
    serial = deploy_store.save(request.app.state.store, user,
                               san=bundle["sans"],
                               not_before=bundle["notBefore"],
                               not_after=bundle["notAfter"],
                               serial=bundle["serial"],
                               note=note,
                               fullchain_pem=bundle["fullchainPem"],
                               privkey_pem=bundle["privkeyPem"])
    request.app.state.store.add_audit("deploycert.issued", user,
                                      {"serial": bundle["serial"], "san": bundle["sans"]})
    return RedirectResponse(
        url=base_path(request) + f"/deploy-certs/{serial}/done", status_code=303)


@router.get("/deploy-certs/{serial}/done")
async def deploy_cert_done(request: Request, serial: str):
    user = require_user(request)
    templates = request.app.state.templates
    entry = deploy_store.get_cert(request.app.state.store, serial)
    if entry is None:
        return render_page(templates, "error.html",
                           page_context(request, user) | {"message": "部署证书不存在。"},
                           status_code=404)
    return render_page(templates, "deploycert_done.html",
                       page_context(request, user) | {"cert": entry})


@router.get("/deploy-certs/{serial}/download/fullchain")
async def download_fullchain(request: Request, serial: str):
    user = require_user(request)
    entry = deploy_store.get_cert(request.app.state.store, serial)
    if entry is None:
        return Response(status_code=404)
    return Response(content=entry["fullchainPem"], media_type="application/x-pem-file",
                    headers={"Content-Disposition":
                             f'attachment; filename="fullchain-{serial}.pem"'})


@router.get("/deploy-certs/{serial}/download/privkey")
async def download_privkey(request: Request, serial: str):
    user = require_user(request)
    entry = deploy_store.get_cert(request.app.state.store, serial)
    if entry is None:
        return Response(status_code=404)
    return Response(content=entry["privkeyPem"], media_type="application/x-pem-file",
                    headers={"Content-Disposition":
                             f'attachment; filename="privkey-{serial}.pem"'})
