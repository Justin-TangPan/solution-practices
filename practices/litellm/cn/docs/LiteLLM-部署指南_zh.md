# LiteLLM，统一的 LLM 网关——部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 1.1
> **发布日期：** 2026-07-10
> **适用站点：** cn（中国站）
> **适用区域：** cn-north-4（华北-北京四）

本文档合并说明 LiteLLM 标准版与高可用版。标准版依据现有
`litellm-standard-cn-north-4.tf`；高可用版依据
`deploying-litellm_v1.tf` 候选模板。高可用候选尚未取得云上真实部署验证证据，不能据此认定已发布、部署成功或达到任何 SLA；正式使用前必须完成云上验证与发布门禁。

## 1. 方案概述

LiteLLM AI Gateway 将多种大模型服务统一到一套 API 入口，并提供虚拟密钥、用量跟踪、路由与负载均衡等网关能力。本方案使用华为云资源编排服务 RFS，通过 1 个资源栈创建所选版本的基础设施与 LiteLLM 运行环境。

### 1.1 应用场景

- **开发与验证环境：** 使用标准版在 1 台 ECS 上运行 LiteLLM、PostgreSQL 与 Prometheus，快速建立共享网关。
- **生产候选架构评估：** 使用高可用候选在 CCE Turbo 上运行 4 个 LiteLLM 副本，并使用托管数据库与缓存服务。
- **多团队统一接入：** 通过 LiteLLM 的虚拟密钥、模型访问控制和用量跟踪能力，为不同团队提供统一入口。

### 1.2 方案架构

#### 1.2.1 标准版

```text
互联网
  │
EIP
  │
ECS（Ubuntu 24.04，Docker Compose）
  ├─ LiteLLM Proxy :4000
  ├─ PostgreSQL 16 :5432
  └─ Prometheus :9090
```

标准版在 1 个 RFS 资源栈中创建 1 个 VPC、1 个子网、1 个安全组、1 个 EIP 和 1 台 ECS。ECS 上由 Docker Compose 运行 3 个容器；PostgreSQL 数据与 Prometheus 数据保存在 ECS 系统盘上的 Docker 卷中。

模板将 TCP 4000 和 9090 开放到公网，SSH 22 仅允许模板指定的 Cloud Shell 地址访问。标准版输出 HTTP 地址，不包含 TLS 终止，生产使用前应限制安全组来源并增加 HTTPS 入口。

#### 1.2.2 高可用版候选

```text
互联网
  │ HTTPS/443
ELB（两个 L7 可用区，绑定已有服务器证书）
  │
CCE Turbo v1.34（多可用区，默认 3 个节点）
  └─ LiteLLM Proxy × 4（跨可用区、跨主机拓扑门禁）
       ├─ RDS for PostgreSQL 16 主备版（两个可用区）
       ├─ DCS Redis 7.0 主备版（两个可用区）
       └─ NAT 网关 + SNAT → 大模型服务 API
```

高可用候选默认创建 CCE Turbo 多可用区集群、3 节点的节点池和 4 个 LiteLLM Pod；Pod 同时设置可用区与主机级 `DoNotSchedule` 拓扑分布约束。数据层使用 RDS for PostgreSQL 16 主备实例（异步复制、100 GB CLOUDSSD）与 DCS Redis 7.0 高可用实例（默认 8 GB）。公网入口为 ELB HTTPS/443，私网出站通过 NAT 网关；模板共创建 3 个 EIP，分别用于 ELB 公网入口、CCE 集群访问与 NAT 出站。

模板在创建前检查 ELB、RDS 与 DCS 对应规格至少提供两个不同可用区。该“双可用区门禁”是模板条件校验，不等同于跨 Region 容灾，也不构成可用性承诺。

### 1.3 方案优势

- **单栈交付：** 每种部署方式均由 1 个 RFS 资源栈管理，便于审阅执行计划、部署和统一删除。
- **明确的高可用基线：** 高可用候选默认 3 个 CCE 节点、4 个 LiteLLM 副本，并对 ELB、RDS、DCS 设置双可用区门禁。
- **托管状态层：** 高可用候选将 PostgreSQL 与 Redis 从应用节点分离到 RDS 和 DCS，降低单个应用 Pod 故障对状态数据的影响。
- **安全公网入口：** 高可用候选只通过 ELB HTTPS/443 提供业务入口，证书由您预先创建并显式传入。

### 1.4 约束与限制

