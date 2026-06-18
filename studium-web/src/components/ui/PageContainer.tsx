import type { ReactNode } from 'react'

interface PageContainerProps {
  children: ReactNode
  /** default = max-w-5xl (main tabs); narrow = max-w-3xl (settings-style) */
  width?: 'default' | 'narrow'
  stackClassName?: string
  className?: string
}

export function PageContainer({
  children,
  width = 'default',
  stackClassName = 'space-y-8',
  className = '',
}: PageContainerProps) {
  const maxWidth = width === 'narrow' ? 'max-w-3xl' : 'max-w-5xl'
  return (
    <div className={`flex-1 overflow-y-auto studium-screen ${className}`.trim()}>
      <div className={`${maxWidth} mx-auto px-4 sm:px-6 py-8 sm:py-10 ${stackClassName}`}>
        {children}
      </div>
    </div>
  )
}
