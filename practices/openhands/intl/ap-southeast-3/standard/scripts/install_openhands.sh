#!/bin/bash

LOGFILE="/var/log/openhands-install.log"
exec 1>"$LOGFILE" 2>&1
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

echo "========================================="
echo "[$(date)] OpenHands deploy START"
echo "========================================="

sleep 10

# Install Docker CE, docker compose (official source)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "" | sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "y" | apt-get -qq update
sleep 10
echo "y" | apt-get -qq install docker-ce docker-compose

# Configure Docker daemon (no mirror needed for international)
echo '{}' >/etc/docker/daemon.json
systemctl restart docker

# ============ Deploy OpenHands ============
mkdir -p /opt/openhands
cd /opt/openhands

cat > docker-compose.yaml << 'EOF'
services:
  openhands:
    image: docker.openhands.dev/openhands/openhands:latest
    container_name: openhands
    restart: unless-stopped
    stdin_open: true
    tty: true
    ports:
      - "3000:3000"
    environment:
      - AGENT_SERVER_IMAGE_REPOSITORY=ghcr.io/openhands/agent-server
      - AGENT_SERVER_IMAGE_TAG=1.19.1-python
      - LOG_ALL_EVENTS=true
      - TZ=Asia/Singapore
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/openhands/config:/.openhands
      - /opt/openhands/workspace:/workspace
      - /etc/localtime:/etc/localtime:ro
    extra_hosts:
      - "host.docker.internal:host-gateway"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

echo "[STEP] Pull OpenHands image..."
for i in 1 2 3; do
  docker pull docker.openhands.dev/openhands/openhands:latest 2>&1
  RC=$?
  if [ $RC -eq 0 ]; then
    echo "[OK] Image pulled"
    break
  fi
  echo "[RETRY] Pull failed ($i/3), retrying in 15s..."
  sleep 15
done

echo "[STEP] Start OpenHands..."
docker compose up -d 2>&1
sleep 5
docker ps -a --filter name=openhands --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Health check
echo "[STEP] Health check..."
HOST_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")
OK=0
for i in $(seq 1 12); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 2>/dev/null || echo "000")
  echo "[$i/12] HTTP $CODE"
  if echo "$CODE" | grep -qE "^(200|302|301)$"; then
    OK=1
    break
  fi
  sleep 5
done

echo "========================================="
if [ "$OK" -eq 1 ]; then
  echo "[$(date)] OpenHands deploy SUCCESS"
  echo "  URL: http://${HOST_IP}:3000"
else
  echo "[$(date)] OpenHands deploy COMPLETE (health check timeout)"
  echo "  Check: docker logs openhands --tail 30"
fi
echo "  EIP:      ${HOST_IP}"
echo "  Config:   /opt/openhands/"
echo "  Log:      $LOGFILE"
echo "========================================="
