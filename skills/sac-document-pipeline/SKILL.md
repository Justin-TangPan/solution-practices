---
name: sac-document-pipeline
description: |
  Build, translate, render, and validate SAC Deployment Guide and Solution Details documents from
  verified practice code and source materials. Use for structured document generation, zh/en
  translation, IDP Word rendering, existing Word/PDF migration, bilingual consistency checks, or
  document-only quality gates.
metadata:
  status: formal
  scope: formal-delivery
  owner: project
---

# SAC Agent Document Pipeline

将已验证的 Practice 实现和技术材料转换为统一标准稿，再确定性渲染 Markdown 与 IDP Word。
模型负责理解、改写和翻译；程序负责格式、占位符保护和静态校验。生成结果必须经过人工审核，
不得因流水线完成而自动视为可上架。

## 适用场景

- 从现有 Practice 生成部署指南和方案详情；
- 生成中国站中文、国际站中文和国际站英文文档；
- 将中文 Markdown/Word/PDF 转换为英文 IDP Word；
- 仅翻译、仅渲染 Word、重新套用模板或仅执行质量检查；
- 对 Markdown、DOCX 和中英文内容执行正式文档门禁。

页面卖点提炼和商品化表达仍由 `sac-page-enhance` 负责；本 Skill 不替代模板开发、测试、安全或
交付 Skill。

## 输入

| 参数 | 必需 | 说明 |
|---|---:|---|
| `project` | 生成 Practice 文档时是 | `practices/<project>` 下的项目 ID |
| `mode` | 否 | `generate`、`analyze`、`translate`、`render-word`、`validate` 或 `convert` |
| `input` | 转换时是 | Markdown、文本、YAML、JSON、DOCX 或 PDF；PDF 仅为离线兜底 |
| `sites` | 否 | `cn`、`intl`；默认按 Practice 已有站点 |
| `locales` | 否 | `zh-cn`、`en-us`；国际站默认两者 |
| `document_types` | 否 | `deployment-guide`、`solution-details` |
| `output_dir` | 否 | 中间产物目录；默认 `output/document-pipeline/<project>/` |
| `template` | 否 | 配置中已注册的模板名称或路径，不接受脚本内硬编码路径 |
| `glossary` | 否 | 项目级术语表；覆盖产品、云服务和全局术语 |
| `model` | 否 | 外部、内部或本地翻译/生成后端配置；未配置时不得假装调用成功 |

输入事实优先级：当前 Practice 代码与配置 > 用户提供材料 > `reference/` 规范 > `assets/` 参考
样例。参考样例只用于结构和样式，不得把其项目正文当作当前项目事实。默认跳过 `.env`、
`.secrets`、凭证文件和二进制构建产物。

## 输出

- `standard-document.json`：统一文档模型、来源和推断标记；
- 正式命名的 Markdown 与 DOCX 文件列表；
- `quality-report.json`：`pass|warning|fail`、错误、警告、信息、生成文件和检查来源；
- `manual-review.json`：技术事实、翻译、图片、敏感信息、Word 和 IDP 导入审核项。

正式文档沿用项目契约：中文正文以 `_zh` 结尾，英文正文以 `_en` 结尾：

```text
practices/<project>/cn/docs/<Name>-部署指南_zh.{md,docx}
practices/<project>/cn/docs/<Name>-方案详情_zh.{md,docx}
practices/<project>/intl/docs/zh-cn/<Name>-部署指南_zh.{md,docx}
practices/<project>/intl/docs/zh-cn/<Name>-方案详情_zh.{md,docx}
practices/<project>/intl/docs/en-us/<Name>-Deployment-Guide_en.{md,docx}
practices/<project>/intl/docs/en-us/<Name>-Solution-Details_en.{md,docx}
```

历史 Practice 未迁移时继续接受已有 Markdown；DOCX 是可配置增强产物，不改变 Terraform 或
发布路径。

## 统一文档模型

所有解析输入先进入 `DocumentModel`，不得从源材料直接自由生成复杂 DOCX。模型至少包含：

