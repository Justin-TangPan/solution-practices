# LiteLLM，The Unified LLM Gateway — One-Click Deployment

## Solution Overview

Deploy LiteLLM — the unified LLM API gateway (GitHub 17k+ Stars) on a Huawei Cloud Flexus X instance via a single Terraform template. LiteLLM unifies 100+ LLM providers (OpenAI, Anthropic, Azure, Cohere, etc.) into a single OpenAI-compatible API, with built-in virtual key management, spend tracking, load balancing, and an Admin Web UI.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                    Internet                      │
└────────────┬────────────────────────┬────────────┘
             │ HTTP :4000              │ SSH :22
             ▼                        ▼
┌──────────────────────┐  ┌────────────────────────┐
│      EIP (Public IP)  │  │   Cloud Shell / Local  │
└──────────┬───────────┘  └────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────┐
│   Flexus X Instance (x1.2u.4g recommended)               │
│  ┌────────────────────────────────────────────────────┐  │
│  │  LiteLLM Proxy ← API Gateway :4000                 │  │
│  │  /v1/chat/completions (OpenAI-compatible)          │  │
│  │  /ui (Admin Dashboard)                             │  │
│  │  ┌────────────────────────────────────────────┐    │  │
│  │  │  PostgreSQL 16 (virtual keys + spend data)  │    │  │
│  │  └────────────────────────────────────────────┘    │  │
│  │  ┌────────────────────────────────────────────┐    │  │
│  │  │  Prometheus (call metrics & monitoring)     │    │  │
│  │  └────────────────────────────────────────────┘    │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
      OpenAI API           Anthropic API        Azure OpenAI
      Cohere API           Replicate API        Custom Providers
```

**Deployed Resources**:

| Resource | Spec | Qty | Description |
|----------|------|:---:|-------------|
| Flexus X Instance | x1.2u.4g (2vCPUs 4GiB) | 1 | Runs LiteLLM + PostgreSQL + Prometheus |
| Elastic IP (EIP) | 5-bgp, 300Mbit/s, traffic billing | 1 | API gateway entry point |
| VPC | 172.16.0.0/16 | 1 | Network isolation |
| VPC Subnet | 172.16.1.0/24 | 1 | Internal communication |
| Security Group | - | 1 | Opens HTTP(4000) + Prometheus(9090) + SSH(22) |

## Use Cases

- Teams needing unified access to multiple LLM providers with centralized key management
- Organizations requiring virtual key management, spend tracking, and cost allocation
- LLM applications needing load balancing, failover, and rate limiting
- Projects using OpenAI-compatible API but switching between multiple providers
- Development and testing environments for AI applications

## Key Benefits

- **17k+ Stars Open Source**: MIT license, active community, supports 100+ LLM providers
- **Single Terraform Template**: One `.tf` file deploys everything — no external dependencies
- **Docker Compose Orchestration**: 3 containers auto-configured, ~10 min deployment
- **OpenAI-Compatible API**: Unified `/v1/chat/completions` endpoint, zero code changes to switch providers
- **Admin Web UI**: Visual management of models, API keys, and usage statistics with Prometheus monitoring
- **Lightweight**: Only requires 2vCPU 4GiB to run all services

## Deployment Guide

### Prerequisites

- Huawei Cloud account with sufficient balance
- RFS (Resource Formation Service) enabled
- Recommended: Flexus X instance x1.2u.4g or above

### One-Click Deploy

1. Log in to Huawei Cloud RFS Console → Create Resource Stack
2. Upload template `deploying-litellm.tf`
3. Configure deployment parameters (`master_key` must start with `sk-`)
4. Click "Deploy"
5. Wait for deployment to complete (~10 minutes, mainly Docker image pulls)

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `solution_name` | `litellm-llm-gateway` | Solution name, used for all resource naming |
| `ecs_flavor` | `x1.2u.4g` | ECS flavor, 2vCPUs 4GiB or above recommended |
| `ecs_password` | (required) | ECS root password |
| `db_password` | (required) | PostgreSQL password |
| `master_key` | (required) | LiteLLM master key, must start with `sk-` |
| `salt_key` | (auto-generated) | Encryption key for stored API keys. **CANNOT be changed once used** |
| `system_disk_size` | `40` | System disk size in GB |
| `bandwidth_size` | `300` | EIP bandwidth in Mbit/s |

## Getting Started

After deployment, access via browser:

```
Admin UI:   http://<EIP>:4000/ui          (login with master_key)
API:        http://<EIP>:4000/v1/chat/completions
Models:     http://<EIP>:4000/v1/models
Health:     http://<EIP>:4000/health/liveliness
Prometheus: http://<EIP>:9090
```

### Add Provider API Key

After deployment, add at least one LLM provider API key:

```bash
ssh root@<EIP>
vi /opt/litellm/.env
# Add the API keys you need:
# OPENAI_API_KEY=sk-xxx
# ANTHROPIC_API_KEY=sk-ant-xxx
cd /opt/litellm && docker compose restart
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

### Custom Model Configuration

Edit `/opt/litellm/config.yaml` to add custom model routing:

```yaml
model_list:
  - model_name: my-gpt4
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY
  - model_name: my-claude
    litellm_params:
      model: anthropic/claude-sonnet-4-20250514
      api_key: os.environ/ANTHROPIC_API_KEY
```

## Estimated Cost

| Resource | Spec | Pay-per-use (USD/hr) | Monthly (USD/mo) |
|----------|------|:--------------------:|:-----------------:|
| Flexus X Instance | x1.2u.4g | ~$0.04-0.07 | ~$22-30 |
| Elastic IP | 300Mbit/s traffic | ~$0.01 (traffic extra) | ~$3 (excl. traffic) |
| System Disk | 40GB SAS | - | ~$3 |
| **Total** | | **~$0.05-0.08/hr** | **~$28-36/mo** |

> Note: LLM API call costs are billed separately by each provider.

## Quick Uninstall

1. Log in to Huawei Cloud RFS Console
2. Locate the corresponding resource stack
3. Click "Delete Resource Stack" → Type "Delete" → Confirm

> Warning: Backup `/opt/litellm/volumes/db/data` before deletion to preserve virtual keys and usage data.

## More Resources

- [LiteLLM GitHub](https://github.com/BerriAI/litellm) — Source code and documentation
- [LiteLLM Proxy Docs](https://docs.litellm.ai/docs/proxy) — Self-hosted deployment guide
- [Huawei Cloud RFS](https://support.huaweicloud.com/rfs/) — Resource Formation Service documentation