- 高可用 `deploying-litellm_v1.tf` 是未云测候选模板；文档中的架构事实来自静态实现核对，不代表实际创建成功。
- 两个版本均固定部署到 `cn-north-4`。部署前须确认账号状态、服务权限、资源配额与目标规格在该区域可售。
- 标准版是单 ECS 架构，没有计算、数据库或缓存高可用；删除 ECS/资源栈会删除系统盘及其本地数据。
- 高可用版要求已有 ELB 服务器证书及其覆盖的域名。部署后还必须将该域名的 DNS A 记录指向模板输出提示中的 ELB EIP。
- 高可用版的 `litellm_salt_key` 用于数据库敏感数据加密，一旦写入数据不得更改；主密钥、Salt Key、数据库和 Redis 密码不得写入代码、文档或日志。
- 大模型服务的账号、API Key 和调用费用不由本模板创建或承担；请在部署后按所选 Provider 的官方方式配置。

### 1.5 上线信息

```text
形式：RFS 一键部署 · 标准版
站点：cn（中国站）
Region：cn-north-4（华北-北京四）

形式：RFS 一键部署 · 高可用版候选（尚未云测）
站点：cn（中国站）
Region：cn-north-4（华北-北京四）
```

## 2. 资源与成本规划

以下表格不填写固定价格。云服务价格会随区域、规格、计费方式、购买时长、折扣和流量变化；请在部署前使用 RFS 执行计划和华为云价格计算器取得当前估算，并以实际账单为准。所有表格均不包含大模型 Provider 调用费、域名或已有证书的可能费用。

### 2.1 标准版——按需计费

| 资源 | 模板配置 | 数量 | 计费核对方式 |
|---|---|---:|---|
| VPC、子网、安全组 | `172.16.0.0/16`，1 个业务子网 | 各 1 | 在执行计划中核对是否产生独立费用 |
| ECS | `x1.8u.16g`，Ubuntu 24.04 | 1 | 按需实例时长 |
| ECS 系统盘 | SSD，默认 200 GB | 1 | 按容量与使用时长 |
| EIP 与公网带宽 | 动态 BGP，默认 200 Mbit/s，按流量 | 1 | 公网流量及相关 EIP 费用 |

### 2.2 标准版——包年包月

| 资源 | 模板配置 | 数量 | 计费核对方式 |
|---|---|---:|---|
| ECS 与系统盘 | `charging_mode=prePaid`；购买周期由 `charging_unit`、`charging_period` 指定 | 1 | 在订单和执行计划中核对订购费用 |
| EIP 与公网带宽 | 模板固定 EIP 为 `postPaid`、按流量；不随 ECS 改为包年包月 | 1 | 按实际公网流量核对 |
| VPC、子网、安全组 | 与按需部署相同 | 各 1 | 在执行计划中核对 |

### 2.3 高可用版——按需计费

| 资源 | 模板配置 | 数量 | 计费核对方式 |
|---|---|---:|---|
| VPC、子网、安全组 | `192.168.0.0/16`；公网、私网及 2 个 ENI 子网 | 1 / 4 / 1 | 在执行计划中核对 |
| CCE Turbo 集群 | v1.34，`cce.s2.small`，多可用区 | 1 | 集群管理规格与使用时长 |
| CCE 节点 | `c7n.2xlarge.2`，Ubuntu 24.04，100 GB GPSSD | 默认 3 | 节点规格、磁盘与使用时长 |
| LiteLLM 工作负载 | 镜像 `1.87.0`，每 Pod 请求/限制 1 vCPU、4 GiB | 4 副本 | 复用 CCE 节点容量，不单列软件价格 |
| RDS for PostgreSQL | 16 主备版，默认 8U16G 独享型，100 GB CLOUDSSD | 1 | 实例规格、存储、备份与使用时长 |
| DCS Redis | 7.0 高可用，默认 8 GB | 1 | 实例容量与使用时长 |
| ELB | L7 性能型，两个可用区，HTTPS/443 | 1 | 实例规格与使用时长 |
| NAT 网关 | 规格 1，3 条 SNAT 规则 | 1 | 网关与连接/流量相关费用 |
| EIP 与公网带宽 | 默认 300 Mbit/s，按流量 | 3 | EIP 及实际公网流量 |

### 2.4 高可用版——包年包月

