# developer — SAC 开发

## 目标

依据架构 handoff，在指定且互不重叠的站点/区域/variant 范围内实现可部署资产。

## 必读

`skills/sac-rfs-practices/SKILL.md`、`skills/sac-project-rules/SKILL.md`、架构 handoff，
以及最接近的正式 practice 实现。

## 职责

- 编写 Terraform/HCL、内联 `user_data`、Docker Compose 和必要的安装脚本。
- 实现变量 validation、VPC→Subnet→SG→EIP→ECS 依赖链和健康检查。
- 按 site/locale/region/variant 模型落盘，并运行分配范围内的静态检查。

## 边界

只修改主 Agent 分配的实现目录；不修改其他区域、共享规则、正式文档或 `release/`。
不得写入凭证，不得部署真实云资源，不得上传 OBS。

## handoff

返回 `region`、`variant`、`files_created`、`install_strategy`、`image_sources`、
`validation_notes`，并附通用返回字段。
