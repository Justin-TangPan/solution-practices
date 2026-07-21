# document-only — SAC 文档专用流水线

## 输入

`project`；可选 `mode`（`generate`、`markdown`、`word`、`translate`、`convert`、
`validate`、`retemplate`）、`input`、`site`、`locale`、`output`。

## 阶段

1. 读取项目规则、`sac-documentation` 和目标 Practice；保留现有文件与目录布局。旧名
   `sac-document-pipeline` 仅映射到该 Skill，不重复加载。
2. 按模式提取项目、Markdown、Word 或 PDF，生成带来源和审核标记的统一文档模型。
3. 生成/翻译正文；翻译前保护代码、命令、参数、URL、路径和专有词。
4. 按配置分别渲染 Markdown 与 Word。`retemplate` 只改变格式，不重写正文。
5. 执行敏感信息、结构、技术事实、Word 和双语一致性检查，写结构化报告及人工审核清单。
6. error 或阻断审核项存在时停止在 `output/document-pipeline/<project>/`；通过后才允许由人工选择
   是否复制到 Practice 正式 docs 目录。IDP 导入和上架始终是人工/显式授权步骤。

## 离线与降级

- 默认离线，不上传代码或文档；外部翻译 provider 必须显式配置。
- 缺少 Word/PDF 可选依赖时保留标准稿并给出明确错误，Markdown/项目分析不受阻。
- PDF 仅为迁移兜底；无法恢复的页码、表格或图片写入待人工确认项，不静默猜测。

## 返回

`standard_document`、`markdown_files`、`docx_files`、`languages`、`quality_report`、
`errors`、`warnings`、`manual_review_items`、`ready_for_manual_review`。
