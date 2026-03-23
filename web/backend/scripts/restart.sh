#!/usr/bin/env bash
# web/backend/scripts/restart.sh — 重启后端服务
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\033[0;36m[backend]\033[0m 重启后端..."
bash "$SCRIPT_DIR/stop.sh"
bash "$SCRIPT_DIR/start.sh"
