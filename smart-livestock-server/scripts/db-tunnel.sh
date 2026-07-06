#!/bin/bash
# 一键启动 PostgreSQL SSH 隧道 + 打开 TablePlus
# 用法: ./scripts/db-tunnel.sh [dev|prod|test]

ENV="${1:-dev}"

case "$ENV" in
  dev)  PORT=16432 ;;
  prod) PORT=15432 ;;
  test) PORT=15432 ;;  # test 和 prod 共用同一套
  *)    echo "用法: $0 [dev|prod|test]"; exit 1 ;;
esac

# 检查隧道是否已在运行
if lsof -i :$PORT &>/dev/null; then
  echo "✅ 隧道已在运行 (端口 $PORT)"
else
  echo "🔗 建立 SSH 隧道 localhost:$PORT → 172.22.1.123:$PORT ..."
  ssh -fN -L $PORT:localhost:$PORT agentic@172.22.1.123
  echo "✅ 隧道已建立"
fi

# 打开 TablePlus
open /Applications/TablePlus.app
echo "🚀 TablePlus 已启动"
