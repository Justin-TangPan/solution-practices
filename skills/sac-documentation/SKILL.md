---
name: sac-documentation
description: Create and verify SAC deployment guides and solution-details documents for China and international sites, including zh-cn/en-us parity, required naming, parameter accuracy, architecture descriptions, and template-to-document consistency. Use when writing, translating, reviewing, or updating formal SAC documentation.
---

# SAC Documentation

Derive documentation from the verified implementation; never invent deployment behavior, parameters,
URLs, ports, versions, or availability.

## Required inputs

Read `skills/sac-project-rules/SKILL.md`, the target Terraform and `.extension`, and
`skills/reference/doc-templates.md`. Use `reference/docs/部署指南模板-华为云标准.md` when the full
formal template is required.

## Workflow

1. Identify site, locale, supported regions, variants, application version, access URL, ports, and prerequisites.
2. Extract variables, defaults, validation constraints, outputs, health checks, security notes, and cleanup
   behavior from the actual template.
3. Create the required site-level documents with `_zh` or `_en` names defined by project rules.
4. For `intl`, maintain both `zh-cn` and `en-us`; translate prose while preserving steps, values, warnings,
   tables, and technical behavior.
5. Compare all facts against implementation after writing. Report implementation/document conflicts to the
   parent Agent instead of changing infrastructure silently.

## Quality gate

Require navigable headings, reproducible deployment steps, parameter explanations, access verification,
troubleshooting, security cautions, cleanup instructions, and revision information. Do not claim successful
cloud validation unless the exact candidate has explicit evidence.

Return files created or updated, implementation facts checked, locale parity status, and unresolved conflicts.
