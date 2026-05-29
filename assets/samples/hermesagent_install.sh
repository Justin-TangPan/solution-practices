#!/bin/bash
# ============================================================
# Hermes Agent 一键安装脚本
# 适用: Huawei Cloud ECS (Ubuntu 22.04 / CentOS 7.9+)
# 触发: RFS user_data 自动注入
# 位置: /var/lib/cloud/instance/user-data.txt
# 日志: /var/log/hermes-agent-install.log
# ============================================================
set -euxo pipefail

LOG_FILE="/var/log/hermes-agent-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ============================================================
# 配置区（由 RFS variables.tf 传入或环境变量覆盖）
# ============================================================
HERMES_VERSION="${HERMES_VERSION:-latest}"
HERMES_PORT="${HERMES_PORT:-8080}"
MODEL_ENDPOINT="${MODEL_ENDPOINT:-http://127.0.0.1:11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen2.5:7b}"
DATA_DIR="${DATA_DIR:-/opt/hermes-agent}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Hermes Agent Installer Started ==="

# ============================================================
# Phase 1: 环境检测与前置依赖
# ============================================================
echo "[Phase 1] 环境检测..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_FAMILY="$ID"
    OS_VERSION="$VERSION_ID"
else
    OS_FAMILY="unknown"
    OS_VERSION="unknown"
fi
echo "  OS: $OS_FAMILY $OS_VERSION"
echo "  Arch: $(uname -m)"

TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
TOTAL_CPU=$(nproc)
echo "  CPU: ${TOTAL_CPU} cores, RAM: ${TOTAL_MEM}MB"

if [ "$TOTAL_MEM" -lt 4096 ]; then
    echo "  [WARN] 内存小于 4GB，建议升级规格"
fi

# ============================================================
# Phase 2: 系统依赖安装
# ============================================================
echo "[Phase 2] 安装系统依赖..."

case "$OS_FAMILY" in
    ubuntu|debian)
        apt-get update -y
        apt-get install -y curl wget git unzip tar jq docker.io docker-compose nginx
        systemctl enable docker
        systemctl start docker
        ;;
    centos|rhel|anolis|openeuler)
        yum install -y curl wget git unzip tar jq yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin nginx
        systemctl enable docker
        systemctl start docker
        ;;
    *)
        echo "  [ERROR] 不支持的 OS: $OS_FAMILY"
        exit 1
        ;;
esac
echo "  [OK] 系统依赖安装完成"

# ============================================================
# Phase 3: Ollama 推理引擎安装
# ============================================================
echo "[Phase 3] 安装 Ollama..."

if ! command -v ollama &>/dev/null; then
    curl -fsSL https://ollama.com/install.sh | bash
fi

mkdir -p /etc/systemd/system/ollama.service.d
cat > /etc/systemd/system/ollama.service.d/override.conf << 'OLLAMAEOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_KEEP_ALIVE=24h"
OLLAMAEOF
systemctl daemon-reload
systemctl restart ollama
systemctl enable ollama

nohup ollama pull "$OLLAMA_MODEL" > /var/log/ollama-pull.log 2>&1 &
echo "  [OK] Ollama 模型 $OLLAMA_MODEL 拉取中（后台）"

# ============================================================
# Phase 4: Hermes Agent 安装
# ============================================================
echo "[Phase 4] 部署 Hermes Agent..."
mkdir -p "$DATA_DIR"/{data,logs,config,backup}
cd "$DATA_DIR"

curl -fsSL -o /tmp/hermes-agent.tar.gz \
  "https://github.com/tinyhumansai/openhuman/releases/${HERMES_VERSION}/download/hermes-agent-linux-x64.tar.gz" || {
    echo "  [WARN] Release 下载失败，跳过二进制部署"
}

cat > "$DATA_DIR/config/config.yaml" << CONFIGEOF
server:
  port: ${HERMES_PORT}
  host: "0.0.0.0"
  data_dir: "${DATA_DIR}/data"
model:
  endpoint: "${MODEL_ENDPOINT}"
  default_model: "${OLLAMA_MODEL}"
storage:
  type: local
  path: "${DATA_DIR}/data"
CONFIGEOF

# ============================================================
# Phase 5: Nginx 配置
# ============================================================
echo "[Phase 5] 配置 Nginx..."
cat > /etc/nginx/sites-available/hermes-agent << 'NGINXEOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:__HERMES_PORT__;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINXEOF

sed -i "s/__HERMES_PORT__/${HERMES_PORT}/g" /etc/nginx/sites-available/hermes-agent
if [ -d /etc/nginx/sites-enabled ]; then
    ln -sf /etc/nginx/sites-available/hermes-agent /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
fi
nginx -t && systemctl restart nginx

# ============================================================
# Phase 6: 服务注册
# ============================================================
echo "[Phase 6] 注册服务..."
cat > /etc/systemd/system/hermes-agent.service << SERVICEEOF
[Unit]
Description=Hermes Agent
After=network.target ollama.service
[Service]
Type=simple
WorkingDirectory=${DATA_DIR}
ExecStart=${DATA_DIR}/hermes-agent
Restart=always
RestartSec=10
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable hermes-agent
systemctl start hermes-agent || echo "  [WARN] 启动失败"

# ============================================================
# Phase 7: 健康检查
# ============================================================
echo "[Phase 7] 健康检查..."
sleep 3
systemctl is-active ollama && echo "  ollama: running"
systemctl is-active nginx && echo "  nginx: running"

echo ""
echo "============================================"
echo "  Hermes Agent 部署摘要"
echo "============================================"
echo "  系统: $OS_FAMILY $OS_VERSION"
echo "  访问地址: http://$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo "  数据目录: ${DATA_DIR}"
echo "  Ollama API: http://localhost:11434"
echo "  模型: ${OLLAMA_MODEL}"
echo "============================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Completed ==="
