import type { HTMLAttributes, ReactNode } from 'react'

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
  accent?: 'math' | 'rw' | 'none'
  padding?: boolean
}

export function Card({ children, accent = 'none', padding = true, className = '', ...props }: CardProps) {
  const accentClass =
    accent === 'math' ? 'border-l-4 border-l-[var(--math)]' :
    accent === 'rw' ? 'border-l-4 border-l-[var(--rw)]' :
    ''

  return (
    <div
      className={['studium-card', accentClass, padding ? 'p-4' : '', className].filter(Boolean).join(' ')}
      {...props}
    >
      {children}
    </div>
  )
}

interface CardHeaderProps {
  title: string
  subtitle?: string
}

export function CardHeader({ title, subtitle }: CardHeaderProps) {
  return (
    <div className="px-4 py-3 border-b border-[var(--border)]">
      <div className="font-semibold text-[var(--text)]">{title}</div>
      {subtitle && <div className="text-xs mt-0.5 text-[var(--muted)]">{subtitle}</div>}
    </div>
  )
}
