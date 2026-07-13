# LiteLLM，统一的 LLM 网关

> **文档类型：** 解决方案实践页面
> **方案版本：** v1.1
> **发布日期：** 2026-07-10
> **站点与区域：** cn（中国站），cn-north-4（华北-北京四）

## 1. 解决方案概述

LiteLLM AI Gateway 为不同大模型服务提供统一 API 入口，并支持虚拟密钥、用量跟踪、预算与速率限制、路由和负载均衡等网关能力。本解决方案实践提供标准版与高可用版候选，两种方式分别由 1 个华为云 RFS 资源栈完成资源创建和生命周期管理。

标准版面向开发验证或小规模共享环境，在 1 台 ECS 上以 Docker Compose 运行 LiteLLM、PostgreSQL 16 和 Prometheus。高可用候选面向生产架构评估，在 CCE Turbo 多可用区集群上默认使用 3 个节点承载 4 个 LiteLLM 副本，状态层使用 RDS for PostgreSQL 16 主备版和 DCS Redis 7.0 高可用实例，公网入口使用 ELB HTTPS/443。

> **状态声明：** 高可用 `deploying-litellm_v1.tf` 是尚未完成云上真实部署验证的候选模板。本文只描述已从代码核对的设计事实，不宣称已部署成功、正式发布或达到任何 SLA。

目标场景：`统一大模型入口 | 团队密钥与用量治理 | 高可用架构评估`

## 2. 方案优势

### 2.1 一套入口管理多模型接入

LiteLLM 将不同 Provider 的模型调用收敛到统一网关，业务可以围绕统一入口管理模型别名、访问密钥和调用策略。实际支持范围与行为以所部署 LiteLLM 版本和官方文档为准。

### 2.2 从单机到高可用的两档架构

标准版以 1 台 ECS 和 3 个容器提供轻量起点；高可用候选以默认 3 个 CCE 节点、4 个 LiteLLM 副本、RDS 主备和 DCS 主备形成明确的扩展基线。两档架构均使用 1 个 RFS 资源栈，便于统一审阅、部署与卸载。

### 2.3 双可用区门禁与安全入口

高可用候选在 ELB、RDS、DCS 创建前检查至少两个不同可用区，并对 LiteLLM Pod 设置跨可用区、跨主机的强制调度约束。公网业务流量仅通过绑定已有服务器证书的 ELB HTTPS/443 进入，部署后还需将证书域名的 DNS A 记录指向 ELB EIP。

### 2.4 状态服务与应用副本解耦

高可用候选使用 RDS for PostgreSQL 16 保存 LiteLLM 状态，并使用 DCS Redis 7.0 提供共享缓存与路由协同；应用 Pod 可由 CCE 重新调度。该设计降低单个 Pod 故障的影响，但不等同于跨 Region 容灾，也不构成零中断或零数据丢失承诺。

## 3. 架构与部署方式

### 3.1 标准版

```text
互联网 → EIP → ECS
                 ├─ LiteLLM Proxy :4000
                 ├─ PostgreSQL 16 :5432
                 └─ Prometheus :9090
```

| 项目 | 实现事实 |
|---|---|
| 部署单元 | 1 个 RFS 资源栈 |
| 计算 | 1 台 ECS，默认 `x1.8u.16g`，Ubuntu 24.04 |
| 应用 | LiteLLM Proxy，模板当前使用可变的 `main-stable` 镜像标签 |
| 数据库 | ECS 内 PostgreSQL 16 容器 |
| 监控 | ECS 内 Prometheus 2.53.0 容器 |
| 公网 | 1 个 EIP；HTTP/4000 与 Prometheus/9090 |
| 数据持久性 | Docker 卷位于 ECS 系统盘；删除系统盘即删除本地数据 |

标准版没有计算或数据层冗余，模板还将 4000/9090 开放到公网。它更适合作为开发验证基础；生产使用前应限制安全组来源、增加 HTTPS，并评估镜像固定版本和备份策略。

### 3.2 高可用版候选

