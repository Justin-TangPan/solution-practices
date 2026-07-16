# full-pipeline — SAC Codex 全流程

## 输入

`project`、`regions`、`description`；可选 `variants`、`deployment constraints`。

## 阶段

1. **Architect**：主 Agent派发 `architect`，审阅其规则/参考证据、冻结参数合同、偏差和风险；需要用户决定的偏差未确认时停止。
2. **Develop**：按不重叠区域/variant 派发一个或多个 `developer`；可并行。
3. **Test + Security**：开发完成后并行派发只读 `tester` 与 `security`；tester 必须运行 `rfs_policy`。
4. **Remediation gate**：若存在 error 或 critical/high，主 Agent先组织最小修复并重新审计；不得直接进入交付。
5. **Document**：按站点/语言拆分 `documenter`；依次完成材料分析、统一模型、中文正文、
   受保护翻译、Markdown/Word 渲染、文档质量检查和人工审核清单；国际站中英文必须成对完成。
6. **Document gate**：结构化质量报告存在 error 或仍有阻断型人工确认项时停止，不得标记可上架。
7. **Deliver**：仅在测试、安全和文档门禁均通过后派发 `delivery`。生产上传、Git 提交和云资源变更仍需用户明确授权。
8. **Final verify**：主 Agent运行仓库正式质量门禁、检查 diff、记录内部 changelog 并汇总交付物。

## 数据流

```text
architect decisions
        ↓
regional developers
        ↓
tester ─┬─ security
        ↓
site/locale documenters
        ↓
delivery → main-agent final verification
```

## 完成条件

- 所有目标区域/variant 的实现存在。
- 正式测试无 error；安全无 critical/high。
- 所需站点语言 Markdown/Word 齐全、与模板一致，质量报告无阻断错误且人工审核清单已交接。
- release 与 practices 一致，或明确说明用户未授权交付阶段。
