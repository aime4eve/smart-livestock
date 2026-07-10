#!/usr/bin/env bash
set -euo pipefail

# Phase C PoC - Real blade integration verification script
# Full data collection for two target CATTLE_TRACKER devices:
#   2072879090955759616 (0095690600028ea6)
#   2072879090955759618 (0095690600028600)
#
# Usage:
#   ./scripts/verify-blade-docking.sh

# ---- Config ----
AUTH_HOST="${AUTH_HOST:-172.22.4.17}"
AUTH_PORT="${AUTH_PORT:-8108}"
DEVICE_HOST="${DEVICE_HOST:-172.22.4.17}"
DEVICE_PORT="${DEVICE_PORT:-8100}"

CLIENT_ID="${CLIENT_ID:-hkt_openapi}"
CLIENT_SECRET="${CLIENT_SECRET:-RLuXd5H8RkZZRPA6TKbf72XmjKYNq}"
TENANT_ID="${TENANT_ID:-000000}"
SERVICE_USER_ID="${SERVICE_USER_ID:-2074385063398711296}"
DEVICE_TYPE_CODE="${DEVICE_TYPE_CODE:-CATTLE_TRACKER}"

DEV1="2072879090955759616"
DEV2="2072879090955759618"
DEVICE_IDS_JSON='["2072879090955759616","2072879090955759618"]'
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PASS=0
FAIL=0
TOKEN=""

ok()   { echo "  [PASS] $1"; PASS=$((PASS+1)); }
warn() { echo "  [WARN] $1"; }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
step() { echo ""; echo "=== $1 ==="; }

get_token() {
  local basic
  basic=$(printf '%s:%s' "$CLIENT_ID" "$CLIENT_SECRET" | base64)
  curl -s --connect-timeout 5 -X POST "http://${AUTH_HOST}:${AUTH_PORT}/oauth2/token" \
    -H "Authorization: Basic ${basic}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Tenant-Id: ${TENANT_ID}" \
    -d "grant_type=openapi&userId=${SERVICE_USER_ID}" 2>&1
}

blade_get() {
  curl -s --connect-timeout 5 \
    "http://${DEVICE_HOST}:${DEVICE_PORT}${1}" \
    -H "token: ${TOKEN}" -H "Tenant-Id: ${TENANT_ID}"
}

blade_post() {
  curl -s --connect-timeout 5 -X POST \
    "http://${DEVICE_HOST}:${DEVICE_PORT}${1}" \
    -H "token: ${TOKEN}" -H "Tenant-Id: ${TENANT_ID}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

# ---- Step 0: Service connectivity ----
step "Step 0: Service connectivity"
for svc in "auth:${AUTH_HOST}:${AUTH_PORT}" "device:${DEVICE_HOST}:${DEVICE_PORT}"; do
  name=$(echo "$svc" | cut -d: -f1)
  host=$(echo "$svc" | cut -d: -f2)
  port=$(echo "$svc" | cut -d: -f3)
  code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 "http://${host}:${port}/actuator/health" 2>/dev/null || echo "000")
  [ "$code" = "200" ] && ok "blade-${name} (${host}:${port}) is UP" || fail "blade-${name} (${host}:${port}) is DOWN"
done

# ---- Step 1: OAuth2 token exchange ----
step "Step 1: OAuth2 token exchange (grant_type=openapi)"
TOKEN_RESP=$(get_token)
TOKEN=$(echo "$TOKEN_RESP" | jq -r '.data.accessToken // empty' 2>/dev/null || echo "")
if [ -n "$TOKEN" ]; then
  ok "Token acquired (expiresIn=$(echo "$TOKEN_RESP" | jq -r '.data.expiresIn // "?"')s)"
else
  fail "Token exchange failed"
  exit 1
fi

# ---- Step 2: Device detail (ops metadata) ----
step "Step 2: Device detail - ops metadata"
for did in "$DEV1" "$DEV2"; do
  RESP=$(blade_post "/feign/v1/device/lifecycle/getDeviceDetail" "{\"deviceId\":\"${did}\"}")
  CODE=$(echo "$RESP" | jq -r '.code // 0')
  if [ "$CODE" = "200" ]; then
    ok "${did} ($(echo "$RESP" | jq -r '.data.deviceName')): online=$(echo "$RESP" | jq -r '.data.onlineStatus') RSSI=$(echo "$RESP" | jq -r '.data.rssi')dBm SNR=$(echo "$RESP" | jq -r '.data.snr') gateway=$(echo "$RESP" | jq -r '.data.lastGateway') lastActive=$(echo "$RESP" | jq -r '.data.lastActiveTime')"
  else
    fail "${did}: $(echo "$RESP" | jq -r '.msg // "error"')"
  fi