```text
互联网
  │ HTTPS/443
ELB（双 L7 可用区）
  │
CCE Turbo v1.34（多可用区）
  └─ LiteLLM 1.87.0 × 4
       ├─ RDS PostgreSQL 16 主备版
       ├─ DCS Redis 7.0 高可用
       └─ NAT 网关 → 外部大模型服务
```

| 项目 | 实现事实 |
|---|---|
| 部署单元 | 1 个 RFS 资源栈 |
| CCE | Turbo v1.34，`multi_az=true`，默认集群规格 `cce.s2.small` |
| 节点池 | 默认 3 个 `c7n.2xlarge.2` 节点；变量范围 1-9，高可用基线为 3 |
| LiteLLM | 固定 1.87.0，4 个 Pod，每 Pod 请求/限制 1 vCPU、4 GiB |
| 调度 | 可用区和主机两级 `DoNotSchedule` 拓扑分布约束 |
| RDS | PostgreSQL 16 主备、异步复制、默认 8U16G 独享型、100 GB CLOUDSSD |
| DCS | Redis 7.0 高可用、默认 8 GB、自动备份策略 |
| ELB | L7 性能型、两个可用区、已有服务器证书、HTTPS/443 |
| NAT | 规格 1，对私网及 2 个 ENI 子网配置 3 条 SNAT 规则 |
| EIP | 3 个：ELB 入口、CCE 集群访问、NAT 出站 |
| 可用区门禁 | ELB、RDS、DCS 均要求返回至少两个不同可用区 |

高可用部署必须提供 `elb_certificate_id`，并在部署后为证书覆盖的实际域名添加指向 ELB EIP 的 DNS A 记录。LiteLLM 主密钥须以 `sk-` 开头、总长 32-64 位；Salt Key 须为 32-64 位，且写入数据后不得轮换。包年包月周期按月为 1-9、按年为 1-3。

### 3.3 部署方式对比

| 维度 | 标准版 | 高可用版候选 |
|---|---|---|
| RFS 资源栈 | 1 个 | 1 个 |
| 应用副本 | 1 个 LiteLLM 容器 | 4 个 LiteLLM Pod |
| 计算节点 | 1 台 ECS | 默认 3 个 CCE 节点 |
| 数据库 | 本机 PostgreSQL 16 | RDS PostgreSQL 16 主备 |
| 缓存 | 无独立 Redis | DCS Redis 7.0 高可用 |
| 公网入口 | EIP + HTTP/4000 | ELB + HTTPS/443 |
| 可用区设计 | 单实例 | ELB/RDS/DCS 双 AZ 门禁，CCE 多 AZ |
| 适合阶段 | 开发、验证、小规模共享 | 生产架构候选评估；云测后方可晋级 |

## 4. 应用场景

### 4.1 开发团队共享网关

团队可用标准版建立统一的模型接入与验证环境，以 1 个资源栈管理基础设施，并使用 LiteLLM 虚拟密钥区分调用主体。标准版不具备高可用能力，关键数据应另行备份。

### 4.2 多团队模型访问治理

平台团队可围绕 LiteLLM 的虚拟密钥、预算、速率限制与用量跟踪能力规划团队级访问策略。相关能力需在部署后结合实际 Provider、模型和组织权限进行配置与验证。

### 4.3 高可用架构验证

需要评估生产架构的团队可基于高可用候选验证 4 副本调度、RDS/DCS 主备、ELB HTTPS 入口和 NAT 出站。验证应包括端到端模型调用、Pod/节点故障、数据库或缓存切换、DNS 与证书、备份恢复及资源栈删除，不得仅以静态检查代替云测。

## 5. 相关解决方案与服务

