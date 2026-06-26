# CodeWhale — DeepSeek V4 AI 编程助手 一键部署方案

## 方案概述

基于华为云 Flexus X 实例一键部署 CodeWhale，面向 DeepSeek V4 的终端原生 AI 编程智能体。单 Rust 二进制，零运行时依赖，OBS 国内加速分发，2 分钟完成部署。

## 方案架构

单人站架构：1 x Flexus X 实例（x1.2u.4g）→ EIP 公网访问，用户 SSH 登录后直接使用 CodeWhale CLI。

## 适用场景

- 需要通过 DeepSeek V4 进行 AI 辅助编程的开发团队
- 需要本地化 AI 编程工具的企业开发者
- 对代码自主权和数据安全有要求的开发环境
- 终端原生交互的非 GUI 开发场景（服务器/容器内开发）

## 方案优势

- **OBS 加速分发**：预编译二进制托管在 OBS，GitHub 回退兜底
- **零依赖安装**：单二进制，无需 Docker/Node.js/Python
- **DeepSeek V4 原生优化**：百万 token 上下文、前缀缓存
- **三种模式**：Plan（只读）/Agent（交互）/YOLO（自动）
- **MIT 开源**：36k Stars

## 交付物

| 文件 | 说明 |
|------|------|
| `tf/deploying-codewhale.tf.json` | RFS 部署模板（VPC + EIP + ECS + 安全组） |
| `tf/.extension` | 参数分组配置（network_config / ecs_config）+ i18n 中英文 |
| `tf/README.md` | 方案文档（架构图 + 部署指南 + 参数表 + 费用预估 + 卸载） |
| `scripts/install_codewhale.sh` | 4 阶段安装脚本（systemd 托管 + 每周自动升级） |
| `codewhale-data.json` | 结构化方案数据（用于页面增强/Excel 导出） |
| `codewhale-solution.xlsx` | 方案页面增强 Excel（富文本，16 章节） |
| `codewhale-solution-package.zip` | RFS 可部署包（约 8KB） |

## 变更记录

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-05 | 初始方案：RFS 模板 + 安装脚本 + 文档 |
| v1.1 | 2026-05-30 | 优化：`.extension` 分组 + systemd 托管 + 自动升级 + 安全组补齐 + 页面 Excel |
