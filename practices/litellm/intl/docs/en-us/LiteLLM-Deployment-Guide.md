# LiteLLM, The Unified LLM Gateway — Deployment Guide

> **Version**: v1.0 · **Date**: 2026-06-17
>
> This document covers both **Single-Instance** and **High-Availability (HA)** deployment options. Single-instance is suitable for dev/test environments; HA is for production-grade enterprise workloads.

---

## 1. Solution Overview

Deploy LiteLLM — the unified LLM API gateway (GitHub 17k+ Stars) on a Huawei Cloud Flexus X instance via a single Terraform template. LiteLLM unifies 100+ LLM providers (OpenAI, Anthropic, Azure, Cohere, etc.) into a single OpenAI-compatible API, with built-in virtual key management, spend tracking, load balancing, and an Admin Web UI.

### Deployment Options Comparison

| Dimension | Single-Instance | High-Availability |
|-----------|----------------|-------------------|
| **Compute** | 1 Flexus X Instance (Docker Compose) | CCE cluster, 4 pods |
| **Database** | Container PostgreSQL | RDS PostgreSQL HA (primary/standby) |
| **Cache** | None | DCS Redis 7.0 HA |
| **Load Balancer** | None (direct EIP) | ELB L7 (multi-AZ) |
| **Auto-scaling** | None | Node pool 1-10 |
| **Failover** | Manual | Automatic |
| **Multi-AZ** | No | Yes |
| **Deploy Time** | ~10 min | ~15-20 min |
| **Cost** | ~$30-36/month | ~$500-800/month |
| **Suitable for** | Dev/test, small teams | Production, enterprise SLA |

---

## 2. Use Cases

- Teams needing unified access to multiple LLM providers with centralized key management
- Organizations requiring virtual key management, spend tracking, and cost allocation
- LLM applications needing load balancing, failover, and rate limiting
- Projects using OpenAI-compatible API but switching between multiple providers
- Development and testing environments for AI applications

## 3. Key Benefits

- **17k+ Stars Open Source**: MIT license, active community, supports 100+ LLM providers
- **OpenAI-Compatible API**: Unified `/v1/chat/completions` endpoint, zero code changes to switch providers
- **Admin Web UI**: Visual management of models, API keys, and usage statistics with Prometheus monitoring
- **Lightweight**: Only requires 2vCPU 4GiB to run all services

---

## 4. Quick Deployment

### 4.1 Single-Instance Deployment

#### Prerequisites

- Huawei Cloud account with sufficient balance
- RFS (Resource Formation Service) enabled
- Recommended: Flexus X instance x1.2u.4g or above

#### One-Click Deploy

1. Log in to Huawei Cloud RFS Console → Create Resource Stack
2. Select template `deploying-litellm.tf`
3. Configure parameters (`master_key` must start with `sk-`)
4. Click "Deploy"
5. Wait for deployment to complete (~10 minutes)

#### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `solution_name` | `litellm-llm-gateway` | Solution name |
| `ecs_flavor` | `x1.2u.4g` | ECS flavor |
| `ecs_password` | (required) | ECS root password |
| `db_password` | (required) | PostgreSQL password |
| `master_key` | (required) | LiteLLM master key, must start with `sk-` |
| `salt_key` | (auto-generated) | Encryption key |
| `system_disk_size` | `40` | System disk size in GB |
| `bandwidth_size` | `300` | EIP bandwidth in Mbit/s |

### 4.2 High-Availability Deployment

#### Prerequisites

- [ ] Huawei Cloud account not in arrears
- [ ] (IAM users) `rf_admin_trust` agency created

#### One-Click Deploy

1. Log in to Huawei Cloud RFS Console → Create Resource Stack, select HA template `deploying-litellm-ha.tf`
2. Configure parameters (key params: `litellm_master_key`, `litellm_salt_key`, `cce_node_pool_password`, `pgsql_admin_password`, `redis_password`)
3. Select `rf_admin_trust` agency → Next
4. Confirm → Create Execution Plan → Deploy
5. Wait ~15-20 minutes

---

## 5. Getting Started

### Single-Instance

```
Admin UI:   http://<EIP>:4000/ui          (login with master_key)
API:        http://<EIP>:4000/v1/chat/completions
```

### High-Availability

```
Admin UI:   http://<ELB-EIP>/ui       (login with master_key)
API:        http://<ELB-EIP>/v1/chat/completions
```

### API Call Example

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

## 6. Estimated Cost

### Single-Instance

| Resource | Spec | Pay-per-use (USD/hr) | Monthly (USD/mo) |
|----------|------|:--------------------:|:-----------------:|
| Flexus X Instance | x1.2u.4g | ~$0.04-0.07 | ~$22-30 |
| Elastic IP | 300Mbit/s traffic | ~$0.01 (traffic extra) | ~$3 (excl. traffic) |
| System Disk | 40GB SAS | - | ~$3 |
| **Total** | | **~$0.05-0.08/hr** | **~$28-36/mo** |

### High-Availability

| Resource | Spec | Est. Monthly Cost (USD) |
|----------|------|:-----------------------:|
| CCE + Node Pool + RDS + DCS + ELB + EIP + NAT | Enterprise HA | **~$560/month** |

---

## 7. Quick Uninstall

1. Log in to Huawei Cloud RFS Console
2. Locate the resource stack → Click "Delete Resource Stack"
3. Type "Delete" → Confirm

---

## 8. More Resources

- [LiteLLM GitHub](https://github.com/BerriAI/litellm)
- [LiteLLM Proxy Docs](https://docs.litellm.ai/docs/proxy)
- [Huawei Cloud RFS](https://support.huaweicloud.com/rfs/)
