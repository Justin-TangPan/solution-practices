---
name: sac-project-rules
description: Govern every SAC Solution Practice from main-Agent architecture assessment through verified local delivery. Use for any SAC project work, workflow selection, role handoff, quality gate, or release decision.
---

# SAC Project Rules

SAC means **Solution Practices（解决方案实践）**. This Skill owns project-wide decisions; implementation,
testing, security, documentation, and packaging details belong to their role Skills.

## Authority and safety

Use truth in this order: `project.config.json`, `practices/`, executable tests, `skills/`,
`docs/contracts/`, then `web/`. `.codex/` and `.claude/` are local orchestration only.
`docs/project-state.md` records current scope. `reference/` is user-owned and read-only.

In an npm-installed host without a root `project.config.json`, use `.sac/project.config.json` as the
packaged baseline. Every role's reference to project configuration follows this fallback.

Preserve existing changes. Never write credentials, tokens, private endpoints, or private bucket data
to source, artifacts, or logs. Record modification batches in `.var/log/internal-changelog.md`;
`.var/` is local memory and is never delivered.

## Main-Agent architecture gate

For every new practice, the main Agent is the accountable solution architect and must:

1. **Assess the system**: official release unit, version, license, dependencies, Huawei Cloud fit,
   Region constraints, topology, persistence, capacity, availability, cost, security, operations,
   upgrade, backup, recovery, and closest formal repository evidence.
2. **Present an initial solution**: recommended topology and defaults, deployment path, runtime,
   public entry, data model, external dependencies, deviations, evidence, and risks.
3. **Confirm user decisions**: site, Region, `standard|ha`, template format, installation/runtime mode,
   public access, billing scope, and product-specific dependencies. Do not re-ask known inputs.
4. **Freeze one architecture contract**: assessment, solution, confirmed inputs, rules read, references,
   variables, fixed values, endpoints, artifacts, deviations, resources, dependencies, and risks.
5. **Dispatch only the frozen contract** with non-overlapping file scopes to child Agents.

Stop before implementation when the contract is absent, incomplete, or internally conflicting.
Child Agents never replace final architecture judgment or ask the user fragmented design questions;
they stop affected writes and report gaps to the main Agent.

## Formal outcome and authorization stops

The formal outcome is a verified **local package** containing deployable Terraform, an optional
`.extension`, required Markdown documents, configured DOCX documents, a deterministic archive, and
SHA-256 checksums. New practices use inline `user_data`; external installers, hosted paths, URL lists,
and `manifest.json` are not formal artifacts.

Stop the pipeline when tests contain an error, security contains a critical/high finding, required
review is incomplete, or authoritative sources disagree. The user normally performs real cloud testing
from the candidate package. Cloud changes, external publication, Git commit/push, and package publication
always require separate explicit authorization. Local checks never imply cloud success or production readiness.

## Canonical structure and candidates

Implementation dimensions are `site → region → variant`:

```text
practices/<project>/<cn|intl>/<region>/<standard|ha>/
├── terraform/deploying-<project>_vN.tf   # or .tf.json
└── .extension                            # optional
practices/<project>/cn/docs/*.md
practices/<project>/intl/docs/{zh-cn,en-us}/*.md
```

Locale is never an implementation dimension. Each `terraform/` directory contains exactly one loadable
Terraform file. Project IDs are lowercase hyphenated names.

Start at `_v1`; use the next `_vN` for every behavior change. Once real testing starts, do not overwrite
that revision. A failed number is not reused. Only explicit approval of that exact candidate permits a
rename to `deploying-<project>.tf`; candidate and formal files never coexist.

## Workflow and ownership

Choose the smallest workflow in `.codex/workflows/`: full delivery, architecture/development prototype,
audit, or delivery-only. The standard dependency chain is:

```text
assessment → initial solution → confirmation → contract → implementation
→ test + security → remediation → user cloud test → promotion → documentation → local delivery
```

- Architect supplies read-only evidence and candidate design to the main Agent.
- Developer owns only its assigned `site/region/variant` implementation directory.
- Tester and Security are read-only unless remediation is explicitly assigned.
- Documenter owns only assigned site/locale documents derived from verified implementation.
- Delivery owns verified local `release/` assets, archive, checksums, and authorized version records.
- Main Agent owns shared files, decisions, conflicts, final gates, and the local changelog.

Run only independent, non-overlapping work in parallel. Every child returns `status`, `summary`,
`files_changed`, `checks_run`, `issues`, and `handoff`, plus its role-specific fields.

## Skill routing

- Terraform, resources, inline bootstrap, regional runtime, candidates: `sac-rfs-practices`.
- Static and repository verification: `sac-testing`.
- Secret, exposure, and exception review: `sac-security`.
- Markdown maintenance, full generation, translation, optional DOCX, and document gates: `sac-documentation`.
- `sac-document-pipeline` is a compatibility alias; never load both document Skills.
- Local archive and checksum assembly: `sac-delivery`.
- Business viability, deep research, and page enhancement are conditional, never default gates.

Do not duplicate those Skills' procedures here. Instance-specific accepted risk belongs in
`project.config.json.quality_gate.practice_policies` or `architecture_exceptions`.

## Promotion and local delivery gates

Before promotion, verify syntax, rendered `user_data`, cloud-init, services, ports, API/auth behavior,
persistence, contract consistency, documentation consistency, and configured security gates.

Assemble `release/<project>/` only when the practice is formal, the exact candidate has user-confirmed
cloud approval and was promoted, configured tests have no errors, security has no critical/high finding,
required locale documents and reviews exist, and copied assets match `practices/`. Build deterministically,
calculate checksums, compare sources, list contents, and call it a local delivery package.

## Versioning and completion

Formal releases use `vX.Y.Z`; unvalidated batches use four-level test versions such as `vX.Y.Z.N`.
Failed candidate numbers are never reused. Public names, commands, fields, and paths cannot silently
disappear in a patch/minor change. Any formal version change synchronizes its configured version records.

Report each variant's local package form, site, Region, variant, static-gate result, and user cloud-test
state. Explicitly state skipped checks and never infer deployment, publication, or production readiness.
