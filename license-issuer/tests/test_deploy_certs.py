"""NIX-191 follow-up: deployment TLS CA + certificate page.

Covers: company CA creation (refuses overwrite), server certificate issuance
with IP/domain SANs, chain verification against the created CA, the ledger,
and the PEM download endpoints.
"""
from __future__ import annotations

import shutil

from cryptography import x509
from cryptography.hazmat.primitives import serialization
from fastapi.testclient import TestClient

from app.main import create_app
from app.security import hash_password
from app.store import IssuerStore

from tests.conftest import (
    OPERATOR_PASSWORD,
    OPERATOR_USER,
    TEST_KEY_DIR,
    extract_csrf,
    login,
    make_settings,
)

SANS_TEXT = "172.17.10.223, mq.example.com"


def _make_client(tmp_path) -> tuple[TestClient, IssuerStore, object]:
    # Isolated keys dir: carries the test signing key (app boot) and receives
    # the deployment CA written by the pages under test.
    keys_dir = tmp_path / "keys"
    keys_dir.mkdir(parents=True)
    for pem in TEST_KEY_DIR.glob("*.pem"):
        shutil.copy(pem, keys_dir / pem.name)

    settings = make_settings(tmp_path, keys_dir=keys_dir)
    store = IssuerStore(settings.db_path)
    store.create_user(OPERATOR_USER, hash_password(OPERATOR_PASSWORD, rounds=4))
    app = create_app(settings)
    app.state.store = store
    client = TestClient(app, follow_redirects=False)
    login(client)
    return client, store, settings


def _csrf(client: TestClient, path: str = "/deploy-certs") -> str:
    return extract_csrf(client.get(path).text)


def test_ca_creation_and_cert_issue_flow(tmp_path):
    client, store, settings = _make_client(tmp_path)

    # 1. No CA yet: issuing is refused with create-the-CA guidance.
    resp = client.post("/deploy-certs/issue", data={
        "sans": SANS_TEXT, "days": "825", "note": "x",
        "csrf_token": _csrf(client),
    })
    assert resp.status_code == 400
    assert "公司 CA" in resp.text

    # 2. Create the company CA.
    resp = client.post("/deploy-certs/ca", data={
        "commonName": "Test Deploy CA", "csrf_token": _csrf(client),
    })
    assert resp.status_code == 200
    assert "公司 CA 已创建" in resp.text

    # 3. Issue a deployment certificate.
    resp = client.post("/deploy-certs/issue", data={
        "sans": SANS_TEXT, "days": "825", "note": "223 交付",
        "csrf_token": _csrf(client),
    }, follow_redirects=False)
    assert resp.status_code == 303, resp.text

    from app.deploy_store import get_cert, list_certs
    certs = list_certs(store)
    assert len(certs) == 1
    entry = get_cert(store, certs[0]["serial"])
    assert entry["san"].startswith("IP:172.17.10.223")
    assert "DNS:mq.example.com" in entry["san"]

    # 4. The server certificate verifies against the created CA.
    full_pem = entry["fullchainPem"]
    server_pem, sep, ca_pem = full_pem.partition("-----END CERTIFICATE-----\n")
    server = x509.load_pem_x509_certificate((server_pem + sep).encode())
    ca_cert = x509.load_pem_x509_certificate(ca_pem.encode())
    server.verify_directly_issued_by(ca_cert)

    san_ext = server.extensions.get_extension_for_class(
        x509.SubjectAlternativeName).value
    values = san_ext.get_values_for_type(x509.IPAddress) + \
        san_ext.get_values_for_type(x509.DNSName)
    assert len(values) == 2

    # 5. Downloads serve the stored PEMs.
    full = client.get(f"/deploy-certs/{entry['serial']}/download/fullchain")
    key = client.get(f"/deploy-certs/{entry['serial']}/download/privkey")
    assert full.status_code == 200 and b"BEGIN CERTIFICATE" in full.content
    assert key.status_code == 200 and b"PRIVATE KEY" in key.content

    # 6. Audit trail records the issuance.
    audit = [a for a in store.list_audit() if a["action"] == "deploycert.issue"]
    assert len(audit) == 1


def test_second_ca_creation_is_refused(tmp_path):
    client, store, settings = _make_client(tmp_path)
    resp = client.post("/deploy-certs/ca", data={
        "commonName": "First CA", "csrf_token": _csrf(client),
    })
    assert resp.status_code == 200
    resp = client.post("/deploy-certs/ca", data={
        "commonName": "Second CA", "csrf_token": _csrf(client),
    })
    assert resp.status_code == 400
