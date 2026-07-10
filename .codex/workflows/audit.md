# audit — SAC Codex 审计

## 输入

`project`；可选 `regions`、`variants`、`fix=false`。

## 阶段

1. 主 Agent确认审计范围和现有工作区修改。
2. 并行派发只读 `tester` 与 `security`。
3. 主 Agent去重、校验证据并按严重级别汇总。
4. 仅当用户明确要求修复或 `fix=true` 时，派发范围明确的 `developer` 修复。
5. 修复后重新运行相关测试和安全检查。

## 输出

给出总体通过状态、阻塞问题、非阻塞警告、证据、已运行命令和建议修复顺序。未要求修复时
不得改动 practice 文件。