done

# ---- Step 3: Device + telemetry snapshot ----
step "Step 3: Device + telemetry snapshot"
for did in "$DEV1" "$DEV2"; do
  RESP=$(blade_get "/feign/v1/device/lifecycle/getDeviceDetailWithTelemetry?deviceId=${did}")
  PROP_COUNT=$(echo "$RESP" | jq -r '.data.telemetryProperties | length' 2>/dev/null || echo "0")
  if [ "$PROP_COUNT" -gt 0 ] 2>/dev/null; then
    ok "${did}: ${PROP_COUNT} telemetry properties"
    echo "    --- Ops ---"
    echo "$RESP" | jq -r '.data.telemetryProperties[] | select(.identifier=="battery") | "    battery = \(.value)\(.specs.unit // "")"' 2>/dev/null || true
    echo "    --- Feature ---"
    echo "$RESP" | jq -r '.data.telemetryProperties[] | select(.identifier=="latitude" or .identifier=="longitude" or .identifier=="stepNumber") | "    \(.identifier) = \(.value)"' 2>/dev/null || true
    echo "    --- Accelerometer (raw -> g, LIS3DH +/-2g LP 8-bit, ~4mg/digit) ---"
    echo "$RESP" | python3 -c '
import sys, json, math
d = json.load(sys.stdin)
def to_g(v):
    s = v - 65536 if v > 32767 else v
    return s * 0.004
props = {p["identifier"]: p["value"] for p in d["data"]["telemetryProperties"] if "Acceleration" in p.get("identifier","")}
if props:
    rx = props.get("xAxisDirectionAccelerationValue", 0)
    ry = props.get("yAxisDirectionAccelerationValue", 0)
    rz = props.get("zAxisDirectionAccelerationValue", 0)
    gx, gy, gz = to_g(rx), to_g(ry), to_g(rz)
    mag = math.sqrt(gx**2 + gy**2 + gz**2)
    mi = abs(mag - 1.0)
    roll = math.degrees(math.atan2(gy, gz))
    pitch = math.degrees(math.atan2(-gx, math.sqrt(gy**2 + gz**2)))
    act = "rest" if mag < 1.15 else "light" if mag < 1.5 else "active" if mag < 2.5 else "intense"
    print(f"    X={gx:>8.4f}g  Y={gy:>8.4f}g  Z={gz:>8.4f}g  |mag|={mag:.4f}g ({act})")
    print(f"    roll={roll:>6.1f} deg  pitch={pitch:>6.1f} deg  motion_intensity={mi:.4f}g")
' 2>/dev/null || true
  else
    fail "${did}: no telemetry properties"
  fi
done

# ---- Step 4: Latest telemetry ----
step "Step 4: Latest telemetry"
LATEST_RESP=$(blade_post "/feign/v1/device/telemetry/history/latest" \
  "{\"deviceIds\":${DEVICE_IDS_JSON},\"deviceTypeCode\":\"${DEVICE_TYPE_CODE}\"}")
LATEST_COUNT=$(echo "$LATEST_RESP" | jq -r '.data | length' 2>/dev/null || echo "0")
if [ "$LATEST_COUNT" -gt 0 ] 2>/dev/null; then
  ok "Latest telemetry for ${LATEST_COUNT} devices"
  echo "$LATEST_RESP" | python3 -c '
import sys, json, math
d = json.load(sys.stdin)
def to_g(v):
    try:
        fv = float(v)
        s = int(fv) - 65536 if fv > 32767 else int(fv)
        return s * 0.004
    except:
        return 0
for item in d["data"]:
    tj = item["telemetryJson"]
    gx = to_g(tj.get("lastRow(xAxisDirectionAccelerationValue)", 0))
    gy = to_g(tj.get("lastRow(yAxisDirectionAccelerationValue)", 0))
    gz = to_g(tj.get("lastRow(zAxisDirectionAccelerationValue)", 0))
    mag = math.sqrt(gx**2 + gy**2 + gz**2)
    act = "rest" if mag < 1.15 else "light" if mag < 1.5 else "active" if mag < 2.5 else "intense"
    print(f"    battery={tj.get(\"lastRow(battery)\",\"?\")} lat={tj.get(\"lastRow(latitude)\",\"?\")} lon={tj.get(\"lastRow(longitude)\",\"?\")} steps={tj.get(\"lastRow(stepNumber)\",\"?\")} | X={gx:.3f}g Y={gy:.3f}g Z={gz:.3f}g |mag|={mag:.3f}g ({act}) ts={tj.get(\"lastRow(ts)\",\"?\")}")
