# Practice Layout Contract

Formal practice discovery is driven by deployable instance directories under `practices/`.

Canonical layout:

```text
practices/<practice>/cn/<region>/<variant>/
practices/<practice>/intl/<region>/<variant>/
```

Where:

- `<practice>` must be listed in `project.config.json` to be part of the formal gate.
- `<region>` is a Huawei Cloud region code such as `cn-north-4` or `ap-southeast-1`.
- `<variant>` is usually `standard` or `ha`.

Locale is not an implementation dimension. International Terraform is shared; localized parameter text
lives in one bilingual `.extension`, and localized prose lives under `intl/docs/<locale>/`. The historical
`intl/<locale>/<region>/<variant>/` layout is migration input only and must not be used for new work.

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

- A deployable instance contains exactly one loadable Terraform file: either `.tf` or `.tf.json`, never both.
- Test candidates use `terraform/deploying-<practice>_vN.tf` (or `_vN.tf.json`).
- Candidate revisions that entered testing are immutable. Superseded or failed candidates are deleted locally; consumed revision numbers stay in the internal changelog.
- After explicit cloud-test approval, promotion renames the candidate to `terraform/deploying-<practice>.tf`.
  It must not leave the candidate beside the formal entry because Terraform loads every file in the directory.
- Git history and the local internal changelog provide audit and rollback history.
- Existing legacy names remain valid until their next functional modification; migration is incremental to avoid breaking local consumers.
