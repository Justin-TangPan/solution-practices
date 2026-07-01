"use client"

import { useState } from "react"
import Link from "next/link"
import { practices } from "@/lib/catalog"
import { Search, ArrowRight } from "lucide-react"
import { cn } from "@/lib/utils"

const cats = ["全部", ...new Set(practices.map(p => p.category))]
const tierLabel: Record<string, string> = { strong: "强烈推荐", good: "推荐", fair: "可选" }

export default function PracticesPage() {
  const [q, setQ] = useState("")
  const [cat, setCat] = useState("全部")
  const filtered = practices
    .filter(p => p.name.toLowerCase().includes(q.toLowerCase()) || p.desc.includes(q))
    .filter(p => cat === "全部" || p.category === cat)
    .sort((a, b) => b.score - a.score)

  return (
    <div className="px-10 py-14 max-w-none">
      {/* 编辑式页头 */}
      <header className="border-b border-border pb-8 mb-10">
        <div className="eyebrow mb-3">Solution Catalog</div>
        <h1 className="heading-lg text-ink">方案目录</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-xl leading-relaxed">
          所有解决方案实践，按业务评估综合得分排序。共 {practices.length} 个方案。
        </p>
      </header>

      {/* 工具栏：圆角搜索 + 胶囊分类 */}
      <div className="flex items-center gap-6 mb-10">
        <div className="flex items-center gap-2 bg-surface border border-border rounded-lg px-3.5 py-2 w-64 shadow-soft focus-within:border-ink/30 focus-within:shadow-soft-lg transition-all">
          <Search className="h-3.5 w-3.5 text-ink-muted" />
          <input value={q} onChange={e => setQ(e.target.value)} placeholder="搜索方案..." className="bg-transparent text-sm focus:outline-none w-full text-ink placeholder:text-ink-muted" />
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          {cats.map(c => (
            <button key={c} onClick={() => setCat(c)} className={cn("px-3 py-1.5 text-xs rounded-full transition-all", cat === c ? "bg-ink text-cream shadow-soft" : "text-ink-faded hover:text-ink hover:bg-surface border border-border")}>{c}</button>
          ))}
        </div>
      </div>

      {/* 圆角卡片网格 */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-6">
        {filtered.map((p, i) => (
          <Link key={p.slug} href={`/practices/${p.slug}`} className="group bg-surface rounded-xl border border-border p-7 shadow-soft hover:shadow-soft-lg hover:-translate-y-0.5 transition-all flex flex-col min-h-[15rem]">
            <div className="flex items-start justify-between mb-5">
              <span className="eyebrow">{String(i + 1).padStart(2, "0")}</span>
              <span className="text-2xl serif font-bold text-ink tabular-nums">{p.score.toFixed(1)}</span>
            </div>
            <h3 className="serif text-xl font-bold text-ink leading-tight group-hover:text-accent transition-colors">{p.name}</h3>
            <div className="eyebrow mt-1.5">{p.category}</div>
            <p className="text-sm text-ink-faded leading-relaxed mt-4 flex-1">{p.desc}</p>
            <div className="flex items-center justify-between mt-6 pt-4 border-t border-border-light">
              <span className="eyebrow">{tierLabel[p.tier]}</span>
              <span className="flex items-center gap-1 text-xs text-ink-faded group-hover:text-accent transition-colors">
                {p.regions.length} 区域 <ArrowRight className="h-3 w-3" />
              </span>
            </div>
          </Link>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="bg-surface rounded-xl border border-border p-8 shadow-soft">
          <p className="eyebrow">No Match</p>
          <p className="serif text-2xl text-ink mt-2">未匹配到任何方案</p>
        </div>
      )}
    </div>
  )
}
