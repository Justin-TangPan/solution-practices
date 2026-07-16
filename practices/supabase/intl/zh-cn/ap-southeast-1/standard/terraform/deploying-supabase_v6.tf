terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
    }
  }
}

provider "huaweicloud" {
  region = "ap-southeast-1"
}

variable "solution_name" {
  default     = "supabase"
  description = "解决方案名称，4-24 个字符，仅支持小写字母、数字和中划线，必须以小写字母开头并以小写字母或数字结尾。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,22}[a-z0-9]$", var.solution_name))
    error_message = "解决方案名称必须为 4-24 个字符，以小写字母开头、以小写字母或数字结尾，且仅包含小写字母、数字或中划线。"
  }
}

variable "ecs_flavor" {
  default     = "c7n.2xlarge.2"
  description = "云服务器实例规格。Supabase 需运行多个 Docker 容器，建议使用 c7n.2xlarge.2（8 vCPUs、16 GiB）或更高规格。"
  type        = string
  nullable    = false
}

variable "ecs_password" {
  description = "云服务器 root 密码，8-26 个字符，至少包含大写字母、小写字母、数字和特殊字符中的三种。"
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition = (
      length(var.ecs_password) >= 8 &&
      length(var.ecs_password) <= 26 &&
      (
        (can(regex("[A-Z]", var.ecs_password)) ? 1 : 0) +
        (can(regex("[a-z]", var.ecs_password)) ? 1 : 0) +
        (can(regex("[0-9]", var.ecs_password)) ? 1 : 0) +
        (can(regex("[^A-Za-z0-9]", var.ecs_password)) ? 1 : 0)
      ) >= 3
    )
    error_message = "云服务器密码必须为 8-26 个字符，并至少包含大写字母、小写字母、数字和特殊字符中的三种。"
  }
}

variable "db_password" {
  description = "PostgreSQL 数据库密码。模板不限制字符类型，并使用安全编码传入 cloud-init；请使用高强度密码。"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "system_disk_size" {
  default     = 100
  description = "系统盘大小（GiB），取值范围为 40-1024。建议至少使用 100 GiB 以存放 Docker 镜像和数据库数据。"
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "系统盘大小必须为 40-1024 GiB。"
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "弹性公网 IP 带宽（Mbit/s），按流量计费，取值范围为 1-300。"
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "带宽必须为 1-300 Mbit/s。"
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "计费模式：postPaid（按需计费）或 prePaid（包年包月）。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "计费模式必须为 postPaid 或 prePaid。"
  }
}

variable "charging_unit" {
  default     = "month"
  description = "订购周期单位：month（月）或 year（年），在 charging_mode 为 prePaid 时使用。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "订购周期单位必须为 month 或 year。"
  }
}

