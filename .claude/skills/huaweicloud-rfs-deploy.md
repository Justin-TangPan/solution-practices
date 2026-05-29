---
name: huaweicloud-rfs-deploy
description: 华为云解决方案实践全生命周期工具 — 基于 RFS + Terraform 生成一键订购/部署模板，涵盖架构设计、TF 资源编排、.extension 增强配置、userdata 脚本、部署文档全链路，并支持8维度技术评估与方案评审
metadata:
  type: skill
---

# 华为云解决方案实践生成器 (RFS + Terraform)

## 触发条件

当用户要求创建华为云解决方案实践 / RFS 部署模板 / 一键部署方案时触发。

**触发关键词**：
- 生成类："创建一个华为云解决方案"、"生成RFS模板"、"写一个一键部署方案"
- 部署类："华为云一键部署"、"Terraform模板"、"资源编排"
- 评估类："技术评估"、"方案评审"、"可行性评估"、"架构评审"、"多维度评估"
- 分析类："评估这个方案"、"能不能部署"、"分析可行性"、"技术选型对比"
- 场景类：涉及华为云资源创建 + 应用部署的场景
- 方案类：用户提供解决方案描述、架构需求、或部署需求，要求输出评审报告

**不触发**：
- 仅查询华为云产品信息、价格、文档 — 用 WebSearch 直接回答
- 仅生成不含华为云资源的 Terraform 模板
- 简单 yes/no 问答（如"这个能用吗"），用直接回答而非完整评估流程

## 执行流程

### Phase 1: 需求理解与架构设计

1. **解析用户输入**：提取关键信息
   - 解决方案名称与用途（如"快速部署Dify智能问答系统"）
   - 所需云资源列表（ECS / RDS / ELB / VPC / OBS / CCE / DCS 等）
   - 需要部署的应用软件（Dify / Jenkins / DeepSeek / 自有应用等）
   - 部署约束条件（区域、可用区、网络拓扑、计费模式）
   - 目标用户画像（中小企业 / 企业 / 开发者）

2. **设计云架构**
   - 确定资源依赖关系图（VPC → 子网 → 安全组 → ECS → 应用）
   - 选择合理的资源规格（根据场景推荐低配以保证性价比）
   - 绘制逻辑组网关系（明确各资源的网络连通关系）

3. **选定模板模式**：按场景匹配预设模板骨架

### Phase 2: 生成 Terraform 模板

依据选定的模式，生成以下标准文件集：

#### 2.1 `versions.tf` — Provider 版本声明

```hcl
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.56.0"
    }
  }
}
```

**规则**：
- source 统一用 `"huawei.com/provider/huaweicloud"`（RFS 要求）
- version 采用 `>=` 宽松约束
- 兼容 Terraform 1.5.2（RFS 当前版本）

#### 2.2 `providers.tf` — Provider 配置

```hcl
provider "huaweicloud" {
  region = var.region
}
```

**规则**：
- 推荐使用环境变量 `HW_REGION_NAME` / `HW_ACCESS_KEY` / `HW_SECRET_KEY` 配置凭证
- 不在 providers.tf 中硬编码 AK/SK
- 用 variable 传递 region，支持多 region 场景用 `alias`

#### 2.3 `variables.tf` — 输入变量定义

- 所有需要用户在部署时填写的参数定义为 variable
- 敏感信息（密码/密钥）设置 `sensitive = true`
- 提供合理的 `default` 值（非必填参数）
- 通过 `metadata.group` 关联 .extension 分组

```hcl
variable "ecs_password" {
  description = "ECS 实例管理员密码"
  type        = string
  sensitive   = true
  metadata {
    group = "ecs_config"
  }
}
```

**变量分类规则**：
| 分组 | 包含变量 |
|------|---------|
| 基础配置 | 资源名称前缀、区域、计费模式 |
| 网络配置 | VPC CIDR、子网 CIDR、可用区 |
| 计算配置 | ECS 规格、镜像、密码、登录方式 |
| 存储配置 | 磁盘类型、大小 |
| 数据库配置 | RDS 规格、密码、数据库版本 |
| 应用配置 | 应用参数、初始化脚本 URL |

#### 2.4 `main.tf` — 核心资源编排

按依赖顺序组织资源块，常见模式：

