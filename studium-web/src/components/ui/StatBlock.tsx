interface StatBlockProps {
  label: string
  value: string | number
  sub?: string
  accent?: string
}

export function StatBlock({ label, value, sub, accent }: StatBlockProps) {
  return (
    <div className="studium-card p-4">
      <div
        className="studium-stat-digit text-2xl"
        style={accent ? { color: accent } : undefined}
      >
        {value}
      </div>
      <div className="text-sm mt-0.5 text-[var(--text)]">{label}</div>
      {sub && <div className="text-xs mt-0.5 text-[var(--muted)]">{sub}</div>}
    </div>
  )
}

interface ProgressBarProps {
  value: number
  max: number
  accent?: string
}

export function ProgressBar({ value, max, accent = 'var(--accent)' }: ProgressBarProps) {
  const pct = max > 0 ? Math.round((value / max) * 100) : 0
  return (
    <div className="flex items-center gap-3">
      <div className="flex-1 h-1.5 rounded-full overflow-hidden bg-[var(--border)]">
        <div
          className="h-full rounded-full transition-all duration-500"
          style={{ width: `${pct}%`, background: accent }}
        />
      </div>
      <span className="text-xs w-9 text-right tabular-nums text-[var(--muted)]">{pct}%</span>
    </div>
  )
}
