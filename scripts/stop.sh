#!/usr/bin/env bash
# scripts/stop.sh — 停止所有后台运行的服务（前端 + 后端）
#
# 用法: bash scripts/stop.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\033[1m  NodeSeek 签到面板 — 停止所有服务\033[0m"
echo ""

bash "$SCRIPT_DIR/backend/stop.sh"
bash "$SCRIPT_DIR/frontend/stop.sh"

echo ""
echo -e "\033[0;32m[stop]\033[0m 所有服务已停止"
