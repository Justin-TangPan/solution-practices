---
name: huaweicloud-solution-extractor
description: |
  Extract and structure content from Huawei Cloud solution implementation pages into a formatted Excel file.
  Use this skill whenever the user asks to extract, organize, or structure content from Huawei Cloud solution pages,
  wants to create a structured document from a Huawei Cloud implementation guide, mentions URLs like
  huaweicloud.com/solution/implementations/, or asks to "梳理" / "提取" / "整理" Huawei Cloud solution content.
  Also triggers on requests like "把华为云方案页内容导出为Excel" or "结构化提取华为云解决方案页面".
  Even if the user only provides a project name (e.g., "n8n", "OpenClaw"), use this skill to search and extract.
---

# Huawei Cloud Solution Content Extractor

爬取华为云解决方案实施页面（`/solution/implementations/xxx.html`），提取结构化信息写入 Excel。子标题加粗、层级分明。

**核心工具链：** `agent-browser` → `snapshot` → `WebSearch` → `gen_xlsx.py`

## 为什么不用 WebFetch？

华为云页面使用 Svelte SPA，关键内容（右侧部署面板）通过 JS 动态加载。`WebFetch` 只能拿到静态 shell，右侧面板显示"内容加载失败"。必须用 `agent-browser` 渲染完整页面，或用 `WebSearch` 兜底搜索 support 文档。

## 页面结构规律

每个方案都遵循一致的 URL 模式：
- **详情页**: `<https://www.huaweicloud.com/solution/implementations/deploying-{project}.html>`
- **部署页**: `<https://www.huaweicloud.com/solution/implementations/deploying-{project}-deploy.html>`
- **支持文档**: `<https://support.huaweicloud.com/{project}-aislt/{project}_0{1,2,4,5,6,7}.html>`

## 触发条件

- 用户要求爬取华为云解决方案页面并生成 Excel
- 提到"方案信息导出"、"提取华为云内容"、"梳理方案"
- 用户只给了项目名（如 "n8n"、"Dify"、"OpenClaw"）

## 工作流

### Phase 1: 浏览器抓取（替代 WebFetch）

1. 用 `agent-browser` 打开详情页 URL
2. `snapshot` 提取完整页面结构（JS 渲染后的 DOM）
3. 提取结构化字段：
   - 标题、简介、适用客户
   - 方案优势（标题 + 描述）
   - 架构与部署（部署方案、组件、费用、时长）
   - 应用场景
   - 解决方案实践拓展
4. 用 `agent-browser` 打开部署页 URL
5. 检查右侧面板内容。如果看到"内容加载失败"或只有空侧边栏，进入 Phase 2

### Phase 2: 支持文档兜底（部署页动态内容）

部署页右侧操作面板（方案概览 / 一键部署 / 开始使用 / 快速卸载）是 Svelte SPA 异步加载的，浏览器也未必成功渲染。此时：

1. 用 `WebSearch` 搜索：`site:support.huaweicloud.com {project} 部署 方案概述 快速部署 开始使用 快速卸载`
2. 常见的文档路径模式：
   - `_{project}_01.html` — 方案概述
   - `_{project}_02.html` — 资源和成本规划
   - `_{project}_04.html` — 准备工作
   - `_{project}_05.html` — 快速部署
   - `_{project}_06.html` — 开始使用
   - `_{project}_07.html` — 快速卸载
3. 用 `WebFetch` 抓取所有发现的文档页（文档站无 JS 反爬）
4. 搜索社区/第三方内容：`华为云 {project} 部署教程 Flexus X实例`

### Phase 3: 构建 JSON 数据

按以下 schema 构建：

```json
{
  "title": "方案标题",
  "intro": "方案简介描述",
  "customers": ["适用客户1", "适用客户2"],
  "advantages": [
    {
      "title": "优势 1：xxx",
      "content": "优势描述文字",
      "fields": {"部署时长": "5分钟", "预估费用": "2~5元"}
    }
  ],
  "architecture": [
    {
      "title": "方案一：xxx",
      "content": "方案描述",
      "fields": {
        "架构组件": "1.xxx；2.xxx",
        "预估费用": "xxx元",
        "部署时长": "x分钟",
        "费用明细": "详细计费说明"
      }
    }
  ],
  "scenarios": [
    { "title": "场景 1：xxx", "content": "xxx" }
  ],
  "extensions": [
    { "title": "关联方案 1", "content": "xxx" }
  ],
  "preparation": [
    { "title": "创建rf_admin_trust委托", "content": "步骤1-7" }
  ],
  "quick_deploy": [
    { "title": "步骤1", "content": "登录..." },
    { "title": "参数-vpc_name", "content": "类型string必填；默认值xxx" }
  ],
  "getting_started": [
    { "title": "模型配置", "content": "CLI命令..." },
    { "title": "飞书机器人配置", "content": "步骤..." }
  ],
  "quick_uninstall": [
    { "title": "步骤1", "content": "..." }
  ],
  "cost_planning": [
    { "title": "按需计费 - ECS", "content": "规格x1.8u.16g；月花费USD 195.98" }
  ]
}
```

### 字段说明

| 字段 | 来源 | 说明 |
|------|------|------|
| `title` | 详情页 | 页面标题 |
| `intro` | 详情页 | 核心介绍/副标题 |
| `customers` | 详情页 | 适用客户列表 |
| `advantages` | 详情页 | 方案优势列表 |
| `architecture` | 详情页 | 架构部署方案（可能有多个方案） |
| `scenarios` | 详情页 | 应用场景 |
| `extensions` | 详情页 | 关联解决方案 |
| `preparation` | 支持文档_04 | 准备工作（仅当存在时） |
| `quick_deploy` | 支持文档_05 | 快速部署步骤+参数表 |
| `getting_started` | 支持文档_06 | 开始使用指南 |
| `quick_uninstall` | 支持文档_07 | 快速卸载步骤 |
| `cost_planning` | 支持文档_02 | 按需/包年包月费用表 |

每个 items 数组用 `title` + 可选的 `content`（正文）和 `fields`（键值对字段）。

### Phase 4: 生成 Excel

```bash
python skill/scripts/gen_xlsx.py data.json output.xlsx
```

脚本生成格式：
- **两列**：项目、内容
- **每大类一行**，内容列用 CellRichText 实现富文本
- **子项标题加粗**独占一行，正文另起一行不加粗
- **字段标题加粗**（如"架构组件："、"预估费用："）独占一行
- **多项用序号**（1、2、3…）
- **自动换行**，内容列宽 100
- **xml:space="preserve"** 修复，确保飞书正确显示换行

## Output

交付给用户：
1. Excel 文件路径
2. JSON 数据文件路径（可二次处理）
3. 覆盖内容摘要

## Edge Cases

- **URL 返回 404**：用 WebSearch 搜索项目名定位正确 URL 和文档
- **项目未上线**：跳过页面抓取，直接 WebSearch 搜索可用文档
- **文档路径不同**：尝试 `{project}-ctf/`、`bestpractice-{product}/` 等变体
- **agent-browser 不可用**：回退到 WebFetch + WebSearch 组合
