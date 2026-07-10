# delivery-only — SAC Codex 仅交付

## 输入

`project`、目标 `regions`；可选 `production_publish=false`。

## 前置检查

主 Agent先确认 practices 实现与站点文档存在，并派发或本地执行必要的测试、安全复核。
不能仅因用户说“打包”而跳过阻塞级门禁。

## 阶段

1. 只读检查源目录、版本、文件命名和所需语言。
2. 派发 `delivery` 生成 `release/{project}/`、URL 清单和归档。
3. 主 Agent比对 release 与 practices，检查归档列表和校验和。
4. 记录内部 changelog 并汇报结果。

## 授权边界

默认只生成本地交付物。生产 OBS 上传、外部发布、Git commit/push 和真实 RFS 部署必须由用户
明确授权；`production_publish=true` 也只能在该授权已经存在时使用。
