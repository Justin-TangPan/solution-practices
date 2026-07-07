# 部署 Supabase — 开源 Firebase 替代 部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 01
> **发布日期：** 2026-06-26

---

## 1. 方案概述

### 1.1 应用场景

本方案在华为云 Flexus X 实例上通过 Docker Compose 一键部署 Supabase — 开源的 Firebase 替代品（GitHub 103k+ Stars）。提供托管 PostgreSQL 数据库、用户认证、自动生成 REST/GraphQL API、实时数据订阅、文件存储等完整后端服务。

典型应用场景包括：

- **快速搭建后端服务** — 为移动/Web 应用提供数据库 + API + 认证的完整后端基础设施
- **AI 应用开发** — 利用 pgvector 向量搜索扩展，构建 RAG 和语义搜索应用
- **实时数据应用** — 通过 WebSocket 实时订阅数据库变更
- **企业内部应用平台** — 自建后端即服务（BaaS）平台，数据完全自主可控

### 1.2 方案架构

#### 单机部署

图 1-1 单机部署架构图

本方案部署以下资源：

- 1 x 华为云 Flexus X 实例（推荐 8vCPUs 16GiB），运行约 10 个 Docker 容器
- 1 x 弹性公网 IP（EIP）关联至 ECS，提供公网 Dashboard 和 API 访问
- 1 x VPC 和子网，用于网络隔离

#### 组件架构

```
Kong (API Gateway) ← 统一入口 :8000
├── GoTrue (认证服务)
├── PostgREST (REST API)
├── Realtime (WebSocket 实时订阅)
├── Storage (文件存储)
├── imgproxy (图片处理)
├── postgres-meta (数据库管理 API)
├── Studio (Web 管理面板)
└── PostgreSQL 15 + Supavisor (连接池)
```

#### 数据流

1. 开发者/应用通过 Kong API 网关（端口 8000）访问 Supabase 服务
2. 认证请求由 GoTrue 处理，生成 JWT Token
3. 数据请求通过 PostgREST 自动转换为 PostgreSQL 查询
4. 实时订阅通过 WebSocket 推送数据库变更
5. 文件存储通过 Storage 服务持久化到本地卷

### 1.3 方案优势

- **103k+ Stars 开源项目** — Apache-2.0 协议，社区活跃，持续更新
- **Docker Compose 一键部署** — 约 10 个容器自动编排，10-15 分钟完成部署
- **统一镜像站加速** — 镜像统一经 `docker.wangzhou3.top` 拉取，国内 ECS 稳定快速
- **内置 PostgreSQL 扩展** — pgvector 向量搜索、pgjwt 认证、PostGIS 地理空间等
- **完整后端能力** — 数据库 + REST API + GraphQL + 认证 + 实时订阅 + 文件存储 + Dashboard
- **自动重试机制** — 5 次重试保障镜像拉取成功率

### 1.4 约束与限制

- 部署前需拥有华为云账号并完成实名认证，账户余额充足。
- 若选择包年包月计费，请确保账户余额足够自动扣费，或前往"费用中心 > 待支付订单"手动支付。
- 部署完成后请等待约 10-15 分钟，让 Docker 镜像拉取和容器启动完成。
- 推荐实例规格为 x1.8u.16g（8vCPUs 16GiB）及以上，以支撑约 10 个容器同时运行。
- 系统盘建议 100GB 起步，用于存储 Docker 镜像和数据库数据。
- 首次部署后请立即修改默认的 JWT 密钥和数据库密码。

---

## 2. 资源和成本规划

> 本方案将部署如下资源，费用仅供参考，实际费用请以华为云官网价格为准。

### 2.1 单机部署

#### 表 2-1 成本预估（按需计费）

| 华为云服务 | 配置 | 数量 | 预估费用（1小时） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：按需计费<br>区域：华北-北京四<br>规格：x1.8u.16g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 100GB | 1 | 约 0.20 美元 |
| 弹性公网 IP EIP | 计费模式：按需计费<br>线路：动态 BGP<br>带宽：按流量计费<br>大小：300Mbit/s | 1 | 0.00 美元 |
| **合计** | — | — | **约 0.20 美元** |

> 预估费用仅供参考，实际费用取决于具体使用量。详细价格请参考华为云官网。

#### 表 2-2 成本预估（包年包月）

| 华为云服务 | 配置 | 数量 | 预估费用（1个月） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：包年包月<br>区域：华北-北京四<br>规格：x1.8u.16g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 100GB | 1 | 约 146.00 美元 |
| 弹性公网 IP EIP | 计费模式：按流量计费<br>线路：动态 BGP<br>带宽：300Mbit/s | 1 | 按实际流量计费 |
| **合计** | — | — | **约 146.00 美元/月 + EIP 流量费** |

