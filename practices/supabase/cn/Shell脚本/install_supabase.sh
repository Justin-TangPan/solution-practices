#!/bin/bash
set -e

LOG="/var/log/supabase-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] Bootstrap: start"

# ===== Stage 1: 安装 Docker CE（华为云镜像源） =====
echo "[$(date)] 安装 Docker CE..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-compose-plugin
echo "[$(date)] Docker 安装完成: $(docker --version)"

# ===== Stage 2: 下载配置并生成 .env =====
echo "[$(date)] 下载 Supabase 配置..."
mkdir -p /opt/supabase/volumes/api /opt/supabase/volumes/db
cd /opt/supabase

OBS_BASE="${OBS_BASE_URL:-https://tp-00940108.obs.cn-south-1.myhuaweicloud.com}/supabase"
wget -q "$OBS_BASE/docker-compose.yaml" -O docker-compose.yaml
wget -q "$OBS_BASE/kong.yml" -O volumes/api/kong.yml

# 参数：db_password jwt_secret
DB_PASSWORD="${1?Usage: install_supabase.sh <db_password> [jwt_secret]}"
JWT_SECRET="${2:-$(openssl rand -base64 32 2>/dev/null || echo 'change-me-secret-key')}"
SECRET_KEY_BASE="$(openssl rand -base64 32 2>/dev/null || echo 'supabase-secret-key-base')"

cat > .env << ENVEOF
# Supabase 环境配置（由部署脚本自动生成）
POSTGRES_PASSWORD=${DB_PASSWORD}
JWT_SECRET=${JWT_SECRET}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
APP_NAME=supabase
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTAyNzN9.CRXP1A7WOeoJeXxjNni43kdEDwNnnP7IGiD1k3ivLc0
SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMDI3M30.sQTxYmZxLJmhFIVwYl_cfMZMZNmrUIMmF8v3Rj7obI0
ENVEOF

# ===== Stage 3: 部署容器 =====
echo "[$(date)] 部署 Supabase..."
cd /opt/supabase

MAX_RETRIES=5
COUNT=0
deploy_ok=0
until [ $COUNT -ge $MAX_RETRIES ]; do
  docker compose pull 2>&1 && docker compose up -d 2>&1 && deploy_ok=1 && break
  COUNT=$((COUNT+1))
  echo "[$(date)] 拉取/启动失败 (尝试 $COUNT/$MAX_RETRIES)，30秒后重试..."
  sleep 30
done

if [ $deploy_ok -eq 0 ]; then
  echo "[FATAL] 部署失败，请查看日志"
  docker compose logs --tail=50 2>&1 || true
  exit 1
fi
echo "[$(date)] 容器启动完成"

# ===== Stage 3.5: DB 初始化 =====
echo "[$(date)] 等待 DB 就绪..."
for i in $(seq 1 30); do
  docker exec supabase-db pg_isready -U postgres -q 2>/dev/null && break
  sleep 2
done

HAS_PW=$(docker exec supabase-db psql -U postgres -t -A -c \
  "SELECT count(*) FROM pg_shadow WHERE usename IN ('authenticator','supabase_auth_admin','supabase_storage_admin') AND passwd IS NOT NULL;" 2>/dev/null || echo "0")

if [ "$HAS_PW" != "3" ]; then
  echo "[INFO] 初始化数据库角色和 schema..."
  docker exec supabase-db psql -U postgres -c "CREATE DATABASE supabase;" 2>/dev/null || true
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d postgres -c "ALTER USER authenticator WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d postgres -c "ALTER USER supabase_auth_admin WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
  docker exec -e PGPASSWORD=$DB_PASSWORD supabase-db psql -U supabase_admin -h localhost \
    -d postgres -c "ALTER USER supabase_storage_admin WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
  docker compose restart auth rest storage realtime 2>/dev/null || true
  echo "[OK] 数据库初始化完成"
fi

# ===== Stage 4: 健康检查 =====
echo "[$(date)] 健康检查..."
sleep 15
echo "--- 容器状态 ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "--- Dashboard 检查 ---"
curl -sS --connect-timeout 5 http://localhost:8000/project/default 2>&1 | head -3 || echo "Dashboard 未就绪（可能需要更多时间）"
echo "[$(date)] Bootstrap: 完成"
echo ""
echo "====================================================="
echo " Dashboard: http://YOUR_EIP:8000/project/default"
echo " 日志: /var/log/supabase-deploy/"
echo " 配置: /opt/supabase/"
echo "====================================================="
