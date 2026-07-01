export const practices = [
  { slug: "litellm", name: "LiteLLM", tagline: "统一 LLM API 网关", desc: "将 100+ LLM Provider 统一为 OpenAI 兼容 API，内置虚拟密钥管理、用量追踪、负载均衡。", overview: "LiteLLM 将 100+ LLM Provider（OpenAI、Anthropic、Azure、Bedrock、华为云 MaaS 等）统一为 OpenAI 兼容 API。内置虚拟密钥管理与预算控制、用量追踪与日志、负载均衡与故障转移、重试与回退策略。适合作为企业多模型接入的统一网关层，与 Dify、Headroom 等上层应用组合使用。", stars: "17k+", category: "AI 网关", regions: ["cn-north-4", "ap-southeast-1"], score: 8.75, tier: "strong" as const, cost: "¥160–220/月", color: "blue", hasHA: true },
  { slug: "dify", name: "Dify", tagline: "AI 应用开发平台", desc: "可视化编排 LLM 工作流、Agent 推理与 RAG 管道。80k+ Stars 社区驱动。", overview: "Dify 是开源的 LLM 应用开发平台，提供可视化 Workflow 编排、Agent 推理、RAG 知识库、Prompt 工程与评测能力。支持从原型到生产的全生命周期，Web UI 低代码上手，适合企业构建客服、知识问答、文档处理等 AI 应用。", stars: "80k+", category: "AI 平台", regions: ["cn-north-4"], score: 8.5, tier: "strong", cost: "¥200–300/月", color: "violet", hasHA: false },
  { slug: "cli-anything-dify", name: "Agent-Native 工厂", tagline: "CLI-Anything + Dify 融合", desc: "Dify 编排智能工作流 + CLI-Anything 操控外部软件，AI 从对话到执行的闭环。", overview: "将 Dify（AI 应用开发平台，80k+ Stars）与 CLI-Anything（Agent-Native CLI 工厂，44k+ Stars）深度融合：Dify 解决 AI 如何思考，CLI-Anything 解决 AI 如何行动。Agent 不仅能生成方案，还能直接操作 Ollama 推理、n8n 编排、ComfyUI 生图，实现 Agent-Native 软件自动化。", stars: "44k+", category: "AI 平台", regions: ["cn-north-4"], score: 7.0, tier: "good" as const, cost: "¥250–400/月", color: "violet", hasHA: false },
  { slug: "headroom-claude-code", name: "Headroom", tagline: "AI 代码助手，60–95% Token 压缩", desc: "代理模式压缩 Token 降低 API 成本，零代码改动接入华为云 MaaS。", overview: "Headroom 在代理模式下压缩上下文 Token，降低 60–95% API 成本，零代码改动接入华为云 MaaS。适合对 Token 成本敏感的团队级编码场景，与 Claude Code / Cursor 等 IDE 配合使用。", stars: "5k+", category: "AI 编码", regions: ["cn-north-4", "ap-southeast-1"], score: 7.75, tier: "good", cost: "¥150–250/月", color: "emerald", hasHA: false },
  { slug: "supabase", name: "Supabase", tagline: "开源 BaaS，含 Auth、Storage、向量库", desc: "Firebase 替代方案。PostgreSQL、身份认证、对象存储与向量搜索。", overview: "Supabase 是 Firebase 的开源替代，基于 PostgreSQL 提供 Auth、Storage、Realtime 与向量搜索。适合需要后端即服务、用户认证、对象存储与 AI 向量检索的 Web/移动应用，可替代自建后端栈。", stars: "75k+", category: "BaaS", regions: ["cn-north-4"], score: 7.75, tier: "good", cost: "¥300–500/月", color: "indigo", hasHA: false },
  { slug: "openhands", name: "OpenHands", tagline: "自主编码 AI Agent", desc: "自主 AI 编码 Agent，支持代码生成、调试与重构。", overview: "OpenHands 是自主 AI 编码 Agent，支持代码生成、调试、重构与仓库级任务执行。适合需要自动化处理重复编码任务、PR 草稿生成、遗留代码改造的场景。", stars: "40k+", category: "AI 编码", regions: ["cn-north-4"], score: 7.0, tier: "good", cost: "¥200–350/月", color: "amber", hasHA: false },
  { slug: "headroom-opencode", name: "OpenCode", tagline: "AI 编码助手（开源版）", desc: "Headroom 开源版本，支持多模型接入与 Token 压缩。", overview: "OpenCode 是 Headroom 的开源版本，支持多模型接入与 Token 压缩，适合希望自托管、可控成本与可定制编码助手的团队。", stars: "3k+", category: "AI 编码", regions: ["cn-north-4"], score: 7.0, tier: "good", cost: "¥150–250/月", color: "emerald", hasHA: false },
  { slug: "codewhale", name: "CodeWhale", tagline: "代码智能分析平台", desc: "代码质量分析与智能建议。", overview: "CodeWhale 提供代码质量分析与智能改进建议，集成静态分析与 LLM 解释，适合作为代码评审辅助与质量门禁组件。", stars: "2k+", category: "代码分析", regions: ["cn-north-4"], score: 6.5, tier: "fair", cost: "¥180–280/月", color: "stone", hasHA: false },
  { slug: "aitoearn", name: "AiToEarn", tagline: "AI 收益管理系统", desc: "模型收益管理与分配系统。", overview: "AiToEarn 是模型收益管理与分配系统，适合多模型、多团队场景下的成本归集、结算与配额管理。", stars: "1k+", category: "AI 运营", regions: ["cn-north-4", "ap-southeast-1"], score: 6.0, tier: "fair", cost: "¥200–300/月", color: "rose", hasHA: false },
]

