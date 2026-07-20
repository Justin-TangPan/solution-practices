// Server component — build 时获取审计数据
import { getAuditResults } from "@/lib/audit"
import { AuditContent } from "@/components/audit-content"

export default function AuditPage() {
  const report = getAuditResults()
  return (
    <div className="px-5 md:px-10 py-10 md:py-14 max-w-7xl mx-auto space-y-8">
      <header className="border-b border-border pb-8">
        <div className="flex flex-wrap items-center gap-3">
          <span className="eyebrow">Quality Center</span>
          <span className="rounded-full border border-border bg-surface px-2 py-1 text-[0.65rem] text-ink-muted">构建时真实检查结果</span>
        </div>
        <h1 className="heading-lg text-ink mt-3">质量中心</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          从总门禁进入具体问题，再查看方案和区域覆盖。数据直接来自 SAC 测试运行器，不解析终端展示文本。
        </p>
      </header>
      <AuditContent {...report} />
    </div>
  )
}
