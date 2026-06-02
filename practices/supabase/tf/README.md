# Supabase — 开源 Firebase 替代品 一键部署

## 方案概述

基于华为云 Flexus 云服务器 X 实例，通过 Docker Compose 一键部署 Supabase — 开源的 Firebase 替代品（GitHub 103k+ Stars）。提供托管 PostgreSQL 数据库、用户认证、自动生成 REST/GraphQL API、实时数据订阅、文件存储等完整后端服务。

## 方案架构

```
┌─────────────────────────────────────────────────┐
│                   互联网                          │
└────────────┬────────────────────────┬────────────┘
             │ HTTP :8000              │ SSH :22
             ▼                        ▼
┌──────────────────────┐  ┌────────────────────────┐
│   EIP (弹性公网 IP)    │  │   Cloud Shell / 本地    │
└──────────┬───────────┘  └────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────┐
│   Flexus X 实例 (x1.8u.16g 推荐)                         │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Kong (API Gateway) ← 统一入口 :8000               │  │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌───────────┐  │  │
│  │  │GoTrue  │ │PostgRST│ │Realtime│ │ Storage   │  │  │
│  │  │认证服务  │ │REST API│ │WebSocket│ │ 文件存储   │  │  │
│  │  └───┬────┘ └───┬────┘ └───┬────┘ └─────┬─────┘  │  │
│  │      └──────────┬┴──────────┴────────────┘         │  │
│  │                 ▼                                   │  │
│  │  ┌────────────────────────────────────────────┐    │  │
│  │  │  PostgreSQL 15 (含 pgvector/pgjwt 等扩展)    │    │  │
│  │  │  + Supavisor 连接池                          │    │  │
│  │  └────────────────────────────────────────────┘    │  │
│  │  ┌────────────────────────────────────────────┐    │  │
│  │  │  Studio Web 管理面板                        │    │  │
│  │  └────────────────────────────────────────────┘    │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**部署资源清单**：

| 资源 | 规格 | 数量 | 说明 |
|------|------|:----:|------|
| Flexus 云服务器 X 实例 | x1.8u.16g (8vCPUs 16GiB) | 1 | 运行全部 Docker 容器（约10个） |
| 弹性公网 IP EIP | 5-bgp, 300Mbit/s, 按流量计费 | 1 | Kong API 网关入口 |
| 虚拟私有云 VPC | 172.16.0.0/16 | 1 | 网络隔离 |
| VPC 子网 | 172.16.1.0/24 | 1 | 内网通信 |
| 安全组 | - | 1 | 开放 HTTP(8000) + SSH(22) + PG内网(5432) |

## 适用场景

- 需要快速搭建后端服务（数据库 + API + 认证）的应用开发团队
- 移动端/Web 应用的后端基础设施（替代 Firebase）
- 需要 PostgreSQL 数据库 + 自动 REST/GraphQL API 的项目
- AI 应用开发（pgvector 向量搜索 + 存储 + 实时订阅）
- 企业内部应用的后端平台

## 方案优势

- **103k+ Stars 开源项目**：Apache-2.0 协议，社区活跃，持续更新
- **Docker Compose 一键部署**：约10个容器自动编排，15分钟完成部署
- **SWR 镜像加速**：华为云 SWR 内网拉取 Docker 镜像，国内 ECS 稳定快速
- **内置 PostgreSQL 扩展**：pgvector 向量搜索、pgjwt 认证、PostGIS 地理空间等
- **完整后端能力**：数据库 + REST API + GraphQL + 认证 + 实时订阅 + 文件存储 + Dashboard
- **自动重试机制**：Hermes 风格的 5 次重试，保障镜像拉取成功率

## 部署指南

### 前置条件

- 已有华为云账号，且账户余额充足
- 已开通 RFS（资源编排服务）
- 推荐规格：Flexus X 实例 x1.8u.16g 及以上

### 一键部署

1. 登录华为云 RFS 控制台 → 创建资源栈
2. 上传模板 `deploying-supabase.tf.json`
3. 配置部署参数
4. 单击"一键部署"
5. 等待部署完成（约 15 分钟，主要耗时在 Docker 镜像拉取）

### 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `vpc_name` | `supabase-backend-platform-demo` | VPC 名称 |
| `security_group_name` | `supabase-backend-platform-demo` | 安全组名称 |
| `ecs_name` | `supabase-backend-platform-demo` | ECS 名称 |
| `ecs_flavor` | `x1.8u.16g` | ECS 规格，推荐 8vCPUs 16GiB 及以上 |
| `ecs_password` | （必填） | ECS root 密码 |
| `system_disk_size` | `100` | 系统盘大小（GB） |
| `bandwidth_size` | `300` | 带宽大小（Mbit/s） |

## 开始使用

部署完成后通过浏览器访问：

```
Dashboard:  http://<EIP>:8000/project/default
REST API:   http://<EIP>:8000/rest/v1/
Auth API:   http://<EIP>:8000/auth/v1/
Storage:    http://<EIP>:8000/storage/v1/
```

### 配置密钥

Supabase 使用 JWT 进行 API 认证，部署后请立即修改默认密钥：

```bash
ssh root@<EIP>
vi /opt/supabase/.env
# 修改 POSTGRES_PASSWORD 和 JWT_SECRET
cd /opt/supabase && docker compose restart
```

### 获取 API Keys

| Key | 说明 | 获取位置 |
|-----|------|---------|
| `ANON_KEY` | 公共访问密钥 | `/opt/supabase/.env` |
| `SERVICE_ROLE_KEY` | 管理员密钥（勿暴露客户端） | `/opt/supabase/.env` |

## 预估费用

| 资源 | 规格 | 按需（元/小时） | 包月（元/月） |
|------|------|:--------------:|:------------:|
| Flexus X 实例 | x1.8u.16g | ~1.5-2.5 | ~600-900 |
| 弹性公网 IP | 300Mbit/s 按流量 | ~0.1（流量另计） | ~20（不含流量） |
| 系统盘 | 100GB SAS | - | ~50 |
| **合计** | | **~1.6-2.6 元/小时** | **~670-970 元/月** |

## 快速卸载

1. 登录华为云 RFS 控制台
2. 找到对应资源栈
3. 单击"删除资源栈"→ 输入 "Delete" → 确认

> 注意：删除前请确保 `/opt/supabase/volumes/db/data` 中的数据库已备份。

## 更多资源

- [Supabase GitHub](https://github.com/supabase/supabase) — 源码与文档
- [Supabase 自托管文档](https://supabase.com/docs/guides/self-hosting/docker) — Docker 部署指南
- [华为云 RFS](https://support.huaweicloud.com/rfs/) — 资源编排服务文档
