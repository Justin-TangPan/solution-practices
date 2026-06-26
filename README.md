# SAC Solution Practice — 解决方案实践仓库

> **SAC = Solution as Code**（解决方案即代码）

---

## 这是什么

这是一个华为云解决方案实践仓库。你不需要自己写 Terraform 模板、Shell 脚本或部署文档——**直接告诉 AI 你想要什么，它会自动完成全部工作**。

本仓库内置了一套 Skills 系统（5 个技能 + 6 个 AI Agent），覆盖从架构设计到交付打包的完整链路。

---

## 核心工作流

```
你说："我要部署 X 到华为云"
  |
  v
AI 架构师 → 评估可行性、设计架构、确认决策点
  |
  v
AI 开发 → 写 Terraform 模板、安装脚本、Docker Compose
  |
  v
AI 测试 + AI 安全 → 验证模板、审计安全风险
  |
  v
AI 文档 → 生成部署指南 + 方案详情
  |
  v
AI 交付 → 打包、生成一键部署 URL
  |
  v
你得到：完整的 practices/ + release/ 交付包
```

全程只需对话，不需要手写任何代码。

---

## 使用场景

### 场景 1：全新方案交付（全流程）

你想把一个新应用部署到华为云，从零到一完整交付。

```
你：我想把 n8n 工作流自动化平台部署到华为云上，支持香港区域
AI：好的，先做技术评估...

[AI 架构师设计架构 → 开发写模板 → 测试验证 → 安全审查 → 写文档 → 打包交付]

你：完成了吗？
AI：已完成！香港区域的标准版和高可用版都已生成：
   - practices/n8n/hk/terraform/deploying-n8n.tf
   - practices/n8n/hk/scripts/install_n8n.sh
   - practices/n8n/hk/docs/README.md
   - release/n8n/hk/url.txt（含 RFS 一键部署链接）
```

### 场景 2：快速原型（架构+开发，跳过审计文档）

你只想快速出模板和脚本，不需要完整流程。

```
你：给 headroom-opencode 快速出个香港版，只要模板和脚本
AI：收到，启动快速原型模式...

[架构师设计 → 开发写模板，跳过测试/安全/文档/交付]

结果：practices/headroom-opencode/hk/ 已生成
```

### 场景 3：审计已有方案

你已经有 practices/ 下的方案，想检查质量。

```
你：帮我审计 litellm 方案，检查模板和安全
AI：启动审计模式...

结果：
   测试：通过（0 个错误）
   安全：发现 1 个高危 — SEC-003 SSH 端口未限制 Cloud Shell IP
   修复建议：在安全组规则中追加 121.36.59.153/32 限制
```

### 场景 4：文案增强与商品化

你已有华为云实践页面的内容，需要优化文案或生成商品化报告。

```
你：增强这个华为云实践页面的文案，生成商品化报告
AI：启动页面增强模式...

[提取页面内容 → AI 文案优化 → 10 维度检查 → 生成报告]

结果：已生成优化建议清单 + Excel 导出报告
```

### 场景 5：仅打包交付

模板和文档已写好，只需要打包生成 URL。

```
你：把 litellm 打包发布
AI：启动交付模式...

结果：
   - release/litellm/ 目录已整理
   - url.txt 已生成（含 TF 直链 + RFS 一键部署链接）
   - litellm.zip 已归档
```

### 场景 6：深度调研

你需要做技术选型或竞品分析。

```
你：调研一下目前主流的 AI API 网关方案，对比 LiteLLM、Kong、Tyk
AI：启动深度搜索模式...

[3 层搜索：广度覆盖 → 深度挖掘 → 交叉验证]

结果：生成调研报告（含 Mermaid 对比图 + 推荐方案 + 优劣势分析）
```

---

## 快速开始

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
```

---

## 已有方案

| 方案 | 说明 | 已支持区域 |
|------|------|-----------|
| Headroom-ClaudeCode | AI 代码助手平台 | CN, HK |
| Headroom-OpenCode | AI 编码助手平台 | HK |
| LiteLLM | 多模型 API 网关 | CN, HK, INTl |
| OpenHands | AI 开发助手平台 | CN |
| Supabase | 开源后端即服务 | CN |
| CodeWhale | 代码智能分析 | CN |
| AiToEarn | AI 收益系统 | CN, HK |

需要新方案？直接告诉 AI 应用名称和目标区域即可。

---

## Skills 架构（内部）

系统内置 5 个技能和 6 个 Agent，自动按需加载：

**技能：**
- `sac-project-rules` — 项目规则总纲（所有 Agent 的基准技能）
- `sac-rfs-practices` — RFS 模板开发（含 27 个 Pitfall 数据库）
- `sac-page-enhance` — 页面文案增强与商品化
- `sac-deep-search` — 深度搜索与调研
- `ppt-forge` — 华为风格 PPT 生成

**Agent：**
| Agent | 职责 | 主技能 |
|-------|------|--------|
| 架构师 | 方案设计、技术评估、决策点确认 | deep-search |
| 开发 | 写 Terraform 模板、Shell 脚本 | rfs-practices |
| 测试 | 模板验证、语法检查 | - |
| 安全 | 安全审计、合规检查 | - |
| 文档 | 生成部署指南、方案详情 | page-enhance |
| 交付 | 打包归档、生成 URL 清单 | - |

---

## 项目结构

```
├── practices/       # 方案源码（Terraform + 脚本 + 文档）
├── release/         # 发布包（按区域归档 + URL 清单）
├── skills/          # AI 技能定义（索引 + 嵌入 + 参考文档）
└── .claude/
    ├── agents/      # 6 个 Agent 角色配置
    └── workflows/   # 多 Agent 工作流编排
```

---

## 版本日志

详见 [CHANGELOG.md](CHANGELOG.md)

---

## 许可证

本仓库中的方案仅供学习和参考使用。
