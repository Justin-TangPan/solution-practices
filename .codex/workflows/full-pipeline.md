# full-pipeline — SAC Codex 全流程

## 输入

`project`、`regions`（`site/region`，例如 `cn/cn-north-4`）、`description`；可选 `variants`、`deployment constraints`。

## 阶段

1. **Assess + Draft**：主 Agent 承担最终架构责任，派发只读 `architect` 收集系统评估证据和初版方案候选；主 Agent 审阅后向用户呈现初版方案与未决输入。
2. **Confirm + Freeze**：确认站点、Region、standard/ha、模板与安装策略、运行方式、公网入口和产品特有外部依赖，冻结完整 `architecture_contract`；合同不完整或必要确认缺失时停止。
3. **Develop**：主 Agent 将完整合同下发给按不重叠区域/variant 分配的 `developer`；可并行。
4. **Test + Security**：开发完成后并行派发只读 `tester` 与 `security`；tester 必须运行 `rfs_policy`。
5. **Remediation gate**：若存在 error 或 critical/high，主 Agent先组织最小修复并重新审计；不得直接进入交付。
6. **Cloud-test gate**：主 Agent 整理明确标记为非最终交付的候选包，由用户在目标云环境测试；仅接受与精确候选版本绑定的结果，成功后再提升为正式入口。
7. **Document**：按站点/语言拆分 `documenter`；依次完成材料分析、统一模型、中文正文、
   受保护翻译、Markdown/Word 渲染、文档质量检查和人工审核清单；国际站中英文必须成对完成。
8. **Document gate**：结构化质量报告存在 error 或仍有阻断型人工确认项时停止，不得标记可交付。
9. **Deliver**：仅在测试、安全、文档和用户云测门禁均通过后派发 `delivery` 组装本地交付包。
10. **Final verify**：主 Agent运行仓库正式质量门禁、检查 diff、记录内部 changelog 并汇总交付物。

## 数据流

```text
system assessment + initial solution
        ↓
user confirmation → architecture_contract
        ↓
regional developers
        ↓
tester ─┬─ security
        ↓
site + docs-locale documenters
        ↓
delivery → main-agent final verification
```

## 完成条件

- 所有目标区域/variant 的实现存在。
- 正式测试无 error；安全无 critical/high。
- 所需站点语言 Markdown 齐全；仅在配置或用户要求时需要 Word。质量报告无阻断错误且人工审核清单已交接。
- release 与 practices 一致，或明确说明用户未授权交付阶段。
