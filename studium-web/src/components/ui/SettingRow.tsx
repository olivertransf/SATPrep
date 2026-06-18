import type { ReactNode } from 'react'

interface SettingRowProps {
  label: string
  sub?: string
  right: ReactNode
}

export function SettingRow({ label, sub, right }: SettingRowProps) {
  return (
    <div className="flex items-center justify-between px-4 py-3 min-h-[52px] border-b last:border-0 border-[var(--border)]">
      <div className="min-w-0 pr-4">
        <div className="text-sm font-medium text-[var(--text)]">{label}</div>
        {sub && <div className="text-xs mt-0.5 text-[var(--muted)]">{sub}</div>}
      </div>
      <div className="shrink-0">{right}</div>
    </div>
  )
}
