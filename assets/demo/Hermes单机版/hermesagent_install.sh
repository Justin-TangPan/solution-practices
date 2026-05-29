#!/bin/bash


LOGFILE="/var/HermesAgent-install.log"
exec 1>"$LOGFILE" 2>&1
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

sleep 10

# 下载 docker CE, docker compose
curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
echo "" | sudo add-apt-repository "deb [arch=amd64] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
echo "y" | apt-get -qq update
sleep 10
echo "y" | apt-get -qq install docker-ce


# 配置docker镜像仓
echo '{"registry-mirrors": ["https://b4a1f63a156e435f9aeb797bdf515250.mirror.swr.myhuaweicloud.com"，"https://docker.1ms.run"]}' >/etc/docker/daemon.json
systemctl restart docker

mkdir -p /root/hermes-agent
cd /root/hermes-agent

cat > docker-compose.yaml << 'EOF'
services:
  hermes:
    image: nousresearch/hermes-agent:v2026.5.7
    container_name: hermes
    restart: unless-stopped
    command: gateway run
    ports:
      - "8642:8642"
      - "9119:9119"
    volumes:
      - /root/.hermes:/opt/data
    environment:
      - HERMES_DASHBOARD=1
    # - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    # - OPENAI_API_KEY=${OPENAI_API_KEY}
    # - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: "2.0"
EOF


MAX_RETRIES=5      # 最大重试次数
SLEEP_INTERVAL=30  # 失败后等待时间（秒）
COUNT=0            # 当前尝试次数
image_pulled=0

echo "开始执行 docker compose up -d..."

until [ $COUNT -ge $MAX_RETRIES ]
do
    # 执行命令
    docker compose up --quiet-pull -d
    
    # 检查上一条命令的退出状态
    if [ $? -eq 0 ]; then
        image_pulled=1
        break
    else
        COUNT=$((COUNT+1))
        echo "执行失败 (尝试次数: $COUNT/$MAX_RETRIES)，将在 ${SLEEP_INTERVAL}s 后重试..."
        sleep $SLEEP_INTERVAL
    fi
done

if [ $image_pulled -eq 0 ]; then
    exit 1
fi