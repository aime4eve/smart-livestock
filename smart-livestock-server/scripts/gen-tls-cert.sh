#!/usr/bin/env bash
# =============================================================================
# gen-tls-cert.sh — TLS certificate helper for release deployments (NIX-191)
#
# Purpose : Create the TLS key material expected at secrets/certs/ so the
#           nginx front door serves HTTPS. Browsers refuse self-signed
#           certificates without a Subject Alternative Name, so the SAN is
#           always generated (host IPs + localhost, or --san values).
# Modes   :
#   default      one-off self-signed server certificate (quick start; browsers
#                will show a trust warning until a CA cert is deployed)
#   --create-ca  additionally create a local CA (ca.crt/ca.key) and issue the
#                server certificate from it — install ca.crt once in the
#                staff browsers and every host signed by this CA is trusted
#   --ca-cert F --ca-key F
#                issue the server certificate from an existing CA
# Usage   : gen-tls-cert.sh --out <certs-dir> [--san value]... [--domain name]
#                 [--create-ca | --ca-cert F --ca-key F] [--force]
# Runs on : Target Linux host (openssl required; installer calls it when
#           secrets/certs is empty). Safe to re-run: existing certs win
#           unless --force.
# =============================================================================
set -euo pipefail

OUT_DIR="./secrets/certs"
CREATE_CA=0
CA_CERT=""
CA_KEY=""
FORCE=0
SANS=()

while (($#)); do
  case "$1" in
    --out)       OUT_DIR="${2:?--out requires a value}"; shift 2 ;;
    --san)       SANS+=("${2:?--san requires a value}"); shift 2 ;;
    --domain)    SANS+=("DNS:${2:?--domain requires a value}"); shift 2 ;;
    --create-ca) CREATE_CA=1; shift ;;
    --ca-cert)   CA_CERT="${2:?--ca-cert requires a value}"; shift 2 ;;
    --ca-key)    CA_KEY="${2:?--ca-key requires a value}"; shift 2 ;;
    --force)     FORCE=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done

command -v openssl >/dev/null 2>&1 || { echo "openssl not found in PATH" >&2; exit 1; }

# Auto-detect host IPs as SANs when the operator gave none.
if (( ${#SANS[@]} == 0 )); then
  if command -v hostname >/dev/null 2>&1; then
    while read -r ip; do
      [[ -n "$ip" ]] && SANS+=("IP:$ip")
    done < <(hostname -I 2>/dev/null || true)
  fi
  SANS+=("DNS:localhost" "IP:127.0.0.1")
fi

mkdir -p "$OUT_DIR"

if [[ -f "$OUT_DIR/fullchain.pem" && -f "$OUT_DIR/privkey.pem" && $FORCE -eq 0 ]]; then
  echo "TLS certificates already present in $OUT_DIR — nothing to do (use --force to overwrite)"
  exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

CA_CRT="$WORK/ca.crt"
CA_KEY="$WORK/ca.key"

if [[ $CREATE_CA -eq 1 ]]; then
  # Local CA: keep ca.crt/ca.key in $OUT_DIR/ca/ — the key is the root of
  # trust for every host signed with it; store it offline after issuance.
  mkdir -p "$OUT_DIR/ca"
  openssl req -x509 -newkey rsa:2048 -keyout "$OUT_DIR/ca/ca.key" \
    -out "$OUT_DIR/ca/ca.crt" -days 3650 -nodes -sha256 \
    -subj "/CN=Deployment Local CA" 2>/dev/null
  chmod 600 "$OUT_DIR/ca/ca.key"
  CA_CRT="$OUT_DIR/ca/ca.crt"
  CA_KEY="$OUT_DIR/ca/ca.key"
  echo "local CA created: $OUT_DIR/ca/ca.crt (install in staff browsers once)"
elif [[ -n "$CA_CERT" ]]; then
  [[ -f "$CA_CERT" && -f "$CA_KEY" ]] || { echo "CA cert/key not found" >&2; exit 1; }
  cp "$CA_CERT" "$CA_CRT"
  cp "$CA_KEY" "$CA_KEY"
else
  : # plain self-signed mode (no CA): server cert only
fi

SAN_ARG="${SANS[*]}"
SAN_ARG="${SAN_ARG// /, }"

openssl req -newkey rsa:2048 -keyout "$WORK/server.key" -out "$WORK/server.csr" \
  -nodes -sha256 -subj "/CN=livestock-release" 2>/dev/null

# Extensions shared by both modes (the SAN list is what browsers require).
printf '%s\n' \
  "basicConstraints=CA:FALSE" \
  "keyUsage=digitalSignature,keyEncipherment" \
  "extendedKeyUsage=serverAuth" \
  "subjectAltName=$SAN_ARG" > "$WORK/ext.cnf"

if [[ -n "$CA_CERT" || $CREATE_CA -eq 1 ]]; then
  openssl x509 -req -in "$WORK/server.csr" -CA "$CA_CRT" -CAkey "$CA_KEY" \
    -CAcreateserial -out "$WORK/server.crt" -days 825 -sha256 \
    -extfile "$WORK/ext.cnf" 2>/dev/null
else
  # No CA given: self-sign the server certificate directly (still carrying
  # the SAN list — the common "missing SAN" browser rejection is avoided).
  openssl x509 -req -in "$WORK/server.csr" -signkey "$WORK/server.key" \
    -out "$WORK/server.crt" -days 825 -sha256 -extfile "$WORK/ext.cnf" 2>/dev/null
fi

if [[ -f "$CA_CRT" ]]; then
  # CA mode: ship leaf + issuer so clients only need the CA installed once.
  cat "$WORK/server.crt" "$CA_CRT" > "$OUT_DIR/fullchain.pem"
else
  cp "$WORK/server.crt" "$OUT_DIR/fullchain.pem"
fi
cp "$WORK/server.key" "$OUT_DIR/privkey.pem"
chmod 600 "$OUT_DIR/privkey.pem"

echo "TLS certificate written:"
echo "  $OUT_DIR/fullchain.pem"
echo "  $OUT_DIR/privkey.pem"
echo "  SAN: $SAN_ARG"
[[ -f "$OUT_DIR/ca/ca.crt" ]] && echo "  local CA: $OUT_DIR/ca/ca.crt (install once in staff browsers)"
