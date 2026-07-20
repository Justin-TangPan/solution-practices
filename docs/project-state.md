# Project State

This document records the current repository scope. It should be updated when a practice becomes formal, is removed, or an experimental area graduates into the release flow.

## Current Formal Scope

- Formal practices: `litellm`, `supabase`, `openjiuwen`
- Formal quality gate: `scripts/tests/`
- Formal rules: `skills/sac-project-rules/`, `skills/sac-rfs-practices/`
- Formal workflow skills: `skills/sac-testing/`, `skills/sac-security/`, `skills/sac-documentation/`, `skills/sac-delivery/`
- Formal npm distribution: `package.json`, `bin/sac.js`, `src/`, and `templates/`
- Formal GitHub visualization source: `web/` (read-only presentation layer; not a release authority)
- Scope config: `project.config.json`

## Explicitly Out Of Formal Scope

- `.claude/agents/`, `.claude/workflows/`, `AGENTS.md`, and `.codex/` are local collaboration assets.
- Historical half-finished practices may still be referenced by old documents, scripts, or catalog data. Those references are not formal unless the practice is listed in `project.config.json`.

## Source-Of-Truth Order

1. `project.config.json` defines current formal scope.
2. `practices/` contains deployable implementation assets.
3. `skills/` contains rules and reusable project knowledge.
4. `scripts/tests/` validates formal practice assets.
5. `web/` visualizes repository facts and generated snapshots, but it does not define formal delivery state.

## npm Distribution

The package name is `solution-practices`, the executable is `sac`, and Node.js 20 or newer is required.
Installed state is recorded in `.sac/manifest.json`. Distribution compatibility and file-ownership rules are
defined in `docs/contracts/npm-distribution.md`.

## Data-Source Policy

When generated data conflicts with actual `practices/` contents, prefer the formal scope in `project.config.json` and the filesystem under `practices/`.

When README, web catalog, or historical scripts mention practices that no longer exist, treat them as stale until reconciled.

## Current Quality-Gate Policy

- `terraform/` is required for a formal deployable instance.
- `scripts/` is optional because some practices use fully inline `user_data`.
- `.extension` is recommended but not currently a hard requirement.
