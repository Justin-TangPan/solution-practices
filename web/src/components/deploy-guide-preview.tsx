"use client"

import ReactMarkdown from "react-markdown"
import remarkGfm from "remark-gfm"

export function DeployGuidePreview({ content, filename }: { content: string; filename?: string }) {
  return (
    <div className="bg-surface rounded-xl border border-border shadow-soft-lg overflow-hidden flex flex-col">
      {/* 文档窗体顶栏 */}
      <div className="flex items-center justify-between px-5 py-3 border-b border-border bg-cream">
        <div className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 rounded-full bg-ink/20" />
          <span className="eyebrow">部署指南 · 预览</span>
        </div>
        {filename && <span className="text-[0.65rem] text-ink-muted truncate max-w-[14rem]">{filename}</span>}
      </div>

      {/* Word 纸面 */}
      <div className="overflow-y-auto px-8 py-10 max-h-[calc(100vh-12rem)]">
        <article className="prose-sac max-w-none">
          <ReactMarkdown
            remarkPlugins={[remarkGfm]}
            components={{
              h1: ({ children }) => <h1 className="serif text-2xl font-bold text-ink border-b border-border pb-3 mb-5 mt-2">{children}</h1>,
              h2: ({ children }) => <h2 className="serif text-xl font-bold text-ink mt-7 mb-3">{children}</h2>,
              h3: ({ children }) => <h3 className="serif text-base font-bold text-ink mt-5 mb-2">{children}</h3>,
              h4: ({ children }) => <h4 className="text-sm font-bold text-ink mt-4 mb-1.5">{children}</h4>,
              p: ({ children }) => <p className="text-sm text-ink-faded leading-relaxed mb-3 text-justify">{children}</p>,
              ul: ({ children }) => <ul className="list-disc pl-5 mb-3 text-sm text-ink-faded leading-relaxed space-y-1">{children}</ul>,
              ol: ({ children }) => <ol className="list-decimal pl-5 mb-3 text-sm text-ink-faded leading-relaxed space-y-1">{children}</ol>,
              li: ({ children }) => <li>{children}</li>,
              blockquote: ({ children }) => <blockquote className="border-l-2 border-accent pl-4 my-3 text-sm text-ink-muted italic">{children}</blockquote>,
              table: ({ children }) => <table className="w-full text-xs border-collapse my-4">{children}</table>,
              thead: ({ children }) => <thead className="bg-cream">{children}</thead>,
              th: ({ children }) => <th className="border border-border px-3 py-2 text-left font-bold text-ink">{children}</th>,
              td: ({ children }) => <td className="border border-border px-3 py-2 text-ink-faded align-top">{children}</td>,
              code: ({ children }) => <code className="bg-cream rounded px-1.5 py-0.5 text-xs font-mono text-ink">{children}</code>,
              pre: ({ children }) => <pre className="bg-ink text-cream rounded-lg p-4 overflow-x-auto text-xs font-mono my-4">{children}</pre>,
              hr: () => <hr className="border-border my-5" />,
              a: ({ children, href }) => <a href={href} className="text-accent underline underline-offset-2">{children}</a>,
              strong: ({ children }) => <strong className="font-bold text-ink">{children}</strong>,
            }}
          >
            {content}
          </ReactMarkdown>
        </article>
      </div>
    </div>
  )
}
