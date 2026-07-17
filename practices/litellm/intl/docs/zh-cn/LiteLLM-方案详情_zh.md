# LiteLLM 国际站方案详情

> **文档版本：** 01
> **发布日期：** 2026-07-10
> **适用站点：** intl（国际站）
> **部署形式：** RFS 一键部署 · 标准版 / 高可用版

> **状态说明：** 国际站高可用版 `deploying-litellm_v1.tf` 当前是尚未完成真实云上部署验证的候选模板，不能据此宣称已正式发布或已达到特定 SLA。

## 1. 解决方案概述

LiteLLM 是统一 LLM API 网关，可通过 OpenAI 兼容接口接入不同模型提供商，并提供管理界面、主密钥与虚拟密钥、用量记录和请求路由能力。本实践提供两种 RFS 部署方式：

- **标准版**：在 1 台 ECS 上通过 Docker Compose 运行 LiteLLM、PostgreSQL 16 和 Prometheus，适合开发、集成验证与中小规模共享使用。
- **高可用版**：在 CCE Turbo 上运行 4 个 LiteLLM 副本，默认使用 3 个节点，并连接 RDS for PostgreSQL 16 主备实例和 DCS Redis 7.0 高可用实例，通过 ELB HTTPS/443 对外服务。

同一套站点级文档覆盖标准版和高可用版，8 个国际站 Region 均提供中英文模板目录。区域候选仍须逐区完成规格、可用区、RFS Provider 和真实部署验证。

## 2. 方案优势

### 2.1 从单机验证到多副本架构

标准版只创建 1 台 ECS；高可用版默认创建 3 个 CCE 节点并运行 4 个 LiteLLM 副本。团队可根据业务阶段选择资源范围，不需要把开发验证架构描述成生产高可用架构。

### 2.2 状态组件托管化

高可用版使用 RDS PostgreSQL 16 主备实例保存 LiteLLM 数据，使用 DCS Redis 7.0 高可用实例承担缓存与路由协调。模板要求 RDS 与 DCS 规格各支持至少 2 个不同可用区。

### 2.3 HTTPS 单一公网入口

高可用版仅以 ELB HTTPS/443 作为应用公网入口，应用端口 4000 保持为 CCE 集群内 ClusterIP。部署者必须提供现有 ELB 服务器证书 ID，并把证书覆盖域名的 A 记录指向资源栈输出的 ELB EIP。

### 2.4 私网出站与健康治理

CCE 节点、RDS、DCS 位于私网资源范围；NAT 网关与 3 条 SNAT 规则为私网和两个 ENI 子网提供出站能力。LiteLLM Deployment 配置 readiness、liveness、优雅终止和跨可用区/主机拓扑约束。

## 3. 架构与部署方式

### 3.1 标准版架构

```text
Internet → EIP → ECS
                  └── Docker Compose
                      ├── LiteLLM Proxy :4000
                      ├── PostgreSQL 16
                      └── Prometheus :9090
```

| 维度 | 实现 |
|---|---|
| 计算 | 1 台 ECS，默认 `c7n.2xlarge.2`，Ubuntu 24.04 |
| 数据库 | ECS 内 PostgreSQL 16 容器 |
| 监控 | ECS 内 Prometheus 2.53.0 容器 |
| 入口 | EIP 直连 HTTP/4000；Prometheus HTTP/9090 |
| 数据盘 | 默认 200 GB SSD 系统盘承载容器和数据 |
| LiteLLM 版本 | `ghcr.io/berriai/litellm:main-stable`，未固定补丁版本 |
| 故障恢复 | 依赖单台 ECS 和容器重启策略，不具备跨节点高可用 |

### 3.2 高可用版架构

```text
Internet
   │ HTTPS/443
   ▼
ELB（至少 2 个 L7 可用区）
   │
CCE Turbo v1.34（多可用区）
   └── LiteLLM Proxy 1.87.0 × 4
       ├── RDS PostgreSQL 16 HA
       ├── DCS Redis 7.0 HA
       └── NAT → 外部模型服务
```

