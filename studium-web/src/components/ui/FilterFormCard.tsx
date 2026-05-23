import type { ReactNode } from 'react'

interface FilterFormCardProps {
  title: string
  children: ReactNode
  className?: string
}

export function FilterFormCard({ title, children, className = '' }: FilterFormCardProps) {
  return (
    <section className={`studium-filter-card ${className}`.trim()}>
      <h3 className="studium-filter-card__title">{title}</h3>
      {children}
    </section>
  )
}

export function FilterChipGrid({ children, columns = 2 }: { children: ReactNode; columns?: 2 | 3 | 4 }) {
  return (
    <div className="studium-chip-grid" style={{ ['--chip-cols' as string]: String(columns) }}>
      {children}
    </div>
  )
}
