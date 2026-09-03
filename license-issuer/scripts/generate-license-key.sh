#!/usr/bin/env bash
# =============================================================================
# generate-license-key.sh — generate an Ed25519 signing key pair for the
#                           license issuer (NIX-184)
#
# Purpose : Creates a new Ed25519 private key <keysDir>/<keyId>.pem (PKCS#8
#           PEM, chmod 0600) for license-issuer signing, prints the raw 32-byte
#           public key (base64, the format of license-public-keys.json) and
#           its SHA-256 fingerprint (the format shown on the issuer /keys page).
# Usage   : scripts/generate-license-key.sh <keyId> [keysDir]
#           keyId    e.g. sl-license-2027q1 (allowed: A-Za-z0-9 . _ -)
#           keysDir  default: <repo>/license-issuer/secrets  (issuer KEYS_DIR
#                    default layout: <KEYS_DIR>/<keyId>.pem, dir 0700)
# Runs on : Issuer host / secure operator machine (offline recommended).
#           NOT part of the customer release package; the private key NEVER
#           leaves this directory and never ships to customers (design §13).
# Design  : docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md (§3/§4)
# =============================================================================
set -euo pipefail

if [[ -t 1 ]]; then
  C_INFO=$'\033[1;34m'; C_OK=$'\033[0;32m'; C_WARN=$'\033[0;33m'; C_ERR=$'\033[0;31m'; C_OFF=$'\033[0m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_OFF=''
fi
info() { printf '%s==> %s%s\n'  "$C_INFO" "$*" "$C_OFF"; }
ok()   { printf '%s    [OK] %s%s\n' "$C_OK" "$*" "$C_OFF"; }
warn() { printf '%s [WARN] %s%s\n' "$C_WARN" "$*" "$C_OFF"; }
die()  { printf '%s [FAIL] %s%s\n' "$C_ERR" "$*" "$C_OFF" >&2; exit 1; }

usage() { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

# Self-locate: <repo>/license-issuer/scripts/generate-license-key.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISSUER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$ISSUER_DIR/.." && pwd)"
DEFAULT_KEYS_DIR="$ISSUER_DIR/secrets"

KEY_ID="${1:-}"
KEYS_DIR="${2:-$DEFAULT_KEYS_DIR}"
if [[ -z "$KEY_ID" || "$KEY_ID" == "-h" || "$KEY_ID" == "--help" ]]; then
  usage
  [[ -z "$KEY_ID" ]] && exit 1 || exit 0
fi

# keyId lands in a filename and in license-public-keys.json / audit records.
if [[ ! "$KEY_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  die "invalid keyId '$KEY_ID' (allowed: letters, digits, '.', '_', '-'; must start alphanumeric)"
fi
[[ "$KEY_ID" == sl-license-* ]] || warn "keyId does not start with 'sl-license-' (convention: sl-license-<year>q<quarter>)"

command -v openssl >/dev/null 2>&1 || die "openssl not found in PATH"
command -v base64 >/dev/null 2>&1 || die "base64 not found in PATH"

if [[ -e "$KEYS_DIR/$KEY_ID.pem" ]]; then
  die "refusing to overwrite existing key: $KEYS_DIR/$KEY_ID.pem (pick a new keyId or remove the old key deliberately)"
fi
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

KEY_FILE="$KEYS_DIR/$KEY_ID.pem"

# ── 1. Generate (probe Ed25519 support first for a clear error) ──────────────
info "Generating Ed25519 key -> $KEY_FILE"
TMP_KEY="$(mktemp "${TMPDIR:-/tmp}/${KEY_ID}.XXXXXX.pem")"
trap 'rm -f "$TMP_KEY"' EXIT
OPENSSL_VERSION="$(openssl version 2>/dev/null || echo unknown)"
if ! openssl genpkey -algorithm ed25519 -out "$TMP_KEY" 2>/dev/null; then
  die "this openssl ($OPENSSL_VERSION) does not support Ed25519 key generation.
     Ed25519 needs OpenSSL 1.1.1+ (or LibreSSL 3.1+). Options:
       - run this script on a Linux issuer host (recommended), or
       - install a modern openssl, e.g. 'brew install openssl@3' on macOS
         and re-run with PATH=\"$(brew --prefix)/opt/openssl@3/bin:\$PATH\"."
fi

# Self-check: the key must parse back as Ed25519 before it is put in place.
if ! openssl pkey -in "$TMP_KEY" -check -noout >/dev/null 2>&1; then
  rm -f "$TMP_KEY"
  die "generated key failed the Ed25519 self-check — nothing written"
fi
mv "$TMP_KEY" "$KEY_FILE"
trap - EXIT
chmod 600 "$KEY_FILE"

# ── 2. Public key (raw 32 bytes, base64) + fingerprint ───────────────────────
# openssl pkey -pubout -outform DER for Ed25519 emits 44 bytes: 12-byte
# SubjectPublicKeyInfo header + 32-byte raw key -> tail -c 32 keeps the raw key.
RAW_PUB_B64="$(openssl pkey -in "$KEY_FILE" -pubout -outform DER | tail -c 32 | base64)"
if command -v sha256sum >/dev/null 2>&1; then
  FP="$(openssl pkey -in "$KEY_FILE" -pubout -outform DER | tail -c 32 | sha256sum | cut -d' ' -f1)"
else
  FP="$(openssl pkey -in "$KEY_FILE" -pubout -outform DER | tail -c 32 | shasum -a 256 | cut -d' ' -f1)"
fi

info "Done."
ok "private key : $KEY_FILE (0600, dir $(basename "$KEYS_DIR") 0700)"
ok "keyId       : $KEY_ID"
ok "public key  : $RAW_PUB_B64"
ok "sha256      : $FP"
info "后续步骤（中文提示）："
info "  1. 将上面「public key」原样追加进 license-public-keys.json："
info "     smart-livestock-server/src/main/resources/licensing/license-public-keys.json"
# NOTE: braces are mandatory here — a multibyte char right after $VAR gets
# absorbed into the variable name by bash (unbound-variable error).
info "     {\"keyId\": \"${KEY_ID}\", \"publicKey\": \"${RAW_PUB_B64}\", \"status\": \"active\"}"
info "     （轮换时旧 key 的 status 改 retired，且仅保留一个 active。）"
info "  2. 私钥保留在本 issuer keys 目录（目录 0700 / 文件 0600），"
info "     同步更新 issuer 的 ACTIVE_KEY_ID=${KEY_ID}。"
info "  3. 私钥绝不进入 release 包 / 代码库 / 地端（设计 §13 红线）。"