| 资源 | 模板配置 | 数量 | 计费核对方式 |
|---|---|---:|---|
| CCE 集群与节点 | `charging_mode=prePaid`；默认 3 节点 | 1 / 3 | 按购买周期核对订单 |
| RDS、DCS、ELB、NAT | 模板传入相同的包年包月周期 | 各 1 | 分服务核对可售规格与订购费用 |
| EIP 与公网带宽 | 模板未设置包年包月，带宽按流量 | 3 | 按实际公网流量核对 |
| VPC、4 个子网、安全组 | 与按需部署相同 | 1 / 4 / 1 | 在执行计划中核对 |

> **费用声明：** 预估费用仅供参考，实际费用取决于所选规格、计费模式、折扣与实际用量，最终以华为云账单为准。请使用[华为云价格计算器](https://www.huaweicloud.com/pricing/)获取实时估算。

## 3. 实施步骤

### 3.1 准备工作

1. 注册并实名认证华为云账号，确认账户无欠费或冻结。
2. 确认在华北-北京四具备 RFS、VPC、EIP、ECS 等资源权限。高可用版还需 CCE、RDS、DCS、ELB、NAT 与 Kubernetes Provider 所需权限。
3. 为 RFS 配置专用 IAM 权限委托，并按实际资源采用最小权限。RFS 官方创建资源栈说明见[创建资源栈](https://support.huaweicloud.com/intl/zh-cn/usermanual-aos/rf_04_0003.html)。
4. 核对配额。高可用版至少需 1 个 CCE 集群、默认 3 个节点、1 个 RDS 主备实例、1 个 DCS 主备实例、1 个 ELB、1 个 NAT 网关和 3 个 EIP。
5. 选择模板：标准版使用 `cn-north-4/standard/terraform/litellm-standard-cn-north-4.tf`；高可用候选使用 `cn-north-4/ha/terraform/deploying-litellm_v1.tf`。
6. 高可用版提前创建 ELB 服务器证书，准备证书 ID 与证书覆盖的公网域名，并确保可以管理该域名的 DNS A 记录。
7. 使用密码学安全随机数生成器准备所有密钥。下面的命令只在本地终端生成值，不要把输出粘贴到文档、工单或日志：

   ```bash
   printf 'sk-'; openssl rand -hex 16
   openssl rand -hex 32
   ```

   第一行结果可满足高可用主密钥“以 `sk-` 开头、总长 32-64 位”的要求；第二行生成 64 位十六进制 Salt Key。请分别保存到受控的凭据管理系统。

### 3.2 标准版快速部署

1. 登录华为云控制台，进入“资源编排服务 RFS > 资源栈 > 创建资源栈”。
2. 选择上传本地 `.tf` 文件并上传标准版模板。
3. 填写下表全部 11 个变量。表中默认值以实际 Terraform 为准。

| 参数 | 默认值 | 说明 |
|---|---|---|
| `solution_name` | `litellm-llm-gateway` | 资源名称前缀；扩展配置期望 4-24 位、小写字母开头，仅含小写字母、数字和中划线 |
| `ecs_flavor` | `x1.8u.16g` | Flexus X 实例规格；模板校验 `x1.{U}u.{G}g` 格式 |
| `ecs_password` | 无 | ECS root 密码；描述要求 8-26 位并包含四类字符中的至少三类 |
| `db_password` | 无 | 容器 PostgreSQL 密码；描述要求 8-26 位 |
| `master_key` | 无 | LiteLLM 管理密钥；须以 `sk-` 开头 |
| `salt_key` | 空 | 留空由启动脚本生成；一旦存储模型凭据后不得更改 |
| `system_disk_size` | `200` | 系统盘 GB，范围 40-1024 |
| `bandwidth_size` | `200` | EIP 带宽 Mbit/s，范围 1-300，按流量计费 |
| `charging_mode` | `postPaid` | `postPaid` 按需或 `prePaid` 包年包月 |
| `charging_unit` | `month` | 包年包月周期单位：`month` 或 `year` |
| `charging_period` | `1` | 购买周期；业务期望按月 1-9、按年 1-3。当前模板只统一校验 1-9，选择年付时请人工限制为 1-3 |

4. 选择权限委托，检查高级配置与删除保护设置。
5. 建议先创建执行计划，审阅将创建的资源和实时费用估算，再部署资源栈。
6. 资源栈显示部署完成后，查看输出 `access_info`。等待 ECS 启动脚本完成，再使用输出中的 Admin UI、API、健康检查和 Prometheus 地址。

### 3.3 高可用版候选快速部署

1. 按 3.2 的方式创建新的 RFS 资源栈并上传 `deploying-litellm_v1.tf`。不要将该候选误命名或视为无版本正式入口。
2. 填写下表全部 17 个变量。

| 参数 | 默认值 | 说明 |
|---|---|---|
| `resource_name_prefix` | `ha-litellm` | 4-24 位，小写字母开头，仅含小写字母、数字和中划线 |
| `bandwidth_size` | `300` | 3 个 EIP 的带宽，整数 1-300 Mbit/s，按流量计费 |
| `elb_certificate_id` | 无 | **必填**；已有 ELB 服务器证书 ID，32-36 位十六进制或中划线，用于 HTTPS/443 |
| `litellm_version` | `1.87.0` | 仅允许 `1.87.0`，对应官方 LiteLLM Proxy 镜像 |
| `litellm_master_key` | 无 | **必填敏感值**；以 `sk-` 开头，总长 32-64，仅含字母、数字、下划线或中划线 |
| `litellm_salt_key` | 无 | **必填敏感值**；32-64 位，仅含字母、数字、下划线或中划线；使用后不得轮换 |
| `cce_cluster_flavor` | `cce.s2.small` | CCE Turbo 集群规格；可选 `cce.s2.small`、`cce.s2.medium`、`cce.s2.large`、`cce.s2.xlarge` |
| `cce_node_pool_password` | 无 | **必填敏感值**；8-24 位，须含大写、小写以及数字或允许的特殊字符 |
| `cce_node_pool_flavor` | `c7n.2xlarge.2` | CCE 节点 ECS 规格 |
| `cce_node_pool_count` | `3` | 期望节点数，整数 1-9；高可用基线使用默认 3 |
| `rds_flavor` | `rds.pg.x1.2xlarge.2.ha` | RDS for PostgreSQL 主备实例规格，默认 8U16G 独享型 |
| `pgsql_admin_password` | 无 | **必填敏感值**；8-24 位，规则同节点密码 |
| `redis_capacity` | `8` | DCS Redis 容量 GB，可选 1、2、4、8、16、32、64 |
| `redis_password` | 无 | **必填敏感值**；8-24 位，规则同节点密码 |
| `charging_mode` | `postPaid` | `postPaid` 按需或 `prePaid` 包年包月 |
| `charging_unit` | `month` | `month` 或 `year`，仅 `prePaid` 生效 |
| `charging_period` | `1` | `month` 时 1-9，`year` 时 1-3；模板在资源生命周期前置条件中校验 |

3. 建议先创建执行计划。重点确认目标规格可售、ELB/RDS/DCS 各自能返回至少两个不同可用区，以及周期和费用符合预期。
4. 部署资源栈并观察事件。由于该候选尚未云测，任何 `Apply` 成功与否都应保留完整的脱敏验证记录，不能仅凭静态检查判定成功。
5. 部署完成后查看输出 `instructions`，取得 ELB EIP 提示。
6. 在 DNS 服务中为证书覆盖的域名添加 A 记录，记录值指向该 ELB EIP。操作方式见[添加公网域名解析记录](https://support.huaweicloud.com/usermanual-dns/dns_usermanual_0006.html)。
7. 等待 DNS 生效后，仅通过证书覆盖的域名和 HTTPS 访问。不要使用 ELB EIP 绕过证书域名校验。

### 3.4 开始使用与验证

#### 3.4.1 标准版

从 RFS 输出 `access_info` 复制实际地址并设置本地变量：

```bash
export LITELLM_URL='从 access_info 复制 API 根地址'
export LITELLM_MASTER_KEY='从凭据系统读取主密钥'
curl --fail --silent --show-error "$LITELLM_URL/health/liveliness"
```

通过输出中的 Admin UI 地址登录，添加实际 Provider 与模型配置；随后使用实际模型别名调用：

```bash
curl --fail --silent --show-error "$LITELLM_URL/v1/chat/completions" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"已在管理界面配置的模型别名","messages":[{"role":"user","content":"健康检查"}]}'
```

#### 3.4.2 高可用版候选

将已完成 DNS A 记录与证书校验的实际 HTTPS 根地址保存为 `LITELLM_URL`，依次验证：

```bash
export LITELLM_URL='使用证书覆盖域名的实际 HTTPS 根地址'
export LITELLM_MASTER_KEY='从凭据系统读取主密钥'
curl --fail --silent --show-error "$LITELLM_URL/health/readiness"
curl --fail --silent --show-error "$LITELLM_URL/v1/models" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY"
```

同时在 CCE 控制台核对 LiteLLM Deployment 期望/就绪副本均为 4，Pod 分布在不同主机并满足可用区约束；核对 RDS、DCS、ELB 与 NAT 状态正常。只有完成端到端模型调用、故障与恢复验证后，才能形成云测结论。

### 3.5 故障排查

| 现象 | 核对项 |
|---|---|
| 标准版资源栈完成但接口不可用 | 查看 `/var/log/litellm-bootstrap.log`、`docker compose ps` 与 `/opt/litellm` 下的容器日志；确认 4000/9090 安全组来源符合访问端 |
| HA 提示证书 ID 无效 | 确认传入 ELB **服务器证书** ID，格式为 32-36 位，并确认该证书与目标域名匹配 |
| HA 在 ELB/RDS/DCS 前置条件失败 | 目标区域或所选规格没有返回至少两个可用区；更换可售规格，不能绕过双 AZ 门禁 |
| HA 的 4 个 Pod 长时间 Pending | 检查默认 3 个节点是否 Ready、节点可用区分布及 CPU/内存容量；拓扑约束设置为 `DoNotSchedule` |
| HA Pod 无法拉取镜像或访问 Provider | 检查 NAT 网关、3 条 SNAT 规则、EIP、DNS 与出站网络策略 |
| HTTPS 证书错误 | 确认使用证书覆盖的域名而非 EIP，并检查 DNS A 记录是否指向 ELB EIP |
| `charging_period` 校验失败 | 月付仅用 1-9，年付仅用 1-3；标准版年付还需人工遵守 1-3 |

### 3.6 快速卸载

1. 备份仍需保留的模型配置、虚拟密钥、用量记录与数据库数据，并验证备份可恢复。
2. 登录 RFS 资源栈列表，选择目标资源栈并执行删除资源操作。
3. 按控制台提示确认删除，持续观察资源事件直至删除完成。
4. 在 VPC、EIP、CCE、RDS、DCS、ELB、NAT 和 DNS 控制台复核是否仍有资源或解析记录需要处理，避免遗留费用或错误入口。

> 标准版 PostgreSQL 与 Prometheus 数据位于 ECS 系统盘；模板设置随 ECS 删除磁盘。高可用版的 RDS/DCS 也由同一资源栈管理。删除前必须自行完成数据保留策略，不能把自动备份等同于删除后的可恢复保证。

## 4. 附录

### 4.1 名词解释

| 术语 | 说明 |
|---|---|
| RFS | 资源编排服务，通过 Terraform 模板管理云资源栈生命周期 |
| CCE Turbo | 华为云云容器引擎的云原生网络集群类型 |
| RDS | 托管关系型数据库服务；本候选使用 PostgreSQL 16 主备版 |
| DCS | 分布式缓存服务；本候选使用 Redis 7.0 高可用实例 |
| ELB | 弹性负载均衡；本候选作为 HTTPS/443 公网入口 |
| NAT | 公网 NAT 网关；本候选用于私网节点和容器访问外部 Provider |
| 可用区 | 同一区域内电力和网络相对隔离的物理区域 |

### 4.2 参考文档

- [LiteLLM AI Gateway 官方文档](https://docs.litellm.ai/docs/simple_proxy)
- [LiteLLM 虚拟密钥官方文档](https://docs.litellm.ai/docs/proxy/virtual_keys)
- [LiteLLM 路由与负载均衡官方文档](https://docs.litellm.ai/docs/routing-load-balancing)
- [华为云 RFS 创建资源栈](https://support.huaweicloud.com/intl/zh-cn/usermanual-aos/rf_04_0003.html)
- [华为云 CCE 文档](https://support.huaweicloud.com/cce/)
- [RDS for PostgreSQL 主备版](https://support.huaweicloud.com/productdesc-rds-pg/rds_01_0036.html)
- [DCS Redis 主备实例](https://support.huaweicloud.com/productdesc-dcs/CacheMasterSlave.html)
- [华为云 ELB 文档](https://support.huaweicloud.com/elb/)
- [华为云公网 NAT 网关文档](https://support.huaweicloud.com/natgateway/)
- [华为云 DNS 添加公网域名解析记录](https://support.huaweicloud.com/usermanual-dns/dns_usermanual_0006.html)
- [华为云价格计算器](https://www.huaweicloud.com/pricing/)

## 5. 修订记录

| 发布日期 | 修订记录 |
|---|---|
| 2026-07-10 | 合并标准版与高可用版；按实际模板补齐 11/17 个变量、双计费方式、HTTPS/DNS 步骤及未云测候选声明。 |
