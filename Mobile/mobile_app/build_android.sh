#!/usr/bin/env bash
# Build a release APK connected to a specific backend environment.
#
# Usage:
#   ./build_android.sh test   # test  env -> https://ah.hkttech.cn/api/v1 (public HTTPS reverse proxy)
#   ./build_android.sh dev    # dev   env -> http://172.22.1.123:19080/api/v1 (LAN only)
#
# Output: build/app/outputs/flutter-apk/app-release.apk
set -euo pipefail
cd "$(dirname "$0")"

# --- Sync version with backend (smart-livestock-server) ---
# majorVersion: from build.gradle "def majorVersion = ... ?: 'X.Y.Z'"
# buildNumber:  from build.number file (auto-incremented by backend bootJar)
SERVER_DIR="../../smart-livestock-server"
BUILD_NUMBER_FILE="${SERVER_DIR}/build.number"
BUILD_GRADLE="${SERVER_DIR}/build.gradle"

if [ ! -f "$BUILD_NUMBER_FILE" ] || [ ! -f "$BUILD_GRADLE" ]; then
  echo "ERROR: Cannot find backend version files at $SERVER_DIR"; exit 1
fi

BUILD_NUMBER=$(cat "$BUILD_NUMBER_FILE" | tr -d '[:space:]')
MAJOR_VERSION=$(grep "def majorVersion" "$BUILD_GRADLE" | sed "s/.*?: *'//; s/'.*//")
APP_VERSION="${MAJOR_VERSION}-b${BUILD_NUMBER}"

ENV="${1:-test}"
case "$ENV" in
  test) API_BASE_URL="https://ah.hkttech.cn/api/v1" ;;
  dev)  API_BASE_URL="http://172.22.1.123:19080/api/v1" ;;
  *)    echo "Unknown env: $ENV (expected: test | dev)"; exit 1 ;;
esac

echo "==> Building release APK v${APP_VERSION} ($ENV env, $API_BASE_URL)"

flutter build apk --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --build-name="$MAJOR_VERSION" \
  --build-number="$BUILD_NUMBER"

APK="build/app/outputs/flutter-apk/app-release.apk"
OUT="build/app/outputs/flutter-apk/hkt-smartlivestock-${APP_VERSION}.apk"
cp "$APK" "$OUT"
echo "==> Done: $OUT"
ls -lh "$OUT"
