#!/usr/bin/env bash
# 智慧畜牧 App 开发启动/停止脚本
# 用法:
#   ./dev.sh start          # 启动 Mock Server + Flutter App
#   ./dev.sh start mock     # Mock 模式启动 Flutter（默认）
#   ./dev.sh start live     # Live 模式启动 Flutter（连接 Mock Server）
#   ./dev.sh stop           # 停止所有服务
#   ./dev.sh restart [mock|live]  # 重启所有服务
#   ./dev.sh status         # 查看服务状态

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
MOBILE_DIR="$ROOT_DIR/mobile_app"
PID_DIR="$ROOT_DIR/.dev-pids"
LOG_DIR="$ROOT_DIR/.dev-logs"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

ensure_dirs() {
  mkdir -p "$PID_DIR" "$LOG_DIR"
}

# ---------- 启动 Mock Server ----------
start_backend() {
  if is_running backend; then
    warn "Mock Server 已在运行 (PID $(cat "$PID_DIR/backend.pid"))"
    return 0
  fi

  info "启动 Mock Server..."
  (cd "$BACKEND_DIR" && node server.js > "$LOG_DIR/backend.log" 2>&1) &
  local pid=$!
  echo "$pid" > "$PID_DIR/backend.pid"

  # 等待端口就绪
  local retries=10
  while (( retries-- > 0 )); do
    if curl -sf http://localhost:3001/api/auth/login -X POST \
         -H "Content-Type: application/json" -d '{"role":"owner"}' > /dev/null 2>&1; then
      info "Mock Server 已启动 (PID $pid) → http://localhost:3001"
      return 0
    fi
    sleep 0.5
  done

  # 端口未响应也保留进程，可能是 curl 不可用
  info "Mock Server 已启动 (PID $pid) → http://localhost:3001"
}

# ---------- 启动 Flutter App ----------
start_flutter() {
  local mode="${1:-mock}"

  if is_running flutter; then
    warn "Flutter App 已在运行 (PID $(cat "$PID_DIR/flutter.pid"))"
    return 0
  fi

  info "启动 Flutter App (APP_MODE=$mode)..."
  (cd "$MOBILE_DIR" && flutter run --dart-define=APP_MODE="$mode" > "$LOG_DIR/flutter.log" 2>&1) &
  local pid=$!
  echo "$pid" > "$PID_DIR/flutter.pid"
  info "Flutter App 已启动 (PID $pid, APP_MODE=$mode)"
  info "  日志: tail -f $LOG_DIR/flutter.log"
}

# ---------- 停止服务 ----------
stop_service() {
  local name="$1"
  local pid_file="$PID_DIR/${name}.pid"

  if [[ ! -f "$pid_file" ]]; then
    warn "$name 未运行（无 PID 文件）"
    return 0
  fi

  local pid
  pid=$(cat "$pid_file")

  if kill -0 "$pid" 2>/dev/null; then
    info "停止 $name (PID $pid)..."
    kill "$pid" 2>/dev/null || true
    # 等待进程退出
    local retries=10
    while (( retries-- > 0 )) && kill -0 "$pid" 2>/dev/null; do
      sleep 0.3
    done
    # 仍未退出则强制
    if kill -0 "$pid" 2>/dev/null; then
      warn "$name 未响应 SIGTERM，发送 SIGKILL..."
      kill -9 "$pid" 2>/dev/null || true
    fi
    info "$name 已停止"
  else
    warn "$name 进程已不存在 (PID $pid)"
  fi

  rm -f "$pid_file"
}

stop_all() {
  info "停止所有服务..."
  stop_service flutter
  stop_service backend
  # 兜底：按端口清理
  local node_pid
  node_pid=$(lsof -ti:3001 2>/dev/null || true)
  if [[ -n "$node_pid" ]]; then
    warn "端口 3001 仍有进程占用 ($node_pid)，清理..."
    kill $node_pid 2>/dev/null || true
  fi
  info "所有服务已停止"
}

# ---------- 状态检查 ----------
is_running() {
  local name="$1"
  local pid_file="$PID_DIR/${name}.pid"
  [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null
}

show_status() {
  ensure_dirs
  if is_running backend; then
    info "Mock Server: 运行中 (PID $(cat "$PID_DIR/backend.pid"))"
  else
    warn "Mock Server: 未运行"
  fi
  if is_running flutter; then
    info "Flutter App: 运行中 (PID $(cat "$PID_DIR/flutter.pid"))"
  else
    warn "Flutter App: 未运行"
  fi
}

# ---------- 日志 ----------
show_logs() {
  local name="$1"
  local log_file="$LOG_DIR/${name}.log"
  if [[ -f "$log_file" ]]; then
    tail -f "$log_file"
  else
    error "日志文件不存在: $log_file"
    exit 1
  fi
}

# ---------- 清理 ----------
cleanup() {
  echo ""
  info "检测到退出信号，停止服务..."
  stop_all
  exit 0
}

# ---------- 主入口 ----------
case "${1:-help}" in
  start)
    ensure_dirs
    # 注册退出清理
    trap cleanup INT TERM

    local mode="${2:-mock}"
    if [[ "$mode" != "mock" && "$mode" != "live" ]]; then
      error "无效模式: $mode（可选 mock / live）"
      exit 1
    fi

    start_backend
    # live 模式需要等 Mock Server 就绪
    if [[ "$mode" == "live" ]]; then
      info "等待 Mock Server 就绪..."
      sleep 1
    fi
    start_flutter "$mode"

    info "========================================="
    info "  所有服务已启动"
    info "  模式: $mode"
    info "  Mock Server: http://localhost:3001"
    info "  日志目录: $LOG_DIR/"
    info "  按 Ctrl+C 停止所有服务"
    info "========================================="

    # 保持前台运行，等待 Ctrl+C
    wait
    ;;

  stop)
    stop_all
    ;;

  restart)
    stop_all
    sleep 1
    exec "$0" start "${2:-mock}"
    ;;

  status)
    show_status
    ;;

  logs)
    case "${2:-}" in
      backend)  show_logs backend ;;
      flutter)  show_logs flutter ;;
      *)        echo "用法: $0 logs [backend|flutter]" ;;
    esac
    ;;

  help|*)
    echo "智慧畜牧 App 开发控制脚本"
    echo ""
    echo "用法:"
    echo "  $0 start [mock|live]   启动所有服务（默认 mock 模式）"
    echo "  $0 stop                停止所有服务"
    echo "  $0 restart [mock|live] 重启所有服务"
    echo "  $0 status              查看服务状态"
    echo "  $0 logs [backend|flutter]  查看日志（实时跟踪）"
    ;;
esac