- `metadata`：项目、名称、类型、版本、站点、语言、生成时间、模型/模板版本和源文件；
- `summary`、业务背景、痛点、价值、场景和优势；
- `architecture`：概述、变体、组件、资源、数据流和架构图；
- 前置条件、资源与成本、部署、参数、验证、入门、运维、故障排查、FAQ；
- 卸载、回滚、限制、安全、参考和修订历史；
- `assets`：图片、表格和代码块；
- `review`：推断项、缺失项、人工确认项、警告和错误。

内容项尽量记录 `source_files`、`source_type`、`from_code`、`inferred`、
`requires_confirmation`、`locale`、`quality_status` 和 `confidence`。无可靠来源时使用“待人工补充”、
“待技术确认”或“缺少来源”，不得补写虚构参数、端口、命令、规格、组件或验证结果。

## 新文档执行步骤

1. 加载 `sac-project-rules`、当前 Practice、架构/开发/测试 handoff 和文档规范。
2. 离线提取 Terraform、Shell、Docker、Kubernetes、README、配置、API 和测试中的事实。
3. 扫描敏感信息；只在报告中记录位置和类型，不记录秘密值。
4. 构建并校验统一文档模型，标记来源、推断、缺失和人工确认项。
5. 生成中文部署指南和方案详情；国际站中文不得照搬中国站不可用的区域事实。
6. 保护代码、命令、变量、路径、URL、IP、端口、键名、镜像、版本和资源 ID。
7. 按“项目 > 产品 > 云服务 > 全局”术语优先级翻译英文并恢复占位符。
8. 从同一标准稿渲染 Markdown，再用配置化模板和样式渲染 DOCX。
9. 检查内容完整性、代码一致性、Markdown、Word、敏感信息及中英文对应关系。
10. 输出质量报告与人工审核清单；只有 `status=pass` 且无阻断项才可进入交付阶段。

## 存量中文文档转换

输入优先级为标准稿 > Markdown > Word > HTML > PDF。解析章节和资产后进入统一模型，再做术语
标准化、占位符保护、翻译、恢复、英文 Word 渲染和双语检查。目标是内容、结构、图片、表格、
代码和参数对应，不要求逐页一致。

PDF 仅使用离线解析器。标题、表格、图片、代码或阅读顺序无法可靠恢复时，保留原页码并生成
人工确认项；解析失败必须返回错误，不得静默猜测或调用公开在线转换站点。

## 模型、联网和离线要求

- 分析、解析、渲染和确定性检查必须可离线运行。
- 模型调用仅用于需要语义理解、正文生成或自然语言翻译的阶段，并由配置显式选择内部、本地或
  外部端点；不得写死模型名称。
- 默认不联网、不上传代码和文档。外部调用必须由调用方显式配置并符合数据策略。
- 模型不可用时保留标准稿和可完成的渲染/检查结果，返回警告或阻断错误，不得伪造翻译。

## 错误处理和质量门禁

以下情况阻止正式导出或交付：Schema 无效、必需事实或必需文档缺失、敏感信息泄露、模板缺失、
占位符不能完整恢复、DOCX 无法打开、代码/参数/URL 不一致、PDF 无法可靠解析却未标记。
缺少可选章节、低置信度排版恢复或需业务润色可以是 warning，但必须进入人工审核清单。

质量报告每项应包含严重级别、文档、章节、说明、建议和 `blocks_export`。正式门禁通过
`python -m scripts.tests.runner` 执行；单独运行 `validate` 不能绕过项目正式测试入口。

## 与其他 Skills 的关系

- 必须加载：`sac-project-rules`；
- 事实来源：架构、开发和测试 Agent 的已验证 handoff；
- 可选上游：`sac-page-enhance`，仅用于页面表达和卖点增强；
- 下游：`sac-testing` 执行正式门禁，`sac-delivery` 仅消费通过门禁的文件；
- `sac-documentation` 保留为历史 Markdown 编写兼容入口，新全链路优先使用本 Skill。

## CLI 示例

```bash
python -m scripts.document_pipeline analyze --project litellm
python -m scripts.document_pipeline generate --project litellm
python -m scripts.document_pipeline translate --project litellm
python -m scripts.document_pipeline render-word --project litellm
python -m scripts.document_pipeline validate --project litellm
python -m scripts.document_pipeline convert --input legacy.docx
```

重新排版必须从已有标准稿或 Markdown 渲染，并保持正文不变。只检查模式不得改写源文档。
