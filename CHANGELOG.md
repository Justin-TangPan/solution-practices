# Changelog

## v0.3.1 (2026-06-29) — Practice 迁移完成 & 技术债务清理

### 实践迁移
- 完成 v0.3.0 中 6 个 practice 的 `standard/` 子目录结构迁移（aitoearn、codewhale、headroom-claude-code、headroom-opencode、openhands、supabase）
- .docx → .md 文档格式迁移（部署指南）
- 删除遗留的 .extension 旧文件和空目录

### 清理
- 移除 `skills/sac-project-rules/SKILL.md` 中 sac-solution-extractor 残留引用（已合并到 sac-page-enhance）
- sac-documenter.json 描述文本精简
- `skills-vector-index.py` 增强：无依赖关键词兜底匹配 + embedding_hash 校验

---

## v0.3.0 (2026-06-26) — Skills 四层调度架构 & README 重构

### 核心架构变更

采用 **元调度层 → 技能索引层 → 动态加载层 → 执行校验层** 四层架构重构 Skills 系统，实现大 Skills 集下上下文无损、精准调度。

#### 元调度层（新增）
- 6 个 Agent JSON 统一新增 `meta_rules` 数组，包含 4 条规则：
  - **意图预检** — 查询不匹配 skill_binding 范围时跳过技能加载
  - **冲突抑制** — 多技能命中时选最高分，conflicts_with 技能不得共存
  - **递归限制** — 技能加载深度 ≤ 1 层，跨技能引用走 reference/*.md
  - **技能区生命周期** — 执行后清空技能上下文，仅保留系统指令+用户查询+滑动历史

#### 技能索引层（新增）
- **`skills-index.json`** — 集中注册 5 个技能、5 个分类、6 个 Agent 绑定，含关键词、依赖/冲突关系、merge_map
- **`skills-embeddings.json`** — 5 个 384 维向量嵌入（all-MiniLM-L6-v2 模型），支持语义相似度排序
- **`scripts/skills-vector-index.py`** — 嵌入生成脚本（支持 local/openai 双模式）

#### 动态加载层（Agent 改造）
- 6 个 Agent JSON 统一新增：`skill_index_mode: true`、`skill_binding`（primary/requires 两级绑定）、`skill_zone_config`（上下文分区参数）

### 内容去重与精简

| 文件 | 改动 | 节省 |
|------|------|------|
| `skills/sac-rfs-practices/SKILL.md` | OBS 规范→引用；区域表→引用；决策点 1-6→引用 | 1167→943 行 |
| `skills/sac-project-rules/SKILL.md` | OBS 规范→引用；区域表→引用；Agent 映射→引用 | 464→396 行 |
| `skills/sac-solution-extractor/SKILL.md` | 降级为 sac-page-enhance 薄别名，保持向后兼容 | 165→23 行 |
| `scripts/gen_xlsx.py` | 从两个 skill 子目录合并到项目根目录 | 去重 |

### 新建参考文档（跨技能共享）

- `skills/reference/obs-conventions.md` — OBS 存储规范
- `skills/reference/decision-framework.md` — 决策点框架
- `skills/reference/region-mapping.md` — 区域代码映射表

---

## v0.2.0 (2026-06-16) — 私有配置参数化 & 安全加固

- refactor: parameterize private config, fix security issues

## v0.1.9 (2026-06-16) — Headroom OpenCode & SAC 报告

- Add Headroom OpenCode practice, SAC reports, competition PPTs, and technical docs

## v0.1.6 (2026-06-11) — 架构概览更新

- Update README.md with new architecture overview

## v0.1.5 (2026-06-11) — 发布系统 & 自动化

- Major architecture refactor: add release system, automation scripts, and new practice modules

## v0.1.1 (2026-06-05) — LiteLLM & Headroom & RFS 优化

- Optimize LiteLLM structure, add Headroom practice, and refine RFS skills

## v0.1.0 (2026-06-04) — 区域重构 & LiteLLM

- Major update: Renamed demo regions, added LiteLLM practices, and enhanced RFS skills

## v0.0.3 (2026-06-02) — CodeWhale & Supabase

- Update CodeWhale practices, add Supabase support, and enhance RFS skills

## v0.0.1 (2026-05-29) — 初始版本

- Initial commit from Trae AI
