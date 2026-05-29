#!/bin/bash
# 集群节点初始化脚本
# 适用于 Ubuntu 22.04
set -euxo pipefail

LOG_FILE="/var/log/install_app.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Starting application installation at $(date) ==="

# 系统更新
apt-get update -y
apt-get install -y curl wget nginx

# 配置 Nginx 反向代理到本地应用
cat > /etc/nginx/sites-available/default << 'NGINX_CONFIG'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_CONFIG

systemctl enable nginx
systemctl restart nginx

echo "=== Installation completed at $(date) ==="
