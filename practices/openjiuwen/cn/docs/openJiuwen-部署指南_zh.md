# 部署 openJiuwen Agent 智能体开发平台 部署指南

> 文档类型：华为云解决方案实践部署指南

## 1. 方案概述

openJiuwen Agent Studio 是 openJiuwen 体系的一站式 AI Agent 开发平台，提供低代码/零代码可视化开发、工作流编排、模型、知识库、插件和记忆等资源管理能力。本实践通过华为云 RFS 一键创建 ECS、VPC、安全组和 EIP，并在 ECS 上自动部署 openJiuwen Agent Studio 单机标准版。

### 1.1 应用场景

| 场景 | 说明 |
|---|---|
| 智能体原型开发 | 通过可视化界面创建 Agent、配置工具和工作流，快速完成业务原型验证。 |
| 企业内部智能助手 | 对接企业可用的大模型和 Embedding 模型，构建客服、运营、研发辅助等内部助手。 |
| Agent 发布与运行验证 | 通过内置 Runtime 能力管理 Agent 的发布、健康检查和运行态访问。 |

### 1.2 方案架构

```text
用户浏览器
  |
  | HTTPS :3000
  v
EIP + 安全组
  |
  v
ECS Ubuntu 24.04
  ├── Docker / Docker Compose
  ├── openJiuwen Frontend
  ├── openJiuwen Backend
  ├── openJiuwen Agent Runtime
  ├── Plugin Server
  ├── Sandbox Gateway / Sandbox Server
  ├── MySQL
  ├── Milvus + Etcd + MinIO
  └── 本地 Docker volumes
```

### 1.3 方案优势

| 优势 | 说明 |
|---|---|
| 一键部署 | RFS 自动完成网络、ECS、Docker 环境和 openJiuwen 容器服务启动。 |
| 可视化开发 | 提供 Agent 开发、工作流编排、模型配置、插件管理等 Web 能力。 |
| 单机闭环 | 首版标准版将数据库、向量库、对象存储、前后端和运行时集中部署在一台 ECS，便于验证和试用。 |
| 国内镜像友好 | 方案使用官方 cn-north-4 部署包，并配置 Docker registry mirror 以降低镜像拉取失败率。 |

### 1.4 约束与限制

- 本实践为单机标准版，适合试用、演示和小规模验证，不等同于生产高可用架构。
- openJiuwen 前端默认使用自签名 HTTPS 证书，浏览器可能提示证书不受信任，选择继续访问即可。
- Milvus 2.6.2 对 CPU 指令集有要求，官方文档提示缺少 AVX 指令时 Milvus 可能退出。
- 首次部署需要下载多个容器镜像，耗时与公网带宽、镜像源可用性有关。
- 如需完整使用记忆/知识相关能力，需要配置 Embedding 模型参数。

## 2. 资源与成本规划

### 2.1 单机版资源清单

| 云服务 | 规格 | 数量 | 说明 |
|---|---:|---:|---|
| ECS | x1.8u.16g 或更高 | 1 | 运行 openJiuwen 全部容器组件 |
| EVS 系统盘 | 高IO SAS 200GB | 1 | 存放系统、Docker 镜像和运行数据 |
| VPC/Subnet | 172.16.0.0/16 | 1 | 自动创建 |
| 安全组 | 开放 3000/8000/8186 和 Cloud Shell SSH | 1 | 3000 为主要访问入口 |
| EIP | 100Mbit/s 按流量 | 1 | 下载镜像与访问控制台 |

### 2.2 费用说明

实际费用以华为云控制台价格为准。本模板默认按需计费，适合验证和短期试用；长期使用建议改为包年包月并根据业务负载调整 ECS 规格和磁盘容量。

## 3. 实施步骤

### 3.1 准备工作

1. 登录华为云账号，并确认账号余额充足。
2. 开通 RFS、ECS、VPC、EIP、EVS 等服务。
3. 创建 RFS 委托 `rf_admin_trust`，授权 RFS 创建云资源。
4. 如需要启用记忆/知识能力，准备可用的 Embedding 模型 `API Base`、模型名称和 API Key。

### 3.2 快速部署

1. 打开 RFS 控制台，选择“创建资源栈”。
2. 上传或选择本实践的 Terraform 模板 `deploying-openjiuwen.tf`。
3. 按参数表填写配置。

| 参数 | 默认值 | 说明 |
|---|---|---|
| `solution_name` | `openjiuwen` | 资源名前缀 |
| `ecs_flavor` | `x1.8u.16g` | ECS 规格，建议不要低于 8vCPU/16GiB |
| `ecs_password` | 无 | ECS root 密码 |
| `system_disk_size` | `200` | 系统盘容量 GB |
| `bandwidth_size` | `100` | EIP 带宽 Mbit/s |
| `deploy_package_url` | 官方 0.1.5 amd64 包 | openJiuwen 官方部署工具包 |
| `frontend_port` | `3000` | Studio 前端访问端口 |
| `backend_port` | `8000` | 后端健康检查端口 |
| `runtime_port` | `8186` | Runtime 健康检查端口 |
| `embedding_api_base` | 空 | 可部署后配置 |
| `embedding_model_name` | 空 | 可部署后配置 |
| `embedding_api_key` | 空 | 可部署后配置 |

4. 提交资源栈，等待 RFS 显示创建成功。
5. 部署完成后查看 RFS 输出 `studio_url` 和 `access_info`。

### 3.3 开始使用

1. 访问 RFS 输出的地址：

```text
https://<EIP>:3000
```

2. 浏览器提示自签名证书风险时，选择继续访问。
3. 进入 openJiuwen Studio 后，按界面提示配置模型、插件和工作流。
4. 如需检查服务状态，可登录 ECS 后执行：

```bash
tail -f /var/log/openjiuwen-bootstrap.log
cd /opt/openjiuwen/deployTool
docker ps
./service.sh stop
./service.sh up
```

### 3.4 快速卸载

1. 在 RFS 控制台删除资源栈。
2. RFS 会删除 ECS、EIP、VPC、安全组等云资源。
3. 如果曾在 ECS 内手动挂载外部数据盘，请在删除前自行备份数据。

## 4. 附录

### 4.1 名词解释

| 名词 | 说明 |
|---|---|
| openJiuwen Agent Studio | openJiuwen 的可视化 Agent 开发平台 |
| Agent Runtime | openJiuwen 的智能体运行和部署管理服务 |
| RFS | 华为云资源编排服务 |
| Milvus | 向量数据库，用于向量检索和记忆相关能力 |
| MinIO | 对象存储组件 |

### 4.2 参考文档

- openJiuwen Agent Studio GitHub：https://github.com/openJiuwen-ai/agent-studio
- openJiuwen Agent Runtime GitHub：https://github.com/openJiuwen-ai/agent-runtime
- 华为云 RFS 文档：https://support.huaweicloud.com/rfs/

## 5. 修订记录

| 日期 | 版本 | 说明 |
|---|---|---|
| 2026-07-10 | v0.1.0 | 首版，提供 cn-north-4 单机标准版部署实践。 |
