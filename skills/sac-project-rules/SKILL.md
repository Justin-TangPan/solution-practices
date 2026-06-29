---
name: sac-project-rules
description: |
  SAC（Solution as Code — 解决方案实践）交付包项目的完整规则定义。

  本 skill 定义了项目的命名规范、目录结构、文件组织、多 Agent 协同架构、交付流程和操作守则。

  触发场景（四类）：
  【直接询问】"项目规则是什么"、"交付规范是什么"、"SAC 规则"、"目录结构怎么组织"、
  "文件命名规则"、"怎么创建新方案"、"release 怎么打包"、"OBS 规则"、"命名规范"
  【多 Agent 协同】当在工作流（sac-full-pipeline）中被架构师/开发/测试/安全/文档/
  交付 Agent 作为共性基础加载时，提供全局规则上下文
  【方案开发】本项目中工作但未明确引用其他 skill 时
  【疑问类】任何涉及项目整体组织方式的疑问
---

# SAC 交付包项目规则

> **SAC = Solution as Code**（解决方案即代码）
>
> 中文名：**解决方案实践**
> 英文名：**Solution Practice**
> 简称：**SAC**

本文档定义了本项目（Solution Practice）的完整组织规则、命名规范、文件结构和交付流程。

---

## 1. 项目概述

本项目是一个基于华为云的解决方案实践集合仓库，提供多种 AI 工具和平台的一键部署方案。

### 1.1 项目使命

将每个解决方案打包为标准交付包，包含：
- **Terraform 模板**（`deploying-{project}.tf`）— 基础设施即代码
- **Shell 安装脚本**（`install_{project}.sh`）— 应用部署逻辑
- **业务文档**（方案详情）— 面向客户的价值描述
- **技术文档**（部署指南）— 面向运维的操作手册
- **RFS 一键部署 URL** — 用户点击即可部署

### 1.2 技能与 Agent 架构

```
solution-practice/
├── skills/                          ← AI 技能包（专业知识范式）
│   ├── sac-project-rules/           ← 项目规则总纲（共性基础）
│   ├── sac-rfs-practices/          ← RFS 模板 + 部署脚本开发
│   ├── sac-solution-extractor/     ← 华为云方案页内容提取
│   ├── sac-page-enhance/           ← 方案页面文案增强
│   └── sac-deep-search/            ← 深度搜索与洞察
│
├── .claude/agents/                 ← Agent 角色定义（JSON 配置）
│   ├── sac-architect.json          🧠 架构师
│   ├── sac-developer.json          💻 开发
│   ├── sac-tester.json             🧪 测试
│   ├── sac-security.json           🔒 安全审查
│   ├── sac-documenter.json         📝 文档
│   └── sac-delivery.json           📦 交付
│
└── .claude/workflows/              ← 多 Agent 协同工作流（JS 编排）
    ├── sac-full-pipeline.js        🔄 全流程：6 Agent 串行+并行
    ├── sac-architect-develop.js    ⚡ 快速原型：架构→开发
    ├── sac-audit.js                🔍 审计：测试+安全并行
    └── sac-delivery-only.js        📦 仅交付：打包→上线
```

**核心关系：** Skills 是"知识库"，Agents 是"角色"，Workflows 是"剧本"。

---

## 2. 根目录结构

```
solution-practice/
├── practices/          # 实践方案源码（开发目录）
│   ├── litellm/        # 完整参考：cn+intl双站点，standard+ha双变体
│   │   ├── cn/         # 中国站（含cn-north-4北京 + ap-southeast-1香港）
│   │   │   ├── cn-north-4/standard/...
│   │   │   ├── cn-north-4/ha/...
│   │   │   ├── ap-southeast-1/standard/...
│   │   │   ├── ap-southeast-1/ha/...
│   │   │   └── docs/         ← 中国站中文文档（站点级）
│   │   └── intl/       # 国际站（多个区域 + docs/{zh-cn,en-us}）
│   ├── headroom-claude-code/
│   ├── headroom-opencode/
│   ├── openhands/
│   ├── supabase/
│   ├── codewhale/
│   └── aitoearn/
├── release/            # 发布包目录（交付产物）
│   ├── litellm/
│   └── headroom-claude-code/
├── skills/             # AI 技能定义
├── assets/             # 模板与示例
│   ├── demo/
│   ├── templates/
│   └── extension-samples/
├── reference/          # 参考文档（只读）
├── scripts/            # 自动化工具脚本
├── docs/               # 项目文档
├── .claude/            # Claude Code 配置
├── .secrets/
├── README.md
└── .gitignore
```