variable "charging_period" {
  default     = 1
  description = "订购周期：按月为 1-9，按年为 1-3，在 charging_mode 为 prePaid 时使用。"
  type        = number
  nullable    = false
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "订购周期必须在 1 到 9 之间；charging_unit 为 year 时请填写 1 到 3。"
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
  description       = "允许 ICMP 连通性测试"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "supabase_http" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Supabase 管理后台和 API 网关"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 8000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "允许从华为云 Cloud Shell 进行 SSH 访问"
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
  system_disk_type            = "SAS"
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
    app = "Supabase"
  }

  user_data = <<-EOT
  #!/bin/bash
  set -Eeuo pipefail
  umask 077

  LOG=/var/log/supabase-bootstrap.log
  exec > >(tee -a "$LOG") 2>&1
  echo "[$(date --iso-8601=seconds)] Supabase 初始化开始"

  fail() {
    echo "[FATAL] $*" >&2
    exit 1
  }

  # ---- 阶段 1：从官方源安装 Docker CE 和必要工具 ----
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg git jq openssl nodejs
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod 0644 /etc/apt/keyrings/docker.gpg
  . /etc/os-release
  ARCH=$(dpkg --print-architecture)
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu %s stable\n' "$ARCH" "$VERSION_CODENAME" > /etc/apt/sources.list.d/docker.list
  chmod 0644 /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker

  # ---- 阶段 2：复制固定 commit 的完整官方 docker 目录 ----
  SUPABASE_REPOSITORY=https://github.com/supabase/supabase.git
  SUPABASE_COMMIT=00ecb5305965ff85e1b5757e34a8eb5eb787f6f6
  SUPABASE_DIR=/opt/supabase
  SOURCE_DIR=$(mktemp -d /tmp/supabase-source.XXXXXX)
  trap 'rm -rf "$SOURCE_DIR"' EXIT

  git -C "$SOURCE_DIR" init -q
  git -C "$SOURCE_DIR" remote add origin "$SUPABASE_REPOSITORY"
  git -C "$SOURCE_DIR" config remote.origin.promisor true
  git -C "$SOURCE_DIR" config remote.origin.partialclonefilter blob:none
  git -C "$SOURCE_DIR" sparse-checkout init --cone
  git -C "$SOURCE_DIR" sparse-checkout set docker
  FETCH_OK=0
  for ATTEMPT in 1 2 3 4 5; do
    if git -C "$SOURCE_DIR" fetch -q --filter=blob:none --depth 1 origin "$SUPABASE_COMMIT"; then
      FETCH_OK=1
      break
    fi
    echo "[$(date --iso-8601=seconds)] 第 $ATTEMPT/5 次源码拉取失败，15 秒后重试"
    sleep 15
  done
  [ "$FETCH_OK" -eq 1 ] || fail "官方源码拉取重试 5 次后仍然失败"
  git -C "$SOURCE_DIR" checkout -q --detach FETCH_HEAD
  ACTUAL_COMMIT=$(git -C "$SOURCE_DIR" rev-parse HEAD)
  [ "$ACTUAL_COMMIT" = "$SUPABASE_COMMIT" ] || fail "官方源码 commit 校验失败"
  [ "$(git -C "$SOURCE_DIR" rev-parse --is-shallow-repository)" = true ] || fail "官方源码检出不是浅层检出"
  [ ! -e "$SUPABASE_DIR" ] || fail "$SUPABASE_DIR 已存在"
  install -d -m 0700 "$SUPABASE_DIR"
  cp -a "$SOURCE_DIR/docker/." "$SUPABASE_DIR/"
  printf '%s\n' "$ACTUAL_COMMIT" > "$SUPABASE_DIR/.supabase-commit"
  chmod 0700 "$SUPABASE_DIR"
  cd "$SUPABASE_DIR"

  # ---- 阶段 3：使用官方脚本静默生成全部密钥 ----
  cp .env.example .env
  chmod 0600 .env
  sh utils/generate-keys.sh --update-env >/dev/null 2>&1
  rm -f .env.old
  sh utils/add-new-auth-keys.sh --update-env >/dev/null 2>&1
  rm -f .env.old docker-compose.yml.old

  set_env() {
    KEY="$1"
    VALUE="$2"
    ESCAPED_VALUE=$(printf '%s' "$VALUE" | sed "s/'/\\\\'/g")
    TMP_ENV=$(mktemp)
    grep -v "^$KEY=" .env > "$TMP_ENV" || true
    printf "%s='%s'\n" "$KEY" "$ESCAPED_VALUE" >> "$TMP_ENV"
    mv "$TMP_ENV" .env
  }

  DB_PASSWORD_B64='${base64encode(var.db_password)}'
  DB_PASSWORD=$(printf '%s' "$DB_PASSWORD_B64" | base64 --decode)
  PUBLIC_BASE_URL=http://${huaweicloud_vpc_eip.vpc_eip.address}:8000
  set_env POSTGRES_PASSWORD "$DB_PASSWORD"
  set_env SUPABASE_PUBLIC_URL "$PUBLIC_BASE_URL"
  set_env API_EXTERNAL_URL "$PUBLIC_BASE_URL/auth/v1"
  set_env SITE_URL "$PUBLIC_BASE_URL"
  set_env POOLER_TENANT_ID '${var.solution_name}'
  set_env OPENAI_API_KEY ''
  unset DB_PASSWORD DB_PASSWORD_B64 ESCAPED_VALUE
  chmod 0600 .env

  # ---- 阶段 4：部署前断言固定版本的官方配置 ----
  [ "$(cat .supabase-commit)" = "$SUPABASE_COMMIT" ] || fail "固定 commit 标记无效"
  grep -Fq 'SNIPPETS_MANAGEMENT_FOLDER: /app/snippets' docker-compose.yml || fail "缺少官方 Snippets 环境配置"
  grep -Fq './volumes/snippets:/app/snippets:z' docker-compose.yml || fail "缺少官方 Snippets 数据卷"
  grep -Eq '^[[:space:]]*- name: basic-auth[[:space:]]*$' volumes/api/kong.yml || fail "缺少官方管理后台 Basic Auth 配置"
  grep -qx 'COMPOSE_FILE=docker-compose.yml' .env || fail "不得启用可选的 Analytics/Vector Compose 覆盖文件"
  if grep -Eq 'image:[[:space:]]*[^#[:space:]]*:latest([[:space:]]|$)' docker-compose.yml; then
    fail "官方基础 Compose 文件中存在未固定版本的 latest 镜像"
  fi
  [ "$(stat -c '%a' "$SUPABASE_DIR")" = 700 ] || fail "$SUPABASE_DIR 权限必须为 700"
  [ "$(stat -c '%a' .env)" = 600 ] || fail ".env 权限必须为 600"
  docker compose config --quiet
  ACTIVE_SERVICES=$(docker compose config --services)
  for REQUIRED_SERVICE in studio kong auth rest realtime storage imgproxy meta functions db supavisor; do
    printf '%s\n' "$ACTIVE_SERVICES" | grep -qx "$REQUIRED_SERVICE" || fail "缺少必要的官方服务：$REQUIRED_SERVICE"
  done
  if printf '%s\n' "$ACTIVE_SERVICES" | grep -Eq '^(analytics|vector)$'; then
    fail "不得启用可选的 Analytics/Vector 服务"
  fi

  # ---- 阶段 5：重试拉取镜像并通过官方 run.sh 启动 ----
  PULL_OK=0
  for ATTEMPT in 1 2 3 4 5; do
    if ./run.sh pull; then
      PULL_OK=1
      break
    fi
    echo "[$(date --iso-8601=seconds)] 第 $ATTEMPT/5 次镜像拉取失败，30 秒后重试"
    sleep 30
  done
  [ "$PULL_OK" -eq 1 ] || fail "镜像拉取重试 5 次后仍然失败"
  ./run.sh start --wait-timeout 900

  # ---- 阶段 6：验证管理后台保护和 SQL Snippets 可写性 ----
  UNAUTHENTICATED_STATUS=$(curl -sS -o /dev/null -w '%%{http_code}' http://127.0.0.1:8000/)
  [ "$UNAUTHENTICATED_STATUS" = 401 ] || fail "管理后台未携带凭证时必须返回 HTTP 401，实际为 $UNAUTHENTICATED_STATUS"
  DASHBOARD_USERNAME=$(grep '^DASHBOARD_USERNAME=' .env | cut -d= -f2-)
  DASHBOARD_PASSWORD=$(grep '^DASHBOARD_PASSWORD=' .env | cut -d= -f2-)
  AUTHENTICATED_STATUS=$(curl -sS -o /dev/null -w '%%{http_code}' -u "$DASHBOARD_USERNAME:$DASHBOARD_PASSWORD" http://127.0.0.1:8000/)
  case "$AUTHENTICATED_STATUS" in
    2??|3??) ;;
    *) fail "管理后台 Basic Auth 验证失败，HTTP 状态码为 $AUTHENTICATED_STATUS" ;;
  esac
  docker compose exec -T studio sh -c 'test -d /app/snippets && test -w /app/snippets' || fail "Studio Snippets 目录不可写"
  [ "$(stat -c '%a' .env)" = 600 ] || fail "部署后 .env 权限发生变化"

  # ---- 阶段 7：使用官方 run.sh 进行 systemd 生命周期管理 ----
  cat > /etc/systemd/system/supabase.service <<'UNITEOF'
  [Unit]
  Description=Supabase self-hosted stack
  Requires=docker.service
  After=docker.service network-online.target
  Wants=network-online.target

  [Service]
  Type=oneshot
  RemainAfterExit=yes
  WorkingDirectory=/opt/supabase
  ExecStart=/opt/supabase/run.sh start --wait-timeout 900
  ExecStop=/opt/supabase/run.sh stop
  TimeoutStartSec=1000
  TimeoutStopSec=300

  [Install]
  WantedBy=multi-user.target
  UNITEOF
  systemctl daemon-reload
  systemctl enable supabase.service

  rm -rf "$SOURCE_DIR"
  trap - EXIT
  echo "[$(date --iso-8601=seconds)] Supabase 初始化完成"
  EOT
}

output "access_info" {
  description = "Supabase 访问与运维信息"
  value       = "请等待约 10-20 分钟以完成 cloud-init。管理后台：http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/ | 请仅通过 SSH 执行以下命令获取随机生成的管理后台密码：cd /opt/supabase && sudo ./run.sh secrets | 部署日志：/var/log/supabase-bootstrap.log"
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
