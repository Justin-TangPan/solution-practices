# SAC Codex 多 Agent 编排

这是 SAC 项目的 Codex 原生协作层。它与 `.claude/` 并存，但不依赖 Claude Code 的
`Workflow()`、`agent()`、`pipeline()` 或 `parallel()` DSL。

Codex 的执行入口是仓库根目录 `AGENTS.md`。主 Agent 根据用户意图选择工作流，通过
子 Agent 协作工具调度 `.codex/agents/` 中的角色，并按 `.codex/workflows/` 中的依赖、
门禁和交接协议推进。

## 目录

```text
AGENTS.md                 # Codex 自动读取的项目级调度规则
.codex/
├── README.md
├── config.toml            # 子 Agent 并发与嵌套深度
├── agents/               # 六个 TOML 原生 Agent + Markdown 详细角色契约
└── workflows/            # 五个可执行工作流说明
```

## 自然语言入口

- `用 SAC Codex 全流程做 <project>，区域为 ...`
- `用 SAC Codex 快速原型做 <project>`
- `用 SAC Codex 审计 <project>`
- `用 SAC Codex 仅交付 <project>`
- `用 SAC Codex 生成/翻译/检查 <project> 文档`

调用时应提供项目名、目标 `site/region`（例如 `cn/cn-north-4`）和简要说明。缺失信息可从仓库可靠推断时直接推断；
会显著改变架构、成本或发布范围时由主 Agent 向用户确认。

## 与 Claude Code 版本的差异

- Claude Code 版以 JS 工作流声明执行；Codex 版以 `AGENTS.md` 持久规则和角色/工作流契约执行。
- Codex 通过六个项目级 TOML 自定义 Agent 加载角色，主 Agent 根据可用槽动态分批。
- 子 Agent 共享工作区，因此通过文件所有权和只读审计约束避免冲突。
- 外部发布、Git 提交和云资源变更不会因选择工作流而自动获得授权。
