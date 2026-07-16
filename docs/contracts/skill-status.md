# Skill Status Contract

Skills are project knowledge assets. They should state whether they are formal, optional, experimental, or deprecated.

Recommended metadata:

```yaml
status: formal | optional | experimental | deprecated
scope: formal-delivery | research | visualization | local-agent
owner: project | user-local | internal
```

Current classification:

| Skill | Status | Scope |
|---|---|---|
| `sac-project-rules` | formal | formal-delivery |
| `sac-rfs-practices` | formal | formal-delivery |
| `sac-testing` | formal | formal-delivery |
| `sac-security` | formal | formal-delivery |
| `sac-documentation` | formal | formal-delivery |
| `sac-document-pipeline` | formal | formal-delivery |
| `sac-delivery` | formal | formal-delivery |
| `sac-business-evaluator` | optional | research |
| `sac-technical-evaluator` | optional | research |
| `sac-page-enhance` | optional | content |
| `sac-deep-search` | optional | research |

Formal skills must not assume that historical or removed practices still exist. The current formal list comes from `project.config.json`.

`sac-documentation` remains the backward-compatible Markdown authoring contract. New structured generation,
translation, IDP Word rendering, existing-document conversion, and document quality reports use
`sac-document-pipeline`. The documenter Agent binds the pipeline as its primary skill and may load
`sac-page-enhance` only when page copy enhancement is requested.
