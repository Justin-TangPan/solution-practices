const buckets = [
  { name: "sac-release", purpose: "发布包归档（.extension、url.txt、docs）", access: "私有" },
  { name: "sac-assets", purpose: "公共资产（模板、图标、静态站点）", access: "公共读" },
  { name: "sac-backup", purpose: "Terraform state 与备份", access: "私有" },
]

const conventions = [
  "桶名小写，以 sac- 前缀分组，避免与区域默认桶冲突。",
  "release 包按 practices/<name>/<site>/ 结构组织，与仓库目录对齐。",
  "公共读桶需配 Referer 白名单与防盗链，避免流量被盗刷。",
  "Terraform state 桶启用版本化与多 AZ 跨区域复制，防止状态丢失。",
]

export default function ObsPage() {
  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Manage · OBS</div>
        <h1 className="heading-lg text-ink">OBS</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          对象存储桶约定 — 发布归档、公共资产与状态备份的分桶策略。
        </p>
      </header>

      <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {buckets.map(b => (
          <div key={b.name} className="bg-surface rounded-xl border border-border p-6 shadow-soft">
            <div className="serif text-base font-bold text-ink">{b.name}</div>
            <p className="text-sm text-ink-faded leading-relaxed mt-2">{b.purpose}</p>
            <div className="eyebrow mt-4">{b.access}</div>
          </div>
        ))}
      </section>

      <section className="bg-surface rounded-xl border border-border p-7 shadow-soft">
        <h2 className="serif text-xl font-bold text-ink mb-5">桶约定</h2>
        <ul className="space-y-3">
          {conventions.map((c, i) => (
            <li key={i} className="flex gap-3 text-sm text-ink-faded leading-relaxed">
              <span className="eyebrow shrink-0 w-6">{String(i + 1).padStart(2, "0")}</span>
              <span>{c}</span>
            </li>
          ))}
        </ul>
      </section>
    </div>
  )
}
