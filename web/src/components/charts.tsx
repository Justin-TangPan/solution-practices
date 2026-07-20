"use client"

import {
  BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Cell, Tooltip,
  RadarChart, Radar, PolarGrid, PolarAngleAxis, PolarRadiusAxis,
} from "recharts"

const INK = "#1a1a1a"
const MUTED = "#8c8c8c"
const ACCENT = "#c96442"
const BORDER = "#e5e3dc"

type ScoreItem = { name: string; score: number }
type RadarItem = { dim: string; value: number }
type BarItem = { label: string; value: number }

export function ScoreBarChart({ data }: { data: ScoreItem[] }) {
  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={data} layout="vertical" margin={{ left: 8, right: 16, top: 4, bottom: 4 }}>
        <XAxis type="number" domain={[0, 10]} hide />
        <YAxis type="category" dataKey="name" width={92} tickLine={false} axisLine={false}
          tick={{ fill: MUTED, fontSize: 12, fontFamily: "var(--font-geist-sans)" }} />
        <Tooltip cursor={{ fill: BORDER }} formatter={(v) => [Number(v).toFixed(2), "评分"]}
          contentStyle={{ border: `1px solid ${BORDER}`, borderRadius: 8, fontSize: 12, boxShadow: "0 4px 12px rgba(20,18,14,0.06)" }} />
        <Bar dataKey="score" radius={[0, 4, 4, 0]} barSize={14}>
          {data.map((d, i) => (
            <Cell key={i} fill={d.score >= 8 ? INK : d.score >= 7 ? ACCENT : MUTED} />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  )
}

export function EvalRadarChart({ data }: { data: RadarItem[] }) {
  return (
    <ResponsiveContainer width="100%" height={280}>
      <RadarChart data={data} outerRadius="72%">
        <PolarGrid stroke={BORDER} />
        <PolarAngleAxis dataKey="dim"
          tick={{ fill: MUTED, fontSize: 11, fontFamily: "var(--font-geist-sans)" }} />
        <PolarRadiusAxis domain={[0, 10]} tickCount={5} axisLine={false}
          tick={{ fill: MUTED, fontSize: 10 }} />
        <Radar dataKey="value" stroke={INK} fill={INK} fillOpacity={0.12} strokeWidth={1.5} />
        <Tooltip formatter={(v) => [Number(v).toFixed(2), "得分"]}
          contentStyle={{ border: `1px solid ${BORDER}`, borderRadius: 8, fontSize: 12, boxShadow: "0 4px 12px rgba(20,18,14,0.06)" }} />
      </RadarChart>
    </ResponsiveContainer>
  )
}

export function HBarChart({ data, unit }: { data: BarItem[]; unit?: string }) {
  const max = Math.max(...data.map(d => d.value), 1)
  return (
    <ResponsiveContainer width="100%" height={data.length * 36 + 16}>
      <BarChart data={data} layout="vertical" margin={{ left: 8, right: 16, top: 4, bottom: 4 }}>
        <XAxis type="number" domain={[0, max]} hide />
        <YAxis type="category" dataKey="label" width={110} tickLine={false} axisLine={false}
          tick={{ fill: MUTED, fontSize: 12, fontFamily: "var(--font-geist-sans)" }} />
        <Tooltip cursor={{ fill: BORDER }} formatter={(v) => [String(v), unit ?? "数量"]}
          contentStyle={{ border: `1px solid ${BORDER}`, borderRadius: 8, fontSize: 12, boxShadow: "0 4px 12px rgba(20,18,14,0.06)" }} />
        <Bar dataKey="value" radius={[0, 4, 4, 0]} barSize={14} fill={INK} />
      </BarChart>
    </ResponsiveContainer>
  )
}
