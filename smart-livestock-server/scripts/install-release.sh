#!/usr/bin/env bash
# =============================================================================
# install-release.sh — offline installer for the market-beta release bundle
#
# Purpose : Preflight-checks the target host (Linux, docker >= 20, compose v2,
#           CPU/mem/disk, free host ports, .env.release secrets, TLS certs),
#           loads images.tar.gz via `docker load`, boots the release compose
#           stack and waits until https://localhost:$HTTPS_PORT/health is 200.
# Usage   : ./scripts/install-release.sh
#           Run from the extracted package's release/ directory; the script
#           locates ../images.tar.gz (or ./images.tar.gz) by itself.
#           Threshold overrides (env): MIN_CPU_CORES (8) MIN_MEM_GB (16)
#           MIN_DISK_GB (100) HEALTH_TIMEOUT_SECS (300).
# Runs on : Target Linux host only (offline install; /etc/machine-id is the
#           ONPREM license fingerprint source, so non-Linux is rejected).
# Design  : docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md (§13/§14)
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

# Self-locate: this script lives at <package>/release/scripts/install-release.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG_ROOT="$(dirname "$RELEASE_DIR")"
cd "$RELEASE_DIR"

ENV_FILE=".env.release"
COMPOSE_FILE="docker-compose.release.yml"
IMAGES_TAR=""
for cand in "$PKG_ROOT/images.tar.gz" "$RELEASE_DIR/images.tar.gz"; do
  if [[ -f "$cand" ]]; then IMAGES_TAR="$cand"; break; fi
done

MIN_CPU_CORES="${MIN_CPU_CORES:-8}"
MIN_MEM_GB="${MIN_MEM_GB:-16}"
MIN_DISK_GB="${MIN_DISK_GB:-100}"
HEALTH_TIMEOUT_SECS="${HEALTH_TIMEOUT_SECS:-300}"

# ── .env.release key readers (same awk approach as scripts/check-env.sh) ─────
value_of() {
  awk -F= -v key="$1" '
    $1 == key {
      sub(/^[^=]*=/, "")
      gsub(/^[[:space:]]+"|[[:space:]]*"$/, "")
      print
      exit
    }
  ' "$ENV_FILE"
}

# Preflight issue counter: report everything, then fail once before docker load.
FAILURES=0
preflight_fail() { fail "$*"; FAILURES=$((FAILURES + 1)); }

info "Release installer preflight (release dir: $RELEASE_DIR)"

# ── 1. Platform ──────────────────────────────────────────────────────────────
if [[ "$(uname -s)" == "Linux" ]]; then
  ok "Linux host ($(uname -r))"
else
  preflight_fail "Linux required (got $(uname -s)); /etc/machine-id fingerprint is Linux-only"
fi

# ── 2. Docker + compose v2 ───────────────────────────────────────────────────
if ! command -v docker >/dev/null 2>&1; then
  preflight_fail "docker not found in PATH"
elif ! docker info >/dev/null 2>&1; then
  preflight_fail "docker daemon not reachable (is it running?)"
else
  DOCKER_VER="$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 0)"
  if (( ${DOCKER_VER%%.*} >= 20 )); then
    ok "docker $DOCKER_VER"
  else
    preflight_fail "docker >= 20 required (server reports $DOCKER_VER)"
  fi
  if docker compose version >/dev/null 2>&1; then
    ok "docker compose v2 ($(docker compose version --short 2>/dev/null || echo 'n/a'))"
  else
    preflight_fail "docker compose v2 plugin not available ('docker compose version' failed)"
  fi
fi

# ── 3. CPU / memory / disk ───────────────────────────────────────────────────
CPU_CORES="$(nproc 2>/dev/null || echo 0)"
if (( CPU_CORES >= MIN_CPU_CORES )); then
  ok "CPU: ${CPU_CORES} cores (>= ${MIN_CPU_CORES})"
else
  preflight_fail "CPU: ${CPU_CORES} cores < required ${MIN_CPU_CORES} (override: MIN_CPU_CORES)"
fi

MEM_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
MEM_GB=$(( MEM_KB / 1024 / 1024 ))
if (( MEM_GB >= MIN_MEM_GB )); then
  ok "Memory: ~${MEM_GB} GB (>= ${MIN_MEM_GB})"
else
  preflight_fail "Memory: ~${MEM_GB} GB < required ${MIN_MEM_GB} (override: MIN_MEM_GB)"
fi

