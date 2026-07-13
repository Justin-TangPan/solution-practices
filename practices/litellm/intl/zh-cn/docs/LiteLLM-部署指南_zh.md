# 快速部署 LiteLLM — 国际站部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 01
> **发布日期：** 2026-07-10
> **适用站点：** intl（国际站）
> **部署形式：** RFS 一键部署 · 标准版 / 高可用版

本文档合并说明 LiteLLM 标准版和高可用版。标准版适合开发、验证和中小规模共享网关；高可用版面向需要多副本、托管数据库与缓存、HTTPS 入口的生产场景。

> **候选状态：** 高可用版 `deploying-litellm_v1.tf` 是尚未完成真实云上部署验证的候选模板。本文档描述其当前实现，不代表模板已经通过云测或正式发布。部署前请先在非生产账号验证目标区域的配额、规格、可用区和 Provider 兼容性。

---

## 1. 方案概述

### 1.1 应用场景

LiteLLM 提供 OpenAI 兼容的统一代理接口，可把多个模型提供商接入集中到同一网关。本实践通过 RFS 模板完成云资源与 LiteLLM 的部署，适用于以下场景：

- **开发与集成验证**：标准版在一台 ECS 上运行 LiteLLM、PostgreSQL 和 Prometheus，便于快速验证模型接入与 API 调用。
- **企业共享模型网关**：高可用版默认使用 3 个 CCE 节点承载 4 个 LiteLLM 副本，并使用 RDS PostgreSQL 16 主备版和 DCS Redis 7.0 高可用实例。
- **统一鉴权与用量管理**：通过 LiteLLM 主密钥、虚拟密钥和数据库持久化统一管理模型访问与用量记录。

### 1.2 方案架构

#### 1.2.1 标准版

```text
Internet
   │
   └── EIP ── ECS / Ubuntu 24.04
                 └── Docker Compose
                     ├── LiteLLM Proxy :4000
                     ├── PostgreSQL 16
                     └── Prometheus :9090
```

标准版创建 1 个 VPC、1 个子网、1 个安全组、1 个按流量计费的 EIP 和 1 台 ECS。LiteLLM 对公网开放 TCP/4000，Prometheus 对公网开放 TCP/9090；SSH 仅允许来自模板指定的 Cloud Shell 地址 `121.36.59.153/32`。

#### 1.2.2 高可用版

```text
Internet
   │ HTTPS/443
   ▼
ELB（双可用区）
   │
CCE Turbo（多可用区，默认 3 节点）
   └── LiteLLM Proxy × 4
       ├── RDS for PostgreSQL 16（主备）
       ├── DCS Redis 7.0（高可用）
       └── 经 NAT 网关访问模型提供商 API
```

高可用版创建：

- 1 个 VPC、4 个子网（公网、私网和 2 个 ENI 子网）及 1 个仅允许 VPC 内部访问的安全组；
- 3 个 EIP，分别用于 ELB 公网入口、CCE 集群访问和 NAT SNAT；
- 1 个跨至少 2 个可用区的 ELB，公网入口强制使用 HTTPS/443；
- 1 个多可用区 CCE Turbo v1.34 集群，节点池默认扩容到 3 个节点、最多 10 个节点；
- 1 个 LiteLLM Kubernetes Deployment，固定 4 个副本，每个副本请求并限制 1 vCPU、4 GiB 内存；
- 1 个 RDS for PostgreSQL 16 主备实例，默认 8 核 16 GiB、100 GB CLOUDSSD；
- 1 个 DCS Redis 7.0 高可用实例，默认 8 GB并启用自动备份；
- 1 个 NAT 网关及 3 条 SNAT 规则，使私网节点和 Pod 网络可以访问外部模型服务。

### 1.3 方案优势

- **同一套交付覆盖两种规模**：一篇指南同时覆盖 1 台 ECS 的标准版和默认 3 节点、4 副本的高可用版。
- **状态服务托管化**：高可用版将 PostgreSQL 和 Redis 分别放在 RDS PostgreSQL 16 主备版与 DCS Redis 7.0 高可用实例中。
- **入口加密**：高可用版只通过 ELB HTTPS/443 暴露服务，必须绑定现有服务器证书，并通过证书覆盖的域名访问。
- **区域一致交付**：中英文模板覆盖 8 个国际站 Region，区域由目录和 Provider 配置明确表达。