| 层级 | 实现 |
|---|---|
| 网络 | 1 个 VPC、4 个子网、1 个安全组、3 个 EIP、1 个 NAT 网关 |
| 入口 | 1 个双可用区 ELB，必须绑定服务器证书，仅使用 HTTPS/443 |
| 容器平台 | CCE Turbo v1.34，多可用区，默认 `cce.s2.small` |
| 节点 | 默认目标 3 个 `c7n.2xlarge.2` 节点；节点池范围 1-10 |
| 应用 | LiteLLM 1.87.0，4 个副本，每副本 1 vCPU / 4 GiB |
| 数据库 | RDS for PostgreSQL 16 主备，默认 8 核 16 GiB、100 GB CLOUDSSD |
| 缓存 | DCS Redis 7.0 高可用，默认 8 GB，自动备份保留 3 天 |
| 出站 | 1 个 NAT 网关，3 条 SNAT 规则覆盖私网和 2 个 ENI 子网 |
| 调度与探针 | 可用区与主机拓扑分散、readiness/liveness、120 秒终止宽限期 |

### 3.3 部署方式对比

| 维度 | 标准版 | 高可用版候选 |
|---|---|---|
| RFS 模板 | 每个 Region 一个 `litellm-standard-cn-{region}.tf` | 每个 Region 一个 `deploying-litellm_v1.tf` |
| 应用实例 | 1 个 LiteLLM 容器 | 4 个 Kubernetes 副本 |
| 默认计算节点 | 1 台 ECS | 3 个 CCE 节点 |
| 数据库 | 容器 PostgreSQL 16 | RDS PostgreSQL 16 主备 |
| 缓存 | 未配置 | DCS Redis 7.0 高可用 |
| 公网入口 | EIP + HTTP/4000 | ELB + HTTPS/443 |
| 证书与域名 | 模板未配置 | 必填证书 ID；部署后创建域名 A 记录 |
| 自动伸缩 | 无 | 节点池按需模式启用伸缩能力，范围 1-10 |
| 当前验证状态 | 以现有验证记录为准 | `_v1` 候选尚未云测 |

## 4. 应用场景

### 4.1 开发与 API 兼容性验证

使用标准版快速建立共享 LiteLLM 入口，验证模型配置、OpenAI 兼容 API、主密钥和虚拟密钥流程。该架构只有 1 台 ECS，不应用于需要跨节点容错的生产负载。

### 4.2 企业内部模型网关

使用高可用版把 4 个 LiteLLM 副本分散到默认 3 个 CCE 节点，并把数据库和缓存迁移到托管高可用服务。适合需要统一模型接入、团队密钥和用量记录的内部平台。

### 4.3 多模型路由与故障隔离

LiteLLM 配置启用 Redis 缓存、共享健康检查、预调用检查和重试策略，可在应用层集中管理多个模型端点。实际路由能力与可用性仍取决于所配置的模型提供商、配额和网络连通性。

## 5. 相关解决方案

| 相关能力 | 配合方式 |
|---|---|
| ModelArts MaaS 或其他模型 API | 作为 LiteLLM 上游模型服务，通过管理界面或数据库配置接入 |
| 云监控服务 CES | 监控模板创建的云资源；CCE 工作负载可另行接入日志与指标系统 |
| 云证书管理服务 CCM | 购买或管理高可用版 ELB HTTPS 服务器证书 |
| 域名服务 DNS | 将证书覆盖域名的 A 记录解析到 ELB EIP |

## 6. 支持区域