| 服务或能力 | 与本方案的关系 | 官方资料 |
|---|---|---|
| 华为云 RFS | 以 Terraform 管理单个方案资源栈 | [RFS 创建资源栈](https://support.huaweicloud.com/intl/zh-cn/usermanual-aos/rf_04_0003.html) |
| 华为云 CCE | 承载高可用候选的 4 个 LiteLLM Pod | [CCE 文档](https://support.huaweicloud.com/cce/) |
| RDS for PostgreSQL | 提供高可用候选的主备数据库 | [主备版说明](https://support.huaweicloud.com/productdesc-rds-pg/rds_01_0036.html) |
| DCS Redis | 提供高可用候选的共享缓存 | [Redis 主备实例](https://support.huaweicloud.com/productdesc-dcs/CacheMasterSlave.html) |
| ELB | 提供 HTTPS/443 公网入口 | [ELB 文档](https://support.huaweicloud.com/elb/) |
| 公网 NAT 网关 | 为私网工作负载提供出站路径 | [NAT 网关文档](https://support.huaweicloud.com/natgateway/) |
| 云解析服务 DNS | 配置证书域名到 ELB EIP 的 A 记录 | [添加公网解析记录](https://support.huaweicloud.com/usermanual-dns/dns_usermanual_0006.html) |

## 6. 支持区域

| 站点 | Region | 标准版 | 高可用版 |
|---|---|---|---|
| cn（中国站） | cn-north-4（华北-北京四） | 现有模板 | `_v1` 未云测候选 |

上线信息：

```text
形式：RFS 一键部署 · 标准版
站点：cn（中国站）
Region：cn-north-4（华北-北京四）

形式：RFS 一键部署 · 高可用版候选（尚未云测）
站点：cn（中国站）
Region：cn-north-4（华北-北京四）
```

## 7. 预估成本

方案同时支持 `postPaid`（按需）和 `prePaid`（包年包月）。本文不提供固定金额，避免将随时间、规格、折扣和流量变化的价格写成承诺；请使用 RFS 执行计划与[华为云价格计算器](https://www.huaweicloud.com/pricing/)取得部署时的实时估算。

### 7.1 按需计费范围

| 版本 | 主要计费资源 | 需单独关注 |
|---|---|---|
| 标准版 | 1 台 ECS、200 GB 系统盘、1 个 EIP | EIP 模板固定按需且带宽按流量；大模型调用费不包含在内 |
| 高可用候选 | 1 个 CCE 集群、默认 3 节点、1 个 RDS、1 个 DCS、1 个 ELB、1 个 NAT、3 个 EIP | 公网流量、数据库存储/备份、各服务规格与大模型调用费 |

### 7.2 包年包月范围

| 版本 | 主要订购资源 | 周期与例外 |
|---|---|---|
| 标准版 | ECS 及随实例订购的系统盘 | 周期单位月/年；业务期望月 1-9、年 1-3。EIP 仍按需、按流量 |
| 高可用候选 | CCE 集群和节点、RDS、DCS、ELB、NAT | 月 1-9、年 1-3；3 个 EIP 仍按流量核对 |

> **费用声明：** 预估费用仅供参考，实际费用取决于具体使用情况，最终以华为云账单为准。域名、已有证书和各大模型 Provider 的费用不包含在模板资源估算中。

## 8. 服务亮点与使用边界

- **统一运维入口：** 通过 1 个 RFS 资源栈管理所选架构的创建与删除。
- **明确可验证：** 高可用候选公开 3 节点、4 副本、双可用区门禁和 HTTPS/443 等可检查事实。
- **凭据边界清晰：** 主密钥、Salt Key、数据库密码、Redis 密码与 Provider API Key 均由客户控制，不应进入代码或日志。
- **状态透明：** `_v1` 仍是候选，只有云上部署、接口、故障恢复、安全和删除门禁全部验证后才能晋级正式入口。
- **官方参考：** [LiteLLM AI Gateway](https://docs.litellm.ai/docs/simple_proxy)、[虚拟密钥](https://docs.litellm.ai/docs/proxy/virtual_keys)、[路由与负载均衡](https://docs.litellm.ai/docs/routing-load-balancing)。

## 9. 修订记录

| 发布日期 | 修订记录 |
|---|---|
| 2026-07-10 | 将原英文方案详情改为中文；合并标准版与高可用候选，补充 1 栈、3 节点、4 副本、双 AZ 门禁、HTTPS/DNS、计费与未云测边界。 |
