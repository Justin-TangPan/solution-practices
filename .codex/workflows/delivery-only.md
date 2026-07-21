# delivery-only — SAC Codex 仅交付

## 输入

`project`、目标 `regions`（`site/region`）和既有测试、安全、文档、用户云测门禁证据。

## 前置检查

主 Agent先确认 practices 实现与站点文档存在，并派发或本地执行必要的测试、安全复核。
不能仅因用户说“打包”而跳过阻塞级门禁。

## 阶段

1. 只读检查源目录、版本、文件命名和所需语言。
2. 派发 `delivery` 生成 `release/{project}/`、确定性归档和 SHA-256 校验和。
3. 主 Agent比对 release 与 practices，检查归档列表和校验和。
4. 记录内部 changelog 并汇报结果。

## 授权边界

本工作流只生成本地交付物。外部发布、Git commit/push 和真实云资源变更属于独立请求，
不通过“仅交付”工作流执行。
