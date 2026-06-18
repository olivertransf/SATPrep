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
