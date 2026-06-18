import type { ReactNode } from 'react'

interface SectionHeadingProps {
  children: ReactNode
  className?: string
}

export function SectionHeading({ children, className = '' }: SectionHeadingProps) {
  return (
    <h2 className={`text-lg font-semibold m-0 mb-4 text-[var(--text)] ${className}`.trim()}>
      {children}
    </h2>
  )
}
