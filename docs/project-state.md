# Project State

This document records the current repository scope. It should be updated when a practice becomes formal, is removed, or an experimental area graduates into the release flow.

## Current Formal Scope

- Formal practices: `litellm`, `supabase`, `openjiuwen`
- Formal quality gate: `scripts/tests/`
- Formal rules: `skills/sac-project-rules/`, `skills/sac-rfs-practices/`
- Scope config: `project.config.json`

## Explicitly Out Of Formal Scope

- `web/` is a future visualization prototype and is not part of the formal release gate.
- `.claude/agents/` and `.claude/workflows/` are local collaboration assets.
- Historical half-finished practices may still be referenced by old documents, scripts, or catalog data. Those references are not formal unless the practice is listed in `project.config.json`.

## Source-Of-Truth Order

1. `project.config.json` defines current formal scope.
2. `practices/` contains deployable implementation assets.
3. `skills/` contains rules and reusable project knowledge.
4. `scripts/tests/` validates formal practice assets.
5. `web/` may visualize or experiment with catalog data, but it does not define formal delivery state.

## Data-Source Policy

When generated data conflicts with actual `practices/` contents, prefer the formal scope in `project.config.json` and the filesystem under `practices/`.

When README, web catalog, or historical scripts mention practices that no longer exist, treat them as stale until reconciled.

## Current Quality-Gate Policy

- `terraform/` is required for a formal deployable instance.
- `scripts/` is optional because some practices use fully inline `user_data`.
- `.extension` is recommended but not currently a hard requirement.
