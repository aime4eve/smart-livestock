"""Read-only views: license list, detail, download, audit log, and key status.

The keys page only ever shows keyId, public key fingerprint, and active flag —
private key material is never rendered or served.
"""
from __future__ import annotations

from fastapi import APIRouter, Request
from fastapi.responses import Response

from app.webutil import (
    render_page,
    page_context,
    require_user,
)

router = APIRouter()


@router.get("/licenses")
async def licenses_page(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    licenses = request.app.state.store.list_licenses()
    return render_page(templates, 
        "licenses.html",
        page_context(request, user) | {"licenses": licenses},
    )


@router.get("/licenses/{license_id}")
async def license_detail(request: Request, license_id: str):
    user = require_user(request)
    templates = request.app.state.templates
    license_row = request.app.state.store.get_license(license_id)
    if license_row is None:
        return render_page(templates, 
            "error.html",
            page_context(request, user) | {"message": "授权记录不存在。"},
            status_code=404,
        )
    return render_page(templates, 
        "license_detail.html",
        page_context(request, user) | {"license": license_row},
    )


@router.get("/licenses/{license_id}/download")
async def license_download(request: Request, license_id: str):
    user = require_user(request)
    store = request.app.state.store
    license_row = store.get_license(license_id)
    templates = request.app.state.templates
    if license_row is None:
        return render_page(templates, 
            "error.html",
            page_context(request, user) | {"message": "授权记录不存在。"},
            status_code=404,
        )
    client_ip = request.client.host if request.client else "unknown"
    store.add_audit(
        "license.downloaded",
        user,
        {"licenseId": license_id, "ip": client_ip},
    )
    filename = f"{license_id}.sllicense"
    body = license_row["envelope_json"]
    if not body.endswith("\n"):
        body += "\n"
    return Response(
        content=body,
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/audit")
async def audit_page(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    entries = request.app.state.store.list_audit()
    return render_page(templates, 
        "audit.html",
        page_context(request, user) | {"entries": entries},
    )


@router.get("/keys")
async def keys_page(request: Request):
    user = require_user(request)
    templates = request.app.state.templates
    active_key = request.app.state.active_key
    keys = [
        {
            "keyId": active_key.key_id,
            "publicKeyFingerprint": active_key.public_key_fingerprint,
            "publicKeyB64": active_key.public_key_b64,
            "active": True,
        }
    ]
    return render_page(templates, 
        "keys.html",
        page_context(request, user) | {"keys": keys},
    )
