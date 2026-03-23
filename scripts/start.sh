#!/usr/bin/env bash
# scripts/start.sh — 后台同时启动前后端
#
# 用法: bash scripts/start.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "\033[1m  NodeSeek 签到面板 — 后台启动\033[0m"
echo ""

bash "$REPO_ROOT/web/backend/scripts/start.sh"
bash "$REPO_ROOT/web/frontend/scripts/start.sh"

echo ""
echo -e "\033[0;32m[start]\033[0m 全部服务已在后台运行"
echo -e "\033[0;32m[start]\033[0m 停止: bash scripts/stop.sh"
echo -e "\033[0;32m[start]\033[0m 后端日志: tail -f .run/backend.log"
echo -e "\033[0;32m[start]\033[0m 前端日志: tail -f .run/frontend.log"
