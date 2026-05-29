# CodeWhale — DeepSeek V4 AI 编程助手

## 方案概述

CodeWhale 是一个面向 DeepSeek V4 的开源终端 AI 编程智能体（Coding Agent），以 Rust 构建。它通过"宪法"约束机制让 AI 保持任务导向，支持 Plan（只读）/ Agent（交互）/ YOLO（自动）三种模式，自带 MCP 客户端、沙箱和 LSP 诊断能力。

该方案从 OBS 拉取预编译二进制进行本地安装，无需从 GitHub 下载，部署快速可靠。

## 方案架构

该解决方案部署以下资源：
- 1 台 Flexus 云服务器 X 实例（2vCPUs 4GiB+）：运行 CodeWhale CLI
- 1 个弹性公网 IP EIP：用于 SSH 登录

## 适用场景

- 需要通过 DeepSeek V4 进行 AI 辅助编程的开发团队
- 需要本地化 AI 编程工具的企业开发者
- 对代码自主权和数据安全有要求的开发环境

## 使用方式

部署完成后 SSH 登录服务器，即可使用：

```bash
# 配置 API Key（必需）
export DEEPSEEK_API_KEY="your-key"
codewhale auth set --provider deepseek

# 启动交互式 TUI
codewhale

# 一次性任务
codewhale "写一个 Python 脚本来分析 CSV 数据"

# 自动模式
codewhale --model auto "优化这个函数"
```

## 方案优势

- **OBS 加速分发**：预编译二进制托管在 OBS，国内 ECS 高速下载
- **零依赖安装**：单二进制文件，无需 Docker/Node/Python 运行时
- **DeepSeek V4 原生优化**：百万 token 上下文、前缀缓存、思考模式
- **三种操作模式**：Plan（只读）/ Agent（交互）/ YOLO（自动）
- **MIT 开源协议**：35.2k Stars，社区活跃
