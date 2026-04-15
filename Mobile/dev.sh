#!/usr/bin/env bash
# 智慧畜牧 App 开发启动/停止脚本
# 用法:
#   ./dev.sh start          # 启动 Mock Server + Flutter App
#   ./dev.sh start mock     # Mock 模式启动 Flutter（默认）
#   ./dev.sh start live     # Live 模式启动 Flutter（连接 Mock Server）
#   ./dev.sh stop           # 停止所有服务
#   ./dev.sh restart [mock|live]  # 重启所有服务
#   ./dev.sh status         # 查看服务状态
#   ./dev.sh diagnose       # 打印最近日志与关键错误行（便于白屏/WASM 等问题排查）

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
  local mode="${1:-live}"
  local device="${2:-chrome}"

  if is_running flutter; then
    warn "Flutter App 已在运行 (PID $(cat "$PID_DIR/flutter.pid"))"
    return 0
  fi

  info "启动 Flutter App (APP_MODE=$mode, device=$device)..."
  if [[ "$device" == "chrome" ]]; then
    (cd "$MOBILE_DIR" && flutter run -d "$device" --no-web-resources-cdn --dart-define=APP_MODE="$mode" > "$LOG_DIR/flutter.log" 2>&1) &
  else
    (cd "$MOBILE_DIR" && flutter run -d "$device" --dart-define=APP_MODE="$mode" > "$LOG_DIR/flutter.log" 2>&1) &
  fi
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

# ---------- 诊断（最近日志 + 关键行） ----------
diagnose() {
  ensure_dirs
  echo ""
  info "=== 进程状态 ==="
  show_status
  echo ""
  local flutter_log="$LOG_DIR/flutter.log"
  local backend_log="$LOG_DIR/backend.log"

  if [[ -f "$flutter_log" ]]; then
    info "=== Flutter 最近 100 行 ($flutter_log) ==="
    tail -n 100 "$flutter_log"
  else
    warn "Flutter 日志不存在: $flutter_log（可能未用本脚本启动或未产生日志）"
  fi
  echo ""
  if [[ -f "$backend_log" ]]; then
    info "=== Mock Server 最近 100 行 ($backend_log) ==="
    tail -n 100 "$backend_log"
  else
    warn "Backend 日志不存在: $backend_log"
  fi
  echo ""
  if [[ -f "$flutter_log" ]]; then
    info "=== Flutter 关键行（匹配 error/exception/fail/abort/wasm 等，最多 50 行）==="
    grep -E -i 'error|exception|fail|abort|fatal|TypeError|webassembly|wasm|rejected|cannot|unhandled' "$flutter_log" 2>/dev/null | tail -n 50 || true
  fi
  if [[ -f "$backend_log" ]]; then
    info "=== Mock Server 关键行（同上，最多 50 行）==="
    grep -E -i 'error|exception|fail|abort|fatal|EADDRINUSE|listen|ECONNREFUSED' "$backend_log" 2>/dev/null | tail -n 50 || true
  fi
  echo ""
  info "完整日志目录: $LOG_DIR/"
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
  start_live)
    start_backend
    start_flutter "live" "chrome"
    ;;
  start_mock)
    start_backend
    start_flutter "mock" "chrome"
    ;;
  start)
    ensure_dirs
    # 注册退出清理
    trap cleanup INT TERM

    mode="${2:-mock}"
    device="${3:-chrome}"
    if [[ "$mode" != "mock" && "$mode" != "live" ]]; then
      error "无效模式: $mode（可选 mock / live）"
      exit 1
    fi

    start_backend
    if [[ "$mode" == "live" ]]; then
      info "等待 Mock Server 就绪..."
      sleep 1
    fi
    start_flutter "$mode" "$device"

    info "========================================="
    info "  所有服务已启动"
    info "  模式: $mode"
    info "  设备: $device"
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
    exec "$0" start "${2:-mock}" "${3:-chrome}"
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

  diagnose)
    diagnose
    ;;

  help|*)
    echo "智慧畜牧 App 开发控制脚本"
    echo ""
    echo "用法:"
    echo "  $0 start [mock|live] [chrome|macos]  启动所有服务（默认 mock + chrome）"
    echo "  $0 stop                              停止所有服务"
    echo "  $0 restart [mock|live] [chrome|macos] 重启所有服务"
    echo "  $0 status                            查看服务状态"
    echo "  $0 logs [backend|flutter]            查看日志（实时跟踪）"
    echo "  $0 diagnose                          诊断：最近 100 行日志 + 关键错误行"
    ;;
esac
