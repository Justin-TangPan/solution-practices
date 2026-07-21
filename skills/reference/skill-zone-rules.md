# Skill 加载规则

## 运行时真相

`AGENTS.md`、`.codex/agents/*.md` 和同名 TOML 决定 Agent 实际加载内容。
`skills-index.json` 只用于发现、展示和内部审计，不得覆盖角色合同。

## 最小加载

每个角色默认只加载项目总纲和一个角色 Skill：

| 角色 | 必需 Skill | 条件 Skill |
|---|---|---|
| Architect | `sac-project-rules`、`sac-technical-evaluator` | 业务预筛时加载 `sac-business-evaluator`；复杂多源研究时加载 `sac-deep-search` |
| Developer | `sac-project-rules`、`sac-rfs-practices` | 仅按 RFS 路由读取相关 reference |
| Tester | `sac-project-rules`、`sac-testing` | 无 |
| Security | `sac-project-rules`、`sac-security` | 无 |
| Documenter | `sac-project-rules`、`sac-documentation` | 页面营销任务才加载 `sac-page-enhance` |
| Delivery | `sac-project-rules`、`sac-delivery` | 无 |

`sac-document-pipeline` 仅保留为旧名称兼容入口，不与 `sac-documentation` 重复加载。
任务结束后清空本次 Skill 上下文。不得为了“可能有用”加载条件 Skill。
