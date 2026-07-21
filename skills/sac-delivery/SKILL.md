---
name: sac-delivery
description: Validate and assemble verified SAC release directories, deterministic local archives, SHA-256 checksums, and authorized version records. Use for local package assembly, delivery readiness, or release-package verification after test, security, documentation, and cloud-test gates pass.
---

# SAC Local Delivery

Produce a local delivery package only. Never describe it as published or online.

## Required inputs

Read `skills/sac-project-rules/SKILL.md`, `docs/contracts/release-contract.md`, `project.config.json`,
and the architecture, developer, tester, security, documentation, and user cloud-test handoffs.

Confirm the project, sites, Regions, variants, exact formal templates, version, and local output scope.

## Gates

Stop when the practice is outside formal scope; tests contain an error; security contains a
critical/high finding; required Markdown or international locale pairs are absent; configured document
review is blocked; the exact candidate lacks explicit user cloud-test approval; or the promoted formal
entry differs from the approved candidate.

## Workflow

1. Copy authoritative `practices/` inputs into the canonical `release/<project>/` layout.
2. Compare every copied file with its source.
3. Create the archive deterministically and list its contents.
4. Generate `SHA256SUMS` for the delivered files and archive.
5. Update version records only when explicitly authorized.
6. Run final package-integrity and repository gates.

Do not create URL manifests or hosted-object metadata. Git commit/tag/push, npm publication, external
release, and real cloud-resource changes are separate actions requiring explicit authorization.

Return `release_dir`, sites, Regions, variants, archive file, checksums, gates evaluated, copied-file
comparison, and blocking reasons.
