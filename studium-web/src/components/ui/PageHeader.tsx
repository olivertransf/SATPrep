import type { ReactNode } from 'react'
import { SectionLabel } from './SectionLabel'

interface PageHeaderProps {
  eyebrow?: string
  title: string
  subtitle?: string
  action?: ReactNode
}

export function PageHeader({ eyebrow, title, subtitle, action }: PageHeaderProps) {
  return (
    <header className="flex items-start justify-between gap-4 mb-2">
      <div className="min-w-0">
        {eyebrow && <SectionLabel>{eyebrow}</SectionLabel>}
        <h1 className="studium-page-title m-0">{title}</h1>
        {subtitle && <p className="studium-page-subtitle mt-1 mb-0">{subtitle}</p>}
      </div>
      {action && <div className="shrink-0">{action}</div>}
    </header>
  )
}
