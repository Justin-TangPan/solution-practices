"use client"

import Link from "next/link"
import { useState } from "react"
import { AlertTriangle, ArrowRight, CheckCircle2, FileCode2, Sparkles } from "lucide-react"

const example = "我需要将 LiteLLM 高可用部署到华为云新加坡区域，使用 PostgreSQL，并提供中英文文档。"

export default function Home() {
  const [request, setRequest] = useState(example)
  const [generated, setGenerated] = useState(false)

  return (
    <div className="px-5 md:px-10 py-10 md:py-14 max-w-6xl mx-auto space-y-8">
      <header className="border-b border-border pb-8">
        <div className="flex flex-wrap items-center gap-3 mb-3">
          <span className="eyebrow">Delivery Workbench</span>
          <span className="rounded-full border border-amber-300 bg-amber-50 px-2 py-1 text-[0.65rem] font-semibold text-amber-800">静态原型 · 演示数据</span>
        </div>
        <h1 className="heading-lg text-ink">描述目标，生成交付任务</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">从业务需求开始，而不是从文件或统计图开始。原型仅演示任务解析与流水线交互，不会执行 Agent 或云端操作。</p>
      </header>

      <section className="bg-surface rounded-2xl border border-border p-5 md:p-8 shadow-soft-lg">
        <label htmlFor="delivery-request" className="serif text-xl font-bold text-ink">你希望交付什么？</label>
        <textarea
          id="delivery-request"
          value={request}
          onChange={event => setRequest(event.target.value)}
          rows={5}
          className="mt-5 w-full resize-none rounded-xl border border-border bg-cream/50 p-4 text-base leading-7 text-ink outline-none transition focus:border-accent"
        />
        <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs text-ink-muted">系统将提取应用、站点、区域、形态、交付物和待确认项。</p>
          <button onClick={() => setGenerated(true)} disabled={!request.trim()} className="inline-flex items-center gap-2 rounded-lg bg-ink px-5 py-2.5 text-sm font-medium text-cream transition hover:bg-accent disabled:opacity-40">
            <Sparkles className="h-4 w-4" /> 生成任务卡
          </button>
        </div>
      </section>

      {generated && (
        <section className="grid gap-6 lg:grid-cols-[1fr_18rem]">
          <div className="bg-surface rounded-2xl border border-border p-6 md:p-8 shadow-soft">
            <div className="flex flex-wrap items-start justify-between gap-4 border-b border-border pb-5">
              <div>
                <div className="eyebrow">Delivery Task · Draft</div>
                <h2 className="serif text-2xl font-bold text-ink mt-2">LiteLLM 高可用交付</h2>
              </div>
              <span className="rounded-full bg-amber-100 px-3 py-1.5 text-xs font-bold text-amber-900">等待用户确认</span>
            </div>

            <dl className="grid sm:grid-cols-2 gap-x-8 gap-y-5 py-6 text-sm">
              {[
                ["应用", "LiteLLM"], ["站点", "INTL"], ["区域", "ap-southeast-3 · 亚太-新加坡"],
                ["形态", "HA"], ["数据库", "PostgreSQL / RDS（待定规格）"], ["文档", "中文 / English"],
              ].map(([label, value]) => <div key={label}><dt className="eyebrow mb-1">{label}</dt><dd className="font-medium text-ink">{value}</dd></div>)}
            </dl>

            <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 flex gap-3">
              <AlertTriangle className="h-5 w-5 shrink-0 text-amber-700" />
              <div>
                <div className="text-sm font-bold text-amber-950">检测到区域语义冲突</div>
                <p className="text-xs leading-5 text-amber-900 mt-1">用户示例写的是“新加坡”与 <code>ap-southeast-1</code>，但仓库正式映射中，新加坡是 <code>ap-southeast-3</code>；<code>ap-southeast-1</code> 是中国香港。本任务卡采用新加坡代码，进入流水线前仍需确认。</p>
              </div>
            </div>

            <div className="mt-6 flex flex-wrap items-center gap-3">
              <Link href="/deploy" className="inline-flex items-center gap-2 rounded-lg bg-ink px-5 py-2.5 text-sm font-medium text-cream transition hover:bg-accent">确认并查看流水线 <ArrowRight className="h-4 w-4" /></Link>
              <button onClick={() => setGenerated(false)} className="rounded-lg border border-border px-5 py-2.5 text-sm text-ink-faded hover:bg-cream">返回修改</button>
            </div>
          </div>

          <aside className="space-y-4">
            <div className="bg-surface rounded-xl border border-border p-5 shadow-soft">
              <div className="flex items-center gap-2 mb-4"><FileCode2 className="h-4 w-4 text-accent" /><h3 className="font-bold text-sm text-ink">计划输出</h3></div>
              <ul className="space-y-2 text-xs text-ink-faded">{["Terraform 模板", "内联安装逻辑", "部署指南", "方案详情", "部署链接（未生成）"].map(item => <li key={item} className="flex gap-2"><CheckCircle2 className="h-3.5 w-3.5 shrink-0 text-ink-muted" />{item}</li>)}</ul>
            </div>
            <div className="bg-ink rounded-xl p-5 text-cream">
              <div className="eyebrow text-cream/60 mb-3">Decision Points</div>
              <p className="text-sm font-bold">数据库规格、域名、网络方式</p>
              <p className="text-xs text-cream/60 mt-2 leading-5">确认动作仅进入演示流水线，不会创建真实资源。</p>
            </div>
          </aside>
        </section>
      )}
    </div>
  )
}
