const releases = [
  { name: "litellm", sites: ["cn", "intl"], status: "已发布" },
  { name: "headroom-claude-code", sites: ["cn", "intl"], status: "已发布" },
]

export default function ReleasesPage() {
  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Manage · Releases</div>
        <h1 className="heading-lg text-ink">发布</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          已打包归档的解决方案发布包，由 package_solution.sh 产出到 release/。
        </p>
      </header>

      <section className="bg-surface rounded-xl border border-border shadow-soft overflow-hidden">
        <div className="grid grid-cols-3 px-7 py-4 border-b border-border eyebrow">
          <span>方案</span><span>上线站</span><span>状态</span>
        </div>
        {releases.map(r => (
          <div key={r.name} className="grid grid-cols-3 px-7 py-5 border-b border-border-light last:border-0 items-center">
            <span className="serif text-base font-bold text-ink">{r.name}</span>
            <span className="text-sm text-ink-faded">{r.sites.join(" · ")}</span>
            <span className="eyebrow">{r.status}</span>
          </div>
        ))}
      </section>
    </div>
  )
}
