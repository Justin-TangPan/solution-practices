const audits = [
  { name: "consistency", desc: "目录结构、命名、docs 完整性一致性校验。" },
  { name: "documentation", desc: "Solution-Details.md 与部署指南齐备且非占位。" },
  { name: "network_audit", desc: "脚本中无硬编码公网 IP、敏感端口暴露审计。" },
  { name: "scripts_audit", desc: "bootstrap 脚本幂等性、退出码、错误处理审计。" },
  { name: "tf_syntax", desc: "Terraform / RFS 模板 JSON 语法与资源合法性校验。" },
]

export default function AuditPage() {
  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Manage · Audit</div>
        <h1 className="heading-lg text-ink">审计</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          解决方案实践上线前的五项审计检查，对应 scripts/tests/ 检查器。
        </p>
      </header>

      <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {audits.map(a => (
          <div key={a.name} className="bg-surface rounded-xl border border-border p-6 shadow-soft">
            <div className="serif text-base font-bold text-ink">{a.name}</div>
            <p className="text-sm text-ink-faded leading-relaxed mt-2">{a.desc}</p>
          </div>
        ))}
      </section>
    </div>
  )
}
