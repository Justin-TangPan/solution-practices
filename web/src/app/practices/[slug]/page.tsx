import Link from "next/link"
import { notFound } from "next/navigation"
import { practices, regions } from "@/lib/catalog"
import { getDeployGuide } from "@/lib/deploy-guide"
import { DeployGuidePreview } from "@/components/deploy-guide-preview"
import { ArrowLeft, ArrowRight, Star, MapPin, ShieldCheck, Server, DollarSign, FileText } from "lucide-react"

export function generateStaticParams() {
  return practices.map(p => ({ slug: p.slug }))
}

export const dynamicParams = false

const tierLabel: Record<string, string> = { strong: "强烈推荐", good: "推荐", fair: "可选" }
const regionName = (code: string) => regions.find(r => r.code === code)?.name ?? code

export default async function PracticeDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params
  const p = practices.find(x => x.slug === slug)
  if (!p) notFound()

  const guide = getDeployGuide(slug)

  const attrs = [
    { icon: Star, label: "Stars", value: p.stars },
    { icon: DollarSign, label: "成本", value: p.cost },
    { icon: ShieldCheck, label: "高可用", value: p.hasHA ? "支持（HA 变体）" : "单机" },
    { icon: Server, label: "部署模式", value: p.hasHA ? "standalone / cluster" : "standalone" },
  ]

  return (
    <div className="px-10 py-14 max-w-none space-y-8">
      {/* 返回 */}
      <Link href="/practices" className="inline-flex items-center gap-2 text-sm text-ink-faded hover:text-ink transition-colors">
        <ArrowLeft className="h-4 w-4" /> 方案目录
      </Link>

      {/* 页头 */}
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">{p.category}</div>
        <div className="flex items-start justify-between gap-6">
          <div>
            <h1 className="heading-lg text-ink">{p.name}</h1>
            <p className="text-base text-ink-faded mt-2">{p.tagline}</p>
          </div>
          <div className="text-right shrink-0">
            <div className="serif text-5xl font-bold text-ink tabular-nums leading-none">{p.score.toFixed(1)}</div>
            <div className="eyebrow mt-2">{tierLabel[p.tier]}</div>
          </div>
        </div>
      </header>

      {/* 左右分栏：左元信息 + 右部署指南预览 */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
        {/* 左：元信息 */}
        <div className="space-y-8">
          <section>
            <h2 className="serif text-xl font-bold text-ink mb-4">概述</h2>
            <p className="text-base text-ink-faded leading-relaxed">{p.overview}</p>
          </section>

          <section>
            <h2 className="serif text-xl font-bold text-ink mb-4">关键属性</h2>
            <div className="grid grid-cols-2 gap-4">
              {attrs.map(a => (
                <div key={a.label} className="bg-surface rounded-xl border border-border p-5 shadow-soft">
                  <a.icon className="h-4 w-4 text-ink-muted mb-3" />
                  <div className="eyebrow mb-1">{a.label}</div>
                  <div className="text-sm font-medium text-ink">{a.value}</div>
                </div>
              ))}
            </div>
          </section>

          <section>
            <h2 className="serif text-xl font-bold text-ink mb-4">部署区域</h2>
            <div className="flex flex-wrap gap-2">
              {p.regions.map(r => (
                <div key={r} className="inline-flex items-center gap-2 bg-surface rounded-lg border border-border px-3 py-2 shadow-soft">
                  <MapPin className="h-3.5 w-3.5 text-ink-muted" />
                  <span className="text-sm font-medium text-ink">{regionName(r)}</span>
                  <span className="eyebrow ml-1">{r}</span>
                </div>
              ))}
            </div>
          </section>

          <section>
            <h2 className="serif text-xl font-bold text-ink mb-4">部署架构</h2>
            <div className={`grid ${p.hasHA ? "grid-cols-1 sm:grid-cols-2" : "grid-cols-1"} gap-4`}>
              <div className="bg-surface rounded-xl border border-border p-6 shadow-soft">
                <div className="eyebrow mb-3">Standard</div>
                <div className="serif text-lg font-bold text-ink mb-2">单机部署</div>
                <p className="text-sm text-ink-faded leading-relaxed">单 ECS 实例 + 本地持久化。适合个人 / 小团队试用，成本最低。</p>
              </div>
              {p.hasHA && (
                <div className="bg-surface rounded-xl border border-border p-6 shadow-soft">
                  <div className="eyebrow mb-3">HA</div>
                  <div className="serif text-lg font-bold text-ink mb-2">高可用集群</div>
                  <p className="text-sm text-ink-faded leading-relaxed">多实例 + RDS 持久化 + 负载均衡，跨可用区容灾。适合生产 7×24 在线场景。</p>
                </div>
              )}
            </div>
          </section>

          <section className="bg-ink rounded-xl p-6 flex items-center justify-between">
            <div>
              <div className="eyebrow text-cream/70 mb-2">Next Step</div>
              <div className="serif text-lg font-bold text-cream">前往部署向导</div>
            </div>
            <Link href="/deploy" className="inline-flex items-center gap-2 text-sm font-medium text-cream hover:text-accent transition-colors">
              继续 <ArrowRight className="h-4 w-4" />
            </Link>
          </section>
        </div>

        {/* 右：部署指南 Word 预览 */}
        <div className="xl:sticky xl:top-8 xl:self-start">
          {guide ? (
            <DeployGuidePreview content={guide.content} filename={guide.filename} />
          ) : (
            <div className="bg-surface rounded-xl border border-border p-10 shadow-soft text-center">
              <FileText className="h-8 w-8 text-ink-muted mx-auto mb-4" />
              <div className="serif text-lg font-bold text-ink">暂无部署指南</div>
              <p className="text-sm text-ink-faded mt-2">该方案尚未提供 cn 站部署指南文档。</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
