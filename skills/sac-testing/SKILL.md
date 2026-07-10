---
name: sac-testing
description: Validate SAC Solution Practices, Terraform templates, deployment scripts, directory layouts, documentation completeness, regional consistency, and release quality gates. Use for SAC test requests, pre-release validation, regression checks, audit workflows, or when a tester Agent must produce evidence-backed pass/fail results.
---

# SAC Testing

Validate the requested scope without editing it unless the parent task explicitly asks for remediation.

## Required inputs

Identify the practice, site, locale, region, variant, and whether the target is a candidate or formal
release. Read `project.config.json` and `skills/sac-project-rules/SKILL.md`. For implementation checks,
also read `skills/sac-rfs-practices/SKILL.md`.

Read `skills/reference/validation-checklist.md` for the detailed checklist. Read
`docs/contracts/practice-layout.md` and `docs/contracts/release-contract.md` when validating layout or
release readiness.

## Workflow

1. Preserve the current worktree and record the exact scope.
2. Discover deployable instances using the supported site/locale/region/variant layouts.
3. Run the formal gate with `.venv-sac/bin/python -m scripts.tests.runner` when the repository tooling
   is available. Run narrower syntax checks when the scope is smaller.
4. Inspect Terraform structure, variables, validation rules, resource dependencies, `user_data`, Shell
   syntax, `.extension`, documentation, and regional consistency as applicable.
5. Separate tool/environment failures from product failures. Do not claim live deployment success from
   static checks.
6. Report each issue with severity, file, line when available, evidence, and a concrete remediation.

## Severity

- `error`: blocks deployment, violates a formal contract, exposes a required asset as unusable, or makes
  the release unverifiable.
- `warning`: material risk or incomplete optional coverage that does not block the configured gate.
- `info`: observation or improvement without release impact.

Return `passed=false` when any error exists. Include commands, exit codes, checks not run, and why.
