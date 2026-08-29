#!/usr/bin/env bash
set -euo pipefail

# Validate a remote environment file without printing secret values.
ENV="${1:-}"
REMOTE="agentic@172.22.1.123"
REMOTE_DIR="~/smart-livestock-server"

case "$ENV" in
  dev)
    ENV_FILE=".env.dev"
    ;;
  test)
    ENV_FILE=".env"
    ;;
  *)
    echo "Usage: ./scripts/check-env.sh <dev|test>" >&2
    exit 1
    ;;
esac

echo "==> Env preflight ($ENV: $ENV_FILE)..."
ssh "$REMOTE" "cd $REMOTE_DIR && ENV_FILE='$ENV_FILE' bash -s" <<'REMOTE_CHECK'
set -u

failures=0

value_of() {
  local key="$1"
  awk -F= -v key="$key" '
    $1 == key {
      sub(/^[^=]*=/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$ENV_FILE"
}

require_value() {
  local key="$1"
  local value
  value="$(value_of "$key")"
  if [[ -z "$value" ]]; then
    echo "  missing: $key" >&2
    failures=$((failures + 1))
  fi
}

require_secret() {
  local key="$1"
  local value
  value="$(value_of "$key")"
  case "$value" in
    ""|your-*|generate-*|default-secret-change-in-production)
      echo "  invalid secret: $key" >&2
      failures=$((failures + 1))
      ;;
  esac
}

# A configured database password may legitimately equal a historical template
# value if that exact value initialized the environment's Postgres volume.
require_configured_secret() {
  local key="$1"
  local value
  value="$(value_of "$key")"
  if [[ -z "$value" ]]; then
    echo "  missing: $key" >&2
    failures=$((failures + 1))
  fi
}

require_enabled_pair() {
  local enabled_key="$1"
  local username_key="$2"
  local password_key="$3"
  local enabled
  enabled="$(value_of "$enabled_key")"
  if [[ "$enabled" == "true" ]]; then
    require_value "$username_key"
    require_secret "$password_key"
  fi
}

if [[ ! -f "$ENV_FILE" ]]; then
  echo "  environment file not found: $ENV_FILE" >&2
  exit 1
fi

for key in \
  DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD \
  REDIS_HOST REDIS_PORT ROCKETMQ_NAME_SERVER \
  JWT_SECRET SERVER_PORT \
  SIMULATOR_DEVICE_REGISTER_KEY SIMULATOR_FENCE_SYNC_KEY \
  AGENTIC_PLATFORM_DEVICE_BASE_URL AGENTIC_PLATFORM_LICENSE_BASE_URL; do
  require_value "$key"
done

require_configured_secret DB_PASSWORD
require_secret JWT_SECRET
require_secret SIMULATOR_DEVICE_REGISTER_KEY
require_secret SIMULATOR_FENCE_SYNC_KEY

if [[ "$(value_of AGENTIC_PLATFORM_OAUTH2_ENABLED)" == "true" ]]; then
  require_secret AGENTIC_PLATFORM_OAUTH2_CLIENT_SECRET
  require_value AGENTIC_PLATFORM_OAUTH2_SERVICE_USER_ID
fi

require_enabled_pair \
  SMARTLIVESTOCK_TB_ENABLED \
  SMARTLIVESTOCK_TB_USERNAME \
  SMARTLIVESTOCK_TB_PASSWORD
require_enabled_pair \
  SMARTLIVESTOCK_NS_ENABLED \
  SMARTLIVESTOCK_NS_USERNAME \
  SMARTLIVESTOCK_NS_PASSWORD

if (( failures > 0 )); then
  echo "  env preflight failed ($failures issue(s))" >&2
  exit 1
fi

echo "  env preflight passed"
REMOTE_CHECK
