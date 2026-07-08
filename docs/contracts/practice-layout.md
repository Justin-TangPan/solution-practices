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
