terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
    }
  }
}

provider "huaweicloud" {
  region = "tr-west-1"
}

variable "solution_name" {
  default     = "litellm-llm-gateway"
  description = "解决方案名称，4-24字符，小写字母/数字/连字符，必须以小写字母开头。"
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "c7n.2xlarge.2"
  description = "ECS 规格代码。推荐 c7n.2xlarge.2（8vCPUs 16GiB）。请根据目标区域可用规格调整。"
  type        = string
  nullable    = false
}

variable "ecs_password" {
  default     = ""
  description = "ECS root 密码，8-26字符，至少包含大写字母、小写字母、数字、特殊字符中的三种。"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "db_password" {
  default     = ""
  description = "PostgreSQL 密码，8-26字符。LiteLLM 内部数据库使用（虚拟密钥、用量追踪）。"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "master_key" {
  default     = ""
  description = "LiteLLM 主密钥，必须以 'sk-' 开头。用于 Admin UI 登录和 API 认证。"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "salt_key" {
  default     = ""
  description = "LiteLLM 盐值密钥，用于加密存储的 API 密钥。一经使用不可更改。留空则自动生成。"
  type        = string
  sensitive   = true
  nullable    = true
}

variable "system_disk_size" {
  default     = 200
  description = "系统盘大小（GB），高IO SSD。Docker 镜像 + PG 数据 + 日志。生产环境推荐 200GB。范围：40-1024。"
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "系统盘大小必须在 40 到 1024 GB 之间。"
  }
}

variable "bandwidth_size" {
  default     = 200
  description = "EIP 带宽（Mbit/s），按流量计费。范围：1-300，默认 200。"
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "带宽必须在 1 到 300 Mbit/s 之间。"
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "计费模式：postPaid（按需）或 prePaid（包周期）。默认按需。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "计费模式必须为 postPaid 或 prePaid。"
  }
}

variable "charging_unit" {
  default     = "month"
  description = "包周期单位：month（月）或 year（年）。prePaid 模式下必填。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "包周期单位必须为 month 或 year。"
  }
}

variable "charging_period" {
  default     = 1
  description = "包周期时长：月1-9，年1-3。prePaid 模式下必填。"
  type        = number
  nullable    = false
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "包周期时长必须为 1-9。"
  }
}

data "huaweicloud_images_image" "Ubuntu" {
  most_recent = true
  name        = "Ubuntu 24.04 server 64bit"
  visibility  = "public"
}

resource "huaweicloud_vpc" "vpc" {
  name = "${var.solution_name}-vpc"
  cidr = "172.16.0.0/16"
}

resource "huaweicloud_vpc_subnet" "subnet" {
  name       = "${var.solution_name}-subnet"
  cidr       = "172.16.1.0/24"
  gateway_ip = "172.16.1.1"
  vpc_id     = huaweicloud_vpc.vpc.id
}

resource "huaweicloud_networking_secgroup" "secgroup" {
  name = "${var.solution_name}-sg"
}

resource "huaweicloud_networking_secgroup_rule" "allow_ping" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "允许 Ping 用于连通性测试"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "litellm_api" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "LiteLLM 代理 API 及管理界面"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 4000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "prometheus_ui" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Prometheus 监控面板"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 9090
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "通过 Cloud Shell 的 SSH 访问"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_vpc_eip" "vpc_eip" {
  name = "${var.solution_name}-eip"
  bandwidth {
    name        = "${var.solution_name}-bw"
    share_type  = "PER"
    size        = var.bandwidth_size
    charge_mode = "traffic"
  }
  publicip {
    type = "5_bgp"
  }
  charging_mode = "postPaid"
}

