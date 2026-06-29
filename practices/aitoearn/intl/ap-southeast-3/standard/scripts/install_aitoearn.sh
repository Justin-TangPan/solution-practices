#!/bin/bash
set -e

LOG="/var/log/aitoearn-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] Bootstrap: start"

# ===== Stage 1: Install Docker CE (official mirror) =====
echo "[$(date)] Installing Docker CE..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
chmod a+r /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-compose-plugin
echo "[$(date)] Docker installed: $(docker --version)"

# ===== Stage 2: Clone project repo =====
echo "[$(date)] Cloning AiToEarn repo..."
cd /opt
rm -rf aitoearn
git clone --depth 1 https://github.com/yikart/AiToEarn.git aitoearn
cd /opt/aitoearn

# ===== Stage 3: Replace images with SWR =====
echo "[$(date)] Replacing images with SWR..."
SWR_PREFIX="${SWR_REGISTRY:-swr.cn-north-4.myhuaweicloud.com}/sac"
sed -i "s|aitoearn/aitoearn-ai:latest|${SWR_PREFIX}/aitoearn-ai:latest|g" docker-compose.yml
sed -i "s|aitoearn/aitoearn-server:latest|${SWR_PREFIX}/aitoearn-server:latest|g" docker-compose.yml
sed -i "s|aitoearn/aitoearn-web:latest|${SWR_PREFIX}/aitoearn-web:latest|g" docker-compose.yml
sed -i "s|rustfs/rustfs:latest|${SWR_PREFIX}/rustfs:latest|g" docker-compose.yml

# ===== Stage 4: Start services =====
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

# ===== Stage 5: Verification =====
echo "--- Verification ---"
echo "Web: $(curl -sf http://localhost:8080 > /dev/null && echo 'OK' || echo 'Not ready')"
echo "Containers: $(docker ps --format '{{.Names}}: {{.Status}}' | wc -l) running"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "[$(date)] Bootstrap: complete"
echo ""
echo "====================================================="
echo " Access: http://YOUR_EIP:8080"
echo " Log: /var/log/aitoearn-bootstrap.log"
echo " Config: /opt/aitoearn/"
echo "====================================================="
