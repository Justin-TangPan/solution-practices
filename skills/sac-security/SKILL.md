---
name: sac-security
description: Audit SAC Solution Practices for embedded credentials, unsafe network exposure, security-group scope, container privileges, dangerous mounts, data protection, dependency and image provenance, and sensitive local delivery artifacts. Use for security reviews, SAC audit workflows, release gates, or remediation verification.
---

# SAC Security

Perform an evidence-based, read-only audit unless remediation is explicitly requested.

## Required inputs

Read `skills/reference/security-check-rules.md`, `skills/sac-project-rules/SKILL.md`, the frozen architecture
contract, and the exact practice scope. Do not load the full RFS Skill; use contract deviations and configured
exceptions to distinguish approved exposure from defects.

## Workflow

1. Search for AK/SK, API keys, tokens, passwords, private endpoints, debug tracing, and unsafe secret
   interpolation. Never reproduce a suspected secret in full.
2. Review ingress and egress rules, public ports, CIDRs, administrative access, and whether application
   exposure matches documented behavior.
3. Review container privilege, host networking, Docker socket and host mounts, image provenance, mutable
   tags, and runtime user choices.
4. Review password generation and storage, database exposure, TLS assumptions, file permissions, logs,
   backups, and local delivery artifacts.
5. Distinguish documented public image proxies from credentials.
6. Report only findings supported by repository evidence. State untested runtime assumptions separately.

## Severity

- `critical`: direct credential compromise, unauthenticated sensitive control, or equivalent immediate impact.
- `high`: practical remote compromise, broad privileged exposure, or release-blocking secret handling.
- `medium`: defense-in-depth gap with meaningful prerequisites.
- `low`: limited hardening opportunity.

Set `passed=false` for any critical or high finding. Return finding ID, severity, file, line, evidence,
impact, remediation, and verification guidance.