resource "huaweicloud_compute_instance" "compute_instance" {
  name                        = "${var.solution_name}-ecs"
  image_id                    = data.huaweicloud_images_image.Ubuntu.id
  flavor_id                   = var.ecs_flavor
  security_group_ids          = [huaweicloud_networking_secgroup.secgroup.id]
  system_disk_type            = "SSD"
  system_disk_size            = var.system_disk_size
  admin_pass                  = var.ecs_password
  delete_disks_on_termination = true
  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }
  agent_list    = "hss,ces"
  eip_id        = huaweicloud_vpc_eip.vpc_eip.id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
  tags = {
    app = "LiteLLM"
  }
  user_data = <<-EOT
  #!/bin/bash
  set -e

  echo 'root:${var.ecs_password}' | chpasswd

  LOG="/var/log/litellm-bootstrap.log"
  exec > >(tee -a "$LOG") 2>&1

  echo "[$(date)] LiteLLM 引导脚本：开始"

  # ---- 安装 Docker CE（官方源） ----
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-compose-plugin
  echo "[$(date)] Docker 已安装: $(docker --version)"

  # ---- 准备目录 ----
  LITELLM_DIR="/opt/litellm"
  mkdir -p "$LITELLM_DIR"

  # ---- 生成 .env ----
  DB_PASSWORD="${var.db_password}"
  MASTER_KEY="${var.master_key}"
  SALT_KEY="${var.salt_key}"
  [ -z "$SALT_KEY" ] && SALT_KEY="$(openssl rand -base64 32)"

  cat > "$LITELLM_DIR/.env" << ENVEOF
  POSTGRES_PASSWORD=$DB_PASSWORD
  LITELLM_MASTER_KEY=$MASTER_KEY
  LITELLM_SALT_KEY=$SALT_KEY
  DATABASE_URL=postgresql://llmproxy:$DB_PASSWORD@db:5432/litellm
  STORE_MODEL_IN_DB=True
  # 在下方添加提供商 API 密钥，然后执行 `docker compose restart`：
  # OPENAI_API_KEY=sk-xxx
  # ANTHROPIC_API_KEY=sk-ant-xxx
  ENVEOF

  # ---- 生成 config.yaml（最小配置；模型通过管理界面管理） ----
  cat > "$LITELLM_DIR/config.yaml" << 'CFGEOF'
  general_settings:
    master_key: os.environ/LITELLM_MASTER_KEY
    database_url: os.environ/DATABASE_URL

  litellm_settings:
    num_retries: 3
    request_timeout: 600
    drop_params: true
  CFGEOF

  # ---- 生成 prometheus.yml ----
  cat > "$LITELLM_DIR/prometheus.yml" << 'PROMEOF'
  scrape_configs:
    - job_name: 'litellm'
      scrape_interval: 15s
      static_configs:
        - targets: ['litellm:4000']
  PROMEOF

  # ---- 生成 docker-compose.yaml（2026 官方模式） ----
  cat > "$LITELLM_DIR/docker-compose.yaml" << 'COMPOSEEOF'
  services:
    litellm:
      image: ghcr.io/berriai/litellm:main-stable
      container_name: litellm-proxy
      restart: unless-stopped
      ports:
        - "4000:4000/tcp"
      command:
        - "--config=/app/config.yaml"
      environment:
        DATABASE_URL: "postgresql://llmproxy:$${POSTGRES_PASSWORD}@db:5432/litellm"
        STORE_MODEL_IN_DB: "True"
        LITELLM_MASTER_KEY: $${LITELLM_MASTER_KEY}
        LITELLM_SALT_KEY: $${LITELLM_SALT_KEY}
      env_file:
        - .env
      volumes:
        - ./config.yaml:/app/config.yaml:ro
      depends_on:
        db:
          condition: service_healthy
      healthcheck:
        test:
          - CMD-SHELL
          - python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')"
        interval: 30s
        timeout: 10s
        retries: 3
        start_period: 40s

    db:
      image: postgres:16
      container_name: litellm-db
      restart: unless-stopped
      ports:
        - "5432:5432"
      environment:
        POSTGRES_DB: litellm
        POSTGRES_USER: llmproxy
        POSTGRES_PASSWORD: $${POSTGRES_PASSWORD}
      volumes:
        - postgres_data:/var/lib/postgresql/data
      healthcheck:
        test:
          - CMD-SHELL
          - pg_isready -d litellm -U llmproxy
        interval: 5s
        timeout: 5s
        retries: 10

    prometheus:
      image: prom/prometheus:v2.53.0
      container_name: litellm-prometheus
      restart: unless-stopped
      ports:
        - "9090:9090/tcp"
      command:
        - "--config.file=/etc/prometheus/prometheus.yml"
        - "--storage.tsdb.path=/prometheus"
        - "--storage.tsdb.retention.time=15d"
      volumes:
        - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
        - prometheus_data:/prometheus
      depends_on:
        - litellm

  volumes:
    postgres_data:
      name: litellm_postgres_data
    prometheus_data:
      name: litellm_prometheus_data
  COMPOSEEOF

  # ---- 部署（含重试） ----
  cd "$LITELLM_DIR"
  MAX_RETRIES=5
  COUNT=0
  deploy_ok=0

  echo "[$(date)] 开始 docker compose pull & up..."
  until [ $COUNT -ge $MAX_RETRIES ]; do
    docker compose pull 2>&1 && docker compose up -d 2>&1 && deploy_ok=1 && break
    COUNT=$((COUNT+1))
    echo "[$(date)] 第 $COUNT/$MAX_RETRIES 次重试，30秒后..."
    sleep 30
  done

  if [ $deploy_ok -eq 0 ]; then
    echo "[$(date)] 严重错误：$MAX_RETRIES 次重试后部署仍失败"
    docker compose logs --tail=50 2>&1 || true
    exit 1
  fi

  # ---- 健康检查 ----
  echo "[$(date)] 等待服务启动..."
  sleep 15

  for i in $(seq 1 12); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://localhost:4000/health/liveliness 2>/dev/null || echo "000")
    [ "$HTTP_CODE" = "200" ] && echo "[$(date)] LiteLLM 健康（HTTP 200）" && break
    echo "[$(date)] 等待中...（第 $i/12 次，HTTP $HTTP_CODE）"
    sleep 10
  done

  echo "--- 容器状态 ---"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

  echo "[$(date)] LiteLLM 引导脚本：完成"

  EOT
}

output "access_info" {
  description = "部署访问信息"
  value       = <<-EOT
等待约10分钟完成部署后访问：

管理界面:   http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/ui
API:        http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/v1/chat/completions
健康检查:   http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/health/liveliness

SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address}

首次使用：
  1. 使用 master_key 登录管理界面
  2. 进入「模型管理」添加模型和 API 密钥
  3. 或编辑配置：vi /opt/litellm/config.yaml
  4. 重启：cd /opt/litellm && docker compose restart

日志: /var/log/litellm-bootstrap.log
EOT
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
