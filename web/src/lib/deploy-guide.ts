// build 时读取正式方案的 Markdown 文档；静态导出后内容已烘焙进 HTML。

import { readdirSync, readFileSync, existsSync } from "node:fs"
import { join, relative } from "node:path"

export type PracticeDocument = { content: string; filename: string; path: string; language: "中文" | "English" }

export function getPracticeDocuments(slug: string): PracticeDocument[] {
  const root = join(process.cwd(), "..", "practices", slug)
  const docsDirs = [join(root, "cn", "docs"), join(root, "intl", "docs", "zh-cn"), join(root, "intl", "docs", "en-us")]

  return docsDirs.flatMap(dir => {
    if (!existsSync(dir)) return []
    return readdirSync(dir).filter(file => file.endsWith(".md")).sort().map(filename => ({
      content: readFileSync(join(dir, filename), "utf8"),
      filename,
      path: relative(root, join(dir, filename)),
      language: dir.includes("en-us") ? "English" as const : "中文" as const,
    }))
  })
}
