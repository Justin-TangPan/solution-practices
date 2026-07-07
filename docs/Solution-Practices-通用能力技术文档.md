# Solution Practices (SAC) — 通用能力技术文档

> **版本**: v2.0 · **日期**: 2026-06-15 · **文档性质**: 技术架构与通用能力说明

---

## 1. 项目定位

### 1.1 一句话定义

**Solution Practices (SAC)** 是一套基于 AI Agent 的华为云解决方案自动化交付框架——将方案评估、脚本生成、文档撰写、打包发布全流程编码为可复用的技能包（Skill），通过 A2A 多智能体协同架构，实现从"需求输入"到"一键部署"的端到端自动化。

### 1.2 核心价值主张

| 维度 | 传统模式 | SAC 模式 | 提升 |
|------|----------|----------|------|
| 交付周期 | 3-7 天 | 30 分钟 | **提速 100-300×** |
| 脚本质量 | 依赖个人经验 | 标准化 + 反模式库兜底 | **零踩坑交付** |
| 文档一致性 | 手动维护，易脱节 | 与脚本同步生成 | **100% 一致** |
| 跨区域复制 | 重新配置 | 参数化一键切换 | **零成本复制** |

### 1.3 适用场景

- 华为云 Marketplace 方案上架（solution.huaweicloud.com）
- 华为云 RFS 一键部署模板制作
- 内部方案标准化归档与知识沉淀
- AI 工具链在华为云上的快速落地

---

## 2. 技能包架构

### 2.1 分层模型

SAC 技能系统采用**三层架构**，每层职责清晰、可独立演进：

```
┌─────────────────────────────────────────────────────────────┐
│                    Layer 2 · 编排层 (Orchestration)            │
│                                                               │
│  ┌─────────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ sac-orchestrator │  │ sac-framework │  │solution-package- │  │
│  │                  │  │              │  │   builder         │  │
│  │ A2A 主控 Agent   │  │ 双文档输出规范 │  │ 目录标准 + OBS 发布│  │
│  └─────────────────┘  └──────────────┘  └──────────────────┘  │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                    Layer 1 · 能力层 (Capabilities)             │
│                                                               │
│  ┌───────────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │sac-technical-     │  │sac-script-    │  │sac-doc-writer │  │
│  │   evaluator       │  │   builder     │  │               │  │
│  │                   │  │               │  │               │  │
│  │ 架构分析           │  │ TF/Shell/Docker│  │ 9章部署指南    │  │
│  │ 资源规划           │  │ 代码生成       │  │ 6模块业务文档   │  │
│  │ 安全评估           │  │               │  │ SAC 报告       │  │
│  └───────────────────┘  └───────────────┘  └───────────────┘  │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                    Layer 0 · 基础层 (Foundation)               │
│                                                               │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐ │
│  │sac-rfs-practices│  │    sac-doc-framework        │ │
│  │                         │  │                             │ │
│  │ RFS 模板工程知识          │  │ 文档格式规范与模板           │ │
│  │ 11 条反模式库            │  │ Business: 6 模块            │ │
│  │ Terraform 最佳实践       │  │ Technical: 9 章             │ │
│  └─────────────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 八个 Skill 的职责边界

#### Layer 0 · 基础层 —— "知识沉淀"

| Skill | 核心职责 | 关键输出 |
|-------|----------|----------|
| **sac-rfs-practices** | RFS 模板工程的全部实战知识，包含 11 条踩坑反模式 | Terraform 模板规范、Shell 脚本 4 阶段模式、OBS 上传规范 |
| **sac-doc-framework** | 定义两种文档的标准格式——业务文档（6 模块）和部署指南（9 章） | 文档模板、术语规范、截图要求 |

#### Layer 1 · 能力层 —— "专业分工"

| Skill | 核心职责 | 输入 | 输出 |
|-------|----------|------|------|
| **sac-technical-evaluator** | 分析应用架构，规划云资源，评估安全风险 | 方案名、区域、应用类型、端口、依赖 | technical-evaluation.md + resource-plan.yaml |
| **sac-script-builder** | 生成 Terraform HCL、Shell 安装脚本、Docker Compose | resource-plan.yaml + 应用配置 | deploying-*.tf + install_*.sh + docker-compose.yaml |
| **sac-doc-writer** | 生成部署指南（9 章）+ 业务文档（6 模块）+ .extension + SAC 报告 | technical-evaluation.md + 脚本清单 | README.md + Solution-Details.md + .extension + SAC-*.md/.docx |

#### Layer 2 · 编排层 —— "流程控制"

| Skill | 核心职责 | 关键机制 |
|-------|----------|----------|
| **sac-orchestrator** | A2A 主控 Agent，协调三个子 Agent 的执行顺序与数据流转 | 5 阶段流水线、10 项质量门禁、并行调度 |
| **sac-framework** | 强制双文档输出规范（技术文档 + 业务文档必须同时产出） | 输出校验、语言规则（cn=中文, hk/sg=英文） |
| **solution-package-builder** | 定义标准目录结构，管理 OBS 发布流程 | 目录规范、OBS 路径映射、release 发布流程 |

### 2.3 Skill 间的数据流转

```
用户需求 (方案名 + 区域 + 应用类型)
    │
    ▼
