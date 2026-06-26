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
| **故障恢复** | 手动 | 自动 |
| **多可用区** | 否 | 是 |
| **部署耗时** | ~10 分钟 | ~15-20 分钟 |
| **月成本** | ~$30-36 | ~$500-800 |
| **适用场景** | 开发测试、小团队 | 生产环境、企业级 SLA |

---

## 2. 快速部署

### 2.1 单机版部署

#### 前置条件

- 已有华为云账号，且账户余额充足
- 已开通 RFS（资源编排服务）
- 推荐规格：Flexus X 实例 x1.2u.4g 及以上

#### 一键部署

1. 登录华为云 RFS 控制台 → 创建资源栈
2. 选择模板 `deploying-litellm.tf`
3. 配置部署参数（master_key 须以 `sk-` 开头）
4. 单击"一键部署"
5. 等待部署完成（约 10 分钟）

#### 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `solution_name` | `litellm-llm-gateway` | 方案名称 |
| `ecs_flavor` | `x1.2u.4g` | ECS 规格 |
| `ecs_password` | （必填） | ECS root 密码 |
| `db_password` | （必填） | PostgreSQL 密码 |
| `master_key` | （必填） | 管理密钥，须以 `sk-` 开头 |
| `salt_key` | （自动生成） | 加密密钥 |
| `system_disk_size` | `40` | 系统盘大小（GB） |
| `bandwidth_size` | `300` | 带宽大小（Mbit/s） |

### 2.2 高可用版部署

#### 前置条件

- [ ] 华为云账号已注册、实名认证、无欠费
- [ ]（IAM 用户）已创建 `rf_admin_trust` 委托

#### 一键部署

1. 登录华为云 RFS 控制台 → 创建资源栈，选择 HA 模板 `deploying-litellm-ha.tf`
2. 配置参数（主要参数：`resource_name_prefix`、`litellm_master_key`、`litellm_salt_key`、`cce_node_pool_password`、`pgsql_admin_password`、`redis_password`）
3. 选择 `rf_admin_trust` 委托 → 点击下一步
4. 确认配置 → 创建执行计划 → 部署
5. 等待约 15-20 分钟完成部署

---

## 3. 开始使用

### 单机版

```
Admin UI:   http://<EIP>:4000/ui          (用 master_key 登录)
API:        http://<EIP>:4000/v1/chat/completions
```

### 高可用版

```
Admin UI:   http://<ELB-EIP>/ui       (用 master_key 登录)
API:        http://<ELB-EIP>/v1/chat/completions
```

### 调用示例

```bash
curl http://<EIP>:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-your-master-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o", "messages": [{"role": "user", "content": "Hello!"}]}'
```

---

## 4. 更多资源

- [LiteLLM GitHub](https://github.com/BerriAI/litellm)
- [LiteLLM Proxy 文档](https://docs.litellm.ai/docs/proxy)
- [华为云 RFS](https://support.huaweicloud.com/rfs/)
