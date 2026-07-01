import Link from "next/link"
import { practices, evaluations } from "@/lib/catalog"
import { regions } from "@/lib/regions"
import { ScoreBarChart, EvalRadarChart } from "@/components/charts"
import { ArrowRight } from "lucide-react"

export default function Home() {
  const avgScore = (practices.reduce((s, p) => s + p.score, 0) / practices.length).toFixed(2)
  const strongCount = practices.filter(p => p.tier === "strong").length
  const top3 = [...practices].sort((a, b) => b.score - a.score).slice(0, 3)
  const barData = [...practices].sort((a, b) => b.score - a.score).map(p => ({ name: p.name, score: p.score }))

  const dims = [
    { dim: "服务端", key: "d1" as const },
    { dim: "营销", key: "d2" as const },
    { dim: "场景", key: "d3" as const },
    { dim: "云上", key: "d4" as const },
  ]
  const radarData = dims.map(d => ({ dim: d.dim, value: +(evaluations.reduce((s, e) => s + e[d.key], 0) / evaluations.length).toFixed(2) }))

  const stats = [
    { label: "方案总数", value: practices.length, sub: "已收录实践" },
    { label: "强推荐", value: strongCount, sub: "tier = strong" },
    { label: "平均分", value: avgScore, sub: "综合评分" },
    { label: "覆盖区域", value: regions.length, sub: "Region" },
  ]

  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      {/* 页头 */}
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Overview</div>
        <h1 className="heading-lg text-ink">SAC 总览</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          华为云解决方案实践目录 — 方案收录、业务评估与部署向导的可视化总览。
        </p>
      </header>

      {/* 统计卡片 */}
      <section className="grid grid-cols-2 md:grid-cols-4 gap-6">
        {stats.map(s => (
          <div key={s.label} className="bg-surface rounded-xl border border-border p-6 shadow-soft">
            <div className="eyebrow mb-3">{s.label}</div>
            <div className="serif text-4xl font-bold text-ink tabular-nums leading-none">{s.value}</div>
            <div className="text-xs text-ink-muted mt-2">{s.sub}</div>
          </div>
        ))}
      </section>

      {/* 推荐方案 + 评分分布 */}
      <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-surface rounded-xl border border-border p-7 shadow-soft">
          <div className="flex items-baseline justify-between mb-6">
            <h2 className="serif text-xl font-bold text-ink">推荐方案</h2>
            <span className="eyebrow">Top 3</span>
          </div>
          <div className="space-y-3">
            {top3.map((p, i) => (
              <Link key={p.slug} href={`/practices/${p.slug}`} className="group flex items-center gap-5 py-3 border-b border-border-light last:border-0 transition-colors hover:bg-cream -mx-3 px-3 rounded-lg">
                <span className="eyebrow w-6">{String(i + 1).padStart(2, "0")}</span>
                <div className="flex-1 min-w-0">
                  <div className="font-bold text-ink group-hover:text-accent transition-colors">{p.name}</div>
                  <div className="text-xs text-ink-muted mt-0.5">{p.category} · {p.tagline}</div>
                </div>
                <span className="serif text-lg font-bold text-ink tabular-nums">{p.score.toFixed(1)}</span>
                <ArrowRight className="h-4 w-4 text-ink-muted group-hover:text-accent transition-colors" />
              </Link>
            ))}
          </div>
        </div>

        <div className="bg-surface rounded-xl border border-border p-7 shadow-soft">
          <div className="flex items-baseline justify-between mb-6">
            <h2 className="serif text-xl font-bold text-ink">评分分布</h2>
            <span className="eyebrow">Score</span>
          </div>
          <ScoreBarChart data={barData} />
        </div>
      </section>

      {/* 评估雷达 + 评估表 */}
      <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-surface rounded-xl border border-border p-7 shadow-soft">
          <div className="flex items-baseline justify-between mb-4">
            <h2 className="serif text-xl font-bold text-ink">业务评估雷达</h2>
            <span className="eyebrow">4 维均值</span>
          </div>
          <EvalRadarChart data={radarData} />
        </div>

        <div className="bg-surface rounded-xl border border-border p-7 shadow-soft">
          <div className="flex items-baseline justify-between mb-6">
            <h2 className="serif text-xl font-bold text-ink">已评估方案</h2>
            <span className="eyebrow">{evaluations.length} 项</span>
          </div>
          <div className="space-y-3">
            {evaluations.map(e => (
              <div key={e.name} className="flex items-center gap-4 py-2.5 border-b border-border-light last:border-0">
                <div className="flex-1 min-w-0">
                  <div className="font-bold text-ink">{e.name}</div>
                  <div className="text-xs text-ink-muted mt-0.5 truncate">{e.url}</div>
                </div>
                <span className="serif text-lg font-bold text-ink tabular-nums">{e.total.toFixed(1)}</span>
                <span className="eyebrow w-14 text-right" style={{ color: e.grade === "green" ? "var(--ink)" : e.grade === "amber" ? "var(--accent)" : "var(--ink-muted)" }}>
                  {e.grade === "green" ? "推荐" : e.grade === "amber" ? "可选" : "不建议"}
                </span>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}
