import Link from "next/link"
import { ArrowRight } from "lucide-react"

const templates = [
  { name: "basic", desc: "单 ECS + 基础安全组，适合单机服务快速起跑。" },
  { name: "cluster", desc: "多节点集群 + 负载均衡，适合无状态水平扩展服务。" },
  { name: "n8n-platform", desc: "n8n 工作流平台模板，含持久化与反代。" },
  { name: "web-application", desc: "通用 Web 应用（前端 + 后端 + 数据库）三件套。" },
]

const steps = [
  { n: "01", title: "选择方案", desc: "从方案目录选取目标实践，确认区域与变体（standard / ha）。" },
  { n: "02", title: "选择模板", desc: "按部署形态匹配 RFS 模板（单机 / 集群 / 平台）。" },
  { n: "03", title: "填写参数", desc: "Region、ECS 规格、EIP 带宽、镜像、密钥对等。" },
  { n: "04", title: "生成与校验", desc: "生成 Terraform / RFS 脚本，跑 tf_syntax 与 scripts_audit 校验。" },
  { n: "05", title: "部署上线", desc: "应用模板，观察资源创建，执行 bootstrap 脚本。" },
  { n: "06", title: "验收与归档", desc: "健康检查、打 release 包、归档到 OBS，更新方案目录。" },
]

export default function DeployPage() {
  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Deploy</div>
        <h1 className="heading-lg text-ink">部署向导</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          从方案选取到上线归档的六步流程，配套 RFS 模板与校验脚本。
        </p>
      </header>

      {/* 流程步骤 */}
      <section>
        <h2 className="serif text-xl font-bold text-ink mb-5">部署流程</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {steps.map(s => (
            <div key={s.n} className="bg-surface rounded-xl border border-border p-6 shadow-soft">
              <div className="eyebrow mb-3">{s.n}</div>
              <div className="serif text-lg font-bold text-ink mb-1.5">{s.title}</div>
              <p className="text-sm text-ink-faded leading-relaxed">{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* RFS 模板 */}
      <section>
        <h2 className="serif text-xl font-bold text-ink mb-5">RFS 模板</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
          {templates.map(t => (
            <Link key={t.name} href="/practices" className="group bg-surface rounded-xl border border-border p-6 shadow-soft hover:shadow-soft-lg hover:-translate-y-0.5 transition-all">
              <div className="serif text-lg font-bold text-ink group-hover:text-accent transition-colors">{t.name}</div>
              <p className="text-sm text-ink-faded leading-relaxed mt-2">{t.desc}</p>
              <div className="flex items-center gap-1 text-xs text-ink-muted mt-4 group-hover:text-accent transition-colors">
                查看 <ArrowRight className="h-3 w-3" />
              </div>
            </Link>
          ))}
        </div>
      </section>
    </div>
  )
}
