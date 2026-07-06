#!/usr/bin/env bash
# Build Flutter web bundle and copy to nginx frontend directory.
# --no-wasm-dry-run suppresses false-positive WASM warnings from
# flutter_secure_storage (native-only, excluded from web bundle
# via conditional import in lib/core/api/jwt_storage.dart).
set -euo pipefail
cd "$(dirname "$0")"
flutter build web --no-wasm-dry-run "$@" \
  --dart-define=API_BASE_URL=/api/v1 \
  --dart-define=REGION=overseas

# Copy build output so deploy.sh rsync + docker build nginx picks it up.
FRONTEND_DIR="../../smart-livestock-server/frontend"
echo "==> Copying build output to $FRONTEND_DIR ..."
rm -rf "$FRONTEND_DIR"
mkdir -p "$FRONTEND_DIR/"
cp -a build/web/. "$FRONTEND_DIR/"
echo "==> Frontend deployed to $FRONTEND_DIR"
