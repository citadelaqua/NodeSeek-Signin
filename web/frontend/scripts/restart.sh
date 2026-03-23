#!/usr/bin/env bash
# web/frontend/scripts/restart.sh — 重启前端开发服务器
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\033[0;35m[frontend]\033[0m 重启前端..."
bash "$SCRIPT_DIR/stop.sh"
bash "$SCRIPT_DIR/start.sh"
