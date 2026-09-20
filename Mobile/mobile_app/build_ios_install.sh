#!/usr/bin/env bash
# Build (reuses build_ios.sh) and install the IPA to a physical iPhone.
#
# Usage:
#   ./build_ios_install.sh test                     # build test env IPA + install to default device
#   ./build_ios_install.sh dev                      # build dev env IPA + install
#   ./build_ios_install.sh test --skip-build        # reinstall newest existing IPA (no build)
#   ./build_ios_install.sh test --launch-only       # just relaunch the app on the device
#   ./build_ios_install.sh test <UDID>              # install to a specific device
#   ./build_ios_install.sh --list                   # list connected devices (UDIDs)
#
# Default device: iPhone XR (iPhone11,8).
#
# Notes:
#   - Pass the IPA as an ABSOLUTE path to devicectl: relative paths resolve
#     against the caller's cwd and fail with CoreDeviceError 1005/260.
#   - Locked phone: install still works; launch fails (FBSOpenApplicationErrorDomain 7).
#     Unlock and tap the icon, or re-run with --launch-only after unlocking.
#   - Free-team provisioning expires 7 days after the build; rebuilding refreshes it.
set -euo pipefail
cd "$(dirname "$0")"

DEFAULT_UDID="E3F9E013-0CAB-5D57-B9F1-88487CFB5AA0"   # iPhone XR (iPhone11,8)
BUNDLE_ID="com.hktlora.smartlivestock"

list_devices() { xcrun devicectl list devices 2>/dev/null | tail -n +2; }

# --- arg parsing: env is "test"|"dev"; flags and optional UDID follow ---------
ENV="${1:-}"
if [[ "$ENV" == "--list" ]]; then list_devices; exit 0; fi
if [[ "$ENV" != "test" && "$ENV" != "dev" ]]; then
  if [[ "${1:-}" == --* || -z "${1:-}" ]]; then ENV="test"; else
    sed -n '3,14p' "$0"; exit 1
  fi
fi
shift || true

SKIP_BUILD=0
LAUNCH_ONLY=0
UDID="$DEFAULT_UDID"
for a in "$@"; do
  case "$a" in
    --skip-build) SKIP_BUILD=1 ;;
    --launch-only) LAUNCH_ONLY=1; SKIP_BUILD=1 ;;
    [0-9A-Fa-f][0-9A-Fa-f-][0-9A-Fa-f-][0-9A-Fa-f-][0-9A-Fa-f-]*) UDID="$a" ;;
    *) echo "Unknown argument: $a"; exit 1 ;;
  esac
done

# --- device must be connected -------------------------------------------------
if ! list_devices | grep -q "$UDID"; then
  echo "ERROR: device $UDID is not connected. Connected devices:"
  list_devices
  exit 1
fi
DEV_NAME=$(list_devices | grep "$UDID" | awk '{print $1}')
echo "==> Target: $DEV_NAME ($UDID)"

# --- build (unless reusing) ----------------------------------------------------
IPA_PATH=$(ls -t build/ios/ipa/hkt-livestock-agentic-*.ipa 2>/dev/null | head -1 || true)
if [[ $LAUNCH_ONLY != 1 ]]; then
  if [[ $SKIP_BUILD == 1 ]]; then
    echo "==> Skipping build (reusing newest IPA)"
  else
    ./build_ios.sh "$ENV"
  fi
  IPA_PATH=$(ls -t build/ios/ipa/hkt-livestock-agentic-*.ipa 2>/dev/null | head -1 || true)
fi
if [[ -z "$IPA_PATH" ]]; then
  echo "ERROR: no IPA found under build/ios/ipa/ — run a build first."; exit 1
fi
# devicectl needs an absolute path (relative paths break bookmark creation)
ABS_IPA="$(cd "$(dirname "$IPA_PATH")" && pwd)/$(basename "$IPA_PATH")"
echo "==> IPA: $ABS_IPA"

if [[ $LAUNCH_ONLY == 1 ]]; then
  echo "==> Launching $BUNDLE_ID ..."
  if xcrun devicectl device process launch --device "$UDID" "$BUNDLE_ID" 2>/dev/null; then
    echo "==> Launched OK."
  else
    echo "!! Launch failed — phone is probably locked. Unlock it and tap the icon, then re-run:"
    echo "   $0 $ENV --launch-only"
  fi
  exit 0
fi

# --- install -------------------------------------------------------------------
echo "==> Installing ..."
if ! xcrun devicectl device install app --device "$UDID" "$ABS_IPA"; then
  echo "!! Install failed (see error above). If the device just reconnected, retry once."
  exit 1
fi

# --- launch (best effort) + liveness check -------------------------------------
echo "==> Launching $BUNDLE_ID ..."
if xcrun devicectl device process launch --device "$UDID" "$BUNDLE_ID" 2>/dev/null; then
  sleep 2
  if xcrun devicectl device info processes --device "$UDID" 2>/dev/null | grep -q "Runner\.app"; then
    echo "==> Done: installed, launched and process is alive."
  else
    echo "==> Done: installed and launched (process check inconclusive)."
  fi
else
  echo "!! Launch skipped — phone is probably locked. Unlock it and tap the icon, then re-run:"
  echo "   $0 $ENV --launch-only"
fi
