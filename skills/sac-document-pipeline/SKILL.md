---
name: sac-document-pipeline
description: Compatibility alias for requests that explicitly name the legacy SAC document pipeline. Use sac-documentation as the sole source of generation, translation, DOCX, conversion, and quality-gate rules.
---

# SAC Document Pipeline Compatibility Alias

Load and follow `skills/sac-documentation/SKILL.md` in full.

Add no workflow, schema, output, or quality rules from this alias. Route every document request to
`sac-documentation` and use its CLI routing. If these files conflict, `sac-documentation` wins.