DISK_AVAIL_GB="$(df -BG "$RELEASE_DIR" 2>/dev/null | awk 'NR==2 {gsub(/G/,"",$4); print $4+0}')"
if (( DISK_AVAIL_GB >= MIN_DISK_GB )); then
  ok "Disk: ${DISK_AVAIL_GB}G available under $RELEASE_DIR (>= ${MIN_DISK_GB})"
else
  preflight_fail "Disk: ${DISK_AVAIL_GB}G available < required ${MIN_DISK_GB}G (override: MIN_DISK_GB)"
fi

# ── 4. Offline payload present ───────────────────────────────────────────────
if [[ -n "$IMAGES_TAR" ]]; then
  ok "images archive: $IMAGES_TAR ($(du -h "$IMAGES_TAR" | cut -f1))"
else
  preflight_fail "images.tar.gz not found (expected next to release/ or inside it)"
fi

# ── 5. .env.release exists (create from template once) + secrets non-template ─
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f ".env.release.example" ]]; then
    cp .env.release.example "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    die "$ENV_FILE was created from the template — fill every CHANGE_ME_* value (and set RELEASE_VERSION to the package version), then re-run this installer"
  else
    preflight_fail ".env.release missing and no .env.release.example to copy"
  fi
fi

require_value() {
  if [[ -z "$(value_of "$1")" ]]; then
    preflight_fail "missing required key in $ENV_FILE: $1"
  fi
}
require_secret() {
  local value
  value="$(value_of "$1")"
  # Template/placeholder patterns copied from scripts/check-env.sh require_secret.
  case "$value" in
    ""|CHANGE_ME_*|your-*|generate-*|default-secret-change-in-production)
      preflight_fail "invalid (template) secret in $ENV_FILE: $1"
      ;;
  esac
}
require_enabled_pair() { # enabled_key username_key password_key
  if [[ "$(value_of "$1")" == "true" ]]; then
    require_value "$2"
    require_secret "$3"
  fi
}

require_value RELEASE_VERSION
require_value HTTP_PORT
require_value HTTPS_PORT
require_value SMARTLIVESTOCK_LICENSE_MODE
require_value SMARTLIVESTOCK_PILOT_LICENSE_ENABLED
require_value DATAGEN_ENABLED
require_value TELEMETRY_SIMULATOR_ENABLED
require_secret POSTGRES_PASSWORD
require_secret JWT_SECRET
require_secret SMART_LIVESTOCK_TILE_WORKER_KEY
require_enabled_pair AGENTIC_PLATFORM_OAUTH2_ENABLED AGENTIC_PLATFORM_OAUTH2_CLIENT_ID AGENTIC_PLATFORM_OAUTH2_CLIENT_SECRET
require_enabled_pair SMARTLIVESTOCK_TB_ENABLED SMARTLIVESTOCK_TB_USERNAME SMARTLIVESTOCK_TB_PASSWORD
require_enabled_pair SMARTLIVESTOCK_NS_ENABLED SMARTLIVESTOCK_NS_USERNAME SMARTLIVESTOCK_NS_PASSWORD

LICENSE_MODE="$(value_of SMARTLIVESTOCK_LICENSE_MODE)"
case "$LICENSE_MODE" in
  HOSTED|ONPREM) ok "license mode: $LICENSE_MODE" ;;
  *) preflight_fail "SMARTLIVESTOCK_LICENSE_MODE must be HOSTED or ONPREM (got '$LICENSE_MODE')" ;;
esac
if [[ "$LICENSE_MODE" == "ONPREM" && "$(value_of SMARTLIVESTOCK_PILOT_LICENSE_ENABLED)" == "true" ]]; then
  warn "SMARTLIVESTOCK_PILOT_LICENSE_ENABLED=true is a HOSTED feature — ignored/forbidden under ONPREM"
fi
# Release double guard: both synthetic-data switches must be false in the env
# too (compose hard-codes them to "false" regardless).
for key in DATAGEN_ENABLED TELEMETRY_SIMULATOR_ENABLED; do
  if [[ "$(value_of "$key")" != "false" ]]; then
    preflight_fail "$key must be \"false\" in $ENV_FILE for release"
  fi
done

# Package/image tag consistency: release/RELEASE_VERSION is stamped by
# build-release-package.sh; compose tags every self-built image with
# ${RELEASE_VERSION:-beta}, so a mismatch means "image not found" at up time.
if [[ -f "$RELEASE_DIR/RELEASE_VERSION" ]]; then
  PKG_VERSION="$(tr -d '[:space:]' < "$RELEASE_DIR/RELEASE_VERSION")"
  if [[ "$PKG_VERSION" != "$(value_of RELEASE_VERSION)" ]]; then
    preflight_fail "RELEASE_VERSION in $ENV_FILE ($(value_of RELEASE_VERSION)) does not match package image tag ($PKG_VERSION)"
  else
    ok "image tag matches package: $PKG_VERSION"
  fi
