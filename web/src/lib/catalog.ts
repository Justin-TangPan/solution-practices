// 数据访问层：合并 practices-index.json（FS 结构，由 scripts/gen-practices-index.mjs 生成）
// 与 data.ts（编辑性字段：score/tier/cost/overview/tagline/category/stars/color）。
// 合并键 = slug。FS 提供真实 regions/hasHA，编辑字段由 data.ts 维护。

import practicesIndex from "./practices-index.json" with { type: "json" };
import { practices as editorial, evaluations } from "./data";

type Editorial = (typeof editorial)[number];

const fsBySlug = new Map<string, { regions: string[]; hasHA: boolean; sites: string[]; title: string | null; docsPath: string | null }>(
  practicesIndex.practices.map(p => [p.slug, { regions: p.regions, hasHA: p.hasHA, sites: p.sites, title: p.title, docsPath: p.docsPath }])
);

// 合并：编辑字段优先，regions/hasHA 用 FS 真实值覆盖
export const practices: Editorial[] = editorial.map(p => {
  const fs = fsBySlug.get(p.slug);
  if (!fs) return p; // FS 暂无目录，保留 data.ts 原值
  return { ...p, regions: fs.regions, hasHA: fs.hasHA };
});

export function getPractices() {
  return practices;
}

export function getPractice(slug: string): Editorial | undefined {
  return practices.find(p => p.slug === slug);
}

export function getPracticeSlugs(): string[] {
  return practices.map(p => p.slug);
}

export { evaluations };

// FS 中存在但 data.ts 未收录的 slug（需补编辑元数据才会出现在目录）
export const uncatalogued: string[] = practicesIndex.practices
  .filter(p => !editorial.some(e => e.slug === p.slug))
  .map(p => p.slug);
