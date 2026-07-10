# 华为云解决方案实践（SAC）技术路线总结

> Solution Practices — 基于华为云 RFS 的一键部署方案技术全景

---

## 一、什么是 SAC

SAC（Solution Practices）是华为云解决方案实践的标准化交付模式。核心思想：

**用一段模板描述整个基础设施 + 应用部署，用户点击"一键部署"，RFS 自动完成全部资源创建和应用安装。**

用户不需要手动创建 VPC、ECS、安全组、EIP，不需要 SSH 登录执行命令。模板定义一切，RFS 编排一切。

---

## 二、技术栈全景

```
┌─────────────────────────────────────────────────────────┐
│                    用户视角                               │
│            华为云控制台 → 点击"一键部署"                    │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    RFS 编排层                             │
│         Resource Formation Service（资源编排）             │
│         解析模板 → 创建资源 → 执行 user_data               │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    模板层                                 │
│     Terraform HCL (.tf)  或  Terraform JSON (.tf.json)   │
│     定义变量、数据源、资源、输出                             │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    资源层                                 │
│     VPC → Subnet → SecGroup → EIP → ECS                 │
│     ECS 启动时执行 user_data 脚本                         │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    应用层                                 │
│     Docker CE → Docker Compose → 应用容器                 │
│     (LiteLLM / n8n / Supabase / Dify / ...)             │
└─────────────────────────────────────────────────────────┘
```

---

## 三、核心概念详解

### 3.1 RFS（Resource Formation Service）

华为云的资源编排服务，对标 AWS CloudFormation / Azure ARM，但底层基于 Terraform。

**工作流程：**
1. 用户上传模板（.tf 或 .tf.json）+ 参数
2. RFS 解析模板，生成执行计划
3. 按依赖顺序创建资源（VPC → Subnet → SecGroup → EIP → ECS）
4. ECS 创建时注入 user_data，机器首次启动自动执行

**关键限制：**
- Terraform 版本：1.5.2（不是最新版）
- Provider：仅支持 `huaweicloud`，不支持 `random`、`tls` 等 HashiCorp 第三方 provider
- HCL 解析器：与原生 Terraform 有细微差异（heredoc 支持、特殊字符转义）

### 3.2 模板格式

#### HCL 格式（.tf）— 推荐主力

```hcl
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
  default     = "my-app"
  description = "Solution name"
  type        = string
  nullable    = false
}

resource "huaweicloud_vpc" "vpc" {
  name = "${var.solution_name}-vpc"
  cidr = "172.16.0.0/16"
}

output "access_info" {
  value = "http://${huaweicloud_vpc_eip.vpc_eip.address}:4000"
}
```

**优点：** 可读性强、支持 heredoc（多行脚本）、Terraform 原生格式
**缺点：** RFS 的 HCL 解析器偶尔有兼容性问题

#### JSON 格式（.tf.json）— 备用保底

```json
{
  "terraform": {
    "required_providers": {
      "huaweicloud": {
        "source": "huawei.com/provider/huaweicloud",
        "version": ">= 1.20.0"
      }
    }
  },
  "provider": {
    "huaweicloud": {
      "region": "ap-southeast-1"
    }
  },
  "resource": {
    "huaweicloud_vpc": {
      "vpc": {
        "name": "${var.solution_name}-vpc",
        "cidr": "172.16.0.0/16"
      }
    }
  }
}
```

**优点：** RFS 原生支持、解析稳定、无 heredoc 兼容问题
**缺点：** 多行 user_data 用 `\n` 拼接，可读性差、维护困难

### 3.3 特殊字符转义规则

在 HCL heredoc 中，Terraform 会解析两种模板语法：

| 语法 | 含义 | 转义方式 | 场景 |
|------|------|---------|------|
| `${...}` | 字符串插值 | `$${...}` | docker-compose 中的 `${POSTGRES_PASSWORD}` |
| `%{...}` | 模板指令 | `%%{...}` | curl 的 `%{http_code}` |

**注意：** `$VAR`（无花括号）不会被 Terraform 解析，无需转义。只有 `${VAR}` 才触发插值。

**示例（docker-compose 环境变量）：**
```hcl
# ❌ 错误：Terraform 会尝试解析 ${POSTGRES_PASSWORD}
environment:
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

# ✅ 正确：$$ 转义为字面 $
environment:
  POSTGRES_PASSWORD: $${POSTGRES_PASSWORD}
```

