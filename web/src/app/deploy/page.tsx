"use client"

import { useState } from "react"
import { AlertTriangle, Check, ChevronRight, Circle, Clock3, FileCode2, GitCompare, ShieldAlert } from "lucide-react"
import { cn } from "@/lib/utils"

type Stage = {
  name: string
  agent: string
  status: "passed" | "running" | "waiting" | "pending"
  summary: string
  details: string[]
}

const stages: Stage[] = [
  { name: "架构", agent: "架构师 Agent", status: "passed", summary: "可行性 8.8 / 10 · HA 拓扑已生成", details: ["ELB → CCE → LiteLLM Pods → RDS / DCS", "公网入口：ELB 443", "风险：域名与证书方案未确认"] },
  { name: "开发", agent: "开发 Agent", status: "running", summary: "演示生成 4 个文件 · 0 个冲突", details: ["deploying-litellm-ha_v1.tf", "LiteLLM-部署指南_zh.md", "使用 Skill：项目规则、RFS 开发"] },
  { name: "测试与安全", agent: "测试 / 安全 Agent", status: "waiting", summary: "需要确认网络方式后才能进入", details: ["Terraform 语法：未运行", "目录完整性：未运行", "凭证、安全组、容器与供应链：未审计"] },
  { name: "文档", agent: "文档 Agent", status: "pending", summary: "中文、English 与方案详情", details: ["中英文一致性：未检查", "文档完整度：未检查"] },
  { name: "交付", agent: "交付 Agent", status: "pending", summary: "交付包、校验和与部署链接", details: ["发布版本：未分配", "Terraform / RFS URL：未生成"] },
]

const statusLabel = { passed: "已通过", running: "运行中", waiting: "等待用户确认", pending: "未开始" }