---

## 3. 实施步骤

### 3.1 准备工作

#### 3.1.1 创建 rf_admin_trust 委托（可选）

步骤 1 打开华为云控制台，将鼠标悬停在右上角用户名，打开"统一身份认证"。

步骤 2 进入"委托"页面，搜索 `rf_admin_trust`。

如已存在该委托，跳过以下创建步骤。
如不存在，请按以下步骤创建。

步骤 3 单击"创建委托"，委托名称填写 `rf_admin_trust`，委托类型选择"云服务"，云服务选择 `RFS`，单击"完成"。

步骤 4 单击"立即授权"。

步骤 5 搜索并选择 `Tenant Administrator`，单击"下一步"。

步骤 6 授权范围选择"所有资源"，单击"确定"完成配置。

步骤 7 确认委托列表中出现 `rf_admin_trust`。

----结束

### 3.2 快速部署

> 本节帮助您高效完成 Supabase 方案部署，请按以下步骤进行一键部署。

步骤 1 单击"开始部署"，跳转至 RFS 资源编排控制台。

步骤 2 单击"下一步"，确认基础配置，并设置 ECS 密码和数据库密码。

**表 3-1 配置参数**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| solution_name | 解决方案名称，4-24个字符，支持小写字母、数字、-（中划线），必须以小写字母开头 | supabase |
| ecs_flavor | 云服务器实例规格，x1.8u.16g（8vCPUs 16GiB）及以上推荐 | x1.8u.16g |
| ecs_password | 云服务器密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种 | / |
| db_password | PostgreSQL数据库密码，8-26位，将同时作为所有数据库角色的密码 | / |
| system_disk_size | 系统盘大小（GB），高IO类型，取值范围：40-1024，Supabase建议100GB起步 | 100 |
| bandwidth_size | 弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300 | 300 |
| charging_mode | 计费模式：postPaid（按需计费）或 prePaid（包年包月） | postPaid |
| charging_unit | 订购周期类型：month（月）或 year（年），仅 prePaid 模式生效 | month |
| charging_period | 订购周期，1-9（月）或 1-3（年），仅 prePaid 模式生效 | 1 |

步骤 3 按需配置加密与权限，单击"下一步"。

步骤 4 查看资源栈内容，可选择单击"创建执行计划"预览预估费用，然后单击"直接部署资源栈"。

步骤 5 等待 `Apply required resource success`，在"输出"页签查看连接信息。请等待约 10-15 分钟后再使用服务（Docker 镜像拉取和启动需要较长时间）。

> **注意：**
> - 若账户余额不足，请前往"费用中心 > 充值"进行充值。
> - 若包年包月自动扣费失败，请前往"费用中心 > 待支付订单"手动支付。

----结束

### 3.3 开始使用

#### 3.3.1 访问 Supabase Dashboard

步骤 1 在浏览器中访问部署输出中提供的 Dashboard 地址：

```
http://<EIP>:8000/project/default
```

> **注意：** 将 `<EIP>` 替换为 RFS 输出中的弹性公网 IP 地址。

步骤 2 首次访问时，Supabase Studio 管理面板将加载。您可以在面板中：

- 查看和管理数据库表
- 配置用户认证（邮箱、OAuth、手机号等）
- 管理文件存储桶
- 查看实时订阅状态
- 执行 SQL 查询

步骤 3 验证 Supabase 运行状态：

```bash
# SSH 登录 ECS
ssh root@<EIP>

# 查看容器状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 查看容器日志
docker compose -f /opt/supabase/docker-compose.yaml logs --tail 50
```

----结束

#### 3.3.2 获取 API Keys

Supabase 使用 JWT 进行 API 认证。部署后请立即查看并妥善保管以下密钥：

```bash
# SSH 登录后查看
ssh root@<EIP>
cat /opt/supabase/.env
```

**表 3-2 API Keys**

| Key | 说明 | 用途 |
|-----|------|------|
| `ANON_KEY` | 公共访问密钥（匿名角色） | 客户端应用使用，权限受限 |
| `SERVICE_ROLE_KEY` | 管理员密钥 | 服务端使用，拥有完整权限，**切勿暴露到客户端** |
| `POSTGRES_PASSWORD` | PostgreSQL 数据库密码 | 数据库连接使用 |

> **安全提示：** 部署时 `JWT_SECRET` 与 `SECRET_KEY_BASE` 已随机生成，`ANON_KEY`/`SERVICE_ROLE_KEY` 由 `JWT_SECRET` 派生签发，开箱即用。请妥善保管 `.env` 中所有密钥，`SERVICE_ROLE_KEY` 切勿暴露到客户端。

----结束

#### 3.3.3 轮换安全密钥（如需）

