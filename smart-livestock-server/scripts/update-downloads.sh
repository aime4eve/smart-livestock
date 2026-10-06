#!/usr/bin/env bash
# Stage the latest built APK/IPA as fixed-name download packages served by
# nginx at /downloads/ (compact download row on the login page, prototype
# docs/prototypes/2026-09-28-login-app-download-prototype.html 方案B).
#
# Run AFTER ./build_android.sh / ./build_ios.sh so the staged version matches
# release.number; build_web.sh then copies downloads/ into frontend/ so the
# nginx image ships the files. Binaries are git-ignored.
#
# Usage: ./scripts/update-downloads.sh
set -euo pipefail
cd "$(dirname "$0")/.."

MAJOR_VERSION=$(grep "def majorVersion" build.gradle | sed "s/.*?: *'//; s/'.*//")
BUILD_NUMBER=$(tr -d '[:space:]' < release.number)
APP_VERSION="${MAJOR_VERSION}-b${BUILD_NUMBER}"

APK_SRC="../Mobile/mobile_app/build/app/outputs/flutter-apk/hkt-livestock-agentic-${APP_VERSION}.apk"
IPA_SRC="../Mobile/mobile_app/build/ios/ipa/hkt-livestock-agentic-${APP_VERSION}.ipa"

OUT_DIR="downloads"
mkdir -p "$OUT_DIR"

STAGED=0
if [ -f "$APK_SRC" ]; then
  cp -f "$APK_SRC" "$OUT_DIR/hkt-livestock-latest.apk"
  echo "==> Staged APK: $APK_SRC"
  STAGED=1
else
  echo "==> WARN: no APK for ${APP_VERSION} (skip: $APK_SRC)"
fi
if [ -f "$IPA_SRC" ]; then
  cp -f "$IPA_SRC" "$OUT_DIR/hkt-livestock-latest.ipa"
  echo "==> Staged IPA: $IPA_SRC"
  STAGED=1
else
  echo "==> WARN: no IPA for ${APP_VERSION} (skip: $IPA_SRC)"
fi
if [ "$STAGED" -eq 0 ]; then
  echo "ERROR: nothing staged — build packages first (build_android.sh / build_ios.sh)" >&2
  exit 1
fi

python3 - "$OUT_DIR" "$APP_VERSION" <<'EOF'
import datetime, json, os, sys

out_dir, version = sys.argv[1], sys.argv[2]
manifest = {"version": version, "updatedAt": datetime.date.today().isoformat()}
for key, name in (("apk", "hkt-livestock-latest.apk"),
                  ("ipa", "hkt-livestock-latest.ipa")):
    path = os.path.join(out_dir, name)
    if os.path.isfile(path):
        manifest[key] = name
        manifest[key + "SizeBytes"] = os.path.getsize(path)
with open(os.path.join(out_dir, "versions.json"), "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
print(json.dumps(manifest, indent=2))
EOF

echo "==> Done: $OUT_DIR/ ready (picked up by the next build_web.sh + deploy)"
