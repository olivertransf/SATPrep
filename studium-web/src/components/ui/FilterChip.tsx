interface FilterChipProps {
  label: string
  selected?: boolean
  onClick: () => void
  className?: string
  fillsCell?: boolean
}

export function FilterChip({ label, selected = false, onClick, className = '', fillsCell = false }: FilterChipProps) {
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
