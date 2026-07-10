# Scripts

Scripts are classified before they are used by release automation.

## Formal

- `tests/`: quality gate for formal practices listed in `project.config.json`.

## Optional

- `obs/`: OBS upload flow. Credentials must come from environment variables only.
- `obs_upload_supabase.py` / `.bat`: compatibility wrappers for the generic OBS uploader; they contain no credentials and require an explicit test version.
- `generate_extension.py`: RFS extension helper.
- `validate_template.py`: template validation helper.

## Experimental

- `gen-practices-index.mjs`: web visualization catalog helper. `web/` is not part of the formal release gate yet.
- `skills-vector-index.py`: skill search/index helper.

## Archive Candidates

The following scripts contain hard-coded local paths, single-practice assumptions, or one-off document generation behavior. Do not call them from formal automation until they are parameterized:

- `fix_one_docx.py`
- `gen_docx.py`
- `gen_litellm_sac_docx.py`
- `gen_sac_docx.py`
- `quick_fix_titles.py`
- `update_docx_titles.py`

When these are still useful, move them to `scripts/archive/` in a dedicated cleanup change or rewrite them with CLI arguments and workspace-relative paths.
