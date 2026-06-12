#!/usr/bin/env bash
# Build Flutter web bundle.
# --no-wasm-dry-run suppresses false-positive WASM warnings from
# flutter_secure_storage (native-only, excluded from web bundle
# via conditional import in lib/core/api/jwt_storage.dart).
set -euo pipefail
cd "$(dirname "$0")"
flutter build web --no-wasm-dry-run "$@"