┌──────────────────┐
│  sac-orchestrator │ ◄── Layer 2: 接收需求，拆解任务
│  Phase 1: 收集    │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────┐
│ sac-technical-evaluator  │ ◄── Layer 1: 架构分析 + 资源规划
│ Phase 2: 评估             │
│ 输出: evaluation.md      │
│         resource-plan.yaml│
└────────┬────────────────┘
         │
    ┌────┴────┐  (并行执行)
    ▼         ▼
┌────────┐ ┌────────────┐
│script- │ │ doc-writer  │ ◄── Layer 1: 脚本生成 + 文档撰写
│builder │ │ Phase 4     │
│Phase 3 │ │             │
└───┬────┘ └──────┬─────┘
    │              │
    ▼              ▼
 .tf  .sh      README.md
 docker-compose Solution-Details.md
                .extension
                SAC-报告
    │              │
    └──────┬───────┘
           ▼
┌──────────────────┐
│  sac-orchestrator │ ◄── Layer 2: 组装 + 校验 + 发布
│  Phase 5: 组装    │
└────────┬─────────┘
         ▼
    标准化方案包
    (practices/{name}/{region}/)
```

**设计原则**：

1. **单向数据流**：数据从 Layer 0 → Layer 1 → Layer 2 单向流动，不存在反向依赖
2. **并行最大化**：Phase 2 完成后，Phase 3（脚本）和 Phase 4（文档）并行执行
3. **知识与执行分离**：Layer 0 只提供"知识"，不参与执行；Layer 1 只执行，不决策流程

---

## 3. 给 AI 的"抓手" —— 如何指导 Agent 快速生成方案

### 3.1 结构化输入协议

SAC 为每个子 Agent 定义了**精确的输入协议**，避免 Agent "自由发挥"导致的产出偏差。

#### 技术评估 Agent 的输入协议

```yaml
required_inputs:
  - solution_name: "headroom-opencode"        # 方案英文名（小写连字符）
  - region: "hk"                               # cn | hk | sg
  - app_type: "Native"                         # Docker | Native | Hybrid
  - app_description: "上下文压缩代理"           # 一句话描述
  - ports: [8787]                              # 开放端口列表

optional_inputs:
  - dependencies: "MaaS API"                   # 外部依赖
  - ecs_recommend: "x1.2u.4g"                  # 推荐规格
```

#### 脚本生成 Agent 的输入协议

```yaml
required_inputs:
  - solution_name: "headroom-opencode"
  - region: "hk"
  - resource_plan: # 来自 technical-evaluator 的输出
      vpc_cidr: "172.16.0.0/16"
      ecs_flavor: "x1.2u.4g"
      ecs_os: "Ubuntu 24.04"
      system_disk: 40
      bandwidth: 100
      ports: [8787]
  - app_config:
      runtime: "Node.js 22 + Python 3.12"
      install_method: "npm + pip"
      docker_required: false
```

#### 文档撰写 Agent 的输入协议

```yaml
required_inputs:
  - solution_name: "headroom-opencode"
  - solution_name_cn: "Headroom + OpenCode · 上下文压缩 AI 编码助手"
  - region: "hk"
  - technical_evaluation: # 来自 technical-evaluator
  - script_list:          # 来自 script-builder
  - app_description: "上下文压缩代理 + 开源 AI 编码助手"
  - target_customer: "需要 AI 辅助编码的开发团队"
