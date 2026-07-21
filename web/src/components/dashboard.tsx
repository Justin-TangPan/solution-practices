"use client"

import Link from "next/link"
import { useState } from "react"
import { AlertTriangle, ArrowRight, CheckCircle2, ClipboardCheck, FileCode2, GitBranch, Layers3, ShieldAlert, Sparkles } from "lucide-react"
import type { WorkbenchSnapshot } from "@/lib/workbench"
import { cn } from "@/lib/utils"

export function Dashboard({ snapshot }: { snapshot: WorkbenchSnapshot }) {
  const [request, setRequest] = useState("")
  const totalInstances = snapshot.deployable.reduce((sum, item) => sum + item.regions.length, 0)
  const auditStatus = snapshot.audit.totalErrors ? "阻断" : snapshot.audit.totalWarnings ? "有警告" : "通过"
  const auditTone = snapshot.audit.totalErrors ? "text-red-700 bg-red-50" : snapshot.audit.totalWarnings ? "text-amber-800 bg-amber-50" : "text-emerald-800 bg-emerald-50"

  return <div className="px-5 md:px-10 py-8 md:py-12 max-w-[1500px] mx-auto space-y-7">
    <header className="flex flex-wrap items-end justify-between gap-5 border-b border-border pb-7">
      <div>
        <div className="eyebrow">SAC Solution Architect Studio</div>
        <h1 className="heading-lg text-ink mt-3">架构师驾驶舱</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-6">从正式方案、部署实例和质量门禁中提炼决策信息。所有数字均来自构建时快照，不代表实时云端状态。</p>
      </div>
      <div className="flex items-center gap-2 text-xs text-ink-muted"><GitBranch className="h-3.5 w-3.5" />{snapshot.revision}<span>·</span>{snapshot.generated.slice(0, 16).replace("T", " ")}</div>
    </header>

    <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
      <Metric icon={Layers3} label="正式方案" value={snapshot.practices.length} note="project.config.json" />
      <Metric icon={ClipboardCheck} label="部署实例" value={totalInstances} note="practices/ 结构扫描" />
      <Metric icon={FileCode2} label="Terraform" value={snapshot.assets.terraform} note="正式方案资产" />
      <Metric icon={ShieldAlert} label="质量警告" value={snapshot.audit.totalWarnings} note={`${snapshot.audit.totalErrors} 个错误`} tone={snapshot.audit.totalErrors ? "danger" : "warn"} />
      <Metric icon={CheckCircle2} label="门禁状态" value={auditStatus} note={`${snapshot.audit.totalPractices} 个实例`} tone={snapshot.audit.totalErrors ? "danger" : snapshot.audit.totalWarnings ? "warn" : "ok"} />
    </section>

    <section className="grid gap-6 xl:grid-cols-[1.45fr_0.85fr]">
      <div className="rounded-2xl border border-border bg-ink p-6 md:p-8 text-cream shadow-soft-lg">
        <div className="eyebrow text-cream/55">Architecture Intake · 草稿规划</div>
        <h2 className="serif text-2xl md:text-3xl font-bold mt-3">描述一个交付目标</h2>
        <p className="text-sm text-cream/65 mt-3 max-w-xl leading-6">输入仅用于生成浏览器会话中的规划草稿，不会执行 Agent、写入仓库或创建云资源。</p>
        <div className="mt-6 flex flex-col sm:flex-row gap-3"><input value={request} onChange={event => setRequest(event.target.value)} placeholder="例如：将 LiteLLM 部署到新加坡，使用 HA" className="min-w-0 flex-1 rounded-xl border border-white/15 bg-white/10 px-4 py-3 text-sm text-cream placeholder:text-cream/35 outline-none focus:border-accent" /><Link href="/workspace" className={cn("inline-flex items-center justify-center gap-2 rounded-xl px-4 py-3 text-sm font-bold transition", request.trim() ? "bg-accent text-white hover:bg-[#db7553]" : "bg-white/10 text-cream/60")}>进入架构工作区 <ArrowRight className="h-4 w-4" /></Link></div>
        <div className="mt-5 flex flex-wrap gap-2 text-[0.68rem] text-cream/55"><span className="rounded-full border border-white/15 px-2.5 py-1">方案合同</span><span className="rounded-full border border-white/15 px-2.5 py-1">Region 冲突检测</span><span className="rounded-full border border-white/15 px-2.5 py-1">资源拓扑</span><span className="rounded-full border border-white/15 px-2.5 py-1">质量证据</span></div>
      </div>
      <div className="rounded-2xl border border-border bg-surface p-6 shadow-soft"><div className="flex items-center justify-between"><div><div className="eyebrow">Quality Gate</div><h2 className="serif text-xl font-bold text-ink mt-2">当前门禁</h2></div><span className={cn("rounded-full px-2.5 py-1 text-xs font-bold", auditTone)}>{auditStatus}</span></div><div className="mt-6 grid grid-cols-3 gap-3"><Stat label="检查项" value={snapshot.audit.results.reduce((sum, result) => sum + result.total, 0)} /><Stat label="错误" value={snapshot.audit.totalErrors} tone={snapshot.audit.totalErrors ? "danger" : undefined} /><Stat label="警告" value={snapshot.audit.totalWarnings} tone={snapshot.audit.totalWarnings ? "warn" : undefined} /></div><Link href="/quality" className="mt-6 inline-flex items-center gap-1.5 text-sm font-bold text-ink hover:text-accent">查看质量证据 <ArrowRight className="h-4 w-4" /></Link></div>
    </section>

    <section className="grid gap-6 lg:grid-cols-[1.25fr_0.75fr]">
      <div className="rounded-2xl border border-border bg-surface shadow-soft overflow-hidden"><div className="flex items-end justify-between gap-4 px-6 pt-6 pb-4"><div><div className="eyebrow">Formal Portfolio</div><h2 className="serif text-xl font-bold text-ink mt-2">正式方案组合</h2></div><Link href="/practices" className="text-xs font-bold text-ink-muted hover:text-ink">查看全部 →</Link></div><div className="divide-y divide-border-light">{snapshot.practices.map(practice => { const item = snapshot.deployable.find(entry => entry.slug === practice.slug); const result = snapshot.audit.results.filter(entry => entry.practice.startsWith(`${practice.slug}/`)); const errors = result.reduce((sum, entry) => sum + entry.errors, 0); return <Link key={practice.slug} href={`/practices/${practice.slug}`} className="grid grid-cols-[1fr_auto] gap-4 px-6 py-4 hover:bg-cream/60 transition"><div><div className="flex items-center gap-2"><span className="serif font-bold text-ink">{practice.name}</span><span className="eyebrow">{practice.category}</span></div><p className="text-xs text-ink-faded mt-1">{practice.tagline}</p><div className="flex flex-wrap gap-2 mt-3 text-[0.68rem] text-ink-muted"><span>{item?.regions.length ?? 0} 个实例</span><span>·</span><span>{practice.hasHA ? "Standard / HA" : "Standard"}</span><span>·</span><span>{practice.regions.length} 个区域</span></div></div><div className="flex items-center gap-3 self-center">{errors ? <span className="rounded-full bg-red-50 px-2 py-1 text-[0.65rem] font-bold text-red-700">{errors} 错误</span> : <span className="rounded-full bg-emerald-50 px-2 py-1 text-[0.65rem] font-bold text-emerald-800">无错误</span>}<ArrowRight className="h-4 w-4 text-ink-muted" /></div></Link> })}</div></div>
      <div className="rounded-2xl border border-border bg-surface p-6 shadow-soft"><div className="flex items-center gap-2"><Sparkles className="h-4 w-4 text-accent" /><div><div className="eyebrow">Evidence Sources</div><h2 className="serif text-xl font-bold text-ink mt-2">数据可信度</h2></div></div><div className="mt-6 space-y-3">{snapshot.evidence.map(item => <div key={item.source} className="rounded-xl bg-cream p-4"><div className="flex items-center justify-between gap-3"><span className="text-sm font-bold text-ink">{item.source}</span><span className={cn("rounded-full px-2 py-0.5 text-[0.62rem] font-bold", item.kind === "事实" ? "bg-emerald-50 text-emerald-800" : "bg-blue-50 text-blue-800")}>{item.kind}</span></div><p className="text-xs text-ink-muted mt-1.5 leading-5">{item.note}</p></div>)}</div><p className="text-[0.68rem] text-ink-muted mt-5 flex gap-2"><AlertTriangle className="h-3.5 w-3.5 shrink-0 text-amber-600" />编辑性评分和业务说明不会覆盖 Terraform、规则与质量结果。</p></div>
    </section>
  </div>
}

function Metric({ icon: Icon, label, value, note, tone }: { icon: typeof Layers3; label: string; value: number | string; note: string; tone?: "danger" | "warn" | "ok" }) { return <div className="rounded-xl border border-border bg-surface p-4 shadow-soft"><div className="flex items-center justify-between"><Icon className={cn("h-4 w-4", tone === "danger" ? "text-red-600" : tone === "warn" ? "text-amber-600" : tone === "ok" ? "text-emerald-600" : "text-accent")} /><span className="eyebrow">{label}</span></div><div className="serif text-3xl font-bold text-ink mt-4 tabular-nums">{value}</div><div className="text-[0.68rem] text-ink-muted mt-1">{note}</div></div> }
function Stat({ label, value, tone }: { label: string; value: number; tone?: "danger" | "warn" }) { return <div className="rounded-xl bg-cream p-3"><div className="eyebrow">{label}</div><div className={cn("serif text-2xl font-bold mt-2", tone === "danger" ? "text-red-600" : tone === "warn" ? "text-amber-600" : "text-ink")}>{value}</div></div> }
