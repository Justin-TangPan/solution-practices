// build 时读取 OBS 参考文档中的桶规范
import { readFileSync, existsSync } from "node:fs"
import { join } from "node:path"

const ROOT = join(process.cwd(), "..")
const OBS_REF = join(ROOT, "skills", "reference", "obs-conventions.md")

export type ObsBucket = {
  name: string
  purpose: string
  access: string
}

export type ObsInfo = {
  buckets: ObsBucket[]
  conventions: string[]
  regionsUsed: { code: string; path: string }[]
}

export function getObsInfo(): ObsInfo {
  // 从 region-mapping.md 读区域列表
  const regionMapFile = join(ROOT, "skills", "reference", "region-mapping.md")
  const regionsUsed: { code: string; path: string }[] = []
  if (existsSync(regionMapFile)) {
    const text = readFileSync(regionMapFile, "utf8")
    const re = /^\|\s*`([a-z0-9-]+)`\s*\|/gm
    let m: RegExpExecArray | null
    while ((m = re.exec(text))) {
      regionsUsed.push({ code: m[1], path: `obs://sac-release/{project}/${m[1]}/` })
    }
  }

  // 从 OBS 参考文档提取桶规范
  let conventions: string[] = []
  if (existsSync(OBS_REF)) {
    const text = readFileSync(OBS_REF, "utf8")
    // 提取列表项
    const listItems = text.match(/^\d+\.\s+(.+)$/gm)
    if (listItems) {
      conventions = listItems.map(l => l.replace(/^\d+\.\s+/, "").trim())
    }
  }

  return {
    buckets: [
      { name: "sac-release", purpose: "发布包归档（.tf、.extension、url.txt、docs）", access: "私有（生产）" },
      { name: "sac-assets", purpose: "公共资产（模板、图标、静态站点、SAC Web）", access: "公共读" },
      { name: "sac-backup", purpose: "Terraform state 与归档备份", access: "私有" },
    ],
    conventions: conventions.length > 0 ? conventions : [
      "桶名小写，以 sac- 前缀分组",
      "release 包按 practices/<name>/<site>/ 结构组织，与仓库目录对齐",
      "公共读桶需配 Referer 白名单与防盗链",
      "Terraform state 桶启用版本化与多 AZ 跨区域复制",
      "测试桶信息保存在本地开发记忆中，不提交到公开仓库",
      "生产桶地址用 locals 块内联，禁止用 variable 暴露给参数面",
    ],
    regionsUsed,
  }
}
