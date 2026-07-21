# 模板验证清单（公共参考文档）

> `sac-testing` 使用本清单验证 SAC Practice；正式必需项以 `project.config.json` 和架构合同为准。

## 目录与模板

- 实现目录符合 `practices/<practice>/<site>/<region>/<variant>/`；locale 仅用于 `intl/docs/<locale>/`。
- 每个 deployable instance 只有一个可加载 `.tf` 或 `.tf.json`，不得混用。
- `required_providers` 是对象且只声明实际需要的 Provider；Provider 配置只包含 `region`。
- 资源命名来自 `var.solution_name` 或稳定用户输入，不使用 UUID 或随机 Provider。
- 标准模板使用全内联 `user_data`，不依赖远端安装脚本。
- Terraform heredoc 中 Shell 命令替换使用 `$()`；只对需保留给下游配置的 `${...}` 使用 `$${...}`。

## 部署逻辑

- 包管理命令非交互、可重复执行，并使用与站点匹配且已验证的软件源。
- `cn` 保留官方 Docker Hub 镜像名，通过已验证的 registry mirror 加速；`intl` 使用官方 Docker Hub 或 `ghcr.io`。
- 配置和有状态目录持久化；数据库初始化幂等，权限和 schema 完整。
- 服务启动后执行有界健康检查，并输出可用于排障的明确状态。
- 变量、上游地址、端口、输出和清理行为与架构合同一致。

## 安全

- 不含 AK/SK、API Key、Token、私有端点或固定生产密码。
- 公网入口和管理端口严格匹配架构合同；数据库等内部端口不做宽泛公网暴露。
- 容器不使用无依据的 `privileged`、Docker socket、host network 或危险宿主机挂载。
- 密码经安全输入或部署时生成，不因模板渲染、命令行或日志而泄露。

## 文档与国际化

- 文档名称、语言和目录符合 Practice Layout Contract；必需章节以文档模板和实际部署流程为准。
- `cn` 提供中文文档；`intl` 同时提供 `zh-cn` 与 `en-us` 文档，并保持技术事实一致。
- `.extension` 与 Terraform 变量一致；国际站 `.extension` 同时提供中英文文案。
- 文档中的参数、端口、输出、健康检查和故障排查均可从实现追溯，不含 TODO 或未解释占位符。

## 结果判定

- 静态检查不得冒充云上部署成功。
- 工具或环境失败与产品失败分开报告。
- 存在正式合同错误、安全门禁错误或不可部署项时 `passed=false`。
