#!/usr/bin/env bash
# Release one user-facing version across web + APK + IPA so the version shown
# on the login page, the download row (versions.json) and the installed app
# are always identical.
#
# Increments release.number (the user-facing version source), rebuilds all
# three artifacts with that number (packages target the public test env),
# and refreshes downloads/versions.json. Deploy afterwards with
# scripts/deploy.sh dev|test. Plain backend/web hotfix deploys do NOT touch
# release.number — the user-facing number only advances here, per release.
#
# Usage: ./scripts/release.sh [--no-bump]   # --no-bump re-tags current number
set -euo pipefail
cd "$(dirname "$0")/.."

RELEASE_FILE="release.number"
[ -f "$RELEASE_FILE" ] || { echo "ERROR: $RELEASE_FILE missing"; exit 1; }
REL=$(tr -d '[:space:]' < "$RELEASE_FILE")
if [ "${1:-}" = "--no-bump" ]; then
  echo "==> Re-releasing version: ${REL}"
else
  REL=$((REL + 1))
  echo "$REL" > "$RELEASE_FILE"
  echo "==> Release number: ${REL}"
fi

cd ../Mobile/mobile_app
./build_android.sh test
./build_ios.sh test

cd ../../smart-livestock-server
# Stage download packages BEFORE build_web so frontend/downloads picks up the
# fresh APK/IPA + versions.json in the same pass (build_web copies downloads/
# into frontend/ and would otherwise ship the previous release's packages).
./scripts/update-downloads.sh

cd ../Mobile/mobile_app
./build_web.sh

echo ""
echo "==> Release ${REL} built (web + APK + IPA + versions.json)."
echo "    Deploy next: ./scripts/deploy.sh dev && ./scripts/deploy.sh test"
echo "    Android versionCode stays monotonic: release.number only increments."