### 2.1 reference/ 目录只读规则

`reference/` 目录仅用户可修改。AI 不得主动修改此目录下的任何文件，除非明确授权。

---

## 3. 区域组织原则

项目涉及两个维度：**区域组**（决定运行时差异）和**具体区域**（决定 OBS 端点）。

### 3.1 区域组划分

| 站点 | 包含的具体区域 | 特点 |
|------|--------------|------|
| `cn` | cn-north-4（华北-北京四）、**ap-southeast-1（中国-香港）** | 中国站，中文文档。香港虽在海外但归 cn 站点 |
| `intl` | ap-southeast-3（亚太-新加坡）、ap-southeast-2（亚太-曼谷）、af-south-1（非洲-约翰内斯堡）、af-north-1（非洲-开罗）、tr-west-1（土耳其-伊斯坦布尔）、la-north-2（拉美-墨西哥城2）、sa-brazil-1（拉美-圣保罗）等 | 国际站，中/英文文档 |

### 3.2 practices/ 按区域组组织（开发目录）

`practices/` 按**区域组**划分，同一组内的脚本和文档共享。

```
practices/{project}/
├── cn/                     # 中国站
│   ├── cn-north-4/         # 北京四区域
│   │   ├── standard/       # 单机版
│   │   │   ├── terraform/
│   │   │   ├── scripts/
│   │   │   └── .extension
│   │   └── ha/             # 高可用版（可选）
│   │       ├── terraform/
│   │       └── .extension
│   ├── ap-southeast-1/     # 香港区域（归属中国站）
│   │   ├── standard/
│   │   └── ha/
│   │
│   └── docs/               # ← 中国站中文文档（站点级，不按区域重复）
│       ├── {Name}-部署指南.md        # 合并 HA+标准版
│       └── {Name}-Solution-Details.md
│
├── intl/                   # 国际站
│   ├── ap-southeast-3/     # 新加坡
│   │   ├── standard/
│   │   │   ├── terraform/
│   │   │   ├── scripts/
│   │   │   └── .extension
│   │   └── ha/
│   ├── af-south-1/         # 约翰内斯堡
│   └── ...                 # 其他区域
│
└── docs/                    # ← 国际站文档（站点级）
    ├── zh-cn/
    │   ├── {Name}-部署指南.md
    │   └── {Name}-Solution-Details.md
    └── en-us/
        ├── {Name}-Deployment-Guide.md
        └── {Name}-Solution-Details.md
```

### 3.3 `.extension` 文件

`.extension` 定义了参数分组和国际化配置，支持 `zh-cn` 和 `en-us`。

---

## 4. release/ 按具体区域组织（发布目录）

`release/` 按**具体区域代码**展开，因为每个区域的 OBS 端点不同，需要独立的模板和 URL。

