# SAC 多 Agent 协同工作架构

> 基于 Claude Code Workflow 引擎的 6-Agent 协同系统，覆盖方案实践交付全生命周期。

---

## 架构总览

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户指令（"做 litellm 方案"）               │
└──────────────────────┬──────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────┐
│                    Workflow 编排引擎                              │
│              (.claude/workflows/sac-full-pipeline.js)            │
│              自动调度 6 个 Agent 按阶段协作                        │
└──────┬──────┬──────┬──────┬──────┬──────┬───────────────────────┘
       │      │      │      │      │      │
       ▼      ▼      ▼      ▼      ▼      ▼
┌─────────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌─────────┐ ┌─────────┐
│ 架构师   │ │ 开发  │ │ 测试  │ │ 安全  │ │  文档   │ │  交付   │
│ Agent   │→│ Agent │→│ Agent │→│ Agent │→│  Agent  │→│  Agent  │
│         │ │      │ │      │ │      │ │         │ │         │
│ 方案设计  │ │ 编码  │ │ 验证  │ │ 审计  │ │ 文档生成 │ │ 本地打包 │
└─────────┘ └──────┘ └──────┘ └──────┘ └─────────┘ └─────────┘
       │         │        │        │         │          │
       ▼         ▼        ▼        ▼         ▼          ▼
┌─────────────────────────────────────────────────────────────────┐
│                        交付产物                                    │
│  practices/ + release/ + 文档 + 安全报告 + 校验和 + 归档包         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6 个 Agent 定义

每个 Agent 的定义文件在 `.claude/agents/` 目录下：

| Agent | 文件 | 职责 | 技能映射 |
|-------|------|------|---------|
| 🧠 **架构师** | `sac-architect.json` | 方案设计、技术评估、决策确认 | `sac-project-rules` + `sac-technical-evaluator`；业务评估/深搜按条件 |
| 💻 **开发** | `sac-developer.json` | Terraform、内联 user_data、Docker Compose | `sac-rfs-practices` + `sac-project-rules` |
| 🧪 **测试** | `sac-tester.json` | 模板验证、脚本检查、完整性检查 | `sac-project-rules` + `sac-testing` |
| 🔒 **安全** | `sac-security.json` | 凭证审计、安全组审计、端口暴露 | `sac-project-rules` + `sac-security` |
| 📝 **文档** | `sac-documenter.json` | README、业务文档、Word 生成 | `sac-project-rules` + `sac-documentation`；页面增强按条件 |
| 📦 **交付** | `sac-delivery.json` | 目录整理、校验和、打包归档 | `sac-project-rules` + `sac-delivery` |

---

## 5 个工作流

工作流脚本在 `.claude/workflows/` 目录下：

### 1️⃣ `sac-full-pipeline` — 全流程（推荐）

**触发方式：**
```
Workflow({scriptPath: '.claude/workflows/sac-full-pipeline.js', args: {
  project: 'litellm',
	  regions: ['cn/cn-north-4', 'intl/ap-southeast-1', 'intl/ap-southeast-3'],
  description: 'Multi-model API Gateway'
}})
```

**流程：** 架构师 → 开发（区域并行）→ 测试 + 安全（并行）→ 文档（区域并行）→ 交付

**适用：** 从零开始创建新方案的全流程交付

### 2️⃣ `sac-architect-develop` — 快速原型

**触发方式：**
```
Workflow({scriptPath: '.claude/workflows/sac-architect-develop.js', args: {
  project: 'litellm',
	  regions: ['cn/cn-north-4', 'intl/ap-southeast-1'],
  description: 'Multi-model API Gateway'
}})
```

**流程：** 架构师 → 开发（跳过测试/安全/文档/交付）

**适用：** 早期快速原型，先看到成果再完善

### 3️⃣ `sac-audit` — 审计

**触发方式：**
```
Workflow({scriptPath: '.claude/workflows/sac-audit.js', args: {
  project: 'litellm',
	  regions: ['cn/cn-north-4', 'intl/ap-southeast-1']
	  // release_package: 'release/litellm/litellm.zip' // 仅审计候选包时填写
}})
```

**流程：** 测试 → 安全 →（仅指定 `release_package` 时只读核验交付包）→ 报告汇总

**适用：** 审查已有 practices/ 目录的质量

### 4️⃣ `sac-delivery-only` — 仅交付

**触发方式：**
```
Workflow({scriptPath: '.claude/workflows/sac-delivery-only.js', args: {
  project: 'litellm',
	  regions: ['cn/cn-north-4', 'intl/ap-southeast-1']
}})
```

**流程：** 准备 → 打包 → 校验

