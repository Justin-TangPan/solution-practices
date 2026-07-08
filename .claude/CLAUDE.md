# SAC 项目规范

> 规则权威来源见 `skills/sac-project-rules/SKILL.md`（项目规则总纲）和 `skills/sac-rfs-practices/SKILL.md`（RFS 开发规范）。
> 当前正式范围见 `docs/project-state.md` 和 `project.config.json`。
> 以下为高频触发规则摘要，确保每次会话都能命中。

## 当前版本范围

- 正式 practice：`litellm`、`supabase`，以 `project.config.json` 为准。
- `web/` 是未来可视化原型，暂不进入正式版本质量门禁。
- `.claude/agents/` 和 `.claude/workflows/` 是本地协作配置，不作为公开交付包必要组成。
- 历史半成品 practice 的旧文档、旧脚本或旧 catalog 记录不构成正式交付依据。

## 项目命名

SAC = **Solution Practices**（解决方案实践）→ 详见 `sac-project-rules` §1

## 版本管理

提交前检查 CHANGELOG → 详见 `sac-project-rules` §13

## 海外 ECS 规格（intl）

`ecs_flavor` 默认 `c7n.2xlarge.2`，禁止 x1 系列 → 详见 `sac-rfs-practices` Rule 9

## 国际站双语言（intl）

`en-us/` + `zh-cn/` 必须同时存在，逻辑一致仅翻译，新增区域同步创建 → 详见 `sac-project-rules` §3.4
