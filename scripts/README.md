# Scripts

Scripts are classified before they are used by release automation.

## Formal

实例级固定 RFS 约束写入 `project.config.json` 的 `quality_gate.practice_policies`，由统一门禁中的 `rfs_policy` 检查：

```bash
.venv-sac/bin/python -m scripts.tests.runner --practice <project> --check rfs_policy
```

- `tests/`: quality gate for formal practices listed in `project.config.json`.
- `document_pipeline/`: offline-first document analysis, structured model, Markdown/Word rendering,
  translation protection, bilingual checks, and the document CLI. Formal acceptance still runs through
  `python -m scripts.tests.runner`.

Document CLI examples:

```bash
python -m scripts.document_pipeline analyze --project litellm
python -m scripts.document_pipeline generate --project litellm
python -m scripts.document_pipeline translate --project litellm
python -m scripts.document_pipeline render-word --project litellm
python -m scripts.document_pipeline validate --project litellm
python -m scripts.document_pipeline convert --input legacy.docx
```

Analysis, parsing, rendering, and deterministic checks work offline. Semantic generation or translation uses
only the explicitly configured internal, local, or external backend. Templates, style maps, glossaries, model
selection, and output paths are configuration values; secrets must come from approved runtime configuration
and must never be logged or copied into documents.

## Optional

- `obs/`: OBS upload flow. Credentials must come from environment variables only. Object keys are
  site/locale-aware, and uploaded zip/manifest objects are read back for SHA-256 verification.
- `obs_upload_supabase.py` / `.bat`: compatibility wrappers for the generic OBS uploader; they contain no credentials and require an explicit test version.
- `generate_extension.py`: RFS extension helper.
- `validate_template.py`: template validation helper.

## Experimental

- `gen-practices-index.mjs`: web visualization catalog helper. `web/` is not part of the formal release gate yet.
- `skills-vector-index.py`: skill search/index helper.

## Deprecated compatibility scripts

The following one-off scripts contain historical assumptions. They are retained for compatibility and
regression reference, but formal workflows must use `scripts.document_pipeline` and must not call them:

- `fix_one_docx.py`
- `gen_docx.py`
- `gen_litellm_sac_docx.py`
- `gen_sac_docx.py`
- `quick_fix_titles.py`
- `update_docx_titles.py`

Do not delete these scripts as part of incremental migration. Move them to `scripts/archive/` only in a
dedicated compatibility cleanup after their remaining consumers have been verified.
