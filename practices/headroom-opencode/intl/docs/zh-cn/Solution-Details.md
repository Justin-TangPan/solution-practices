# Headroom + OpenCode 方案详情

## 标题区域

**Headroom + OpenCode，更省的编程助手**

一键部署的开源 AI 编程辅助环境，通过智能上下文压缩技术，将 Token 成本降低 60-95%。

- 开源技术栈，无供应商锁定（MIT 许可证）
- 实际开发场景下可节省 60-95% 的 Token 消耗
- 华为云 Flexus X 实例上一键部署
- 通过 MaaS 支持 DeepSeek、Claude 等主流 LLM

## 方案优势

### 成本效益

- **60-95% Token 压缩** — Headroom 的上下文压缩引擎在到达 LLM 之前分析并压缩工具输出、文件内容、对话历史和日志，大幅降低 Token 消耗，不影响回答质量。
- **开源，零许可费** — OpenCode 和 Headroom 均为开源项目。无按席位许可成本，无供应商锁定。团队可以自由自托管、定制和扩展。
- **按需付费** — 在华为云 Flexus X 实例上部署，支持按需计费。根据实际团队需求弹性扩缩。

### 开发者体验

- **终端原生工作流** — OpenCode 直接在终端中运行，自然融入现有开发流程。无需 IDE 插件或浏览器扩展。
- **多模型支持** — 通过简单的配置更改即可在 DeepSeek、Claude 等模型间切换。为每项任务选择最合适的模型。
- **AST 感知压缩** — Headroom 在抽象语法树层面理解代码结构，实现对 Python、JavaScript、TypeScript、Go、Rust、Java 和 C++ 的智能压缩。
- **可逆压缩** — 压缩的上下文可按需解压。如果 LLM 需要原始数据，可通过 `headroom_retrieve` 机制获取。

### 企业就绪

- **数据主权** — 所有代码和数据在 ECS 实例本地处理。除压缩后的 API 调用外，无数据离开实例。
- **内置监控** — 提供 Prometheus 兼容指标端点（`/metrics`）、实时统计（`/stats`）和历史分析（`/stats-history`）用于运维可见性。
- **安全组隔离** — 部署在隔离的 VPC 中，安全组规则可配置。SSH 和代理端口显式控制。

## 架构与部署

### 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                    华为云 ECS 实例                        │
│                                                          │
│  ┌──────────────┐    ┌──────────────────┐               │
│  │  OpenCode     │───>│  Headroom 代理   │               │
│  │  CLI 工具     │    │  (端口 8787)     │               │
│  │               │    │                  │               │
│  │ opencode.json │    │ 上下文压缩引擎    │               │
│  │ → baseURL:    │    │ (60-95%)         │               │
│  │   localhost   │    │                  │               │
│  │   :8787       │    └────────┬─────────┘               │
│  └──────────────┘              │                          │
└────────────────────────────────┼──────────────────────────┘
                                 │
                                 ▼
                    华为云 MaaS API
                    (api.modelarts-maas.com)
                                 │
                                 ▼
                     LLM 推理服务
                    (DeepSeek / Claude / ...)
```

### 数据流

1. 开发者在 OpenCode CLI 中输入提示或命令
2. OpenCode 将请求发送至 `http://localhost:8787`（Headroom 代理）
3. Headroom 分析上下文载荷，压缩冗余数据（工具输出、文件读取、对话历史）
4. 压缩后的请求转发至华为云 MaaS API
5. MaaS 路由至配置的 LLM 进行推理
6. 响应经 Headroom 返回至 OpenCode
7. 开发者在终端中看到响应

### 部署资源

| 资源 | 规格 | 用途 |
|----------|--------------|---------|
| Flexus X ECS | x1.2u.4g, Ubuntu 24.04, 40GB 系统盘 | 运行 Headroom + OpenCode |
| VPC + 子网 | 172.16.0.0/16, 172.16.1.0/24 | 隔离网络 |
| 安全组 | ICMP, SSH(22), 代理(8787) | 访问控制 |
| 弹性 IP | 300Mbit/s, 按流量计费 | 公网访问 |

## 应用场景

### 场景 1：日常 AI 辅助开发

开发者使用 OpenCode 进行代码补全、重构建议和缺陷修复。Headroom 压缩多轮对话中积累的重复上下文（文件内容、搜索结果），在不影响代码质量的前提下将 Token 成本降低 60-80%。

**典型节省：** 60-80% Token 缩减 | **推荐模型：** `deepseek-v3.2`

### 场景 2：大型代码库探索

探索不熟悉的代码库时，开发者需要阅读大量文件并进行多次搜索。Headroom 的 AST 感知压缩在此场景下尤为有效，在保留代码结构和语义的同时，文件内容压缩率可达 88%。

**典型节省：** 85-92% Token 缩减 | **推荐模型：** `deepseek-v3.2`

### 场景 3：复杂架构设计

对于需要深度推理的任务（系统设计、复杂重构），团队可切换到 Claude 等更强大的模型。Headroom 确保即使这些昂贵的模型调用也能实现成本优化。

**典型节省：** 70-85% Token 缩减 | **推荐模型：** `claude-sonnet-4-20250514`

### 场景 4：日志分析与调试

调试通常涉及阅读大量日志文件。Headroom 在日志内容上实现最高的压缩率（92%），使 AI 用于日志分析极具成本效益。

**典型节省：** 90-95% Token 缩减 | **推荐模型：** `deepseek-v3.2`

## 相关方案

| 方案 | 描述 | 适用场景 |
|----------|-------------|----------|
| Headroom + Claude Code | Headroom 压缩 + Anthropic 官方 Claude Code CLI | 偏好 Anthropic 官方工具的团队 |
| ModelArts MaaS | 华为云模型即服务平台 | 无需代理直接访问 LLM API |
| Flexus X 实例 | 华为云灵活计算服务 | 通用开发服务器 |

## 服务亮点

### 一键部署

整个方案——ECS 实例、Headroom 代理、OpenCode CLI 及所有依赖——通过华为云解决方案实践一键部署，无需手动配置服务器、管理依赖或编辑配置文件。

### 按需付费经济性

- **基础设施：** Flexus X 实例，新加坡区域起步 ~USD 38.50/月
- **Token 费用：** 按实际 MaaS 用量计费，经 Headroom 压缩后降低 60-95%
- **软件：** 开源 — OpenCode 和 Headroom 均无需许可费

### 运维简便性

- **内置健康检查：** `curl http://localhost:8787/readyz`
- **实时监控：** `curl http://localhost:8787/stats`
- **Prometheus 集成：** `curl http://localhost:8787/metrics`
- **日志管理：** 所有启动和代理日志集中在 `/var/log/`

### 支持与资源

- [OpenCode 文档](https://opencode.ai) — 配置和使用指南
- [Headroom GitHub](https://github.com/chopratejas/headroom) — 源代码和基准测试
- [华为云 MaaS](https://support.huaweicloud.com/model-call-maas/model-call-060.html) — API 设置指南
- [华为云解决方案实践](https://solution.huaweicloud.com/) — 部署门户
