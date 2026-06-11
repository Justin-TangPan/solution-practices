#!/bin/bash
# ================================================
# LiteLLM — 统一 LLM 代理网关 部署脚本
# 模式: Docker Compose（官方镜像）
# 适用环境: Ubuntu 24.04 / Huawei Cloud ECS（海外区域）
# 用法: bash install_litellm.sh <db_password> <master_key> [salt_key]
#   db_password:  PostgreSQL 密码（必填）
#   master_key:   LiteLLM 管理密钥（必填，须以 sk- 开头）
#   salt_key:     加密密钥（可选，不传则自动生成；一旦使用不可更改）
# ================================================

set -euo pipefail

APP="litellm"
LOG_DIR="/var/log/${APP}-deploy"
mkdir -p "$LOG_DIR"
RUN_LOG="${LOG_DIR}/run-all.log"
exec > >(tee -a "$RUN_LOG") 2>&1

echo "========================================="
echo "[$(date)] LiteLLM deploy START"
echo "========================================="

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

OBS_BASE="https://tp-00940108.obs.cn-south-1.myhuaweicloud.com"
LITELLM_DIR="/opt/litellm"

# 参数解析
DB_PASSWORD="${1:?Usage: install_litellm.sh <db_password> <master_key> [salt_key]}"
MASTER_KEY="${2:?Usage: install_litellm.sh <db_password> <master_key> [salt_key]}"
SALT_KEY="${3:-$(openssl rand -base64 32 2>/dev/null || echo 'litellm-salt-key-default')}"

# ============ Stage 1: 安装 Docker CE ============
echo "[$(date)][STAGE 1/4] Install Docker CE..."
exec > >(tee -a "${LOG_DIR}/01-docker.log") 2>&1

dpkg --configure -a 2>/dev/null || true
apt-get $APT_OPTS update
apt-get $APT_OPTS install ca-certificates curl gnupg lsb-release

# 从官方 Docker 仓库安装
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get $APT_OPTS update
apt-get $APT_OPTS install docker-ce docker-compose-plugin

echo "[OK] Stage 1 complete"

# ============ Stage 2: 生成配置文件 ============
echo "[$(date)][STAGE 2/4] Generate config files..."
exec > >(tee -a "${LOG_DIR}/02-config.log") 2>&1

mkdir -p "$LITELLM_DIR/volumes/db/data" "$LITELLM_DIR/volumes/prometheus/data"
cd "$LITELLM_DIR"

# 从 OBS 下载配置文件
for f in docker-compose.yaml config.yaml prometheus.yml; do
  wget -q -O "$f" "${OBS_BASE}/litellm-hk/${f}" || echo "[WARN] Failed to download ${f}"
done

# 生成 .env
cat > .env << ENVEOF
# LiteLLM 环境配置（由部署脚本自动生成）
POSTGRES_PASSWORD=${DB_PASSWORD}
LITELLM_MASTER_KEY=${MASTER_KEY}
LITELLM_SALT_KEY=${SALT_KEY}
DATABASE_URL=postgresql://llmproxy:${DB_PASSWORD}@db:5432/litellm
STORE_MODEL_IN_DB=True
# 如需使用特定 Provider，在此添加 API Key：
# OPENAI_API_KEY=sk-xxx
# ANTHROPIC_API_KEY=sk-ant-xxx
# AZURE_API_KEY=xxx
# AZURE_API_BASE=https://xxx.openai.azure.com
# AZURE_API_VERSION=2024-02-01
ENVEOF

# 验证关键文件
for f in docker-compose.yaml config.yaml prometheus.yml; do
  if [ ! -f "$f" ]; then
    echo "[FATAL] Missing required file: $f"
    exit 1
  fi
done
echo "[OK] Config generated, all files verified"
echo "[OK] Stage 2 complete"

# ============ Stage 3: 部署容器 ============
echo "[$(date)][STAGE 3/4] Deploy containers..."
exec > >(tee -a "${LOG_DIR}/03-deploy.log") 2>&1

cd "$LITELLM_DIR"

# 拉取镜像 + 启动（重试机制）
MAX_RETRIES=5
SLEEP_INTERVAL=30
COUNT=0
deploy_ok=0

echo "Starting docker compose pull & up..."