```
release/{project}/
├── cn/                           # 中国站
│   ├── cn-north-4/               # 北京四
│   │   ├── standard/
│   │   │   ├── deploying-{project}.tf
│   │   │   ├── install_{project}.sh
│   │   │   ├── .extension
│   │   │   └── url.txt
│   │   └── ha/
│   │       ├── deploying-{project}-ha.tf
│   │       └── url.txt
│   └── ap-southeast-1/           # 香港（归属中国站）
│       ├── standard/
│       │   ├── deploying-{project}-ap-southeast-1.tf
│       │   ├── install_{project}.sh
│       │   ├── .extension
│       │   └── url.txt
│       └── ha/
│           ├── deploying-{project}-ha-ap-southeast-1.tf
│           └── url.txt
│
├── intl/                         # 国际多区域
│   ├── ap-southeast-3/
│   ├── ap-southeast-2/
│   ├── af-south-1/
│   ├── af-north-1/
│   ├── tr-west-1/
│   ├── la-north-2/
│   └── sa-brazil-1/
│
└── docs/                         # ← 文档站点级
    ├── {Name}-部署指南.md
    ├── {Name}-Solution-Details.md
    └── intl/{zh-cn,en-us}/
```

每个区域目录内部：

```
release/{project}/intl/af-south-1/
├── standard/
│   ├── deploying-litellm-af-south-1.tf    # Terraform 模板（含区域代码）
│   ├── install_litellm.sh                 # 安装脚本
│   ├── .extension
│   └── url.txt                            # 该区域专属 URL
└── ha/
    ├── deploying-litellm-ha-af-south-1.tf
    └── url.txt
```

文档按站点归类，不按区域重复：

```
release/{project}/
├── cn/cn-north-4/...
├── intl/ap-southeast-3/...
├── cn/docs/
│   ├── {Name}-部署指南.md
│   └── {Name}-Solution-Details.md
└── intl/docs/
    ├── zh-cn/
    │   ├── {Name}-部署指南.md
    │   └── {Name}-Solution-Details.md
    └── en-us/
        ├── {Name}-Deployment-Guide.md
        └── {Name}-Solution-Details.md
```

### 4.1 URL 文件格式

每个区域 `url.txt` 记录该区域的部署链接：

```
# --- af-south-1 (Johannesburg) ---
TF:https://{bucket}.obs.af-south-1.myhuaweicloud.com/{path}/standard/deploying-{project}-af-south-1.tf
sh:https://{bucket}.obs.af-south-1.myhuaweicloud.com/{path}/standard/install_{project}.sh
RFS_intl:https://console-intl.huaweicloud.com/rf/?region=af-south-1&locale=en-us#/console/stack/stackCreate?templateUrl={TF_URL}&stackName={name}&stackDescription={desc}
```

### 4.2 归档包

`release/{project}/{project}.zip` 是完整的交付归档包。

---

## 5. 文件命名规范

| 对象 | 命名规则 | 示例 |
|------|---------|------|
| 项目名 | 小写 + 连字符 | `litellm`、`headroom-claude-code` |
| 模板（国内标准） | `deploying-{project}.tf` | `deploying-litellm.tf` |
| 模板（海外标准） | `deploying-{project}-{region}.tf` | `deploying-litellm-af-south-1.tf` |
| 模板（高可用） | `deploying-{project}-ha[-{region}].tf` | `deploying-litellm-ha-af-south-1.tf` |
| 安装脚本 | `install_{project}.sh` | `install_litellm.sh` |
| 部署指南（中国站中文） | `{Name}-部署指南.md` | 位于 `cn/docs/`，含标准版+HA |
| 业务文档（中国站中文） | `{Name}-Solution-Details.md` | 位于 `cn/docs/` |
| 部署指南（国际站中文） | `{Name}-部署指南.md` | 位于 `intl/docs/zh-cn/`，含标准版+HA |
| 业务文档（国际站中文） | `{Name}-Solution-Details.md` | 位于 `intl/docs/zh-cn/` |
| 部署指南（国际站英文） | `{Name}-Deployment-Guide.md` | 位于 `intl/docs/en-us/`，含标准版+HA |
| 业务文档（国际站英文） | `{Name}-Solution-Details.md` | 位于 `intl/docs/en-us/` |
| 扩展配置 | `.extension` | 固定文件名 |
| URL 清单 | `url.txt` | 每区域每个模式一个 |
| 归档包 | `{project}.zip` | `litellm.zip` |
| practices 目录 | 按区域组 | `practices/litellm/intl/` |
| release 目录 | 按具体区域代码 | `release/litellm/intl/af-south-1/` |

