#!/usr/bin/env bash
# =============================================================================
# verify-release-bundle.sh — release-package contract checker
#
# Purpose : Asserts the offline bundle contract (design §13) on an EXTRACTED
#           package directory:
#             - SHA256SUMS verifies (images.tar.gz + release/*)
#             - no license-issuer/ anywhere in the package
#             - no PEM private-key material ("BEGIN ... PRIVATE KEY")
#             - no *.pem files at all (TLS certs are user-supplied at install)
#             - no *.sllicense license artifacts
#             - compose hard-codes DATAGEN_ENABLED="false" and
#               TELEMETRY_SIMULATOR_ENABLED="false"
#             - compose has no build: sections (pre-built images only) and no
#               ports: outside nginx (internal services stay host-unmapped)
# Usage   : ./verify-release-bundle.sh <extracted-package-dir>
#           e.g. smart-livestock-market-beta-<version>/ containing
#           images.tar.gz + SHA256SUMS + release/.
# Runs on : Any machine (build machine smoke test and pre-install on target).
# Design  : docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md (§13)
# Limits  : grep cannot see inside images.tar.gz (gzip); the private-key and
#           issuer scans therefore cover the extracted tree. The ports:/
#           build: assertion is indentation-based, not a full YAML parser —
#           it assumes the canonical 2-space layout of docker-compose.release.yml.
# =============================================================================
set -euo pipefail

if [[ -t 1 ]]; then
  C_INFO=$'\033[1;34m'; C_OK=$'\033[0;32m'; C_WARN=$'\033[0;33m'; C_ERR=$'\033[0;31m'; C_OFF=$'\033[0m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_OFF=''
fi
info() { printf '%s==> %s%s\n'  "$C_INFO" "$*" "$C_OFF"; }
ok()   { printf '%s [PASS] %s%s\n' "$C_OK" "$*" "$C_OFF"; }
warn() { printf '%s [WARN] %s%s\n' "$C_WARN" "$*" "$C_OFF"; }
fail() { printf '%s [FAIL] %s%s\n' "$C_ERR" "$*" "$C_OFF" >&2; }
die()  { fail "$*"; exit 1; }

[[ $# -eq 1 ]] || { sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }
PKG="${1%/}"
[[ -d "$PKG" ]] || die "package dir not found: $PKG"
PKG_ABS="$(cd "$PKG" && pwd)"

PASS_COUNT=0
FAIL_COUNT=0
pass() { ok "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
bad()  { fail "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

info "Verifying release bundle: $PKG_ABS"

# ── 0. Structure ─────────────────────────────────────────────────────────────
for f in "images.tar.gz" "SHA256SUMS" "release/docker-compose.release.yml" "release/.env.release.example"; do
  if [[ -f "$PKG_ABS/$f" ]]; then
    pass "present: $f"
  else
    bad "missing: $f"
  fi
done

# ── 1. SHA256SUMS ────────────────────────────────────────────────────────────
SUMS_OK=0
if [[ -f "$PKG_ABS/SHA256SUMS" ]]; then
  # Output is discarded (not --status) so busybox sha256sum works like GNU's.
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$PKG_ABS" && sha256sum -c SHA256SUMS >/dev/null 2>&1) && SUMS_OK=1 || true
  else
    (cd "$PKG_ABS" && shasum -a 256 -c SHA256SUMS >/dev/null 2>&1) && SUMS_OK=1 || true
  fi
fi
if (( SUMS_OK )); then
  pass "SHA256SUMS verifies (all checksums match)"
else
  bad "SHA256SUMS verification failed:"
  if [[ -f "$PKG_ABS/SHA256SUMS" ]]; then
    (cd "$PKG_ABS" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c SHA256SUMS || true; else shasum -a 256 -c SHA256SUMS || true; fi) >&2
  fi
fi

# ── 2. No license-issuer anywhere ────────────────────────────────────────────
HITS="$(find "$PKG_ABS" -name 'license-issuer*' -print 2>/dev/null || true)"
if [[ -z "$HITS" ]]; then
  pass "no license-issuer path in package"
else
  bad "license-issuer present in package (issuing infrastructure must never ship):"
  printf '%s\n' "$HITS" | sed 's/^/        /' >&2
fi

# ── 3. No PEM private-key material ───────────────────────────────────────────
# -I skips binary (images.tar.gz is gzip); see header Limits note.
HITS="$(grep -rIlE 'BEGIN [A-Z0-9 ]*PRIVATE KEY' "$PKG_ABS" 2>/dev/null || true)"
if [[ -z "$HITS" ]]; then
  pass "no private-key armor (BEGIN ... PRIVATE KEY) in package"
else
  bad "private-key material found in:"
  printf '%s\n' "$HITS" | sed 's/^/        /' >&2
fi

# ── 4. No *.pem files at all ─────────────────────────────────────────────────
# TLS certs are user-supplied at install time (./secrets/certs/); the package
# must not carry fullchain.pem OR privkey.pem — any pem is a violation.
HITS="$(find "$PKG_ABS" -type f -name '*.pem' ! -name '._*' -print 2>/dev/null || true)"
if [[ -z "$HITS" ]]; then
  pass "no *.pem files (certs are user-supplied at install)"
else
  bad "*.pem files found in package:"
  printf '%s\n' "$HITS" | sed 's/^/        /' >&2
fi

# ── 5. No *.sllicense artifacts ──────────────────────────────────────────────
HITS="$(find "$PKG_ABS" -type f -name '*.sllicense' ! -name '._*' -print 2>/dev/null || true)"
if [[ -z "$HITS" ]]; then
  pass "no *.sllicense files"
else
  bad "*.sllicense files found in package (licenses are issued per-host, never shipped):"
  printf '%s\n' "$HITS" | sed 's/^/        /' >&2
fi

COMPOSE="$PKG_ABS/release/docker-compose.release.yml"
if [[ -f "$COMPOSE" ]]; then
  # ── 6. Synthetic-data switches hard-off in compose ─────────────────────────
  for key in DATAGEN_ENABLED TELEMETRY_SIMULATOR_ENABLED; do
    if grep -Eq "^[[:space:]]*${key}:[[:space:]]*\"?false\"?" "$COMPOSE"; then
      pass "compose pins $key=false"
    else
      bad "compose does not pin $key=false"
    fi
  done

  # ── 7. No build: sections (pre-built images only) ──────────────────────────
  if grep -Eq '^[[:space:]]+build:' "$COMPOSE"; then
    bad "compose contains build: sections (install host must never need build context)"
  else
    pass "compose has no build: sections"
  fi

  # ── 8. ports: only under nginx ─────────────────────────────────────────────
  # Indentation-based parse (documented limitation): a service key is a line
  # with exactly 2 leading spaces ending in ':', a ports key has 4+ spaces.
  PORT_SVCS="$(awk '
    /^[[:space:]]*#/ { next }
    /^  [A-Za-z0-9_-]+:[[:space:]]*$/ { svc = $1; sub(/:$/, "", svc) }
    /^[[:space:]]{4,}ports:/ { print svc }
  ' "$COMPOSE" | LC_ALL=C sort -u)"
  if [[ "$PORT_SVCS" == "nginx" ]]; then
    pass "compose ports: only under nginx"
  else
    bad "compose ports: found outside nginx -> [${PORT_SVCS//$'\n'/, }]"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────
info "Result: $PASS_COUNT passed, $FAIL_COUNT failed."
if (( FAIL_COUNT > 0 )); then
  fail "BUNDLE VERIFICATION FAILED"
  exit 1
fi
info "BUNDLE VERIFICATION PASSED"
