"""Deployment TLS certificate ledger (NIX-191 follow-up).

Backed by the audit log (same pattern as the offline contract registry): each
issuance is one audited event whose details carry the delivery PEMs, so no new
SQL surface is introduced and every issuance is attributable by construction.
Certificates are addressed by their unique serial number for re-download.
"""
from __future__ import annotations

ACTION = "deploycert.issue"


def save(store, operator: str, *, san: str, not_before: str, not_after: str,
         serial: str, note: str, fullchain_pem: str, privkey_pem: str) -> str:
    store.add_audit(ACTION, operator, {
        "san": san,
        "notBefore": not_before,
        "notAfter": not_after,
        "serial": serial,
        "note": note,
        "fullchainPem": fullchain_pem,
        "privkeyPem": privkey_pem,
    })
    return serial


def _decode(item: dict) -> dict:
    details = item.get("details") or {}
    return {
        "serial": details.get("serial", ""),
        "san": details.get("san", ""),
        "notBefore": details.get("notBefore", ""),
        "notAfter": details.get("notAfter", ""),
        "note": details.get("note", ""),
        "issuedBy": item.get("operator", ""),
        "occurredAt": item.get("occurredAt", ""),
        "fullchainPem": details.get("fullchainPem", ""),
        "privkeyPem": details.get("privkeyPem", ""),
    }


def list_certs(store, limit: int = 200) -> list[dict]:
    out: list[dict] = []
    for item in store.list_audit(limit=limit * 3):
        if item.get("action") != ACTION:
            continue
        out.append(_decode(item))
        if len(out) >= limit:
            break
    return out


def get_cert(store, serial: str) -> dict | None:
    for item in store.list_audit(limit=1000):
        if item.get("action") != ACTION:
            continue
        details = item.get("details") or {}
        if details.get("serial") == serial:
            entry = _decode(item)
            entry["occurredAt"] = item.get("occurredAt", "")
            entry["operator"] = item.get("operator", "")
            return entry
    return None
