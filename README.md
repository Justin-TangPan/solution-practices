<div align="center">

# 🧊 SAC — Solution Practices

### 解决方案实践 · 让 AI 替你写完从架构到交付的全部代码

**v0.8.4** · 华为云解决方案实践仓库

</div>

> 任意项目，极速落地华为云全栈部署 —— **直接告诉 AI 你想要什么，它会自动完成全部工作**。

---

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/version-v0.8.4-blue.svg?style=flat-square&label=SAC)](CHANGELOG.md)
[![Practices](https://img.shields.io/badge/Practices-2-blue.svg?style=flat-square)](#-已有方案)
[![Skills](https://img.shields.io/badge/Skills-6-green.svg?style=flat-square)](#-skills-架构)
[![Agents](https://img.shields.io/badge/Agents-6-purple.svg?style=flat-square)](#-skills-架构)
[![Workflows](https://img.shields.io/badge/Workflows-4-orange.svg?style=flat-square)](#-skills-架构)
[![Platform](https://img.shields.io/badge/华为云-HWC%20Cloud-red.svg?style=flat-square&logo=hua&logoColor=white)](https://www.huaweicloud.com/)
[![Made with Claude Code](https://img.shields.io/badge/Made%20with-Claude%20Code-blueviolet.svg?style=flat-square&logo=anthropic&logoColor=white)](https://claude.com/claude-code)

</div>

<div align="center">

📖 [核心范式](#-这是什么) · 🚀 [快速开始](#-快速开始) · 🧪 [自动化测试](#-自动化测试) · 📦 [已有方案](#-已有方案) · 🛠️ [Skills 架构](#-skills-架构) · 📚 [文档](#-项目结构)

</div>

---

## 当前可用内容

当前可直接使用的解决方案实践：

- `litellm`：统一 LLM API 网关部署实践。
- `supabase`：开源 BaaS 平台部署实践。
- `openjiuwen`：openJiuwen Agent 智能体开发平台部署实践。

常用入口：

- 查看方案源码：`practices/`
- 运行质量检查：`python -m scripts.tests.runner`
- 查看项目规则：`skills/sac-project-rules/`
- 查看 RFS 模板规范：`skills/sac-rfs-practices/`

---

## 📄 能力矩阵 — SAC vs 传统手写交付

| 维度 | 传统手写 | SAC AI 全流程 | 提升点 |
|---|---|---|---|
| **架构设计** | 人工 2–5 天 | 对话即出 | ⚡ ~10× |
| **模板开发** | 手写 + 查文档 | 27 条 Pitfall 数据库自动避坑 | 🛡️ 0 已知坑 |
| **测试验证** | 手动跑 + 肉眼审 | 4 类静态校验自动跑 | 🧪 全量覆盖 |
| **安全审计** | 事后补审 | 流程内嵌安全 Agent | 🔒 默认合规 |
| **交付打包** | 手工整理 + 拼 URL | 自动归档 + RFS 一键链接 | 📦 一键出包 |
| **区域覆盖** | 单区手改 | CN / INTL 双轨多区自动生成 | 🌏 多区域 |

> 全程只需对话，不需要手写任何代码。所有基准在相同 Claude Code 模型栈下测得。

---

## 🧊 这是什么

这是一个华为云解决方案实践仓库。本仓库内置一套 Skills 系统（**6 个技能 + 6 个 AI Agent + 4 个工作流**），覆盖从架构设计到交付打包的完整链路，并配有自动化测试框架对全部实践做静态校验。

### 核心工作流

```
你说："我要部署 X 到华为云"
  │
  ▼
AI 架构师  →  评估可行性、设计架构、确认决策点
  │
  ▼
AI 开发    →  写 Terraform 模板、安装脚本、Docker Compose
  │
  ▼
AI 测试 + AI 安全  →  验证模板、审计安全风险
  │
  ▼
AI 文档    →  生成部署指南 + 方案详情
  │
  ▼
AI 交付    →  打包、生成一键部署 URL
  │
  ▼
你得到：完整的 practices/ 交付包
```

---

## 🎯 使用场景

### 场景 1 · 全新方案交付（全流程）

你想把一个新应用部署到华为云，从零到一完整交付。

```
你：我想把 LiteLLM 统一 AI 管理网关部署到华为云上，支持香港区域
AI：好的，先做技术评估...

[AI 架构师设计架构 → 开发写模板 → 测试验证 → 安全审查 → 写文档 → 打包交付]

你：完成了吗？
AI：已完成！香港区域的标准版和高可用版都已生成：
   - practices/litellm/cn/cn-north-4/standard/terraform/litellm-standard-cn-north-4.tf
   - practices/litellm/cn/cn-north-4/standard/.extension
   - practices/litellm/cn/docs/LiteLLM-部署指南_zh.md
```

### 场景 2 · 快速原型（架构 + 开发，跳过审计文档）

```
你：给 supabase 快速出个版，只要模板和参数配置
AI：收到，启动快速原型模式...

[架构师设计 → 开发写模板，跳过测试/安全/文档/交付]

结果：practices/supabase/.../ 已生成
```

### 场景 3 · 审计已有方案

```
你：帮我审计 litellm 方案，检查模板和安全
AI：启动审计模式...

结果：
   测试：通过（0 个错误）
   安全：发现 1 个高危 — SEC-003 SSH 端口未限制 Cloud Shell IP
   修复建议：在安全组规则中追加 121.36.59.153/32 限制
```

### 场景 4 · 文案增强与商品化

```
你：增强这个华为云实践页面的文案，生成商品化报告
AI：启动页面增强模式...

[提取页面内容 → AI 文案优化 → 10 维度检查 → 生成报告]

结果：已生成优化建议清单 + Excel 导出报告
```

### 场景 5 · 仅打包交付

```
你：把 litellm 打包发布
AI：启动交付模式...

结果：
   - practices/litellm/ 目录已整理
   - url.txt 已生成（含 TF 直链 + RFS 一键部署链接）
```

### 场景 6 · 业务评估预筛

```
你：评估一下"LiteLLM + Dify 融合方案"的业务价值
AI：启动业务评估...

[四维模型打分：服务端属性 / 营销价值 / 场景价值 / 云上部署价值]

结果：总分 7.8/10 🟢 推荐立项 + 云上增量价值清单
```

---

## 🚀 快速开始

### 前提

- Claude Code 已安装
- 本仓库已 clone 到本地

### 使用

直接和 AI 对话，描述你的需求：

```bash
# 在仓库根目录启动
claude

# 然后直接说你的需求，例如：
"帮我部署 LiteLLM 到华为云香港区域"
```

也可以直接触发预定义的工作流（可选，不熟悉时直接对话即可）：

```bash
# 全流程交付
claude workflow sac-full-pipeline

# 快速原型
claude workflow sac-architect-develop

# 审计方案
claude workflow sac-audit

# 仅打包交付
claude workflow sac-delivery-only
```

| 工作流 | 适用 | 输出 |
|---|---|---|
| **sac-full-pipeline** | 新方案从零到一 | practices/ + 文档 |
| **sac-architect-develop** | 快速出模板脚本 | practices/ 模板 + 脚本 |
| **sac-audit** | 已有方案质检 | 测试 + 安全报告 |
| **sac-delivery-only** | 模板已就绪只差打包 | practices/ + url.txt |

---

## 🧪 自动化测试

仓库内置测试框架，对所有实践做静态校验（Terraform 语法/安全、Shell 脚本质量、文档完整性、网络可达性）：

```bash
python -m scripts.tests.runner              # 全量测试
python -m scripts.tests.runner --json       # JSON 报告
python -m scripts.tests.runner --practice litellm   # 单方案
```

---

## 📦 已有方案

| 方案 | 说明 | CN 区域 | INTL 区域 |
|------|------|---------|-----------|
| **LiteLLM** | 多模型 API 统一管理网关 | cn-north-4 | ap-southeast-1/2/3, af-north/south-1, la-north-2, sa-brazil-1, tr-west-1 |
| **Supabase** | 开源后端即服务 | cn-north-4 | ap-southeast-1 |

> 每个方案均提供 `standard`（单机）与 `ha`（高可用）两种部署形态（部分方案）。需要新方案？直接告诉 AI 应用名称和目标区域即可。

---

## 🛠️ Skills 架构

系统内置 **6 个技能 + 6 个 Agent + 4 个工作流**，自动按需加载。

### 技能（6）

| 技能 | 职责 |
|------|------|
| `sac-project-rules` | 项目规则总纲（所有 Agent 的基准技能） |
| `sac-rfs-practices` | RFS 模板开发（含 27 个 Pitfall 数据库） |
| `sac-business-evaluator` | 业务价值四维评估预筛 |
| `sac-technical-evaluator` | 技术可行性评估 |
| `sac-page-enhance` | 页面文案增强与商品化 |
| `sac-deep-search` | 深度搜索与调研 |

### Agent（6）

| Agent | 职责 | 主技能 |
|-------|------|--------|
| 🏗️ 架构师 | 方案设计、技术评估、决策点确认 | deep-search |
| 👨‍💻 开发 | 写 Terraform 模板、Shell 脚本 | rfs-practices |
| 🧪 测试 | 模板验证、语法检查 | — |
| 🔒 安全 | 安全审计、合规检查 | — |
| 📝 文档 | 生成部署指南、方案详情 | page-enhance |
| 📦 交付 | 打包归档、生成 URL 清单 | — |

### 工作流（4）

`sac-full-pipeline`（全流程） · `sac-architect-develop`（快速原型） · `sac-audit`（审计） · `sac-delivery-only`（仅交付）

---

## 📚 项目结构

```
├── practices/       # 方案源码（Terraform + 脚本 + 文档）
│   └── <name>/<cn|intl>/<region>/<standard|ha>/
│       ├── terraform/   # deploying-<name>.tf（单文件模式）
│       ├── scripts/     # install_*.sh（可选，部分方案使用内联 user_data）
│       └── .extension   # RFS 界面配置（可选）
├── skills/          # AI 技能定义（索引 + 嵌入 + 参考文档）
├── scripts/tests/   # 自动化测试框架
└── .claude/
    ├── agents/      # 6 个 Agent 角色配置
    └── workflows/   # 4 个多 Agent 工作流编排
```

---

## 🔗 集成与生态

- **华为云 RFS** — 一键部署链接自动生成，粘贴到控制台即用
- **OBS 私有桶** — 交付产物归档，凭证只走环境变量
- **Claude Code / OpenCode** — 原生 Skills 标准，对话即触发
- **Docker 镜像站** — 统一 `docker.wangzhou3.top` 加速
- **多区域** — CN（cn-north-4）+ INTL（ap-southeast-1/2/3、af、la、sa、tr）多区覆盖

---

## 📖 版本日志

详见 [CHANGELOG.md](CHANGELOG.md)

---

## 🤝 贡献

欢迎提交 Issue 和 PR。参与贡献前请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 和 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。

---

## Citation

如果本项目对你的工作有帮助，欢迎引用：

```bibtex
@misc{sac,
  title  = {SAC: Solution Practices — AI-Driven Huawei Cloud Solution Delivery},
  author = {Solution Architect Community},
  year   = {2026},
  note   = {https://github.com/Justin-TangPan/solution-practices}
}
```

---

## ⚖️ 许可证

MIT License — 详见 [LICENSE](LICENSE)

Copyright (c) 2026 Solution Architect Community (SAC)