export default function DeployPage() {
  const [selected, setSelected] = useState(2)
  const stage = stages[selected]

  return (
    <div className="min-h-screen flex flex-col">
      <header className="px-5 md:px-8 py-5 border-b border-border bg-surface/60 flex flex-wrap items-center justify-between gap-4">
        <div><div className="eyebrow">SAC Studio · 静态原型 / 演示数据</div><h1 className="serif text-xl font-bold text-ink mt-1">LiteLLM HA · 新加坡 <span className="text-sm font-sans font-normal text-ink-muted">ap-southeast-3</span></h1></div>
        <div className="rounded-full bg-amber-100 px-3 py-1.5 text-xs font-bold text-amber-900">1 个决策等待确认</div>
      </header>

      <div className="grid flex-1 xl:grid-cols-[minmax(0,1fr)_22rem]">
        <main className="p-5 md:p-8 border-r border-border space-y-7">
          <div>
            <div className="eyebrow mb-2">AI Delivery Pipeline</div>
            <h2 className="heading-lg text-ink">Agent 交付流水线</h2>
            <p className="text-sm text-ink-faded mt-2">点击阶段查看输入、输出与风险。状态和日志均为静态演示，不代表真实执行结果。</p>
          </div>

          <section className="space-y-3">
            {stages.map((item, index) => {
              const active = selected === index
              const Icon = item.status === "passed" ? Check : item.status === "running" ? Clock3 : item.status === "waiting" ? AlertTriangle : Circle
              return (
                <button key={item.name} onClick={() => setSelected(index)} className={cn("w-full text-left rounded-xl border p-5 transition", item.status === "waiting" ? "border-amber-400 bg-amber-50 shadow-[0_0_0_3px_rgba(245,158,11,.10)]" : active ? "border-ink bg-surface shadow-soft-lg" : "border-border bg-surface hover:border-ink/30")}>
                  <div className="flex items-start gap-4">
                    <span className={cn("mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-full", item.status === "passed" ? "bg-emerald-100 text-emerald-700" : item.status === "running" ? "bg-blue-100 text-blue-700" : item.status === "waiting" ? "bg-amber-200 text-amber-900" : "bg-cream text-ink-muted")}><Icon className="h-4 w-4" /></span>
                    <span className="min-w-0 flex-1">
                      <span className="flex flex-wrap items-center gap-2"><span className="serif text-lg font-bold text-ink">{item.name}阶段</span><span className={cn("rounded-full px-2 py-1 text-[0.65rem] font-bold", item.status === "waiting" ? "bg-amber-900 text-white" : "bg-cream text-ink-faded")}>{statusLabel[item.status]}</span></span>
                      <span className="block text-xs text-ink-muted mt-1">{item.agent}</span>
                      <span className="block text-sm text-ink-faded mt-3">{item.summary}</span>
                    </span>
                    <ChevronRight className={cn("h-4 w-4 mt-2 transition", active ? "rotate-90 text-accent" : "text-ink-muted")} />
                  </div>
                  {active && <span className="mt-4 ml-13 grid gap-2 border-t border-current/10 pt-4">{item.details.map(detail => <span key={detail} className="text-xs text-ink-faded flex items-center gap-2"><span className="h-1 w-1 rounded-full bg-current" />{detail}</span>)}</span>}
                </button>
              )
            })}
          </section>

          <section className="rounded-xl border border-border bg-surface p-5">
            <div className="flex items-center justify-between gap-4"><div><div className="eyebrow">Development Diff · 演示</div><h3 className="serif text-lg font-bold text-ink mt-1">当前文件变化</h3></div><GitCompare className="h-5 w-5 text-ink-muted" /></div>
            <div className="grid grid-cols-3 gap-3 mt-4 text-center">{[["新增", "4"], ["修改", "0"], ["冲突", "0"]].map(([label, value]) => <div key={label} className="rounded-lg bg-cream p-3"><div className="serif text-2xl font-bold">{value}</div><div className="eyebrow mt-1">{label}</div></div>)}</div>
          </section>
        </main>

        <aside className="p-5 md:p-6 bg-cream/40 space-y-5 xl:sticky xl:top-0 xl:h-screen xl:overflow-y-auto">
          <div><div className="eyebrow">Current Stage</div><h2 className="serif text-xl font-bold text-ink mt-1">{stage.name}阶段详情</h2></div>
          {[
            ["输入", selected === 2 ? "LiteLLM HA、INTL、新加坡、PostgreSQL" : "上游阶段合同与演示产物"],
            ["输出文件", selected < 2 ? "Terraform、拓扑数据、决策记录" : "尚未产生真实文件"],
            ["决策点", selected === 2 ? "公网 / 私网接入、域名与 TLS、RDS 规格" : "无新增决策"],
            ["Agent 日志", `[演示] ${stage.agent} 已选择；没有运行真实命令。`],
          ].map(([label, value]) => <section key={label} className="rounded-xl border border-border bg-surface p-4"><h3 className="eyebrow mb-2">{label}</h3><p className="text-xs leading-5 text-ink-faded">{value}</p></section>)}
          <section className="rounded-xl border border-red-200 bg-red-50 p-4"><div className="flex items-center gap-2"><ShieldAlert className="h-4 w-4 text-red-700" /><h3 className="text-sm font-bold text-red-950">风险与建议</h3></div><p className="text-xs leading-5 text-red-900 mt-2">安全组与公网入口尚未确认，不能声称质量门禁通过或生成可用部署链接。</p></section>
          {selected === 2 && <button className="w-full rounded-lg bg-amber-900 px-4 py-3 text-sm font-bold text-white">确认决策（演示）</button>}
        </aside>
      </div>

      <footer className="border-t border-border bg-surface px-5 md:px-8 py-4 flex flex-wrap items-center gap-x-6 gap-y-2 text-xs">
        <span className="eyebrow">生成文件 · 演示</span>
        {["deploying-litellm-ha_v1.tf", ".extension", "部署指南_zh.md", "Deployment-Guide_en.md", "url.txt（未生成）"].map(file => <span key={file} className="inline-flex items-center gap-1.5 text-ink-faded"><FileCode2 className="h-3.5 w-3.5" />{file}</span>)}
      </footer>
    </div>
  )
}