### 1.4 约束与限制

- 部署前需完成华为云账号注册与所需权限配置，账号不得欠费或冻结；IAM 用户应使用权限满足资源创建和删除要求的 RFS 委托。
- 高可用版要求目标 Region 至少提供 2 个可用的 category-0 L7 ELB 可用区，并要求所选 RDS、DCS 高可用规格各支持至少 2 个不同可用区。
- 高可用版必须提前在部署 Region 创建 ELB 服务器证书。证书覆盖的域名必须在部署后通过 A 记录指向模板输出的 ELB EIP。
- `litellm_master_key` 和 `litellm_salt_key` 必须使用密码学安全随机数生成；Salt Key 写入数据后不得更换。不得把密钥写入文档、工单或日志。
- 高可用版 LiteLLM 镜像固定为 `docker.litellm.ai/berriai/litellm:1.87.0`；标准版当前使用 `ghcr.io/berriai/litellm:main-stable`，升级风险和版本变化需分别评估。
- 高可用版候选尚未云测。创建生产资源前必须执行 Terraform 语法、RFS 执行计划、真实部署、健康检查、HTTPS 访问与卸载验证。

---

## 2. 资源与成本规划

所有价格随 Region、规格、活动和计费规则变化。下表只列出计费资源，不编写未经价格计算器确认的金额。部署前请在 RFS 执行计划和华为云价格计算器中核算，以实际账单为准。

### 2.1 标准版

#### 表 2-1 标准版资源和成本规划（按需计费）

| 华为云服务 | 当前模板配置 | 数量 | 费用填写规则 |
|---|---|---:|---|
| VPC / 子网 / 安全组 | `172.16.0.0/16`；子网 `172.16.1.0/24` | 各 1 | 以控制台计费规则为准 |
| ECS | Ubuntu 24.04；默认 `c7n.2xlarge.2`；200 GB SSD；`postPaid` | 1 | 部署前查询目标 Region 按需价 |
| EIP / 公网带宽 | 动态 BGP；默认 200 Mbit/s；按流量计费 | 1 | 以实际公网流量账单为准 |
| LiteLLM / PostgreSQL / Prometheus | ECS 内 Docker Compose 容器 | 各 1 | 开源软件本身不在华为云资源账单中 |

#### 表 2-2 标准版资源和成本规划（包年包月）

| 华为云服务 | 当前模板配置 | 数量 | 费用填写规则 |
|---|---|---:|---|
| VPC / 子网 / 安全组 | 与按需模式相同 | 各 1 | 以控制台计费规则为准 |
| ECS | `charging_mode=prePaid`；周期单位 month/year | 1 | 部署前查询目标 Region 包年包月价 |
| EIP / 公网带宽 | 模板中仍为 `postPaid` 且按流量计费 | 1 | 与 ECS 周期费用分开核算 |
| 系统盘 | 默认 200 GB SSD，随 ECS 配置 | 1 | 以资源栈执行计划为准 |

### 2.2 高可用版

#### 表 2-3 高可用版资源和成本规划（按需计费）

| 华为云服务 | 当前模板配置 | 数量 | 费用填写规则 |
|---|---|---:|---|
| VPC / 子网 / 安全组 | 1 个 VPC、4 个子网、1 个安全组 | 1 组 | 以控制台计费规则为准 |
| EIP / 公网带宽 | 默认 300 Mbit/s，按流量计费 | 3 | 以实际公网流量账单为准 |
| ELB | L7 性能型规格查询结果；双可用区；HTTPS/443 | 1 | 查询目标 Region 的按需 ELB 费用 |
| CCE Turbo | v1.34，多可用区；默认 `cce.s2.small` | 1 | 查询 CCE 集群管理费用 |
| CCE 节点池 | 默认 `c7n.2xlarge.2`；100 GB GPSSD；目标 3 节点 | 1 个池 / 3 节点 | 查询节点 ECS 与云硬盘按需价 |
| RDS for PostgreSQL | PostgreSQL 16 主备；默认 8 核 16 GiB；100 GB | 1 | 查询 RDS 按需价 |
| DCS Redis | Redis 7.0 高可用；默认 8 GB | 1 | 查询 DCS 按需价 |
| NAT 网关 | 小型规格；3 条 SNAT 规则共用第 3 个 EIP | 1 | 查询 NAT 网关与流量费用 |

