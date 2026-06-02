#!/bin/bash
# ================================================
# Supabase — 开源 Firebase 替代品 部署脚本
# 模式: Docker Compose + SWR 镜像加速
# 适用环境: Ubuntu 24.04 / Huawei Cloud ECS
# 用法: bash install_supabase.sh <db_password> <jwt_secret>
#   db_password: PostgreSQL 密码（必填，同时作为所有 DB 角色密码）
#   jwt_secret:  JWT 密钥（可选，不传则自动生成）
# ================================================

set -euo pipefail

APP="supabase"
LOG_DIR="/var/log/${APP}-deploy"
mkdir -p "$LOG_DIR"
RUN_LOG="${LOG_DIR}/run-all.log"
exec > >(tee -a "$RUN_LOG") 2>&1

echo "========================================="
echo "[$(date)] Supabase deploy START"
echo "========================================="

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

OBS_BASE="https://tp-00940108.obs.cn-south-1.myhuaweicloud.com"
SUPABASE_DIR="/opt/supabase"

# 参数：db_password jwt_secret
DB_PASSWORD="${1:?Usage: install_supabase.sh <db_password> [jwt_secret]}"
JWT_SECRET="${2:-$(openssl rand -base64 32 2>/dev/null || echo 'change-me-secret-key')}"
SECRET_KEY_BASE="$(openssl rand -base64 32 2>/dev/null || echo 'supabase-secret-key-base')"

# ANON_KEY 和 SERVICE_ROLE_KEY 基于 JWT_SECRET 生成固定测试密钥
# 生产环境建议替换
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTAyNzN9.CRXP1A7WOeoJeXxjNni43kdEDwNnnP7IGiD1k3ivLc0"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMDI3M30.sQTxYmZxLJmhFIVwYl_cfMZMZNmrUIMmF8v3Rj7obI0"

# ============ Stage 1: 安装 Docker CE ============
echo "[$(date)][STAGE 1/4] Install Docker CE..."
exec > >(tee -a "${LOG_DIR}/01-docker.log") 2>&1

dpkg --configure -a 2>/dev/null || true
apt-get $APT_OPTS update
apt-get $APT_OPTS install ca-certificates curl gnupg lsb-release

# 从华为云镜像安装 Docker CE（国内 ECS 加速）
curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get $APT_OPTS update
apt-get $APT_OPTS install docker-ce docker-compose-plugin

# SWR 登录（同区域 ECS 内网拉取镜像）
docker login -u cn-north-4@HPUALBI1EVWBSTTGUVLR -p 280586e790351984803be55526f3b4abda214f4bf4726ea9306d293da2d74fd7 swr.cn-north-4.myhuaweicloud.com 2>&1
echo "[OK] Stage 1 complete"

# ============ Stage 2: 生成 .env 配置文件 ============
echo "[$(date)][STAGE 2/4] Generate .env config..."
exec > >(tee -a "${LOG_DIR}/02-env.log") 2>&1

cd "$SUPABASE_DIR"

cat > .env << ENVEOF
# Supabase 环境配置（由部署脚本自动生成）
POSTGRES_PASSWORD=${DB_PASSWORD}
JWT_SECRET=${JWT_SECRET}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
APP_NAME=supabase
ANON_KEY=${ANON_KEY}
SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}
ENVEOF

# 验证关键文件
for f in docker-compose.yaml volumes/api/kong.yml; do
  if [ ! -f "$f" ]; then
    echo "[FATAL] Missing required file: $f"
    exit 1
  fi
done
echo "[OK] .env generated, all files verified"
echo "[OK] Stage 2 complete"

# ============ Stage 3: 部署容器 ============
echo "[$(date)][STAGE 3/4] Deploy containers..."
exec > >(tee -a "${LOG_DIR}/03-deploy.log") 2>&1

cd "$SUPABASE_DIR"

# 拉取镜像 + 启动（Hermes 风格的重试机制）
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
echo "[$(date)][STAGE 3.5/4] Database init..."
exec > >(tee -a "${LOG_DIR}/03-db-init.log") 2>&1