```

**关键设计**：每个 Agent 的输入都**明确标注来源**（用户直接提供 / 来自哪个上游 Agent），避免 Agent 自行猜测或编造数据。

### 3.2 模板驱动生成

SAC 不是从零生成，而是**基于模板填充**。每个 Skill 内置了经过验证的模板：

#### Terraform 模板骨架

```hcl
# 由 sac-script-builder 自动填充
terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.36.0"
    }
  }
}

provider "huaweicloud" {
  region = var.region  # ← 由 region 参数驱动
}

locals {
  name_suffix = substr(uuid(), 0, 8)  # ← 唯一命名，避免重部署冲突
}

# VPC → Subnet → SecurityGroup → EIP → ECS (user_data)
# 每个资源的名称都包含 ${local.name_suffix}
```

#### Shell 脚本 4 阶段模式

```bash
#!/bin/bash
set -e
LOG_FILE="/var/log/${SOLUTION_NAME}-bootstrap.log"

echo "===== Stage 1: System Prepare ====="
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
apt-get update -y
apt-get install -y --force-confdef --force-confold curl wget git

echo "===== Stage 2: Runtime Install ====="
# Docker / Node.js / Python ...

echo "===== Stage 3: Application Config ====="
# 创建目录、写入配置文件 ...

echo "===== Stage 4: Start Application ====="
# 启动服务、健康检查 ...
```

#### 文档 9 章模板（部署指南）

```
01 方案简介        → 场景、架构图、优势、约束
02 资源与成本规划  → 云资源表格、按需/包周期对比
03 实施步骤        → 索引页，链接 04-07
04 前提条件        → 账号、IAM 委托、MaaS 开通
05 快速部署        → 参数表、一键 RFS、验证
06 快速入门        → API 示例、配置指南、端到端验证
07 快速卸载        → RFS 资源栈删除 + 数据备份提醒
08 常见问题        → 5-8 个 FAQ（症状→原因→修复）
09 附录            → 术语表、参考链接、修订记录
```

#### 业务文档 6 模块模板

```
Module 1: Hero            → 标题 + 价值主张 + 客户标签 + CTA
Module 2: 方案优势         → 3 张优势卡片（价值优先，技术其次）
Module 3: 架构与部署       → 架构图 + 部署选项 + 成本 + 时长
Module 4: 应用场景         → 3 个场景卡片（客户痛点 → 解决方案 → 价值）
Module 5: 方案扩展         → 3 个关联方案
Module 6: 服务亮点栏       → 5 个服务链接
```

### 3.3 反模式库与约束注入

`sac-rfs-practices` Skill 维护了 **11 条经过实战验证的反模式**，Agent 在生成脚本时必须遵守：

| # | 反模式 | 根因 | 修复方案 |
|---|--------|------|----------|
| 1 | sshd_config TUI 阻塞部署 | dpkg 配置文件提示未被抑制 | 添加 `DEBCONF_NONINTERACTIVE_SEEN=true` + `--force-confdef --force-confold` |
| 2 | Docker CE GPG 密钥下载失败 | docker.com 在国内 ECS 不可达 | 使用 `mirrors.huaweicloud.com/docker-ce` |
| 3 | `docker compose` 命令不存在 | 华为云 Docker CE 只提供 v1 独立二进制 | 统一使用 `docker-compose`（带连字符） |
| 4 | Docker 镜像拉取失败 | Docker Hub 在国内不可达 | 配置 `registry-mirrors`（docker.1ms.run + SWR） |
| 5 | 容器 EACCES 权限拒绝 | Volume 属主为 root，容器以非 root UID 运行 | `chown -R UID:GID` 挂载目录 |
| 6 | Secure Cookie 阻止 HTTP 登录 | 应用默认要求 HTTPS | 设置 `N8N_SECURE_COOKIE=false` 等环境变量 |
| 7 | required_providers 格式错误 | 写成数组而非对象 | 始终使用 `{ "huaweicloud": {...} }` 对象格式 |
| 8 | Random provider 不可用 | RFS 仅支持 huaweicloud provider | 使用 `substr(uuid(), 0, 8)` 生成唯一后缀 |
| 9 | VPC/ECS 名称冲突 | 静态资源名导致重部署失败 | 所有资源名追加 `-${local.name_suffix}` |
| 10 | OBS 脚本静态化阻碍迭代 | 每次改脚本需重建 RFS 模板包 | user_data 只做下载+执行，逻辑在 OBS 上的 .sh |
| 11 | pip/PyPI 超时 | pypi.org 在国内 ECS 不可达 | 使用清华镜像 `pypi.tuna.tsinghua.edu.cn` |

**约束注入机制**：这些反模式不是"建议"，而是**硬约束**——Agent 在生成脚本时，这些规则会作为上下文注入，确保产出物天然避开已知陷阱。

### 3.4 从"会写代码"到"会写方案"的跃迁

传统 AI 编码工具（如 Copilot）擅长写代码片段，但 SAC 要求 Agent 做的是**写方案**——这是一个质的跃迁：

```
传统 AI 编码:                    SAC 方案生成:
┌──────────────┐                ┌──────────────────┐
│ 输入: 函数签名 │                │ 输入: 业务需求     │
│ 输出: 代码片段 │                │ 输出: 完整方案包   │
│              │                │                  │
│ · 关注语法正确 │                │ · 关注架构合理性   │
│ · 单文件产出  │                │ · 多文件协同产出   │
│ · 无部署知识  │                │ · 内置云平台知识   │
│ · 无文档能力  │                │ · 自动撰写文档     │
└──────────────┘                └──────────────────┘
```

SAC 实现这一跃迁的关键：

1. **Skill 封装专家知识**：每个 Skill 文件就是一个"专家经验包"，Agent 读取 Skill 后即获得该领域的专家能力
2. **模板约束输出格式**：不是让 Agent 自由发挥，而是在严格模板内填充内容
3. **反模式库兜底质量**：11 条踩坑记录确保 Agent 不会重复人类犯过的错误
4. **A2A 协同分解复杂度**：一个 Agent 做不好的事，拆给三个专业 Agent 并行做

---

## 4. 交付流水线——端到端逻辑

### 4.1 五阶段流程

```
用户输入需求
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  Phase 1: 需求收集 (sac-orchestrator)                  │
│  · 收集 9 项结构化输入                                  │
│  · 确认方案名、区域、应用类型、端口、依赖                 │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  Phase 2: 技术评估 (sac-technical-evaluator)            │
│  · 应用架构分析（技术栈、运行时、存储、网络）              │
│  · 部署架构设计（单机/主从/集群、高可用策略）              │
│  · 云资源规划（VPC/子网/安全组/ECS/EIP/成本）             │
│  · 安全风险评估（端口暴露、访问控制、合规）                │
│  · 输出: technical-evaluation.md + resource-plan.yaml  │
└─────────────────────────────────────────────────────┘
    │
    ├──────────────────────┬──────────────────────┐
    ▼ (并行)               ▼ (并行)               │