**示例（curl 格式字符串）：**
```bash
# ❌ 错误：%{http_code} 被当作模板指令
HTTP_CODE=$(curl -w "%{http_code}" ...)

# ✅ 正确：%% 转义为字面 %
HTTP_CODE=$(curl -w "%%{http_code}" ...)
```

---

## 四、模板标准结构

### 4.1 资源依赖链

```
VPC ──→ Subnet ──→ ECS
            ↗
SecGroup ──→ ECS
            ↗
EIP ──────→ ECS (eip_id 绑定)
```

所有资源通过 Terraform 的引用语法自动建立依赖关系，RFS 按拓扑序创建。

### 4.2 标准资源清单

| 资源类型 | 资源名 | 说明 | 必需 |
|---------|--------|------|------|
| `huaweicloud_vpc` | `vpc` | VPC 网络 | ✅ |
| `huaweicloud_vpc_subnet` | `subnet` | 子网 | ✅ |
| `huaweicloud_networking_secgroup` | `secgroup` | 安全组 | ✅ |
| `huaweicloud_networking_secgroup_rule` | `allow_ping` | ICMP 放行 | ✅ |
| `huaweicloud_networking_secgroup_rule` | `cloud_shell` | SSH 22 端口 | ✅ |
| `huaweicloud_networking_secgroup_rule` | `{app}_{port}` | 应用端口 | ✅ |
| `huaweicloud_vpc_eip` | `vpc_eip` | 弹性公网 IP | ✅ |
| `huaweicloud_compute_instance` | `compute_instance` | ECS 云服务器 | ✅ |
| `huaweicloud_images_image` | `Ubuntu` | 镜像数据源 | ✅ |

### 4.3 安全组规则模式

每个应用至少开放 3 个端口：

```hcl
# 必选：ping 测试
resource "huaweicloud_networking_secgroup_rule" "allow_ping" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

# 必选：SSH（仅限 Cloud Shell IP）
resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

# 按需：应用端口（根据实际端口添加）
resource "huaweicloud_networking_secgroup_rule" "app_port" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 4000  # 应用监听端口
  remote_ip_prefix  = "0.0.0.0/0"
}
```

### 4.4 ECS 标准配置

```hcl
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

  agent_list    = "hss,ces"           # 安全监控 + 云监控
  eip_id        = huaweicloud_vpc_eip.vpc_eip.id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period

  tags = {
    app = "LiteLLM"
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -e
    # ... 部署脚本 ...
  USERDATA
}
```

---

## 五、部署策略

### 5.1 两种 user_data 模式

#### 模式 A：内联 user_data（SAC 标准模式）

整个部署脚本直接写在模板的 user_data 字段里。

```
模板文件 (.tf)
  └── user_data = <<-USERDATA
        #!/bin/bash
        set -e
        apt-get install docker-ce ...
        cat > docker-compose.yaml << 'EOF'
        ...
        EOF
        docker compose up -d
      USERDATA
```

**优点：** 单文件交付、无外部脚本依赖、RFS 一个模板搞定、交付边界清晰
**缺点：** 脚本长了难维护、改脚本要重新发布模板

**适用：** SAC 标准交付。参考 LiteLLM、Supabase，将安装、配置生成、服务启动、健康检查和输出提示都内联在 `.tf` 的 user_data 中。

#### 模式 B：OBS 下载（例外模式）

user_data 只做两件事：下载脚本 + 执行。

```
模板文件 (.tf)
  └── user_data = "#!/bin/bash\ncurl -fsSL obs://.../install.sh | bash"

OBS 桶
  ├── install_litellm.sh    ← 可独立更新
  ├── docker-compose.yaml
  └── config.yaml
```

**优点：** 脚本可独立迭代、改脚本不用动模板、支持复杂多文件
**缺点：** 依赖 OBS 桶、需要维护两套文件

**适用：** 仅当用户明确要求外置脚本，或存在必须热更新脚本/多文件分发的技术约束时使用。启用前必须说明原因。

### 5.2 部署脚本标准结构（4 阶段）

无论是内联 user_data 还是例外 OBS 下载，部署逻辑统一采用 4 阶段模式：

```bash
#!/bin/bash
set -e

# ===== Stage 1: 系统准备 =====
export DEBIAN_FRONTEND=noninteractive
dpkg --configure -a 2>/dev/null || true
apt-get update -y
apt-get install -y ca-certificates curl gnupg

# ===== Stage 2: Docker 安装 =====
# 国内：mirrors.huaweicloud.com
# 海外：download.docker.com
apt-get install -y docker-ce docker-compose-plugin

# ===== Stage 3: 应用配置 =====
mkdir -p /opt/app/volumes
cat > /opt/app/.env << 'EOF'
POSTGRES_PASSWORD=xxx
EOF
cat > /opt/app/docker-compose.yaml << 'EOF'
services:
  ...
EOF

# ===== Stage 4: 启动应用 =====
cd /opt/app
docker compose pull
docker compose up -d
# 健康检查循环
for i in $(seq 1 12); do
  curl -sf http://localhost:4000/health && break
  sleep 10
done
```

