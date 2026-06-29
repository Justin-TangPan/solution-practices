# 部署 Headroom + Claude Code — 部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 01
> **发布日期：** 2026-06-26

---

## 1. 方案概述

### 1.1 应用场景

本方案在华为云 Flexus X 实例上部署 Headroom + Claude Code：一个开源、低成本的终端原生 AI 编程环境，通过智能上下文压缩技术将 Token 消耗降低 60-95%。

典型应用场景包括：

- **日常 AI 辅助编程** — 使用自然语言在终端中编写、重构和调试代码，Headroom 自动压缩上下文以减少 Token 消耗
- **大型代码库探索** — 快速阅读和理解不熟悉的代码库，AST 感知压缩可实现高达 88% 的文件内容压缩率
- **日志分析与调试** — 使用 AI 分析大型日志文件，Headroom 在日志内容上可实现 90-95% 的压缩率
- **架构设计与代码审查** — 在终端中进行系统设计讨论和代码审查，支持 DeepSeek、Claude 等多种模型

### 1.2 方案架构

#### 单机部署

图 1-1 单机部署架构图

本方案部署以下资源：

- 1 x 华为云 Flexus X 实例，运行 Headroom 代理和 Claude Code CLI
- 1 x 弹性公网 IP（EIP）关联至 ECS，提供公网访问
- 1 x VPC 和子网，用于网络隔离

#### 数据流

1. 开发者在终端中输入提示或命令
2. Claude Code 将请求发送至 `http://localhost:8787`（Headroom 代理）
3. Headroom 分析上下文负载，压缩冗余数据（工具输出、文件读取、对话历史）
4. 压缩后的请求被转发至华为云 MaaS API
5. MaaS 将请求路由至配置的 LLM 进行推理
6. 响应通过 Headroom 返回至 Claude Code
7. 开发者在终端中看到响应

### 1.3 方案优势

- **60-95% Token 压缩** — Headroom 的上下文压缩引擎在不降低回答质量的情况下显著减少 Token 消耗
- **开源零授权费用** — Headroom 和 Claude Code 均为开源项目，无供应商锁定
- **终端原生工作流** — Claude Code 直接在终端中运行，自然融入现有开发者工作流
- **多模型支持** — 通过简单配置更改即可在 DeepSeek、Claude 等模型之间切换

### 1.4 约束与限制

- 部署前需拥有华为云账号并完成实名认证，账户余额充足。
- 若选择包年包月计费，请确保账户余额足够自动扣费，或前往"费用中心 > 待支付订单"手动支付。
- 部署完成后请等待约 10 分钟，让 Headroom 代理和 Claude Code 完成初始化。
- 首次使用前需要从华为云 ModelArts MaaS 获取 API Key。
- Claude Code 需通过 SSH 登录 ECS 后在终端中使用，非 Web 界面。

---

## 2. 资源和成本规划

> 本方案将部署如下资源，费用仅供参考，实际费用请以华为云官网价格为准。

### 2.1 单机部署

#### 表 2-1 成本预估（按需计费）

| 华为云服务 | 配置 | 数量 | 预估费用（1小时） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：按需计费<br>区域：华北-北京四<br>规格：x1.2u.4g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 40GB | 1 | 约 0.32 元 |
| 弹性公网 IP EIP | 计费模式：按需计费<br>线路：动态 BGP<br>带宽：按流量计费<br>大小：300Mbit/s | 1 | 0.00 元 |
| **合计** | — | — | **约 0.32 元** |

> 预估费用仅供参考，实际费用取决于具体使用量。详细价格请参考华为云官网。

#### 表 2-2 成本预估（包年包月）

| 华为云服务 | 配置 | 数量 | 预估费用（1个月） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：包年包月<br>区域：华北-北京四<br>规格：x1.2u.4g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 40GB | 1 | 约 233 元 |
| 弹性公网 IP EIP | 计费模式：按流量计费<br>线路：动态 BGP<br>带宽：300Mbit/s | 1 | 按实际流量计费 |
| **合计** | — | — | **约 233 元/月 + EIP 流量费** |

> MaaS 的 Token 费用另计，按实际使用量计费。Headroom 可将此费用降低 60-95%。

---

## 3. 实施步骤

### 3.1 准备工作

#### 3.1.1 获取 MaaS API Key

步骤 1 登录华为云控制台，进入"ModelArts 模型服务"。

步骤 2 在左侧导航中选择"MaaS > API Key 管理"。

步骤 3 单击"创建 API Key"，输入名称后单击"确认"。

