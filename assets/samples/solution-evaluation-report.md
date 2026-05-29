---
name: solution-evaluation-report
description: 华为云行业解决方案落地实践全维度技术评估报告 — 基于RFS+Terraform的一键部署架构评审
---

# 华为云行业解决方案实践全维度技术评估报告

> **评估对象：基于 RFS + Terraform 的行业解决方案一键部署体系**
> **样本项目：Hermes Agent / OpenHuman + Ollama 智能助手平台**
> **评估日期：2026-05-21**
> **适用场景：华为云 Solution as Code 开源方案落地**

---

## 目录

1. [核心架构总览](#1-核心架构总览)
2. [流程架构梳理](#2-流程架构梳理)
3. [TF 模板编写要点](#3-tf-模板编写要点)
4. [RFS 调用配置参数](#4-rfs-调用配置参数)
5. [user_data 脚本注入规范](#5-user_data-脚本注入规范)
6. [一键部署执行逻辑](#6-一键部署执行逻辑)
7. [多维度技术评审](#7-多维度技术评审)
8. [落地注意事项](#8-落地注意事项)
9. [优化改造方案](#9-优化改造方案)

---

## 1. 核心架构总览

### 1.1 整体架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                        用户 / 客户                                    │
│              华为云控制台 / RFS API / 解决方案实践库                    │
└───────────────────────────┬─────────────────────────────────────────┘
                            │ 一键部署
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    RFS 资源编排服务                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │ 模板解析     │  │ 执行计划     │  │ 资源栈管理   │                  │
│  │ .tf / .tf.json│  │ 变更预览    │  │ 创建/删除    │                  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                  │
│         │                │                │                          │
│         ▼                ▼                ▼                          │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │              Terraform Core Engine                       │       │
│  │  huaweicloud provider (source: huawei.com/provider/...)  │       │
│  └──────────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  网络层          │ │  计算层          │ │  存储/中间件     │
│  VPC            │ │  ECS / Flexus X  │ │  RDS / DCS      │
│  子网            │ │  CCE / BMS      │ │  OBS / SFS      │
│  安全组 + 规则   │ │  GPU ECS        │ │  ELB / DMS      │
│  EIP + 带宽      │ │                 │ │                 │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         │          ┌────────┴────────┐          │
         │          │  user_data 注入  │          │
         │          ▼                 ▼          │
         │   ┌──────────────────────────────┐    │
         │   │  业务部署层                   │    │
         │   │  ┌────────────────────────┐  │    │
         │   │  │ Hermes Agent / OpenHuman│  │    │
         │   │  │ Ollama 推理引擎          │  │    │
         │   │  │ Nginx 反向代理           │  │    │
         │   │  │ Docker 运行环境          │  │    │
         │   │  └────────────────────────┘  │    │
         │   └──────────────────────────────┘    │
         └──────────────────┬────────────────────┘
                            ▼
              ┌─────────────────────────┐
              │  业务上线               │
              │  https://{EIP}/ → Hermes│
              │  API → Ollama → 推理结果 │
              └─────────────────────────┘
```

### 1.2 分层职责

| 层级 | 组件 | 职责 | 生命周期 |
|------|------|------|---------|
| **编排层** | RFS + Terraform Core | 解析 HCL/JSON 模板，生成执行计划，驱动资源创建 | 模板定义即生命周期 |
| **Provider 层** | huaweicloud provider | 对接华为云 API，管理具体云资源 | 随 RFS 版本升级 |
| **资源层** | VPC/Subnet/SG/EIP/ECS/RDS/OBS/ELB | 基础设施即代码，声明式定义终态 | RFS Stack 管理 |
| **注入层** | cloud-init / user_data | ECS 首次启动时自动执行 Shell 脚本 | 仅首次启动 |
| **应用层** | Ollama / Hermes Agent / Nginx | 业务服务安装、配置、启动、自愈 | systemd 管理 |
| **接入层** | EIP + Nginx → 用户访问 | 对外暴露服务入口 | 持续运行 |

### 1.3 数据流

```
用户浏览器 ──HTTP──▶ EIP:80 ──▶ Nginx ──proxy──▶ Hermes Agent:8080 ──API──▶ Ollama:11434
                                                                                │
                                                                        ┌───────┴───────┐
                                                                        │ DeepSeek/Qwen │
                                                                        │ 本地推理模型    │
                                                                        └───────────────┘
```

---

## 2. 流程架构梳理

### 2.1 全链路部署流程

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Step 1  │   │  Step 2  │   │  Step 3  │   │  Step 4  │   │  Step 5  │   │  Step 6  │
│ 进入解决 │──▶│ 选择模板 │──▶│ 配置参数 │──▶│ 委托设置 │──▶│ 创建执行 │──▶│ 部署执行 │
│ 方案库   │   │          │   │          │   │ (可选)   │   │ 计划     │   │          │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
                                                                                        │
                                                                                        ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Step 10 │   │  Step 9  │   │  Step 8  │   │  Step 7  │   │          │   │          │
│ 开始使用 │◀──│ 部署完成 │◀──│ 费用支付 │◀──│ 资源创建 │◀──│          │   │          │
│          │   │ 获取输出 │   │ (可选)   │   │ + 脚本   │   │          │   │          │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
```

### 2.2 RFS 内部执行时序

```
用户                            RFS                        Terraform Core            Huawei Cloud API
 │                               │                              │                        │
 │──上传模板(.tf.json)──────────▶│                              │                        │
 │                               │──解析模板──────────────────▶│                        │
 │                               │                              │──查询可用区───────────▶│
 │                               │                              │◀──返回可用区列表───────│
 │                               │                              │──查询规格/镜像────────▶│
 │                               │                              │◀──返回规格/镜像───────│
 │                               │◀──返回参数列表──────────────│                        │
 │──填写参数────────────────────▶│                              │                        │
 │                               │──创建执行计划──────────────▶│                        │
 │                               │                              │──预检查资源──────────▶│
 │                               │                              │◀──返回检查结果────────│
 │                               │◀──返回执行计划──────────────│                        │
 │──确认执行────────────────────▶│                              │                        │
 │                               │──apply─────────────────────▶│                        │
 │                               │                              │──创建VPC─────────────▶│
 │                               │                              │◀──返回VPC ID─────────│
 │                               │                              │──创建子网────────────▶│
 │                               │                              │◀──返回子网ID─────────│
 │                               │                              │──创建安全组──────────▶│
 │                               │                              │──创建EIP─────────────▶│
 │                               │                              │──创建ECS────────────▶│
 │                               │                              │  (user_data注入)      │
 │                               │                              │◀──返回ECS信息────────│
 │                               │                              │──等待ECS完成─────────▶│
 │                               │                              │◀──ECS running────────│
 │                               │◀──部署完成──────────────────│                        │
 │                               │                              │                        │
 │                               │   ┌── ECS user_data 自动执行 ──┐                     │
 │                               │   │ Phase 1: 环境检测          │                     │
 │                               │   │ Phase 2: 系统依赖安装       │                     │
 │                               │   │ Phase 3: Ollama 安装与配置  │                     │
 │                               │   │ Phase 4: Hermes Agent 部署  │                     │
 │                               │   │ Phase 5: Nginx 反向代理配置  │                     │
 │                               │   │ Phase 6: 服务注册 systemd   │                     │
 │                               │   │ Phase 7: 健康检查与输出      │                     │
 │                               │   └────────────────────────────┘                     │
 │◀──返回outputs────────────────│                              │                        │
 │   (web_url, ecs_id, ...)     │                              │                        │
```

### 2.3 部署耗时分布

```
┌──────────────────────────────────────────────────────────────────┐
│  总耗时: ≈ 8-15 分钟                                              │
│                                                                  │
│  模板解析 + 执行计划:  2-10s                                      │
│  VPC + 子网 + 安全组:  5-15s                                      │
│  EIP + 带宽:          3-8s                                        │
│  ECS 创建:           30-90s  (规格越大越慢)                       │
│  ECS 初始化 + user_data:  3-8min  (依赖下载速度)                  │
│  └─ apt/yum 更新:      1-3min                                     │
│  └─ Ollama 模型拉取:    2-5min  (后台异步, 不阻塞部署完成状态)     │
│  └─ Hermes Agent 安装:  30-60s                                    │
│  应用就绪(模型到位):     +5-15min (后台异步)                       │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. TF 模板编写要点

### 3.1 模板格式选型

| 格式 | 适用场景 | 优缺点 |
|------|---------|--------|
| **HCL (`.tf`)** | 人工编写，复杂逻辑 | 可读性强，支持条件/循环，RFS 完整支持 |
| **JSON (`.tf.json`)** | 机器生成，API 调用 | 程序友好，适合 CI/CD 自动化生成 |

**推荐**：人工维护的解决方案实践采用 HCL 格式（`.tf`）；平台自动化生成的采用 JSON 格式（`.tf.json`）。

### 3.2 核心文件组织

```
solution-name/
├── .extension                    # [必选] RFS 参数 UI 增强
├── versions.tf                   # [必选] Provider 版本
├── providers.tf                  # [必选] Provider 配置（无AK/SK）
├── variables.tf                  # [必选] 输入参数定义
├── main.tf                       # [必选] 资源编排执行入口
├── outputs.tf                    # [推荐] 输出定义
├── userdata/                     # [推荐] 应用部署脚本
│   └── install.sh
└── README.md                     # [推荐] 方案文档
```

### 3.3 resource 定义规范

```hcl
# 1. 使用隐式依赖，不写 depends_on
resource "huaweicloud_vpc_subnet" "main" {
  vpc_id = huaweicloud_vpc.main.id    # 隐式依赖
}

# 2. 多实例用 count / for_each
resource "huaweicloud_compute_instance" "cluster" {
  count = var.ecs_count
  name  = "${var.cluster_name}-ecs-${count.index + 1}"
}

# 3. tags 标记所有资源
resource "huaweicloud_compute_instance" "main" {
  tags = {
    Name        = var.ecs_name
    managed_by  = "rfs"
    owner       = "solution"          # 统一标记便于成本分析
  }
}

# 4. 敏感信息变量化
variable "ecs_password" {
  type      = string
  sensitive = true                    # 防止日志泄露
}
```

### 3.4 user_data 注入规范

```hcl
# 推荐方式：filebase64 引用外部脚本
resource "huaweicloud_compute_instance" "main" {
  user_data = filebase64("${path.module}/userdata/install.sh")
}

# 备选方式：内联脚本（不推荐，仅用于极简场景）
resource "huaweicloud_compute_instance" "main" {
  user_data = <<-EOT
    #!/bin/bash
    echo "Hello" > /tmp/test
  EOT
}
```

### 3.5 Provider 关键约束

```hcl
terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"   # RFS 专用 source
      version = ">= 1.56.0"                          # 推荐宽松约束
    }
  }
}

provider "huaweicloud" {
  region = var.region                                 # region 变量化
  # 禁止硬编码 access_key / secret_key
  # 通过环境变量 HW_ACCESS_KEY / HW_SECRET_KEY 传入
}
```

---

## 4. RFS 调用配置参数

### 4.1 典型参数配置表（以 Hermes Agent 方案为例）

| 参数 | 类型 | 必填 | 说明 | 推荐值 |
|------|------|------|------|--------|
| `region` | string | 是 | 部署区域 | `cn-north-4` |
| `vpc_name` | string | 是 | VPC 名称 | `hermes-agent-vpc` |
| `subnet_cidr` | string | 是 | 子网网段 | `10.0.1.0/24` |
| `availability_zone` | string | 是 | 可用区 | 自动查询 |
| `ecs_name` | string | 是 | ECS 名称 | `hermes-agent-server` |
| `ecs_flavor` | string | 是 | 规格 | `x1.4u.8g` (4C8G) |
| `image_id` | string | 是 | 镜像 ID | Ubuntu 22.04 |
| `ecs_password` | string(敏感) | 是 | 管理员密码 | 用户输入 |
| `system_disk_size` | number | 是 | 系统盘大小(GB) | `100` |
| `data_disk_size` | number | 否 | 数据盘大小(GB) | `200` |
| `bandwidth_size` | number | 是 | 带宽(Mbit/s) | `5` |
| `charging_mode` | string | 是 | 计费模式 | `postPaid` |
| `charging_unit` | string | 条件 | 周期类型(prePaid) | `month` |
| `charging_period` | number | 条件 | 周期数量(prePaid) | `1` |
| `ollama_model` | string | 否 | Ollama 模型名 | `qwen2.5:7b` |
| `hermes_version` | string | 否 | Hermes 版本 | `latest` |

### 4.2 .extension 分组配置

```json
{
  "variables": {
    "grouping": {
      "network_config": {
        "label": "网络配置",
        "description": "配置虚拟私有云和子网"
      },
      "ecs_config": {
        "label": "云服务器配置",
        "description": "配置 ECS 规格、镜像、登录密码"
      },
      "app_config": {
        "label": "应用配置",
        "description": "配置 Ollama 模型和 Hermes Agent 参数"
      },
      "billing_config": {
        "label": "计费配置",
        "description": "选择计费模式和订购周期"
      }
    }
  }
}
```

### 4.3 RFS 委托配置

| 委托类型 | 权限范围 | 适用场景 |
|---------|---------|---------|
| `rf_admin_trust` | 资源编排全权限 | 推荐：自动创建所有资源 |
| 自定义委托 | 限定服务权限 | 企业安全管控场景 |
| 不指定委托 | 使用当前用户权限 | 主账号 / admin 子账号 |

### 4.4 删除保护与回滚

```hcl
# 在 Terraform 中设置删除保护
resource "huaweicloud_rds_instance" "main" {
  # ...
}

# RFS 控制台设置
# - 删除保护: 开启（防止误删）
# - 回滚配置: 部署失败时自动回滚
# - 超时设置: 资源创建超时（默认 30min）
```

---

## 5. user_data 脚本注入规范

### 5.1 脚本设计原则

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| **幂等性** | 重复执行不破坏状态 | 每次执行前检测已安装标记文件 `/opt/.installed` |
| **健壮性** | 部分失败不影响整体 | `set -euo pipefail` + 阶段分离 + trap 错误处理 |
| **可观测** | 全流程日志可追溯 | `tee -a $LOG_FILE` + 时间戳 + 阶段标记 |
| **可配置** | 参数外部化 | 环境变量注入 / RFS variables 传入 |
| **可回滚** | 失败可清理 | 每个 phase 记录 checkpoint |

### 5.2 脚本标准结构

```bash
#!/bin/bash
set -euo pipefail

# === 固定开头：日志配置 ===
LOG_FILE="/var/log/solution-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# === 配置区（变量覆盖）===
PARAM1="${PARAM1:-default_value}"
PARAM2="${PARAM2:-default_value}"

# === Phase 1: 环境检测 ===
# 检测 OS / 资源 / 网络

# === Phase 2: 系统依赖安装 ===
# 安装 Docker / Nginx / 运行时

# === Phase 3: 应用安装 ===
# 下载 Release / 编译 / 配置

# === Phase 4: 服务配置 ===
# 写入配置文件 / 设置 systemd

# === Phase 5: 启动与健康检查 ===
# systemctl start / curl 健康检测

# === Phase 6: 输出摘要 ===
# 打印部署结果关键信息
```

### 5.3 幂等实现模式

```bash
# 幂等标记
INSTALL_FLAG="/opt/.solution-installed"
if [ -f "$INSTALL_FLAG" ]; then
    echo "[SKIP] 检测到已安装标记，跳过安装"
    exit 0
fi

# 阶段 checkpoint 文件
checkpoint() {
    echo "$1" >> /tmp/install-checkpoints
}

if grep -q "phase3" /tmp/install-checkpoints 2>/dev/null; then
    echo "[SKIP] Phase 3 已完成，跳过"
else
    # 执行 Phase 3
    checkpoint "phase3"
fi

# 安装完成后创建标记
touch "$INSTALL_FLAG"
```

### 5.4 错误处理模式

```bash
# 非致命错误容忍
command_that_might_fail || echo "[WARN] 非关键步骤失败，继续执行"

# 致命错误处理
fatal() {
    echo "[FATAL] $1"
    # 发送告警到 CES / SMN
    exit 1
}

# 超时控制
timeout 300 curl -fsSL https://example.com/bigfile.tar.gz || fatal "下载超时"
```

### 5.5 脚本兼容性矩阵

| 项目 | Ubuntu 22.04 | CentOS 7.9 | Anolis OS 8 | openEuler 22.03 |
|------|-------------|-----------|-------------|-----------------|
| 包管理器 | apt | yum | yum | yum |
| Docker 安装 | apt install | yum + repo | yum + repo | yum + repo |
| Nginx 安装 | apt install | yum install | yum install | yum install |
| systemd 兼容 | 原生 | 原生 | 原生 | 原生 |
| Python 版本 | 3.10 | 3.6 | 3.8 | 3.9 |
| cloud-init | 内置 | 需检查 | 内置 | 内置 |

---

## 6. 一键部署执行逻辑

### 6.1 执行流状态机

```
                  ┌──────────────┐
                  │  INITIAL     │ 用户进入解决方案库
                  └──────┬───────┘
                         │ 选择模板
                         ▼
                  ┌──────────────┐
                  │  CONFIGURING │ 填写参数 + .extension 校验
                  └──────┬───────┘
                         │ 参数校验通过
                         ▼
                  ┌──────────────┐
                  │  PLANNING    │ 创建执行计划（Terraform plan）
                  └──────┬───────┘
                    ┌────┴────┐
                    ▼         ▼
            ┌──────────┐  ┌──────────┐
            │ PLAN_OK  │  │ PLAN_ERR │ 参数问题，返回 CONFIGURING
            └────┬─────┘  └──────────┘
                 │ 用户确认
                 ▼
          ┌──────────────┐
          │  APPLYING    │ Terraform apply
          └──────┬───────┘
           ┌─────┴──────┐
           ▼             ▼
    ┌──────────┐   ┌──────────┐
    │ SUCCESS  │   │ FAILED   │ ← 自动回滚
    └────┬─────┘   └──────────┘
         │ 脚本自动执行
         ▼
    ┌──────────────┐
    │  WAITING     │ 等待 user_data 完成（5-10min）
    └──────┬───────┘
           │ outputs 输出
           ▼
    ┌──────────────┐
    │  COMPLETED   │ 获取访问地址
    └──────────────┘
```

### 6.2 关键事件序列

| 阶段 | RFS 事件 | 状态 | 用户操作 |
|------|---------|------|---------|
| 1 | 解析模板参数 | `IN_PROGRESS` → `SUCCESS` | 填写参数 |
| 2 | 创建执行计划 | `IN_PROGRESS` → `SUCCESS` | 确认部署 |
| 3 | 部署资源 | `IN_PROGRESS` | 等待 |
| 4 | VPC 创建完成 | `SUCCESS` | — |
| 5 | 子网创建完成 | `SUCCESS` | — |
| 6 | 安全组创建完成 | `SUCCESS` | — |
| 7 | ECS 创建中 | `IN_PROGRESS` | — |
| 8 | ECS 创建完成 | `SUCCESS` | — |
| 9 | user_data 执行中 | 无状态（ECS 内部） | — |
| 10 | Apply required resource success | `SUCCESS` | 查看 outputs |
| 11 | 应用就绪 | 无状态（手动验证） | 访问应用 |

### 6.3 超时与重试策略

| 场景 | 超时时间 | 重试策略 |
|------|---------|---------|
| ECS 创建 | 30min | 自动重试 1 次 |
| EIP 绑定 | 5min | 自动重试 2 次 |
| RDS 创建 | 40min | 自动重试 1 次 |
| user_data 执行 | 无超时（ECS 内部） | 脚本内部超时 |
| 整个资源栈 | 120min | 手工重新部署 |

---

## 7. 多维度技术评审

### 7.1 评审总表

| 维度 | 权重 | 评分 | 关键发现 |
|------|------|------|---------|
| **技术可行性** | ★★★★★ | ★★★★★ | 方案成熟：基于华为云 RFS + Terraform 标准能力，已在 FastGPT/Hermes Agent 等方案验证 |
| **部署效率** | ★★★★★ | ★★★★☆ | 全自动化部署，8-15 分钟完成；模型拉取后台异步不阻塞主流程 |
| **运维便捷性** | ★★★★☆ | ★★★★☆ | systemd 管理服务自愈；但无内置监控告警，需对接 CES |
| **脚本兼容性** | ★★★★☆ | ★★★★☆ | 支持 Ubuntu/CentOS/Anolis/openEuler；各发行版包管理器差异需分支处理 |
| **TF 模板通用性** | ★★★★★ | ★★★★★ | HCL 模板完整解耦：变量参数化、资源独立、可复用为其他方案骨架 |
| **RFS 编排稳定性** | ★★★★★ | ★★★★☆ | 标准资源编排稳定；GPU ECS 等特殊规格依赖区域库存，可能因资源不足失败 |
| **批量集群部署** | ★★★☆☆ | ★★★☆☆ | count/for_each 支持水平扩展；但 Terraform 线性执行，大规模集群（50+节点）效率下降 |
| **故障回滚机制** | ★★★★☆ | ★★★☆☆ | RFS 支持自动回滚；但 user_data 执行失败无法自动感知，需手工排查 |

### 7.2 详细评审

#### 7.2.1 技术可行性 — ★★★★★

**通过标准**：方案基于华为云现有正式发布的服务，无技术障碍。

- **RFS 服务状态**：已商用，支持 HCL/JSON/TF 模板
- **huaweicloud provider**：v1.97+，覆盖 800+ 资源
- **ECS + user_data**：标准能力，cloud-init 原生支持
- **GPU ECS**：p2v/p2vs 系列已商用，支持 Ollama 推理
- **Ollama 安装**：Linux 官方脚本，验证通过
- **结论**：全部使用华为云成熟服务，无技术风险

#### 7.2.2 部署效率 — ★★★★☆

**瓶颈分析**：

| 阶段 | 耗时 | 是否可优化 |
|------|------|-----------|
| 模板解析 | 2-10s | 已最优 |
| 网络资源创建 | 15-30s | 已最优 |
| ECS 创建 | 30-90s | 取决于规格 and 区域库存 |
| apt/yum 更新 | 60-180s | **可优化**：使用华为云镜像源 |
| Ollama 下载 | 30-60s | 受 GitHub 网络影响 |
| 模型拉取 | 2-5min | 后台异步，不阻塞 |
| Docker 镜像拉取 | 60-120s | 可用 SWR 镜像加速 |

**优化建议**：
1. apt/yum 源切换到 `mirrors.huaweicloud.com`（节省 60-120s）
2. 预置常用 Docker 镜像到 SWR（节省 pull 时间）
3. 模型文件预下载到 OBS，user_data 从 OBS 拉取（绕过 GitHub 限速）

#### 7.2.3 运维便捷性 — ★★★★☆

| 运维场景 | 当前能力 | 改进方向 |
|---------|---------|---------|
| 服务自愈 | systemd Restart=always | 无 |
| 日志查看 | journalctl / 日志文件 | 对接 LTS 集中日志 |
| 监控告警 | 无内置 | 对接 CES + SMN 告警 |
| 备份恢复 | 无自动备份 | 对接 CBR 策略备份 |
| 扩缩容 | 手动修改 count | 对接 AS 弹性伸缩 |
| 版本升级 | 手动更新脚本 | CI/CD 自动发布 |
| 成本管理 | tags 标记资源 | 对接 Cost Center |

#### 7.2.4 脚本兼容性 — ★★★★☆

**已验证兼容的 OS**：
- Ubuntu 20.04 / 22.04 ✅（推荐）
- CentOS 7.9 / 8.4 ✅
- Anolis OS 8.8 ✅
- openEuler 22.03 LTS ✅

**差异点**：
```bash
# 包管理器差异
apt-get install -y nginx        # Debian 系
yum install -y nginx            # RHEL 系

# Docker 安装差异
apt-get install -y docker.io    # Ubuntu 直接安装
# CentOS 需先添加 repo
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 网络工具差异
ss -tlnp                        # 通用
ip addr                         # 通用
ifconfig                        # 可能需安装 net-tools
```

#### 7.2.5 TF 模板通用性 — ★★★★★

本报告使用的模板模式可抽象为通用骨架，适配任意 Web 类解决方案：

```hcl
# 通用骨架：替换 {solution_name} 即可
resource "huaweicloud_vpc" "main" { name = "{solution_name}-vpc" }
resource "huaweicloud_vpc_subnet" "main" { ... }
resource "huaweicloud_networking_secgroup" "main" { ... }
resource "huaweicloud_vpc_eip" "main" { ... }
resource "huaweicloud_compute_instance" "main" {
  name      = "{solution_name}-server"
  user_data = filebase64("${path.module}/userdata/install.sh")
  ...
}
output "web_url" { value = "http://${huaweicloud_vpc_eip.main.address}" }
```

**已适配的方案**：
| 方案 | 仅需替换 | user_data |
|------|---------|-----------|
| FastGPT | ecs_flavor + user_data | FastGPT 安装脚本 |
| Hermes Agent | ecs_flavor + user_data | hermesagent_install.sh |
| Dify | ecs_flavor + user_data + RDS | Dify docker-compose |
| DeepSeek | GPU规格 + user_data | Ollama + DeepSeek 模型 |
| 智能问数 | ecs_flavor + user_data + RDS | 问数平台安装脚本 |

#### 7.2.6 RFS 编排稳定性 — ★★★★☆

| 风险场景 | 概率 | 影响 | 应对措施 |
|---------|------|------|---------|
| 资源库存不足 | 低 | 高（部署失败） | 多可用区 fallback |
| API 限流 | 低 | 中（重试可恢复） | RFS 内置重试 |
| Provider 版本兼容 | 低 | 高 | 固定 version 约束 |
| 资源创建超时 | 中 | 中 | 增加超时时间 |
| user_data 静默失败 | 中 | 高 | 脚本内健康检查 + 日志 |

#### 7.2.7 批量集群部署能力 — ★★★☆☆

| 集群规模 | 部署方式 | 预估时间 | 限制因素 |
|---------|---------|---------|---------|
| 单节点 | 直接部署 | 8-12min | — |
| 3-5 节点 | count/for_each | 15-25min | 线性创建 |
| 10-20 节点 | count + 并行子网 | 30-60min | Terraform 线性执行 |
| 50+ 节点 | AS 弹性伸缩 | 按需扩容 | 不建议 TF 管理大批量 |

**优化建议**：大批量场景使用 AS（弹性伸缩组）管理 ECS 数量，TF 只管理 AS 组配置。

#### 7.2.8 故障回滚机制 — ★★★☆☆

| 故障层级 | RFS 回滚 | 数据影响 | 说明 |
|---------|---------|---------|------|
| VPC 创建失败 | 自动回滚 | 无损 | 所有资源未创建 |
| ECS 创建失败 | 自动回滚 | 无损 | VPC 等已创建资源被回收 |
| user_data 脚本失败 | **无法自动回滚** | ECS 已创建但应用不可用 | **最大风险点** |
| 应用运行时故障 | 不涉及 | 不影响云资源 | systemd 自愈 |

**user_data 失败场景的应对**：
1. 脚本内设置 `set -e` 及早 fail
2. 关键步骤记录 checkpoint
3. 通过 outputs 输出健康状态供用户判断
4. 提供一键卸载能力（删除资源栈）

---

## 8. 落地注意事项

### 8.1 网络安全

```hcl
# 安全组最小权限原则
resource "huaweicloud_networking_secgroup_rule" "allow_ssh" {
  # 不推荐 0.0.0.0/0，建议限制为管理 IP
  remote_ip_prefix = "0.0.0.0/0"    # 生产环境应改为特定 IP
}
```

**要点**：
- 安全组规则遵循最小权限原则，仅开放必要端口（22/80/443/11434）
- 数据库端口（3306/5432）不对公网开放，仅允许 VPC 内访问
- 建议生产环境使用 EIP + 安全组白名单

### 8.2 费用控制

| 资源 | 规格 | 月预估费用 |
|------|------|-----------|
| ECS (Flexus X) | x1.4u.8g | ≈ ¥200-300 |
| GPU ECS | p2v.2xlarge | ≈ ¥3000-5000 |
| EIP 带宽 | 5Mbit/s 按流量 | ≈ ¥50-100 |
| RDS MySQL | 2C4G 40GB | ≈ ¥200-400 |
| OBS 存储 | 标准存储 | ≈ ¥10-50 |

**省钱策略**：
- 开发测试用按需计费 (`postPaid`)，用完删除
- 生产环境用包年包月 (`prePaid`)，费用降 30-50%
- GPU ECS 支持按需 + 关机不计费（不运行时节省费用）
- OBS 生命周期管理，30 天后转为归档

### 8.3 区域选择

| 区域 | GPU 可用性 | 适用场景 |
|------|-----------|---------|
| cn-north-4 (北京四) | ✅ p2v/p2vs 充足 | 推荐，资源最全 |
| cn-east-3 (上海一) | ✅ p2v 充足 | 华东业务 |
| cn-south-1 (广州) | ✅ p2v 可用 | 华南业务 |
| ap-southeast-1 (新加坡) | ❌ GPU 受限 | 国际业务 |

### 8.4 镜像选择

| 镜像 | 版本 | 推荐场景 |
|------|------|---------|
| Ubuntu | 22.04 LTS | **首选**：包新、社区活跃、Ollama 官方支持 |
| Anolis OS | 8.8 | 国产化需求 |
| openEuler | 22.03 LTS | 信创场景 |

---

## 9. 优化改造方案

### 9.1 架构优化

#### 9.1.1 当前架构（单机部署）

```
ECS ×1 (应用 + 推理 + 数据库)
```

**优点**：简单、成本低
**缺点**：单点故障、无法水平扩展

#### 9.1.2 目标架构（高可用生产级）

```
┌──────────┐    ┌──────────────────────────────────────┐
│  ELB     │───▶│  ECS Cluster (应用层)                 │
│  (公网)  │    │  ├─ Hermes Agent Node 1               │
│          │    │  ├─ Hermes Agent Node 2               │
│          │    │  ├─ Hermes Agent Node N               │
│          │    │  └─ ...                               │
└──────────┘    └──────────────────────────────────────┘
                        │
                        ▼
                ┌──────────────┐      ┌──────────────────┐
                │  GPU ECS     │      │  RDS / Redis     │
                │  Ollama 推理  │      │  共享存储/缓存    │
                └──────────────┘      └──────────────────┘
                        │
                        ▼
                ┌──────────────┐
                │  OBS / SFS   │
                │  模型文件 +   │
                │  持久化数据   │
                └──────────────┘
```

#### 9.1.3 优化建议优先级

| 优先级 | 优化项 | 效果 | 复杂度 |
|--------|-------|------|--------|
| P0 | apt/yum 源切换华为云镜像 | 部署提速 60-120s | 低 |
| P0 | 模型通过 OBS 分发替代 GitHub | 提速 3-5min，不受 GitHub 限速 | 低 |
| P1 | 对接 CES 监控 + SMN 告警 | 可观测性 | 中 |
| P1 | 对接 LTS 集中日志 | 排障效率 | 中 |
| P2 | CBR 自动备份策略 | 数据安全 | 低 |
| P2 | SWR 镜像加速 | 部署提速 | 中 |
| P3 | AS 弹性伸缩组 | 生产高可用 | 高 |
| P3 | 多 ELB + 多可用区部署 | 容灾 | 高 |

### 9.2 TF 模板优化

#### 9.2.1 模块化改造

```hcl
# 当前：单文件 main.tf
# 优化后：模块化拆分
modules/
├── vpc/          # VPC + 子网 + 安全组
├── ecs/          # ECS + EIP + user_data
├── rds/          # RDS 实例
└── elb/          # 负载均衡

# 主模板引用模块
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}
module "ecs" {
  source    = "./modules/ecs"
  subnet_id = module.vpc.subnet_id
  user_data = filebase64("${path.module}/userdata/install.sh")
}
```

#### 9.2.2 条件表达式

```hcl
# 根据计费模式动态设置
resource "huaweicloud_compute_instance" "main" {
  charging_mode = var.charging_mode
  //
  period_unit = var.charging_mode == "prePaid" ? var.charging_unit : null
  period      = var.charging_mode == "prePaid" ? var.charging_period : null
}
```

### 9.3 脚本优化

#### 9.3.1 镜像源加速

```bash
# Ubuntu 切换华为云镜像源
sed -i 's|http://archive.ubuntu.com|https://mirrors.huaweicloud.com|g' /etc/apt/sources.list
sed -i 's|http://security.ubuntu.com|https://mirrors.huaweicloud.com|g' /etc/apt/sources.list

# CentOS 切换镜像源
sed -i 's|mirror.centos.org|mirrors.huaweicloud.com|g' /etc/yum.repos.d/*.repo
```

#### 9.3.2 模型 OBS 加速分发

```bash
# 从 OBS 拉取模型（替换官方下载）
OBS_BUCKET="solution-models-${region}"
OBS_PATH="models/${OLLAMA_MODEL}/"

# 优先从 OBS 拉取
if obsutil ls "obs://${OBS_BUCKET}/${OBS_PATH}" &>/dev/null; then
    obsutil cp "obs://${OBS_BUCKET}/${OBS_PATH}" /usr/share/ollama/models/ -f -r
    echo "  [OK] 模型从 OBS 加载"
else
    ollama pull "$OLLAMA_MODEL"   # 降级到官方源
fi
```

### 9.4 CI/CD 集成方案

```
Git Push (tf + sh 代码)
    │
    ▼
CodeArts Pipeline
    │
    ├── 语法检查: terraform validate
    ├── 模板检查: python validate_template.py
    ├── 安全扫描: AK/SK 泄露检测
    │
    ▼
自动打包 (zip)
    │
    ▼
上传 OBS
    │
    ▼
RFS 私有模板更新
    │
    ▼
通知解决方案实践库更新
```

---

## 附录 A: 样本文件清单

```
huaweicloud-rfs-deploy/assets/samples/
├── hermesagent_install.sh           # Hermes Agent 安装脚本（230 行）
├── solution-evaluation-report.md    # 本评估报告
└── tf-templates/
    ├── versions.tf
    ├── providers.tf
    ├── variables.tf
    ├── main.tf
    ├── outputs.tf
    └── .extension
```

## 附录 B: 相关链接

| 资源 | 链接 |
|------|------|
| 华为云 RFS 文档 | https://support.huaweicloud.com/rfs/ |
| Terraform Provider 文档 | https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest |
| 解决方案实践库 | https://www.huaweicloud.com/solution/implementations/ |
| Gitee 仓库组织 | https://gitee.com/HuaweiCloudDeveloper |
| FastGPT 方案文档 | https://support.huaweicloud.com/fastgpt-aislt/fastgpt_01.html |
| Hermes Agent 方案 | https://support.huaweicloud.com/hermes-aislt/hermes_01.html |
| OpenHuman 项目 | https://github.com/tinyhumansai/openhuman |
| Ollama 官方 | https://ollama.com |
| 市场自动部署模板开发 | https://support.huaweicloud.com/usermanual-marketplace/zh-cn_topic_0070649328.html |
