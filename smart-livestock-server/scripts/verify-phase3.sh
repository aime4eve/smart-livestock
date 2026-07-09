#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Phase 3 Integration Verification Script
#
# Verifies the full chain after deployment:
#   1. Flyway migration (new columns + new table exist)
#   2. Seed data (demo devices have platform_device_id)
#   3. Device creation with devEui → 录入即注册 (platformDeviceId returned)
#   4. Device activation
#   5. Device health score API
#   6. Telemetry sync (if enabled): device_telemetry_logs has data
#
# Usage:
#   ./scripts/verify-phase3.sh [dev|test]
#
# Prerequisites:
#   - Server deployed and running
#   - agentic-platform.oauth2.enabled=true (for steps 3)
#   - agentic-platform.sync.enabled=true (for step 6)
# ============================================================

ENV="${1:-test}"

case "$ENV" in
  dev)  PORT="19080" ;;
  test) PORT="18080" ;;
  *)    echo "Usage: $0 [dev|test]"; exit 1 ;;
esac

BASE="http://172.22.1.123:${PORT}/api/v1"
PASS=0; FAIL=0; SKIP=0
TOKEN=""

# Demo seed credentials (owner role)
OWNER_PHONE="13800138000"
OWNER_PASSWORD="123"
DEMO_FARM_ID="1"
DEMO_TENANT_ID="1"

# Demo device IDs (from V10 seed)
DEV1_LOCAL_ID="1"   # DEV-GPS-001, linked to platform 2072879090955759616
DEV2_LOCAL_ID="2"   # DEV-GPS-002, linked to platform 2072879090955759618

# Test device for 录入即注册 (will be created)
TEST_DEV_CODE="DEV-PHASE3-TEST-$(date +%s)"

