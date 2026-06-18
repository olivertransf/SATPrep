import type { ReactNode } from 'react'

interface ChipProps {
  label: string
  sublabel?: string
  icon?: ReactNode
  selected?: boolean
  onClick: () => void
  className?: string
  fillsCell?: boolean
}

export function Chip({
  label,
  sublabel,
  icon,
  selected = false,
  onClick,
  className = '',
  fillsCell = false,
}: ChipProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        'studium-chip',
        selected ? 'studium-chip--selected' : '',
        fillsCell ? 'studium-chip--grid' : '',
        sublabel || icon ? 'min-h-[48px] justify-start px-3' : '',
        className,
      ].filter(Boolean).join(' ')}
    >
      {sublabel || icon ? (
        <span className="flex items-center gap-2">
          {icon}
          <span className="text-left">
            <span className="block text-sm font-semibold">{label}</span>
            {sublabel && (
              <span className="block text-xs font-normal text-[var(--muted)]">{sublabel}</span>
            )}
          </span>
        </span>
      ) : (
        label
      )}
    </button>
  )
}
