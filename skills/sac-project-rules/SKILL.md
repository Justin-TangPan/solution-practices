---
name: sac-project-rules
status: formal
scope: formal-delivery
owner: project
description: |
  SAC（Solution Practices — 解决方案实践）交付包项目的完整规则定义。

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

> **SAC = Solution Practices**（解决方案实践）
>
> 中文名：**解决方案实践**
> 英文名：**Solution Practices**
> 简称：**SAC**

本文档定义了本项目（Solution Practices）的完整组织规则、命名规范、文件结构和交付流程。

---

## 0. 当前范围与事实源

本 skill 是正式规则源，但不直接声明当前有哪些 practice 属于正式版本。当前正式范围以仓库根目录 `project.config.json` 为准。

事实源优先级：

1. `project.config.json`：正式 practice 范围、质量门禁策略、资产状态。
2. `practices/`：可部署方案实现。
3. `scripts/tests/`：正式质量门禁。
4. `skills/`：规则和可复用知识。
5. `web/`：未来可视化原型，不反向约束正式版本。

当前治理文件：

- `docs/project-state.md`：当前版本状态。
- `OWNERSHIP.md`：资产归属。
- `docs/contracts/`：目录、脚本、skill、发布契约。

历史半成品 practice、旧 web catalog、旧一次性脚本或旧 README 示例，不构成正式交付依据，除非对应 practice 被重新加入 `project.config.json`。

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
│   │   ├── cn/         # 中国站（含cn-north-4北京）
│   │   │   ├── cn-north-4/standard/...
│   │   │   ├── cn-north-4/ha/...
│   │   │   └── docs/         ← 中国站中文文档（站点级）
│   │   └── intl/       # 国际站（含ap-southeast-1香港 + 其他区域 + docs/{zh-cn,en-us}）
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
| `cn` | cn-north-4（华北-北京四） | 中国站，中文文档 |
| `intl` | **ap-southeast-1（中国-香港）**、ap-southeast-3（亚太-新加坡）、ap-southeast-2（亚太-曼谷）、af-south-1（非洲-约翰内斯堡）、af-north-1（非洲-开罗）、tr-west-1（土耳其-伊斯坦布尔）、la-north-2（拉美-墨西哥城2）、sa-brazil-1（拉美-圣保罗）等 | 国际站，中/英文文档 |

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
│   │
│   └── docs/               # ← 中国站中文文档（站点级，不按区域重复）
│       ├── {Name}-部署指南.md        # 合并 HA+标准版
│       └── {Name}-Solution-Details.md
│
├── intl/                   # 国际站
│   ├── ap-southeast-1/     # 香港区域（归属 intl 国际站）
│   │   ├── en-us/
│   │   │   ├── standard/
│   │   │   └── ha/
│   │   └── zh-cn/
│   │       ├── standard/
│   │       └── ha/
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

### 3.4 国际站双语言规则（intl）

`practices/*/intl/` 下必须同时存在 `en-us/` 和 `zh-cn/` 目录，且满足：

1. **必须同时存在** — 不允许只有 en-us 没有 zh-cn，反之亦然
2. **逻辑完全一致** — zh-cn 版仅翻译 `description` / `error_message` / shell 注释 / `output`，资源定义和部署逻辑与 en-us 完全一致
3. **同步创建** — 新增区域时，en-us 和 zh-cn 同步创建，不允许先建一个再补另一个

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
│
├── intl/                         # 国际多区域
│   ├── ap-southeast-1/           # 香港（归属 intl 国际站）
│   │   ├── standard/
│   │   │   ├── deploying-{project}-ap-southeast-1.tf
│   │   │   ├── install_{project}.sh
│   │   │   ├── .extension
│   │   │   └── url.txt
│   │   └── ha/
│   │       ├── deploying-{project}-ha-ap-southeast-1.tf
│   │       └── url.txt
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

参见 `sac-rfs-practices` 获取完整技术规范：

| 本节主题 | 对应位置 |
|---------|---------|
| Provider 配置（只写 region） | `sac-rfs-practices` Rule 1 + Pitfall 19 |
| required_providers 对象格式 | `sac-rfs-practices` tf.json Template Standards |
| 标准资源创建顺序 | `sac-rfs-practices` VPC/Subnet/Security Group/EIP/ECS |
| 模板-脚本分离（模式 A） | `sac-rfs-practices` Rule 3 + user_data Pattern |
| 全内联 user_data（模式 B） | `sac-rfs-practices` User Constraints §7 |
| HCL2 转义坑（`%%{}`/`$$`） | `sac-rfs-practices` Pitfall 22 |
| intl 语言层 | `sac-rfs-practices` 定位 → intl 语言层说明 |

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

