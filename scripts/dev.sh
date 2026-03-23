#!/usr/bin/env bash
# scripts/dev.sh — 前台同时启动前后端（开发模式）
#
# 用法: bash scripts/dev.sh
#
# 前端 Vite HMR → http://localhost:5173  （代理 /api → :8000）
# 后端 uvicorn  → http://localhost:8000
#
# 按 Ctrl-C 同时终止两个进程
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_SCRIPTS="$REPO_ROOT/web/backend/scripts"
FRONTEND_SCRIPTS="$REPO_ROOT/web/frontend/scripts"

# ── 颜色 ──────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

cd "$REPO_ROOT"

# ── 前置依赖检查（提前失败，避免一边起来一边失败）────────────────────────────
if [[ -f "$REPO_ROOT/.venv/bin/python" ]]; then
    PYTHON="$REPO_ROOT/.venv/bin/python"
elif command -v python3 &>/dev/null; then
    PYTHON="$(command -v python3)"
    echo -e "${YELLOW}[dev]${RESET} 未找到 .venv，使用系统 Python: $PYTHON"
else
    echo -e "\033[0;31m[dev]\033[0m 未找到 Python，请先创建虚拟环境" >&2; exit 1
fi

if ! "$PYTHON" -c "import fastapi" &>/dev/null; then
    echo -e "${YELLOW}[dev]${RESET} 安装后端依赖..."
    "$PYTHON" -m pip install -q -r "$REPO_ROOT/requirements.txt" \
                                  -r "$REPO_ROOT/requirements-web.txt"
fi

if ! command -v node &>/dev/null; then
    echo -e "\033[0;31m[dev]\033[0m 未找到 Node.js，请先安装: https://nodejs.org" >&2; exit 1
fi

if [[ ! -d "$REPO_ROOT/web/frontend/node_modules" ]]; then
    echo -e "${YELLOW}[dev]${RESET} 安装前端依赖..."
    npm --prefix "$REPO_ROOT/web/frontend" install
fi

if [[ -f "$REPO_ROOT/.env" ]]; then
    echo -e "${CYAN}[dev]${RESET} 加载 .env"
    set -o allexport
    # shellcheck source=/dev/null
    source "$REPO_ROOT/.env"
    set +o allexport
else
    echo -e "${YELLOW}[dev]${RESET} .env 不存在，请参考 .env.example 创建"
fi

# ── 多路输出：给子进程加颜色前缀 ─────────────────────────────────────────────
_prefix() {
    local prefix="$1" color="$2"
    while IFS= read -r line; do
        echo -e "${color}${prefix}${RESET} ${line}"
    done
}

# ── 启动 ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  NodeSeek 签到面板 — 开发模式${RESET}"
echo -e "  ${CYAN}后端${RESET} → http://localhost:8000   (uvicorn --reload)"
echo -e "  ${MAGENTA}前端${RESET} → http://localhost:5173   (vite HMR)"
echo ""

"$PYTHON" -m uvicorn web.backend.main:app \
    --host 0.0.0.0 --port 8000 \
    --reload \
    --reload-dir "$REPO_ROOT/web/backend" \
    --reload-dir "$REPO_ROOT/src" \
    2>&1 | _prefix "[backend]" "$CYAN" &
BACKEND_PID=$!

sleep 1

npm --prefix "$REPO_ROOT/web/frontend" run dev \
    2>&1 | _prefix "[frontend]" "$MAGENTA" &
FRONTEND_PID=$!

# ── Ctrl-C / 异常退出清理 ─────────────────────────────────────────────────────
_cleanup() {
    echo ""
    echo -e "${YELLOW}[dev]${RESET} 正在停止..."
    kill "$BACKEND_PID"  2>/dev/null || true
    kill "$FRONTEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID"  2>/dev/null || true
    wait "$FRONTEND_PID" 2>/dev/null || true
    echo -e "${GREEN}[dev]${RESET} 已退出"
}
trap _cleanup EXIT INT TERM

# 等待任意子进程退出
wait -n "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