```hcl
# 1. 网络资源
resource "huaweicloud_vpc" "main" { ... }
resource "huaweicloud_vpc_subnet" "main" { ... }
resource "huaweicloud_networking_secgroup" "main" { ... }

# 2. 弹性 IP
resource "huaweicloud_vpc_eip" "main" { ... }

# 3. 计算资源 + userdata
resource "huaweicloud_compute_instance" "main" {
  ...
  user_data = filebase64("${path.module}/userdata/init.sh")
}

# 4. 数据库 / 中间件
resource "huaweicloud_rds_instance" "main" { ... }
resource "huaweicloud_dcs_instance" "redis" { ... }

# 5. 存储
resource "huaweicloud_obs_bucket" "main" { ... }

# 6. 负载均衡
resource "huaweicloud_elb_loadbalancer" "main" { ... }
resource "huaweicloud_lb_listener" "main" { ... }
resource "huaweicloud_lb_pool" "main" { ... }
resource "huaweicloud_lb_member" "main" { ... }
```

**资源编排规则**：
- 使用隐式依赖（`huaweicloud_vpc.main.id`）而非 `depends_on`
- 相同类型的多实例用 `count` 或 `for_each`
- 敏感 tag 标记：`"owner" = "solution"`, `"managed_by" = "rfs"`
- 输出资源访问地址、ID 等信息供用户后续使用

#### 2.5 `outputs.tf` — 输出定义

输出用户需要的信息，如：
```hcl
output "web_url" {
  description = "应用访问地址"
  value       = "http://${huaweicloud_vpc_eip.main.address}:8080"
}

output "ecs_id" {
  description = "ECS 实例 ID"
  value       = huaweicloud_compute_instance.main.id
}
```

### Phase 3: 生成 .extension 增强配置

为 RFS 控制台部署提供参数分组和 UI 增强：

```json
{
  "variables": {
    "grouping": {
      "network_config": {
        "label": "网络配置",
        "description": "配置 VPC 网络参数"
      },
      "ecs_config": {
        "label": "ECS 配置",
        "description": "配置云服务器规格"
      },
      "app_config": {
        "label": "应用配置",
        "description": "配置应用部署参数"
      }
    }
  }
}
```

**规则**：
- 分组 label 简洁清晰（2-5 个中文字）
- grouping 的 key 与 variables.tf 中 `metadata.group` 值对应
- 敏感参数（密码）应标注 `encryption` 字段

### Phase 4: 生成应用部署脚本

如果解决方案需要在 ECS 上部署应用，生成 `userdata/` 下的初始化脚本。

**脚本规范**：
- shell 脚本 (.sh)，以 `#!/bin/bash` 开头
- 支持幂等执行（多次运行不破坏已有状态）
- 从可靠源下载应用包（OBS / 官方仓库）
- 配置 systemd 服务实现自启动
- 输出安装日志到 `/var/log/install.log`

```
userdata/
├── install_app.sh          # 主安装脚本
└── configure_app.sh        # 应用配置脚本（可选）
```

### Phase 5: 生成文档

生成标准的解决方案文档：

```
README.md                  # 方案概述 + 架构图 + 部署步骤 + 使用指南
```

**文档章节**：
1. **方案概述** — 一句话描述 + 适用场景
2. **方案架构** — 架构图 + 资源清单表
3. **部署指南** — 部署前置条件 + RFS 一键部署步骤 + 参数说明表
4. **开始使用** — 部署后如何访问和使用
5. **预估费用** — 各资源规格及预估价格
6. **快速卸载** — 资源栈删除步骤

### Phase 6: 验证与打包

1. **结构检查**：确认以下文件齐全
   ```
   {solution-name}/
   ├── .extension
   ├── versions.tf
   ├── providers.tf
   ├── variables.tf
   ├── main.tf
   ├── outputs.tf
   ├── userdata/              # （可选）
   │   ├── install_*.sh
   │   └── configure_*.sh
   ├── README.md
   └── document/
       └── architecture.png   #（可选）
   ```

2. **内容检查**：
   - variables.tf 中的每个 variable 有合理的 `description` 和 `type`
   - 密码等敏感字段设置了 `sensitive = true`
   - outputs.tf 覆盖了所有用户需要的信息
   - main.tf 中资源引用正确（无悬空引用）
   - .extension 的 grouping key 与 metadata.group 一致
   - providers.tf 中无硬编码 AK/SK
   - 所有文件 UTF-8 编码

3. **打包输出**（可选）：提供 zip 包用于 RFS 上传

### Phase 7: 技术评估与多维度评审

当用户要求对方案进行技术评审、可行性评估、选型对比时，执行此阶段。

#### 7.1 评审维度框架

从 8 个核心维度做结构化评审，每个维度输出评分（★1-5）和关键发现：

