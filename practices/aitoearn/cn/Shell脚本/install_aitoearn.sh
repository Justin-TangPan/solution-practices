#!/bin/bash
set -e

LOG="/var/log/aitoearn-bootstrap.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] Bootstrap: start"

# ===== Stage 1: 安装 Docker CE（华为云镜像源） =====
echo "[$(date)] 安装 Docker CE..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg git
curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
chmod a+r /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-compose-plugin
echo "[$(date)] Docker 安装完成: $(docker --version)"

# ===== Stage 2: 克隆项目仓库 =====
echo "[$(date)] 克隆 AiToEarn 仓库..."
cd /opt
rm -rf aitoearn
git clone --depth 1 https://github.com/yikart/AiToEarn.git aitoearn
cd /opt/aitoearn

# ===== Stage 3: 替换镜像为 SWR =====
echo "[$(date)] 替换镜像为 SWR..."
SWR_PREFIX="swr.cn-north-4.myhuaweicloud.com/sac"
sed -i "s|aitoearn/aitoearn-ai:latest|${SWR_PREFIX}/aitoearn-ai:latest|g" docker-compose.yml
sed -i "s|aitoearn/aitoearn-server:latest|${SWR_PREFIX}/aitoearn-server:latest|g" docker-compose.yml
sed -i "s|aitoearn/aitoearn-web:latest|${SWR_PREFIX}/aitoearn-web:latest|g" docker-compose.yml
sed -i "s|rustfs/rustfs:latest|${SWR_PREFIX}/rustfs:latest|g" docker-compose.yml

# ===== Stage 4: 启动服务 =====
echo "[$(date)] 启动 AiToEarn..."
docker compose pull
docker compose up -d

echo "[$(date)] 等待服务就绪..."
sleep 30
for i in $(seq 1 20); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:8080 2>/dev/null || echo "000")
  [ "$HTTP_CODE" = "200" ] && echo "[$(date)] AiToEarn 就绪 (HTTP 200)" && break
  echo "[$(date)] 等待中... (尝试 $i/20, HTTP $HTTP_CODE)"
  sleep 15
done

# ===== Stage 5: 验证 =====
echo "--- 验证 ---"
echo "Web: $(curl -sf http://localhost:8080 > /dev/null && echo '正常' || echo '异常')"
echo "容器: $(docker ps --format '{{.Names}}: {{.Status}}' | wc -l) 个运行中"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "[$(date)] Bootstrap: 完成"
echo ""
echo "====================================================="
echo " 访问地址: http://YOUR_EIP:8080"
echo " 日志: /var/log/aitoearn-bootstrap.log"
echo " 配置: /opt/aitoearn/"
echo "====================================================="
