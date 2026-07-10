---
name: sac-security
description: Audit SAC Solution Practices for embedded credentials, unsafe network exposure, security-group scope, container privileges, dangerous mounts, data protection, dependency and image provenance, and OBS permissions. Use for security reviews, SAC audit workflows, release gates, or remediation verification.
---

# SAC Security

Perform an evidence-based, read-only audit unless remediation is explicitly requested.

## Required inputs

Read `skills/reference/security-check-rules.md`, `skills/sac-project-rules/SKILL.md`, and the relevant
sections of `skills/sac-rfs-practices/SKILL.md`. Confirm the exact practice and deployment scope.

## Workflow

1. Search for AK/SK, API keys, tokens, passwords, private endpoints, debug tracing, and unsafe secret
   interpolation. Never reproduce a suspected secret in full.
2. Review ingress and egress rules, public ports, CIDRs, administrative access, and whether application
   exposure matches documented behavior.
3. Review container privilege, host networking, Docker socket and host mounts, image provenance, mutable
   tags, and runtime user choices.
4. Review password generation and storage, database exposure, TLS assumptions, file permissions, logs,
   backups, and OBS read/write policy.
5. Distinguish public production bucket names and the documented public image proxy from credentials.
6. Report only findings supported by repository evidence. State untested runtime assumptions separately.

## Severity

- `critical`: direct credential compromise, unauthenticated sensitive control, or equivalent immediate impact.
- `high`: practical remote compromise, broad privileged exposure, or release-blocking secret handling.
- `medium`: defense-in-depth gap with meaningful prerequisites.
- `low`: limited hardening opportunity.

Set `passed=false` for any critical or high finding. Return finding ID, severity, file, line, evidence,
impact, remediation, and verification guidance.