' 2>/dev/null || true
else
  warn "Latest telemetry returned empty"
fi

# ---- Step 5: Device uplink history summary ----
step "Step 5: Device uplink history (latest 10 records)"
for did in "$DEV1" "$DEV2"; do
  RESP=$(blade_get "/device/report-record/page?deviceId=${did}&current=1&size=10")
  TOTAL=$(echo "$RESP" | jq -r '.data.total // 0')
  if [ "$TOTAL" -gt 0 ] 2>/dev/null; then
    ok "${did}: ${TOTAL} uplink records total"
    echo "$RESP" | python3 -c '
import sys, json, math
d = json.load(sys.stdin)
def to_g(v):
    s = v - 65536 if v > 32767 else v
    return s * 0.004
for r in d["data"]["records"]:
    dd = json.loads(r["decodeData"])["properties"]["properties"]
    ts = r["reportTime"]
    rx, ry, rz = dd.get("xAxisDirectionAccelerationValue",0), dd.get("yAxisDirectionAccelerationValue",0), dd.get("zAxisDirectionAccelerationValue",0)
    gx, gy, gz = to_g(rx), to_g(ry), to_g(rz)
    mag = math.sqrt(gx**2 + gy**2 + gz**2)
    act = "rest" if mag < 1.15 else "light" if mag < 1.5 else "active" if mag < 2.5 else "intense"
    print(f"    {ts}: battery={dd.get(\"battery\",\"?\")} rssi={r[\"rssi\"]} snr={r[\"snr\"]} | lat={dd.get(\"latitude\",\"?\")} lon={dd.get(\"longitude\",\"?\")} steps={dd.get(\"stepNumber\",\"?\")} | X={gx:.3f}g Y={gy:.3f}g Z={gz:.3f}g |mag|={mag:.3f}g ({act})")
' 2>/dev/null || true
  else
    fail "${did}: report-record query failed"
  fi
done

# ---- Step 6: GPS + steps + accel time-sorted table ----
step "Step 6: GPS + steps + accel history (all records, time-sorted, g values)"
for did in "$DEV1" "$DEV2"; do
  OUTPUT=$(python3 "${SCRIPT_DIR}/report-history-table.py" \
    "${did}" "${DEVICE_HOST}" "${DEVICE_PORT}" "${TOKEN}" "${TENANT_ID}" 2>&1)
  RECORD_COUNT=$(echo "$OUTPUT" | head -1 | grep -o 'Total records: [0-9]*' | grep -o '[0-9]*' || echo "0")
  if [ "$RECORD_COUNT" -gt 0 ] 2>/dev/null; then
    ok "${did}: ${RECORD_COUNT} records in table"
    echo "$OUTPUT"
  else
    fail "${did}: no records for table"
  fi
done

# ---- Step 7: Thing model ----
step "Step 7: Thing model (device/type/findById)"
TYPE_ID=$(blade_post "/feign/v1/device/lifecycle/getDeviceDetail" "{\"deviceId\":\"${DEV1}\"}" | jq -r '.data.deviceTypeId')
MODEL_RESP=$(blade_get "/feign/v1/device/type/findById?id=${TYPE_ID}")
MODEL_CODE=$(echo "$MODEL_RESP" | jq -r '.code')
if [ "$MODEL_CODE" = "200" ]; then
  ok "Thing model for ${DEVICE_TYPE_CODE} (typeId=${TYPE_ID})"
  echo "$MODEL_RESP" | python3 -c '
import sys,json
d=json.load(sys.stdin)
props_raw=d["data"]["deviceThingModel"]["properties"]
props=json.loads(props_raw) if isinstance(props_raw,str) else props_raw
for p in props:
    ident=p.get("identifier","?")
    name=p.get("name","?")
    dt=p.get("dataType",{}).get("type","?") if isinstance(p.get("dataType"),dict) else p.get("dataType","?")
    print(f"      {ident:45s} {name:45s} {dt}")
' 2>/dev/null || true
else
  warn "Thing model query returned code=${MODEL_CODE}"
fi

# ---- Summary ----
echo ""
echo "==========================================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "==========================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
