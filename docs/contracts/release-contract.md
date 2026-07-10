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
- The unversioned formal Terraform entry must match the approved candidate byte-for-byte.
- Credentials must not be committed or written into generated artifacts.
- Any OBS upload must use environment variables for credentials.
- Test releases use four-level SAC versions (`X.Y.Z.N`); formal releases use exact three-level versions (`X.Y.Z`).
