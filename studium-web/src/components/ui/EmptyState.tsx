import type { ReactNode } from 'react'

interface EmptyStateProps {
  title: string
  description?: string
  action?: ReactNode
}

export function EmptyState({ title, description, action }: EmptyStateProps) {
  return (
    <div className="text-center py-16 px-4">
      <p className="text-base font-semibold m-0 text-[var(--text)]">{title}</p>
      {description && (
        <p className="studium-page-subtitle mt-2 mb-0 max-w-md mx-auto">{description}</p>
      )}
      {action && <div className="mt-4">{action}</div>}
    </div>
  )
}