### 5.3 Docker Compose 标准模式

单机部署统一使用 Docker Compose，典型 3 容器架构：

```yaml
services:
  app:                    # 主应用容器
    image: {app-image}
    ports:
      - "4000:4000"
    environment: ...
    depends_on:
      db:
        condition: service_healthy
    healthcheck: ...

  db:                     # 数据库容器
    image: postgres:16
    volumes:
      - ./volumes/db/data:/var/lib/postgresql/data
    healthcheck: ...

  prometheus:             # 监控容器（可选）
    image: prom/prometheus:v2.53.0
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
```

**关键原则：**
- 数据目录挂载到宿主机（`./volumes/`），容器重建不丢数据
- 数据库必须配 healthcheck，应用通过 `depends_on` + `condition` 等待就绪
- 敏感信息走 `.env` 文件，不硬编码在 compose 里

---

## 六、地域差异策略

### 6.1 国内 vs 海外核心差异

| 维度 | 国内 (cn-*) | 海外 (ap-*, eu-*) |
|------|------------|-------------------|
| **Docker 安装源** | `mirrors.huaweicloud.com` | `download.docker.com` |
| **Docker 镜像拉取** | SWR 预推送 + 镜像加速 | 直接从 Docker Hub / ghcr.io |
| **SWR** | 必须 | 不需要 |
| **语言** | 中文 | 英文 |
| **目录后缀** | 无 | `-platform` (非香港区域) |
| **daemon.json** | 需要配置 registry-mirrors | 不需要 |
| **GPG Key** | 华为云镜像 | Docker 官方 |

### 6.2 国内 Docker 安装模式

```bash
# Stage 2: 使用华为云镜像
curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
    https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-compose

# 配置镜像加速
cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://{project-hash}.mirror.swr.myhuaweicloud.com"
  ]
}
EOF
systemctl restart docker

# 拉取镜像（从 SWR）
docker login -u cn-north-4@AK -p SK swr.cn-north-4.myhuaweicloud.com
docker pull swr.cn-north-4.myhuaweicloud.com/{namespace}/litellm:latest
```

### 6.3 海外 Docker 安装模式

```bash
# Stage 2: 使用 Docker 官方源
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-compose-plugin

# 直接拉取，无需镜像加速
docker pull ghcr.io/berriai/litellm-database:main-stable
```

---

## 七、变量设计规范

### 7.1 标准变量清单

所有方案统一包含以下变量：

| 变量名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `solution_name` | string | `"{app}-demo"` | 方案名，所有资源名前缀 |
| `ecs_flavor` | string | `x1.2u.4g` | ECS 规格 |
| `ecs_password` | string(sensitive) | `""` | ECS root 密码 |
| `system_disk_size` | number | `40`-`100` | 系统盘 GB |
| `bandwidth_size` | number | `300` | EIP 带宽 Mbps |
| `charging_mode` | string | `"postPaid"` | 计费模式 |
| `charging_unit` | string | `"month"` | 订购周期类型 |
| `charging_period` | number | `1` | 订购周期 |

### 7.2 应用专属变量

根据应用需求额外添加：

| 变量名 | 适用场景 | 说明 |
|--------|---------|------|
| `db_password` | 有数据库的应用 | PostgreSQL 密码 |
| `master_key` | LiteLLM | API 主密钥 |
| `salt_key` | LiteLLM | 加密盐值 |
| `app_version` | 需要版本管理的应用 | 应用版本号 |

### 7.3 变量验证模式

```hcl
# ECS 规格验证
validation {
  condition     = can(regex("^x1\\.([1-9]|1[0-6])u\\.([1-9][0-9]{0,1}|1[0-2][0-8])g$", var.ecs_flavor))
  error_message = "Invalid ECS flavor format. Example: x1.2u.4g"
}

# 枚举验证
validation {
  condition     = contains(["postPaid", "prePaid"], var.charging_mode)
  error_message = "Must be postPaid or prePaid."
}

# 范围验证
validation {
  condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
  error_message = "System disk size must be between 40 and 1024 GB."
}
```

