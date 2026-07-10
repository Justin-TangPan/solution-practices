# architect-develop — SAC Codex 快速原型

## 输入

`project`、`regions`、`description`；可选 `variants`。

## 阶段

1. 派发 `architect`，形成 decisions、variables、resources 和 risks。
2. 主 Agent审阅会显著改变范围的决策；必要时向用户确认。
3. 按区域/variant 并行派发 `developer`，每个 Agent只拥有一个不重叠目录。
4. 主 Agent运行基础静态检查并检查 diff。

## 范围

本流程不包含正式安全审计、完整文档和 release 打包。最终必须明确标注“原型”，列出未执行的
门禁，不能宣称已可正式发布。
