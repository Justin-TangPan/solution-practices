import { getObsInfo } from "@/lib/obs"

export default function ObsPage() {
  const obs = getObsInfo()

  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Manage · OBS</div>
        <h1 className="heading-lg text-ink">OBS 存储</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          从 <code className="bg-cream rounded px-1 py-0.5">skills/reference/obs-conventions.md</code> 读取的桶规范与区域映射。
        </p>
      </header>

      {/* 桶列表 */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {obs.buckets.map(b => (
          <div key={b.name} className="bg-surface rounded-xl border border-border p-6 shadow-soft">
            <div className="serif text-base font-bold text-ink">{b.name}</div>
            <p className="text-sm text-ink-faded leading-relaxed mt-2">{b.purpose}</p>
            <div className="eyebrow mt-4">{b.access}</div>
          </div>
        ))}
      </section>

      {/* 规范清单 */}
      <section className="bg-surface rounded-xl border border-border p-7 shadow-soft">
        <h2 className="serif text-xl font-bold text-ink mb-5">桶约定</h2>
        <ul className="space-y-3">
          {obs.conventions.map((c, i) => (
            <li key={i} className="flex gap-3 text-sm text-ink-faded leading-relaxed">
              <span className="eyebrow shrink-0 w-6">{String(i + 1).padStart(2, "0")}</span>
              <span>{c}</span>
            </li>
          ))}
        </ul>
      </section>

      {/* 区域路径一览 */}
      {obs.regionsUsed.length > 0 && (
        <section className="bg-surface rounded-xl border border-border p-7 shadow-soft">
          <h2 className="serif text-xl font-bold text-ink mb-5">区域路径</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
            {obs.regionsUsed.map(r => (
              <div key={r.code} className="flex items-center gap-2 text-xs bg-cream rounded-lg px-3 py-2">
                <span className="font-mono font-bold text-ink">{r.code}</span>
                <span className="text-ink-muted truncate">{r.path}</span>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