┌──────────────────┐  ┌──────────────────┐      │
│ Phase 3: 脚本生成  │  │ Phase 4: 文档撰写 │      │
│ (sac-script-builder)│  │ (sac-doc-writer)  │      │
│                    │  │                    │      │
│ · Terraform HCL   │  │ · 9 章部署指南     │      │
│ · Shell 安装脚本   │  │ · 6 模块业务文档   │      │
│ · Docker Compose  │  │ · .extension 配置  │      │
│ · 应用配置文件     │  │ · SAC 报告(MD+DOCX)│      │
└──────────────────┘  └──────────────────┘      │
    │                       │                     │
    └───────────┬───────────┘                     │
                ▼                                  │
┌─────────────────────────────────────────────────────┐
│  Phase 5: 组装发布 (sac-orchestrator)                  │
│  · 按标准目录结构组装                                   │
│  · 10 项质量门禁校验                                   │
│  · OBS 上传                                           │
│  · 生成 url.txt（TF/Shell/RFS 控制台直连）              │
└─────────────────────────────────────────────────────┘
```

### 4.2 并行调度机制

Phase 3 和 Phase 4 的并行执行是 SAC 的核心效率优势：

```
Phase 2 输出 (resource-plan.yaml)
        │
        ├─────────────────────┐
        ▼                     ▼
   ┌─────────┐          ┌─────────┐
   │ Script   │          │  Doc    │
   │ Builder  │          │ Writer  │
   │          │          │         │
   │ 耗时: ~8min│         │ 耗时: ~10min│
   └────┬────┘          └────┬────┘
        │                     │
        └─────────┬───────────┘
                  ▼
            Phase 5 组装
            (耗时: ~2min)
            
