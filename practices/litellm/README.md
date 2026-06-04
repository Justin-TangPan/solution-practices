# LiteLLM — 统一 LLM 代理网关 一键部署

## 方案概述

基于华为云 Flexus 云服务器 X 实例，通过 Docker Compose 一键部署 LiteLLM — 统一 LLM API 代理网关（GitHub 17k+ Stars）。LiteLLM 将 100+ LLM Provider（OpenAI、Anthropic、Azure、Cohere 等）统一为 OpenAI 兼容 API，内置虚拟密钥管理、用量追踪、负载均衡和 Admin Web 管理面板。

## 方案架构

```
┌─────────────────────────────────────────────────┐
│                   互联网                          │
└────────────┬────────────────────────┬────────────┘
             │ HTTP :4000              │ SSH :22
             ▼                        ▼
┌──────────────────────┐  ┌────────────────────────┐
│   EIP (弹性公网 IP)    │  │   Cloud Shell / 本地    │
└──────────┬───────────┘  └────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────┐
│   Flexus X 实例 (x1.2u.4g 推荐)                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  LiteLLM Proxy ← 统一 API 入口 :4000               │  │
│  │  /v1/chat/completions (OpenAI 兼容)                │  │
│  │  /ui (Admin 管理面板)                               │  │
│  │  ┌────────────────────────────────────────────┐    │  │
│  │  │  PostgreSQL 16 (虚拟密钥 + 用量统计)         │    │  │
│  │  └────────────────────────────────────────────┘    │  │
│  │  ┌────────────────────────────────────────────┐    │  │
│  │  │  Prometheus (调用指标监控)                    │    │  │
│  │  └────────────────────────────────────────────┘    │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
      OpenAI API           Anthropic API        Azure OpenAI
      Cohere API           Replicate API        自定义 Provider
```

**部署资源清单**：

| 资源 | 规格 | 数量 | 说明 |
|------|------|:----:|------|
| Flexus 云服务器 X 实例 | x1.2u.4g (2vCPUs 4GiB) | 1 | 运行 LiteLLM + PostgreSQL + Prometheus |
| 弹性公网 IP EIP | 5-bgp, 300Mbit/s, 按流量计费 | 1 | API 网关入口 |
| 虚拟私有云 VPC | 172.16.0.0/16 | 1 | 网络隔离 |
| VPC 子网 | 172.16.1.0/24 | 1 | 内网通信 |
| 安全组 | - | 1 | 开放 HTTP(4000) + Prometheus(9090) + SSH(22) |

## 适用场景

- 多 LLM Provider 统一接入，避免各业务团队各自管理 API Key
- 需要虚拟密钥管理、用量追踪、费用分摊的团队
- LLM 应用需要负载均衡、故障切换、限流等网关能力
- 需要 OpenAI 兼容 API 但实际使用多家 Provider 的项目
- AI 应用开发测试环境的 API 网关

## 方案优势

- **17k+ Stars 开源项目**：MIT 协议，社区活跃，支持 100+ LLM Provider
- **Docker Compose 一键部署**：3 个容器自动编排，10 分钟完成部署
- **SWR 镜像加速**：华为云 SWR 内网拉取 Docker 镜像，国内 ECS 稳定快速
- **OpenAI 兼容 API**：统一 `/v1/chat/completions` 接口，业务代码零改动切换 Provider
- **Admin Web 面板**：可视化管理模型、密钥、用量统计，支持 Prometheus 监控
- **轻量高效**：仅需 2vCPU 4GiB 即可运行，资源消耗极低

## 部署指南

### 前置条件

- 已有华为云账号，且账户余额充足
- 已开通 RFS（资源编排服务）
- 推荐规格：Flexus X 实例 x1.2u.4g 及以上

### 一键部署

1. 登录华为云 RFS 控制台 → 创建资源栈
2. 上传模板 `deploying-litellm.tf.json`
3. 配置部署参数（master_key 须以 `sk-` 开头）
4. 单击"一键部署"
5. 等待部署完成（约 10 分钟，主要耗时在 Docker 镜像拉取）

### 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `vpc_name` | `litellm-llm-gateway-demo` | VPC 名称 |
| `security_group_name` | `litellm-llm-gateway-demo` | 安全组名称 |
| `ecs_name` | `litellm-llm-gateway-demo` | ECS 名称 |
| `ecs_flavor` | `x1.2u.4g` | ECS 规格，推荐 2vCPUs 4GiB 及以上 |
| `ecs_password` | （必填） | ECS root 密码 |
| `db_password` | （必填） | PostgreSQL 密码 |
| `master_key` | （必填） | LiteLLM 管理密钥，须以 `sk-` 开头 |
| `salt_key` | （自动生成） | 加密密钥，留空自动生成，**一旦使用不可更改** |
| `system_disk_size` | `40` | 系统盘大小（GB） |
| `bandwidth_size` | `300` | 带宽大小（Mbit/s） |

## 开始使用

部署完成后通过浏览器访问：

```
Admin UI:   http://<EIP>:4000/ui          (用 master_key 登录)
API:        http://<EIP>:4000/v1/chat/completions
Models:     http://<EIP>:4000/v1/models
Health:     http://<EIP>:4000/health/liveliness
Prometheus: http://<EIP>:9090
```

### 添加 Provider API Key

部署后需添加至少一个 LLM Provider 的 API Key：

```bash
ssh root@<EIP>
vi /opt/litellm/.env
# 添加需要的 API Key：
# OPENAI_API_KEY=sk-xxx
# ANTHROPIC_API_KEY=sk-ant-xxx
cd /opt/litellm && docker compose restart
```

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

### 自定义模型配置

编辑 `/opt/litellm/config.yaml` 添加自定义模型路由：

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

## 预估费用

| 资源 | 规格 | 按需（元/小时） | 包月（元/月） |
|------|------|:--------------:|:------------:|
| Flexus X 实例 | x1.2u.4g | ~0.3-0.5 | ~120-180 |
| 弹性公网 IP | 300Mbit/s 按流量 | ~0.1（流量另计） | ~20（不含流量） |
| 系统盘 | 40GB SAS | - | ~20 |
| **合计** | | **~0.4-0.6 元/小时** | **~160-220 元/月** |

> 注：LLM API 调用费用由各 Provider 单独计费，不在本方案费用内。

## 快速卸载

1. 登录华为云 RFS 控制台
2. 找到对应资源栈
3. 单击"删除资源栈" → 输入 "Delete" → 确认

> 注意：删除前请确保 `/opt/litellm/volumes/db/data` 中的密钥和用量数据已备份。

## 更多资源

- [LiteLLM GitHub](https://github.com/BerriAI/litellm) — 源码与文档
- [LiteLLM Proxy 文档](https://docs.litellm.ai/docs/proxy) — 自托管部署指南
- [华为云 RFS](https://support.huaweicloud.com/rfs/) — 资源编排服务文档
