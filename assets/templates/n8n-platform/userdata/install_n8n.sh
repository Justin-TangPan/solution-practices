#!/bin/bash
# ================================================
# n8n 工作流自动化平台 — 单机版部署脚本
# 用法: bash install_n8n.sh [n8n_version]
# 模式: 单脚本 (对齐 Hermes/Dify demo)
# ================================================
N8N_VERSION="${1:-latest}"

LOGFILE="/var/n8n-install.log"
exec 1>"$LOGFILE" 2>&1
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

echo "========================================="
echo "[$(date)] n8n deploy START, version=$N8N_VERSION"
echo "========================================="

# ============ 1. 系统初始化 ============
echo "[STEP] System prepare..."

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

# 修复残留 dpkg 配置，避免 sshd_config 等交互式卡死
dpkg --configure -a 2>/dev/null || true

apt-get $APT_OPTS update
apt-get $APT_OPTS install ca-certificates curl gnupg lsb-release cron tar software-properties-common
uname -a
df -h /
echo "[OK] System ready"

# ============ 2. 安装 Docker (华为云镜像，对齐 demo 模式) ============
echo "[STEP] Install Docker via Huawei Cloud mirror..."

# 使用华为云 Docker CE 镜像源 (与 Hermes/Dify demo 一致)
mkdir -p /usr/share/keyrings
curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get $APT_OPTS update
apt-get $APT_OPTS install docker-ce docker-compose
echo "[OK] Docker CE + compose installed"

# Docker 国内镜像加速 (华为云SWR + 1ms 高速镜像)
cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://b4a1f63a156e435f9aeb797bdf515250.mirror.swr.myhuaweicloud.com"
  ],
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF

systemctl daemon-reload
systemctl enable docker
systemctl restart docker
sleep 2
docker version | head -3
echo "[OK] Docker running"

# ============ 3. n8n 配置 ============
echo "[STEP] Setup n8n..."

N8N_HOME="/opt/n8n"
mkdir -p "$N8N_HOME/data" "$N8N_HOME/backup"

# n8n 容器内用 node 用户 (uid 1000)，需修复权限避免 EACCES
chown -R 1000:1000 "$N8N_HOME/data"
echo "[OK] Permissions set (uid 1000)"

cat > "$N8N_HOME/docker-compose.yaml" << COMPOSE
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:\${N8N_VERSION:-latest}
    container_name: n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - N8N_USER_MANAGEMENT_DISABLED=false
      - N8N_DIAGNOSTICS_ENABLED=true
      - N8N_PERSONALIZATION_ENABLED=true
      - N8N_TEMPLATES_ENABLED=true
      - N8N_METRICS=true
      - N8N_LOG_LEVEL=info
      - N8N_LOG_OUTPUT=console
      - DB_TYPE=sqlite
      - DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite
      - N8N_DEFAULT_LOCALE=zh_CN
      - N8N_SECURE_COOKIE=false
      - NODE_ENV=production
      - N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
    volumes:
      - /opt/n8n/data:/home/node/.n8n
      - /opt/n8n/backup:/backup
      - /etc/localtime:/etc/localtime:ro
COMPOSE

export N8N_VERSION
echo "[OK] docker-compose.yaml written"

# 备份脚本 + cron
cat > "$N8N_HOME/backup.sh" << 'BAK'
#!/bin/bash
D="/opt/n8n"
TS=$(date '+%Y%m%d-%H%M%S')
tar -czf "$D/backup/n8n-backup-$TS.tar.gz" -C "$D/data" .
find "$D/backup" -name "*.tar.gz" -mtime +7 -delete
echo "[$(date)] backup ok: n8n-backup-$TS.tar.gz"
BAK
chmod +x "$N8N_HOME/backup.sh"
(crontab -l 2>/dev/null; echo "0 2 * * * $N8N_HOME/backup.sh >> /var/n8n-backup.log 2>&1") | crontab -
echo "[OK] Backup cron added"

# ============ 4. 启动 n8n (带重试，对齐 demo 模式) ============
echo "[STEP] Start n8n..."

cd "$N8N_HOME"

MAX_RETRIES=5
SLEEP_INTERVAL=30
COUNT=0
STARTED=0

until [ $COUNT -ge $MAX_RETRIES ]; do
  docker-compose up --quiet-pull -d
  if [ $? -eq 0 ]; then
    STARTED=1
    break
  else
    COUNT=$((COUNT+1))
    echo "[RETRY] docker-compose up failed ($COUNT/$MAX_RETRIES), retrying in ${SLEEP_INTERVAL}s..."
    sleep $SLEEP_INTERVAL
  fi
done

if [ $STARTED -eq 0 ]; then
  echo "[FATAL] n8n failed to start after $MAX_RETRIES attempts"
  exit 1
fi

sleep 3
docker ps -a
docker logs n8n --tail 20 2>&1 || true

# 健康检查 (最长 120s)
OK=0
for i in $(seq 1 24); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5678/healthz 2>/dev/null || echo "000")
  echo "[$i/24] healthz -> HTTP $CODE"
  if echo "$CODE" | grep -qE "^(200|302)$"; then
    OK=1
    break
  fi
  sleep 5
done

if [ "$OK" -eq 0 ]; then
  echo "[WARN] health check timeout, dumping logs:"
  docker logs n8n 2>&1 || true
fi

echo "========================================="
echo "[$(date)] n8n deploy COMPLETE (health=$OK)"
echo "  URL:  http://<EIP>:5678"
echo "  Log:  $LOGFILE"
echo "========================================="