总耗时: max(8, 10) + 2 = 12min
(而非串行的 8 + 10 + 2 = 20min)
```

### 4.3 质量门禁

Phase 5 执行 10 项质量校验，分为**阻断级**（不通过不发布）和**建议级**（警告但不阻断）：

| # | 校验项 | 级别 | 校验方式 |
|---|--------|------|----------|
| 1 | TF 语法正确 | 阻断 | `terraform validate` |
| 2 | Shell 可执行 | 阻断 | `bash -n` 语法检查 |
| 3 | .extension JSON 格式 | 阻断 | JSON 解析 + 必填字段校验 |
| 4 | 01-09 章节覆盖 | 阻断 | 章节标题匹配 |
| 5 | OBS 路径一致性 | 阻断 | TF 中 wget 路径 = 实际上传路径 |
| 6 | 安全组规则完整性 | 建议 | ICMP + SSH 必须存在 |
| 7 | 成本表格存在 | 建议 | 必须包含按需/包周期对比 |
| 8 | 术语规范 | 建议 | "云服务器" ≠ "虚拟机" |
| 9 | 中英文对应 | 建议 | .extension 双语描述完整性 |
| 10 | 版本号一致 | 阻断 | 所有文档版本号相同 |

---

## 5. 标准化产物规范

### 5.1 目录结构标准

```
practices/{solution-name}/{region}/
├── .extension                          # RFS 参数配置 (JSON)
├── terraform/
│   └── deploying-{solution-name}.tf    # 基础架构即代码
├── scripts/
│   ├── install_{solution-name}.sh      # 安装脚本（4 阶段）
│   ├── docker-compose.yaml             # [可选] 容器编排
│   └── config.yaml                     # [可选] 应用配置
└── docs/
    ├── README.md                       # 9 章部署指南
    ├── Solution-Details.md             # 6 模块方案详情
    ├── {SolutionName}-部署指南.docx    # [可选] Word 版
    └── {SolutionName}-业务价值报告.docx # [可选] Word 版
```

### 5.2 OBS 发布路径规范

| 用途 | OBS 桶 | 路径格式 |
|------|--------|----------|
| 内部开发（practices） | `tp-00940108` | `obs://tp-00940108/{solution-name}-{region}/` |
| 公开发布（release） | `documentation-samples-5` | `obs://documentation-samples-5/solution-as-code-publicbucket/solution-as-code-module/{solution-name}-{region}/` |

### 5.3 .extension 配置规范

```json
{
  "template_url": "https://tp-00940108.obs.ap-southeast-1.myhuaweicloud.com/.../deploying-*.tf",
  "group_order": ["network_config", "ecs_config", "charging_config"],
  "parameters": {
    "ecs_flavor": {
      "group": "ecs_config",
      "order": 1,
      "description": {
        "zh_cn": "云服务器规格",
        "en": "ECS Flavor"
      }
    }
  },
  "group_labels": {
    "network_config": { "zh_cn": "网络配置", "en": "Network Config" },
    "ecs_config":     { "zh_cn": "服务器配置", "en": "ECS Config" },
    "charging_config": { "zh_cn": "计费配置", "en": "Charging Config" }
  },
  "solution_info": {
    "name": { "zh_cn": "...", "en": "..." },
    "description": { "zh_cn": "...", "en": "..." },
    "version": "v1.0",
    "category": "AI Development"
  }
}
```

---

## 6. 已验证的成功案例

### 6.1 方案全景

| 方案 | 描述 | 区域 | 状态 | 核心技术 |
|------|------|------|------|----------|
| **headroom-claude-code** | Headroom 上下文压缩 + Claude Code | CN + HK | ✅ 完整交付 | Node.js, Python, MaaS API |
| **headroom-opencode** | Headroom 上下文压缩 + OpenCode | HK | ✅ 完整交付 | Node.js, Python, MIT 开源栈 |
| **litellm** | 多模型统一 API 网关 | CN + HK | ✅ 完整交付 | Docker Compose, PostgreSQL, Prometheus |
| **supabase** | 开源 Firebase 替代 | CN | ✅ 完整交付 | Docker Compose (10 容器), PostgreSQL + pgvector |
| **openhands** | AI 开发助手平台 | CN | 🔧 开发中 | Docker, Dockerfile |
| **codewhale** | 智能代码分析平台 | CN | 🔧 开发中 | Docker |
| **aitoearn** | AI 收益系统 | CN + HK | 🔧 开发中 | Native |

### 6.2 案例详解：Headroom + OpenCode

**方案定位**：为开发团队提供带上下文压缩的 AI 编码助手，Token 成本降低 60-95%。

