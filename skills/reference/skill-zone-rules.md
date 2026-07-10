# Skill Zone 规则（Agent 共享）

> 本文档定义了 SAC Agent 框架中技能加载（Skill Zone）的通用规则。
> 所有 Agent 引用此文件而非各自维护，确保规则一致。

## R1: 意图预检

加载任何技能前，先判断用户查询是否匹配当前 Agent 的 `skill_binding` 注册范围；
不匹配时跳过技能加载，直接使用基线能力。

## R2: 冲突抑制

查询同时命中多个技能时，优先选择 `skills-index.json` 中 `category`、`keywords`、`agents` 和 `status/scope` 最匹配当前任务的技能；
若两个技能声明了 `conflicts_with` 关系，不得同时加载。

## R3: 递归限制

技能加载深度上限 = 1 层。技能内容中不得递归引用加载其他技能。
所有跨技能引用必须通过 `reference/*.md` 公共参考文档完成。

## R4: 技能区生命周期

每次 Agent 执行完成后，清空 ZONE 3（技能区）上下文，
仅保留 ZONE 1（系统指令）+ ZONE 2（用户查询）+ ZONE 4（滑动历史窗口）。