步骤 4 复制生成的 API Key 并妥善保存，后续配置 Headroom 时需要使用。

----结束

#### 3.1.2 创建 rf_admin_trust 委托（可选）

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

> 本节帮助您高效完成"Headroom + Claude Code"方案部署，请按以下步骤进行一键部署。

步骤 1 单击"开始部署"，跳转至 RFS 资源编排控制台。

步骤 2 单击"下一步"，确认基础配置，并设置 ECS 密码。

**表 3-1 配置参数**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| solution_name | 解决方案名称，4-24个字符，支持小写字母、数字、-（中划线），必须以小写字母开头 | headroom-claude-code |
| ecs_flavor | 云服务器实例规格，x1.2u.4g（2vCPUs 4GiB）及以上推荐 | x1.2u.4g |
| ecs_password | 云服务器密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种 | / |
| system_disk_size | 系统盘大小（GB），高IO类型，取值范围：40-1024 | 40 |
| bandwidth_size | 弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300 | 300 |
| charging_mode | 计费模式：postPaid（按需计费）或 prePaid（包年包月） | postPaid |
| charging_unit | 订购周期类型：month（月）或 year（年），仅 prePaid 模式生效 | month |
| charging_period | 订购周期，1-9（月）或 1-3（年），仅 prePaid 模式生效 | 1 |

步骤 3 按需配置加密与权限，单击"下一步"。

步骤 4 查看资源栈内容，可选择单击"创建执行计划"预览预估费用，然后单击"直接部署资源栈"。

步骤 5 等待 `Apply required resource success`，在"输出"页签查看连接信息。请等待约 10 分钟后再使用服务。

> **注意：**
> - 若账户余额不足，请前往"费用中心 > 充值"进行充值。
> - 若包年包月自动扣费失败，请前往"费用中心 > 待支付订单"手动支付。

----结束

### 3.3 开始使用

#### 3.3.1 配置 API Key 并启动 Claude Code

步骤 1 SSH 登录已部署的 ECS 实例（连接信息可在 RFS 输出中获取）。

步骤 2 设置 MaaS API Key：

```bash
export ANTHROPIC_AUTH_TOKEN='your-maas-api-key'
source /root/.bashrc
```

> **注意：** 将 `your-maas-api-key` 替换为步骤 3.1.1 中获取的实际 API Key。

步骤 3 启动 Claude Code：

```bash
claude
```

步骤 4 验证 Headroom 代理状态：

**表 3-2 Headroom 管理端点**

| 端点 | 说明 | 示例 |
|------|------|------|
| 健康检查 | 服务健康检查 | `curl http://localhost:8787/readyz` |
| 实时统计 | 实时统计信息 | `curl http://localhost:8787/stats` |
| 指标 | Prometheus 指标 | `curl http://localhost:8787/metrics` |

步骤 5 开始使用 Claude Code 进行 AI 辅助编程。Headroom 将自动压缩上下文以减少 Token 消耗。

----结束

> **注意：** Claude Code 首次启动时会自动在 `/root/.bashrc` 中配置环境变量，`ANTHROPIC_BASE_URL` 已预配置为指向 Headroom 代理地址。

### 3.4 卸载

步骤 1 在 RFS 控制台中找到本方案创建的资源栈，单击资源栈名称旁的"删除"按钮。

步骤 2 在弹出的确认框中选择"删除资源"，输入 `Delete`，单击"确定"完成卸载。

----结束

---

## 4. 附录

### 4.1 名词解释

| 术语 | 说明 |
|------|------|
| Claude Code | Anthropic 官方终端原生 AI 编程助手，支持多种 LLM 后端 |
| Headroom | 开源 AI 上下文压缩代理，可将 Token 消耗降低 60-95% |
| MaaS | ModelArts 模型即服务，华为云的模型服务平台 |
| Flexus X | 华为云 Flexus X 实例，新一代柔性算力云服务器 |
| RFS | 资源编排服务（Resource Formation Service），华为云的资源编排服务 |

### 4.2 参考链接

- [Claude Code 文档](https://docs.anthropic.com/en/docs/claude-code)
- [Headroom GitHub](https://github.com/chopratejas/headroom)
- [华为云 MaaS API 指南](https://support.huaweicloud.com/model-call-maas/model-call-060.html)
- [华为云 RFS](https://support.huaweicloud.com/rfs/)

---

## 5. 修订记录

| 日期 | 修订记录 |
|---------|---------|
| 2026-06-26 | 首次发布。|
