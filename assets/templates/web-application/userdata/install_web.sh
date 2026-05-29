#!/bin/bash
# Web 应用安装脚本
# 适用于 Ubuntu 22.04
set -euxo pipefail

LOG_FILE="/var/log/install_web.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Starting web application installation at $(date) ==="

# 系统更新
apt-get update -y
apt-get upgrade -y

# 安装 Docker
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | bash
  systemctl enable docker
  systemctl start docker
fi

# 安装 Docker Compose
if ! command -v docker-compose &>/dev/null; then
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# 安装 Nginx
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx

echo "=== Installation completed at $(date) ==="
echo "Web server is ready at http://$(curl -s ifconfig.me)"
