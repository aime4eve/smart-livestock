#!/usr/bin/env bash
# Build a release IPA connected to a specific backend environment.
#
# Prerequisites:
#   1. Apple Developer account (free Apple ID works for personal device testing)
#   2. Valid signing identity installed (check: security find-identity -v -p codesigning)
#   3. DEVELOPMENT_TEAM set via env or Xcode
#
# Usage:
#   DEVELOPMENT_TEAM=ABCD1234 ./build_ios.sh test   # test  env
#   DEVELOPMENT_TEAM=ABCD1234 ./build_ios.sh dev    # dev   env
#
# Output: build/ios/ipa/hkt-smartlivestock-*.ipa
set -euo pipefail
cd "$(dirname "$0")"

# --- Sync version with backend (smart-livestock-server) ---
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

echo "==> Building release IPA v${APP_VERSION} ($ENV env, $API_BASE_URL)"

# Check signing identity
if [ -z "${DEVELOPMENT_TEAM:-}" ]; then
  echo "ERROR: DEVELOPMENT_TEAM env var not set."
  echo "  Find your Team ID at: https://developer.apple.com/account -> Membership"
  echo "  Usage: DEVELOPMENT_TEAM=ABCD1234 ./build_ios.sh test"
  exit 1
fi

echo "==> Team: $DEVELOPMENT_TEAM"

# Install CocoaPods deps if needed
if [ ! -d "ios/Pods" ]; then
  echo "==> Installing CocoaPods dependencies..."
  cd ios && pod install --repo-update && cd ..
fi

flutter build ipa --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --build-name="$MAJOR_VERSION" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist=ios/ExportOptions.plist

# Rename IPA
SRC_IPA="build/ios/ipa/hkt_livestock_agentic.ipa"
if [ ! -f "$SRC_IPA" ]; then
  # Flutter may name it differently
  SRC_IPA=$(find build/ios/ipa -name "*.ipa" | head -1)
fi
OUT_IPA="build/ios/ipa/hkt-smartlivestock-${APP_VERSION}.ipa"
cp "$SRC_IPA" "$OUT_IPA"
echo "==> Done: $OUT_IPA"
ls -lh "$OUT_IPA"
