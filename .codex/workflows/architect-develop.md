# architect-develop — SAC Codex 快速原型

## 输入

`project`、`regions`（`site/region`，例如 `cn/cn-north-4`）、`description`；可选 `variants`。

## 阶段

1. 主 Agent 派发只读 `architect`，形成 `system_assessment`、`initial_solution`、用户待确认项和证据。
2. 主 Agent 向用户呈现初版方案，确认站点、Region、standard/ha、模板与安装策略、运行方式、公网入口和产品特有外部依赖。
3. 主 Agent 冻结完整 `architecture_contract`；必要确认缺失时停止，不派发实现。
4. 将完整合同下发给按区域/variant 分配的 `developer`，每个 Agent只拥有一个不重叠目录。
5. 主 Agent运行基础静态检查并检查 diff。

## 范围

本流程不包含正式安全审计、完整文档和 release 打包。最终必须明确标注“原型”，列出未执行的
门禁，不能宣称已可正式发布。
