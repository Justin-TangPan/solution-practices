# SAC Codex 协作规则

本文件是 Codex 在本仓库中的项目级持久指令。业务与交付规则的权威来源仍是
`skills/sac-project-rules/SKILL.md`、`skills/sac-rfs-practices/SKILL.md`、
`project.config.json` 和 `docs/project-state.md`。

## 多 Agent 调度

当用户要求以下任一事项时，允许并要求主 Agent 按 `.codex/workflows/` 调度子 Agent：

- 新建或完整交付一个 Solution Practice；
- 快速完成架构和实现原型；
- 对现有 practice 做测试、安全或完整质量审计；
- 整理、打包或发布已有 practice；
- 用户明确要求多 Agent、并行处理或使用 SAC 编排。

小范围单文件修改、解释、查询或无需角色分工的任务由主 Agent 直接完成，不为形式上的并行而拆分。

主 Agent 是唯一编排者，负责：选择工作流、读取所有适用规则、拆分任务、传递上游结果、控制并发、整合结论、执行最终质量门禁并向用户汇报。子 Agent 不得自行扩大范围、发布生产资源、提交 Git 或覆盖其他 Agent 的改动。

## 工作流选择

| 用户意图 | 工作流 |
|---|---|
| “全流程做/交付某方案” | `.codex/workflows/full-pipeline.md` |
| “快速原型/先做架构和模板” | `.codex/workflows/architect-develop.md` |
| “审计/检查质量与安全” | `.codex/workflows/audit.md` |
| “整理发布包/仅交付” | `.codex/workflows/delivery-only.md` |

若用户没有指定工作流，按最小充分流程选择；涉及生产上传、外部发布、Git 提交或真实云资源变更时，必须另行获得明确授权。

## 角色与并发

原生角色入口位于 `.codex/agents/*.toml`，详细契约位于同名 Markdown：`sac_architect`、
`sac_developer`、`sac_tester`、`sac_security`、`sac_documenter`、`sac_delivery`。

- 仅并行执行互不依赖且文件范围不重叠的任务。
- 区域开发可并行；测试与安全可并行；不同语言或站点文档可并行。
- 并发槽不足时分批执行，不改变依赖顺序。
- 每个子 Agent 必须返回：`status`、`summary`、`files_changed`、`checks_run`、`issues`、`handoff`。
- 子 Agent 发现阻塞项时应停止相关写入并报告；主 Agent决定重试、修复或请求用户输入。

## 文件所有权

- 开发 Agent：仅修改分配给它的 `practices/{project}/<site...>/<region>/<variant>/` 实现目录。
- 文档 Agent：仅修改分配站点/语言的 `docs/` 文件。
- 测试和安全 Agent：默认只读；除非主 Agent 明确要求修复，否则不得改文件。
- 交付 Agent：仅在质量门禁通过且用户授权的范围内修改 `release/`、URL 清单和版本记录。
- 主 Agent 负责共享文件、冲突处理、最终验证和 `.var/log/internal-changelog.md`。

## 通用约束

- 开始工作前检查 `git status --short`，保留用户已有修改。
- 查找优先使用 `rg`/`rg --files`，编辑使用补丁方式。
- Python 使用仓库根目录 `.venv-sac`。
- 每批修改记录到 `.var/log/internal-changelog.md`；该文件不提交、不发布。
- `reference/` 默认只读。
- 测试凭证、AK/SK、Token、私有桶地址不得写入产物或日志。
- 正式交付正确性不得依赖 `.codex/` 或 `.claude/`；它们都是本地协作资产。
