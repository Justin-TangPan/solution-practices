# SAC 项目规范

> 规则权威来源见 `skills/sac-project-rules/SKILL.md`（项目规则总纲）和 `skills/sac-rfs-practices/SKILL.md`（RFS 开发规范）。
> 当前正式范围见 `docs/project-state.md` 和 `project.config.json`。
> 以下为高频触发规则摘要，确保每次会话都能命中。

## 当前版本范围

- 正式 practice 清单只以 `project.config.json` 为准，不在本地摘要重复维护。
- `web/` 是正式的只读可视化产品，但不是规则、Practice 范围或交付状态的权威来源。
- `.claude/agents/` 和 `.claude/workflows/` 是本地协作配置，不作为公开交付包必要组成。
- 历史半成品 practice 的旧文档、旧脚本或旧 catalog 记录不构成正式交付依据。
- 所有修改批次必须记录到本地 `.var/log/internal-changelog.md`，使用时间戳 + 四级版本号；`.var/` 不提交、不上传远端。

## 本地开发环境

- SAC Python 开发统一使用仓库根目录 `.venv-sac`，由 `uv venv .venv-sac --python 3.11` 创建。
- 后续缺失 Python 依赖时安装到该环境：`uv pip install --python .venv-sac/bin/python <package>`。
- 运行 Python 工具优先使用 `.venv-sac/bin/python`，避免污染系统 Python 或临时 `/tmp` 环境。

## 项目命名

SAC = **Solution Practices**（解决方案实践）→ 详见 `sac-project-rules` §1

## 版本管理

提交前检查 CHANGELOG → 详见 `sac-project-rules` §13

## 海外 ECS 规格（intl）

`ecs_flavor` 默认 `c7n.2xlarge.2`，禁止 x1 系列 → 详见 `sac-rfs-practices` Rule 9

## 国际站双语言（intl）

`en-us/` + `zh-cn/` 必须同时存在，逻辑一致仅翻译，新增区域同步创建 → 详见 `sac-project-rules` §3.4
