#!/usr/bin/env bash
# scripts/remote-integration-test.sh — 借 dev 服务器（172.22.1.123）的 Docker
# 跑本机跑不了的 Testcontainers 集成测试（schema validate / @DataJpaTest
# 装配 / fixture CHECK 约束 / journey 全链路）。
#
# 背景：本机 Mac 无 Docker，@Testcontainers(disabledWithoutDocker=true) 在
# 本地全部 skip——GitHub CI 是唯一能暴露这类问题的地方，等 push 后才发现
# 就是一轮返工（2026-10-28 Backend 四层根因复盘）。123 与 CI 同 JDK 版本
# (17.0.20)，Docker 29.x，2TB 数据盘，作为远程测试执行机。
#
# 用法：
#   ./scripts/remote-integration-test.sh                # CI 等效集（推荐 push 前跑）
#   ./scripts/remote-integration-test.sh --with-journey # 全量含 journey（已知大片历史债挂，见下）
#   ./scripts/remote-integration-test.sh --target <TestClassName>
#   ./scripts/remote-integration-test.sh --skip-sync    # 跳过 rsync 复用上次源码
#
# 模式说明：
# - 默认（CI 等效集）：-PexcludeIntegrationTests=true，与 backend-ci.yml 逐字
#   一致——unit 全量 + integration 包外的 Testcontainers 用例（如
#   ContactAnalysisServiceIntegrationTest，@Testcontainers 类但不在
#   integration/** 包，CI 会跑）。
# - --with-journey：额外跑 integration/** 包的 Journey 测试。已知状态：
#   这些测试从未被 CI 执行（build.gradle 排除）且长期未维护，2026-10-28
#   首跑 ~50 类大面积失败（NIX-256 R2 N1 遗留"journey setup 未修"债务），
#   修复须另立工单，失败清单见知识库复盘笔记。
#
# 一次性初始化（已做，重建 testbed 时需重跑）：
#   mkdir -p /data/agentic/ci-testbed/.gradle-home/wrapper/dists
#   cp -r /data/agentic/.gradle/wrapper/dists/gradle-8.7-bin \
#         /data/agentic/ci-testbed/.gradle-home/wrapper/dists/
# （123 出网访问 services.gradle.org 超时，wrapper 发行版必须从打包缓存
#  /data/agentic/.gradle 预置；依赖下载走 Maven Central 正常。）
#
# 原理：rsync 增量源码到 123 的 /data/agentic/ci-testbed/（独立于打包目录
# /data/agentic/smart-livestock/，互不干扰；licensing 向量测试依赖仓库根的
# 兄弟目录 license-issuer/，一并同步），ssh 执行 gradlew test。
set -uo pipefail

HOST="172.22.1.123"
BASE="/data/agentic/ci-testbed"
REMOTE_ROOT="$BASE"
LOCAL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TARGET=""
WITH_JOURNEY=0
SYNC=1
GRADLE_PROPS="-PexcludeIntegrationTests=true"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --with-journey) WITH_JOURNEY=1; GRADLE_PROPS=""; shift ;;
    --skip-sync) SYNC=0; shift ;;
    *) echo "未知参数: $1"; exit 2 ;;
  esac
done

if [[ $SYNC -eq 1 ]]; then
  echo "━━━ rsync 源码 → $HOST:$REMOTE_ROOT ━━━"
  rsync -az --delete \
    --exclude 'build/' --exclude '.gradle/' --exclude 'bin/' --exclude '._*' \
    "$LOCAL_ROOT/smart-livestock-server/" "$HOST:$REMOTE_ROOT/smart-livestock-server/" \
    || { echo "❌ rsync smart-livestock-server 失败"; exit 1; }
  rsync -az --delete \
    --exclude 'build/' --exclude '._*' \
    "$LOCAL_ROOT/license-issuer/" "$HOST:$REMOTE_ROOT/license-issuer/" \
    || { echo "❌ rsync license-issuer 失败（licensing 向量测试依赖）"; exit 1; }
fi

GRADLE_CMD="./gradlew test $GRADLE_PROPS"
[[ -n "$TARGET" ]] && GRADLE_CMD="./gradlew test $GRADLE_PROPS --tests '$TARGET'"

MODE="CI 等效集（unit 全量 + integration 包外 Testcontainers）"
[[ $WITH_JOURNEY -eq 1 ]] && MODE="全量含 journey（已知历史债大面积挂）"
echo "━━━ 远程测试：$MODE ━━━"

ssh "$HOST" "cd $REMOTE_ROOT/smart-livestock-server && \
  GRADLE_USER_HOME=$BASE/.gradle-home $GRADLE_CMD"
STATUS=$?

echo ""
if [[ $STATUS -eq 0 ]]; then
  echo "🟢 远程测试全绿。"
else
  echo "🔴 远程测试失败（exit $STATUS）。定位："
  echo "   ssh $HOST 'grep -l \"<failure\" $REMOTE_ROOT/smart-livestock-server/build/test-results/test/*.xml'"
fi
exit $STATUS
