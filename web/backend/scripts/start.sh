#!/usr/bin/env bash
# web/backend/scripts/start.sh — 后台启动后端（nohup）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$BACKEND_DIR/../.." && pwd)"

cd "$REPO_ROOT"

RUN_DIR="$REPO_ROOT/.run"
PID_FILE="$RUN_DIR/backend.pid"
LOG_FILE="$RUN_DIR/backend.log"

# ── 颜色 ──────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

log()  { echo -e "${CYAN}[backend]${RESET} $*"; }
ok()   { echo -e "${GREEN}[backend]${RESET} $*"; }
warn() { echo -e "${YELLOW}[backend]${RESET} $*"; }
err()  { echo -e "${RED}[backend]${RESET} $*" >&2; }

mkdir -p "$RUN_DIR"

# ── 检查是否已在运行 ──────────────────────────────────────────────────────────
if [[ -f "$PID_FILE" ]]; then
    OLD_PID="$(cat "$PID_FILE")"
    if kill -0 "$OLD_PID" 2>/dev/null; then
        warn "后端已在运行（PID $OLD_PID），跳过"
        warn "如需重启: bash web/backend/scripts/restart.sh"
        exit 0
    else
        warn "发现过期 PID 文件，清理..."
        rm -f "$PID_FILE"
    fi
fi

# ── Python 环境 ───────────────────────────────────────────────────────────────
if [[ -f "$REPO_ROOT/.venv/bin/python" ]]; then
    PYTHON="$REPO_ROOT/.venv/bin/python"
    log "使用虚拟环境: .venv"
elif command -v python3 &>/dev/null; then
    PYTHON="$(command -v python3)"
    warn "未找到 .venv，使用系统 Python: $PYTHON"
else
    err "未找到 Python，请先安装 Python 3.9+"
    exit 1
fi

# ── 依赖检查 ──────────────────────────────────────────────────────────────────
if ! "$PYTHON" -c "import fastapi" &>/dev/null; then
    warn "FastAPI 未安装，正在安装依赖..."
    "$PYTHON" -m pip install -q -r "$REPO_ROOT/requirements.txt" \
                                  -r "$REPO_ROOT/requirements-web.txt"
fi

# ── 加载 .env ─────────────────────────────────────────────────────────────────
if [[ -f "$REPO_ROOT/.env" ]]; then
    log "加载 .env"
    set -o allexport
    # shellcheck source=/dev/null
    source "$REPO_ROOT/.env"
    set +o allexport
else
    warn ".env 不存在，请参考 .env.example 创建"
fi

# ── 启动 ──────────────────────────────────────────────────────────────────────
log "后台启动后端..."
log "日志: $LOG_FILE"

nohup "$PYTHON" -m uvicorn web.backend.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    > "$LOG_FILE" 2>&1 &

BACKEND_PID=$!
echo "$BACKEND_PID" > "$PID_FILE"

sleep 1
if kill -0 "$BACKEND_PID" 2>/dev/null; then
    ok "后端已启动 → http://localhost:8000  (PID $BACKEND_PID)"
    ok "查看日志: tail -f $LOG_FILE"
else
    err "后端启动失败，请查看日志: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi
