#!/usr/bin/env bash
# web/frontend/scripts/start.sh — 后台启动前端开发服务器（nohup）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FRONTEND_DIR/../.." && pwd)"

RUN_DIR="$REPO_ROOT/.run"
PID_FILE="$RUN_DIR/frontend.pid"
LOG_FILE="$RUN_DIR/frontend.log"

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

mkdir -p "$RUN_DIR"

# ── 检查是否已在运行 ──────────────────────────────────────────────────────────
if [[ -f "$PID_FILE" ]]; then
    OLD_PID="$(cat "$PID_FILE")"
    if kill -0 "$OLD_PID" 2>/dev/null; then
        warn "前端已在运行（PID $OLD_PID），跳过"
        warn "如需重启: bash web/frontend/scripts/restart.sh"
        exit 0
    else
        warn "发现过期 PID 文件，清理..."
        rm -f "$PID_FILE"
    fi
fi

# ── Node 环境 ─────────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
    err "未找到 Node.js，请先安装: https://nodejs.org"
    exit 1
fi

# ── 依赖检查 ──────────────────────────────────────────────────────────────────
if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    warn "node_modules 不存在，正在安装依赖..."
    npm --prefix "$FRONTEND_DIR" install
fi

# ── 启动 ──────────────────────────────────────────────────────────────────────
log "后台启动前端开发服务器..."
log "日志: $LOG_FILE"

nohup npm --prefix "$FRONTEND_DIR" run dev \
    > "$LOG_FILE" 2>&1 &

FRONTEND_PID=$!
echo "$FRONTEND_PID" > "$PID_FILE"

# vite 需要 ~1s 完成初始化
sleep 2
if kill -0 "$FRONTEND_PID" 2>/dev/null; then
    ok "前端已启动 → http://localhost:5173  (PID $FRONTEND_PID)"
    ok "查看日志: tail -f $LOG_FILE"
else
    err "前端启动失败，请查看日志: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi
