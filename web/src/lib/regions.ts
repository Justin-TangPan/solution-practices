// build 时从 skills/reference/region-mapping.md 解析权威区域表。
// 替代 data.ts 里手维护的 4 条。解析失败则回退 data.ts。

import { readFileSync, existsSync } from "node:fs"
import { join } from "node:path"
import { regions as fallback } from "./data"

type Region = { code: string; name: string; group: string }

function loadRegions(): Region[] {
  const file = join(process.cwd(), "..", "skills", "reference", "region-mapping.md")
  if (!existsSync(file)) return fallback
  let text: string
  try { text = readFileSync(file, "utf8") } catch { return fallback }

  const rows: Region[] = []
  // 匹配 | `code` | 显示名称 | cn|intl |
  const re = /^\|\s*`([a-z0-9-]+)`\s*\|\s*(.+?)\s*\|\s*(cn|intl)\s*\|$/gm
  let m: RegExpExecArray | null
  while ((m = re.exec(text))) {
    rows.push({ code: m[1], name: m[2].trim(), group: m[3] })
  }
  return rows.length >= fallback.length ? rows : fallback
}

export const regions: Region[] = loadRegions()
