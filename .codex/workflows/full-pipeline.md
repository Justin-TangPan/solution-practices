# full-pipeline — SAC Codex 全流程

## 输入

`project`、`regions`、`description`；可选 `variants`、`deployment constraints`。

## 阶段

1. **Architect**：主 Agent派发 `architect`，审阅其 decisions 和风险。
2. **Develop**：按不重叠区域/variant 派发一个或多个 `developer`；可并行。
3. **Test + Security**：开发完成后并行派发只读 `tester` 与 `security`。
4. **Remediation gate**：若存在 error 或 critical/high，主 Agent先组织最小修复并重新审计；不得直接进入交付。
5. **Document**：按站点/语言拆分 `documenter`；国际站中英文必须成对完成。
6. **Deliver**：仅在门禁通过后派发 `delivery`。生产上传、Git 提交和云资源变更仍需用户明确授权。
7. **Final verify**：主 Agent运行仓库正式质量门禁、检查 diff、记录内部 changelog 并汇总交付物。

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
- 所需站点语言文档齐全且与模板一致。
- release 与 practices 一致，或明确说明用户未授权交付阶段。
