import { Chip } from './Chip'

interface FilterChipProps {
  label: string
  selected?: boolean
  onClick: () => void
  className?: string
  fillsCell?: boolean
}

export function FilterChip(props: FilterChipProps) {
  return <Chip {...props} />
}