**适用：** 已有 practices/ 内容和完整门禁证据，需要生成本地交付包

### 5️⃣ `sac-document-only` — 文档专用

**流程：** 使用 `sac-documentation` 完成生成、翻译、转换或只读检查；旧名
`sac-document-pipeline` 仅作兼容映射。

**适用：** 不修改 Terraform 的独立文档任务

---

## 如何运行工作流

### 方式一：使用 Workflow 工具（推荐）

```json
{
  "name": "Workflow",
  "arguments": {
    "scriptPath": ".claude/workflows/sac-full-pipeline.js",
    "args": {
      "project": "litellm",
	      "regions": ["cn/cn-north-4", "intl/ap-southeast-1"],
      "description": "Multi-model API Gateway"
    }
  }
}
```

### 方式二：直接说人话

在 Claude Code 中直接说：
- **"用全流程做 litellm 方案"** → 触发 `sac-full-pipeline`
- **"快速原型一个新方案"** → 触发 `sac-architect-develop`
- **"审计一下 litellm 的质量"** → 触发 `sac-audit`
- **"把 litellm 生成本地交付包"** → 触发 `sac-delivery-only`
- **"生成/翻译/检查 litellm 文档"** → 触发 `sac-document-only`

### 方式三：单步调 Agent

你也可以不启动工作流，直接在对话中用 Agent 工具调单个 Agent：

```
Agent({...})  // 只调架构师做设计
Agent({...})  // 只调开发写模板
Agent({...})  // 只调测试做验证
```

---

## 协同工作示意

### 全流程时序图

```
	用户: "做 litellm 方案，支持 cn-north-4、ap-southeast-1、ap-southeast-3 三个区域"
  │
  ├── 🧠 架构师 Agent ────────────────────────────────────── 1-2 轮对话
  │   输出：技术评估报告 + 架构设计 + 决策点 + 变量表
  │
  ├── 💻 开发 Agent（cn 区域）──────┐
	  ├── 💻 开发 Agent（intl/ap-southeast-1 区域）──────┤  并行执行
  ├── 💻 开发 Agent（intl 区域）────┘  ─────────────── 1 轮对话
  │   输出：每个区域的 .tf + 可选 .extension 文件
  │
  ├── 🧪 测试 Agent ──────────────┐  并行执行
  ├── 🔒 安全 Agent ──────────────┘  ─────────────── 1 轮对话
  │   输出：验证报告 + 安全审计报告
  │
  ├── 📝 文档 Agent（cn）──────────┐
	  ├── 📝 文档 Agent（intl/zh-cn + intl/en-us）──────────┤  并行执行
  ├── 📝 文档 Agent（intl）────────┘  ────────────── 1 轮对话
  │   输出：部署指南_zh / 方案详情_zh / Deployment-Guide_en / Solution-Details_en
  │
  ├── 📦 交付 Agent ─────────────────────────────────────── 1 轮对话
  │   输出：release/ 目录 + SHA256SUMS + .zip 归档
  │
  └── ✅ 向用户汇报最终结果
```

### 并行执行效率

| Agent 数量 | 串行时间 | 并行优化后 | 节省 |
|-----------|---------|-----------|------|
| 3 个区域开发 | 3x | 1x | 67% |
| 测试+安全 | 2x | 1x | 50% |
| 3 个区域文档 | 3x | 1x | 67% |

全流程从 8 个串行步骤优化为 5 个阶段，**总耗时降低约 60%**。

---

## Agent 间通信流

```
架构师 → 开发：     decisions（决策点）+ variables（变量表）
开发 → 测试：       practices/ 目录文件
开发 → 安全：       practices/ 目录文件
架构师+开发 → 文档： decisions + practices 内容
测试+安全+文档 → 交付： practices/ + 文档 + 验证通过信号
```

每个 Agent 只需要关心上一个阶段产出的结构化数据，不需要了解全流程细节。

---

## 扩展指南

### 新增 Agent

1. 在 `.claude/agents/` 下创建 `sac-xxx.json`
2. 定义 roles、skills、inputs、outputs、rules
3. 在 workflow 脚本中通过 `agent(...)` 调用

### 新增工作流

1. 在 `.claude/workflows/` 下创建 `sac-xxx.js`
2. 定义 `meta`（name, description, phases）
3. 用 `phase()` + `agent()` + `parallel()` + `pipeline()` 编排

### 映射新技能

Agent 通过 `skills` 声明必读技能，通过 `conditional_skills` 声明条件技能；技能在 `skills/` 目录下维护。
当技能更新时，Agent 自动受益（因为 prompt 中引用技能内容）。
