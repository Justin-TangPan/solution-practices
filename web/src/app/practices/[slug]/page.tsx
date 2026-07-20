import { practices } from "@/lib/catalog"
import { PracticeDetail } from "@/components/practice-detail"
import { getPracticeDocuments } from "@/lib/deploy-guide"
import { getDeployablePractices } from "@/lib/deployable"
import { notFound } from "next/navigation"

const formalSlugs = new Set(["litellm", "supabase", "openjiuwen"])
const formalPractices = practices.filter(practice => formalSlugs.has(practice.slug))

export function generateStaticParams() {
  return formalPractices.map(practice => ({ slug: practice.slug }))
}

export const dynamicParams = false

export default async function PracticeDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params
  const practice = formalPractices.find(item => item.slug === slug)
  if (!practice) notFound()
  const documents = getPracticeDocuments(slug)
  const terraformFiles = getDeployablePractices().find(item => item.slug === slug)?.tfFiles ?? []
  if (!documents.length) throw new Error(`No Markdown documents found for formal practice: ${slug}`)
  if (!terraformFiles.length) throw new Error(`No Terraform files found for formal practice: ${slug}`)
  return <PracticeDetail practice={practice} documents={documents} terraformFiles={terraformFiles} />
}
