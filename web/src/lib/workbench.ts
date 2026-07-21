import { readdirSync, existsSync, readFileSync } from "node:fs"
import { execFileSync } from "node:child_process"
import { join } from "node:path"
import { getAuditResults, type AuditReport } from "@/lib/audit"
import { getPractices } from "@/lib/catalog"
import { getDeployablePractices } from "@/lib/deployable"
import { getReleases, type ReleaseInfo } from "@/lib/releases"

const ROOT = join(process.cwd(), "..")
const FORMAL = new Set<string>(JSON.parse(readFileSync(join(ROOT, "project.config.json"), "utf8")).formal.practices)

export type Evidence = {
  kind: "事实" | "推导" | "编辑" | "待确认"
  source: string
  note: string
}

export type AssetTotals = {
  terraform: number
  docs: number
  extensions: number
}

export type WorkbenchSnapshot = {
  generated: string
  revision: string
  practices: ReturnType<typeof getPractices>
  deployable: ReturnType<typeof getDeployablePractices>
  audit: AuditReport
  releases: ReleaseInfo[]
  assets: AssetTotals
  evidence: Evidence[]
}

function countAssets(): AssetTotals {
  const totals: AssetTotals = { terraform: 0, docs: 0, extensions: 0 }
  const walk = (directory: string) => {
    if (!existsSync(directory)) return
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const path = join(directory, entry.name)
      if (entry.isDirectory()) walk(path)
      else if (entry.name.endsWith(".tf") || entry.name.endsWith(".tf.json")) totals.terraform++
      else if (entry.name.endsWith(".md")) totals.docs++
      else if (entry.name === ".extension") totals.extensions++
    }
  }
  for (const slug of FORMAL) walk(join(ROOT, "practices", slug))
  return totals
}

function revision(): string {
  try {
    return execFileSync("git", ["rev-parse", "--short", "HEAD"], { cwd: ROOT, encoding: "utf8" }).trim() || "未知提交"
  } catch {
    return "构建时快照"
  }
}

export function getWorkbenchSnapshot(): WorkbenchSnapshot {
  const practices = getPractices().filter(practice => FORMAL.has(practice.slug))
  const deployable = getDeployablePractices().filter(practice => FORMAL.has(practice.slug))
  return {
    generated: new Date().toISOString(),
    revision: revision(),
    practices,
    deployable,
    audit: getAuditResults(),
    releases: getReleases(),
    assets: countAssets(),
    evidence: [
      { kind: "事实", source: "project.config.json", note: "正式方案范围与质量策略" },
      { kind: "事实", source: "practices/", note: "部署实例、Terraform 与文档" },
      { kind: "事实", source: "scripts/tests/runner.py", note: "构建时质量门禁结果" },
      { kind: "推导", source: "web/src/lib/workbench.ts", note: "工作台汇总指标" },
    ],
  }
}
