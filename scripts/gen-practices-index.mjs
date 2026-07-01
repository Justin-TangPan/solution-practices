#!/usr/bin/env node
// 遍历 practices/ 目录，生成 practices-index.json 供 web 消费。
// 结构：practices/<slug>/<site>/<region>/<variant>/  variant ∈ {standard, ha}
// 输出：web/src/lib/practices-index.json
//
// 编辑性字段（score/tier/cost/overview/tagline/category/stars/color）仍由 web/src/lib/data.ts 维护；
// 本脚本只产结构化字段（slug/title/sites/regions/hasHA/docsPath），由 catalog.ts 合并。

import { readdirSync, readFileSync, statSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const PRACTICES_DIR = join(ROOT, "practices");
const OUT = join(ROOT, "web", "src", "lib", "practices-index.json");

function dirs(p) {
  if (!existsSync(p)) return [];
  return readdirSync(p).filter(n => statSync(join(p, n)).isDirectory());
}

function readH1(filePath) {
  if (!existsSync(filePath)) return null;
  const text = readFileSync(filePath, "utf8");
  const m = text.match(/^#\s+(.+)$/m);
  if (!m) return null;
  return m[1].replace(/\s*Solution Details\s*$/i, "").trim();
}

function firstDocH1(slug) {
  // 优先 cn/docs/Solution-Details.md，回退 intl/docs/zh-cn/ 或 intl/docs/
  const candidates = [
    join(PRACTICES_DIR, slug, "cn", "docs", "Solution-Details.md"),
    join(PRACTICES_DIR, slug, "intl", "docs", "zh-cn", "Solution-Details.md"),
    join(PRACTICES_DIR, slug, "intl", "docs", "Solution-Details.md"),
  ];
  for (const c of candidates) {
    const h1 = readH1(c);
    if (h1) return { title: h1, docsPath: c.replace(/\\/g, "/").replace(ROOT + "/", "") };
  }
  return { title: null, docsPath: null };
}

const slugs = dirs(PRACTICES_DIR).sort();
const practices = slugs.map(slug => {
  const sites = dirs(join(PRACTICES_DIR, slug));
  const regions = new Set();
  let hasHA = false;
  for (const site of sites) {
    const siteRegions = dirs(join(PRACTICES_DIR, slug, site)).filter(r => r !== "docs");
    for (const r of siteRegions) {
      regions.add(r);
      const variants = dirs(join(PRACTICES_DIR, slug, site, r));
      if (variants.includes("ha")) hasHA = true;
    }
  }
  const { title, docsPath } = firstDocH1(slug);
  return {
    slug,
    title,
    sites,
    regions: [...regions].sort(),
    hasHA,
    docsPath,
  };
});

const index = {
  generated: new Date().toISOString(),
  count: practices.length,
  practices,
};

writeFileSync(OUT, JSON.stringify(index, null, 2), "utf8");
console.log(`✓ generated ${OUT.replace(ROOT + "/", "")} — ${practices.length} practices`);
for (const p of practices) {
  console.log(`  ${p.slug.padEnd(22)} regions=${p.regions.length} hasHA=${p.hasHA} title=${p.title ?? "—"}`);
}
