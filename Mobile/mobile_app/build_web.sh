#!/usr/bin/env bash
# Build Flutter web bundle and copy to nginx frontend directory.
# --no-wasm-dry-run suppresses false-positive WASM warnings from
# flutter_secure_storage (native-only, excluded from web bundle
# via conditional import in lib/core/api/jwt_storage.dart).
# --pwa-strategy=none disables the service worker: offline-first SW
# serves a stale main.dart.js after each deploy until the next visit,
# which made new frontend releases invisible to returning users.
set -euo pipefail
cd "$(dirname "$0")"
flutter build web --no-wasm-dry-run "$@" \
  --pwa-strategy=none \
  --dart-define=API_BASE_URL=/api/v1 \
  --no-source-maps \
  --strip-wasm

# Copy build output so deploy.sh rsync + docker build nginx picks it up.
FRONTEND_DIR="../../smart-livestock-server/frontend"
echo "==> Copying build output to $FRONTEND_DIR ..."
rm -rf "$FRONTEND_DIR"
mkdir -p "$FRONTEND_DIR/"
cp -a build/web/. "$FRONTEND_DIR/"
echo "==> Frontend deployed to $FRONTEND_DIR"
