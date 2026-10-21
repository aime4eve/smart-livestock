#!/usr/bin/env bash
# BoviScout (Smart Livestock) App Store / TestFlight build:
#   flutter build ipa (archive + app-store-connect export) -> optional upload to ASC
#
# Version source: smart-livestock-server release.number (user-facing single
# source shared with web/APK) + build.gradle majorVersion.
#   Store mapping: ShortVersion=0.6.1 / Build=760 -> TestFlight shows 0.6.1 (760)
#
# Prerequisites:
#   - Apple Developer Program team QQC56X32GR (tech@hktchn.com) logged into
#     Xcode (Settings -> Accounts); upload uses that session, no API key needed
#   - ASC App record exists for com.hktlora.smartlivestock, else upload fails
#     (IDEDistribution...missingApp)
#   - Distribution signing is automatic: Cloud Managed Apple Distribution is
#     created/reused by -allowProvisioningUpdates (private key stays at Apple)
#   - ITSAppUsesNonExemptEncryption=false is set in Info.plist (system TLS
#     only), so ASC does not ask the export-compliance question per build
#
# Usage:
#   ./Tools/build_appstore.sh [test|dev] [--upload] [-s]
#     test|dev    backend environment, default test (public livestock.hkttech.cn)
#     --upload    after export, upload the archive to App Store Connect
#                 (destination=upload; lands in TestFlight, takes minutes to
#                 half an hour to process)
#     -s          skip flutter build + archive, reuse build/ios/archive
set -euo pipefail
cd "$(dirname "$0")/../.."   # mobile_app root

TEAM="QQC56X32GR"
BUNDLE_ID="com.hktlora.smartlivestock"
APP_NAME="BoviScout"   # keep in sync with Info.plist CFBundleDisplayName
SERVER_DIR="../../smart-livestock-server"

DO_UPLOAD=0
SKIP_BUILD=0
ENV="test"
for arg in "$@"; do
  case "$arg" in
    --upload) DO_UPLOAD=1 ;;
    -s|--skip-build) SKIP_BUILD=1 ;;
    test|dev) ENV="$arg" ;;
    *) echo "Unknown arg: $arg (see header comments)" >&2; exit 1 ;;
  esac
done

say() { printf '\n==> %s\n' "$*"; }

# --- version: release.number + majorVersion -> SHORT_VERSION / BUILD_NUMBER ---
RELEASE_NUMBER_FILE="${SERVER_DIR}/release.number"
BUILD_GRADLE="${SERVER_DIR}/build.gradle"
[[ -f "$RELEASE_NUMBER_FILE" && -f "$BUILD_GRADLE" ]] \
  || { echo "ERROR: backend version files not found at $SERVER_DIR" >&2; exit 1; }