else
  warn "release/RELEASE_VERSION stamp missing — skipping image-tag consistency check"
fi

HTTP_PORT="$(value_of HTTP_PORT)"
HTTPS_PORT="$(value_of HTTPS_PORT)"

# ── 6. Host ports free ───────────────────────────────────────────────────────
port_free() {
  # A successful TCP connect to 127.0.0.1:<port> means something is listening
  # (loopback or wildcard binding) -> occupied. 2s timeout guards odd firewalls.
  ! timeout 2 bash -c "exec 3<>/dev/tcp/127.0.0.1/$1" 2>/dev/null
}
for port in "$HTTP_PORT" "$HTTPS_PORT"; do
  if port_free "$port"; then
    ok "host port $port is free"
  else
    preflight_fail "host port $port already in use (HTTP_PORT/HTTPS_PORT)"
  fi
done

# ── 7. TLS certs present and not expired ─────────────────────────────────────
if [[ -f secrets/certs/fullchain.pem && -f secrets/certs/privkey.pem ]]; then
  if CERT_END="$(openssl x509 -enddate -noout -in secrets/certs/fullchain.pem 2>/dev/null | cut -d= -f2)"; then
    CERT_END_EPOCH="$(date -d "$CERT_END" +%s 2>/dev/null || echo 0)"
    if (( CERT_END_EPOCH > $(date +%s) )); then
      ok "TLS certificate valid until: $CERT_END"
    else
      preflight_fail "TLS certificate expired at $CERT_END (secrets/certs/fullchain.pem)"
    fi
  else
    preflight_fail "cannot read secrets/certs/fullchain.pem (not a valid certificate?)"
  fi
else
  preflight_fail "TLS certificates missing: secrets/certs/{fullchain.pem,privkey.pem}"
fi

# ── Preflight gate: nothing touches docker state until everything passed ─────
if (( FAILURES > 0 )); then
  die "preflight failed with $FAILURES issue(s) — fix and re-run"
fi
info "Preflight passed ($FAILURES issues)."

# ── 8. Load offline images ───────────────────────────────────────────────────
info "Loading images (docker load — this can take a few minutes)..."
docker load -i "$IMAGES_TAR"

# ── 9. Start the stack ───────────────────────────────────────────────────────
info "Starting release stack (docker compose up -d)..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

# ── 10. Wait for /health == 200 ──────────────────────────────────────────────
health_code() {
  if command -v curl >/dev/null 2>&1; then
    # -w emits 000 even on failure, so only swallow the exit code (a bare
    # `|| echo 000` would concatenate a second 000).
    curl -k -s --connect-timeout 3 -o /dev/null -w '%{http_code}' "https://localhost:${HTTPS_PORT}/health" || true
  elif command -v wget >/dev/null 2>&1; then
    # wget has no http-code flag in busybox/GNU minimal installs; 0 == 2xx.
    if wget --no-check-certificate -q -T 5 -O /dev/null "https://localhost:${HTTPS_PORT}/health"; then echo 200; else echo 000; fi
  else
    die "neither curl nor wget available for the health probe"
  fi
}
info "Waiting for https://localhost:${HTTPS_PORT}/health to return 200 (timeout ${HEALTH_TIMEOUT_SECS}s)..."
DEADLINE=$(( SECONDS + HEALTH_TIMEOUT_SECS ))
while (( SECONDS < DEADLINE )); do
  CODE="$(health_code)"
  if [[ "$CODE" == "200" ]]; then
    ok "/health returned 200"
    break
  fi
  printf '.'
  sleep 5
done
if [[ "${CODE:-000}" != "200" ]]; then
  info "Last 50 compose log lines for triage:"
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs --tail 50 app || true
  die "health check did not return 200 within ${HEALTH_TIMEOUT_SECS}s"
fi

HOSTNAME_HINT="$(hostname -f 2>/dev/null || hostname)"
info "Install complete."
ok "version : $(value_of RELEASE_VERSION) (images smart-livestock/<svc>:$(value_of RELEASE_VERSION))"
ok "entry   : https://${HOSTNAME_HINT}:${HTTPS_PORT}/"
info "Next: run ./scripts/check-release-health.sh for the full health report."
