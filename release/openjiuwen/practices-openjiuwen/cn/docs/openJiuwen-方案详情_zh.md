# openJiuwen Agent 智能体开发平台 方案详情

## 1. 解决方案概述

openJiuwen Agent Studio 提供一站式 AI Agent 开发平台，覆盖 Agent 开发、测试、工作流编排、模型管理、插件管理和发布运行等环节。本方案将 openJiuwen Agent Studio 封装为华为云 RFS 一键部署实践，帮助用户在华为云 ECS 上快速获得可访问、可调试、可扩展的智能体开发环境。

首版采用单机标准版架构，面向试用、演示和小规模验证场景。方案自动创建云基础设施，并使用 openJiuwen 官方 Docker 部署工具启动前端、后端、Runtime、插件服务、沙箱服务、MySQL、Milvus、Etcd 和 MinIO 等组件。

## 2. 方案优势

| 优势 | 价值 |
|---|---|
| 快速上线 | 从云资源创建到 openJiuwen 服务启动由 RFS 自动完成，减少手工安装和环境配置工作。 |
| 开发闭环 | 支持从 Agent 设计、工作流编排、模型配置到发布运行的完整链路。 |
| 资源集中 | 单机标准版将所有依赖组件部署在同一 ECS，便于验证、演示和问题定位。 |
| 易于扩展 | 后续可扩展为 DeepSearch 知识增强搜索实践或多渠道 Agent 实践。 |

## 3. 架构与部署方式

```text
Huawei Cloud RFS
  |
  v
VPC + Subnet + Security Group + EIP
  |
  v
ECS Ubuntu 24.04
  |
  +-- Docker Compose
      +-- openJiuwen Frontend
      +-- openJiuwen Backend
      +-- Agent Runtime
      +-- Plugin Server
      +-- Sandbox Gateway / Server
      +-- MySQL
      +-- Milvus / Etcd / MinIO
```

部署方式：

- 基础设施：Terraform HCL 模板。
- 应用部署：内联 `user_data` 自动安装 Docker、下载官方部署工具包、生成 `.env.custom` 并启动服务。
- 访问入口：`https://<EIP>:3000`。
- 运维入口：ECS 内 `/opt/openjiuwen/deployTool` 和 `/var/log/openjiuwen-bootstrap.log`。

## 4. 应用场景

| 场景 | 说明 |
|---|---|
| Agent 原型验证 | 通过可视化界面快速构建业务 Agent，缩短从想法到演示的周期。 |
| 企业知识助手开发 | 对接模型和知识能力，构建面向内部员工或客户的智能问答助手。 |
| 工作流编排实验 | 使用拖拽画布编排多步骤任务，验证 Agent 工作流逻辑。 |
| Agent 运行态验证 | 借助 Runtime 将开发态 Agent 发布为运行态服务，并进行健康检查和调用测试。 |

## 5. 相关解决方案

| 方案 | 关系 |
|---|---|
| openJiuwen DeepSearch 企业知识检索助手 | 可作为第二阶段实践，聚焦知识增强搜索和研究型问答。 |
| JiuwenSwarm 多渠道智能体助手 | 可作为第三阶段实践，聚焦飞书、钉钉、Telegram 等渠道接入。 |
| LiteLLM 统一 LLM 网关 | 可作为模型 API 网关，为 openJiuwen 提供统一模型接入层。 |

## 6. 支持区域

首版支持：

| 站点 | Region | 形态 |
|---|---|---|
| 中国站 | cn-north-4（华北-北京四） | 单机标准版 |

后续可按相同架构扩展到国际站 `ap-southeast-1`，并补齐英文和国际站中文文档。

## 7. 预估成本

本方案主要成本来自 ECS、系统盘和 EIP 公网带宽。默认规格为 `x1.8u.16g`、200GB 高IO系统盘、100Mbit/s 按流量计费 EIP。实际费用以华为云控制台为准。

成本优化建议：

- 短期验证使用按需计费，用完后及时删除 RFS 资源栈。
- 长期使用改为包年包月。
- 若只做轻量演示，可在实测确认后降低 ECS 规格和带宽。

## 8. 服务亮点

- 可视化 Agent 和工作流开发。
- 模型、插件、知识和记忆资源统一管理。
- 集成 Runtime，支持从开发态到运行态的发布验证。
- 使用官方 Docker 部署工具，尽量贴近 openJiuwen 推荐部署路径。
- RFS 输出访问地址、健康检查地址、安装目录和日志路径，便于交付验收。