**技术架构**：

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   开发者终端   │────▶│  Headroom    │────▶│  LLM API     │
│  (OpenCode)   │     │  Proxy :8787  │     │  (MaaS)      │
│              │     │              │     │              │
│  opencode.json│     │ 压缩上下文    │     │ DeepSeek     │
│  → localhost  │     │ 60-95% 节省  │     │ Claude       │
└──────────────┘     └──────────────┘     └──────────────┘
```

**云资源清单**：

| 资源 | 规格 | 月费（按需） |
|------|------|-------------|
| Flexus X ECS | x1.2u.4g (2vCPU 4GB) | ~$24 |
| EIP | 100Mbps 按流量 | ~$12.50 |
| VPC + Subnet + SG | 免费 | $0 |
| **合计** | | **~$36.50/月** |

**交付物清单**：

```
practices/headroom-opencode/hk/
├── .extension                    ← RFS 参数配置
├── terraform/
│   └── deploying-headroom.tf     ← VPC + ECS + EIP + SG
├── scripts/
│   └── install_headroom.sh       ← 4 阶段：系统→Node.js→Headroom→配置
└── docs/
    ├── README.md                 ← 9 章完整部署指南
    └── Solution-Details.md       ← 6 模块业务价值文档
```

**SAC 报告**（reports/headroom-opencode/）：
- SAC-业务价值报告-Headroom-OpenCode.md / .docx
- SAC-技术交付报告-Headroom-OpenCode.md / .docx

### 6.3 案例详解：LiteLLM 多模型网关

**方案定位**：为团队提供统一的 LLM API 入口，支持 100+ 模型提供商，内置虚拟密钥管理、花费追踪、负载均衡。

**技术架构**：

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   应用/客户端  │────▶│  LiteLLM     │────▶│  100+ LLM    │
│              │     │  Proxy :4000  │     │  Providers   │
│  OpenAI 兼容  │     │              │     │              │
│  API 格式    │     │ 虚拟密钥管理  │     │ OpenAI       │
│              │     │ 花费追踪      │     │ Anthropic    │
│              │     │ 负载均衡      │     │ DeepSeek ... │
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │
                     ┌──────┴───────┐
                     │  PostgreSQL   │
                     │  + Prometheus │
                     │  :9090        │
                     └──────────────┘
```

**Docker Compose 架构**（3 容器）：

| 容器 | 镜像 | 端口 | 用途 |
|------|------|------|------|
| litellm | ghcr.io/berriai/litellm:main | 4000 | API 代理 |
| db | postgres:16 | 5432 | 数据存储 |
| prometheus | prom/prometheus:latest | 9090 | 监控 |

**交付物清单**：

```
practices/litellm/hk/
├── .extension                      ← RFS 参数配置
├── terraform/
│   ├── deploying-litellm.tf        ← HCL 格式
│   └── deploying-litellm.tf.json   ← JSON 格式（兼容旧版）
├── scripts/
│   ├── install_litellm.sh          ← 4 阶段安装
│   ├── docker-compose.yaml         ← 3 容器编排
│   ├── config.yaml                 ← LiteLLM 模型配置
│   └── prometheus.yml              ← 监控配置
└── docs/
    ├── README.md                   ← 9 章部署指南
    └── Solution-Details.md         ← 6 模块业务文档
```

### 6.4 案例详解：Supabase 后端即服务

**方案定位**：为开发者提供开箱即用的后端服务——数据库、认证、实时订阅、存储、API 一站搞定。

**技术架构**：

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│   前端应用    │────▶│  Kong GW     │────▶│  Supabase 微服务  │
│              │     │  :8000        │     │                  │
│  REST API    │     │              │     │  GoTrue (认证)    │
│  GraphQL     │     │  路由 + 限流   │     │  PostgREST (API)  │
│  Realtime WS │     │              │     │  Realtime (WS)    │
│              │     │              │     │  Storage (文件)    │
│              │     │              │     │  Studio (管理面板)  │
└──────────────┘     └──────────────┘     └────────┬─────────┘
                                                    │
                                           ┌────────┴─────────┐
                                           │  PostgreSQL 15    │
                                           │  + pgvector       │
                                           │  + pgjwt          │
                                           │  + PostGIS        │
                                           └──────────────────┘