| 维度 | 权重 | 评估要点 |
|------|------|---------|
| **技术可行性** | ★★★★★ | 云服务成熟度、技术风险、依赖约束 |
| **部署效率** | ★★★★★ | 一键部署耗时、自动化程度、瓶颈分析 |
| **运维便捷性** | ★★★★☆ | 自愈能力、监控告警、日志、备份、扩缩容 |
| **脚本兼容性** | ★★★★☆ | OS 兼容矩阵、包管理器差异、shell 可移植性 |
| **TF 模板通用性** | ★★★★★ | 模板解耦度、参数化程度、可复用为其他方案骨架 |
| **RFS 编排稳定性** | ★★★★★ | 资源依赖复杂度、库存风险、API 限流、超时处理 |
| **批量集群能力** | ★★★☆☆ | 水平扩展方式（count/for_each/AS）、线性 vs 并行 |
| **故障回滚机制** | ★★★★☆ | RFS 自动回滚覆盖范围、user_data 失败感知、数据保护 |

#### 7.2 评估执行流程

```
Step 1: 解析方案需求与架构
  → 提取云资源清单、部署模式、应用类型
  → 参考 reference/common-patterns.md 匹配标准模式

Step 2: 逐维度评审
  → 技术可行性：确认所有云服务已商用、无依赖黑洞
  → 部署效率：模拟部署流程，识别瓶颈节点（网络/下载/构建）
  → 运维便捷性：检查 systemd 托管、日志输出、监控对接
  → 脚本兼容性：对照 OS 兼容矩阵验证
  → TF 模板通用性：评估参数化程度和模块化水平
  → RFS 编排稳定性：分析资源依赖链，识别单点故障
  → 批量集群能力：评估扩展策略是否匹配需求规模
  → 故障回滚机制：区分资源层回滚和应用层回滚

Step 3: 输出评审报告
  → 按 assets/samples/solution-evaluation-report.md 模板生成
  → 包含架构图、时序图、评审总表、优化建议
```

#### 7.3 评分标准

| 分数 | 含义 | 行动建议 |
|------|------|---------|
| ★★★★★ | 无风险，生产就绪 | 可直接发布 |
| ★★★★☆ | 低风险，有优化空间 | 修复建议项后发布 |
| ★★★☆☆ | 中等风险，需改造 | 必须解决风险项 |
| ★★☆☆☆ | 高风险，架构需重新设计 | 重新设计后再评估 |
| ★☆☆☆☆ | 不可行 | 建议替代方案 |

#### 7.4 产出物

评审结果按照 `assets/samples/solution-evaluation-report.md` 的模板结构输出，包含：

```
{solution-name}/
└── evaluation/
    ├── report.md              # 完整评审报告（9 章节）
    ├── architecture.md        # 架构图与时序图
    ├── checklist.md           # 逐项检查清单
    └── recommendations.md     # 优化改造方案（P0-P3）
```

**报告标准章节**：
1. 核心架构总览 — 架构图 + 分层职责 + 数据流
2. 流程架构梳理 — 部署流程 + RFS 时序 + 耗时分布
3. TF 模板编写要点 — 格式选型 + 文件组织 + resource 规范
4. RFS 调用配置参数 — 参数表 + .extension 分组 + 委托 + 回滚
5. user_data 脚本注入规范 — 幂等 + checkpoint + 错误处理 + 兼容矩阵
6. 一键部署执行逻辑 — 状态机 + 事件序列 + 超时重试
7. 多维度技术评审 — 8 维度评分 + 详细分析 + 瓶颈识别
8. 落地注意事项 — 网络安全 + 费用 + 区域 + 镜像
9. 优化改造方案 — P0-P3 优先级 + 目标架构 + CI/CD 集成

## 标准模板模式

### 模式 A: 单节点基础部署 (single-node-ecs)
```
适用: 简单应用（单机部署），新建 VPC
资源: 1×ECS + 1×EIP + 1×VPC/子网/安全组
```

### 模式 B: 单节点已有 VPC (single-node-ecs-existing-vpc)
```
适用: 在已有网络中部署单机应用
资源: 1×ECS + 1×EIP（复用现有 VPC/子网/安全组）
```

### 模式 C: Web 应用集群 (ecs-cluster)
```
适用: 高可用 Web 应用
资源: 2×ECS + 1×ELB + 1×RDS + 1×EIP + VPC
```

### 模式 D: 高可用部署 (ecs-ha)
```
适用: 关键业务高可用
资源: 2×ECS（多网卡+不同安全组）+ RDS + ELB + EIP + VPC
```

### 模式 E: 容器化部署 (cce-cluster)
```
适用: 容器化应用
资源: 1×CCE 集群 + 节点池 + EIP + OBS + SWR
```

### 模式 F: 函数计算部署 (ecs-fg)
```
适用: ECS 创建后需执行自定义脚本
资源: 1×ECS + 1×FunctionGraph + EIP + VPC
```

## 常用华为云 TF 资源速查