| Region | 中文名称 | 标准版 | 高可用版候选 |
|---|---|:---:|:---:|
| `ap-southeast-1` | 中国-香港 | 有模板 | 有 `_v1` 候选 |
| `ap-southeast-2` | 亚太-曼谷 | 有模板 | 有 `_v1` 候选 |
| `ap-southeast-3` | 亚太-新加坡 | 有模板 | 有 `_v1` 候选 |
| `af-south-1` | 非洲-约翰内斯堡 | 有模板 | 有 `_v1` 候选 |
| `af-north-1` | 非洲-开罗 | 有模板 | 有 `_v1` 候选 |
| `tr-west-1` | 土耳其-伊斯坦布尔 | 有模板 | 有 `_v1` 候选 |
| `la-north-2` | 拉美-墨西哥城二 | 有模板 | 有 `_v1` 候选 |
| `sa-brazil-1` | 拉美-圣保罗一 | 有模板 | 有 `_v1` 候选 |

“有模板”只表示仓库中存在对应文件，不等于当前账号在该 Region 一定有配额、默认规格一定可售或候选已经云测。高可用版还要求 ELB、RDS 和 DCS 分别满足双可用区前置条件。

## 7. 预估成本

文档不写入未经价格计算器确认的金额。应在目标 Region 通过 RFS 执行计划和华为云价格计算器核算，最终以账单为准。

| 版本 | 按需计费资源 | 包年包月资源 | 额外费用关注点 |
|---|---|---|---|
| 标准版 | ECS；EIP 按流量计费 | ECS 可设 `prePaid` | EIP 在模板中仍为按需流量计费；系统盘随 ECS 核算 |
| 高可用版 | ELB、CCE、节点 ECS/云硬盘、RDS、DCS、NAT；3 个 EIP 流量 | ELB、CCE、节点、RDS、DCS、NAT 可随 `prePaid` 参数购买 | 分别核算集群管理、计算、存储、公网流量和数据库/缓存费用 |

| 购买周期参数 | 允许值 |
|---|---|
| `charging_mode` | `postPaid` 或 `prePaid` |
| `charging_unit` | `month` 或 `year` |
| `charging_period` | 按月 1-9；按年 1-3 |

> **费用免责声明：** 预估费用仅供规划，实际费用取决于 Region、规格、购买周期、网络流量和优惠活动，最终以华为云实际账单为准。

## 8. 服务亮点

| 亮点 | 具体实现 |
|---|---|
| 统一入口 | LiteLLM 提供 OpenAI 兼容 API 和管理界面 |
| 4 副本部署 | 高可用版 Kubernetes Deployment 固定 4 个副本 |
| 默认 3 节点 | CCE 节点池默认目标节点数为 3，最大节点数为 10 |
| 双可用区前置检查 | ELB、RDS 和 DCS 在创建前验证至少 2 个可用区 |
| 托管 PostgreSQL 与 Redis | RDS PostgreSQL 16 主备 + DCS Redis 7.0 HA |
| HTTPS/443 | ELB 绑定现有服务器证书；证书域名 A 记录指向 ELB EIP |
| 密钥约束 | Master Key 以 `sk-` 开头且总长 32-64；Salt Key 长 32-64且不可在已有数据后轮换 |
| 多区域模板 | 国际站中英文实现覆盖 8 个 Region |

## 参考文档

- [LiteLLM Proxy 快速入门](https://docs.litellm.ai/docs/proxy/quick_start)
- [LiteLLM GitHub 仓库](https://github.com/BerriAI/litellm)
- [华为云 RFS 访问说明](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0020.html)
- [华为云 CCE 集群概述](https://support.huaweicloud.com/intl/en-us/usermanual-cce/cce_10_0430.html)
- [华为云 ELB 证书说明](https://support.huaweicloud.com/intl/en-us/usermanual-elb/elb_ug_zs_0001.html)
- [华为云 DNS A 记录规则](https://support.huaweicloud.com/intl/en-us/usermanual-dns/dns_usermanual_0601.html)

## 修订记录

| 发布日期 | 文档版本 | 修订记录 |
|---|---|---|
| 2026-07-10 | 01 | 合并标准版与高可用版，补充 8 个 Region、实际 HA 资源拓扑、双计费模式和未云测候选声明。 |
