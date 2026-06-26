#!/bin/bash
set -euo pipefail

LOG="/var/log/litellm-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] Bootstrap: start"

# ===== Stage 1: Install Docker CE (official registry) =====
echo "[$(date)] Stage 1/4: Install Docker CE..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-compose-plugin
echo "[$(date)] Docker installed: $(docker --version)"

# ===== Stage 2: Generate config files =====
echo "[$(date)] Stage 2/4: Generate config files..."
LITELLM_DIR="/opt/litellm"
mkdir -p "$LITELLM_DIR/volumes/db/data" "$LITELLM_DIR/volumes/prometheus/data"
cd "$LITELLM_DIR"

# Parameters: db_password, master_key, salt_key
DB_PASSWORD="${1?Usage: install_litellm.sh <db_password> <master_key> [salt_key]}"
MASTER_KEY="${2?Usage: install_litellm.sh <db_password> <master_key> [salt_key]}"
SALT_KEY="${3:-$(openssl rand -base64 32 2>/dev/null || echo 'litellm-salt-key-default')}"

# .env
cat > .env << ENVEOF
POSTGRES_PASSWORD=${DB_PASSWORD}
LITELLM_MASTER_KEY=${MASTER_KEY}
LITELLM_SALT_KEY=${SALT_KEY}
DATABASE_URL=postgresql://llmproxy:${DB_PASSWORD}@db:5432/litellm
STORE_MODEL_IN_DB=True
# Add provider API keys below:
# OPENAI_API_KEY=sk-xxx
# ANTHROPIC_API_KEY=sk-ant-xxx
ENVEOF

# config.yaml
cat > config.yaml << 'CFGEOF'
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY
  - model_name: gpt-4o-mini
    litellm_params:
      model: openai/gpt-4o-mini
      api_key: os.environ/OPENAI_API_KEY
  - model_name: claude-sonnet-4-20250514
    litellm_params:
      model: anthropic/claude-sonnet-4-20250514
      api_key: os.environ/ANTHROPIC_API_KEY
  - model_name: "*"
    litellm_params:
      model: "*"
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: os.environ/DATABASE_URL
litellm_settings:
  ssl_verify: false
  num_retries: 3
  request_timeout: 600
CFGEOF

# docker-compose.yaml
cat > docker-compose.yaml << 'COMPOSEEOF'
services:
  litellm:
    image: ghcr.io/berriai/litellm-database:main-stable
    container_name: litellm-proxy
    restart: unless-stopped
    ports:
      - "4000:4000/tcp"
    command:
      - "--config=/app/config.yaml"
    environment:
      DATABASE_URL: "postgresql://llmproxy:${POSTGRES_PASSWORD}@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
      LITELLM_MASTER_KEY: ${LITELLM_MASTER_KEY}
      LITELLM_SALT_KEY: ${LITELLM_SALT_KEY}
    env_file:
      - .env
    volumes:
      - ./config.yaml:/app/config.yaml:ro
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')\""]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
  db:
    image: postgres:16
    container_name: litellm-db
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: litellm
      POSTGRES_USER: llmproxy
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./volumes/db/data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d litellm -U llmproxy"]
      interval: 10s
      timeout: 5s
      retries: 10
  prometheus:
    image: prom/prometheus:v2.53.0
    container_name: litellm-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090/tcp"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--storage.tsdb.retention.time=15d"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./volumes/prometheus/data:/prometheus
    depends_on:
      - litellm
COMPOSEEOF

# prometheus.yml
cat > prometheus.yml << 'PROMEOF'
scrape_configs:
  - job_name: 'litellm'
    scrape_interval: 15s
    static_configs:
      - targets: ['litellm:4000']
PROMEOF

echo "[$(date)] Config files generated"

# ===== Stage 3: Deploy containers =====
echo "[$(date)] Stage 3/4: Deploy containers..."
cd "$LITELLM_DIR"

MAX_RETRIES=5
COUNT=0
deploy_ok=0
until [ $COUNT -ge $MAX_RETRIES ]; do
  docker compose pull 2>&1 && docker compose up -d 2>&1 && deploy_ok=1 && break
  COUNT=$((COUNT+1))
  echo "[$(date)] Retry $COUNT/$MAX_RETRIES in 30s..."
  sleep 30
done

if [ $deploy_ok -eq 0 ]; then
  echo "[FATAL] Deploy failed after $MAX_RETRIES attempts"
  docker compose logs --tail=50 2>&1 || true
  exit 1
fi
echo "[$(date)] Containers started"

# ===== Stage 3.5: DB init check =====
echo "[$(date)] Database init check..."
for i in $(seq 1 30); do
  docker exec litellm-db pg_isready -U llmproxy -q 2>/dev/null && break
  sleep 2
done
DB_EXISTS=$(docker exec litellm-db psql -U llmproxy -t -A -c "SELECT 1 FROM pg_database WHERE datname='litellm';" 2>/dev/null || echo "0")
if [ "$DB_EXISTS" != "1" ]; then
  echo "[INFO] Creating litellm database..."
  docker exec litellm-db psql -U llmproxy -c "CREATE DATABASE litellm;" 2>/dev/null || true
fi
echo "[$(date)] Database ready"

# ===== Stage 4: Health check =====
echo "[$(date)] Stage 4/4: Health check..."
sleep 15
echo "--- Container status ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "--- LiteLLM health ---"
for i in $(seq 1 12); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:4000/health/liveliness 2>/dev/null || echo "000")
  [ "$HTTP_CODE" = "200" ] && echo "[$(date)] LiteLLM healthy (HTTP 200)" && break
  echo "[$(date)] Waiting... (attempt $i/12, HTTP $HTTP_CODE)"
  sleep 10
done

# Summary
echo ""
echo "====================================================="
echo " LiteLLM Deployment Complete"
echo "====================================================="
echo " Admin UI:   http://<EIP>:4000/ui"
echo " API:        http://<EIP>:4000/v1/chat/completions"
echo " Prometheus: http://<EIP>:9090"
echo " Config:     /opt/litellm/"
echo " Logs:       /var/log/litellm-bootstrap.log"
echo "====================================================="
echo "[$(date)] Bootstrap: done"
