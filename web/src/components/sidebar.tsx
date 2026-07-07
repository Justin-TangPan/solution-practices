"use client"

import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { cn } from "@/lib/utils"
import { LayoutDashboard, Boxes, Brain, Rocket, BarChart3, Globe, ShieldCheck, Upload, Menu, X } from "lucide-react"

const groups = [
  { label: "概览", items: [{ href: "/", icon: LayoutDashboard, label: "总览" }] },
  { label: "方案", items: [{ href: "/practices", icon: Boxes, label: "方案目录" }, { href: "/evaluate", icon: Brain, label: "业务评估" }, { href: "/deploy", icon: Rocket, label: "部署向导" }] },
  { label: "管理", items: [{ href: "/manage/releases", icon: Upload, label: "发布" }, { href: "/manage/obs", icon: Globe, label: "OBS" }, { href: "/manage/audit", icon: ShieldCheck, label: "审计" }] },
  { label: "洞察", items: [{ href: "/reports", icon: BarChart3, label: "报告" }] },
]

function NavLinks({ path, onNavigate }: { path: string; onNavigate?: () => void }) {
  return (
    <nav className="flex-1 px-6 py-8 space-y-8 overflow-y-auto">
      {groups.map(g => (
        <div key={g.label}>
          <div className="eyebrow px-3 mb-3">{g.label}</div>
          <div className="space-y-1">
            {g.items.map(item => {
              const active = path === item.href
              return (
                <Link key={item.href} href={item.href} onClick={onNavigate}
                  className={cn("flex items-center gap-3 px-3 py-2 text-sm rounded-lg transition-all",
                    active ? "bg-ink text-cream font-medium shadow-soft" : "text-ink-faded hover:text-ink hover:bg-surface"
                  )}>
                  <item.icon className="h-4 w-4 flex-shrink-0" />
                  {item.label}
                </Link>
              )
            })}
          </div>
        </div>
      ))}
    </nav>
  )
}

function Brand() {
  return (
    <div className="px-8 pt-10 pb-6 border-b border-border">
      <Link href="/" className="flex items-baseline gap-2.5">
        <span className="serif text-2xl font-bold text-ink leading-none">SAC</span>
        <span className="eyebrow">Solution Practices</span>
      </Link>
    </div>
  )
}

function Footer() {
  return (
    <div className="px-8 py-5 border-t border-border">
      <div className="flex items-center gap-3">
        <div className="h-7 w-7 rounded-full border border-border flex items-center justify-center text-ink text-[0.6rem] font-semibold">SA</div>
        <div>
          <div className="text-sm font-medium text-ink leading-tight">Solution Architect</div>
          <div className="eyebrow mt-0.5">华为云 SAC</div>
        </div>
      </div>
    </div>
  )
}

export function Sidebar() {
  const path = usePathname()
  const [open, setOpen] = useState(false)

  return (
    <>
      {/* 桌面侧栏 */}
      <aside className="fixed left-0 top-0 h-full w-72 bg-cream border-r border-border z-40 hidden lg:flex flex-col">
        <Brand />
        <NavLinks path={path} />
        <Footer />
      </aside>

      {/* 移动端顶栏 */}
      <div className="lg:hidden fixed top-0 left-0 right-0 h-14 bg-cream border-b border-border z-40 flex items-center justify-between px-5">
        <Link href="/" className="flex items-baseline gap-2">
          <span className="serif text-xl font-bold text-ink leading-none">SAC</span>
          <span className="eyebrow">Solution Practices</span>
        </Link>
        <button onClick={() => setOpen(true)} aria-label="打开菜单" className="p-2 -mr-2 text-ink hover:text-accent transition-colors">
          <Menu className="h-5 w-5" />
        </button>
      </div>

      {/* 移动端抽屉 */}
      {open && (
        <div className="lg:hidden fixed inset-0 z-50 flex">
          <div className="absolute inset-0 bg-ink/30" onClick={() => setOpen(false)} />
          <aside className="relative w-72 h-full bg-cream border-r border-border flex flex-col shadow-soft-lg">
            <button onClick={() => setOpen(false)} aria-label="关闭菜单" className="absolute top-4 right-4 p-2 text-ink-faded hover:text-ink transition-colors z-10">
              <X className="h-5 w-5" />
            </button>
            <Brand />
            <NavLinks path={path} onNavigate={() => setOpen(false)} />
            <Footer />
          </aside>
        </div>
      )}
    </>
  )
}
