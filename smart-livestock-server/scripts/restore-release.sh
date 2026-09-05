#!/usr/bin/env bash
# =============================================================================
# restore-release.sh — restore a backup produced by backup-release.sh
#
# Purpose : Verifies the backup's SHA256SUMS, then:
#             stop app/tile-worker/nginx -> drop+recreate the database and
#             replay pg_dump -> restore tileserver-data + behavior-models
#             volumes from tar -> compose up -d -> run check-release-health.sh
# Usage   : ./scripts/restore-release.sh <backup-dir> [--yes]
#           <backup-dir>  e.g. backups/release-20260903-120000 (must contain
#                         SHA256SUMS, db/*.sql and volumes/*.tar.gz)
#           --yes         skip the interactive RESTORE confirmation
# Runs on : Target Linux host.
# Warning : DESTRUCTIVE — the live database and the two data volumes are
#           replaced. The confirmation prompt requires typing "RESTORE".
# Design  : docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md (§14)
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$RELEASE_DIR"

ENV_FILE=".env.release"
COMPOSE_FILE="docker-compose.release.yml"
[[ -f "$ENV_FILE" ]] || die "$ENV_FILE not found in $RELEASE_DIR"
[[ -f "$COMPOSE_FILE" ]] || die "$COMPOSE_FILE not found in $RELEASE_DIR"

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

# ── Args ─────────────────────────────────────────────────────────────────────
BACKUP_DIR=""
ASSUME_YES=0
while (($#)); do
  case "$1" in
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) BACKUP_DIR="$1"; shift ;;
  esac
done
[[ -n "$BACKUP_DIR" ]] || { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }
[[ -d "$BACKUP_DIR" ]] || die "backup dir not found: $BACKUP_DIR"
BACKUP_DIR_ABS="$(cd "$BACKUP_DIR" && pwd)"

DB_NAME="$(value_of DB_NAME)"; DB_NAME="${DB_NAME:-smart_livestock}"
DB_USER="$(value_of DB_USER)"; DB_USER="${DB_USER:-postgres}"
PG_IMAGE="smart-livestock/postgres:$(value_of RELEASE_VERSION)"

command -v docker >/dev/null 2>&1 || die "docker not found in PATH"
docker info >/dev/null 2>&1 || die "docker daemon not reachable"

# ── 1. Validate + verify backup integrity BEFORE touching anything ──────────
info "[1/5] Verifying backup at $BACKUP_DIR_ABS"
[[ -f "$BACKUP_DIR_ABS/SHA256SUMS" ]] || die "SHA256SUMS missing in backup dir"
DUMP_FILE="$(find "$BACKUP_DIR_ABS/db" -maxdepth 1 -type f -name '*.sql' ! -name '._*' 2>/dev/null | head -1 || true)"
[[ -n "$DUMP_FILE" ]] || die "no db/*.sql dump found in backup dir"
TARS=( "$BACKUP_DIR_ABS"/volumes/*.tar.gz )
[[ -f "${TARS[0]}" ]] || die "no volumes/*.tar.gz found in backup dir"

info "      checking SHA256SUMS..."
SUMS_OK=0
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$BACKUP_DIR_ABS" && sha256sum -c SHA256SUMS >/dev/null 2>&1) && SUMS_OK=1 || true
else
  (cd "$BACKUP_DIR_ABS" && shasum -a 256 -c SHA256SUMS >/dev/null 2>&1) && SUMS_OK=1 || true
fi
if (( ! SUMS_OK )); then
  info "      mismatch details:"
  (cd "$BACKUP_DIR_ABS" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c SHA256SUMS || true; else shasum -a 256 -c SHA256SUMS || true; fi) >&2
  die "backup integrity check FAILED — refusing to restore"
fi
ok "backup integrity verified"

# ── 2. Confirmation ──────────────────────────────────────────────────────────
info "[2/5] Confirming destructive restore"
if (( ! ASSUME_YES )); then
  printf 'This DROPS database "%s" and OVERWRITES tileserver-data + behavior-models.\n' "$DB_NAME"
  printf 'Source backup: %s\n' "$BACKUP_DIR_ABS"
  printf 'Type RESTORE to continue: '
  read -r ANSWER
  [[ "$ANSWER" == "RESTORE" ]] || die "aborted by operator"
fi

# ── 3. Stop stateful-adjacent services (postgres stays up for the replay) ────
info "[3/5] Stopping app / tile-worker / nginx ..."
compose stop app tile-worker nginx

info "      dropping and recreating database $DB_NAME ..."
compose exec -T postgres psql -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DB_NAME' AND pid <> pg_backend_pid();" >/dev/null
compose exec -T postgres psql -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS \"$DB_NAME\";" >/dev/null
compose exec -T postgres psql -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$DB_NAME\";" >/dev/null
info "      replaying $(basename "$DUMP_FILE") ..."
compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -q < "$DUMP_FILE" >/dev/null
ok "database restored"

# ── 4. Restore data volumes ──────────────────────────────────────────────────
info "[4/5] Restoring volumes from tar archives ..."
volume_of() { # <svc> <container_path> -> volume name
  local cid
  cid="$(compose ps -q "$1")"
  [[ -n "$cid" ]] || die "service $1 is not running — cannot resolve volume"
  docker inspect -f "{{range .Mounts}}{{if eq .Destination \"$2\"}}{{.Name}}{{end}}{{end}}" "$cid"
}
for spec in "tileserver:tileserver-data" "ai-platform:behavior-models"; do
  svc="${spec%%:*}"; vol_key="${spec##*:}"
  VOL="$(volume_of "$svc" "/data")"
  [[ -n "$VOL" ]] || die "cannot resolve volume for $svc mount /data (expected $vol_key)"
  TAR_NAME="${vol_key}.tar.gz"
  [[ -f "$BACKUP_DIR_ABS/volumes/$TAR_NAME" ]] || die "missing archive: volumes/$TAR_NAME"
  info "      $TAR_NAME -> volume $VOL"
  docker run --rm \
    -v "$VOL":/data \
    -v "$BACKUP_DIR_ABS/volumes":/backup:ro \
    "$PG_IMAGE" \
    sh -c 'find /data -mindepth 1 -maxdepth 1 -exec rm -rf {} + ; tar xzf "/backup/$1" -C /data' restore_sh "$TAR_NAME"
  ok "volume restored: $VOL"
done

# ── 5. Restart + full health gate ────────────────────────────────────────────
info "[5/5] Starting stack (docker compose up -d) ..."
compose up -d
info "Running check-release-health.sh as the final gate ..."
exec bash "$SCRIPT_DIR/check-release-health.sh"
