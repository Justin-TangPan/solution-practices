// build 时从 practices/<slug>/cn/docs/ 读取 *-部署指南.md，供详情页 Word 预览。
// 仅在 next build / next dev (SSG) 期间执行；静态导出后内容已烘焙进 HTML。

import { readdirSync, readFileSync, existsSync } from "node:fs"
import { join } from "node:path"

export function getDeployGuide(slug: string): { content: string; filename: string } | null {
  const docsDir = join(process.cwd(), "..", "practices", slug, "cn", "docs")
  if (!existsSync(docsDir)) return null
  let files: string[]
  try { files = readdirSync(docsDir) } catch { return null }
  const fn = files.find(f => f.endsWith("部署指南.md"))
  if (!fn) return null
  try {
    return { content: readFileSync(join(docsDir, fn), "utf8"), filename: fn }
  } catch {
    return null
  }
}