部署时 `JWT_SECRET`、`SECRET_KEY_BASE` 已随机生成，`ANON_KEY`/`SERVICE_ROLE_KEY` 用 `JWT_SECRET` 现场签发。如需轮换：

```bash
ssh root@<EIP>
cd /opt/supabase

# 1. 生成新 JWT_SECRET
NEW_JWT=$(openssl rand -base64 32)

# 2. 用新 JWT_SECRET 重新签发 ANON_KEY / SERVICE_ROLE_KEY
gen_jwt() {
  local secret="$1" role="$2"
  local h p sig
  h=$(printf '%s' '{"alg":"HS256","typ":"JWT"}' | openssl base64 -A | tr '/+' '_-' | tr -d '=')
  p=$(printf '%s' "{\"iss\":\"supabase\",\"role\":\"$role\",\"exp\":1983810273,\"ref\":\"default\"}" | openssl base64 -A | tr '/+' '_-' | tr -d '=')
  sig=$(printf '%s' "$h.$p" | openssl dgst -sha256 -hmac "$secret" -binary | openssl base64 -A | tr '/+' '_-' | tr -d '=')
  printf '%s' "$h.$p.$sig"
}

# 3. 写回 .env 并重启
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$NEW_JWT|" .env
sed -i "s|^ANON_KEY=.*|ANON_KEY=$(gen_jwt "$NEW_JWT" anon)|" .env
sed -i "s|^SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=$(gen_jwt "$NEW_JWT" service_role)|" .env
docker compose restart
```

> **注意：** 单独改 `JWT_SECRET` 而不重新签发 `ANON_KEY`/`SERVICE_ROLE_KEY` 会导致 REST/Auth/Storage 验签全部失败。`POSTGRES_PASSWORD` 轮换需同步 `ALTER USER` 各数据库角色，建议直接重建栈完成。

----结束

#### 3.3.4 常用服务端点

**表 3-3 Supabase 服务端点**

| 端点 | 说明 | 示例 |
|------|------|------|
| Dashboard | Web 管理面板 | `http://<EIP>:8000/project/default` |
| REST API | 自动生成的 RESTful API | `http://<EIP>:8000/rest/v1/` |
| Auth API | 用户认证 API | `http://<EIP>:8000/auth/v1/` |
| Storage | 文件存储 API | `http://<EIP>:8000/storage/v1/` |
| Realtime | WebSocket 实时订阅 | `http://<EIP>:8000/realtime/v1/` |

----结束

### 3.4 卸载

步骤 1 在 RFS 控制台中找到本方案创建的资源栈，单击资源栈名称旁的"删除"按钮。

步骤 2 在弹出的确认框中选择"删除资源"，输入 `Delete`，单击"确定"完成卸载。

> **注意：**
> - 卸载会释放所有资源（ECS、EIP、VPC、安全组）。
> - **删除前请务必备份 `/opt/supabase/volumes/db/data` 中的数据库数据**，卸载后数据将不可恢复。

----结束

---

## 4. 附录

### 4.1 名词解释

| 术语 | 说明 |
|------|------|
| Supabase | 开源的 Firebase 替代品，提供 PostgreSQL 数据库、认证、REST API、实时订阅、文件存储等完整后端服务 |
| PostgreSQL | 开源关系型数据库，Supabase 的核心数据存储引擎 |
| Kong | 开源 API 网关，作为 Supabase 的统一入口 |
| GoTrue | 开源用户认证服务，支持邮箱、OAuth、手机号等多种认证方式 |
| PostgREST | 自动生成 PostgreSQL 数据库的 RESTful API |
| pgvector | PostgreSQL 向量搜索扩展，用于 AI 和语义搜索应用 |
| Flexus X | 华为云 Flexus X 实例，新一代柔性算力云服务器 |
| RFS | 资源编排服务（Resource Formation Service），华为云的资源编排服务 |
| SWR | 容器镜像服务（SoftWare Repository for Container），华为云的容器镜像仓库 |
| JWT | JSON Web Token，用于 API 认证的无状态令牌 |

### 4.2 参考链接

- [Supabase 官方文档](https://supabase.com/docs)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [Supabase 自托管指南](https://supabase.com/docs/guides/self-hosting/docker)
- [华为云 RFS](https://support.huaweicloud.com/rfs/)

---

## 5. 修订记录

| 日期 | 修订记录 |
|---------|---------|
| 2026-07-02 | 完善部署脚本：修复 JWT 密钥一致性（ANON/SERVICE_ROLE_KEY 改由随机 JWT_SECRET 派生签发）、补全 imgproxy 接线与 meta 健康检查、Terraform 密码参数校验。|
| 2026-06-26 | 首次发布。|