**注意事项：**
- 项目名不带区域后缀（如 `litellm`，不是 `litellm-hk`）
- 模板文件名中的区域后缀在 `release/` 多区域场景使用
- 高可用版模板加 `-ha-` 标识

---

## 6. OBS 存储规范

参见 `skills/reference/obs-conventions.md`（OBS 目录结构、环境区分、RFS URL 格式）。

---

## 7. 模板技术规范

### 7.1 Provider 配置

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
  region = "ap-southeast-1"   # 只写 region
}
```

**关键规则：**
- Provider 块**只写 `region`**，不加 `auth_url`/`cloud`/`insecure`
- RFS 仅支持 `huaweicloud` provider
- `required_providers` 是**对象**格式（`{}`），不是数组（`[]`）

### 7.2 标准资源创建顺序

```
VPC → Subnet → Security Group → EIP → ECS
```

### 7.3 模板与脚本分离

`.tf` 的 `user_data` 必须**最小化**：重置密码 → 下载脚本 → 执行 → 清理。
所有部署逻辑在 `.sh` 脚本中。

---

## 8. SAC 交付流程

```
洞察（用户）→ 技术评估（AI）→ 方案设计（AI）
→ 用户拍板 → 开发（AI）→ 测试 OBS 上传
→ 用户测试 → 生产打包 → 用户上传 OBS → RFS 上线
```

| 阶段 | 负责人 | 产出 |
|------|--------|------|
| 1. 洞察 | 用户 | 明确方案、目标用户、核心价值 |
| 2. 技术评估 | AI | 可行性分析、技术栈评估 |
| 3. 方案设计 | AI | 架构设计 + 决策点确认 |
| 4. 拍板 | 用户 | 确认决策点 |
| 5. 开发 | AI | `.tf` + `.sh` + Markdown 文档（部署指南+业务文档） |
| 6. 测试上传 | AI | 上传测试桶验证 |
| 7. 用户测试 | 用户 | 部署验证 |
| 8. 生产打包 | AI | 预置生产路径到 `release/` |

---

## 9. 决策点框架

| # | 决策点 | 选项 | 默认 |
|---|--------|------|------|
| 1 | 模板格式 | `.tf` (HCL) / `.tf.json` (JSON) | 问用户 |
| 2 | 安装策略 | 内联 user_data / OBS 下载 | 问用户 |
| 3 | 地域 | 国内 (cn-*) / 海外 (ap-*, af-*) | 问用户 |
| 4 | 语言 | 中文 / 英文 | 跟随地域 |
| 5 | 部署架构 | 标准版 / 高可用版 | 问用户 |
| 6 | 容器化 | Docker Compose / 直接安装 | 问用户 |

---

## 10. 项目约束规则

- **不硬编码凭证** — 无 AK/SK/API Key
- **不修改第三方源码** — 通过配置定制
- **先确认再动手** — 开发前确认决策点
- **国内/海外差异** — Docker 源、pip 镜像、语言

### 10.1 国内/海外差异

| 维度 | 国内 (cn-*) | 海外 (ap-*, af-*, tr-*, la-*) |
|------|------------|-------------------------------|
| Docker 安装源 | `mirrors.huaweicloud.com` | `download.docker.com` |
| pip 镜像 | 清华 PyPI | 直连 pypi.org |
| Docker 镜像 | SWR + `docker.1ms.run` | 直接从 Docker Hub |

---

## 11. 常用区域代码

参见 `skills/reference/region-mapping.md`（站点类型、区域代码映射、区域组划分、国内/海外差异）。

---

## 12. Agent 与 Skill 映射

参见 `.claude/MULTI-AGENT-README.md`（Agent 角色定义、技能依赖、数据流、工作流场景）。

---

*文档版本：2026-06-25*
*英文名：Solution Practice*
*区域：practices 按区域组，release 按具体区域代码*
