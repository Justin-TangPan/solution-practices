# 部署 CodeWhale — DeepSeek V4 AI 编程助手 部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 01
> **发布日期：** 2026-06-26

---

## 1. 方案概述

### 1.1 应用场景

本方案在华为云 Flexus X 实例上部署 CodeWhale — 面向 DeepSeek V4 的终端原生 AI 编程智能体。单二进制文件，零运行时依赖，国内 OBS 加速分发，部署仅需约 2 分钟。

典型应用场景包括：

- **日常 AI 辅助编程** — 使用自然语言在终端中编写、重构和调试代码，支持 Plan/Agent/YOLO 三种操作模式
- **大型代码库探索** — 快速阅读和理解不熟悉的代码库，利用 DeepSeek V4 百万 Token 上下文能力
- **日志分析与调试** — 使用 AI 分析大型日志文件，快速定位问题根因
- **自动化脚本生成** — 通过自然语言描述生成 Shell、Python 等自动化脚本

### 1.2 方案架构

#### 单机部署

图 1-1 单机部署架构图

本方案部署以下资源：

- 1 x 华为云 Flexus X 实例，运行 CodeWhale CLI 和可选的 API Server
- 1 x 弹性公网 IP（EIP）关联至 ECS，提供公网 SSH 访问
- 1 x VPC 和子网，用于网络隔离

#### 数据流

1. 开发者在终端中输入提示或命令
2. CodeWhale CLI 将请求直接发送至 DeepSeek API
3. DeepSeek V4 进行推理并返回响应
4. 开发者在终端中看到响应结果

（可选）启动 API Server 后：
1. 外部客户端通过 HTTP 请求访问 CodeWhale API Server
2. API Server 转发请求至 DeepSeek API
3. 响应通过 SSE 流式返回给客户端

### 1.3 方案优势

- **OBS 加速分发** — 预编译二进制托管在华为云 OBS，国内 ECS 高速下载，GitHub Release 回退兜底
- **零依赖安装** — 单 Rust 二进制文件，无需 Docker/Node.js/Python 运行时
- **DeepSeek V4 原生优化** — 百万 Token 上下文、前缀缓存感知、思考模式流式推理
- **三种操作模式** — Plan（只读调查）/ Agent（交互审批）/ YOLO（自动执行）
- **MIT 开源协议** — 社区活跃，持续更新，无供应商锁定

### 1.4 约束与限制

- 部署前需拥有华为云账号并完成实名认证，账户余额充足。
- 若选择包年包月计费，请确保账户余额足够自动扣费，或前往"费用中心 > 待支付订单"手动支付。
- 部署完成后请等待约 2 分钟，让 CodeWhale 完成安装和初始化。
- 首次使用前需要从 DeepSeek 平台获取 API Key。
- CodeWhale 需通过 SSH 登录 ECS 后在终端中使用，非 Web 界面。

---

## 2. 资源和成本规划

> 本方案将部署如下资源，费用仅供参考，实际费用请以华为云官网价格为准。

### 2.1 单机部署

#### 表 2-1 成本预估（按需计费）

| 华为云服务 | 配置 | 数量 | 预估费用（1小时） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：按需计费<br>区域：华北-北京四<br>规格：x1.2u.4g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 60GB | 1 | 约 0.05 美元 |
| 弹性公网 IP EIP | 计费模式：按需计费<br>线路：动态 BGP<br>带宽：按流量计费<br>大小：300Mbit/s | 1 | 0.00 美元 |
| **合计** | — | — | **约 0.05 美元** |

> 预估费用仅供参考，实际费用取决于具体使用量。详细价格请参考华为云官网。

#### 表 2-2 成本预估（包年包月）

| 华为云服务 | 配置 | 数量 | 预估费用（1个月） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：包年包月<br>区域：华北-北京四<br>规格：x1.2u.4g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 60GB | 1 | 约 36.50 美元 |
| 弹性公网 IP EIP | 计费模式：按流量计费<br>线路：动态 BGP<br>带宽：300Mbit/s | 1 | 按实际流量计费 |
| **合计** | — | — | **约 36.50 美元/月 + EIP 流量费** |

> DeepSeek API 的 Token 费用另计，按实际使用量计费。

---

## 3. 实施步骤

### 3.1 准备工作

#### 3.1.1 获取 DeepSeek API Key

