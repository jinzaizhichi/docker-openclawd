#!/usr/bin/env bash
# docker-openclawd 一键安装脚本
# 用法: curl -fsSL https://raw.githubusercontent.com/liam798/docker-openclawd/main/scripts/install.sh | bash
# 或指定安装目录: curl -fsSL .../install.sh | bash -s - /path/to/docker-openclawd

set -euo pipefail

REPO="${DOCKER_OPENCLAWD_REPO:-https://github.com/liam798/docker-openclawd.git}"
BRANCH="${DOCKER_OPENCLAWD_BRANCH:-main}"
# 安装目录：第一个参数，或环境变量 DOCKER_OPENCLAWD_DEST，或默认当前目录下的 docker-openclawd
DEST="${1:-${DOCKER_OPENCLAWD_DEST:-./docker-openclawd}}"

echo "docker-openclawd 一键安装"
echo "  仓库: $REPO (分支: $BRANCH)"
echo "  目标: $DEST"
echo ""

# 前置：需要 Docker 和 Docker Compose
if ! command -v docker &>/dev/null; then
  echo "错误: 未检测到 Docker，请先安装 Docker Desktop 或 Docker Engine。"
  echo "  https://docs.docker.com/get-docker/"
  exit 1
fi
if ! docker compose version &>/dev/null 2>&1; then
  echo "错误: 未检测到 Docker Compose v2，请确保已安装并可用（docker compose version）。"
  echo "  https://docs.docker.com/compose/install/"
  exit 1
fi

# 克隆或更新
if [ -d "$DEST/.git" ]; then
  echo "已在 $DEST 检测到仓库，正在更新..."
  git -C "$DEST" fetch origin
  git -C "$DEST" checkout -q "$BRANCH" 2>/dev/null || true
  git -C "$DEST" pull --ff-only origin "$BRANCH"
else
  echo "正在克隆仓库到 $DEST ..."
  git clone --branch "$BRANCH" --single-branch --depth 1 "$REPO" "$DEST"
fi

cd "$DEST"

if [ ! -f "docker-setup.sh" ]; then
  echo "错误: 未找到 docker-setup.sh，请检查仓库是否完整。"
  exit 1
fi

chmod +x docker-setup.sh 2>/dev/null || true
echo ""
echo "正在执行 docker-setup.sh ..."
echo "----------------------------------------"
exec ./docker-setup.sh
