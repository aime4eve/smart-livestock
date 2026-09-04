#!/usr/bin/env bash
# =============================================================================
# backup-release.sh — consistent cold backup of the release stack
#
# Purpose : Backs up, into backups/release-<timestamp>/:
#             - PostgreSQL  : pg_dump of the app database (db/<db>.sql)
#             - Volumes     : tileserver-data + behavior-models (tar.gz via a
#                             read-only volume mount into a temporary container)
#             - Config      : .env.release + secrets/certs/ (TLS material)
#             - SHA256SUMS  : over everything above
# Usage   : ./scripts/backup-release.sh
#           Run from the installed release/ directory. Override the backup
#           destination with BACKUP_ROOT=/path (default: <release>/backups).
# Runs on : Target Linux host.
# Design  : docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md (§14)
# Note    : pg_dump runs against a live database (logical backup). For a fully
#           crash-consistent snapshot, run this while the app is stopped or
#           accept WAL-less logical semantics as documented in the ops guide.
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

DB_NAME="$(value_of DB_NAME)"; DB_NAME="${DB_NAME:-smart_livestock}"
DB_USER="$(value_of DB_USER)"; DB_USER="${DB_USER:-postgres}"
PG_IMAGE="smart-livestock/postgres:$(value_of RELEASE_VERSION)"  # self-built image ships tar(1)

command -v docker >/dev/null 2>&1 || die "docker not found in PATH"
docker info >/dev/null 2>&1 || die "docker daemon not reachable"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${BACKUP_ROOT:-$RELEASE_DIR/backups}"
BACKUP_DIR="$BACKUP_ROOT/release-$TS"
mkdir -p "$BACKUP_DIR/db" "$BACKUP_DIR/volumes" "$BACKUP_DIR/config"
# Absolute path for docker -v mounts (works when invoked from anywhere).
BACKUP_DIR_ABS="$(cd "$BACKUP_DIR" && pwd)"

info "Backing up to $BACKUP_DIR"

# ── 1. PostgreSQL logical dump ───────────────────────────────────────────────
info "[1/4] pg_dump $DB_NAME -> db/${DB_NAME}.sql"
compose exec -T postgres pg_dump -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_DIR/db/${DB_NAME}.sql"
[[ -s "$BACKUP_DIR/db/${DB_NAME}.sql" ]] || die "pg_dump produced an empty file"
ok "dump size: $(du -h "$BACKUP_DIR/db/${DB_NAME}.sql" | cut -f1)"

# ── 2. Named volumes (read-only mount -> tar in a throwaway container) ───────
# Resolve the *actual* volume name via the running container's mounts so this
# survives compose project renames (name is <project>_<volume>).
volume_of() { # <svc> <container_path> -> volume name
  local cid
  cid="$(compose ps -q "$1")"
  [[ -n "$cid" ]] || die "service $1 is not running — start the stack before backing up"
  docker inspect -f "{{range .Mounts}}{{if eq .Destination \"$2\"}}{{.Name}}{{end}}{{end}}" "$cid"
}
tar_volume() { # <volume-name> <output-file.tar.gz>
  docker run --rm \
    -v "$1":/data:ro \
    -v "$BACKUP_DIR_ABS/volumes":/backup \
    "$PG_IMAGE" tar czf "/backup/$2" -C /data .
}
for spec in "tileserver:tileserver-data" "ai-platform:behavior-models"; do
  svc="${spec%%:*}"; vol_key="${spec##*:}"
  VOL="$(volume_of "$svc" "/data")"
  [[ -n "$VOL" ]] || die "cannot resolve volume for $svc mount /data (expected $vol_key)"
  info "      tarring volume $VOL -> volumes/${vol_key}.tar.gz"
  tar_volume "$VOL" "${vol_key}.tar.gz"
  [[ -s "$BACKUP_DIR/volumes/${vol_key}.tar.gz" ]] || die "volume archive empty: ${vol_key}.tar.gz"
done
# pgdata is NOT archived as a volume tar: the logical dump in db/ is the
# restore source (restoring a raw pgdata volume across postgres versions is
# unsupported; the self-built postgres image may move between 16.x minors).

# ── 3. Config + TLS material ─────────────────────────────────────────────────
info "[3/4] Copying $ENV_FILE and secrets/certs/ ..."
cp "$ENV_FILE" "$BACKUP_DIR/config/"
if [[ -d secrets/certs ]]; then
  cp -a secrets/certs "$BACKUP_DIR/config/certs"
else
  warn "secrets/certs not found — backup proceeds without TLS material"
fi
# Backup contains a DB password and the TLS private key: lock it to root/owner.
chmod -R go-rwx "$BACKUP_DIR" 2>/dev/null || true  # volume tars may be root-owned

# ── 4. SHA256SUMS ────────────────────────────────────────────────────────────
info "[4/4] Generating SHA256SUMS..."
(
  cd "$BACKUP_DIR"
  if command -v sha256sum >/dev/null 2>&1; then
    find . -type f ! -name '._*' ! -name SHA256SUMS -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
  else
    find . -type f ! -name '._*' ! -name SHA256SUMS -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256
  fi
) > "$BACKUP_DIR/SHA256SUMS"
[[ -s "$BACKUP_DIR/SHA256SUMS" ]] || die "SHA256SUMS generation failed"

info "Backup complete."
ok "location : $BACKUP_DIR"
ok "contents : db/${DB_NAME}.sql, volumes/*.tar.gz, config/{.env.release,certs/}, SHA256SUMS"
info "Restore with: ./scripts/restore-release.sh $BACKUP_DIR"
