# Release Contract

Formal release automation must use the following inputs in order:

1. `project.config.json` for formal scope.
2. `practices/` for deployable assets.
3. `scripts/tests/` for validation.
4. `CHANGELOG.md` for release history.

`web/`, `.claude/agents/`, `.claude/workflows/`, and generated visualization indexes are not release authorities.

Before a practice is released:

- It must be listed in `project.config.json`.
- Its deployable instances must pass the configured quality gate.
- The exact versioned Terraform candidate must have explicit user confirmation that cloud deployment testing passed.
- Promotion renames the approved candidate to the unversioned formal entry; its approved checksum and
  revision are recorded before the rename. Candidate and formal files must never coexist in one directory.
- Credentials must not be committed or written into generated artifacts.
- The formal delivery output is `release/<project>/`, a deterministic local ZIP, and `SHA256SUMS` covering
  delivered files and the archive. It contains deployable Terraform, optional `.extension`, required
  Markdown, and DOCX only when configured or requested; it contains no hosted-object metadata or URL manifest.
- Git, external publication, and real cloud-resource changes are separate explicitly authorized actions.
- Test releases use four-level SAC versions (`X.Y.Z.N`); formal releases use exact three-level versions (`X.Y.Z`).
