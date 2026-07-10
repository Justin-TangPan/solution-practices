---
name: sac-delivery
description: Validate and assemble SAC release directories, regional RFS URL manifests, archives, checksums, and version records after quality and security gates pass. Use for local packaging, delivery-only workflows, release readiness checks, or authorized publication preparation; never infer permission for external publication.
---

# SAC Delivery

Package only verified inputs and preserve the distinction between local assembly, test publication, and
production publication.

## Required inputs

Read `skills/sac-project-rules/SKILL.md`, `docs/contracts/release-contract.md`, `project.config.json`,
and the tester/security/documentation handoffs. Confirm project, regions, locales, variants, candidate/formal
version, and the user's publication authorization.

## Gates

Stop formal delivery when:

- the practice is outside formal scope;
- tests contain an error;
- security contains a critical or high finding;
- required site or international locale documentation is absent;
- an exact candidate lacks explicit cloud-test approval for promotion;
- the formal entry differs from the approved candidate.

## Workflow

1. Assemble `release/{project}/` from the authoritative `practices/` inputs.
2. Generate region- and variant-specific URL manifests using the documented OBS conventions.
3. Create the archive deterministically and list its contents.
4. Calculate SHA-256 checksums and compare copied files with their sources.
5. Update version records only within the authorized release scope.
6. Keep production OBS upload, external release, Git commit/push, and real RFS deployment disabled unless the
   user explicitly authorizes that exact action.

Return release directory, regions/locales/variants, URL files, archive, checksums, gates evaluated, and any
blocking reason. Never describe a local package as published.
