#!/usr/bin/env bash
# =============================================================================
# check-release-health.sh — full health report for the release stack
#
# Purpose : PASS/FAIL report over the release contract (design §14):
#             1. https /health == 200 (local, -k)
#             2. docker compose ps: all 9 services running, healthchecks green
#             3. postgres pg_isready
#             4. redis PING
#             5. rocketmq namesrv (+broker) TCP reachable
#             6. latest Flyway migration marked success in DB
#             7. no host port mapping on internal services
#             8. TLS certificate > 30 days of remaining validity
#             9. DATAGEN_ENABLED / TELEMETRY_SIMULATOR_ENABLED == false
# Usage   : ./scripts/check-release-health.sh
#           Run from the installed release/ directory (next to
#           docker-compose.release.yml + .env.release).
# Runs on : Target Linux host (or any host with docker + access to the stack).
# Design  : docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md (§14)
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$RELEASE_DIR"

ENV_FILE=".env.release"
COMPOSE_FILE="docker-compose.release.yml"
[[ -f "$ENV_FILE" ]] || { fail "$ENV_FILE not found in $RELEASE_DIR"; exit 1; }
[[ -f "$COMPOSE_FILE" ]] || { fail "$COMPOSE_FILE not found in $RELEASE_DIR"; exit 1; }

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

