#!/usr/bin/env bash
# scripts/restart.sh — 重启所有服务（前端 + 后端）
#
# 用法: bash scripts/restart.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\033[1m  NodeSeek 签到面板 — 重启所有服务\033[0m"
echo ""

bash "$SCRIPT_DIR/stop.sh"
echo ""
bash "$SCRIPT_DIR/start.sh"
