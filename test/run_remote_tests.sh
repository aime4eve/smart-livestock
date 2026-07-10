#!/bin/bash
set -e

SERVER="agentic@172.22.1.123"
REMOTE_DIR="~/smart-livestock-server"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== 同步代码到远程服务器 ==="
rsync -avz --exclude='.git' --exclude='.gradle' --exclude='build/tmp' \
  --exclude='build/classes' "$PROJECT_DIR/smart-livestock-server/" $SERVER:$REMOTE_DIR/ 2>&1 | tail -3

echo ""
echo "=== 1. 后端编译 ==="
ssh $SERVER "cd $REMOTE_DIR && ./gradlew compileJava compileTestJava 2>&1 | tail -3"

echo ""
echo "=== 2. RanchOverview 单元测试 ==="
ssh $SERVER "cd $REMOTE_DIR && ./gradlew test --tests 'com.smartlivestock.ranch.application.service.RanchOverviewApplicationServiceTest' 2>&1 | tail -5"

echo ""
echo "=== 3. RanchOverview 集成测试 ==="
ssh $SERVER "cd $REMOTE_DIR && ./gradlew test --tests 'com.smartlivestock.integration.RanchOverviewIntegrationTest' 2>&1 | tail -5"

echo ""
echo "=== 4. 后端全部测试 ==="
ssh $SERVER "cd $REMOTE_DIR && ./gradlew test 2>&1 | grep -E 'BUILD|tests' | tail -5"

echo ""
echo "✅ 后端测试完成"
