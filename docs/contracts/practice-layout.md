# Practice Layout Contract

Formal practice discovery is driven by deployable instance directories under `practices/`.

Supported layouts:

```text
practices/<practice>/cn/<region>/<variant>/
practices/<practice>/intl/<region>/<variant>/
practices/<practice>/intl/<locale>/<region>/<variant>/
```

Where:

- `<practice>` must be listed in `project.config.json` to be part of the formal gate.
- `<region>` is a Huawei Cloud region code such as `cn-north-4` or `ap-southeast-1`.
- `<locale>` is optional and currently expected to be `en-us` or `zh-cn` for international variants.
- `<variant>` is usually `standard` or `ha`.

Required contents are controlled by `project.config.json`.

Current policy:

- `terraform/` is required.
- `scripts/` is optional when inline `user_data` is used.
- `.extension` is optional unless the quality gate is tightened.

## Site-level document outputs

Formal document names follow the body language, including the `_zh`/`_en` suffix:

```text
practices/<practice>/cn/docs/<Name>-部署指南_zh.md
practices/<practice>/cn/docs/<Name>-方案详情_zh.md
practices/<practice>/intl/docs/zh-cn/<Name>-部署指南_zh.md
practices/<practice>/intl/docs/zh-cn/<Name>-方案详情_zh.md
practices/<practice>/intl/docs/en-us/<Name>-Deployment-Guide_en.md
practices/<practice>/intl/docs/en-us/<Name>-Solution-Details_en.md
```

The document pipeline may create a DOCX beside each Markdown document using the same basename. DOCX is an
additive, configurable IDP rendering output; historical practices that only contain Markdown remain valid
until migrated. Intermediate standard documents, conversion artifacts, and reports belong under
`output/document-pipeline/<practice>/`, not `reference/` or `release/`.

Terraform lifecycle:

- Test candidates use `terraform/deploying-<practice>_vN.tf` (or `_vN.tf.json`).
- Candidate revisions that entered testing are immutable. Superseded or failed candidates are deleted locally; only user-confirmed cloud-test candidates remain for audit and rollback, while consumed revision numbers stay in the internal changelog.
- `terraform/deploying-<practice>.tf` is the promoted formal entry only after explicit user test approval.
- Existing legacy names remain valid until their next functional modification; migration is incremental to avoid breaking RFS and OBS links.
