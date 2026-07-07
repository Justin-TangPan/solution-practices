# 模板验证清单（公共参考文档）

> 本文档定义了 SAC 项目模板与脚本的验证标准。sac-tester Agent 通过引用本文档执行验证。

## 模板结构验证（template）

- required_providers 是对象格式，不是数组
- 只有 huaweicloud provider（无 random/tls 等）
- Provider 块只有 region
- 资源名使用 var.solution_name 前缀（无 uuid/random）
- user_data 最小化：密码 + wget + 执行 + 清理
- 所有资源命名统一加 -${local.name_suffix}

## 安装脚本验证（install_script）

- pip install 用 --break-system-packages --ignore-installed
- 所有依赖在一条 pip 命令中
- 国内版：PyPI 镜像 -i https://pypi.tuna.tsinghua.edu.cn/simple
- 国内版：Docker CE 从 mirrors.huaweicloud.com
- 海外版：Docker CE 从 download.docker.com
- 国内版：Docker 镜像引用前缀 docker.wangzhou3.top/（compose / install 脚本 / user_data）
- 海外版：Docker 镜像引用无前缀（官方 Docker Hub / ghcr.io），禁止 docker.wangzhou3.top
- 环境变量在 .bashrc 中 export
- 代理上游 URL 显式设置
- 健康检查循环（最长 120s）

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