---

## 八、输出与文档

### 8.1 Output 标准格式

```hcl
output "access_info" {
  description = "Deployment access information"
  value       = <<-EOT
    Wait ~10 minutes for deployment to complete, then access:

    Admin UI:   http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/ui
    API:        http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/v1/chat/completions
    Health:     http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/health/liveliness

    SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address}

    Logs: /var/log/litellm-bootstrap.log
  EOT
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
```

输出内容应包含：访问地址、SSH 命令、日志路径、后续配置步骤。

### 8.2 README 文档标准

每个方案必须包含 README.md，结构如下：

1. **标题** — 方案名 + 一句话描述
2. **方案概述** — 是什么、能做什么
3. **方案架构** — ASCII 架构图 + 资源表
4. **适用场景** — 3-5 个场景
5. **方案优势** — 4-6 个卖点
6. **部署指南** — 前置条件 + 一键部署步骤 + 参数表
7. **开始使用** — 访问方式 + API 示例 + 配置说明
8. **预估费用** — 按资源的费用表
9. **快速卸载** — 删除步骤
10. **更多资源** — 外部链接

---

## 九、目录结构与命名

### 9.1 项目目录结构

```
solution-practices/
├── practices/
│   ├── litellm/                    # 方案根目录
│   │   ├── cn/                     # 中国站
│   │   │   ├── cn-north-4/         # 华北-北京四
│   │   │   │   └── standard/
│   │   │   │       ├── terraform/deploying-litellm.tf
│   │   │   │       ├── terraform/deploying-litellm.tf.json
│   │   │   │       └── .extension
│   │   │   └── docs/
│   │   │       ├── LiteLLM-部署指南_zh.md
│   │   │       └── LiteLLM-方案详情_zh.md
│   │   └── intl/                   # 国际站
│   │       ├── ap-southeast-1/     # 中国-香港（归属 intl 国际站）
│   │       │   └── standard/
│   │       │       ├── terraform/deploying-litellm-ap-southeast-1.tf
│   │       │       ├── .extension
│   │       │       └── scripts/
│   │       ├── ap-southeast-3/     # 亚太-新加坡
│   │       │   └── standard/
│   │       │       ├── terraform/deploying-litellm-ap-southeast-3.tf
│   │       │       └── .extension
│   │       ├── af-south-1/
│   │       ├── ...                 # 其他 intl 区域
│   │       └── docs/
│   │           ├── zh-cn/
│   │           │   ├── LiteLLM-部署指南_zh.md
│   │           │   └── LiteLLM-方案详情_zh.md
│   │           └── en-us/
│   │               ├── LiteLLM-Deployment-Guide_en.md
│   │               └── LiteLLM-Solution-Details_en.md
│
└── skills/
    └── sac-rfs-practices/
        ├── SKILL.md                # 技能包主文件
        └── SAC-技术路线总结.md      # 本文档
```

### 9.2 命名规范

| 对象 | 命名规则 | 示例 |
|------|---------|------|
| 项目根目录 | `{project}` | `litellm` |
| cn 区域目录 | `cn/{region}/{variant}/` | `cn/cn-north-4/standard/` |
| intl 区域目录 | `intl/{region}/{variant}/` | `intl/ap-southeast-3/standard/` |
| 模板（默认区域） | `deploying-{project}.tf` | `deploying-litellm.tf` |
| 模板（非默认区域） | `deploying-{project}-{region}.tf` | `deploying-litellm-ap-southeast-1.tf` |
| 高可用模板 | `deploying-{project}-ha[-{region}].tf` | `deploying-litellm-ha-cn-north-4.tf` |
| 安装脚本 | 非标准交付物，仅例外脚本模式使用 | `install_litellm.sh` |
| 文档（中国站中文） | `{Name}-部署指南_zh.md` / `{Name}-方案详情_zh.md` | `LiteLLM-部署指南_zh.md` |
| 文档（国际站中文） | `{Name}-部署指南_zh.md` / `{Name}-方案详情_zh.md`，位于 `intl/docs/zh-cn/` | `LiteLLM-部署指南_zh.md` |
| 文档（国际站英文） | `{Name}-Deployment-Guide_en.md` / `{Name}-Solution-Details_en.md` | `LiteLLM-Deployment-Guide_en.md` |
| OBS 归档包 | `{project}.zip` | `litellm.zip` |
| 资源名 | `${var.solution_name}-{type}` | `litellm-vpc` |
| 安全组规则 | `{app}_{port}` | `litellm_api` |

---

## 十、已踩坑点速查

