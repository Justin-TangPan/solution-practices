#!/bin/bash
DIFY_VERSION=$1

# Dify版本参数校验
if [ -z "${DIFY_VERSION+x}" ] || [ -z "$DIFY_VERSION" ]; then
DIFY_VERSION="0.15.3"
fi

LOGFILE="/var/dify-install.log"
exec 1>"$LOGFILE" 2>&1
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

RETRY_INTERVAL=10
MAX_RETRIES=10
RETRY_COUNT=0
wget https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/building-a-dify-llm-application-development-platform/userdata/get.docker.sh
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do

    if sh get.docker.sh --mirror Aliyun; then
        break
    else
        echo "Retry installing docker"
        sleep $RETRY_INTERVAL
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

rm get.docker.sh

# 配置docker镜像仓
echo '{"registry-mirrors": ["https://docker.1ms.run","https://b4a1f63a156e435f9aeb797bdf515250.mirror.swr.myhuaweicloud.com"]}' >/etc/docker/daemon.json
systemctl restart docker

# 安装dify
rm -rf dify
git clone https://gitee.com/dify_ai/dify.git &&
cd dify/ &&
git checkout tags/"$DIFY_VERSION"
git checkout -b local-"$DIFY_VERSION"
cd docker/ &&
cp .env.example .env

chmod 777 /dify/docker/.env

sed -i '52s|.*|LOG_FILE=/app/logs/server|' /dify/docker/.env

if grep -q "PIP_MIRROR_URL=" .env; then
    sed -i 's/PIP_MIRROR_URL=.*$/PIP_MIRROR_URL=https:\/\/pypi.tuna.tsinghua.edu.cn\/simple/' .env
    echo "已成功替换 PIP_MIRROR_URL 参数"
else
    echo "未找到 PIP_MIRROR_URL 参数"
fi

if grep -q "INTERNAL_FILES_URL=" .env; then
    sed -i 's/INTERNAL_FILES_URL=.*$/INTERNAL_FILES_URL=http:\/\/api:5001/' .env
    echo "已成功替换 INTERNAL_FILES_URL 参数"
else
    echo "未找到 INTERNAL_FILES_URL 参数"
fi

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


docker compose ps

#下载配置HTTPS域名的脚本
wget -P /dify/docker/ https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/building-a-dify-llm-application-development-platform/userdata/configure_dify_domain_name.sh
chmod u+x /dify/docker/configure_dify_domain_name.sh

# 安装searxng
docker pull searxng/searxng:2025.10.4-7bf65d68c

# 更新配置文件
rm -f /dify/api/core/tools/provider/builtin/searxng/docker/settings.yml
wget -P /dify/api/core/tools/provider/builtin/searxng/docker/ https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/building-a-dify-llm-application-development-platform/userdata/settings.yml

# 启动searxngvim
docker run --rm -d -p 8080:8080 -v "/dify/api/core/tools/provider/builtin/searxng/docker:/etc/searxng" searxng/searxng:2025.10.4-7bf65d68c

# searxng开机自启动
echo "[Unit]
Description=searxng docker
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/root
ExecStart=docker run --rm -d -p 8080:8080 -v '/dify/api/core/tools/provider/builtin/searxng/docker:/etc/searxng' searxng/searxng:2025.10.4-7bf65d68c
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/searxng.service
systemctl daemon-reload
systemctl enable searxng.service

# 安全漏洞修复
wget https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/building-a-dify-llm-application-development-platform/userdata/dify-security-fix.sh
bash dify-security-fix.sh
rm dify-security-fix.sh