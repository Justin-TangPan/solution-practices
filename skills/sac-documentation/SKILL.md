---
name: sac-documentation
description: Generate, maintain, translate, render, and validate SAC deployment guides and solution details from verified implementation facts. Use for new or existing Markdown, zh/en documents, optional DOCX, legacy document conversion, or formal document quality gates.
---

# SAC Documentation

Use this as the single formal entry for SAC documentation. Derive technical facts from verified implementation;
never invent parameters, ports, versions, costs, performance, availability, or validation results.

## Scope

- Generate or maintain Deployment Guide and Solution Details Markdown.
- Produce China-site Chinese and international-site Chinese/English documents.
- Translate while protecting code, commands, paths, URLs, identifiers, versions, and resource IDs.
- Render DOCX only when `project.config.json` sets `require_docx=true` or the user requests it.
- Convert existing Markdown, DOCX, or PDF through the standard document model.
- Run document-only checks; page extraction and marketing/Excel work belongs to `sac-page-enhance`.

## Inputs and truth

Read `sac-project-rules`, the architecture contract, current Terraform and optional `.extension`, then relevant
developer/tester handoffs and existing documents. Truth order is implementation and configuration, explicit user
material, project references, then style samples. Never use samples as project facts. Skip secrets and build output.

For a small edit, verify only affected facts and preserve unrelated structure. For generation, translation,
conversion, or formal review, use the standard model and pipeline below.

## Required outputs

- Formal Markdown for each requested site, locale, and document type.
- `standard-document.json`, `quality-report.json`, and `manual-review.json` for pipeline work.
- DOCX only when required; its absence must not block a Markdown-only delivery.

Use the repository naming and locale layout defined by `sac-project-rules`. Retain historical names until an
explicit migration is requested.

## Workflow

1. Resolve requested sites, locales, document types, and whether DOCX is required.
2. Extract implementation, architecture, parameter, deployment, validation, security, rollback, and limitation facts.
3. Scan for sensitive values; report location and type, never the value.
4. Build or update the standard model with source, inferred, missing, and confirmation markers.
5. Generate Chinese Markdown; adapt regional facts before producing international Chinese.
6. Translate English using project, product, cloud-service, then global terminology priority.
7. Render all formats from the same model; do not independently rewrite DOCX content.
8. Compare documents with implementation and across locales, then produce quality and manual-review reports.
9. Run the formal project test entry before handing files to delivery.

Retain costs, durations, percentages, performance, customer counts, and similar numbers only with a verifiable
source. Otherwise remove them or mark them `待业务确认`. Record unreliable PDF structure as a review item.

## CLI routing

In this source repository, use `.venv-sac/bin/python` and the root `scripts/` tree. In an npm-initialized
host, use its isolated `.sac/tooling` copy instead:

```bash
python -m venv .venv-sac
.venv-sac/bin/python -m pip install -r .sac/tooling/requirements-document-pipeline.txt
PYTHONPATH=.sac/tooling .venv-sac/bin/python -m scripts.document_pipeline generate --project <project> --site <cn|intl|all> [--docx]
```

Do not claim DOCX or formal-gate execution when neither tooling location is present; report that capability as
blocked. The remaining source-repository commands are:

```bash
.venv-sac/bin/python -m scripts.document_pipeline analyze --project <project>
.venv-sac/bin/python -m scripts.document_pipeline generate --project <project> --site <cn|intl|all> [--docx]
.venv-sac/bin/python -m scripts.document_pipeline translate --project <project> --locale en-us
.venv-sac/bin/python -m scripts.document_pipeline render-word --project <project>
.venv-sac/bin/python -m scripts.document_pipeline validate --project <project>
.venv-sac/bin/python -m scripts.document_pipeline convert --input <legacy.md|docx|pdf>
```

- `analyze`: build the standard model without formal publication.
- `generate`: produce the requested document set and reports.
- `translate`: create a locale-specific model and Markdown.
- `render-word`: use only when DOCX is required; template paths come from configuration or arguments.
- `validate`: read-only document check; it does not replace the formal project test entry.
- `convert`: normalize legacy input before editing or translation.

Default to offline processing. External models or endpoints require explicit configuration and applicable data
authorization. If unavailable, preserve deterministic outputs and report the missing semantic work.

## Quality gate

Block handoff for invalid schema, missing required Markdown or facts, secret exposure, broken protected tokens,
implementation/parameter/URL conflicts, or unmarked unreliable conversion. Block on DOCX errors only when DOCX is
required. Wording, optional sections, and low-confidence layout may be warnings but must enter manual review.

Run `.venv-sac/bin/python -m scripts.tests.runner`, or the npm-host equivalent
`PYTHONPATH=.sac/tooling .venv-sac/bin/python -m scripts.tests.runner`. Handoff only when formal checks pass and no blocking review item remains.
Return files changed, sources checked, commands run, warnings, blockers, and required human review.
