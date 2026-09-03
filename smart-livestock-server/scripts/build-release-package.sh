#!/usr/bin/env bash
# =============================================================================
# build-release-package.sh — build the offline market-beta release package
#
# Purpose : One-shot builder for the single-host offline release bundle
#           (NIX-184 T8b, design §13):
#             bootJar -> (optional) Flutter web bundle -> five self-built
#             images -> pull three pinned third-party images -> docker save
#             | gzip -> images.tar.gz -> assemble release/ (compose, env
#             template, ops scripts, guides) -> SHA256SUMS -> single tar.gz.
# Usage   : scripts/build-release-package.sh [--version <v>] [--skip-web] [--out <dir>]
#           --version <v>  tag for all self-built images AND the package's
#                          RELEASE_VERSION (default: value of build.number,
#                          e.g. "540" -> package smart-livestock-market-beta-540).
#                          Must stay in sync with RELEASE_VERSION in .env.release
#                          on the install host (installer hard-fails on mismatch).
#           --skip-web     reuse existing smart-livestock-server/frontend/
#                          instead of rebuilding the Flutter web bundle.
#           --out <dir>    directory for the final tar.gz (default: build/release).
# Runs on : Build machine only (JDK17 + Flutter + docker daemon required).
#           Never shipped inside the package (only the five install/ops
#           scripts are copied into release/scripts/).
# Design  : docs/superpowers/specs/2026-08-31-market-beta-release-readiness-implementation-design.md (§13)
# =============================================================================
set -euo pipefail

# ── Output helpers (same convention as scripts/deploy.sh) ────────────────────
if [[ -t 1 ]]; then
  C_INFO=$'\033[1;34m'; C_OK=$'\033[0;32m'; C_WARN=$'\033[0;33m'; C_ERR=$'\033[0;31m'; C_OFF=$'\033[0m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_OFF=''
fi
info() { printf '%s==> %s%s\n'  "$C_INFO" "$*" "$C_OFF"; }
ok()   { printf '%s    [OK] %s%s\n' "$C_OK" "$*" "$C_OFF"; }
warn() { printf '%s [WARN] %s%s\n' "$C_WARN" "$*" "$C_OFF"; }
die()  { printf '%s [FAIL] %s%s\n' "$C_ERR" "$*" "$C_OFF" >&2; exit 1; }

usage() {
  sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ── Self-locate: runnable from repo root, smart-livestock-server/, or anywhere ─
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SERVER_DIR/.." && pwd)"

VERSION=""
SKIP_WEB=0
OUT_DIR=""
while (($#)); do
  case "$1" in
    --version)  VERSION="${2:?--version requires a value}"; shift 2 ;;
    --skip-web) SKIP_WEB=1; shift ;;
    --out)      OUT_DIR="${2:?--out requires a value}"; shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    *)          die "unknown argument: $1 (see --help)" ;;
  esac
done

# Default version = build.number (docker tag must match RELEASE_VERSION in env).
if [[ -z "$VERSION" ]]; then
  [[ -f "$SERVER_DIR/build.number" ]] || die "build.number not found and no --version given"
  VERSION="$(tr -d '[:space:]' < "$SERVER_DIR/build.number")"
