#!/usr/bin/env bash
# scripts/frontend/stop.sh — 停止后台运行的前端开发服务器
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

RUN_DIR="$REPO_ROOT/.run"
PID_FILE="$RUN_DIR/frontend.pid"

# ── 颜色 ──────────────────────────────────────────────────────────────────────
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

log()  { echo -e "${MAGENTA}[frontend]${RESET} $*"; }
ok()   { echo -e "${GREEN}[frontend]${RESET} $*"; }
warn() { echo -e "${YELLOW}[frontend]${RESET} $*"; }
err()  { echo -e "${RED}[frontend]${RESET} $*" >&2; }

_kill_pid() {
    local pid="$1"
    if kill -0 "$pid" 2>/dev/null; then
        log "发送 SIGTERM 到 PID $pid..."
        # npm 启动的 vite 需要向整个进程组发信号
        kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
        local i
        for i in $(seq 1 8); do
            sleep 1
            if ! kill -0 "$pid" 2>/dev/null; then
                ok "进程 $pid 已停止"
                return 0
            fi
        done
        warn "进程未在 8 秒内退出，发送 SIGKILL..."
        kill -9 -- -"$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
        ok "进程 $pid 已强制终止"
    fi
}

# ── 优先通过 PID 文件停止 ──────────────────────────────────────────────────────
if [[ -f "$PID_FILE" ]]; then
    PID="$(cat "$PID_FILE")"
    log "从 PID 文件读取进程 ID: $PID"
    _kill_pid "$PID"
    rm -f "$PID_FILE"
    # 同时清理可能残留的 vite 子进程
    pkill -f "vite" 2>/dev/null || true
    exit 0
fi

# ── 回退：按进程名匹配 vite ───────────────────────────────────────────────────
warn "未找到 PID 文件，尝试按进程名查找..."
PIDS="$(pgrep -f "vite" 2>/dev/null || true)"

if [[ -z "$PIDS" ]]; then
    warn "未找到运行中的前端进程，可能已停止"
    exit 0
fi

for PID in $PIDS; do
    _kill_pid "$PID"
done
ok "所有匹配的前端进程已停止"
