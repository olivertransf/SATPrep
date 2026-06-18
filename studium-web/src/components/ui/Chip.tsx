interface ChipProps {
  label: string
  selected?: boolean
  onClick: () => void
  className?: string
  fillsCell?: boolean
}

export function Chip({ label, selected = false, onClick, className = '', fillsCell = false }: ChipProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        'studium-chip',
        selected ? 'studium-chip--selected' : '',
        fillsCell ? 'studium-chip--grid' : '',
        className,
      ].filter(Boolean).join(' ')}
    >
      {label}
    </button>
  )
}
