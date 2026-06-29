# 部署 OpenHands — AI 软件开发智能体 部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 01
> **发布日期：** 2026-06-26

---

## 1. 方案概述

### 1.1 应用场景

本方案在华为云 Flexus X 实例上部署 OpenHands — 一个开源的 AI 软件开发生成式智能体平台。它能够通过自然语言指令自动完成代码编写、调试、测试、部署等软件开发任务。

典型应用场景包括：

- **AI 驱动开发** — 使用自然语言描述需求，AI 自动完成编码、调试、部署全流程
- **自动化代码审查** — 让 AI 审查代码并提出改进建议
- **快速原型开发** — 通过自然语言描述快速生成可运行的原型代码
- **多模型协作开发** — 在 Claude、GPT-4、DeepSeek 等多种模型之间灵活切换

### 1.2 方案架构

#### 单机部署

图 1-1 单机部署架构图

本方案部署以下资源：

- 1 x 华为云 Flexus X 实例，运行 OpenHands Docker 容器
- 1 x 弹性公网 IP（EIP）关联至 ECS，提供公网 Web UI 访问
- 1 x VPC 和子网，用于网络隔离

#### 数据流

1. 开发者通过浏览器访问 OpenHands Web UI
2. OpenHands 接收自然语言指令，调用配置的 LLM 进行推理
3. LLM 返回的代码/命令在沙箱环境中执行
4. 执行结果返回至 Web UI 展示给开发者

### 1.3 方案优势

- **AI 驱动开发** — 自然语言描述需求，AI 自动完成编码、调试、部署全流程
- **Web UI 访问** — 无需本地安装，浏览器即可使用完整的开发环境
- **多 LLM 支持** — 兼容 Claude、GPT-4、DeepSeek 等多种主流模型
- **Docker 容器化** — 隔离运行环境，支持 Docker-in-Docker 让 Agent 调用容器
- **开源社区活跃** — 持续更新，丰富的插件生态

### 1.4 约束与限制

- 部署前需拥有华为云账号并完成实名认证，账户余额充足。
- 若选择包年包月计费，请确保账户余额足够自动扣费，或前往"费用中心 > 待支付订单"手动支付。
- 部署完成后请等待约 10 分钟，让 Docker 镜像拉取和容器启动完成。
- 首次使用前需要在 OpenHands Web UI 中配置 LLM API Key。
- OpenHands 通过浏览器访问，支持主流现代浏览器。

---

## 2. 资源和成本规划

> 本方案将部署如下资源，费用仅供参考，实际费用请以华为云官网价格为准。

### 2.1 单机部署

#### 表 2-1 成本预估（按需计费）

| 华为云服务 | 配置 | 数量 | 预估费用（1小时） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：按需计费<br>区域：亚太-新加坡<br>规格：x1.2u.4g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 60GB | 1 | 约 0.05 美元 |
| 弹性公网 IP EIP | 计费模式：按需计费<br>线路：动态 BGP<br>带宽：按流量计费<br>大小：300Mbit/s | 1 | 0.00 美元 |
| **合计** | — | — | **约 0.05 美元** |

> 预估费用仅供参考，实际费用取决于具体使用量。详细价格请参考华为云官网。

#### 表 2-2 成本预估（包年包月）

| 华为云服务 | 配置 | 数量 | 预估费用（1个月） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：包年包月<br>区域：亚太-新加坡<br>规格：x1.2u.4g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 60GB | 1 | 约 36.50 美元 |
| 弹性公网 IP EIP | 计费模式：按流量计费<br>线路：动态 BGP<br>带宽：300Mbit/s | 1 | 按实际流量计费 |
| **合计** | — | — | **约 36.50 美元/月 + EIP 流量费** |

> LLM API 的 Token 费用另计，按实际使用量计费。

---

## 3. 实施步骤

### 3.1 准备工作

#### 3.1.1 获取 LLM API Key

OpenHands 支持多种 LLM 后端，请根据您的需求选择并获取对应的 API Key：

