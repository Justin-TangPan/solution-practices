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

# ===== Stage 2: Install Node.js 18+ & OpenCode =====
echo "[$(date)] Installing Node.js 18..."
curl -fsSL https://mirrors.huaweicloud.com/nodejs/v18.x/node_18.x.pub | gpg --dearmor -o /usr/share/keyrings/nodejs.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/nodejs.gpg] https://mirrors.huaweicloud.com/nodejs/v18.x $(lsb_release -cs) main" > /etc/apt/sources.list.d/nodesource.list
apt-get update -y
apt-get install -y nodejs
echo "[$(date)] Node.js installed: $(node --version)"

echo "[$(date)] Installing OpenCode..."
npm config set registry https://registry.npmmirror.com
npm install -g opencode-ai@latest
echo "[$(date)] OpenCode installed: $(opencode --version 2>/dev/null || echo 'installed')"

# ===== Stage 3: Install Headroom & Start Proxy =====
echo "[$(date)] Installing Headroom..."
pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers \
  -i https://pypi.tuna.tsinghua.edu.cn/simple \
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

# ===== Stage 4: Configure Environment & OpenCode =====
echo "[$(date)] Configuring environment..."
cat >> /root/.bashrc << 'ENVEOF'

# --- Headroom + OpenCode ---
# Replace with your actual MaaS API Key:
# export ANTHROPIC_AUTH_TOKEN="your-maas-api-key"
export ANTHROPIC_BASE_URL="http://localhost:8787"
export ANTHROPIC_TARGET_API_URL="https://api.modelarts-maas.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v3.2"
ENVEOF

echo "[$(date)] Creating OpenCode configuration..."
mkdir -p /root/.config/opencode
cat > /root/.config/opencode/opencode.json << 'OCEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "anthropic": {
      "options": {
        "baseURL": "http://localhost:8787",
        "apiKey": "{env:ANTHROPIC_AUTH_TOKEN}"
      }
    }
  },
  "model": "deepseek-v3.2"
}
OCEOF

# Also create a project-level config template
mkdir -p /root/opencode-project
cat > /root/opencode-project/opencode.json << 'OCEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "anthropic": {
      "options": {
        "baseURL": "http://localhost:8787",
        "apiKey": "{env:ANTHROPIC_AUTH_TOKEN}"
      }
    }
  },
  "model": "deepseek-v3.2"
}
OCEOF

# ===== Stage 5: Verify =====
echo "--- Verification ---"
echo "Headroom proxy: $(curl -sf http://localhost:8787/readyz && echo 'OK' || echo 'FAILED')"
echo "OpenCode CLI: $(opencode --version 2>/dev/null || echo 'installed')"
echo "Headroom CLI: $(headroom --version 2>/dev/null || echo 'installed')"
echo "OpenCode config: $(test -f /root/.config/opencode/opencode.json && echo 'OK' || echo 'MISSING')"
echo "[$(date)] Bootstrap: done"
echo ""
echo "====================================================="
echo " NEXT STEPS (after SSH into this ECS):"
echo " 1. Set your MaaS API Key:"
echo "    export ANTHROPIC_AUTH_TOKEN='your-key'"
echo " 2. Start OpenCode:"
echo "    opencode"
echo " 3. Check token savings:"
echo "    curl http://localhost:8787/stats"
echo "====================================================="
