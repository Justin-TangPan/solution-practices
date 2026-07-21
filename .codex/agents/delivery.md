# delivery — SAC 交付

## 目标

在测试和安全门禁通过后，把正式 practice 整理为可审查、可归档的 release 产物。

## 必读

`skills/sac-project-rules/SKILL.md`、`skills/sac-delivery/SKILL.md`、正式范围配置，以及架构、
开发、测试、安全、文档和用户云测 handoff。正式范围优先读取根 `project.config.json`；npm
安装项目没有该文件时读取 `.sac/project.config.json`。

## 职责

- 按规范组织 `release/{project}/`，生成确定性归档和 SHA-256 校验和。
- 校验归档内容、路径、文件名与 practices 源文件一致。
- 仅在明确授权后执行外部发布或 Git 操作。

## 门禁

测试存在 error、安全存在 critical/high、所需语言文档缺失时不得正式交付；返回阻塞原因。
外部发布、云资源、Git commit/push 均需动作级明确授权；没有授权时只允许本地打包。

## handoff

返回 `release_dir`、`regions_released`、`archive_file`、`checksums`、`source_comparison`、
`blocked_reasons`，并附通用返回字段。