**选项 A：Claude API Key**
步骤 1 访问 [Anthropic 控制台](https://console.anthropic.com/)。
步骤 2 进入"API Keys"页面，单击"创建 Key"。
步骤 3 复制生成的 API Key 并妥善保存。

**选项 B：OpenAI API Key**
步骤 1 访问 [OpenAI 平台](https://platform.openai.com/api-keys)。
步骤 2 单击"创建新的密钥"。
步骤 3 复制生成的 API Key 并妥善保存。

**选项 C：DeepSeek API Key**
步骤 1 访问 [DeepSeek 开放平台](https://platform.deepseek.com/api_keys)。
步骤 2 单击"创建 API Key"。
步骤 3 复制生成的 API Key 并妥善保存。

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

> 本节帮助您高效完成 OpenHands 方案部署，请按以下步骤进行一键部署。

步骤 1 单击"开始部署"，跳转至 RFS 资源编排控制台。

步骤 2 单击"下一步"，确认基础配置，并设置 ECS 密码。

**表 3-1 配置参数**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| solution_name | 解决方案名称，4-24个字符，支持小写字母、数字、-（中划线），必须以小写字母开头 | openhands |
| ecs_flavor | 云服务器实例规格，x1.2u.4g（2vCPUs 4GiB）及以上推荐 | x1.2u.4g |
| ecs_password | 云服务器密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种 | / |
| system_disk_size | 系统盘大小（GB），高IO类型，取值范围：40-1024 | 60 |
| bandwidth_size | 弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300 | 300 |
| charging_mode | 计费模式：postPaid（按需计费）或 prePaid（包年包月） | postPaid |
| charging_unit | 订购周期类型：month（月）或 year（年），仅 prePaid 模式生效 | month |
| charging_period | 订购周期，1-9（月）或 1-3（年），仅 prePaid 模式生效 | 1 |

步骤 3 按需配置加密与权限，单击"下一步"。

步骤 4 查看资源栈内容，可选择单击"创建执行计划"预览预估费用，然后单击"直接部署资源栈"。

步骤 5 等待 `Apply required resource success`，在"输出"页签查看连接信息。请等待约 10 分钟后再使用服务（Docker 镜像拉取和启动需要时间）。

> **注意：**
> - 若账户余额不足，请前往"费用中心 > 充值"进行充值。
> - 若包年包月自动扣费失败，请前往"费用中心 > 待支付订单"手动支付。

----结束

### 3.3 开始使用

#### 3.3.1 访问 OpenHands Web UI

步骤 1 在浏览器中访问部署输出中提供的 Web UI 地址：

```
http://<EIP>:3000/
```

> **注意：** 将 `<EIP>` 替换为 RFS 输出中的弹性公网 IP 地址。

步骤 2 首次访问时，OpenHands 会引导您配置 LLM 设置：

- 选择 LLM 提供商（如 Anthropic、OpenAI、DeepSeek 等）
- 输入对应的 API Key
- 选择模型（如 claude-3-5-sonnet、gpt-4、deepseek-chat 等）

步骤 3 配置完成后，即可在对话框中输入自然语言指令，让 AI 协助完成开发任务。

步骤 4 验证 OpenHands 运行状态：

```bash
# SSH 登录 ECS
ssh root@<EIP>

# 查看容器状态
docker ps --filter name=openhands

# 查看容器日志
docker logs openhands --tail 50
```

----结束

#### 3.3.2 常用操作

**在 Web UI 中：**

- 输入自然语言描述需求，如"创建一个 Python Flask 应用，包含用户注册和登录功能"
- 上传文件让 AI 分析或修改
- 查看 AI 执行的每一步操作和输出结果
- 在设置中随时切换 LLM 提供商和模型

**在 ECS 中管理：**

```bash
# 重启 OpenHands
docker compose -f /opt/openhands/docker-compose.yaml restart

# 停止 OpenHands
docker compose -f /opt/openhands/docker-compose.yaml down

# 更新到最新镜像
docker pull docker.openhands.dev/openhands/openhands:latest
docker compose -f /opt/openhands/docker-compose.yaml up -d
```

----结束

### 3.4 卸载

步骤 1 在 RFS 控制台中找到本方案创建的资源栈，单击资源栈名称旁的"删除"按钮。

步骤 2 在弹出的确认框中选择"删除资源"，输入 `Delete`，单击"确定"完成卸载。

> **注意：** 卸载会释放所有资源（ECS、EIP、VPC、安全组），但 OpenHands 中保存的代码和配置将随 ECS 删除而丢失，请提前备份重要数据。

----结束

---

## 4. 附录

### 4.1 名词解释

| 术语 | 说明 |
|------|------|
| OpenHands | 开源 AI 软件开发生成式智能体平台，支持通过自然语言指令自动完成编码、调试、测试等任务 |
| LLM | 大语言模型（Large Language Model），如 Claude、GPT-4、DeepSeek 等 |
| Docker | 容器化平台，用于打包和运行应用程序及其依赖 |
| Docker Compose | 多容器 Docker 应用编排工具 |
| Flexus X | 华为云 Flexus X 实例，新一代柔性算力云服务器 |
| RFS | 资源编排服务（Resource Formation Service），华为云的资源编排服务 |

### 4.2 参考链接

- [OpenHands 官方文档](https://docs.all-hands.dev/)
- [OpenHands GitHub](https://github.com/All-Hands-AI/OpenHands)
- [华为云 RFS](https://support.huaweicloud.com/rfs/)

---

## 5. 修订记录

| 日期 | 修订记录 |
|---------|---------|
| 2026-06-26 | 首次发布。|
