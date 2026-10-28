#!/usr/bin/env bash
# scripts/precheck-ci.sh — 本地复刻两条 GitHub Actions 流水线的关键步骤，
# 把 CI 最常见的失败（编译错 / 单测挂 / analyze 告警 / golden 跨环境）挡在 push 前。
#
# 用法：./scripts/precheck-ci.sh            # 全量（约 6 分钟）
#       ./scripts/precheck-ci.sh --quick    # 跳过 flutter 全量测试（约 4 分钟）
#
# 说明：
# - 后端与 flutter 均以 CI=true 运行，行为与 GitHub runner 完全一致
#   （golden / 字体栅格化类测试会自动 skip，与 CI 相同）。
# - 后端单元测试不含 Testcontainers（-PexcludeIntegrationTests），与 CI 的
#   unit test 步骤一致；Testcontainers 集成测试本地无 Docker 跑不了，
#   仍由 CI 兜底——实体↔迁移类型对账规范见 AGENTS.md §8。
# - GRADLE_USER_HOME 强制外置卷（漏设曾写爆系统盘，lessons-learned）。
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUICK=0
[[ "${1:-}" == "--quick" ]] && QUICK=1

FAILURES=()

step() {
  local name="$1"; shift
  echo ""
  echo "━━━ $name ━━━"
  if "$@"; then
    echo "✅ $name"
  else
    echo "❌ $name"
    FAILURES+=("$name")
  fi
}

export GRADLE_USER_HOME="${GRADLE_USER_HOME:-/Volumes/DEV/gradle-home}"
export HOME=/private/tmp
export FLUTTER_SUPPRESS_ANALYTICS=true

step "Backend: compile + 全量单元测试（与 CI 同参）" bash -c \
  "cd '$ROOT/smart-livestock-server' && ./gradlew test -PexcludeIntegrationTests=true"

step "Flutter: analyze（与 CI 同参，info/warning 不致命）" bash -c \
  "cd '$ROOT/Mobile/mobile_app' && flutter analyze --no-fatal-infos --no-fatal-warnings"

if [[ $QUICK -eq 0 ]]; then
  step "Flutter: 全量测试（CI=true，与 CI 命令逐字一致）" bash -c \
    "cd '$ROOT/Mobile/mobile_app' && \
     find test -name '*_test.dart' -not -path 'test/e2e/*' | xargs env CI=true flutter test --exclude-tags=golden"
fi

echo ""
if [[ ${#FAILURES[@]} -eq 0 ]]; then
  echo "🟢 预检全绿，与 CI 行为一致，可以 push。"
else
  echo "🔴 预检失败 ${#FAILURES[@]} 项，push 必红，先修复："
  printf '  - %s\n' "${FAILURES[@]}"
  exit 1
fi
