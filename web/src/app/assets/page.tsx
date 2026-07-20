import { readdirSync, statSync } from "node:fs"
import { basename, join } from "node:path"
import Link from "next/link"
import { ArrowRight, FileArchive, FileCode2, FileText, PackageOpen, type LucideIcon } from "lucide-react"
import { getDeployablePractices } from "@/lib/deployable"

const formal = new Set(["litellm", "supabase", "openjiuwen"])

function countFiles(root: string) {
  const counts = { terraform: 0, docs: 0, extension: 0, links: 0 }
  const walk = (directory: string) => readdirSync(directory).forEach(name => {
    const path = join(directory, name)
    if (statSync(path).isDirectory()) return walk(path)
    if (name.endsWith(".tf") || name.endsWith(".tf.json")) counts.terraform++
    else if (name.endsWith(".md")) counts.docs++
    else if (basename(path) === ".extension") counts.extension++
    else if (name === "url.txt") counts.links++
  })
  walk(root)
  return counts
}

export default function AssetsPage() {
  const practices = getDeployablePractices().filter(practice => formal.has(practice.slug)).map(practice => ({ ...practice, counts: countFiles(join(process.cwd(), "..", "practices", practice.slug)) }))
  const totals = practices.reduce((sum, practice) => ({ terraform: sum.terraform + practice.counts.terraform, docs: sum.docs + practice.counts.docs, extension: sum.extension + practice.counts.extension, links: sum.links + practice.counts.links }), { terraform: 0, docs: 0, extension: 0, links: 0 })
  const stats: [string, number, LucideIcon][] = [["Terraform", totals.terraform, FileCode2], ["Markdown", totals.docs, FileText], [".extension", totals.extension, PackageOpen], ["部署链接", totals.links, FileArchive]]

  return <div className="px-5 md:px-10 py-10 md:py-14 max-w-7xl mx-auto space-y-8">
    <header className="border-b border-border pb-8"><div className="flex flex-wrap items-center gap-3"><span className="eyebrow">Asset Management</span><span className="rounded-full border border-border bg-surface px-2 py-1 text-[0.65rem] text-ink-muted">只读 · 文件系统快照</span></div><h1 className="heading-lg text-ink mt-3">资产管理</h1><p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">按正式方案管理 Terraform、文档、扩展配置与部署链接；OBS 只是资产的一种发布位置，不再代替整个资产中心。</p></header>

    <section className="grid grid-cols-2 gap-3 md:grid-cols-4">{stats.map(([label, value, Icon]) => <div key={label} className="rounded-xl border border-border bg-surface p-5 shadow-soft"><Icon className="h-4 w-4 text-accent" /><div className="eyebrow mt-4">{label}</div><div className="serif mt-2 text-3xl font-bold text-ink">{value}</div></div>)}</section>

    <section className="space-y-4">{practices.map(practice => <article key={practice.slug} className="rounded-2xl border border-border bg-surface p-6 shadow-soft">
      <div className="flex flex-wrap items-start justify-between gap-4"><div><div className="eyebrow">Formal Practice</div><h2 className="serif mt-2 text-xl font-bold text-ink">{practice.slug}</h2><p className="mt-2 text-xs text-ink-muted">{practice.sites.join(" / ").toUpperCase()} · {new Set(practice.regions.map(region => region.code)).size} 个区域 · {practice.variants.join(" / ")}</p></div><Link href={`/practices/${practice.slug}`} className="inline-flex items-center gap-2 rounded-lg bg-ink px-4 py-2 text-xs font-bold text-cream">查看方案 <ArrowRight className="h-3.5 w-3.5" /></Link></div>
      <div className="mt-6 grid grid-cols-2 gap-3 md:grid-cols-4">{Object.entries(practice.counts).map(([type, count]) => <div key={type} className="rounded-xl bg-cream p-4"><div className="eyebrow">{type}</div><div className="serif mt-2 text-2xl font-bold text-ink">{count}</div></div>)}</div>
    </article>)}</section>
  </div>
}
