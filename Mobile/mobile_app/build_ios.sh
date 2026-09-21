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
# Output: build/ios/ipa/hkt-livestock-agentic-*.ipa
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
  test) API_BASE_URL="https://livestock.hkttech.cn/api/v1" ;;
  dev)  API_BASE_URL="http://172.22.1.123:19080/api/v1" ;;
  *)    echo "Unknown env: $ENV (expected: test | dev)"; exit 1 ;;
esac

echo "==> Building release IPA v${APP_VERSION} ($ENV env, $API_BASE_URL)"

# Check signing identity
# Default team = free personal team of sales@hktlora.com (zhiyong wu)
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-J62PU4Y357}"

echo "==> Team: $DEVELOPMENT_TEAM"

# Install CocoaPods deps if needed
if [ ! -d "ios/Pods" ]; then
  echo "==> Installing CocoaPods dependencies..."
  cd ios && pod install --repo-update && cd ..
fi

flutter build ipa --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=APP_VERSION="$APP_VERSION" \
  --build-name="$MAJOR_VERSION" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist=ios/ExportOptions.plist

# Rename IPA
# Flutter names the export after the app display name (e.g. "Livestock
# Agent.ipa") and has used both snake/kebab names in the past — so pick the
# NEWEST non-versioned IPA instead of any fixed name; a leftover from an
# earlier naming era must never win.
SRC_IPA=$(ls -t build/ios/ipa/*.ipa 2>/dev/null \
          | grep -vE 'hkt-livestock-agentic-[0-9]|hkt-smartlivestock-[0-9]' \
          | head -1 || true)
if [ -z "$SRC_IPA" ]; then
  echo "ERROR: flutter build produced no IPA under build/ios/ipa/"; exit 1
fi
echo "==> Source IPA: $SRC_IPA ($(stat -f '%Sm' "$SRC_IPA"))"
OUT_IPA="build/ios/ipa/hkt-livestock-agentic-${APP_VERSION}.ipa"
cp "$SRC_IPA" "$OUT_IPA"
echo "==> Done: $OUT_IPA"
ls -lh "$OUT_IPA"
