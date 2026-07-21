---
name: sac-rfs-practices
description: Implement a frozen SAC architecture contract as Huawei Cloud RFS/OpenTofu Terraform with inline ECS bootstrap. Use for practice implementation, candidate revision, deployment debugging, or RFS policy validation.
---

# Huawei Cloud RFS Solution Builder

Implement the frozen contract as a self-contained local asset. This Skill never authorizes cloud changes,
external publication, or Git operations.

Load this Skill for Developer work after contract freeze. It is not a prerequisite for the Architect's
system assessment or the main Agent's confirmation step.

## Inputs and conditional references

Always read `sac-project-rules`, the complete user-confirmed `architecture_contract`, the closest formal
practice, and `assets/demo/` baseline. Read references only when their condition applies:

- `decision-framework.md`: selecting between viable implementation patterns;
- `region-mapping.md`: adding/changing a site or Region, or resolving regional behavior;
- `docker-registry.md`: the confirmed runtime uses containers;
- `validation-checklist.md`: final implementation validation or tester handoff.

Stop before writing if site, Region, variant, runtime, endpoint, variables, fixed values, dependencies,
resources, or allowed files are missing or conflicting. Return the gap to the main Agent; do not invent
architecture defaults.

## Canonical implementation

```text
practices/<project>/<cn|intl>/<region>/<standard|ha>/
├── terraform/deploying-<project>_vN.tf   # or .tf.json when contracted
└── .extension                            # optional
```

Locale is not a Terraform dimension. Use HCL unless the contract requires `.tf.json`. A deployable
instance contains exactly one Terraform file.

## Provider and resources

Use only `huaweicloud` unless `project.config.json` records a cloud-validated exception:

```hcl
terraform {
  required_providers {
    huaweicloud = { source = "huawei.com/provider/huaweicloud", version = ">= 1.20.0" }
  }
}
provider "huaweicloud" { region = "<confirmed-region>" }
```

Do not set `auth_url`, `cloud`, or `insecure`; do not add `random`, `tls`, or another provider without
an approved exception. Create only contracted resources, normally `VPC → Subnet → Security Group → EIP
→ ECS`. Prefix stable names with `var.solution_name`; never use changing UUID/random names.

Default to Ubuntu 24.04 unless upstream requires another image. Enable `hss,ces`. Set
`delete_disks_on_termination = true` only when the confirmed durability model permits it.

## Variables, secrets, and trust boundaries

Expose customer decisions only, typically `solution_name`, `ecs_flavor`, sensitive `ecs_password`, system
disk, bandwidth, and contracted billing inputs. Keep official ports, health endpoint, internal CIDRs,
image source, and service wiring fixed unless confirmed as choices. Each validation references only its
own variable because RFS rejects cross-variable validation.

Encode sensitive Terraform values with `base64encode()` before crossing into `user_data`; decode on ECS,
write with restrictive permissions, and never log them. Never interpolate raw credentials into Shell,
`sed`, URLs, or unquoted dotenv content.

Allow SSH only from CloudShell `121.36.59.153/32`; open only contracted application ports. Public HTTP,
administrative or credential-bearing endpoints, and `0.0.0.0/0` access require an explicit architecture
decision. Never publicly expose databases, caches, Docker, or debuggers. Privileged containers, host
networking, Docker socket mounts, broad host mounts, or mutable tags require an approved exception.

## Inline bootstrap

All new practices use fully inline `user_data`: noninteractive OS preparation, confirmed runtime,
generated configuration/service definitions, startup, bounded health verification, and sanitized local
failure logs. Do not create or fetch an external installer. Pinned official packages and images remain
allowed when the contract records source and version.

Keep rendered `user_data` within 32 KiB. China first boot must not depend on GitHub. If the official unit
cannot fit or be fetched reliably, stop with an architecture constraint rather than adding a distribution
channel.

For containers, use Docker Compose v2, preserve Compose `${NAME}` as `$${NAME}` in Terraform heredocs,
keep Shell substitution as `$(command)`, and escape Terraform template sequences such as curl
`%%{http_code}`. Use persistent directories with correct ownership. Never hide required setup/startup
failure behind an unconditional fallback.

## Regional invariants

- `cn`: use approved Huawei Cloud Docker CE and domestic package mirrors; retain official image names,
  configure the approved daemon registry mirror, restart Docker, and verify it loaded.
- `intl`: use official package/runtime sources, omit China mirrors, default candidates to
  `c7n.2xlarge.2` subject to availability, and never restrict validation to China-only `x1.*` flavors.

Apply the upstream deployment unit completely. Do not trim required services, initialization assets,
schemas, roles, volumes, gateways, or authentication. For stateful services, preserve idempotent bootstrap,
ownership, persistence, restart behavior, and fail-fast database initialization. Do not replace a customized
database with managed RDS until required extensions, roles, replication, and initialization are proven compatible.

## Candidate lifecycle

Start a new instance at `_v1`. A revision is immutable after real testing begins. On failure, remove the
failed local candidate, record why, and use the next unused `_vN`. Only explicit approval of that exact
candidate permits renaming it to `deploying-<project>.tf`; never retain candidate and formal entries together.
Local release assembly waits for configured test, security, documentation, and promotion gates.

## Minimum checks and handoff

Run the applicable smallest set:

- `terraform fmt -check` and syntax parsing;
- rendered `user_data` Shell syntax and 32 KiB size;
- `docker compose config --quiet` when Compose is generated;
- instance-scoped `rfs_policy` and configured repository/security gates;
- contract comparison for resources, variables, fixed values, endpoints, dependencies, and allowed files.

Static checks do not prove cloud deployment. Return commands, exit codes, skipped runtime checks, risks,
and exact candidate revision in the developer handoff.
