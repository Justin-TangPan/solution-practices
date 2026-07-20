"use client"

import { useState } from "react"
import Link from "next/link"
import { ArrowRight, Copy, MapPin, Rocket, Search } from "lucide-react"

const solutions = [
  { slug: "litellm", name: "LiteLLM", type: "AI 网关", desc: "多模型 API 统一管理网关", sites: "CN / INTL", variants: "Standard / HA", regions: "北京四、香港、新加坡等 9 个区域", docs: "中文 / English", deploy: true },
  { slug: "supabase", name: "Supabase", type: "BaaS", desc: "PostgreSQL 驱动的开源后端平台", sites: "CN / INTL", variants: "Standard", regions: "北京四、香港", docs: "中文 / English", deploy: true },
  { slug: "openjiuwen", name: "openJiuwen", type: "AI 平台", desc: "企业级 Agent 开发与编排平台", sites: "CN", variants: "Standard", regions: "北京四", docs: "中文", deploy: false },
]

export default function PracticesPage() {
  const [query, setQuery] = useState("")
  const [site, setSite] = useState("全部站点")
  const [variant, setVariant] = useState("全部形态")
  const [language, setLanguage] = useState("全部语言")
  const [deploy, setDeploy] = useState("部署能力")
  const filtered = solutions.filter(solution =>
    `${solution.name}${solution.type}${solution.desc}${solution.regions}`.toLowerCase().includes(query.toLowerCase()) &&
    (site === "全部站点" || solution.sites.includes(site)) &&
    (variant === "全部形态" || solution.variants.includes(variant)) &&
    (language === "全部语言" || solution.docs.includes(language)) &&
    (deploy === "部署能力" || (deploy === "支持一键部署" ? solution.deploy : !solution.deploy))
  )

  return (
    <div className="px-5 md:px-10 py-10 md:py-14 max-w-7xl mx-auto space-y-8">
      <header className="border-b border-border pb-8">
        <div className="flex flex-wrap gap-3 items-center"><span className="eyebrow">Solution Center</span><span className="rounded-full border border-border bg-surface px-2 py-1 text-[0.65rem] text-ink-muted">正式范围 · 3 项</span></div>
        <h1 className="heading-lg text-ink mt-3">解决方案库</h1>
        <p className="text-sm text-ink-faded mt-3">以方案能力和部署条件组织，不把仓库目录当作产品界面。质量与一键部署状态仅作原型展示。</p>
      </header>

      <section className="rounded-xl border border-border bg-surface p-4 shadow-soft flex flex-wrap gap-3">
        <label className="flex min-w-60 flex-1 items-center gap-2 rounded-lg border border-border px-3 py-2"><Search className="h-4 w-4 text-ink-muted" /><input value={query} onChange={event => setQuery(event.target.value)} placeholder="搜索应用、类型或区域" className="w-full bg-transparent text-sm outline-none" /></label>
        <select aria-label="站点" value={site} onChange={event => setSite(event.target.value)} className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-ink"><option>全部站点</option><option>CN</option><option>INTL</option></select>
        <select aria-label="部署形态" value={variant} onChange={event => setVariant(event.target.value)} className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-ink"><option>全部形态</option><option>Standard</option><option>HA</option></select>
        <select aria-label="语言" value={language} onChange={event => setLanguage(event.target.value)} className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-ink"><option>全部语言</option><option>中文</option><option>English</option></select>
        <select aria-label="一键部署" value={deploy} onChange={event => setDeploy(event.target.value)} className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-ink"><option>部署能力</option><option>支持一键部署</option><option>链接未生成</option></select>
      </section>

      <div className="grid gap-6 xl:grid-cols-3">
        {filtered.map(solution => (
          <article key={solution.slug} className="bg-surface rounded-2xl border border-border p-6 shadow-soft flex flex-col">
            <div className="flex items-start justify-between gap-4"><div><div className="eyebrow">{solution.type}</div><h2 className="serif text-2xl font-bold text-ink mt-2">{solution.name}</h2><p className="text-sm text-ink-faded mt-2">{solution.desc}</p></div><span className="rounded-full bg-emerald-50 px-2 py-1 text-[0.65rem] font-bold text-emerald-800">正式范围</span></div>
            <dl className="mt-6 grid gap-3 text-xs">
              {[['部署形态', solution.variants], ['站点', solution.sites], ['区域', solution.regions], ['文档', solution.docs], ['质量状态', '未运行 · 原型'], ['部署链接', solution.deploy ? '能力已收录 · URL 未展示' : '未生成']].map(([label, value]) => <div key={label} className="grid grid-cols-[5rem_1fr] gap-3 border-b border-border-light pb-3"><dt className="text-ink-muted">{label}</dt><dd className="font-medium text-ink">{value}</dd></div>)}
            </dl>
            <div className="mt-6 flex flex-wrap items-center gap-2">
              <Link href={`/practices/${solution.slug}`} className="inline-flex items-center gap-1.5 rounded-lg bg-ink px-4 py-2 text-xs font-bold text-cream">查看详情 <ArrowRight className="h-3.5 w-3.5" /></Link>
              <button className="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs text-ink-faded"><Copy className="h-3.5 w-3.5" />复制方案</button>
              <Link href="/" className="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs text-ink-faded"><Rocket className="h-3.5 w-3.5" />开始部署</Link>
            </div>
          </article>
        ))}
      </div>

      {filtered.length === 0 && <div className="rounded-xl border border-border bg-surface p-10 text-center"><MapPin className="h-6 w-6 mx-auto text-ink-muted" /><p className="text-sm text-ink-faded mt-3">没有符合当前筛选的正式方案。</p></div>}
    </div>
  )
}