BUILD_NUMBER=$(tr -d '[:space:]' < "$RELEASE_NUMBER_FILE")
MAJOR_VERSION=$(grep "def majorVersion" "$BUILD_GRADLE" | sed "s/.*?: *'//; s/'.*//")
if [[ ! "$MAJOR_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
   || [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "ERROR: bad version: major='$MAJOR_VERSION' build='$BUILD_NUMBER'" >&2
  exit 1
fi
APP_VERSION="${MAJOR_VERSION}-b${BUILD_NUMBER}"
say "Store mapping: ${APP_VERSION} -> ShortVersion=${MAJOR_VERSION} / Build=${BUILD_NUMBER}"

case "$ENV" in
  test) API_BASE_URL="https://livestock.hkttech.cn/api/v1" ;;
  dev)  API_BASE_URL="http://172.22.1.123:19080/api/v1" ;;
esac

ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"
LOG="build/ios/appstore_build.log"
mkdir -p build/ios

if [[ "$SKIP_BUILD" -eq 1 && -d "$ARCHIVE_PATH" ]]; then
  say "Skip build/archive, reuse: $ARCHIVE_PATH"
else
  # --- 1. flutter build ipa: archive (auto dev signing) + app-store export ---
  # ExportOptions destination must stay "export" here so flutter keeps the IPA;
  # the upload step below re-exports the same archive with destination=upload.
  PLIST="build/ios/ExportOptions-appstore.plist"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>${TEAM}</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>uploadSymbols</key>
	<true/>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
EOF

  say "flutter build ipa (release, $ENV env, $API_BASE_URL)"
  if ! flutter build ipa --release \
        --dart-define=API_BASE_URL="$API_BASE_URL" \
        --dart-define=APP_VERSION="$APP_VERSION" \
        --build-name="$MAJOR_VERSION" \
        --build-number="$BUILD_NUMBER" \
        --export-options-plist="$PLIST" 2>&1 | tee "$LOG"; then
    echo "flutter build ipa failed, full log: $LOG" >&2
    exit 1
  fi
  # flutter build ipa can exit 0 even when its internal export fails (seen
  # once: "network connection was lost" after a good archive) - the renamed
  # copy in step 3 would then silently pick up a stale IPA from an earlier
  # build. Guard: the fresh display-named IPA must exist and be newer than
  # the archive.
  FRESH_IPA="build/ios/ipa/${APP_NAME}.ipa"
  if [[ ! -f "$FRESH_IPA" || "$FRESH_IPA" -ot "$ARCHIVE_PATH" ]]; then
    echo "ERROR: no fresh export IPA ($FRESH_IPA missing or older than archive)." >&2
    echo "  Re-run export only:" >&2
    echo "  xcodebuild -exportArchive -archivePath $ARCHIVE_PATH -exportPath build/ios/ipa -exportOptionsPlist $PLIST -allowProvisioningUpdates" >&2
    exit 1
  fi
fi

[[ -d "$ARCHIVE_PATH" ]] || { echo "ERROR: archive not found: $ARCHIVE_PATH" >&2; exit 1; }

# --- 2. upload (optional): re-export archive with destination=upload ---
if [[ "$DO_UPLOAD" -eq 1 ]]; then
  say "xcodebuild -exportArchive (app-store-connect, destination=upload)"
  UPLOAD_PLIST="build/ios/ExportOptions-appstore-upload.plist"
  cat > "$UPLOAD_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>${TEAM}</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>destination</key>
	<string>upload</string>
</dict>
</plist>
EOF
  if ! xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "build/ios/appstore-upload" \
        -exportOptionsPlist "$UPLOAD_PLIST" \
        -allowProvisioningUpdates 2>&1 | tee -a "$LOG"; then
    echo "Upload failed (common cause: no ASC App record for $BUNDLE_ID), log: $LOG" >&2
    exit 1
  fi
  say "Submitted to App Store Connect. Processing takes minutes to half an hour;"
  say "then TestFlight shows ${MAJOR_VERSION} (${BUILD_NUMBER})."
  exit 0
fi

# --- 3. local archiving: rename IPA + verify version & signing ---
# flutter names the export after the app display name; the freshness guard
# above makes sure this file came from this run, so no stale-package rename.
SRC_IPA="build/ios/ipa/${APP_NAME}.ipa"
[[ -f "$SRC_IPA" ]] || { echo "ERROR: no IPA at $SRC_IPA" >&2; exit 1; }
OUT_IPA="build/ios/ipa/smart-livestock-${APP_VERSION}-appstore-$(date +%Y%m%d).ipa"
cp -f "$SRC_IPA" "$OUT_IPA"
echo "App Store IPA: $OUT_IPA ($(du -h "$OUT_IPA" | cut -f1))"

rm -rf /tmp/la_as_check && mkdir -p /tmp/la_as_check
unzip -q "$OUT_IPA" -d /tmp/la_as_check
APP_DIR=$(ls -d /tmp/la_as_check/Payload/*.app 2>/dev/null | head -1)
if [[ -n "$APP_DIR" ]]; then
  echo "--- Info.plist check (expect ${APP_NAME} / ${MAJOR_VERSION} / ${BUILD_NUMBER}) ---"
  /usr/libexec/PlistBuddy -c 'Print CFBundleDisplayName' -c 'Print CFBundleShortVersionString' -c 'Print CFBundleVersion' "$APP_DIR/Info.plist"
  DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c 'Print CFBundleDisplayName' "$APP_DIR/Info.plist")
  [[ "$DISPLAY_NAME" == "$APP_NAME" ]] \
    || { echo "ERROR: IPA display name '$DISPLAY_NAME' != expected '$APP_NAME' (stale export?)" >&2; exit 1; }
  codesign -d --verbose=2 "$APP_DIR" 2>&1 | grep -E 'TeamIdentifier' | head -2
fi
say "Not uploaded. To upload: ./ios/Tools/build_appstore.sh ${ENV} --upload (ASC App record required)"
