#!/usr/bin/env bash
# web/backend/scripts/dev.sh — 前台启动后端（开发模式，热重载）
set -euo pipefail

# REPO_ROOT = web/backend/scripts/../../.. = 仓库根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$BACKEND_DIR/../.." && pwd)"

cd "$REPO_ROOT"

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

# ── Python 环境 ───────────────────────────────────────────────────────────────
if [[ -f "$REPO_ROOT/.venv/bin/python" ]]; then
    PYTHON="$REPO_ROOT/.venv/bin/python"
    log "使用虚拟环境: .venv"
elif command -v python3 &>/dev/null; then
    PYTHON="$(command -v python3)"
    warn "未找到 .venv，使用系统 Python: $PYTHON"
    warn "建议: python3 -m venv .venv && source .venv/bin/activate"
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

ok "后端开发服务器启动（热重载） → http://localhost:8000"
ok "API 文档 → http://localhost:8000/docs"

exec "$PYTHON" -m uvicorn web.backend.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --reload \
    --reload-dir "$REPO_ROOT/web/backend" \
    --reload-dir "$REPO_ROOT/src"