echo "Waiting for DB to be healthy..."
for i in $(seq 1 30); do
  docker exec supabase-db pg_isready -U postgres -q 2>/dev/null && break
  sleep 2
done

# 检查 service 角色是否有密码
HAS_PW=$(docker exec supabase-db psql -U postgres -t -A -c \
  "SELECT count(*) FROM pg_shadow WHERE usename IN ('authenticator','supabase_auth_admin','supabase_storage_admin') AND passwd IS NOT NULL;" 2>/dev/null || echo "0")

if [ "$HAS_PW" != "3" ]; then
  echo "[INFO] Setting up database roles and schemas..."

  # 创建 supabase 数据库
  docker exec supabase-db psql -U postgres -c "CREATE DATABASE supabase;" 2>/dev/null || true

  # 设置 service 角色密码（只能用 supabase_admin，普通用户无权限）
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d postgres -c "ALTER USER authenticator WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d postgres -c "ALTER USER supabase_auth_admin WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d postgres -c "ALTER USER supabase_storage_admin WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true

  # 创建所需 schema
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d supabase -c "CREATE SCHEMA IF NOT EXISTS auth;" 2>/dev/null || true
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d supabase -c "CREATE SCHEMA IF NOT EXISTS storage;" 2>/dev/null || true
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d supabase -c "CREATE SCHEMA IF NOT EXISTS _realtime;" 2>/dev/null || true
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d supabase -c "CREATE SCHEMA IF NOT EXISTS graphql_public;" 2>/dev/null || true

  # 重启依赖 DB 的容器使新密码生效
  docker compose restart auth rest storage realtime 2>/dev/null || true
  echo "[OK] Database initialized"
else
  echo "[OK] Database already initialized"
fi
echo "[OK] Stage 3.5 complete"

# ============ Stage 4: 健康检查 ============
echo "[$(date)][STAGE 4/4] Health check..."
exec > >(tee -a "${LOG_DIR}/04-health.log") 2>&1

sleep 15

echo "--- Container status ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "--- Kong health check ---"
curl -sS --connect-timeout 5 http://localhost:8000/ 2>&1 | head -3 || echo "Kong not ready yet"

echo "--- Studio health check ---"
curl -sS --connect-timeout 5 http://localhost:8000/project/default 2>&1 | head -3 || echo "Studio not ready yet (may need more time)"

echo "--- PostgREST check ---"
curl -sS --connect-timeout 5 http://localhost:8000/rest/v1/ 2>&1 | head -3 || echo "PostgREST not ready yet"

echo "[OK] Stage 4 complete"

# ============ Summary ============
EIP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "<EIP>")

echo ""
echo "========================================="
echo "[$(date)] Supabase deploy COMPLETE"
echo "========================================="
echo ""
echo "  架构: 1 x Flexus X 实例"
echo "  服务: Kong + PostgreSQL + GoTrue + PostgREST + Realtime + Storage + Studio"
echo ""
echo "  访问地址:"
echo "    Dashboard:  http://${EIP}:8000/project/default"
echo "    REST API:   http://${EIP}:8000/rest/v1/"
echo "    Auth API:   http://${EIP}:8000/auth/v1/"
echo "    Storage:    http://${EIP}:8000/storage/v1/"
echo ""
echo "  默认凭证:"
echo "    anon key:        $(grep ANON_KEY .env 2>/dev/null | cut -d= -f2 || echo 'see .env')"
echo "    service_role key: $(grep SERVICE_ROLE_KEY .env 2>/dev/null | cut -d= -f2 || echo 'see .env')"
echo ""
echo "  使用前: 替换 JWT_SECRET 和 POSTGRES_PASSWORD"
echo "    vi /opt/supabase/.env && docker compose restart"
echo ""
echo "  部署日志: ${LOG_DIR}/"
echo "    ├── 01-docker.log"
echo "    ├── 02-download.log"
echo "    ├── 03-deploy.log"
echo "    └── 04-health.log"
echo ""
echo "========================================="