compose() { docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"; }

HTTPS_PORT="$(value_of HTTPS_PORT)"; HTTPS_PORT="${HTTPS_PORT:-443}"
DB_NAME="$(value_of DB_NAME)"; DB_NAME="${DB_NAME:-smart_livestock}"
DB_USER="$(value_of DB_USER)"; DB_USER="${DB_USER:-postgres}"

PASS_COUNT=0
FAIL_COUNT=0
pass() { ok "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
bad()  { fail "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

info "Release health check ($(date '+%F %T %Z'))"

# ── 1. /health over local HTTPS ──────────────────────────────────────────────
if command -v curl >/dev/null 2>&1; then
  # -w emits 000 even on failure; only swallow the exit code.
  CODE="$(curl -k -s --connect-timeout 3 -o /dev/null -w '%{http_code}' "https://localhost:${HTTPS_PORT}/health" || true)"
else
  if wget --no-check-certificate -q -T 5 -O /dev/null "https://localhost:${HTTPS_PORT}/health" 2>/dev/null; then CODE=200; else CODE=000; fi
fi
if [[ "$CODE" == "200" ]]; then
  pass "GET /health -> 200"
else
  bad "GET /health -> ${CODE} (expected 200)"
fi

# ── 2. compose ps: all services running with green healthchecks ──────────────
SERVICES=(nginx app postgres redis rocketmq-namesrv rocketmq-broker ai-platform tileserver tile-worker)
for svc in "${SERVICES[@]}"; do
  cid="$(compose ps -q "$svc" 2>/dev/null || true)"
  if [[ -z "$cid" ]]; then
    bad "service not running: $svc"
    continue
  fi
  state="$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null || echo unknown)"
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cid" 2>/dev/null || echo unknown)"
  if [[ "$state" == "running" && "$health" =~ ^(healthy|none)$ ]]; then
    pass "service $svc: $state (health: $health)"
  else
    bad "service $svc: state=$state health=$health"
  fi
done

# ── 3. PostgreSQL ────────────────────────────────────────────────────────────
if compose exec -T postgres pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
  pass "postgres pg_isready ($DB_NAME)"
else
  bad "postgres pg_isready failed"
fi

# ── 4. Redis ─────────────────────────────────────────────────────────────────
if [[ "$(compose exec -T redis redis-cli ping 2>/dev/null | tr -d '[:space:]')" == "PONG" ]]; then
  pass "redis PING -> PONG"
else
  bad "redis PING failed"
fi

# ── 5. RocketMQ namesrv (+ broker listen port) via bash /dev/tcp ─────────────
if compose exec -T rocketmq-namesrv bash -c 'echo > /dev/tcp/localhost/9876' >/dev/null 2>&1; then
  pass "rocketmq-namesrv reachable on 9876"
else
  bad "rocketmq-namesrv 9876 unreachable"
fi
if compose exec -T rocketmq-broker bash -c 'echo > /dev/tcp/localhost/10911' >/dev/null 2>&1; then
  pass "rocketmq-broker reachable on 10911"
else
  bad "rocketmq-broker 10911 unreachable"
fi

# ── 6. Latest Flyway migration succeeded ─────────────────────────────────────
FLYWAY_LAST="$(compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -tAc \
  "select success from flyway_schema_history order by installed_rank desc limit 1" 2>/dev/null | tr -d '[:space:]')"
if [[ "$FLYWAY_LAST" == "t" ]]; then
  pass "latest Flyway migration succeeded"
else
  bad "latest Flyway migration not successful (got '$FLYWAY_LAST'; empty = no migrations ran)"
fi

# ── 7. No host port mapping on internal services ─────────────────────────────
# Primary probe per design: `docker compose port <svc> <port>` must print
# nothing when the service is internal-only. Cross-checked against the
# container's HostConfig.PortBindings (authoritative, empty bindings expected).
INTERNAL_PORTS=(
  postgres:5432 redis:6379
  rocketmq-namesrv:9876 rocketmq-broker:10911
  tileserver:8080 ai-platform:8000 app:8080 tile-worker:8080
)
for entry in "${INTERNAL_PORTS[@]}"; do
  svc="${entry%%:*}"; port="${entry##*:}"
  cid="$(compose ps -q "$svc" 2>/dev/null || true)"
  if [[ -z "$cid" ]]; then
    bad "$svc container not found (is the stack up?)"
    continue
  fi
  # `docker compose port` output varies across versions for unpublished ports
  # (v5.5.1 prints "invalid IP:0" on stdout), so the authoritative check is
  # HostConfig.PortBindings: internal-only services must have none.
  bindings="$(docker inspect -f '{{json .HostConfig.PortBindings}}' "$cid" 2>/dev/null || echo '{}')"
  published="$(compose port "$svc" "$port" 2>/dev/null || true)"
  if [[ "$bindings" == *HostPort* ]]; then
    bad "$svc has a host port mapping (PortBindings: $bindings)"
  elif [[ "$published" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    bad "$svc has a host port mapping: $published"
  else
    pass "$svc has no host port mapping (internal-only)"
  fi
done

# ── 8. TLS certificate > 30 days remaining ───────────────────────────────────
CERT_MIN_DAYS=30
if [[ -f secrets/certs/fullchain.pem ]] \
  && CERT_END="$(openssl x509 -enddate -noout -in secrets/certs/fullchain.pem 2>/dev/null | cut -d= -f2)"; then
  CERT_END_EPOCH="$(date -d "$CERT_END" +%s 2>/dev/null || echo 0)"
  CERT_DAYS_LEFT=$(( (CERT_END_EPOCH - $(date +%s)) / 86400 ))
  if (( CERT_DAYS_LEFT > CERT_MIN_DAYS )); then
    pass "TLS certificate valid for ${CERT_DAYS_LEFT} more days (until $CERT_END)"
  else
    bad "TLS certificate expires in ${CERT_DAYS_LEFT} day(s) (<= $CERT_MIN_DAYS): $CERT_END — renew now"
  fi
else
  bad "cannot read/expiry-parse secrets/certs/fullchain.pem"
fi

# ── 9. Synthetic-data switches stay off in .env.release ──────────────────────
for key in DATAGEN_ENABLED TELEMETRY_SIMULATOR_ENABLED; do
  if [[ "$(value_of "$key")" == "false" ]]; then
    pass "$key=false in $ENV_FILE"
  else
    bad "$key must be \"false\" in $ENV_FILE (release contract)"
  fi
done

# ── Summary ──────────────────────────────────────────────────────────────────
info "Result: $PASS_COUNT passed, $FAIL_COUNT failed."
if (( FAIL_COUNT > 0 )); then
  fail "HEALTH CHECK FAILED"
  exit 1
fi
info "HEALTH CHECK PASSED"
