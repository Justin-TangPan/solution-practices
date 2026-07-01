import { evaluations } from "@/lib/catalog"
import { EvalRadarChart } from "@/components/charts"

const dimensions = [
  { key: "d1" as const, label: "D1 服务端", desc: "项目本质是服务端软件还是客户端工具？" },
  { key: "d2" as const, label: "D2 营销", desc: "能否为华为云市场带来差异化、获客、品牌增益？" },
  { key: "d3" as const, label: "D3 场景", desc: "是否解决真实客户痛点？有无付费意愿？" },
  { key: "d4" as const, label: "D4 云上", desc: "部署到华为云后是否产生增量价值（vs 本地）？" },
]

const gradeLabel: Record<string, { text: string; color: string }> = {
  green: { text: "推荐", color: "var(--ink)" },
  amber: { text: "可选", color: "var(--accent)" },
  red: { text: "不建议", color: "var(--ink-muted)" },
}

export default function EvaluatePage() {
  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      {/* 页头 */}
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Evaluation</div>
        <h1 className="heading-lg text-ink">业务评估</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          四维评估模型 — 在技术评估之前，先回答「值不值得做」。技术可行性 ≠ 商业可行性。
        </p>
      </header>

      {/* 四维模型说明 */}
      <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        {dimensions.map(d => (
          <div key={d.key} className="bg-surface rounded-xl border border-border p-5 shadow-soft">
            <div className="eyebrow mb-2">{d.label}</div>
            <p className="text-sm text-ink-faded leading-relaxed">{d.desc}</p>
          </div>
        ))}
      </section>

      {/* 评估卡片 */}
      <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {evaluations.map(e => {
          const radarData = dimensions.map(d => ({ dim: d.label.split(" ")[0], value: e[d.key] }))
          const rationale = dimensions.map(d => ({ label: d.label, score: e[d.key], text: e[`${d.key}r` as "d1r"] }))
          const g = gradeLabel[e.grade]
          return (
            <div key={e.name} className="bg-surface rounded-xl border border-border p-7 shadow-soft flex flex-col">
              <div className="flex items-start justify-between gap-4 mb-5">
                <div className="min-w-0">
                  <h2 className="serif text-xl font-bold text-ink">{e.name}</h2>
                  <div className="text-xs text-ink-muted mt-1 truncate">{e.url} · {e.stars}</div>
                </div>
                <div className="text-right shrink-0">
                  <div className="serif text-3xl font-bold text-ink tabular-nums leading-none">{e.total.toFixed(1)}</div>
                  <div className="eyebrow mt-1.5" style={{ color: g.color }}>{g.text}</div>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 items-center">
                <EvalRadarChart data={radarData} />
                <div className="space-y-2.5">
                  {rationale.map(r => (
                    <div key={r.label}>
                      <div className="flex items-baseline justify-between">
                        <span className="eyebrow">{r.label}</span>
                        <span className="serif text-sm font-bold text-ink tabular-nums">{r.score}</span>
                      </div>
                      <p className="text-xs text-ink-faded leading-relaxed mt-0.5">{r.text}</p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="mt-5 pt-4 border-t border-border-light">
                <div className="eyebrow mb-1.5">结论</div>
                <p className="text-sm text-ink leading-relaxed">{e.rec}</p>
              </div>
            </div>
          )
        })}
      </section>
    </div>
  )
}
