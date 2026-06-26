#!/bin/bash
DIFY_VERSION=$1
CSS_VPCEP_IP=$2
# Dify版本参数校验
if [ -z "${DIFY_VERSION+x}" ] || [ -z "$DIFY_VERSION" ]; then
DIFY_VERSION="0.15.3"
fi

LOGFILE="/var/dify-install.log"
exec 1>"$LOGFILE" 2>&1
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

# 下载 docker CE, docker compose
curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
echo "" | sudo add-apt-repository "deb [arch=amd64] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
echo "y" | apt-get update
echo "y" | apt-get install docker-ce docker-compose

# 配置docker镜像仓
echo '{"registry-mirrors": ["https://docker.1ms.run","https://b4a1f63a156e435f9aeb797bdf515250.mirror.swr.myhuaweicloud.com"]}' >/etc/docker/daemon.json
systemctl restart docker

# 安装dify
rm -rf dify
git clone https://gitee.com/dify_ai/dify.git &&
cd dify/ &&
git checkout tags/"$DIFY_VERSION"
cd docker/ &&
cp .env.example .env

chmod 777 /dify/docker/.env

sed -i '52s|.*|LOG_FILE=/app/logs/server|' /dify/docker/.env

if grep -q "PIP_MIRROR_URL=" .env; then
    sed -i 's/PIP_MIRROR_URL=.*$/PIP_MIRROR_URL=https:\/\/pypi.tuna.tsinghua.edu.cn\/simple/' /dify/docker/.env
    echo "已成功替换 PIP_MIRROR_URL 参数"
else
    echo "未找到 PIP_MIRROR_URL 参数"
fi

#CSS配置
sed -i "s/VECTOR_STORE=weaviate/VECTOR_STORE=opensearch/" /dify/docker/.env
sed -i "s/OPENSEARCH_HOST=opensearch/OPENSEARCH_HOST=$CSS_VPCEP_IP/" /dify/docker/.env
sed -i "s/OPENSEARCH_SECURE=true/OPENSEARCH_SECURE=false/" /dify/docker/.env
docker-compose up -d
docker-compose ps

#下载配置HTTPS域名的脚本
wget -P /dify/docker/ https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/building-a-dify-llm-application-development-platform/userdata/configure_dify_domain_name.sh
chmod u+x /dify/docker/configure_dify_domain_name.sh

#安装知识库
cd /root/ &&
wget -P /home/ https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/building-a-dify-llm-application-development-platform/userdata/baidu_search.tar
tar -xvf /home/baidu_search.tar
docker cp /root/baidu_search docker_api_1:/app/api/core/tools/provider/builtin/
sleep 10
docker restart docker_api_1

# 安装searxng
docker pull searxng/searxng

# 更新配置文件
rm -f /dify/api/core/tools/provider/builtin/searxng/docker/settings.yml
wget -P /dify/api/core/tools/provider/builtin/searxng/docker/ https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/building-a-dify-llm-application-development-platform/userdata/settings.yml

# 启动searxng
docker run --rm -d -p 8080:8080 -v "/dify/api/core/tools/provider/builtin/searxng/docker:/etc/searxng" searxng/searxng

# searxng开机自启动
echo "[Unit]
Description=searxng docker
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/root
ExecStart=docker run --rm -d -p 8080:8080 -v '/dify/api/core/tools/provider/builtin/searxng/docker:/etc/searxng' searxng/searxng
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/searxng.service
systemctl daemon-reload
systemctl enable searxng.service

# 安全漏洞修复
wget https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/building-a-dify-llm-application-development-platform/userdata/dify-security-fix.sh
bash dify-security-fix.sh
rm dify-security-fix.sh