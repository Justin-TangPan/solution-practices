// build 时运行 SAC 测试框架，将结果注入静态页面
import { execFileSync, spawnSync } from "node:child_process"
import { join } from "node:path"

export type AuditItem = {
  check_name: string
  passed: boolean
  severity: string
  message: string
  file?: string
  practice?: string
}

export type AuditResult = {
  practice: string
  total: number
  errors: number
  warnings: number
  infos: number
  passed: boolean
  items: AuditItem[]
}

export type AuditReport = {
  results: AuditResult[]
  generated: string
  totalErrors: number
  totalWarnings: number
  totalPractices: number
}

const ROOT = join(process.cwd(), "..")

function guessPython(): string {
  const candidates = [
    join(ROOT, ".venv-sac", "bin", "python"),
    join(ROOT, ".venv", "bin", "python"),
    "python3",
    "python",
  ]
  for (const c of candidates) {
    try {
      execFileSync(c, ["--version"], { stdio: "pipe", timeout: 5000 })
      return c
    } catch { /* try next */ }
  }
  return "python3"
}

export function getAuditResults(): AuditReport {
  const run = spawnSync(guessPython(), ["-m", "scripts.tests.runner", "--json"], { cwd: ROOT, encoding: "utf8", timeout: 60000 })
  const raw = `${run.stdout ?? ""}\n${run.stderr ?? ""}`
  if (!raw.trim()) {
    throw new Error("SAC quality gate returned no output")
  }

  // 跳过第一行 "Found X practice instances\n"
  const lines = raw.split("\n")
  const jsonStart = lines.findIndex(l => l.trim().startsWith("["))
  if (jsonStart === -1) {
    throw new Error("SAC quality gate returned no JSON report")
  }
  const jsonStr = lines.slice(jsonStart).join("\n")

  let items: AuditItem[]
  try {
    items = JSON.parse(jsonStr)
  } catch {
    throw new Error("SAC quality gate returned invalid JSON")
  }

  // 按 practice 分组
  const groups = new Map<string, AuditItem[]>()
  for (const item of items) {
    const p = item.practice || "unknown"
    if (!groups.has(p)) groups.set(p, [])
    groups.get(p)!.push(item)
  }

  const results: AuditResult[] = []
  for (const [practice, checks] of groups) {
    const errors = checks.filter(c => c.severity === "ERROR").length
    const warnings = checks.filter(c => c.severity === "WARN").length
    const infos = checks.filter(c => c.severity === "INFO").length
    results.push({
      practice,
      total: checks.length,
      errors,
      warnings,
      infos,
      passed: errors === 0,
      items: checks.map(c => ({
        check_name: c.check_name,
        passed: c.passed,
        severity: c.severity,
        message: c.message,
        file: c.file,
      })),
    })
  }

  // 排序：有 ERROR 的在前
  results.sort((a, b) => {
    if (a.errors !== b.errors) return b.errors - a.errors
    return a.practice.localeCompare(b.practice)
  })

  return {
    results,
    generated: new Date().toISOString(),
    totalErrors: results.reduce((s, r) => s + r.errors, 0),
    totalWarnings: results.reduce((s, r) => s + r.warnings, 0),
    totalPractices: results.length,
  }
}
