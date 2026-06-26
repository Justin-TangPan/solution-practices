# LiteLLM，统一的 LLM 网关 — 部署指南

> **版本**: v1.0 · **日期**: 2026-06-17
>
> 本文档涵盖 **单机版** 和 **高可用版 (HA)** 两种部署方案。

---

## 1. 方案概述

基于华为云 Flexus 云服务器 X 实例，通过 Docker Compose 一键部署 LiteLLM — 统一的 LLM 网关（GitHub 17k+ Stars）。

### 部署方案对比

| 维度 | 单机版 | 高可用版 (HA) |
|------|--------|--------------|
| **计算** | 1 台 Flexus X 实例 (Docker Compose) | CCE 集群，4 个 Pod |
| **数据库** | 容器 PostgreSQL | RDS PostgreSQL 主备版 |
| **缓存** | 无 | DCS Redis 7.0 HA |
| **负载均衡** | 无（直连 EIP） | ELB 七层（多可用区） |
| **月成本** | ~$30-36 | ~$500-800 |
| **适用场景** | 开发测试、小团队 | 生产环境、企业级 SLA |

---

## 2. 快速部署

### 2.1 单机版部署

1. 登录华为云 RFS 控制台 → 创建资源栈
2. 选择模板 `deploying-litellm-{region}.tf`
3. 配置部署参数（master_key 须以 `sk-` 开头）
4. 单击"一键部署"
5. 等待部署完成（约 10 分钟）

### 2.2 高可用版部署

1. 登录华为云 RFS 控制台 → 创建资源栈
2. 选择模板 `deploying-litellm-ha-{region}.tf`
3. 配置部署参数
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

---

## 4. 更多资源

- [LiteLLM GitHub](https://github.com/BerriAI/litellm)
- [LiteLLM Proxy 文档](https://docs.litellm.ai/docs/proxy)
- [华为云 RFS](https://support.huaweicloud.com/rfs/)
