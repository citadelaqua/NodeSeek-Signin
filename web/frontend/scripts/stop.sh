#!/usr/bin/env bash
# web/frontend/scripts/stop.sh — 停止前端开发服务器
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FRONTEND_DIR/../.." && pwd)"

RUN_DIR="$REPO_ROOT/.run"
PID_FILE="$RUN_DIR/frontend.pid"

# ── 颜色 ──────────────────────────────────────────────────────────────────────
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

log()  { echo -e "${MAGENTA}[frontend]${RESET} $*"; }
ok()   { echo -e "${GREEN}[frontend]${RESET} $*"; }
warn() { echo -e "${YELLOW}[frontend]${RESET} $*"; }

_kill_pid() {
    local pid="$1"
    if ! kill -0 "$pid" 2>/dev/null; then
        warn "进程 $pid 已不存在"
        return 0
    fi
    log "发送 SIGTERM → PID $pid"
    # 向进程组发信号，覆盖 npm 派生的 vite 子进程
    kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
    local i
    for i in $(seq 1 8); do
        sleep 1
        if ! kill -0 "$pid" 2>/dev/null; then
            ok "进程 $pid 已停止"
            return 0
        fi
    done
    warn "8 秒内未退出，发送 SIGKILL..."
    kill -9 -- -"$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
    ok "进程 $pid 已强制终止"
}

# ── 优先通过 PID 文件停止 ──────────────────────────────────────────────────────
if [[ -f "$PID_FILE" ]]; then
    PID="$(cat "$PID_FILE")"
    log "PID 文件 → $PID"
    _kill_pid "$PID"
    rm -f "$PID_FILE"
    # 清理可能残留的 vite 子进程
    pkill -f "vite" 2>/dev/null || true
    exit 0
fi

# ── 回退：按进程名匹配 ─────────────────────────────────────────────────────────
warn "未找到 PID 文件，按进程名查找..."
PIDS="$(pgrep -f "vite" 2>/dev/null || true)"

if [[ -z "$PIDS" ]]; then
    warn "未找到运行中的前端进程"
    exit 0
fi

for PID in $PIDS; do
    _kill_pid "$PID"
done
ok "前端进程已全部停止"