export const evaluations = [
  { name: "CLI-Anything", url: "github.com/HKUDS/CLI-Anything", stars: "44.2k", d1: 3, d2: 6, d3: 4, d4: 1, total: 3.5, grade: "red", d1r: "CLI 包装层——在 REST API 外套一层 Click，核心桌面 harness 无法上云", d2r: "概念新颖但 44k stars 与云部署脱节", d3r: "本地有价值；云上是伪需求", d4r: "全部 8 项云上增量价值指标均未满足", rec: "不建议作为独立解决方案实践" },
  { name: "Dify", url: "github.com/langgenius/dify", stars: "80k+", d1: 9, d2: 8, d3: 9, d4: 8, total: 8.5, grade: "green", d1r: "服务端 + Web UI，REST API 完整", d2r: "80k stars，华为云市场零同类", d3r: "AI 应用开发是企业刚需", d4r: "云上高可用、RDS 持久化、多 Region", rec: "强烈推荐——已上线" },
  { name: "LiteLLM", url: "github.com/BerriAI/litellm", stars: "17k+", d1: 10, d2: 8, d3: 8, d4: 9, total: 8.75, grade: "green", d1r: "纯服务端 API 网关", d2r: "唯一统一 LLM 网关", d3r: "多 Provider 统一是真实痛点", d4r: "API 网关需 7×24 在线", rec: "强烈推荐——已上线" },
  { name: "Ollama", url: "github.com/ollama/ollama", stars: "120k+", d1: 9, d2: 7, d3: 7, d4: 6, total: 7.25, grade: "amber", d1r: "服务端 REST API", d2r: "120k stars 顶级知名度", d3r: "本地推理真实需求", d4r: "云上 GPU 可行但本地体验更好", rec: "值得做，与 Dify 组合价值更高" },
]

export const regions = [
  { code: "cn-north-4", name: "华北-北京四", group: "cn" },
  { code: "cn-southwest-2", name: "西南-贵阳一", group: "cn" },
  { code: "ap-southeast-1", name: "中国-香港", group: "cn" },
  { code: "ap-southeast-3", name: "亚太-新加坡", group: "intl" },
]
