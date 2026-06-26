# Claude Code + Headroom，更省的编程助手 — 一键部署

## 方案概述

### 应用场景

本方案面向使用 Claude Code 进行 AI 辅助编程的开发者，通过部署 [Headroom](https://github.com/chopratejas/headroom) 上下文压缩代理，解决以下核心痛点：

- **上下文溢出** — 长对话、大文件读取、多轮工具调用导致上下文窗口快速填满，被迫中断会话
- **Token 成本过高** — 每轮对话携带完整上下文（含历史消息），代码文件动辄数千行，Token 线性增长

Headroom 作为代理层，坐在 Claude Code 和大模型 API 之间，自动压缩工具输出、文件内容、对话历史和日志，在数据到达模型之前完成优化。实测压缩率 60-95%，答案质量不降。

### 方案架构

```
用户终端
  │
  ▼
Claude Code CLI（ECS 上）
  │ ANTHROPIC_BASE_URL=http://localhost:8787
  ▼
Headroom Proxy（本地后台进程，端口 8787）
  │ 压缩上下文 60-95%
  │ ANTHROPIC_TARGET_API_URL=https://api.modelarts-maas.com/anthropic
  ▼
华为云 MaaS API
  │
  ▼
模型推理（DeepSeek / Claude / ...）
```

**关键配置：**

| 配置项 | 值 | 作用 |
|--------|-----|------|
| `ANTHROPIC_BASE_URL` | `http://localhost:8787` | Claude Code → Headroom 代理 |
| `ANTHROPIC_TARGET_API_URL` | `https://api.modelarts-maas.com/anthropic` | Headroom 代理 → MaaS 上游 |
| `ANTHROPIC_AUTH_TOKEN` | MaaS API Key | 认证凭据 |
| `ANTHROPIC_MODEL` | `deepseek-v3.2` | 使用的模型 |

**部署资源：**

| 资源 | 说明 |
|------|------|
| 弹性公网 IP（EIP） | 提供公网访问能力，用于 SSH 登录和 API 调用 |
| Flexus 云服务器 X 实例（ECS） | 部署 Headroom 代理和 Claude Code |
| 安全组 | 放行 SSH(22)、Headroom 代理(8787)、ICMP |
| VPC + 子网 | 提供隔离的虚拟网络环境 |

### 方案优势

- **节省 60-95% Token** — 真实 Agent 工作负载实测，代码搜索场景从 17,765 Token 压缩到 1,408
- **零代码改动** — 代理透明接入，Claude Code 无感知，无需修改任何代码
- **可逆压缩** — 原始数据本地保存，模型可通过 `headroom_retrieve` 按需取回
- **AST 感知** — 支持 Python、JS、TS、Go、Rust、Java、C++ 语法树级智能压缩
- **内置监控** — `/stats`、`/metrics`（Prometheus）、`/stats-history` 端点开箱即用
- **一键部署** — Headroom 代理 + Claude Code 预装，添加 API Key 即可使用
- **企业级安全** — 数据本地处理，不出域，支持私有化部署

### 约束与限制

- 使用前需注册华为云账号，开通华为云并进行实名认证。
- 账户不得处于欠费或冻结状态。
- 需在 ModelArts 平台开通 MaaS 服务并获取 API Key。
- Claude Code 需通过 SSH 登录 ECS 后在终端中使用，非 Web 界面。
- Headroom 压缩效果因工作负载而异，日志密集型场景压缩率最高（92%），代码探索场景约 47%。

## 资源和成本规划

本方案部署以下资源，费用仅供参考，具体请查看[华为云定价中心](https://www.huaweicloud.com/pricing/calculator.html#/ecs)。

### 按需计费

| 华为云服务 | 资源名称 | 配置 | 数量 | 每月预估花费 |
|-----------|---------|------|------|------------|
| 虚拟私有云 VPC | headroom-claude-code-vpc | 172.16.0.0/16，华北-北京四 | 1 | 0.00 元 |
| 子网 Subnet | headroom-claude-code-subnet | 172.16.1.0/24 | 1 | 0.00 元 |
| 安全组 SecurityGroup | headroom-claude-code-sg | 放行 ICMP、22、8787 端口 | 1 | 0.00 元 |
| Flexus 云服务器 X 实例 | headroom-claude-code-ecs | x1.2u.4g，Ubuntu 24.04，40GB 高 IO | 1 | ≈233.60 元 |
| 弹性公网 IP EIP | headroom-claude-code-eip | 动态 BGP，300Mbit/s，按流量计费 0.80 元/GB | 1 | ≈44 元（视流量） |
| **合计** | — | — | — | **≈277.60 元 + 流量费** |

> MaaS 的 Token 费用另计，按实际使用量计费。Headroom 可将此费用降低 60-95%。

### ROI 计算

以 10 人研发团队为例：

| 项目 | 优化前 | 优化后 | 节省 |
|------|-------|-------|------|
| 月 Token 费用 | ¥10,000 | ¥1,000 - ¥4,000 | ¥6,000 - ¥9,000 |
| 年 Token 费用 | ¥120,000 | ¥12,000 - ¥48,000 | ¥72,000 - ¥108,000 |
| ECS 服务器费用 | — | ¥3,331/年 | — |
| **年净节省** | — | — | **¥68,669 - ¥104,669** |

## 实施步骤

部署流程如下：

1. [准备工作](#准备工作) — 创建 RFS 委托（如需要）
2. [快速部署](#快速部署) — 通过 RFS 一键部署
3. [开始使用](#开始使用) — 配置 MaaS API Key，启动 Claude Code
4. [快速卸载](#快速卸载) — 删除资源栈，释放所有资源

## 准备工作

如果您使用新注册的华为云账号，可跳过准备工作直接进入[快速部署](#快速部署)。

如果您使用 IAM 子用户，请确认该用户已加入 admin 用户组。如未加入，请参考[IAM 权限管理](https://support.huaweicloud.com/usermanual-iam/iam_01_0001.html)授权后，完成以下准备工作。

### 创建 rf_admin_trust 委托（可选）

1. 登录华为云[管理控制台](https://console.huaweicloud.com/console/?region=cn-north-4)，将鼠标移至右上角个人账号处，单击"统一身份认证"。
2. 进入"委托"菜单，搜索 `rf_admin_trust`。
   - 如果已存在 → 跳过以下步骤
   - 如果不存在 → 继续执行步骤 3
3. 单击"创建委托"，委托名称输入 `rf_admin_trust`，委托类型选择"云服务"，输入 `RFS`，单击"完成"。
4. 单击"立即授权"。
5. 在搜索框中输入 `Tenant Administrator`，勾选搜索结果，单击"下一步"。
6. 选择"所有资源"，单击"确定"完成配置。
7. 验证：委托列表中出现 `rf_admin_trust` 即为创建成功。

## 快速部署

### 操作步骤

1. 登录华为云[解决方案实践](https://solution.huaweicloud.com/)，搜索"Headroom + Claude Code"，单击"开始部署"进入部署界面。
2. 在左侧部署按钮处单击，进入购买页面，浏览 Flexus 云服务器 X 实例配置，设置服务器密码。
3. 单击"一键部署"，系统将自动扣费，请确保账户余额充足。
4. 在事件日志中等待出现"Apply required resource success"，表示资源栈部署成功。资源栈部署成功后，部署脚本将自动执行，等待约 10 分钟（视网络环境而定）。

### 部署验证

部署完成后，SSH 登录 ECS，执行以下命令验证：

```bash
headroom --version          # 应输出版本号
claude --version            # 应输出版本号
curl http://localhost:8787/readyz  # 应返回 status: healthy
```

## 开始使用

### 第一步：开通华为云 MaaS

1. 进入 [ModelArts MaaS 控制台](https://console.huaweicloud.com/modelarts/?region=cn-southwest-2#/model-service/maas)。
2. 开通 MaaS 服务（如未开通）。
3. 创建 API Key：
   - 单击"API Key 管理" → "创建 API Key"。
   - 复制并安全保存（仅显示一次）。

> MaaS 服务托管在贵阳区域，但 API 端点为公网地址，从任何区域均可访问。

### 第二步：配置环境变量

SSH 登录 ECS，将以下内容写入 `/root/.bashrc`（替换 `your-maas-api-key` 为实际值）：

```bash
cat >> /root/.bashrc << 'EOF'
export ANTHROPIC_AUTH_TOKEN="your-maas-api-key"
export ANTHROPIC_BASE_URL="http://localhost:8787"
export ANTHROPIC_TARGET_API_URL="https://api.modelarts-maas.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v3.2"
EOF
source /root/.bashrc
```

**说明：**

| 变量 | 作用 |
|------|------|
| `ANTHROPIC_AUTH_TOKEN` | MaaS API Key，Claude Code 发请求时带上 |
| `ANTHROPIC_BASE_URL` | Claude Code 的请求发到本地代理 `localhost:8787` |
| `ANTHROPIC_TARGET_API_URL` | Headroom 代理把压缩后的请求转发到 MaaS |
| `ANTHROPIC_MODEL` | 使用的模型名称 |

### 第三步：启动 Claude Code

```bash
claude
```

Claude Code 会从环境变量读取 `ANTHROPIC_BASE_URL`，自动连接本地 Headroom 代理。

### 第四步：验证全链路

在 Claude Code 中发送任意消息（如"你好"），然后在另一个终端检查：

```bash
curl -s http://localhost:8787/stats | grep -o '"api_requests":[0-9]*'
```

预期：`api_requests` > 0，说明请求经过了 Headroom 代理。

### 第五步：切换模型（可选）

修改 `/root/.bashrc` 中的 `ANTHROPIC_MODEL`，然后 `source /root/.bashrc` 生效：

```bash
export ANTHROPIC_MODEL="claude-sonnet-4-20250514"
```

可选模型取决于您的 MaaS 订阅：

| 模型 | 特点 | 适用场景 |
|------|------|---------|
| `deepseek-v3.2` | 性价比高 | 日常编程、代码补全 |
| `claude-sonnet-4-20250514` | 推理能力最强 | 复杂重构、架构设计 |

### 第六步：查看 Token 节省量

```bash
# 实时节省统计
headroom perf

# 代理统计
curl http://localhost:8787/stats

# Prometheus 指标
curl http://localhost:8787/metrics
```

### 常用命令

```bash
# 启动 Claude Code（需先 source /root/.bashrc）
claude

# 查看代理状态
curl http://localhost:8787/health

# 查看代理统计（api_requests 应 >0）
curl http://localhost:8787/stats

# 查看代理日志
tail -f /var/log/headroom-proxy.log

# 重启代理
pkill headroom
export ANTHROPIC_TARGET_API_URL=https://api.modelarts-maas.com/anthropic
nohup headroom proxy --host 0.0.0.0 --port 8787 > /var/log/headroom-proxy.log 2>&1 &
```

## 最佳实践

### 模型选择策略

| 场景 | 推荐模型 | 原因 |
|------|---------|------|
| 日常编码、代码补全 | `deepseek-v3.2` | 性价比高，响应快 |
| 复杂重构、架构设计 | `claude-sonnet-4-20250514` | 推理能力强 |
| 代码审查、Bug 定位 | `deepseek-v3.2` | 够用且经济 |
| 跨模块分析 | `claude-sonnet-4-20250514` | 需要全局理解能力 |

### 压缩率优化

不同工作负载的压缩效果不同：

| 工作负载 | 预期压缩率 | 优化建议 |
|---------|-----------|---------|
| 代码搜索 | 92% | 无需优化，效果最佳 |
| 文件内容嵌入 | 88% | 无需优化 |
| 日志分析 | 92% | 无需优化 |
| 对话历史 | 89% | 无需优化 |
| 代码探索 | 47% | 可配合 `headroom_retrieve` 取回原文 |

### 监控告警建议

建议设置以下监控告警：

| 监控项 | 告警阈值 | 处理方式 |
|-------|---------|---------|
| 代理健康检查 | 连续 3 次失败 | 重启代理 |
| 磁盘使用率 | > 80% | 清理旧数据 |
| API 请求数 | 异常增长 | 检查是否有异常调用 |

## 常见问题

### headroom: command not found

**原因：** Ubuntu 24.04 PEP 668 阻止 pip 系统级安装。

**解决：**
```bash
pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers \
  -i https://pypi.tuna.tsinghua.edu.cn/simple \
  --break-system-packages --ignore-installed
```

### ModuleNotFoundError: No module named 'fastapi' / 'transformers'

**原因：** headroom-ai 的依赖未完全安装。

**解决：**
```bash
pip3 install fastapi uvicorn 'httpx[http2]' transformers \
  -i https://pypi.tuna.tsinghua.edu.cn/simple \
  --break-system-packages --ignore-installed
```

### Headroom proxy 启动后立即退出

**原因：** 缺少 h2 包（HTTP/2 支持）。

**解决：**
```bash
pip3 install h2 -i https://pypi.tuna.tsinghua.edu.cn/simple --break-system-packages
```

查看日志定位原因：
```bash
tail -20 /var/log/headroom-proxy.log
```

### Claude Code 发消息但 stats 没变化

**原因：** `ANTHROPIC_BASE_URL` 未注入到 Claude Code 进程环境，请求没经过代理。

**排查：**
```bash
echo $ANTHROPIC_BASE_URL    # 如果为空，说明环境变量没生效
source /root/.bashrc        # 重新加载
claude                      # 再试
```

或直接在命令行传入：
```bash
ANTHROPIC_BASE_URL=http://localhost:8787 claude
```

### 代理响应缓慢

**原因：** 网络延迟或 MaaS 服务响应慢。

**排查：**
```bash
# 检查到 MaaS 的网络延迟
ping api.modelarts-maas.com

# 查看代理日志中的延迟信息
grep "latency" /var/log/headroom-proxy.log

# 检查系统资源使用
top -bn1 | head -20
```

### 验证部署状态

```bash
headroom --version                    # Headroom CLI
claude --version                      # Claude Code
curl http://localhost:8787/readyz     # 代理健康
echo $ANTHROPIC_BASE_URL              # 应为 http://localhost:8787
echo $ANTHROPIC_TARGET_API_URL        # 应为 https://api.modelarts-maas.com/anthropic
echo $ANTHROPIC_AUTH_TOKEN             # 应为 MaaS API Key
```

## 安全建议

### 网络安全

- **限制 SSH 来源 IP**：在安全组中限制 SSH(22) 端口的来源 IP
- **不暴露代理端口**：8787 端口仅本地访问，不建议暴露到公网
- **使用 VPC**：所有资源部署在独立 VPC 中，与企业其他网络隔离

### 数据安全

- **数据本地处理**：所有代码和数据在 ECS 本地处理，不出域
- **API Key 保护**：敏感信息通过环境变量传递，不硬编码在代码中
- **定期轮换 Key**：建议定期轮换 MaaS API Key

### 访问控制

- **最小权限原则**：仅授予必要的 IAM 权限
- **审计日志**：启用 CloudTrail 记录所有 API 调用
- **多因素认证**：建议为华为云账号启用 MFA

## 快速卸载

1. 登录 [RFS 控制台](https://console.huaweicloud.com/rfs/)。
2. 找到本方案创建的资源栈，单击右侧"删除"按钮。
3. 在弹出的确认框中，删除方式选择"删除资源"，输入 `Delete`，单击"确定"完成卸载。

## 附录

### 名词解释

| 术语 | 说明 |
|------|------|
| **Flexus 云服务器 X 实例** | 华为云面向中小企业和开发者推出的新一代柔性算力云服务器 |
| **弹性云服务器 ECS** | 一种可随时自助获取、可弹性伸缩的计算服务 |
| **虚拟私有云 VPC** | 华为云上隔离的、私密的虚拟网络环境 |
| **弹性公网 IP EIP** | 提供独立的公网 IP 地址和带宽资源 |
| **Headroom** | 开源上下文压缩代理层，通过压缩工具输出、文件内容、对话历史等减少 LLM Token 消耗 |
| **Claude Code** | Anthropic 官方 CLI 编程工具，支持代码生成、重构、调试等 AI 辅助编程能力 |
| **MaaS** | Model as a Service，华为云模型即服务平台，提供多种大模型的 API 接口 |
| **AST** | Abstract Syntax Tree，抽象语法树，代码的树状结构表示 |

### 参考资源

- [Headroom GitHub](https://github.com/chopratejas/headroom) — 源码、文档、性能基准
- [Headroom 文档](https://headroom-docs.vercel.app) — 完整配置参考
- [华为云 MaaS 接入指南](https://support.huaweicloud.com/model-call-maas/model-call-060.html) — MaaS API 接入
- [Claude Code 文档](https://docs.anthropic.com/en/docs/claude-code) — Claude Code 官方文档
- [华为云 RFS](https://support.huaweicloud.com/tr-aos/rf_05_0001.html) — 资源编排服务

## 修订记录

| 发布日期 | 修订记录 |
|---------|---------|
| 2026-06-05 | 全链路验证通过，更新依赖清单和配置说明 |
| 2026-06-11 | 新增 ROI 计算、最佳实践、安全建议、更多常见问题 |

## 更多资源

- [Headroom GitHub](https://github.com/chopratejas/headroom) — 源码、文档、性能基准
- [Headroom 文档](https://headroom-docs.vercel.app) — 完整配置参考
- [华为云 MaaS 接入指南](https://support.huaweicloud.com/model-call-maas/model-call-060.html) — MaaS API 接入
- [Claude Code 文档](https://docs.anthropic.com/en/docs/claude-code) — Claude Code 官方文档
- [华为云 RFS](https://support.huaweicloud.com/tr-aos/rf_05_0001.html) — 资源编排服务
