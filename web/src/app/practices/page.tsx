import { SolutionCatalog, type CatalogItem } from "@/components/solution-catalog"
import { getPractices } from "@/lib/catalog"
import { getDeployablePractices } from "@/lib/deployable"
import { getAuditResults } from "@/lib/audit"

export default function PracticesPage() {
  const practices = getPractices()
  const deployable = getDeployablePractices()
  const audit = getAuditResults()
  const items: CatalogItem[] = practices.map(practice => {
    const entry = deployable.find(item => item.slug === practice.slug)
    const results = audit.results.filter(item => item.practice.startsWith(`${practice.slug}/`))
    return { slug: practice.slug, name: practice.name, category: practice.category, tagline: practice.tagline, overview: practice.overview, sites: entry?.sites ?? [], regions: practice.regions, variants: entry?.variants ?? [practice.hasHA ? "standard" : "standard"], hasHA: practice.hasHA, hasDocs: entry?.hasDocs ?? false, errors: results.reduce((sum, item) => sum + item.errors, 0), warnings: results.reduce((sum, item) => sum + item.warnings, 0) }
  })
  return <SolutionCatalog items={items} />
}
