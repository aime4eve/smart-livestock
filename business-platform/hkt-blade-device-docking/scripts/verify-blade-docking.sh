#!/usr/bin/env bash
set -euo pipefail

# Phase C PoC - Real blade integration verification script
# Reads device EUI list from scripts/devices.conf, auto-resolves deviceId.
# To add a device: add one line (EUI) to devices.conf, no code changes needed.
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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVICES_FILE="${DEVICES_FILE:-${SCRIPT_DIR}/devices.conf}"

# ---- Parse EUIs from devices.conf ----
DEVICE_EUIS=()
DEVICE_NOTES=()
if [ ! -f "$DEVICES_FILE" ]; then
  echo "ERROR: devices file not found: $DEVICES_FILE"
  exit 1
fi
while IFS='|' read -r eui note || [ -n "$eui" ]; do
  eui="${eui#"${eui%%[![:space:]]*}"}"  # trim leading whitespace
  eui="${eui%"${eui##*[![:space:]]}"}"  # trim trailing whitespace
  [[ "$eui" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$eui" ]] && continue
  note="${note#"${note%%[![:space:]]*}"}"  # trim leading whitespace
  note="${note%"${note##*[![:space:]]}"}"  # trim trailing whitespace
  DEVICE_EUIS+=("$eui")
  DEVICE_NOTES+=("${note:-}")
done < "$DEVICES_FILE"

if [ ${#DEVICE_EUIS[@]} -eq 0 ]; then
  echo "ERROR: no devices in $DEVICES_FILE"
  exit 1
fi

# deviceId resolved after token acquisition
DEVICE_IDS=()
DEVICE_IDS_JSON=""

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

echo ""
echo "  Devices in ${DEVICES_FILE##*/}: ${#DEVICE_EUIS[@]} total"
for i in "${!DEVICE_EUIS[@]}"; do
  echo "    ${DEVICE_EUIS[$i]} — ${DEVICE_NOTES[$i]}"
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

# ---- Step 1.5: Resolve deviceIds from EUIs ----
step "Step 1.5: Resolve deviceIds from EUIs"
for i in "${!DEVICE_EUIS[@]}"; do
  eui="${DEVICE_EUIS[$i]}"
  RESP=$(blade_post "/feign/v1/device/lifecycle/pageDevices" \
    "{\"keyword\":\"${eui}\",\"current\":1,\"size\":1}")
  CODE=$(echo "$RESP" | jq -r '.code // 0')
  TOTAL=$(echo "$RESP" | jq -r '.data.total // 0')
  if [ "$CODE" = "200" ] && [ "$TOTAL" -gt 0 ] 2>/dev/null; then
    DID=$(echo "$RESP" | jq -r '.data.records[0].deviceId')
    DEVICE_IDS+=("$DID")
    ok "${eui} -> deviceId=${DID}"
  else
    fail "${eui}: device not found on blade (code=${CODE})"
    DEVICE_IDS+=("")
  fi
done

# build JSON array for telemetry batch queries (only valid IDs)
VALID_IDS=()
for id in "${DEVICE_IDS[@]}"; do
  [ -n "$id" ] && VALID_IDS+=("$id")
done
if [ ${#VALID_IDS[@]} -gt 0 ]; then
  DEVICE_IDS_JSON=$(printf '"%s",' "${VALID_IDS[@]}" | sed 's/,$//')
  DEVICE_IDS_JSON="[${DEVICE_IDS_JSON}]"
fi

# ---- Step 2: Device detail (ops metadata) ----
step "Step 2: Device detail - ops metadata"
for i in "${!DEVICE_EUIS[@]}"; do
  eui="${DEVICE_EUIS[$i]}"
  did="${DEVICE_IDS[$i]}"
  [ -z "$did" ] && continue
  RESP=$(blade_post "/feign/v1/device/lifecycle/getDeviceDetail" "{\"deviceId\":\"${did}\"}")
  CODE=$(echo "$RESP" | jq -r '.code // 0')
  if [ "$CODE" = "200" ]; then
    ok "${did} (${eui}): online=$(echo "$RESP" | jq -r '.data.onlineStatus') RSSI=$(echo "$RESP" | jq -r '.data.rssi')dBm SNR=$(echo "$RESP" | jq -r '.data.snr') gateway=$(echo "$RESP" | jq -r '.data.lastGateway') lastActive=$(echo "$RESP" | jq -r '.data.lastActiveTime')"
  else
    fail "${did} (${eui}): $(echo "$RESP" | jq -r '.msg // "error"')"
  fi
done

# ---- Step 3: Device + telemetry snapshot ----
step "Step 3: Device + telemetry snapshot"
for i in "${!DEVICE_EUIS[@]}"; do
  eui="${DEVICE_EUIS[$i]}"
  did="${DEVICE_IDS[$i]}"
  [ -z "$did" ] && continue
  RESP=$(blade_get "/feign/v1/device/lifecycle/getDeviceDetailWithTelemetry?deviceId=${did}")
  CODE=$(echo "$RESP" | jq -r '.code // 0')
  PROP_COUNT=$(echo "$RESP" | jq -r '.data.telemetryProperties | length' 2>/dev/null || echo "0")
  if [ "$CODE" = "200" ] && [ "$PROP_COUNT" -gt 0 ] 2>/dev/null; then
    ok "${did} (${eui}): ${PROP_COUNT} telemetry properties"
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
  elif [ "$CODE" = "200" ]; then
    warn "${did} (${eui}): device registered but no telemetry data yet"
  else
    fail "${did} (${eui}): telemetry query failed: $(echo "$RESP" | jq -r '.msg // "error"')"
  fi
done

# ---- Step 4: Latest telemetry ----
step "Step 4: Latest telemetry"
if [ -n "$DEVICE_IDS_JSON" ]; then
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
    warn "Latest telemetry returned empty (devices may not have reported yet)"
  fi
else
  warn "No valid deviceIds to query telemetry"
fi

# ---- Step 5: Device uplink history summary ----
step "Step 5: Device uplink history (latest 10 records)"
for i in "${!DEVICE_EUIS[@]}"; do
  eui="${DEVICE_EUIS[$i]}"
  did="${DEVICE_IDS[$i]}"
  [ -z "$did" ] && continue
  RESP=$(blade_get "/device/report-record/page?deviceId=${did}&current=1&size=10")
  TOTAL=$(echo "$RESP" | jq -r '.data.total // 0')
  if [ "$TOTAL" -gt 0 ] 2>/dev/null; then
    ok "${did} (${eui}): ${TOTAL} uplink records total"
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
    warn "${did} (${eui}): no uplink records yet (device may not have reported)"
  fi
done

# ---- Step 6: GPS + steps + accel time-sorted table ----
step "Step 6: GPS + steps + accel history (all records, time-sorted, g values)"
for i in "${!DEVICE_EUIS[@]}"; do
  eui="${DEVICE_EUIS[$i]}"
  did="${DEVICE_IDS[$i]}"
  [ -z "$did" ] && continue
  OUTPUT=$(python3 "${SCRIPT_DIR}/report-history-table.py" \
    "${did}" "${DEVICE_HOST}" "${DEVICE_PORT}" "${TOKEN}" "${TENANT_ID}" 2>&1)
  RECORD_COUNT=$(echo "$OUTPUT" | head -1 | grep -o 'Total records: [0-9]*' | grep -o '[0-9]*' || echo "0")
  if [ "$RECORD_COUNT" -gt 0 ] 2>/dev/null; then
    ok "${did} (${eui}): ${RECORD_COUNT} records in table"
    echo "$OUTPUT"
  else
    warn "${did} (${eui}): no records for table"
  fi
done

# ---- Step 7: Thing model ----
step "Step 7: Thing model (device/type/findById)"
FIRST_VALID_ID=""
for id in "${DEVICE_IDS[@]}"; do
  [ -n "$id" ] && FIRST_VALID_ID="$id" && break
done
if [ -n "$FIRST_VALID_ID" ]; then
  TYPE_ID=$(blade_post "/feign/v1/device/lifecycle/getDeviceDetail" "{\"deviceId\":\"${FIRST_VALID_ID}\"}" | jq -r '.data.deviceTypeId')
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
else
  warn "No valid deviceId to query thing model"
fi

# ---- Summary ----
echo ""
echo "==========================================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "==========================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
