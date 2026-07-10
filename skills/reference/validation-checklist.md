# 模板验证清单（公共参考文档）

> 本文档定义了 SAC 项目模板与脚本的验证标准。sac-tester Agent 通过引用本文档执行验证。

## 模板结构验证（template）

- required_providers 是对象格式，不是数组
- 只有 huaweicloud provider（无 random/tls 等）
- Provider 块只有 region
- 资源名使用 var.solution_name 前缀或稳定用户输入（无 uuid/random）
- user_data 模式明确：标准模式为全内联，保持自包含、可审计；OBS 下载模式为例外，必须说明原因且 user_data 保持最小化
- 不在同一 deployable instance 混用 OBS 下载和全内联部署逻辑
- Terraform heredoc 中 shell 命令替换必须写 `$()`，不得写 `$$()`；只对需要保留给下游配置的 `${...}` 使用 `$${...}`

## 部署逻辑验证（user_data / optional install_script）

- pip install 用 --break-system-packages --ignore-installed
- 所有依赖在一条 pip 命令中
- 国内版：PyPI 镜像 -i https://pypi.tuna.tsinghua.edu.cn/simple
- 国内版：Docker CE 从 mirrors.huaweicloud.com
- 海外版：Docker CE 从 download.docker.com
- 国内版：Docker Hub 镜像在 compose / install 脚本 / user_data 中保留官方镜像名，通过 `/etc/docker/daemon.json` 配置 `registry-mirrors: ["https://docker.wangzhou3.top"]`
- 国内版：禁止把 Docker Hub 镜像改写为 `docker.wangzhou3.top/sac/...` 等自定义路径，除非该路径是已验证可拉取的正式镜像仓
- 海外版：Docker 镜像引用无前缀（官方 Docker Hub / ghcr.io），禁止 docker.wangzhou3.top
- 环境变量在 .bashrc 中 export
- 代理上游 URL 显式设置
- 健康检查循环（最长 120s）
- Compose 中有 PostgreSQL/MySQL 等有状态服务时，bootstrap 必须幂等创建应用数据库、owner、服务角色密码、必需 schema 和授权；若用 heredoc 通过 `docker exec` 执行 SQL，必须加 `-i`
- `manifest.json` 不作为标准交付物校验；只有用户或工具明确要求时才检查其内容

## 安全验证（security）

- 无硬编码 AK/SK/API Key
- 安全组端口范围合理
- SSH 仅限 Cloud Shell IP
- 数据库密码不硬编码在 compose 中

## 文档验证（documents）

- README.md 含 9 个标准章节
- 语言匹配区域（国内中文/海外英文）
- Output 引用正确日志路径
- 文档中无占位符或 TODO
