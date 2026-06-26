# LiteLLM, The Unified LLM Gateway — Deployment Guide

> **Version**: v1.0 · **Date**: 2026-06-17
>
> This document covers both **Single-Instance** and **High-Availability (HA)** deployment options.

---

## 1. Solution Overview

Deploy LiteLLM — the unified LLM API gateway (GitHub 17k+ Stars) on a Huawei Cloud Flexus X instance. LiteLLM unifies 100+ LLM providers into a single OpenAI-compatible API, with built-in virtual key management, spend tracking, and load balancing.

### Deployment Options

| Dimension | Single-Instance | High-Availability |
|-----------|----------------|-------------------|
| **Compute** | 1 Flexus X Instance (Docker Compose) | CCE cluster, 4 pods |
| **Database** | Container PostgreSQL | RDS PostgreSQL HA (primary/standby) |
| **Cache** | None | DCS Redis 7.0 HA |
| **Load Balancer** | None (direct EIP) | ELB L7 (multi-AZ) |
| **Cost** | ~$30-36/month | ~$500-800/month |
| **Suitable for** | Dev/test, small teams | Production, enterprise SLA |

---

## 2. Quick Deployment

### 2.1 Single-Instance Deployment

1. Log in to Huawei Cloud RFS Console → Create Resource Stack
2. Select template `deploying-litellm-{region}.tf`
3. Configure parameters (`master_key` must start with `sk-`)
4. Click "Deploy"
5. Wait for deployment to complete (~10 minutes)

### 2.2 High-Availability Deployment

1. Log in to Huawei Cloud RFS Console → Create Resource Stack
2. Select template `deploying-litellm-ha-{region}.tf`
3. Configure parameters
4. Confirm → Create Execution Plan → Deploy
5. Wait ~15-20 minutes for deployment to complete

---

## 3. Getting Started

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

---

## 4. More Resources

- [LiteLLM GitHub](https://github.com/BerriAI/litellm)
- [LiteLLM Proxy Docs](https://docs.litellm.ai/docs/proxy)
- [Huawei Cloud RFS](https://support.huaweicloud.com/rfs/)
