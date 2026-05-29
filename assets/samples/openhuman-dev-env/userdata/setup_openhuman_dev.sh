#!/bin/bash
# ============================================================
# OpenHuman 云端开发环境 — 一键初始化脚本
# 适用: Ubuntu 22.04 LTS (Flexus X 2u4g)
# 触发: RFS user_data 自动注入
# 日志: /var/log/setup-openhuman.log
# ============================================================
set -euo pipefail

LOG_FILE="/var/log/setup-openhuman.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ============================================================
# 配置区（可通过环境变量覆盖）
# ============================================================
REPO_URL="${REPO_URL:-https://github.com/tinyhumansai/openhuman.git}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen2.5:0.5b}"
NODE_VERSION="${NODE_VERSION:-24}"
OPENHUMAN_DIR="${OPENHUMAN_DIR:-/opt/openhuman}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== OpenHuman Dev Env Setup Started ====="

# ============================================================
# Phase 1: 系统更新 + 基础依赖
# ============================================================
echo "[Phase 1] 系统更新与依赖安装..."

apt-get update -y
apt-get upgrade -y
apt-get install -y \
    curl wget git unzip tar jq \
    build-essential pkg-config libssl-dev \
    cmake ninja-build ripgrep \
    ca-certificates gnupg lsb-release

echo "  [OK] 基础依赖安装完成"

# ============================================================
# Phase 2: Node.js 24 + pnpm
# ============================================================
echo "[Phase 2] 安装 Node.js ${NODE_VERSION}..."

if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt-get install -y nodejs
    echo "  [OK] Node.js $(node --version) 安装完成"
else
    echo "  [SKIP] Node.js $(node --version) 已存在"
fi

# 安装 pnpm
if ! command -v pnpm &>/dev/null; then
    npm install -g pnpm@10.10.0
    echo "  [OK] pnpm $(pnpm --version) 安装完成"
else
    echo "  [SKIP] pnpm $(pnpm --version) 已存在"
fi

# ============================================================
# Phase 3: Rust 工具链
# ============================================================
echo "[Phase 3] 安装 Rust..."

if ! command -v rustc &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    rustup default stable
    rustup component add rustfmt clippy
    echo "  [OK] Rust $(rustc --version) 安装完成"
else
    echo "  [SKIP] Rust $(rustc --version) 已存在"
fi

# ============================================================
# Phase 4: Docker（可选）
# ============================================================
echo "[Phase 4] 安装 Docker..."

if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
    echo "  [OK] Docker 安装完成"
else
    echo "  [SKIP] Docker 已存在"
fi

# ============================================================
# Phase 5: Ollama 推理引擎
# ============================================================
echo "[Phase 5] 安装 Ollama..."

if ! command -v ollama &>/dev/null; then
    curl -fsSL https://ollama.com/install.sh | bash

    # 配置监听所有接口（供局域网或公网连接）
    mkdir -p /etc/systemd/system/ollama.service.d
    cat > /etc/systemd/system/ollama.service.d/override.conf << 'OLLAMA_EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_KEEP_ALIVE=24h"
OLLAMA_EOF

    systemctl daemon-reload
    systemctl restart ollama
    systemctl enable ollama
    echo "  [OK] Ollama 安装完成"
else
    echo "  [SKIP] Ollama 已存在"
fi

# 后台拉取小模型（不阻塞主线流程）
nohup ollama pull "$OLLAMA_MODEL" > /var/log/ollama-pull.log 2>&1 &
echo "  [OK] Ollama 模型 $OLLAMA_MODEL 拉取中（后台 PID: $!）"

# ============================================================
# Phase 6: 克隆 OpenHuman 项目
# ============================================================
echo "[Phase 6] 克隆 OpenHuman 项目..."

mkdir -p "$OPENHUMAN_DIR"
cd "$OPENHUMAN_DIR"

if [ ! -d ".git" ]; then
    git clone "$REPO_URL" "$OPENHUMAN_DIR" 2>/dev/null || {
        echo "  [WARN] 克隆失败，尝试浅克隆..."
        git clone --depth 1 "$REPO_URL" "$OPENHUMAN_DIR"
    }

    # 更新子模块
    echo "  [INFO] 更新子模块（首次较慢，后台执行）..."
    nohup git submodule update --init --recursive > /var/log/submodule.log 2>&1 &
    echo "  [OK] OpenHuman 项目克隆完成（子模块后台拉取中）"
else
    echo "  [SKIP] OpenHuman 项目已存在"
fi

# 后台执行 pnpm install
if [ -f "package.json" ]; then
    echo "  [INFO] pnpm install 后台执行..."
    nohup pnpm install > /var/log/pnpm-install.log 2>&1 &
fi

# ============================================================
# Phase 7: 输出摘要
# ============================================================
PRIVATE_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "获取失败")

echo ""
echo "============================================"
echo "  OpenHuman 云端开发环境 — 部署完成"
echo "============================================"
echo "  部署时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  SSH 访问: ssh root@${PUBLIC_IP}"
echo "  ECS 内网: ${PRIVATE_IP}"
echo "  项目目录: ${OPENHUMAN_DIR}"
echo "  Ollama API: http://${PUBLIC_IP}:11434"
echo "  Ollama 模型: ${OLLAMA_MODEL}"
echo ""
echo "  已安装运行环境:"
echo "    Node.js:  $(node --version 2>/dev/null || echo 'N/A')"
echo "    pnpm:     $(pnpm --version 2>/dev/null || echo 'N/A')"
echo "    Rust:     $(rustc --version 2>/dev/null || echo 'N/A')"
echo "    Docker:   $(docker --version 2>/dev/null || echo 'N/A')"
echo "    Ollama:   $(ollama --version 2>/dev/null || echo 'N/A')"
echo ""
echo "  开发命令:"
echo "    SSH 连接:   ssh root@${PUBLIC_IP}"
echo "    进入项目:   cd ${OPENHUMAN_DIR}"
echo "    安装依赖:   pnpm install"
echo "    启动开发:   pnpm dev"
echo "    构建:       pnpm build"
echo ""
echo "  日志文件:"
echo "    安装日志:   tail -f ${LOG_FILE}"
echo "    pnpm:       tail -f /var/log/pnpm-install.log"
echo "    Ollama:     tail -f /var/log/ollama-pull.log"
echo "    子模块:     tail -f /var/log/submodule.log"
echo ""
echo "  注意事项:"
echo "  1. OpenHuman 是桌面应用，此环境为开发工作站"
echo "  2. SSH 进入后执行 pnpm dev 启动 Web UI 开发模式"
echo "  3. Ollama API 可直接供 OpenHuman 桌面端连接"
echo "  4. 安全组已开放 22(SSH) 和 11434(Ollama API)"
echo "============================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===== Setup Completed ====="
