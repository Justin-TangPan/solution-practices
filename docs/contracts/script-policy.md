# Script Policy

Scripts are classified by role before they are used in release automation.

## Formal

- `scripts/tests/`: static validation and quality gate.

## Optional

- `scripts/obs/`: OBS upload flow.
- `scripts/generate_extension.py`: extension generation helper.
- `scripts/validate_template.py`: template validation helper.

## Experimental

- `scripts/gen-practices-index.mjs`: web visualization catalog helper.
- Web-related scripts must not define formal release state.

## Archive Candidates

Scripts with hard-coded absolute local paths, one-off DOCX generation logic, or a single practice name are archive candidates. They should be moved under `scripts/archive/` or rewritten before being used in formal automation.

Examples currently matching this category include DOCX title fixers and one-off LiteLLM/Supabase helpers.
