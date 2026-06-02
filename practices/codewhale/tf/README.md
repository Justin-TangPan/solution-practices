# CodeWhale — DeepSeek V4 AI 编程助手 一键部署

## 方案概述

基于华为云 Flexus 云服务器 X 实例，一键部署 CodeWhale — 面向 DeepSeek V4 的终端原生 AI 编程智能体（Coding Agent）。单二进制文件，零运行时依赖，国内 OBS 加速分发，部署仅需约 2 分钟。

## 方案架构

```
┌─────────────────────────────────────────────────┐
│                   互联网                          │
└────────────┬────────────────────────┬────────────┘
             │ HTTP/HTTPS              │ SSH (22)
             ▼                        ▼
┌──────────────────────┐  ┌────────────────────────┐
│   EIP (弹性公网 IP)    │  │   Cloud Shell / 本地    │
│   5-bgp, 10Mbit/s    │  │   SSH 客户端            │
└──────────┬───────────┘  └───────────┬────────────┘
           │                          │
           ▼                          ▼
┌──────────────────────────────────────────────────────┐
│              Flexus X 实例 (x1.2u.4g)                  │
│  ┌──────────────────────────────────────────────────┐ │
│  │  Ubuntu 24.04 LTS                                │ │
│  │  ┌─────────────────┐  ┌──────────────────────┐  │ │
│  │  │  codewhale CLI   │  │  codewhale API Server │  │ │
│  │  │  (交互式 TUI)     │  │  (HTTP/SSE, systemd)  │  │ │
│  │  └─────────────────┘  └──────────────────────┘  │ │
│  │  ODS 60GB SAS                                    │ │
│  └──────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

**部署资源清单**：

| 资源 | 规格 | 数量 | 说明 |
|------|------|:----:|------|
| Flexus 云服务器 X 实例 | x1.2u.4g (2vCPUs 4GiB) | 1 | 运行 CodeWhale CLI |
| 弹性公网 IP EIP | 5-bgp, 10Mbit/s, 按流量计费 | 1 | SSH 登录 + API 服务 |
| 虚拟私有云 VPC | 172.16.0.0/16 | 1 | 网络隔离 |
| VPC 子网 | 172.16.1.0/24 | 1 | 内网通信 |
| 安全组 | - | 1 | 开放 SSH(22) + ICMP |

## 适用场景

- 需要通过 DeepSeek V4 进行 AI 辅助编程的开发团队
- 需要本地化 AI 编程工具的企业开发者
- 对代码自主权和数据安全有要求的开发环境
- 需要终端原生交互的非 GUI 开发场景（服务器/容器内开发）

## 方案优势

- **OBS 加速分发**：预编译二进制托管在华为云 OBS，国内 ECS 高速下载，GitHub 回退兜底
- **零依赖安装**：单 Rust 二进制文件，无需 Docker/Node.js/Python 运行时
- **DeepSeek V4 原生优化**：百万 token 上下文、前缀缓存感知、思考模式流式推理
- **三种操作模式**：Plan（只读调查）/ Agent（交互审批）/ YOLO（自动执行）
- **MIT 开源协议**：36k Stars，社区活跃，持续更新

## 部署指南

### 前置条件

- 已有华为云账号，且账户余额充足（预估费用约 0.5-1 元/小时）
- 已开通 RFS（资源编排服务）
- 已获取 DeepSeek API Key（[platform.deepseek.com](https://platform.deepseek.com/api_keys)）

### 一键部署

1. 登录华为云 RFS 控制台 → 创建资源栈
2. 上传模板 `deploying-codewhale.tf.json`（或使用模板 URI）
3. 配置部署参数（见下方参数表）
4. 单击"一键部署"
5. 等待部署完成（约 2 分钟）

### 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `vpc_name` | `codewhale-demo` | VPC 名称前缀 |
| `security_group_name` | `codewhale-demo` | 安全组名称前缀 |
| `ecs_name` | `codewhale-demo` | ECS 名称前缀 |
| `ecs_flavor` | `x1.2u.4g` | ECS 规格，按需调整 |
| `ecs_password` | （必填） | ECS root 密码，8-26位，3种字符 |
| `system_disk_size` | `60` | 系统盘大小（GB） |
| `bandwidth_size` | `10` | 带宽大小（Mbit/s） |
| `charging_mode` | `postPaid` | 计费模式：按需/包月 |

## 开始使用

部署完成后 SSH 登录服务器：

```bash
# SSH 登录（IP 在部署输出中获取）
ssh root@<EIP>

# 配置 API Key（必需）
export DEEPSEEK_API_KEY="你的密钥"
codewhale auth set --provider deepseek

# 启动交互式 TUI
codewhale

# 一次性任务
codewhale "写一个 Python 脚本来分析 CSV 数据"

# 自动模式
codewhale --yolo "优化这个函数"

# 启动 API Server（可选，后台运行）
export DEEPSEEK_API_KEY="你的密钥"
systemctl enable --now codewhale
```

## 预估费用

| 资源 | 规格 | 按需（元/小时） | 包月（元/月） |
|------|------|:--------------:|:------------:|
| Flexus X 实例 | x1.2u.4g | ~0.4-0.8 | ~180-250 |
| 弹性公网 IP | 10Mbit/s 按流量 | ~0.1（流量另计） | ~20（不含流量） |
| 系统盘 | 60GB SAS | - | ~30 |
| **合计** | | **~0.5-1 元/小时** | **~230-300 元/月** |

> 实际费用以华为云控制台显示为准。建议使用按需计费测试，长期使用切换为包月。

## 快速卸载

1. 登录华为云 RFS 控制台
2. 找到对应资源栈
3. 单击"删除资源栈"→ 输入 "Delete" → 确认

卸载会自动释放所有资源（ECS、EIP、VPC、安全组），不会产生残留费用。

## 更多资源

- [CodeWhale GitHub](https://github.com/Hmbown/CodeWhale) — 源码与文档
- [DeepSeek 平台](https://platform.deepseek.com/) — API Key 管理
- [华为云 RFS](https://support.huaweicloud.com/rfs/) — 资源编排服务文档