fi
[[ "$VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "invalid version/tag: '$VERSION'"

OUT_DIR="${OUT_DIR:-$SERVER_DIR/build/release}"
PKG_NAME="smart-livestock-market-beta-${VERSION}"
PKG="$OUT_DIR/$PKG_NAME"
mkdir -p "$OUT_DIR"

command -v docker >/dev/null 2>&1 || die "docker not found in PATH"
[[ -x "$SERVER_DIR/gradlew" ]] || die "gradlew not found/executable under $SERVER_DIR"

if [[ "$SKIP_WEB" -eq 1 ]]; then
  [[ -d "$SERVER_DIR/frontend" ]] || die "--skip-web given but $SERVER_DIR/frontend does not exist yet"
else
  command -v flutter >/dev/null 2>&1 || die "flutter not found in PATH (or use --skip-web)"
fi

cd "$SERVER_DIR"

info "Release package: $PKG_NAME (image tag: $VERSION)"

# ── [1/8] Backend JAR ────────────────────────────────────────────────────────
info "[1/8] Building backend JAR (./gradlew bootJar -x test)..."
./gradlew bootJar -x test
ls build/libs/smart-livestock-server-*.jar >/dev/null 2>&1 || die "bootJar produced no smart-livestock-server-*.jar"

# ── [2/8] Flutter web bundle ─────────────────────────────────────────────────
if [[ "$SKIP_WEB" -eq 1 ]]; then
  warn "[2/8] Skipping Flutter web build (--skip-web): reusing existing frontend/"
else
  info "[2/8] Building Flutter web bundle (Mobile/mobile_app/build_web.sh)..."
  WEB_SCRIPT="$REPO_ROOT/Mobile/mobile_app/build_web.sh"
  [[ -f "$WEB_SCRIPT" ]] || die "build_web.sh not found: $WEB_SCRIPT"
  bash "$WEB_SCRIPT"
  [[ -f "$SERVER_DIR/frontend/index.html" ]] || die "frontend/index.html missing after build_web.sh"
fi

# ── [3/8] Self-built images ──────────────────────────────────────────────────
info "[3/8] Building five self-built images (tag smart-livestock/<svc>:$VERSION)..."
info "      app (context: smart-livestock-server root, Dockerfile)"
docker build -t "smart-livestock/app:$VERSION" "$SERVER_DIR"
info "      nginx (infrastructure/nginx/Dockerfile.release — bakes frontend/ + nginx.release.conf)"
docker build -f infrastructure/nginx/Dockerfile.release -t "smart-livestock/nginx:$VERSION" "$SERVER_DIR"
info "      postgres (infrastructure/postgres/ — hardened pg_hba.conf, see compose header)"
docker build -t "smart-livestock/postgres:$VERSION" infrastructure/postgres/
info "      ai-platform (ai-platform/)"
docker build -t "smart-livestock/ai-platform:$VERSION" ai-platform/
info "      tile-worker (infrastructure/tile-worker/)"
docker build -t "smart-livestock/tile-worker:$VERSION" infrastructure/tile-worker/

# ── [4/8] Pinned third-party images ──────────────────────────────────────────
info "[4/8] Pulling pinned third-party images..."
PINS=(redis:7-alpine apache/rocketmq:5.1.0 maptiler/tileserver-gl:latest)
for img in "${PINS[@]}"; do
  docker pull "$img"
done

# ── [5/8] docker save | gzip ─────────────────────────────────────────────────
info "[5/8] Saving images -> images.tar.gz (9 services / 8 unique images:"
info "      apache/rocketmq:5.1.0 is shared by rocketmq-namesrv + rocketmq-broker)..."
rm -rf "$PKG"
mkdir -p "$PKG/release/scripts" "$PKG/release/docs" "$PKG/release/infrastructure/nginx"
IMAGES=(
  "smart-livestock/app:$VERSION"
  "smart-livestock/nginx:$VERSION"
  "smart-livestock/postgres:$VERSION"
  "smart-livestock/ai-platform:$VERSION"
  "smart-livestock/tile-worker:$VERSION"
  "redis:7-alpine"
  "apache/rocketmq:5.1.0"
  "maptiler/tileserver-gl:latest"
)
docker save "${IMAGES[@]}" | gzip > "$PKG/images.tar.gz"
[[ -s "$PKG/images.tar.gz" ]] || die "images.tar.gz is empty"

# ── [6/8] Assemble release/ ──────────────────────────────────────────────────
info "[6/8] Assembling release/ content..."
cp docker-compose.release.yml "$PKG/release/"
cp .env.release.example "$PKG/release/"
cp infrastructure/nginx/nginx.release.conf "$PKG/release/infrastructure/nginx/"
printf '%s\n' "$VERSION" > "$PKG/release/RELEASE_VERSION"
# The five target-host scripts (build-release-package.sh itself stays out —
# the install host never builds anything).
for s in install-release.sh check-release-health.sh backup-release.sh restore-release.sh verify-release-bundle.sh; do
  cp "$SCRIPT_DIR/$s" "$PKG/release/scripts/"
done
# Operator guides (owned by T9b — warn + continue when not written yet).
for d in release-install-guide.md release-operations-guide.md release-checklist.md; do
  if [[ -f "$REPO_ROOT/docs/guides/$d" ]]; then
    cp "$REPO_ROOT/docs/guides/$d" "$PKG/release/docs/"
  else
    warn "docs/guides/$d not found — packaged without it (T9b pending?)"
  fi
done

# ── [7/8] SHA256SUMS ─────────────────────────────────────────────────────────
info "[7/8] Generating SHA256SUMS (images.tar.gz + every file under release/)..."
# NOTE: xargs cannot invoke shell functions, so branch on the tool instead.
(
  cd "$PKG"
  if command -v sha256sum >/dev/null 2>&1; then
    find images.tar.gz release -type f ! -name '._*' -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 sha256sum
  else
    find images.tar.gz release -type f ! -name '._*' -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 shasum -a 256
  fi
) > "$PKG/SHA256SUMS"
[[ -s "$PKG/SHA256SUMS" ]] || die "SHA256SUMS generation failed"

# ── [8/8] Final tar.gz ───────────────────────────────────────────────────────
info "[8/8] Packing $PKG_NAME.tar.gz..."
# COPYFILE_DISABLE=1 + --exclude: keep macOS AppleDouble (._*) / .DS_Store
# pollution out of the artifact (see AGENTS.md env-layer lessons).
COPYFILE_DISABLE=1 tar -czf "$OUT_DIR/$PKG_NAME.tar.gz" \
  --exclude='._*' --exclude='.DS_Store' \
  -C "$OUT_DIR" "$PKG_NAME"

info "Done."
ok "package : $OUT_DIR/$PKG_NAME.tar.gz ($(du -h "$OUT_DIR/$PKG_NAME.tar.gz" | cut -f1))"
ok "version : $VERSION (images smart-livestock/<svc>:$VERSION)"
info "Next steps:"
info "  1. scp $OUT_DIR/$PKG_NAME.tar.gz to the target Linux host"
info "  2. tar xzf $PKG_NAME.tar.gz && cd $PKG_NAME"
info "  3. ./release/scripts/verify-release-bundle.sh ."
info "  4. cd release && ./scripts/install-release.sh"
