#!/bin/bash
set -e

LOG="/var/log/aitoearn-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] Bootstrap: start"

# ===== Stage 1: Install Docker CE =====
echo "[$(date)] Installing Docker CE..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-compose-plugin
echo "[$(date)] Docker installed: $(docker --version)"

# ===== Stage 2: Clone project repository =====
echo "[$(date)] Cloning AiToEarn repository..."
cd /opt
rm -rf aitoearn
git clone --depth 1 https://github.com/yikart/AiToEarn.git aitoearn
cd /opt/aitoearn

# ===== Stage 3: Start services =====
echo "[$(date)] Starting AiToEarn..."
docker compose pull
docker compose up -d

echo "[$(date)] Waiting for services..."
sleep 30
for i in $(seq 1 20); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:8080 2>/dev/null || echo "000")
  [ "$HTTP_CODE" = "200" ] && echo "[$(date)] AiToEarn ready (HTTP 200)" && break
  echo "[$(date)] Waiting... (attempt $i/20, HTTP $HTTP_CODE)"
  sleep 15
done

# ===== Stage 4: Verify =====
echo "--- Verification ---"
echo "Web: $(curl -sf http://localhost:8080 > /dev/null && echo 'OK' || echo 'FAILED')"
echo "Containers: $(docker ps --format '{{.Names}}: {{.Status}}' | wc -l) running"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "[$(date)] Bootstrap: done"
echo ""
echo "====================================================="
echo " Access: http://YOUR_EIP:8080"
echo " Logs: /var/log/aitoearn-bootstrap.log"
echo " Config: /opt/aitoearn/"
echo "====================================================="
