"""Deployment TLS CA + server certificate management (NIX-191 follow-up).

The vendor company CA lives under ``<keys_dir>/deploy-ca/`` (ca.crt/ca.key,
0700/0600). Created once from the web UI; every deployment server
certificate is signed by it, so staff browsers trust all deployments after
installing ``ca.crt`` once. Uses the ``cryptography`` package that the
issuer already depends on for Ed25519 — no new dependencies.
"""
from __future__ import annotations

import datetime
import ipaddress
import re
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID

_CA_DIR_NAME = "deploy-ca"
_SERVER_DAYS_DEFAULT = 825
_CA_DAYS = 3650


def ca_paths(keys_dir: str | Path) -> tuple[Path, Path]:
    base = Path(keys_dir) / _CA_DIR_NAME
    return base / "ca.crt", base / "ca.key"


def ca_exists(keys_dir: str | Path) -> bool:
    crt, key = ca_paths(keys_dir)
    return crt.is_file() and key.is_file()


def create_ca(keys_dir: str | Path, common_name: str = "Livestock Deployment CA") -> None:
    """Create the vendor deployment CA once. Refuses to overwrite."""
    crt_path, key_path = ca_paths(keys_dir)
    if ca_exists(keys_dir):
        raise ValueError("deployment CA already exists")
    key_path.parent.mkdir(parents=True, exist_ok=True)

    ca_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    now = datetime.datetime.now(datetime.timezone.utc)
    subject = x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, common_name or "Deployment CA"),
    ])
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(subject)
        .public_key(ca_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - datetime.timedelta(minutes=5))
        .not_valid_after(now + datetime.timedelta(days=_CA_DAYS))
        .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
        .sign(ca_key, hashes.SHA256())
    )
    key_path.write_bytes(ca_key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.TraditionalOpenSSL,
        serialization.NoEncryption(),
    ))
    crt_path.write_bytes(cert.public_bytes(serialization.Encoding.PEM))
    key_path.chmod(0o600)
    crt_path.chmod(0o644)


def load_ca(keys_dir: str | Path):
    crt_path, key_path = ca_paths(keys_dir)
    ca_key = serialization.load_pem_private_key(key_path.read_bytes(), password=None)
    ca_cert = x509.load_pem_x509_certificate(crt_path.read_bytes())
    return ca_key, ca_cert


def parse_sans(raw: str) -> list[x509.GeneralName]:
    """Parse a comma/whitespace separated SAN list into GeneralName values.

    Bare tokens are treated as IPs when they parse as one, otherwise as DNS
    names (lowercased, hostname-charset validated).
    """
    sans: list[x509.GeneralName] = []
    seen: set[str] = set()
    for token in re.split(r"[,\s]+", raw or ""):
        token = token.strip()
        if token.lower().startswith("dns:"):
            token = token[4:]
        elif token.lower().startswith("ip:"):
            token = token[3:]
        token = token.strip()
        if not token or token.lower() in seen:
            continue
        seen.add(token.lower())
        try:
            sans.append(x509.IPAddress(ipaddress.ip_address(token)))
        except ValueError:
            if not re.fullmatch(r"[A-Za-z0-9*._-]+", token):
                raise ValueError(f"非法的 SAN 值: {token}")
            sans.append(x509.DNSName(token.lower()))
    if not sans:
        raise ValueError("至少需要一个 SAN（IP 或域名）")
    return sans


def issue_server_cert(keys_dir: str | Path, sans: list[x509.GeneralName],
                      days: int = 825) -> dict:
    """Issue (or re-issue) a server certificate from the deployment CA.

    Returns the delivery bundle as PEM text plus metadata for the ledger:
    ``{"fullchainPem", "privkeyPem", "notBefore", "notAfter", "serial"}``.
    """
    if not ca_exists(keys_dir):
        raise ValueError("deployment CA does not exist")
    if not 1 <= days <= 8250:
        raise ValueError("validity must be between 1 and 8250 days")
    ca_key, ca_cert = load_ca(keys_dir)

    server_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    now = datetime.datetime.now(datetime.timezone.utc)
    subject = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "livestock-release")])
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(ca_cert.subject)
        .public_key(server_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - datetime.timedelta(minutes=5))
        .not_valid_after(now + datetime.timedelta(days=days))
        .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
        .add_extension(x509.KeyUsage(
            digital_signature=True, key_encipherment=True, content_commitment=False,
            data_encipherment=False, key_agreement=False, key_cert_sign=False,
            crl_sign=False, encipher_only=False, decipher_only=False), critical=True)
        .add_extension(x509.ExtendedKeyUsage([x509.ExtendedKeyUsageOID.SERVER_AUTH]),
                       critical=False)
        .add_extension(x509.SubjectAlternativeName(sans), critical=False)
        .sign(ca_key, hashes.SHA256())
    )

    server_pem = cert.public_bytes(serialization.Encoding.PEM).decode("ascii")
    ca_pem = ca_cert.public_bytes(serialization.Encoding.PEM).decode("ascii")
    key_pem = server_key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.TraditionalOpenSSL,
        serialization.NoEncryption(),
    ).decode("ascii")
    return {
        "fullchainPem": server_pem + ca_pem,
        "privkeyPem": key_pem,
        "notBefore": cert.not_valid_before_utc.isoformat(),
        "notAfter": cert.not_valid_after_utc.isoformat(),
        "serial": format(cert.serial_number, "x"),
        "sans": ", ".join(
            f"IP:{s.value}" if isinstance(s.value, ipaddress.IPv4Address)
            or isinstance(s.value, ipaddress.IPv6Address) else f"DNS:{s.value}"
            for s in sans
        ),
    }