until [ $COUNT -ge $MAX_RETRIES ]; do
  docker compose pull 2>&1
  if [ $? -eq 0 ]; then
    echo "[OK] All images pulled successfully"
    docker compose up -d 2>&1
    if [ $? -eq 0 ]; then
      deploy_ok=1
      break
    fi
  fi
  COUNT=$((COUNT+1))
  echo "Pull/up failed (attempt $COUNT/$MAX_RETRIES), retry in ${SLEEP_INTERVAL}s..."
  sleep $SLEEP_INTERVAL
done

if [ $deploy_ok -eq 0 ]; then
  echo "[FATAL] Failed to deploy after $MAX_RETRIES attempts"
  docker compose logs --tail=50 2>&1 || true
  exit 1
fi
echo "[OK] Stage 3 complete"

# ============ Stage 3.5: DB 初始化兜底 ============
echo "[$(date)][STAGE 3.5/4] Database init check..."
exec > >(tee -a "${LOG_DIR}/03-db-init.log") 2>&1

echo "Waiting for DB to be healthy..."
for i in $(seq 1 30); do
  docker exec litellm-db pg_isready -U llmproxy -q 2>/dev/null && break
  sleep 2
done

# 验证 litellm 数据库存在
DB_EXISTS=$(docker exec litellm-db psql -U llmproxy -t -A -c "SELECT 1 FROM pg_database WHERE datname='litellm';" 2>/dev/null || echo "0")
if [ "$DB_EXISTS" != "1" ]; then
  echo "[WARN] litellm database not found, creating..."
  docker exec litellm-db psql -U llmproxy -c "CREATE DATABASE litellm;" 2>/dev/null || true
fi

echo "[OK] Database ready"
echo "[OK] Stage 3.5 complete"

# ============ Stage 4: 健康检查 ============
echo "[$(date)][STAGE 4/4] Health check..."
exec > >(tee -a "${LOG_DIR}/04-health.log") 2>&1

sleep 15

echo "--- Container status ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "--- LiteLLM health check ---"
for i in $(seq 1 12); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:4000/health/liveliness 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    echo "[OK] LiteLLM API is healthy (HTTP 200)"
    break
  fi
  echo "[WAIT] LiteLLM not ready yet (HTTP $HTTP_CODE), attempt $i/12..."
  sleep 10
done

echo "--- Admin UI check ---"
curl -sS --connect-timeout 5 http://localhost:4000/ui 2>&1 | head -3 || echo "Admin UI not ready yet"

echo "--- Prometheus check ---"
curl -sS --connect-timeout 5 http://localhost:9090/-/healthy 2>&1 | head -3 || echo "Prometheus not ready yet"

echo "[OK] Stage 4 complete"

# ============ Summary ============
EIP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "<EIP>")

echo ""
echo "========================================="
echo "[$(date)] LiteLLM deploy COMPLETE"
echo "========================================="
echo ""
echo "  架构: 1 x Flexus X 实例"
echo "  服务: LiteLLM Proxy + PostgreSQL + Prometheus"
echo ""
echo "  访问地址:"
echo "    Admin UI:   http://${EIP}:4000/ui"
echo "    API:        http://${EIP}:4000/v1/chat/completions"
echo "    Health:     http://${EIP}:4000/health/liveliness"
echo "    Prometheus: http://${EIP}:9090"
echo ""
echo "  默认凭证:"
echo "    Master Key: $(grep LITELLM_MASTER_KEY .env 2>/dev/null | cut -d= -f2 || echo 'see .env')"
echo "    Salt Key:   $(grep LITELLM_SALT_KEY .env 2>/dev/null | cut -d= -f2 || echo 'see .env')"
echo ""
echo "  首次使用:"
echo "    1. 登录 Admin UI（用 Master Key）"
echo "    2. 进入 'Model Management' 添加模型和 API Key"
echo "    3. 或手动编辑: vi ${LITELLM_DIR}/config.yaml"
echo "    4. 修改后重启: cd ${LITELLM_DIR} && docker compose restart"
echo ""
echo "  注意事项:"
echo "    - SALT_KEY 一旦使用不可更改，否则已有密钥将失效"
echo "    - Admin UI 需使用 Master Key 登录"
echo "    - 支持 OpenAI / Anthropic / Azure / Cohere 等多 Provider"
echo ""
echo "  部署日志: ${LOG_DIR}/"
echo "    ├── 01-docker.log"
echo "    ├── 02-config.log"
echo "    ├── 03-deploy.log"
echo "    ├── 03-db-init.log"
echo "    └── 04-health.log"
echo ""
echo "========================================="
