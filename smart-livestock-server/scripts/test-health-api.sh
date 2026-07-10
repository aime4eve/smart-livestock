#!/bin/bash
# ============================================================
# Health API Contract Test Script
# Usage: ./scripts/test-health-api.sh [BASE_URL] [TOKEN]
# Default: http://localhost:18080/api/v1
# ============================================================
set -euo pipefail

BASE_URL="${1:-http://localhost:18080/api/v1}"
TOKEN="${2:-}"
FARM_ID="${3:-1}"

if [ -z "$TOKEN" ]; then
    echo ">> Logging in as owner..."
    LOGIN_RESP=$(curl -s -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"phone":"13800138000","password":"123"}')
    TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null || echo "")
    if [ -z "$TOKEN" ]; then
        echo "FAILED: Login failed. Response: $LOGIN_RESP"
        exit 1
    fi
    echo "   Token acquired: ${TOKEN:0:20}..."
fi

AUTH="Authorization: Bearer $TOKEN"
HEALTH="$BASE_URL/farms/$FARM_ID/health"
PASS=0
FAIL=0
TOTAL=0

assert_status() {
    local name="$1" url="$2" expected="$3"
    TOTAL=$((TOTAL + 1))
    resp=$(curl -s -w "\n%{http_code}" "$url" -H "$AUTH")
    code=$(echo "$resp" | tail -1)
    body=$(echo "$resp" | sed '$d')
    if [ "$code" = "$expected" ]; then
        echo "  ✅ $name → $code"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $name → expected $expected, got $code"
        echo "     Body: $(echo "$body" | head -c 300)"
        FAIL=$((FAIL + 1))
    fi
}

assert_field() {
    local name="$1" url="$2" field="$3"
    TOTAL=$((TOTAL + 1))
    body=$(curl -s "$url" -H "$AUTH")
    val=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print($field)" 2>/dev/null || echo "ERROR")
    if [ "$val" != "ERROR" ] && [ -n "$val" ]; then
        echo "  ✅ $name → $field=$val"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $name → field $field not found"
        echo "     Body: $(echo "$body" | head -c 400)"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "=========================================="
echo "  Health API Contract Tests"
echo "  Base URL: $HEALTH"
echo "=========================================="
echo ""

# ---- 1. Health Overview ----
echo "--- 1. Health Overview ---"
assert_status "GET /health/overview" "$HEALTH/overview" "200"
assert_field "Overview has stats" "$HEALTH/overview" "d.get('stats') is not None"
assert_field "Overview has sceneSummary" "$HEALTH/overview" "d.get('sceneSummary') is not None"
assert_field "Overview has pendingTasks" "$HEALTH/overview" "isinstance(d.get('pendingTasks'), list)"
echo ""

# ---- 2. Fever (发热预警) ----
echo "--- 2. Fever ---"
assert_status "GET /health/fever" "$HEALTH/fever" "200"
assert_field "Fever has items" "$HEALTH/fever" "isinstance(d.get('items'), list)"

LIVESTOCK_ID=$(curl -s "$HEALTH/fever" -H "$AUTH" | python3 -c "
import sys,json
d = json.load(sys.stdin)['data']
items = d.get('items', [])
print(items[0]['livestockId'] if items else '')
" 2>/dev/null || echo "")

if [ -n "$LIVESTOCK_ID" ]; then
    assert_status "GET /health/fever/{id}" "$HEALTH/fever/$LIVESTOCK_ID" "200"
    assert_field "Fever detail has baselineTemp" "$HEALTH/fever/$LIVESTOCK_ID" "d.get('baselineTemp') is not None"
    assert_field "Fever detail has recent72h" "$HEALTH/fever/$LIVESTOCK_ID" "isinstance(d.get('recent72h'), list)"
else
    echo "  ⚠️  No fever items to test detail endpoint"
fi
echo ""

# ---- 3. Digestive (消化管理) ----
echo "--- 3. Digestive ---"
assert_status "GET /health/digestive" "$HEALTH/digestive" "200"
assert_field "Digestive has items" "$HEALTH/digestive" "isinstance(d.get('items'), list)"

DIGESTIVE_ID=$(curl -s "$HEALTH/digestive" -H "$AUTH" | python3 -c "
import sys,json
d = json.load(sys.stdin)['data']
items = d.get('items', [])
print(items[0]['livestockId'] if items else '')
" 2>/dev/null || echo "")

if [ -n "$DIGESTIVE_ID" ]; then
    assert_status "GET /health/digestive/{id}" "$HEALTH/digestive/$DIGESTIVE_ID" "200"
    assert_field "Digestive detail has recent24h" "$HEALTH/digestive/$DIGESTIVE_ID" "isinstance(d.get('recent24h'), list)"
fi
echo ""

# ---- 4. Estrus (发情识别) ----
echo "--- 4. Estrus ---"
assert_status "GET /health/estrus" "$HEALTH/estrus" "200"
assert_field "Estrus has items" "$HEALTH/estrus" "isinstance(d.get('items'), list)"

ESTRUS_ID=$(curl -s "$HEALTH/estrus" -H "$AUTH" | python3 -c "
import sys,json
d = json.load(sys.stdin)['data']
items = d.get('items', [])
for item in items:
    if item.get('score', 0) > 0:
        print(item['livestockId'])
        break
" 2>/dev/null || echo "")

if [ -n "$ESTRUS_ID" ]; then
    assert_status "GET /health/estrus/{id}" "$HEALTH/estrus/$ESTRUS_ID" "200"
    assert_field "Estrus detail has trend7d" "$HEALTH/estrus/$ESTRUS_ID" "isinstance(d.get('trend7d'), list)"
else
    echo "  ⚠️  No estrus items with score > 0 to test detail"
fi
echo ""

# ---- 5. Epidemic (疫病防控) ----
echo "--- 5. Epidemic ---"
assert_status "GET /health/epidemic" "$HEALTH/epidemic" "200"
assert_field "Epidemic has metrics" "$HEALTH/epidemic" "d.get('metrics') is not None"
assert_field "Epidemic metrics has avgTemperature" "$HEALTH/epidemic" "d['metrics'].get('avgTemperature') is not None"
assert_field "Epidemic has contacts" "$HEALTH/epidemic" "isinstance(d.get('contacts'), list)"
echo ""

echo "=========================================="
echo "  Results: $PASS passed, $FAIL failed (total: $TOTAL)"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
