# Skill Status Contract

Skills are project knowledge assets. Runtime routing lives in `AGENTS.md` and `.codex/agents/`; each
`SKILL.md` owns its behavior, while `skills-index.json` is discovery and audit metadata only. SKILL
frontmatter contains only `name` and `description` so discovery metadata stays minimal.

Current classification:

| Skill | Status | Scope |
|---|---|---|
| `sac-project-rules` | formal | formal-delivery |
| `sac-rfs-practices` | formal | formal-delivery |
| `sac-technical-evaluator` | formal | research |
| `sac-testing` | formal | formal-delivery |
| `sac-security` | formal | formal-delivery |
| `sac-documentation` | formal | formal-delivery |
| `sac-document-pipeline` | deprecated alias | compatibility |
| `sac-delivery` | formal | formal-delivery |
| `sac-business-evaluator` | optional | research |
| `sac-page-enhance` | optional | content |
| `sac-deep-search` | optional | research |

Formal skills must not assume that historical or removed practices still exist. The current formal list comes from `project.config.json`.

`sac-documentation` is the sole formal documentation entry for maintenance, generation, translation,
optional DOCX rendering, conversion, and quality gates. `sac-document-pipeline` is a compatibility alias
and is never loaded beside it. `sac-page-enhance` is loaded only for explicit page-copy work.
