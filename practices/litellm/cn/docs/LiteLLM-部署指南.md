# LiteLLM，统一的 LLM 网关 — 部署指南

> **版本**: v1.0 · **日期**: 2026-06-17
>
> 本文档涵盖 **单机版** 和 **高可用版 (HA)** 两种部署方案。单机版适用于开发测试环境，高可用版适用于生产环境。

---

## 1. 方案概述

基于华为云 Flexus 云服务器 X 实例，通过 Docker Compose 一键部署 LiteLLM — 统一的 LLM 网关（GitHub 17k+ Stars）。将 100+ LLM Provider（OpenAI、Anthropic、Azure、Cohere 等）统一为 OpenAI 兼容 API，内置虚拟密钥管理、用量追踪、负载均衡和 Admin Web 管理面板。

### 部署方案对比

| 维度 | 单机版 | 高可用版 (HA) |
|------|--------|--------------|
| **计算** | 1 台 Flexus X 实例 (Docker Compose) | CCE 集群，4 个 Pod |
| **数据库** | 容器 PostgreSQL | RDS PostgreSQL 主备版 |
| **缓存** | 无 | DCS Redis 7.0 HA |
| **负载均衡** | 无（直连 EIP） | ELB 七层（多可用区） |
| **自动伸缩** | 无 | 节点池 1-10 |
| **故障恢复** | 手动 | 自动（Pod 重启 + DB 主备切换） |
| **多可用区** | 否 | 是（CCE + RDS + DCS） |
| **部署耗时** | ~10 分钟 | ~15-20 分钟 |
| **月成本** | ~$30-36 | ~$500-800 |
| **适用场景** | 开发测试、小团队 | 生产环境、企业级 SLA |

---

## 2. 适用场景

- 多 LLM Provider 统一接入，避免各业务团队各自管理 API Key
- 需要虚拟密钥管理、用量追踪、费用分摊的团队
- LLM 应用需要负载均衡、故障切换、限流等网关能力
- 需要 OpenAI 兼容 API 但实际使用多家 Provider 的项目
- AI 应用开发测试环境的 API 网关

## 3. 方案优势

- **17k+ Stars 开源项目**：MIT 协议，社区活跃，支持 100+ LLM Provider
- **Docker Compose 一键部署**：3 个容器自动编排，10 分钟完成部署
- **SWR 镜像加速**：华为云 SWR 内网拉取 Docker 镜像，国内 ECS 稳定快速
- **OpenAI 兼容 API**：统一 `/v1/chat/completions` 接口，业务代码零改动切换 Provider
- **Admin Web 面板**：可视化管理模型、密钥、用量统计，支持 Prometheus 监控
- **轻量高效**：仅需 2vCPU 4GiB 即可运行，资源消耗极低

---

## 4. 快速部署

### 4.1 单机版部署

#### 前置条件

- 已有华为云账号，且账户余额充足
- 已开通 RFS（资源编排服务）
- 推荐规格：Flexus X 实例 x1.2u.4g 及以上

#### 一键部署

1. 登录华为云 RFS 控制台 → 创建资源栈
2. 选择模板 `deploying-litellm.tf`
3. 配置部署参数（master_key 须以 `sk-` 开头）
4. 单击"一键部署"
5. 等待部署完成（约 10 分钟，主要耗时在 Docker 镜像拉取）

#### 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `solution_name` | `litellm-llm-gateway` | 方案名称，用于所有资源命名 |
| `ecs_flavor` | `x1.2u.4g` | ECS 规格，推荐 2vCPUs 4GiB 及以上 |
| `ecs_password` | （必填） | ECS root 密码 |
| `db_password` | （必填） | PostgreSQL 密码 |
| `master_key` | （必填） | LiteLLM 管理密钥，须以 `sk-` 开头 |
| `salt_key` | （自动生成） | 加密密钥，留空自动生成，**一旦使用不可更改** |
| `system_disk_size` | `40` | 系统盘大小（GB） |
| `bandwidth_size` | `300` | 带宽大小（Mbit/s） |

### 4.2 高可用版部署

#### 前置条件