步骤 1 访问 [DeepSeek 开放平台](https://platform.deepseek.com/api_keys)。

步骤 2 登录账号后，进入"API Keys"页面。

步骤 3 单击"创建 API Key"，输入名称后单击"创建"。

步骤 4 复制生成的 API Key 并妥善保存，后续配置 CodeWhale 时需要使用。

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

> 本节帮助您高效完成 CodeWhale 方案部署，请按以下步骤进行一键部署。

步骤 1 单击"开始部署"，跳转至 RFS 资源编排控制台。

步骤 2 单击"下一步"，确认基础配置，并设置 ECS 密码。

**表 3-1 配置参数**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| solution_name | 解决方案名称，4-24个字符，支持小写字母、数字、-（中划线），必须以小写字母开头 | codewhale |
| ecs_flavor | 云服务器实例规格，x1.2u.4g（2vCPUs 4GiB）及以上推荐 | x1.2u.4g |
| ecs_password | 云服务器密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种 | / |
| system_disk_size | 系统盘大小（GB），高IO类型，取值范围：40-1024 | 60 |
| bandwidth_size | 弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300 | 300 |
| codewhale_version | CodeWhale 版本，支持 latest 及 v0.8.47 等 | latest |
| charging_mode | 计费模式：postPaid（按需计费）或 prePaid（包年包月） | postPaid |
| charging_unit | 订购周期类型：month（月）或 year（年），仅 prePaid 模式生效 | month |
| charging_period | 订购周期，1-9（月）或 1-3（年），仅 prePaid 模式生效 | 1 |

步骤 3 按需配置加密与权限，单击"下一步"。

步骤 4 查看资源栈内容，可选择单击"创建执行计划"预览预估费用，然后单击"直接部署资源栈"。

步骤 5 等待 `Apply required resource success`，在"输出"页签查看连接信息。请等待约 2 分钟后再使用服务。

> **注意：**
> - 若账户余额不足，请前往"费用中心 > 充值"进行充值。
> - 若包年包月自动扣费失败，请前往"费用中心 > 待支付订单"手动支付。

----结束

### 3.3 开始使用

#### 3.3.1 配置 API Key 并启动 CodeWhale

步骤 1 SSH 登录已部署的 ECS 实例（连接信息可在 RFS 输出中获取）。

步骤 2 设置 DeepSeek API Key：

```bash
export DEEPSEEK_API_KEY='your-deepseek-api-key'
source /root/.bashrc
```

> **注意：** 将 `your-deepseek-api-key` 替换为步骤 3.1.1 中获取的实际 API Key。

步骤 3 配置认证信息：

```bash
codewhale auth set --provider deepseek
```

步骤 4 启动 CodeWhale 交互式 TUI：

```bash
codewhale
```

步骤 5 验证 CodeWhale 安装状态：

```bash
codewhale --version
codewhale --help
```

步骤 6 开始使用 CodeWhale 进行 AI 辅助编程：

```bash
# 交互式 TUI
codewhale

# 一次性任务
codewhale "写一个 Python 脚本来分析 CSV 数据"

# 自动模式（无需确认）
codewhale --yolo "优化这个函数"
```

----结束

#### 3.3.2 启动 API Server（可选）

如需将 CodeWhale 作为后台 API 服务运行：

```bash
export DEEPSEEK_API_KEY='your-deepseek-api-key'
systemctl enable --now codewhale
```

API Server 默认监听 HTTP 端口，可通过 `systemctl status codewhale` 查看服务状态。

----结束

### 3.4 卸载

步骤 1 在 RFS 控制台中找到本方案创建的资源栈，单击资源栈名称旁的"删除"按钮。

步骤 2 在弹出的确认框中选择"删除资源"，输入 `Delete`，单击"确定"完成卸载。

----结束

---

## 4. 附录

### 4.1 名词解释

| 术语 | 说明 |
|------|------|
| CodeWhale | 面向 DeepSeek V4 的终端原生 AI 编程智能体，支持交互式 TUI 和 API Server 两种模式 |
| DeepSeek V4 | DeepSeek 推出的第四代大语言模型，支持百万 Token 上下文和流式推理 |
| Flexus X | 华为云 Flexus X 实例，新一代柔性算力云服务器 |
| RFS | 资源编排服务（Resource Formation Service），华为云的资源编排服务 |
| TUI | 终端用户界面（Terminal User Interface），在终端中运行的交互式界面 |
| OBS | 对象存储服务（Object Storage Service），华为云的分布式存储服务 |

### 4.2 参考链接

- [CodeWhale GitHub](https://github.com/Hmbown/CodeWhale)
- [DeepSeek 开放平台](https://platform.deepseek.com/)
- [华为云 RFS](https://support.huaweicloud.com/rfs/)

---

## 5. 修订记录

| 日期 | 修订记录 |
|---------|---------|
| 2026-06-26 | 首次发布。|
