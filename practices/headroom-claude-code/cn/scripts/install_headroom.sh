#!/bin/bash
set -e

LOG="/var/log/headroom-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] Bootstrap: start"

# ===== Stage 1: 安装依赖 =====
echo "[$(date)] 安装依赖..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl python3-pip build-essential

# ===== Stage 2: 安装 Node.js 18+ & Claude Code =====
echo "[$(date)] 安装 Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
echo "[$(date)] Node.js 安装完成: $(node --version)"

echo "[$(date)] 安装 Claude Code..."
npm install -g @anthropic-ai/claude-code
echo "[$(date)] Claude Code 安装完成"

# ===== Stage 3: 安装 Headroom & 启动代理 =====
echo "[$(date)] 安装 Headroom..."
pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers \
  -i https://pypi.tuna.tsinghua.edu.cn/simple \
  --break-system-packages --ignore-installed
echo "[$(date)] Headroom 安装完成: $(headroom --version 2>/dev/null || echo 'installed')"

echo "[$(date)] 启动 Headroom 代理（后台运行）..."
export ANTHROPIC_TARGET_API_URL=https://api.modelarts-maas.com/anthropic
nohup headroom proxy --host 0.0.0.0 --port 8787 > /var/log/headroom-proxy.log 2>&1 &
sleep 10
for i in $(seq 1 12); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:8787/readyz 2>/dev/null || echo "000")
  [ "$HTTP_CODE" = "200" ] && echo "[$(date)] Headroom 代理就绪 (HTTP 200)" && break
  echo "[$(date)] 等待中... (尝试 $i/12, HTTP $HTTP_CODE)"
  sleep 5
done

# ===== Stage 4: 配置环境变量 =====
echo "[$(date)] 配置环境变量..."
cat >> /root/.bashrc << 'ENVEOF'

# --- Headroom + Claude Code ---
# 请替换为您的 MaaS API Key：
# export ANTHROPIC_AUTH_TOKEN="your-maas-api-key"
export ANTHROPIC_BASE_URL="http://localhost:8787"
export ANTHROPIC_TARGET_API_URL="https://api.modelarts-maas.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v3.2"
ENVEOF

# ===== Stage 5: 验证 =====
echo "--- 验证 ---"
echo "Headroom 代理: $(curl -sf http://localhost:8787/readyz && echo '正常' || echo '异常')"
echo "Claude Code: $(claude --version 2>/dev/null || echo '已安装')"
echo "Headroom CLI: $(headroom --version 2>/dev/null || echo '已安装')"
echo "[$(date)] Bootstrap: 完成"
echo ""
echo "====================================================="
echo " 后续步骤（SSH 登录后执行）："
echo " 1. 设置 MaaS API Key："
echo "    export ANTHROPIC_AUTH_TOKEN='your-key'"
echo " 2. 启动 Claude Code："
echo "    claude"
echo " 3. 查看 Token 节省量："
echo "    curl http://localhost:8787/stats"
echo "====================================================="
