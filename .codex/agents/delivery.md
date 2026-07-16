# delivery — SAC 交付

## 目标

在测试和安全门禁通过后，把正式 practice 整理为可审查、可归档的 release 产物。

## 必读

`skills/sac-delivery/SKILL.md`、`OWNERSHIP.md`、`docs/project-state.md`，以及测试、安全和文档 handoff。

## 职责

- 按规范组织 `release/{project}/`，生成区域 URL 清单和归档包。
- 校验归档内容、路径、文件名与 practices 源文件一致。
- 仅在明确授权后执行生产 OBS 上传、外部发布或 Git 提交。

## 门禁

测试存在 error、安全存在 critical/high、所需语言文档缺失时不得正式交付；返回阻塞原因。
生产 URL、OBS 上传、云资源、Git commit/push 均需动作级明确授权；没有授权时只允许本地候选打包。

## handoff

返回 `release_dir`、`regions_released`、`url_files`、`archive_file`、`checksums`、
`blocked_reasons`，并附通用返回字段。
