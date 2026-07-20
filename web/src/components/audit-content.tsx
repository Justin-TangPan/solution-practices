"use client"

import { useState } from "react"
import { AlertTriangle, CheckCircle2, ChevronDown, MapPinned, ShieldCheck, XCircle } from "lucide-react"
import { cn } from "@/lib/utils"
import type { AuditReport, AuditResult } from "@/lib/audit"

const gates = [
  ["consistency", "目录规范"],
  ["tf_syntax", "Terraform"],
  ["scripts", "脚本质量"],
  ["docs", "文档完整性"],
  ["network", "网络与安全"],
  ["rfs_policy", "RFS 策略"],
] as const

const coverage = [
  ["LiteLLM Standard", true, true, true, true, true, true],
  ["LiteLLM HA", true, true, true, true, true, true],
  ["Supabase", true, true, false, false, false, false],
  ["openJiuwen", true, false, false, false, false, false],
] as const

function PracticeCard({ result }: { result: AuditResult }) {
  const [open, setOpen] = useState(false)
  const visible = result.items.filter(item => item.severity !== "INFO")

  return (
    <article className={cn("overflow-hidden rounded-xl border bg-surface shadow-soft", result.errors ? "border-red-200" : "border-border")}>
      <button onClick={() => setOpen(value => !value)} className="flex w-full items-center gap-4 px-5 py-4 text-left transition hover:bg-cream/50" aria-expanded={open}>
        {result.errors ? <XCircle className="h-5 w-5 shrink-0 text-red-600" /> : result.warnings ? <AlertTriangle className="h-5 w-5 shrink-0 text-amber-600" /> : <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-600" />}
        <span className="min-w-0 flex-1"><span className="block truncate text-sm font-bold text-ink">{result.practice}</span><span className="mt-1 block text-xs text-ink-muted">{result.total} 项检查 · {result.errors} 错误 · {result.warnings} 警告</span></span>
        <span className={cn("rounded-full px-2.5 py-1 text-[0.65rem] font-bold", result.errors ? "bg-red-50 text-red-700" : result.warnings ? "bg-amber-50 text-amber-700" : "bg-emerald-50 text-emerald-700")}>{result.errors ? "未通过" : result.warnings ? "有警告" : "已通过"}</span>
        <ChevronDown className={cn("h-4 w-4 text-ink-muted transition", open && "rotate-180")} />
      </button>
      {open && <div className="space-y-2 border-t border-border bg-cream/30 px-5 py-4">
        {(visible.length ? visible : result.items.slice(0, 3)).map((item, index) => <div key={`${item.check_name}-${index}`} className="grid gap-1 rounded-lg bg-surface p-3 text-xs sm:grid-cols-[7rem_1fr]">
          <span className={cn("font-mono font-bold", item.severity === "ERROR" ? "text-red-700" : item.severity === "WARN" ? "text-amber-700" : "text-ink-muted")}>{item.check_name}</span>
          <span className="leading-5 text-ink-faded">{item.message}</span>
        </div>)}
      </div>}
    </article>
  )
}

export function AuditContent({ results, generated, totalErrors, totalWarnings, totalPractices }: AuditReport) {
  const [filter, setFilter] = useState<"all" | "error" | "warn">(totalErrors ? "error" : "all")
  const checks = results.flatMap(result => result.items)
  const filtered = results.filter(result => filter === "error" ? result.errors > 0 : filter === "warn" ? result.warnings > 0 : true)
  const totalChecks = results.reduce((sum, result) => sum + result.total, 0)

  return <>
    <section className="grid gap-6 lg:grid-cols-[1.35fr_1fr]">
      <div className={cn("rounded-2xl border p-6 md:p-8", totalErrors ? "border-red-200 bg-red-50" : "border-border bg-ink text-cream")}>
        <div className="flex items-start justify-between gap-5">
          <div><div className={cn("eyebrow", !totalErrors && "text-cream/60")}>Quality Gate</div><h2 className="serif mt-2 text-3xl font-bold">{totalErrors ? "质量门禁未通过" : totalWarnings ? "质量门禁通过，有警告" : "质量门禁已通过"}</h2><p className={cn("mt-3 text-sm", totalErrors ? "text-red-900" : "text-cream/65")}>{totalErrors ? `${totalErrors} 个错误需要先处理，暂不应进入正式交付。` : `${totalPractices} 个实例已完成结构化检查。`}</p></div>
          {totalErrors ? <XCircle className="h-9 w-9 shrink-0 text-red-700" /> : <ShieldCheck className="h-9 w-9 shrink-0 text-emerald-400" />}
        </div>
        <div className={cn("mt-8 border-t pt-4 text-xs", totalErrors ? "border-red-200 text-red-800" : "border-white/15 text-cream/55")}>报告生成：{generated.slice(0, 16).replace("T", " ")} · 构建时快照</div>
      </div>
      <div className="grid grid-cols-2 gap-3">
        {[["检查实例", totalPractices], ["检查项", totalChecks], ["错误", totalErrors], ["警告", totalWarnings]].map(([label, value]) => <div key={label} className="rounded-xl border border-border bg-surface p-5 shadow-soft"><div className="eyebrow">{label}</div><div className={cn("serif mt-3 text-3xl font-bold tabular-nums", label === "错误" && Number(value) > 0 ? "text-red-600" : label === "警告" && Number(value) > 0 ? "text-amber-600" : "text-ink")}>{value}</div></div>)}
      </div>
    </section>

    <section className="rounded-2xl border border-border bg-surface p-6 md:p-7 shadow-soft">
      <div className="flex items-baseline justify-between gap-4"><div><div className="eyebrow">Gate Overview</div><h2 className="serif mt-2 text-xl font-bold text-ink">质量门禁总览</h2></div><span className="text-xs text-ink-muted">6 类检查</span></div>
      <div className="mt-6 grid gap-2 md:grid-cols-2">
        {gates.map(([key, label]) => {
          const items = checks.filter(item => item.check_name === key)
          const errors = items.filter(item => item.severity === "ERROR").length
          const warnings = items.filter(item => item.severity === "WARN").length
          return <div key={key} className="flex items-center gap-3 rounded-xl bg-cream p-4">{errors ? <XCircle className="h-4 w-4 text-red-600" /> : warnings ? <AlertTriangle className="h-4 w-4 text-amber-600" /> : <CheckCircle2 className="h-4 w-4 text-emerald-600" />}<span className="flex-1 text-sm font-medium text-ink">{label}</span><span className="text-xs text-ink-muted">{errors ? `${errors} 错误` : warnings ? `${warnings} 警告` : items.length ? "已通过" : "未运行"}</span></div>
        })}
      </div>
    </section>

    <section>
      <div className="mb-5 flex flex-wrap items-end justify-between gap-4"><div><div className="eyebrow">Issues</div><h2 className="serif mt-2 text-xl font-bold text-ink">问题列表</h2></div><div className="flex gap-1 rounded-lg bg-surface p-1 shadow-soft">{[["all", "全部"], ["error", "错误"], ["warn", "警告"]].map(([key, label]) => <button key={key} onClick={() => setFilter(key as typeof filter)} className={cn("rounded-md px-3 py-1.5 text-xs", filter === key ? "bg-ink text-cream" : "text-ink-muted hover:text-ink")}>{label}</button>)}</div></div>
      <div className="space-y-3">{filtered.length ? filtered.map(result => <PracticeCard key={result.practice} result={result} />) : <div className="rounded-xl border border-border bg-surface p-8 text-center text-sm text-ink-muted">当前筛选下没有问题。</div>}</div>
    </section>

    <section className="rounded-2xl border border-border bg-surface p-6 md:p-7 shadow-soft">
      <div className="flex items-center gap-3"><MapPinned className="h-5 w-5 text-accent" /><div><div className="eyebrow">Coverage Matrix</div><h2 className="serif mt-1 text-xl font-bold text-ink">区域覆盖矩阵</h2></div></div>
      <div className="mt-6 overflow-x-auto"><table className="w-full min-w-[46rem] text-left text-xs"><thead><tr className="border-b border-border text-ink-muted">{["方案", "北京四", "香港", "新加坡", "曼谷", "拉美", "南非"].map(label => <th key={label} className="px-3 py-3 font-medium">{label}</th>)}</tr></thead><tbody>{coverage.map(([name, ...regions]) => <tr key={name} className="border-b border-border-light last:border-0"><td className="px-3 py-4 font-bold text-ink">{name}</td>{regions.map((covered, index) => <td key={index} className="px-3 py-4">{covered ? <CheckCircle2 className="h-4 w-4 text-emerald-600" aria-label="支持" /> : <span className="text-ink-muted">—</span>}</td>)}</tr>)}</tbody></table></div>
    </section>
  </>
}
