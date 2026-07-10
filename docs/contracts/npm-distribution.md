# npm Distribution Contract

`solution-practices` is distributed as an explicit CLI, not as an install-time workspace mutator.

## Stable interfaces

- npm package: `solution-practices`
- executable: `sac`
- commands: `init`, `install`, `update`, `list`, `doctor`
- manifest: `.sac/manifest.json`
- discoverable Skills: `.codex/skills/` with a root `skills/` compatibility mirror
- Codex custom-agent names: `sac_architect`, `sac_developer`, `sac_tester`, `sac_security`,
  `sac_documenter`, `sac_delivery`

Renaming or removing one of these requires a major npm version or a documented compatibility alias and
deprecation period.

## Versions

- `package.json.version` is the npm SemVer package version.
- `package.json.sac.manifestSchemaVersion` versions the installed manifest structure.
- `package.json.sac.contentVersion` versions bundled Skills, Agent contracts, and practices.
- Terraform candidate versions and SAC four-level cloud-test versions remain governed separately by
  `sac-project-rules`.

## File ownership

- `managed`: SAC may update the file only when its current checksum matches the previous manifest.
- `merge-block`: SAC owns only the text between explicit SAC markers.
- `managed-unless-modified`: user changes produce a `.sac-new` candidate instead of replacement.
- `user-owned`: SAC never replaces the file.

`--force` is an explicit replacement request, but does not authorize external publication or cloud actions.

## Update and migration

Every structural manifest change increments `manifestSchemaVersion` and adds a deterministic migration under
`src/migrations/`. Migrations run in ascending order, reject newer unsupported schemas, write atomically, and
must have upgrade tests from the oldest supported version.

CLI file operations must be idempotent. Existing user content outside SAC marker blocks must survive repeated
`init` and `update` operations. Conflicts must be visible and non-destructive.

## Publication gate

Before `npm publish`:

1. Run `npm test`.
2. Run the formal SAC project gate.
3. Run Skill validation.
4. Run `npm pack --dry-run` and inspect included files for secrets, test endpoints, local logs, and oversized
   unintended assets.
5. Test install, repeated install, modified-file update, dry-run, doctor, and practice installation in temporary
   directories.
6. Publish a prerelease tag before `latest` for breaking or migration-heavy changes.

`npm install`, `sac init`, and `sac update` never imply permission for Git commit/push, OBS upload, external
publication, real RFS deployment, or production cloud mutation.
