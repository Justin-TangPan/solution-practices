# SAC Web 可视化

华为云解决方案实践（Solution Practices）的可视化前端 — 方案目录、业务评估、部署向导与报告洞察。

## 技术栈

- **Next.js 16.2.9**（App Router，静态导出 `output: 'export'`）
- **React 19.2.4** + **TypeScript 5**
- **Tailwind CSS v4**（`@theme` token，无 config 文件）
- **recharts 3**（图表，client 组件）
- **lucide-react**（图标）

## 数据流

```
practices/  ──┐
              ├─ scripts/gen-practices-index.mjs ─→ web/src/lib/practices-index.json
skills/     ──┘                                          │
                                                         ▼
web/src/lib/data.ts (编辑性字段) ──→ web/src/lib/catalog.ts (合并) ─→ pages
```

- **结构化字段**（slug / regions / hasHA / sites）由生成器从 `practices/` 目录树真实扫描产出。
- **编辑性字段**（score / tier / cost / overview / tagline / category）由 `data.ts` 人工维护。
- `catalog.ts` 按 slug 合并两者，页面统一从 `catalog.ts` 取数。

### 重新生成索引

```bash
node scripts/gen-practices-index.mjs
```

新增/删除 `practices/` 目录后跑一次，再 rebuild web。

## 开发

```bash
cd web
npm install
npm run dev      # http://localhost:3000
npm run lint
```

## 构建与静态导出

```bash
npm run build    # 产出 out/ 纯静态 HTML
npx serve out    # 本地预览
```

`out/` 可直接托管到 OBS / 任意静态主机。动态路由 `/practices/[slug]` 由 `generateStaticParams` 枚举，`dynamicParams = false`。

## 目录结构

```
web/src/
  app/
    page.tsx                    # 总览仪表盘
    practices/page.tsx          # 方案目录
    practices/[slug]/page.tsx   # 方案详情
    evaluate/page.tsx           # 业务评估（四维雷达）
    deploy/page.tsx             # 部署向导
    manage/{releases,obs,audit}/page.tsx
    reports/page.tsx            # 报告洞察
    layout.tsx globals.css
  components/{sidebar,charts}.tsx
  lib/{data,catalog,utils}.ts practices-index.json
```

## 设计语言

瑞士杂志 / Claude 风格 — 暖纸底（#f5f4ee）+ 墨黑 + 单一陶土 accent（#c96442，克制使用）。衬线大标题 + Geist 无衬正文，圆角卡片 + 柔阴影，暗色模式跟随系统。

## 注意

- Next.js 16 有 breaking changes，动手前先翻 `node_modules/next/dist/docs/`（见 `AGENTS.md`）。
- 静态导出禁用 `cookies()/headers()/searchParams`；所有数据 build 时烘焙。
