#!/usr/bin/env bash
# scripts/frontend/dev.sh — 前台启动前端开发服务器（Vite HMR）
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FRONTEND_DIR="$REPO_ROOT/web/frontend"

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

# ── Node 环境 ─────────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
    err "未找到 Node.js，请先安装: https://nodejs.org"
    exit 1
fi

if ! command -v npm &>/dev/null; then
    err "未找到 npm，请先安装 Node.js: https://nodejs.org"
    exit 1
fi

# ── 依赖检查 ──────────────────────────────────────────────────────────────────
if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    warn "node_modules 不存在，正在安装依赖..."
    npm --prefix "$FRONTEND_DIR" install
fi

ok "前端开发服务器启动（Vite HMR） → http://localhost:5173"
ok "API 请求代理到 → http://localhost:8000（请确保后端已启动）"

exec npm --prefix "$FRONTEND_DIR" run dev