| 分类 | 资源 | 用途 |
|------|------|------|
| 网络 | `huaweicloud_vpc` | 虚拟私有云 |
| 网络 | `huaweicloud_vpc_subnet` | 子网 |
| 网络 | `huaweicloud_networking_secgroup` | 安全组 |
| 网络 | `huaweicloud_vpc_eip` | 弹性公网 IP |
| 网络 | `huaweicloud_vpc_eip_associate` | EIP 绑定 |
| 计算 | `huaweicloud_compute_instance` | ECS 云服务器 |
| 计算 | `huaweicloud_compute_keypair` | SSH 密钥对 |
| 数据库 | `huaweicloud_rds_instance` | RDS 实例 |
| 数据库 | `huaweicloud_dcs_instance` | Redis / Memcached |
| 存储 | `huaweicloud_evs_volume` | 云硬盘 |
| 存储 | `huaweicloud_obs_bucket` | OBS 桶 |
| 存储 | `huaweicloud_sfs_turbo` | 弹性文件服务 |
| 容器 | `huaweicloud_cce_cluster` | CCE 集群 |
| 容器 | `huaweicloud_cce_node` | CCE 节点 |
| 容器 | `huaweicloud_swr_organization` | SWR 组织 |
| 容器 | `huaweicloud_swr_repository` | SWR 镜像仓库 |
| 负载均衡 | `huaweicloud_elb_loadbalancer` | ELB 实例 |
| 负载均衡 | `huaweicloud_lb_listener` | 监听器 |
| 负载均衡 | `huaweicloud_lb_pool` | 后端服务器组 |
| 计算 | `huaweicloud_fgs_function` | FunctionGraph 函数 |
| 消息 | `huaweicloud_dms_kafka_instance` | Kafka 实例 |
| 消息 | `huaweicloud_smn_topic` | SMN 主题 |
| DNS | `huaweicloud_dns_zone` | DNS 域名 |
| DNS | `huaweicloud_dns_recordset` | DNS 记录集 |
| 安全 | `huaweicloud_waf_dedicated_instance` | WAF 实例 |
| 日志 | `huaweicloud_lts_group` | LTS 日志组 |
| 数据库 | `huaweicloud_gaussdb_mysql_instance` | GaussDB MySQL |

## 输出结构

### 模板生成模式输出

所有生成的方案按以下目录结构输出到项目：

```
{solution-name}/
├── .extension                    # 参数 UI 增强配置
├── versions.tf                   # Provider 版本约束
├── providers.tf                  # Provider 配置
├── variables.tf                  # 输入参数
├── main.tf                       # 资源编排核心
├── outputs.tf                    # 输出定义
├── userdata/                     # （可选）应用部署脚本
│   └── install.sh
├── README.md                     # 方案文档
└── document/
    └── architecture.png          # （可选）架构图

### 技术评估模式输出

当执行技术评估（Phase 7）时，评审报告按以下结构输出：

```
{solution-name}/
└── evaluation/
    ├── report.md                 # 完整9章节评审报告
    ├── architecture-diagram.md   # 架构图与时序图（ASCII）
    ├── checklist.md              # 逐项检查清单
    └── recommendations.md        # 优化改造方案（P0-P3）
```
```

## 边界条件

1. **凭证安全**：绝不在模板中硬编码 AK/SK，必须通过环境变量传入
2. **最小权限**：资源规格推荐选择满足运行需求的最低配置
3. **幂等性**：模板需支持重复执行（`terraform apply` 多次结果一致）
4. **敏感信息**：密码/密钥变量必须设置 `sensitive = true`
5. **编码**：所有文件统一 UTF-8 编码，.tf.json 不含 BOM 头
6. **文件大小**：zip 包不超过 1MB，文件数不超过 100 个
7. **不支持变量文件**：包内不得包含 `.tfvars` 文件
8. **资源命名**：服务器命名体现用途（如"web-server"、"db-server"）
9. **版本兼容**：provider source 使用 `huawei.com/provider/huaweicloud`（RFS 平台要求）
10. **费用透明**：文档中必须提供各资源规格的预估费用参考

### 技术评估边界条件

1. **评审时效**：评估报告标注评审日期，云服务规格和价格以华为云官网为准
2. **客观中立**：评分基于技术事实，不因项目偏好调整评分
3. **风险明确**：每个"低分"维度必须附带具体原因和改进建议
4. **数据支撑**：评估结论引用具体文档、API 版本、测试数据
5. **兼容范围**：脚本兼容性仅验证声明支持的 OS 版本
6. **不替代测试**：评审报告不替代实际部署测试，标注"建议完成实际部署验证"
7. **度量标准**：部署效率耗时标记为"预估"，以实际网络环境和规格为准
8. **分层输出**：模板生成模式和技术评估模式互斥，一次对话只输出一种模式
