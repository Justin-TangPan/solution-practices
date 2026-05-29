# OpenHuman 云端开发环境

## 方案概述

在华为云 Flexus X 实例上一键搭建 OpenHuman AI 开发环境，预装 Node.js 24、pnpm、Rust、Docker、Ollama 等全套开发工具链。

> **重要**：OpenHuman 是 Tauri 桌面应用，此方案提供的是 **云端开发工作站**，非 Web 服务部署。开发者通过 SSH 连接后进行开发。

## 方案架构

```
Flexus X 实例 (2u4g) Ubuntu 22.04
├── Node.js 24 + pnpm       # 前端构建
├── Rust 1.93 + rustfmt     # 核心编译
├── Docker                  # 容器化运行
├── Ollama + 小模型          # 本地 AI 推理
└── OpenHuman 源码已克隆     # /opt/openhuman
```

## 部署资源

| 资源 | 规格 | 说明 |
|------|------|------|
| Flexus X 实例 | x1.2u.4g | 2vCPU 4GB |
| 弹性公网 IP | 5Mbit/s 按流量 | SSH 管理 + Ollama API |
| VPC | /16 | 新建 VPC |
| 安全组 | 22+11434 | SSH + Ollama API |

## 部署步骤

### 一键部署（RFS）

1. 进入华为云解决方案实践库，选择本方案
2. 配置参数（密码必填，其余可默认）
3. 单击"一键部署"
4. 等待约 5-8 分钟
5. 查看 outputs 中的 SSH 连接命令

### 开始使用

```bash
# 1. SSH 连接
ssh root@{public_ip}

# 2. 进入项目目录
cd /opt/openhuman

# 3. 安装依赖（如未自动完成）
pnpm install

# 4. 启动 Web UI 开发模式
pnpm dev
```

### Ollama API 使用

OpenHuman 桌面端配置：

```yaml
# OpenHuman config.toml
[model]
endpoint = "http://{public_ip}:11434"
default_model = "qwen2.5:0.5b"
```

## 预估费用

| 资源 | 规格 | 按月预估 |
|------|------|---------|
| Flexus X | x1.2u.4g (按需) | ≈ ¥100-150 |
| EIP 带宽 | 5Mbit/s 按流量 | ≈ ¥30-50 |
| 总计 | | ≈ ¥130-200 |

## 快速卸载

1. 登录 RFS 控制台
2. 找到对应资源栈
3. 单击"删除" → 输入 "Delete" → 确认