```

**Docker Compose 架构**（~10 容器）：

| 容器 | 用途 | 端口 |
|------|------|------|
| kong | API 网关 | 8000 |
| auth (GoTrue) | 用户认证 | 9999 |
| rest (PostgREST) | REST API | 3000 |
| realtime | WebSocket 订阅 | 4000 |
| storage | 文件存储 | 5000 |
| studio | Web 管理面板 | 3000 |
| meta | 元数据管理 | 8080 |
| db | PostgreSQL 15 | 5432 |
| supavisor | 连接池 | 5432 |
| imgproxy | 图片处理 | 5001 |

**资源规格**：x1.8u.16g (8vCPU 16GB) —— 比其他方案更大，因为需要运行 ~10 个容器 + PostgreSQL。

---

## 7. 技术亮点总结

### 7.1 Skill 即"数字员工手册"

每个 SKILL.md 文件约 200-500 行，包含：
- **输入协议**：精确到每个字段的类型、格式、来源
- **输出规范**：精确到每个文件的目录位置、命名规则、内容结构
- **反模式库**：踩坑记录 + 修复方案
- **模板骨架**：可直接复用的代码/文档模板

Agent 读取一个 Skill 文件，就相当于"阅读了一本专家手册"，立即获得该领域的完整工作能力。

### 7.2 A2A 协同的"流水线工厂"

```
传统模式: 1 个工程师 × 3 天 = 1 个方案
SAC 模式: 3 个 Agent × 30 分钟 = 1 个方案

效率提升: (3 × 8h) / 30min = 48×
```

### 7.3 可扩展的方案矩阵

SAC 的技能包架构天然支持横向扩展——新增一个方案只需：

1. 在 `practices/` 下创建目录
2. 调用 `sac-orchestrator` 输入 9 项需求
3. 等待 30 分钟，完整方案包自动生成

无需修改任何 Skill 文件，无需编写新代码。

### 7.4 跨区域零成本复制

同一方案从 CN 复制到 HK，只需：
- 将 `region` 参数从 `cn` 改为 `hk`
- 重新运行 SAC 流水线
- 自动适配 OBS 路径、镜像源、区域代码

---

## 附录 A：术语表

| 术语 | 全称 | 说明 |
|------|------|------|
| SAC | Solution Practices | 解决方案实践，本框架的核心理念 |
| A2A | Agent-to-Agent | 多智能体协同架构 |
| RFS | Resource Formation Service | 华为云资源编排服务 |
| OBS | Object Storage Service | 华为云对象存储服务 |
| ECS | Elastic Cloud Server | 华为云弹性云服务器 |
| EIP | Elastic IP | 弹性公网 IP |
| SWR | Software Repository | 华为云容器镜像服务 |
| MaaS | Model as a Service | 华为云模型即服务 |
| TF | Terraform | 基础设施工具 |
| SG | Security Group | 安全组 |

## 附录 B：Skill 文件索引

| Skill | 路径 | 行数 |
|-------|------|------|
| sac-orchestrator | `~/.claude/skills/sac-orchestrator/SKILL.md` | ~300 |
| sac-framework | `~/.claude/skills/sac-framework/SKILL.md` | ~200 |
| sac-technical-evaluator | `~/.claude/skills/sac-technical-evaluator/SKILL.md` | ~250 |
| sac-script-builder | `~/.claude/skills/sac-script-builder/SKILL.md` | ~350 |
| sac-doc-writer | `~/.claude/skills/sac-doc-writer/SKILL.md` | ~400 |
| sac-doc-framework | `~/.claude/skills/sac-doc-framework/SKILL.md` | ~200 |
| solution-package-builder | `~/.claude/skills/solution-package-builder/SKILL.md` | ~250 |
| sac-rfs-practices | `~/.claude/skills/sac-rfs-practices/SKILL.md` | ~500 |

## 附录 C：已知约束与边界

| 约束 | 说明 | 规避方案 |
|------|------|----------|
| RFS 仅支持 huaweicloud provider | 不能使用 random、tls 等 HashiCorp provider | 使用 `substr(uuid(), 0, 8)` |
| 国内 ECS 无法访问 docker.com | GPG 密钥下载失败 | 使用华为云镜像 |
| `docker compose` v2 不可用 | 华为云 Docker CE 只提供 v1 | 使用 `docker-compose` |
| pip 国内超时 | pypi.org 不可达 | 使用清华镜像 |
| release 目录只读 | 未经授权不得修改 | practices 先开发，确认后复制到 release |

---

> **文档维护**: SAC Framework Team  
> **最后更新**: 2026-06-15  
> **版本**: v2.0
