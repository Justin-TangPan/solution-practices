# SAC Solution Practices

For SAC solution creation, prototyping, audits, delivery, or explicit multi-agent requests, use the
workflow contracts under `.codex/workflows/` and the custom agents under `.codex/agents/`.

- Full delivery: `.codex/workflows/full-pipeline.md`
- Architecture prototype: `.codex/workflows/architect-develop.md`
- Quality and security audit: `.codex/workflows/audit.md`
- Local release packaging: `.codex/workflows/delivery-only.md`
- Document generation, translation, conversion, or review: `.codex/workflows/document-only.md`

Use project Skills from `.codex/skills/`; the mirrored root `skills/` tree preserves SAC's internal
reference paths. `skills-index.json` is the discovery catalog; role contracts under `.codex/agents/`
define mandatory and conditional loading. Read `skills/sac-project-rules/SKILL.md` before changing SAC assets. For an npm-installed toolkit,
use `.sac/project.config.json` as the packaged formal-scope baseline unless the host repository defines
an explicit SAC `project.config.json`. Read the role-specific Skill and contract before delegating.
Preserve existing changes, keep parallel write scopes disjoint, and
make tester/security agents read-only. Never infer permission to upload, publish, deploy cloud
resources, commit, or push. Every subagent returns `status`, `summary`, `files_changed`,
`checks_run`, `issues`, and `handoff`.
