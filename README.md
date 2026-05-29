# 华为云解决方案实践生成器

## 简介

本工具集用于生成华为云解决方案实践 — 基于 RFS (Resource Formation Service) + Terraform 的一键部署模板体系。

## 目录结构

```
huaweicloud-rfs-deploy/
├── .claude/
│   └── skills/
│       └── huaweicloud-rfs-deploy.md      # 主技能定义 — AI 核心执行逻辑
├── reference/                              # 参考文档
│   ├── terraform-resource-catalog.md       # TF 资源分类速查
│   ├── template-specification.md           # RFS 模板规范
│   ├── extension-format.md                 # .extension 文件格式
│   ├── solution-standards.md               # 解决方案发布标准
│   ├── common-patterns.md                  # 常见部署模式
│   └── evaluation-methodology.md           # 8 维度技术评估方法论
├── scripts/                                # 自动化脚本
│   ├── validate_template.py                # 模板结构验证器
│   ├── generate_extension.py               # .extension 文件生成器
│   └── package_solution.sh                 # 解决方案打包脚本
├── assets/                                 # 模板与示例
│   ├── templates/
│   │   ├── basic/                          # 基础单节点模板
│   │   ├── web-application/                # Web 应用模板（ECS+ELB+RDS）
│   │   └── cluster/                        # 集群部署模板
│   ├── extension-samples/                  # .extension 配置示例
│   └── samples/                            # 完整方案示例
│       ├── hermesagent_install.sh          # Hermes Agent 安装脚本
│       └── solution-evaluation-report.md   # 全维度技术评估报告样例
└── README.md                               # 本文件
```

## 使用方式

### 1. 直接调用 AI 技能

**模板生成模式**：
触发关键词："创建一个华为云解决方案实践"、"生成RFS部署模板"、"写一个一键部署方案"

AI 流程：
1. 需求理解 → 2. 架构设计 → 3. TF 模板生成 → 4. .extension 配置 → 5. userdata 脚本 → 6. 文档生成 → 7. 验证 → 8. 打包

**技术评估模式**：
触发关键词："技术评估"、"方案评审"、"可行性评估"、"架构评审"、"评估这个方案"

AI 流程：
1. 方案解析 → 2. 8 维度逐项评审 → 3. 瓶颈识别 → 4. 评分汇总 → 5. 优化建议 → 6. 报告输出

### 2. 手动验证

```bash
# 验证模板结构
python scripts/validate_template.py ./my-solution/

# 生成 .extension
python scripts/generate_extension.py ./my-solution/

# 打包
bash scripts/package_solution.sh ./my-solution/
```

## 关键规则

- Provider source: `huawei.com/provider/huaweicloud`（RFS 要求）
- 禁止在模板中硬编码 AK/SK，通过环境变量传入
- .extension 分组 key 需与 metadata.group 值对应
- 包内不得包含 .tfvars 文件
- 所有文件 UTF-8 编码，.tf.json 不含 BOM
