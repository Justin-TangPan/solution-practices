#!/bin/bash
set -e

LOG="/var/log/headroom-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] Bootstrap: start"

# ===== Stage 1: Install dependencies =====
echo "[$(date)] Installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl python3-pip build-essential

# ===== Stage 2: Install Node.js 18+ & Claude Code =====
echo "[$(date)] Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
echo "[$(date)] Node.js installed: $(node --version)"

echo "[$(date)] Installing Claude Code..."
npm install -g @anthropic-ai/claude-code
echo "[$(date)] Claude Code installed"

# ===== Stage 3: Install Headroom & Start Proxy =====
echo "[$(date)] Installing Headroom..."
pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers \
  --break-system-packages --ignore-installed
echo "[$(date)] Headroom installed: $(headroom --version 2>/dev/null || echo 'installed')"

echo "[$(date)] Starting Headroom proxy (background)..."
export ANTHROPIC_TARGET_API_URL=https://api.modelarts-maas.com/anthropic
nohup headroom proxy --host 0.0.0.0 --port 8787 > /var/log/headroom-proxy.log 2>&1 &
sleep 10
for i in $(seq 1 12); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:8787/readyz 2>/dev/null || echo "000")
  [ "$HTTP_CODE" = "200" ] && echo "[$(date)] Headroom proxy healthy (HTTP 200)" && break
  echo "[$(date)] Waiting... (attempt $i/12, HTTP $HTTP_CODE)"
  sleep 5
done

# ===== Stage 4: Configure Environment =====
echo "[$(date)] Configuring environment..."
cat >> /root/.bashrc << 'ENVEOF'

# --- Headroom + Claude Code ---
# Replace with your actual MaaS API Key:
# export ANTHROPIC_AUTH_TOKEN="your-maas-api-key"
export ANTHROPIC_BASE_URL="http://localhost:8787"
export ANTHROPIC_TARGET_API_URL="https://api.modelarts-maas.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v3.2"
ENVEOF

# ===== Stage 5: Verify =====
echo "--- Verification ---"
echo "Headroom proxy: $(curl -sf http://localhost:8787/readyz && echo 'OK' || echo 'FAILED')"
echo "Claude Code: $(claude --version 2>/dev/null || echo 'installed')"
echo "Headroom CLI: $(headroom --version 2>/dev/null || echo 'installed')"
echo "[$(date)] Bootstrap: done"
echo ""
echo "====================================================="
echo " NEXT STEPS (after SSH into this ECS):"
echo " 1. Set your MaaS API Key:"
echo "    export ANTHROPIC_AUTH_TOKEN='your-key'"
echo " 2. Start Claude Code:"
echo "    claude"
echo " 3. Check token savings:"
echo "    curl http://localhost:8787/stats"
echo "====================================================="