### 8.1 交付步骤（AI 执行）

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 整理 practices/ 到 release/ | 按区域复制 practices 文件到 release 目录 |
| 2 | 预置生产 OBS 路径 | 将 templateUrl 中的测试桶路径替换为生产桶路径 |
| 3 | 生成 URL 清单 | 为每个区域生成 TF 链接、SH 链接、RFS 页面链接 |
| 4 | 打包归档 | 创建 {project}.zip，包含全部区域文件 |
| 5 | 更新变更日志 | 在 CHANGELOG.md 中记录版本变更 |
| 6 | Git 提交 | 提交 release/ 目录到仓库 |

### 8.2 URL 格式

| 类型 | 格式 |
|------|------|
| TF 模板 | `https://{bucket}.obs.{region}.myhuaweicloud.com/{path}/deploying-{project}.tf` |
| 安装脚本 | `https://{bucket}.obs.{region}.myhuaweicloud.com/{path}/install_{project}.sh` |
| RFS（intl） | `https://console-intl.huaweicloud.com/rf/?region={region}&locale=en-us#/console/stack/stackCreate?templateUrl={TF_URL}&stackName={name}&stackDescription={desc}` |
| RFS（cn） | `https://console.huaweicloud.com/rf/?region={region}&locale=zh-cn#/console/stack/stackCreate?templateUrl={TF_URL}&stackName={name}&stackDescription={desc}` |

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

通用开发约束参见 `sac-rfs-practices` User Constraints（不硬编码凭证 → UC2，不修改第三方源码 → UC3，先确认再动手 → UC5）。

国内/海外差异（Docker 源、pip 镜像、Docker 镜像站）参见 `skills/reference/docker-registry.md`。

### 10.2 文档交付规则

- **方案描述必须包含量化价值指标** — 如"降低 70% 运维成本"、"部署时间从 2 小时缩短至 10 分钟"
- **费用表必须包含按需和包年包月两种计费模式** — 两种模式都要列出，方便用户对比
- **部署参数表中的每个变量必须有中文/英文描述** — cn 站点中文描述，intl 站点英文描述
- **所有 URL 链接必须可访问** — 文档中不含占位符 URL（如 `https://xxx`），所有链接必须指向真实地址

### 10.3 上线信息告知规则

交付时（交付 Agent 完成打包后、或向用户汇报交付结果时），**必须向用户明确说明以下三项上线信息**：

| # | 信息项 | 说明 | 示例 |
|---|--------|------|------|
| 1 | **上线形式** | 部署方式与架构变体 | `RFS 一键部署 · 标准版` / `RFS 一键部署 · 高可用版` |
| 2 | **上线站点** | 中国站 (cn) 或国际站 (intl) | `cn（中国站）` / `intl（国际站）` |
| 3 | **上线 Region** | 具体区域代码及中文名称 | `cn-north-4（华北-北京四）` / `ap-southeast-1（中国-香港）` |

**输出格式**（在交付汇报或文档中必须出现）：

```
上线信息：
  形式：RFS 一键部署 · 标准版
  站点：intl（国际站）
  Region：ap-southeast-1（中国-香港）
```

- 多区域交付时，每个区域单独列出上线信息
- 此规则适用于所有交付场景：Agent 工作流交付、手动交付、文档中的部署说明

---

## 11. 常用区域代码

参见 `skills/reference/region-mapping.md`（站点类型、区域代码映射、区域组划分、国内/海外差异）。

---

## 12. Agent 与 Skill 映射

参见 `.claude/MULTI-AGENT-README.md`（Agent 角色定义、技能依赖、数据流、工作流场景）。

---

## 13. 版本管理

每次提交代码前，检查是否需要更新 `CHANGELOG.md`：

- **新功能 / 架构变更** → 升次版本号（如 v0.3.0 → v0.4.0）
- **修复 / 小改动** → 升修订号（如 v0.3.0 → v0.3.1）

CHANGELOG 格式参照已有条目：**日期 + 版本标题 + 分类描述 + 关键文件清单**。

### 13.1 版本号同步规则

版本号变更时，**必须同步更新以下三处**，缺一不可：

| # | 文件 | 更新内容 |
|---|------|---------|
| 1 | `CHANGELOG.md` | 新增版本条目（日期 + 标题 + 分类描述 + 关键文件） |
| 2 | `README.md` | ① 版本显示文本（`**vX.Y.Z**`）② 版本徽章（`badge/version-vX.Y.Z-blue`） |
| 3 | `.claude/CLAUDE.md` | 如有版本号引用，同步更新 |

**检查清单**（提交前逐项确认）：

- [ ] `CHANGELOG.md` 顶部新增了版本条目
- [ ] `README.md` 中 `**vX.Y.Z**` 已更新为新版本号
- [ ] `README.md` 中 badge `version-vX.Y.Z` 已更新为新版本号
- [ ] 方案表（README 已有方案章节）已反映新增/变更的区域覆盖

---

*文档版本：2026-07-07*
*英文名：Solution Practices*
*区域：practices 按区域组，release 按具体区域代码*