#### 表 2-4 高可用版资源和成本规划（包年包月）

| 华为云服务 | 当前模板配置 | 数量 | 费用填写规则 |
|---|---|---:|---|
| ELB | `prePaid`，周期单位 month/year，HTTPS/443 | 1 | 查询目标 Region 包年包月价 |
| CCE Turbo 与节点池 | 集群 1 个；节点池目标 3 节点 | 1 组 | 分别核算集群、ECS 节点和云硬盘 |
| RDS for PostgreSQL | PostgreSQL 16 主备；100 GB | 1 | 查询 RDS 包年包月价 |
| DCS Redis | Redis 7.0 高可用；默认 8 GB | 1 | 查询 DCS 包年包月价 |
| NAT 网关 | 小型规格 | 1 | 查询 NAT 包年包月价 |
| EIP / 公网流量 | 3 个 EIP；带宽按流量计费 | 3 | 与周期资源费用分开核算 |

> **费用免责声明：** 预估费用仅供规划，实际费用取决于 Region、规格、购买周期、网络流量和优惠活动，最终以华为云实际账单为准。

---

## 3. 实施步骤

### 3.1 准备工作

#### 3.1.1 检查账号、配额和区域能力

1. 登录[华为云国际站控制台](https://console-intl.huaweicloud.com/)。
2. 确认账号状态正常，并核对 VPC、EIP、ELB、CCE、ECS、RDS、DCS 和 NAT 网关配额。
3. 在目标 Region 查询 `c7n.2xlarge.2`、`rds.pg.x1.2xlarge.2.ha`、DCS Redis 7.0 HA 规格以及至少 2 个可用区的可用性；如默认规格不可售，仅修改相应可配置规格参数，不能绕过 HA 可用区前置检查。
4. IAM 用户应按[华为云 RFS IAM 委托文档](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0017.html)创建或选择权限足够的委托。应遵循最小权限原则，不在文档或模板中保存 AK/SK。

#### 3.1.2 准备高可用版证书与域名

1. 准备一个您可以管理 DNS 的域名，以及覆盖该访问域名的有效服务器证书。
2. 在目标 Region 的 ELB 控制台添加服务器证书，记录证书 ID。证书需要在每个部署 Region 单独创建或导入。
3. 证书 ID 必须为 32-36 位十六进制字符或连字符；将其填入 `elb_certificate_id`。
4. 部署完成前不要创建指向未知地址的 DNS 记录。资源栈输出 ELB EIP 后，再为证书覆盖的域名创建 A 记录。

#### 3.1.3 生成高可用版 LiteLLM 密钥

在安全终端执行以下命令，并把结果保存到受控密码管理系统。命令不会把固定密钥写入仓库：

```bash
MASTER_KEY="sk-$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9_-' | head -c 45)"
SALT_KEY="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9_-' | head -c 48)"
printf 'master length=%s\nsalt length=%s\n' "${#MASTER_KEY}" "${#SALT_KEY}"
```

`MASTER_KEY` 总长必须为 32-64 位并以 `sk-` 开头；`SALT_KEY` 必须为 32-64 位。两者只允许字母、数字、下划线和中划线。

### 3.2 快速部署

#### 3.2.1 上线信息

| 形式 | 站点 | 支持 Region |
|---|---|---|
| RFS 一键部署 · 标准版 | intl（国际站） | 下列 8 个 Region |
| RFS 一键部署 · 高可用版候选 | intl（国际站） | 下列 8 个 Region；需逐区云测 |

| Region | 中文名称 | 标准版模板 | 高可用版候选模板 |
|---|---|---|---|
| `ap-southeast-1` | 中国-香港 | `litellm-standard-cn-ap-southeast-1.tf` | `deploying-litellm_v1.tf` |
| `ap-southeast-2` | 亚太-曼谷 | `litellm-standard-cn-ap-southeast-2.tf` | `deploying-litellm_v1.tf` |
| `ap-southeast-3` | 亚太-新加坡 | `litellm-standard-cn-ap-southeast-3.tf` | `deploying-litellm_v1.tf` |
| `af-south-1` | 非洲-约翰内斯堡 | `litellm-standard-cn-af-south-1.tf` | `deploying-litellm_v1.tf` |
| `af-north-1` | 非洲-开罗 | `litellm-standard-cn-af-north-1.tf` | `deploying-litellm_v1.tf` |
| `tr-west-1` | 土耳其-伊斯坦布尔 | `litellm-standard-cn-tr-west-1.tf` | `deploying-litellm_v1.tf` |
| `la-north-2` | 拉美-墨西哥城二 | `litellm-standard-cn-la-north-2.tf` | `deploying-litellm_v1.tf` |
| `sa-brazil-1` | 拉美-圣保罗一 | `litellm-standard-cn-sa-brazil-1.tf` | `deploying-litellm_v1.tf` |

> 当前仓库未提供已发布的生产 OBS 模板 URL，因此本文档不编造“开始部署”深链。请在[RFS 控制台](https://console-intl.huaweicloud.com/rf/)选择目标 Region 后上传对应本地模板。高可用版正式晋级前必须保留 `_v1` 候选文件并完成真实云测。

#### 3.2.2 标准版参数

标准版共 11 个变量：

| 参数 | 默认值 | 说明 |
|---|---|---|
| `solution_name` | `litellm-llm-gateway` | 4-24 位，小写字母开头，仅使用小写字母、数字和中划线 |
| `ecs_flavor` | `c7n.2xlarge.2` | ECS 规格；请按目标 Region 可售规格调整 |
| `ecs_password` | 必填 | ECS root 密码，8-26 位，至少包含四类字符中的三类 |
| `db_password` | 必填 | LiteLLM 内部 PostgreSQL 密码，8-26 位 |
| `master_key` | 必填 | LiteLLM 管理与 API 鉴权主密钥，须以 `sk-` 开头 |
| `salt_key` | 空 | 数据加密 Salt Key；空值由启动脚本生成，使用后不可更换 |
| `system_disk_size` | `200` | SSD 系统盘，40-1024 GB |
| `bandwidth_size` | `200` | EIP 带宽，1-300 Mbit/s，按流量计费 |
| `charging_mode` | `postPaid` | `postPaid` 按需或 `prePaid` 包年包月 |
| `charging_unit` | `month` | `month` 或 `year`，仅 `prePaid` 时生效 |
| `charging_period` | `1` | 按月 1-9，按年 1-3，仅 `prePaid` 时生效 |

#### 3.2.3 高可用版参数

高可用版共 17 个变量：

| 参数 | 默认值 | 说明 |
|---|---|---|
| `resource_name_prefix` | `ha-litellm` | 4-24 位，小写字母开头，仅使用小写字母、数字和中划线 |
| `bandwidth_size` | `300` | 3 个 EIP 的带宽，1-300 Mbit/s，按流量计费 |
| `elb_certificate_id` | 必填 | 现有 ELB 服务器证书 ID，供 HTTPS/443 入口使用 |
| `litellm_version` | `1.87.0` | 固定值；镜像为 `docker.litellm.ai/berriai/litellm:1.87.0` |
| `litellm_master_key` | 必填 | 密码学安全随机主密钥，以 `sk-` 开头，总长 32-64 位 |
| `litellm_salt_key` | 必填 | 密码学安全随机 Salt Key，32-64 位，存储数据后不得更换 |
| `cce_cluster_flavor` | `cce.s2.small` | 可选 `cce.s2.small/medium/large/xlarge` |
| `cce_node_pool_password` | 必填 | 8-24 位，含大写、小写以及数字或允许的特殊字符 |
| `cce_node_pool_flavor` | `c7n.2xlarge.2` | CCE 节点 ECS 规格；默认满足每实例 4 核 8 GiB 以上建议 |
| `cce_node_pool_count` | `3` | 目标节点数 1-9；默认 3，节点池最大 10 |
| `rds_flavor` | `rds.pg.x1.2xlarge.2.ha` | RDS PostgreSQL 主备规格，默认 8 核 16 GiB |
| `pgsql_admin_password` | 必填 | PostgreSQL 管理员密码，8-24 位 |
| `redis_capacity` | `8` | GB；可选 1、2、4、8、16、32、64 |
| `redis_password` | 必填 | Redis 密码，8-24 位 |
| `charging_mode` | `postPaid` | `postPaid` 按需或 `prePaid` 包年包月 |
| `charging_unit` | `month` | `month` 或 `year`，仅 `prePaid` 时生效 |
| `charging_period` | `1` | 按月 1-9，按年 1-3，仅 `prePaid` 时生效 |

#### 3.2.4 创建并部署资源栈

1. 打开[RFS 控制台](https://console-intl.huaweicloud.com/rf/)，切换到表 3-1 中的目标 Region。
2. 创建资源栈并上传该 Region、语言和部署类型对应的 Terraform 文件。不要把其他 Region 的模板交叉上传。
3. 填写表 3-2 或表 3-3 的全部必填参数；高可用版必须填写证书 ID、两项 LiteLLM 密钥以及 CCE、RDS、Redis 密码。
4. 绑定权限足够的 RFS 委托，创建执行计划，检查将新增的资源、规格和费用。
5. 确认执行计划后部署资源栈，并等待资源栈进入成功状态。高可用版候选首次部署应在非生产环境执行并完整保存验证结果。
6. 标准版查看 `access_info` 输出；高可用版查看 `instructions` 输出并记录 ELB EIP。

### 3.3 开始使用

#### 3.3.1 标准版验证

1. 从 RFS 的 `access_info` 输出打开管理界面 URL。标准版 URL 使用 HTTP 和 EIP 的 TCP/4000 端口。
2. 使用部署时输入的 `master_key` 登录管理界面，添加模型及对应提供商 API Key。
3. 使用输出中的健康检查 URL验证 `/health/liveliness` 返回成功。
4. 如需查看监控，使用资源栈 EIP 的 TCP/9090 访问 Prometheus；生产使用前应收紧 4000、9090 的安全组来源范围并配置 TLS 反向代理。

#### 3.3.2 高可用版配置 DNS 与验证 HTTPS

1. 从 RFS `instructions` 输出复制 ELB EIP。
2. 在域名的权威 DNS 服务中，为证书覆盖的访问域名创建 A 记录，记录值设为该 ELB EIP。A 记录规则参见[华为云 DNS 文档](https://support.huaweicloud.com/intl/en-us/usermanual-dns/dns_usermanual_0601.html)。
3. 等待 DNS 生效后，仅通过证书域名的 HTTPS/443 访问 LiteLLM。不要直接使用 EIP 访问 HTTPS，因为证书域名校验会失败。
4. 设置本地环境变量 `LITELLM_BASE_URL` 为实际 HTTPS 域名后执行：

```bash
curl --fail --show-error "${LITELLM_BASE_URL}/health/liveliness"
curl --fail --show-error "${LITELLM_BASE_URL}/health/readiness"
```

5. 使用 `litellm_master_key` 登录管理界面并添加模型。API 路径为 `/v1/chat/completions`，Bearer Token 使用 LiteLLM 主密钥或随后创建的虚拟密钥。
6. 在 CCE 控制台确认 `litellm-proxy` Deployment 有 4 个 Ready 副本，并检查其跨主机、跨可用区调度状态；同时验证 RDS、DCS、ELB、NAT 和所有健康探针正常。

#### 3.3.3 安全检查

- 不在聊天记录、截图、Markdown、Terraform 默认值或日志中保存真实密钥和密码。
- 标准版 4000 和 9090 当前允许公网访问；生产前应限制安全组来源并增加 HTTPS 入口。
- 高可用版外部入口为 HTTPS/443；应用端口 4000 仅在集群内部通过 ClusterIP 使用。
- 定期轮换主密钥、数据库密码和 Redis 密码时，应先评估应用连接与数据影响；LiteLLM Salt Key 在已有加密数据后不得轮换。
- 监控证书到期时间，并在到期前更新 ELB 证书绑定。

### 3.4 故障排查

| 现象 | 检查项 | 处理建议 |
|---|---|---|
| RFS 计划阶段提示周期无效 | `charging_unit` 与 `charging_period` | 按月使用 1-9；按年使用 1-3 |
| 高可用资源创建前置检查失败 | ELB、RDS 或 DCS 可用区数量 | 换用支持至少 2 个可用区的 Region/规格 |
| 4 个 LiteLLM 副本未全部 Ready | CCE 节点数、拓扑约束、镜像拉取、探针 | 确认目标 3 节点已完成扩容，并查看 Pod 事件和日志 |
| HTTPS 证书错误 | 访问地址、证书域名、A 记录 | 使用证书覆盖的域名，不要用 EIP；核对 A 记录指向输出 EIP |
| HTTPS 无法连接 | ELB 证书 ID、Ingress、443 监听器 | 检查证书存在于同一 Region，并查看 CCE Ingress 事件 |
| LiteLLM 数据库或缓存报错 | RDS/DCS 状态、私网连接、密码 | 检查安全组仅 VPC 内访问、连接地址与 Kubernetes Secret |
| 标准版容器未启动 | `/var/log/litellm-bootstrap.log` | 检查 Docker 安装、镜像拉取和 `docker compose` 日志 |

### 3.5 快速卸载

1. 先备份需要保留的 LiteLLM 配置、数据库数据和审计信息。删除资源栈会删除模板管理的资源。
2. 登录 RFS 控制台，选择对应 Region 和资源栈。
3. 先创建删除执行计划并核对影响，再选择删除资源栈及其资源。
4. 按控制台要求输入确认文本并执行删除。
5. 删除后检查 EIP、ELB、CCE 节点、RDS、DCS、NAT、云硬盘和 DNS A 记录是否仍有残留或持续计费。域名与预先导入的 ELB 证书不是模板创建的资源，需按您的保留策略单独处理。

---

## 4. 附录

### 4.1 名词解释

| 术语 | 说明 |
|---|---|
| RFS | Resource Formation Service，基于模板创建和管理资源栈 |
| CCE Turbo | 使用云原生网络 2.0 的托管 Kubernetes 集群类型 |
| ELB | Elastic Load Balance，本方案高可用版的 HTTPS 公网入口 |
| RDS | Relational Database Service，高可用版用于 PostgreSQL 16 持久化 |
| DCS | Distributed Cache Service，高可用版用于 Redis 7.0 缓存与协调 |
| NAT | 为私网子网和 ENI 子网提供 SNAT 出网能力 |
| Salt Key | LiteLLM 用于加密数据库敏感字段的密钥，写入数据后不得更换 |

### 4.2 参考文档

- [LiteLLM Proxy 快速入门](https://docs.litellm.ai/docs/proxy/quick_start)
- [LiteLLM GitHub 仓库](https://github.com/BerriAI/litellm)
- [访问华为云 RFS](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0020.html)
- [华为云 RFS IAM 委托](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0017.html)
- [华为云 CCE 集群概述](https://support.huaweicloud.com/intl/en-us/usermanual-cce/cce_10_0430.html)
- [华为云 ELB 证书说明](https://support.huaweicloud.com/intl/en-us/usermanual-elb/elb_ug_zs_0001.html)
- [华为云 DNS A 记录规则](https://support.huaweicloud.com/intl/en-us/usermanual-dns/dns_usermanual_0601.html)

---

## 5. 修订记录

| 发布日期 | 文档版本 | 修订记录 |
|---|---|---|
| 2026-07-10 | 01 | 合并国际站标准版与高可用版，补充 8 个 Region、17 项 HA 参数、HTTPS/443 证书与 DNS A 记录步骤、双计费模式费用表，并明确 `_v1` 候选未云测。 |
