#!/usr/bin/env bash
# scripts/stop.sh — 停止所有后台服务（前端 + 后端）
#
# 用法: bash scripts/stop.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "\033[1m  NodeSeek 签到面板 — 停止所有服务\033[0m"
echo ""

bash "$REPO_ROOT/web/backend/scripts/stop.sh"
bash "$REPO_ROOT/web/frontend/scripts/stop.sh"

echo ""
echo -e "\033[0;32m[stop]\033[0m 所有服务已停止"
