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
| `sac-business-evaluator` | optional | research |
| `sac-technical-evaluator` | optional | research |
| `sac-page-enhance` | optional | content |
| `sac-deep-search` | optional | research |

Formal skills must not assume that historical or removed practices still exist. The current formal list comes from `project.config.json`.
