#!/bin/bash
set -e
cd "$(dirname "$0")/../Mobile/mobile_app"

echo "=== 1. 前端模型单元测试 ==="
flutter test test/features/ranch/ 2>&1 | tail -10

echo ""
echo "=== 2. 前端导航测试 ==="
flutter test test/app/route_guard_test.dart test/widget_smoke_test.dart test/app/main_shell_empty_farm_test.dart 2>&1 | tail -10

echo ""
echo "=== 3. API 合约测试 ==="
flutter test test/contract/api_contract_test.dart 2>&1 | tail -10

echo ""
echo "=== 4. 前端 E2E（需 172.22.1.123 在线）==="
flutter test test/e2e/backend_e2e_test.dart --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1 2>&1 | tail -10

echo ""
echo "✅ 前端测试完成"
