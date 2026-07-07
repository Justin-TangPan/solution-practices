# SAC 项目规范

> 完整规则见 `skills/sac-project-rules/SKILL.md`（项目规则总纲）和 `skills/sac-rfs-practices/SKILL.md`（RFS 开发规范）。
> 以下为高频触发规则摘要，确保每次会话都能命中。

## 项目命名

- 英文名：**Solution Practices**，缩写 **SAC**，中文名：**解决方案实践**

## 版本管理

- 每次提交代码前，检查是否需要更新 `CHANGELOG.md`（详见 `sac-project-rules` §版本管理）

## 海外 ECS 规格（intl）

- `ecs_flavor` 默认 `c7n.2xlarge.2`，禁止 x1 系列；validation 禁止仅匹配 `x1.*`（详见 `sac-rfs-practices` Rule 9）

## 国际站双语言（intl）

- `en-us/` + `zh-cn/` 必须同时存在，逻辑一致仅翻译，新增区域同步创建（详见 `sac-project-rules` §3.4）
