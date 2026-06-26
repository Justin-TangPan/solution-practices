# 决策点框架（公共参考文档）

> 本文档是 SAC 项目决策点框架的权威来源。每个新方案开发前必须确认以下决策点。

| # | 决策点 | 选项 | 默认 |
|---|--------|------|------|
| 1 | 模板格式 | `.tf` (HCL) / `.tf.json` (JSON) | 问用户 |
| 2 | 安装策略 | 内联 user_data / OBS 下载 | 问用户 |
| 3 | 地域 | 国内 (cn-*) / 海外 (ap-*, af-*) | 问用户 |
| 4 | 语言 | 中文 / 英文 | 跟随地域 |
| 5 | 部署架构 | 标准版 / 高可用版 | 问用户 |
| 6 | 容器化 | Docker Compose / 直接安装 | 问用户 |

## 详细决策说明

### Decision 1: 模板格式

| 格式 | Pros | Cons |
|------|------|------|
| `.tf` (HCL) | Clean syntax, heredoc support, readable | RFS may require JSON for some operations |
| `.tf.json` (JSON) | RFS native, no HCL parsing needed | Verbose, no heredoc, hard to maintain multiline user_data |

### Decision 2: 安装策略

| 策略 | Pros | Cons |
|------|------|------|
| **Inline user_data** | Single file deployment, no OBS dependency | user_data grows large, harder to iterate |
| **OBS download** | Hot-fixable without RFS template change | Requires OBS bucket, two files to maintain |

### Decision 3: 地域

| 区域类型 | Docker 源 | SWR 需要? | 镜像配置 |
|----------|-----------|-----------|---------|
| **国内 (cn-\*)** | SWR mirror or Huawei Cloud mirror | Yes | `daemon.json` registry-mirrors + fallback |
| **海外 (ap-\*, eu-\*)** | Direct from source | No | None needed |

### Decision 4: 语言

| 目标受众 | 描述语言 | 变量描述 | 输出信息 |
|---------|---------|---------|---------|
| 国内 (cn-\*) | 中文 | 中文 | 中文 |
| 海外 (ap-\*, eu-\*) | 英文 | 英文 | 英文 |

### Decision 5: 脚本架构

- **Inline user_data**：全部配置通过 heredoc 在 user_data 中生成，.tf 文件完全自包含
- **OBS 下载**：user_data 只下载和执行脚本，配置文件上传 OBS，独立版本管理

### Decision 6: Docker vs 直接安装

| 方式 | 适用场景 |
|------|---------|
| **Docker Compose** | 多容器应用（DB + app + 监控）、有官方 Docker 镜像 |
| **直接安装 (pip/npm)** | CLI 工具、单进程应用、Python/Node 包 |