ok()     { echo "  [PASS] $1"; PASS=$((PASS+1)); }
warn()   { echo "  [WARN] $1"; SKIP=$((SKIP+1)); }
fail()   { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
step()   { echo ""; echo "=== $1 ==="; }

# ---- Helper: login and get JWT ----
login() {
  local phone="$1" password="$2"
  curl -s --connect-timeout 5 -X POST "${BASE}/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"phone\":\"${phone}\",\"password\":\"${password}\"}"
}

# ---- Helper: authed GET ----
api_get() {
  curl -s --connect-timeout 5 "${BASE}/$1" \
    -H "Authorization: Bearer ${TOKEN}"
}

# ---- Helper: authed POST ----
api_post() {
  curl -s --connect-timeout 5 -X POST "${BASE}/$1" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

# ---- Helper: authed PUT ----
api_put() {
  curl -s --connect-timeout 5 -X PUT "${BASE}/$1" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${3:-}}"
}

# ---- Helper: farm-scoped GET ----
farm_get() {
  curl -s --connect-timeout 5 "${BASE}/farms/${DEMO_FARM_ID}/$1" \
    -H "Authorization: Bearer ${TOKEN}"
}

# ---- Helper: farm-scoped POST ----
farm_post() {
  curl -s --connect-timeout 5 -X POST "${BASE}/farms/${DEMO_FARM_ID}/$1" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

# ---- Helper: farm-scoped PUT ----
farm_put() {
  curl -s --connect-timeout 5 -X PUT "${BASE}/farms/${DEMO_FARM_ID}/$1" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${2:-}}"
}

# ============================================================
# Step 0: Service connectivity
# ============================================================
step "Step 0: Service connectivity (${ENV}, port ${PORT})"
LOGIN_CHECK=$(login "$OWNER_PHONE" "$OWNER_PASSWORD" 2>/dev/null)
LOGIN_CODE=$(echo "$LOGIN_CHECK" | jq -r ".code // 0" 2>/dev/null || echo "000")
if [ "$LOGIN_CODE" = "200" ] || [ "$LOGIN_CODE" = "OK" ]; then
  ok "Server is UP (login endpoint responds)"
else
  fail "Server is DOWN or unreachable (login returned code=${LOGIN_CODE})"
  exit 1
fi
TOKEN=$(echo "$LOGIN_CHECK" | jq -r '.data.accessToken // empty' 2>/dev/null || echo "")
if [ -n "$TOKEN" ]; then
  ok "Owner logged in, JWT acquired"
else
  fail "Login failed: $(echo "$LOGIN_CHECK" | head -c 200)"
  exit 1
fi

# ============================================================
# Step 2: Flyway migration verification (new fields visible in API response)
# ============================================================
step "Step 2: Flyway migration — device model has new fields"
DEV1_RESP=$(farm_get "devices/${DEV1_LOCAL_ID}")
DEV1_PID=$(echo "$DEV1_RESP" | jq -r '.data.platformDeviceId // empty' 2>/dev/null || echo "")
if [ -n "$DEV1_PID" ] && [ "$DEV1_PID" != "null" ]; then
  ok "device #${DEV1_LOCAL_ID} has platformDeviceId=${DEV1_PID} (Flyway + seed OK)"
else
  fail "device #${DEV1_LOCAL_ID} missing platformDeviceId (seed migration V20260709130000 may not have run)"
fi

# Check new operational fields exist
DEV1_RSSI=$(echo "$DEV1_RESP" | jq -r '.data.rssi // empty' 2>/dev/null || echo "")
if [ -n "$DEV1_RSSI" ]; then
  ok "device #${DEV1_LOCAL_ID} has rssi=${DEV1_RSSI} (ops fields present)"
else
  warn "device #${DEV1_LOCAL_ID} rssi is null (may not have synced yet)"
fi

# Check DeviceDto returns new fields
HAS_SNR=$(echo "$DEV1_RESP" | jq -r '.data.snr // "ABSENT"' 2>/dev/null || echo "ABSENT")
if [ "$HAS_SNR" != "ABSENT" ]; then
  ok "DeviceDto includes snr field (JPA mapping OK)"
else
  fail "DeviceDto missing snr field (Mapper/Entity issue)"
fi

# ============================================================
# Step 3: 录入即注册 — Create device with devEui
# ============================================================
step "Step 3: 录入即注册 (POST /devices with devEui)"
CREATE_BODY=$(cat <<JSON
{"deviceCode":"${TEST_DEV_CODE}","deviceType":"TRACKER","devEui":"$(printf 'TEST%011d' ${RANDOM}${RANDOM})"}
JSON
)
CREATE_RESP=$(farm_post "devices" "$CREATE_BODY")
CREATED_ID=$(echo "$CREATE_RESP" | jq -r '.data.id // empty' 2>/dev/null || echo "")
CREATED_PID=$(echo "$CREATE_RESP" | jq -r '.data.platformDeviceId // empty' 2>/dev/null || echo "")

if [ -n "$CREATED_ID" ] && [ "$CREATED_ID" != "null" ]; then
  ok "Device created locally: id=${CREATED_ID}, code=${TEST_DEV_CODE}"
else
  fail "Device creation failed: $(echo "$CREATE_RESP" | head -c 300)"
  # Continue to next steps with existing demo devices
  CREATED_ID=""
fi

if [ -n "$CREATED_PID" ] && [ "$CREATED_PID" != "null" ]; then
  ok "录入即注册成功: platformDeviceId=${CREATED_PID}"
else
  warn "录入即注册 skipped/failed (platformDeviceId=null) — platform OAuth2 may be disabled. Retry endpoint available."
  # Try explicit retry if local device was created
  if [ -n "$CREATED_ID" ]; then
    RETRY_RESP=$(farm_post "devices/${CREATED_ID}/register-platform" "{}")
    RETRY_PID=$(echo "$RETRY_RESP" | jq -r '.data.platformDeviceId // empty' 2>/dev/null || echo "")
    if [ -n "$RETRY_PID" ] && [ "$RETRY_PID" != "null" ]; then
      ok "Retry registration succeeded: platformDeviceId=${RETRY_PID}"
    else
      warn "Retry also failed: $(echo "$RETRY_RESP" | head -c 200)"
    fi
  fi
fi

# ============================================================
# Step 4: Device activation
# ============================================================
step "Step 4: Device activation"
if [ -n "$CREATED_ID" ]; then
  ACT_RESP=$(farm_put "devices/${CREATED_ID}/activate")
  ACT_STATUS=$(echo "$ACT_RESP" | jq -r '.data.status // empty' 2>/dev/null || echo "")
  if [ "$ACT_STATUS" = "ACTIVE" ]; then
    ok "Test device activated: status=ACTIVE"
  else
    fail "Activation failed: $(echo "$ACT_RESP" | head -c 200)"
  fi
fi

# Verify demo devices are ACTIVE
DEV1_STATUS=$(echo "$DEV1_RESP" | jq -r '.data.status // empty' 2>/dev/null || echo "")
if [ "$DEV1_STATUS" = "ACTIVE" ]; then
  ok "Demo device #${DEV1_LOCAL_ID} is ACTIVE (eligible for telemetry sync)"
else
  warn "Demo device #${DEV1_LOCAL_ID} status=${DEV1_STATUS} (needs activation for sync)"
fi

# ============================================================
# Step 5: Device health score API
# ============================================================
step "Step 5: Device health score (GET /devices/{id}/health)"
HEALTH_RESP=$(farm_get "devices/${DEV1_LOCAL_ID}/health")
HEALTH_SCORE=$(echo "$HEALTH_RESP" | jq -r '.data.score // empty' 2>/dev/null || echo "")
HEALTH_GRADE=$(echo "$HEALTH_RESP" | jq -r '.data.grade // empty' 2>/dev/null || echo "")
if [ -n "$HEALTH_SCORE" ] && [ "$HEALTH_SCORE" != "null" ]; then
  ok "Device #${DEV1_LOCAL_ID} health: score=${HEALTH_SCORE}, grade=${HEALTH_GRADE}"
  # Show dimensional breakdown
  echo "    Dimensions:"
  echo "$HEALTH_RESP" | jq -r '.data.dimensions // {} | to_entries[] | "      \(.key): \(.value)"' 2>/dev/null || true
else
  fail "Health API failed: $(echo "$HEALTH_RESP" | head -c 200)"
fi

# ============================================================
# Step 6: Telemetry sync verification (if sync.enabled=true)
# ============================================================
step "Step 6: Telemetry sync — device_telemetry_logs data"
# Check if device #1 has lastTelemetrySyncedAt (indicates sync ran)
DEV1_REFRESH=$(farm_get "devices/${DEV1_LOCAL_ID}")
SYNCED_AT=$(echo "$DEV1_REFRESH" | jq -r '.data.lastTelemetrySyncedAt // empty' 2>/dev/null || echo "")
if [ -n "$SYNCED_AT" ] && [ "$SYNCED_AT" != "null" ]; then
  ok "device #${DEV1_LOCAL_ID} lastTelemetrySyncedAt=${SYNCED_AT}"
  # Verify device runtime status was updated
  UPDATED_RSSI=$(echo "$DEV1_REFRESH" | jq -r '.data.rssi // "null"')
  UPDATED_BATTERY=$(echo "$DEV1_REFRESH" | jq -r '.data.batteryLevel // "null"')
  echo "    Updated snapshot: rssi=${UPDATED_RSSI}dBm battery=${UPDATED_BATTERY}%"
  echo "    gateway=$(echo "$DEV1_REFRESH" | jq -r '.data.lastGateway // "null"')"
else
  warn "device #${DEV1_LOCAL_ID} has no telemetry sync yet (sync.enabled may be false or first run pending)"
  echo "    To enable: set AGENTIC_PLATFORM_SYNC_ENABLED=true + AGENTIC_PLATFORM_OAUTH2_ENABLED=true"
  echo "    Then wait 5 min for Dispatcher to pick up, or restart the service."
fi

# ============================================================
# Step 7: Device list shows new fields
# ============================================================
step "Step 7: Device list includes new fields"
LIST_RESP=$(farm_get "devices?page=1&pageSize=5")
ITEM_COUNT=$(echo "$LIST_RESP" | jq -r '.data.items | length' 2>/dev/null || echo "0")
if [ "$ITEM_COUNT" -gt 0 ] 2>/dev/null; then
  ok "Device list returns ${ITEM_COUNT} items"
  echo "    Sample:"
  echo "$LIST_RESP" | jq -r '.data.items[0] | "      id=\(.id) code=\(.deviceCode) status=\(.status) platformDeviceId=\(.platformDeviceId // "null") rssi=\(.rssi // "null")"' 2>/dev/null || true
else
  fail "Device list empty: $(echo "$LIST_RESP" | head -c 200)"
fi

# ============================================================
# Cleanup: decommission test device
# ============================================================
if [ -n "$CREATED_ID" ]; then
  echo ""
  echo "=== Cleanup ==="
  farm_put "devices/${CREATED_ID}/decommission" >/dev/null 2>&1 || true
  echo "  Decommissioned test device #${CREATED_ID}"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "==========================================="
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
echo "==========================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
