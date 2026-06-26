# OpenHands CLI — AI 编程助手

## 方案概述

OpenHands 是一个开源的 AI 软件开发生成式 Agent 平台。它能够通过自然语言指令自动完成代码编写、调试、测试、部署等软件开发任务。支持多种 LLM 后端（Claude、GPT-4、DeepSeek 等），提供 Web UI 和命令行两种交互方式。

该方案基于华为云 Flexus 云服务器 X 实例快速部署 OpenHands Web UI，通过 systemd 服务实现开机自启。

## 方案架构

该解决方案部署以下资源：
- 1 台 Flexus 云服务器 X 实例（2vCPUs 4GiB+）：运行 OpenHands CLI Web UI
- 1 个弹性公网 IP EIP：提供 Web 控制台访问
- 1 个安全组：开放 Web UI（3000）、SSH（22）端口

## 方案优势

- **AI 驱动开发**：自然语言描述需求，AI 自动完成编码、调试、部署全流程
- **Web UI 访问**：无需本地安装，浏览器即可使用
- **多 LLM 支持**：兼容 Claude、GPT-4、DeepSeek 等多种模型
- **systemd 守护**：开机自启，掉线自动恢复

## 费用参考

| 资源 | 规格 | 预估费用 |
|------|------|----------|
| Flexus X 实例 | x1.2u.4g（2核4GB） | ~0.37元/小时 |
| 弹性公网 IP | 按流量计费 300Mbit/s | 0.80元/GB |
| **合计** | — | **极低门槛，按需付费** |

## 快速使用

部署完成后浏览器访问 `http://{EIP}:3000`，在设置页面配置 LLM API Key 即可开始使用。
