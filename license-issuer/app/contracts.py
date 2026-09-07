"""Contract registry for the issuing tool (NIX-191).

Backed by the audit log instead of a dedicated table: each manual contract
entry is an audited event, which keeps an immutable trail for free and avoids
new SQL surface in the store layer.

Two sourcing modes:
- offline manual entry (this module), and
- online pull from the cloud business API (see routers/contracts.py), which
  auto-fills tier/period from the selected cloud contract.
"""
from __future__ import annotations

ACTION = "contract.add"


def add_contract(store, operator: str, contract_number: str, customer: str = "",
                 tier: str = "", note: str = "") -> None:
    store.add_audit(ACTION, operator, {
        "contractNumber": contract_number,
        "customer": customer,
        "tier": tier,
        "note": note,
    })


def list_contracts(store, limit: int = 200) -> list[dict]:
    contracts: list[dict] = []
    for item in store.list_audit(limit=limit * 3):
        if item.get("action") != ACTION:
            continue
        details = item.get("details") or {}
        contracts.append({
            "contractNumber": details.get("contractNumber", ""),
            "customer": details.get("customer", ""),
            "tier": details.get("tier", ""),
            "note": details.get("note", ""),
            "occurredAt": item.get("occurredAt", ""),
        })
        if len(contracts) >= limit:
            break
    return contracts
