import type { ReactNode } from 'react'
import { ChevronRight } from 'lucide-react'

interface NavListRowProps {
  icon: ReactNode
  label: string
  sub?: string
  onClick: () => void
}

export function NavListRow({ icon, label, sub, onClick }: NavListRowProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="w-full flex items-center gap-3 px-4 py-3 min-h-[52px] text-left border-0 bg-transparent cursor-pointer hover:bg-[var(--fill-tertiary)] transition-colors"
    >
      <span className="shrink-0 text-[var(--accent)]" aria-hidden="true">{icon}</span>
      <div className="flex-1 min-w-0">
        <div className="text-sm font-semibold text-[var(--text)]">{label}</div>
        {sub && <div className="text-xs text-[var(--muted)]">{sub}</div>}
      </div>
      <ChevronRight size={16} className="text-[var(--muted)] shrink-0" aria-hidden="true" />
    </button>
  )
}
