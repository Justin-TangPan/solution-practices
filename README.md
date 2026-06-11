# Solution Implementations - 解决方案实践仓库

## 📖 项目简介

本仓库是一个基于华为云的解决方案实践集合，提供了多种 AI 工具和平台的一键部署方案，包括：
- Headroom-ClaudeCode (AI 代码助手)
- LiteLLM (多模型 API 网关)
- OpenHands (AI 开发助手)
- Supabase (开源后端即服务)
- CodeWhale (代码智能分析)
- AiToEarn (AI 收益系统)

所有方案都遵循统一的目录结构和最佳实践，支持国内 (CN) 和香港 (HK) 区域部署。

---

## 🗂️ 项目结构

```
solution-implementations/
├── practices/                # 实践方案目录
│   ├── aitoearn/             # AiToEarn 实践
│   ├── codewhale/            # CodeWhale 实践
│   ├── headroom-claude-code/ # Headroom-ClaudeCode 实践
│   ├── litellm/              # LiteLLM 实践
│   ├── openhands/            # OpenHands 实践
│   └── supabase/             # Supabase 实践
│       ├── cn/               # 国内区域部署
│       │   ├── Shell脚本/    # Shell 自动化脚本
│       │   ├── Terraform脚本/# Terraform 部署模板
│       │   ├── 业务文档（方案详情）/
│       │   └── 技术文档（部署指南）/
│       └── hk/               # 香港区域部署
├── release/                  # 发布包管理
│   ├── headroom-claude-code/
│   └── litellm/
├── reports/                  # SAC 方案报告
│   └── headroom-claude-code/
├── reference/                # 参考文档
│   ├── doc/                  # 文档模板
│   ├── common-patterns.md    # 常见部署模式
│   ├── evaluation-methodology.md
│   └── terraform-resource-catalog.md
├── scripts/                  # 自动化工具脚本
│   ├── gen_docx.py           # 文档生成脚本
│   ├── gen_sac_docx.py       # SAC 文档生成
│   └── validate_template.py  # 模板验证
├── skills/                   # AI 技能定义
│   ├── huaweicloud-rfs-practices/ # 核心技能
│   └── ...
├── assets/                   # 模板与示例
│   ├── demo/                 # 演示方案
│   ├── templates/            # 基础模板
│   └── extension-samples/
└── README.md                 # 本文件
```

---

## 🚀 快速开始

### 使用方案进行部署

每个实践方案都包含以下内容：

1. **技术文档（部署指南）**：详细的部署步骤和说明
2. **业务文档（方案详情）**：方案的业务价值和功能介绍
3. **Shell 脚本**：自动化安装和配置脚本
4. **Terraform 模板**：一键式基础设施即代码部署

进入任意 `practices/[方案名]/[区域]/` 目录，按照 README 进行部署即可。

### 使用 AI 技能

本仓库集成了多个 AI 技能，可以通过 Trae 或 Claude Code 直接调用：

- `huaweicloud-rfs-practices`：核心实践生成技能，用于创建和优化华为云 RFS 方案
- `ai-solution-page-enhance`：方案页面增强
- `deep-search-and-insight-synthesize`：深度搜索和洞察综合

---

## 📋 方案清单

| 方案名称 | 描述 | 支持区域 |
|---------|------|---------|
| **Headroom-ClaudeCode** | Claude 代码助手平台 | CN / HK |
| **LiteLLM** | 多模型 API 网关，支持统一接入多种大模型 | CN / HK |
| **OpenHands** | AI 驱动的开发助手平台 | CN |
| **Supabase** | 开源 Firebase 替代品，后端即服务 | CN |
| **CodeWhale** | 智能代码分析平台 | CN |
| **AiToEarn** | AI 收益系统 | CN / HK |

---

## 🔧 开发工具

### 脚本工具

```bash
# 验证模板结构
python scripts/validate_template.py ./path/to/solution/

# 生成 Word 文档
python scripts/gen_docx.py ./path/to/solution/

# 生成 SAC 报告
python scripts/gen_sac_docx.py ./path/to/solution/
```

### 文档模板

参考 `reference/doc/` 目录下的标准模板：
- `业务文档模板-解决方案实践.md`
- `技术文档模板-支持中心.md`

---

## 📚 参考资源

- [Terraform 资源速查](reference/terraform-resource-catalog.md)
- [解决方案标准规范](reference/solution-standards.md)
- [Extension 格式说明](reference/extension-format.md)
- [常见部署模式](reference/common-patterns.md)

---

## 📝 更新日志

详细版本变更请查看项目根目录下的 `log/version.log` 文件。

---

## 🌟 贡献指南

欢迎贡献新的方案实践！请遵循以下结构：
1. 在 `practices/` 下创建新目录
2. 遵循标准的 4 子目录结构（技术文档、业务文档、Shell脚本、Terraform脚本）
3. 同时提供 CN 和 HK 区域支持（如适用）
4. 提交 PR 或联系维护者

---

## 📄 许可证

本仓库中的方案仅供学习和参考使用。