| # | 坑 | 现象 | 解法 |
|---|-----|------|------|
| 1 | sshd_config TUI 弹窗 | RFS 部署卡死 | `DEBCONF_NONINTERACTIVE_SEEN=true` + `--force-confdef` |
| 2 | Docker GPG 下载超时 | 国内 ECS 连不上 download.docker.com | 用 `mirrors.huaweicloud.com` |
| 3 | `docker compose` 找不到 | `unknown command: docker compose` | 华为源装的是 v1，用 `docker-compose`（带横杠） |
| 4 | Docker 镜像拉取超时 | 国内连 Docker Hub 超时 | SWR 预推送 + 镜像加速器 |
| 5 | 容器权限拒绝 | EACCES: permission denied | `chown -R UID:GID` 数据目录 |
| 6 | `required_providers` 格式错 | `Duplicate required providers` | 用对象 `{}` 不用数组 `[]` |
| 7 | `random` provider 缺失 | `provider hashicorp/random was not found` | 用稳定的 `solution_name` 或用户输入区分，禁止 `uuid()` |
| 8 | SWR 镜像 400 | 部分镜像拉不到 | SWR 不是通用代理，需预推送 |
| 9 | `${...}` 被 Terraform 解析 | docker-compose 变量报错 | `$${...}` 转义 |
| 10 | `%{...}` 被 Terraform 解析 | curl 格式字符串报错 | `%%{...}` 转义 |
| 11 | pip 下载超时 | 国内 ECS 连 pypi.org 超时 | 用清华/阿里镜像 |
| 12 | GLIBC 版本不匹配 | 二进制文件无法执行 | 用最新 Ubuntu LTS |
| 13 | 空 protocol 字符串 | 安全组规则无效 | 必须指定 `tcp`/`udp`/`icmp` |
| 14 | heredoc 缩进问题 | bash 脚本执行异常 | `<<-` 只去 tab 不去空格，内容左对齐 |
| 15 | PG 保留角色 | 容器反复重启 | 找到真正的 superuser 操作 |
| 16 | 环境变量缺失 | 容器无限重启 | `.env` 动态生成 + 启动后检查日志 |
| 17 | 空挂载覆盖初始化 | 数据库缺表/缺扩展 | 不挂载 `/docker-entrypoint-initdb.d` |
| 18 | RDS 替换内置 PG | 功能缺失 | 仅限原生 PG，自定义 PG 不可行 |

---

## 十一、决策点框架

创建新方案时，需确认以下决策：

| # | 决策点 | 选项 | 默认 |
|---|--------|------|------|
| 1 | 模板格式 | `.tf` (HCL) / `.tf.json` (JSON) | 问用户 |
| 2 | 安装策略 | 内联 user_data / OBS 下载 | 默认内联；OBS 下载为例外 |
| 3 | 地域 | 国内 (cn-*) / 海外 (ap-*) | 问用户 |
| 4 | 语言 | 中文 / 英文 | 跟随地域 |
| 5 | 脚本架构 | 单文件 / 多文件 | 默认单文件内联；多文件为例外 |
| 6 | 部署文档 | 必须输出 README.md | 强制 |
| 7 | 命名规范 | `{project}` / `-platform` | 跟随地域 |

---

## 十二、从零创建新方案的标准流程

```
1. 确认决策点
   ├── 格式：.tf 还是 .tf.json？
   ├── 地域：国内还是海外？
   ├── 安装：默认内联；如需 OBS 脚本需说明原因
   └── 语言：中文还是英文？

2. 创建目录
   practices/{project}[-platform]/

3. 编写模板
   ├── terraform + provider 块
   ├── 变量定义（7 核心 + 应用专属）
   ├── 数据源（镜像查询）
   ├── 网络资源（VPC → Subnet → SecGroup → EIP）
   ├── ECS 资源（含 user_data）
   └── 输出（访问信息）

4. 编写 user_data
   ├── Stage 1: 系统准备
   ├── Stage 2: Docker 安装（国内/海外选择）
   ├── Stage 3: 应用配置（.env + compose + config）
   └── Stage 4: 启动 + 健康检查

5. 编写 README.md
   └── 10 个标准章节

6. 测试验证
   ├── RFS 控制台部署
   ├── SSH 检查日志
   ├── 访问应用
   └── 验证端口/功能

7. 打包上传
   └── obs://{bucket}/{project}[-platform].zip
```

---

*文档版本：2026-06-04*
*基于 LiteLLM、n8n、Supabase、Hermes 等方案实践总结*