- [ ] 华为云账号已注册、实名认证、无欠费
- [ ] 已开通 MaaS 服务，获取 API Key
- [ ]（IAM 用户）已创建 `rf_admin_trust` 委托，绑定 Tenant Administrator 策略

#### 一键部署

1. 登录华为云 RFS 控制台 → 创建资源栈，选择 HA 模板 `deploying-litellm-ha.tf`
2. 配置参数（以下为主要参数，完整参数请参考模板说明）

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `resource_name_prefix` | `ha-litellm` | 资源名称前缀，4-24字符，小写字母/数字/中划线 |
| `bandwidth_size` | `300` | EIP 带宽，Mbit/s，按流量计费 |
| `litellm_master_key` | （必填） | 主密钥，须以 `sk-` 开头，最长24位 |
| `litellm_salt_key` | （必填） | 数据库加密密钥，8-24位 |
| `cce_node_pool_password` | （必填） | 节点池 SSH 密码 |
| `pgsql_admin_password` | （必填） | PostgreSQL 管理员密码 |
| `redis_password` | （必填） | Redis 密码 |

3. 选择 `rf_admin_trust` 委托（IAM 用户），点击下一步
4. 确认配置 → 创建执行计划 → 状态变为"可用" → 部署
5. 等待约 15-20 分钟完成部署
6. 在"输出"页签查看 ELB 访问地址

---

## 5. 开始使用

### 单机版

部署完成后通过浏览器访问：

```
Admin UI:   http://<EIP>:4000/ui          (用 master_key 登录)
API:        http://<EIP>:4000/v1/chat/completions
Models:     http://<EIP>:4000/v1/models
Health:     http://<EIP>:4000/health/liveliness
Prometheus: http://<EIP>:9090
```

### 高可用版

```
Admin UI:   http://<ELB-EIP>/ui       （使用 master_key 登录）
API:        http://<ELB-EIP>/v1/chat/completions
健康检查:    http://<ELB-EIP>/health/readiness
```

### 添加 Provider API Key

**单机版** — SSH 登录 ECS 后编辑：

```bash
ssh root@<EIP>
vi /opt/litellm/.env
cd /opt/litellm && docker compose restart
```

**高可用版** — 通过 Admin UI 添加模型。

### 调用示例

```bash
curl http://<EIP>:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-your-master-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## 6. 预估费用

### 单机版

| 资源 | 规格 | 按需（元/小时） | 包月（元/月） |
|------|------|:--------------:|:------------:|
| Flexus X 实例 | x1.2u.4g | ~0.3-0.5 | ~120-180 |
| 弹性公网 IP | 300Mbit/s 按流量 | ~0.1（流量另计） | ~20（不含流量） |
| 系统盘 | 40GB SAS | - | ~20 |
| **合计** | | **~0.4-0.6 元/小时** | **~160-220 元/月** |

### 高可用版

| 资源 | 规格 | 月预估 (USD) |
|------|------|:------------:|
| CCE 集群 | cce.s2.small | ~$50 |
| CCE 节点池 | c7n.2xlarge.2 × 3 | ~$250 |
| RDS PostgreSQL | pg.x1.2xlarge.2.ha, 100GB | ~$120 |
| DCS Redis | 8GB HA | ~$60 |
| ELB | 七层性能型 | ~$30 |
| EIP ×3 | 300Mbit/s 按流量 | ~$45 (不含流量) |
| NAT 网关 | 规格 1 | ~$5 |
| **合计** | | **~$560/月** |

> 注：LLM API 调用费用由各 Provider 单独计费，不在本方案费用内。

---

## 7. 快速卸载

1. 登录华为云 RFS 控制台
2. 找到对应资源栈
3. 单击"删除资源栈" → 输入 "Delete" → 确认

> 注意：删除前请确保 `/opt/litellm/volumes/db/data` 中的密钥和用量数据已备份。

---

## 8. 更多资源

- [LiteLLM GitHub](https://github.com/BerriAI/litellm) — 源码与文档
- [LiteLLM Proxy 文档](https://docs.litellm.ai/docs/proxy) — 自托管部署指南
- [华为云 RFS](https://support.huaweicloud.com/rfs/) — 资源编排服务文档
