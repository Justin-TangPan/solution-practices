# Contributing to SAC Solution Practice

感谢您考虑为 SAC 项目贡献代码！本文档提供了贡献指南。

## 项目概述

SAC (Solution Practices) 是一个华为云解决方案实践仓库。核心工作流：
1. AI 架构师评估方案可行性
2. AI 开发生成 Terraform 模板 + 安装脚本
3. AI 测试验证模板语法
4. AI 安全审查风险
5. AI 文档生成部署指南
6. AI 交付打包归档

## 目录结构规范

每个实践方案遵循以下目录结构：

```
practices/{solution-name}/
├── {region}/                          # 区域代码 (cn, intl)
│   ├── {deploy-type}/                # 部署类型 (standard, ha)
│   │   ├── terraform/                # Terraform 模板
│   │   │   ├── versions.tf           # Provider 版本声明
│   │   │   ├── providers.tf          # Provider 配置（无硬编码AK/SK）
│   │   │   ├── variables.tf          # 变量定义（含description）
│   │   │   ├── main.tf               # 主资源定义
│   │   │   └── outputs.tf            # 输出定义（可选）
│   │   ├── scripts/                  # 安装脚本
│   │   │   └── install_{name}.sh     # 安装部署脚本
│   │   └── .extension                # RFS 界面配置文件
│   └── docs/                         # 文档
│       ├── {Solution-部署指南}.md     # 部署指南
│       └── Solution-Details.md       # 方案详情
└── intl/                             # 国际站（同上结构）
```

## 开发流程

### 1. 新方案提交流程

```bash
# 从 litellm 模板复制（最成熟的方案）
cp -r practices/litellm/cn/cn-north-4 practices/my-app/cn/cn-north-4

# 修改模板内容
# 编辑 terraform/deploying-my-app.tf
# 编辑 scripts/install_my_app.sh

# 运行测试验证
python -m scripts.tests.runner --practice my-app

# 提交
git add practices/my-app/
git commit -m "feat: add my-app practice (cn-north-4)"
```

### 2. 代码规范

**Terraform 规范：**
- 所有密码/密钥变量必须设置 `sensitive = true`
- 安全组规则必须限制源 IP，不允许 `0.0.0.0/0`
- 变量必须包含 `description` 字段
- Region 代码统一使用标准命名（`cn-north-4`、`ap-southeast-1`）

**Shell 脚本规范：**
- 必须包含 `set -euo pipefail`
- 必须包含健康检查步骤
- 必须使用 `mkdir -p` 确保幂等性
- 禁止硬编码密码/Token
- 禁止 `curl | bash` 高危管道安装
- 日志输出到 `/var/log/{app}-deploy/`

### 3. 提交信息格式

```
<type>: <简短描述> (<version>)

- <具体改动 1>
- <具体改动 2>

Co-Authored-By: Claude <noreply@anthropic.com>
```

类型：`feat` / `fix` / `refactor` / `test` / `docs` / `chore`

### 4. 测试

提交前运行：
```bash
# 全量测试
python -m scripts.tests.runner --json

# 只测试你的方案
python -m scripts.tests.runner --practice my-app
```

## 安全注意事项

- **不要** 在代码中提交真实 AK/SK 或密码
- **不要** 提交 `.tfvars` 文件到仓库
- 敏感信息应通过环境变量或 RFS 参数传递
- 发现安全漏洞请直接联系维护者

## 问题反馈

提交 Issue 时请包含：
- 方案名称和区域
- 具体错误信息
- `python -m scripts.tests.runner --practice <name>` 的输出
