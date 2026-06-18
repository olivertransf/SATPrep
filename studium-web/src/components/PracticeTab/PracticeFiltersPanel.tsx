import type { AnswerStatus, CBVerifiedInactiveFilter } from '../../types'
import { Chip } from '../ui/Chip'
import { FilterChipGrid, FilterFormCard } from '../ui/FilterFormCard'
import { Shuffle, ArrowDownUp } from 'lucide-react'

const DIFFICULTY_LABELS: Record<string, string> = { E: 'Easy', M: 'Medium', H: 'Hard' }

export interface PracticeFilterState {
  module?: 'math' | 'english'
  difficulty?: string
  answerStatus: AnswerStatus
  cbVerifiedInactive?: CBVerifiedInactiveFilter
  shuffled: boolean
  questionLimit?: number
}

interface PracticeFiltersPanelProps {
  filters: PracticeFilterState
  onChange: (patch: Partial<PracticeFilterState>) => void
  sidebar?: boolean
}

export function PracticeFiltersPanel({ filters, onChange, sidebar }: PracticeFiltersPanelProps) {
  const cols = sidebar ? 2 : 2

  return (
    <div className="flex flex-col gap-4">
      <FilterFormCard title="Section">
        <FilterChipGrid columns={cols}>
          <Chip label="All" selected={!filters.module} onClick={() => onChange({ module: undefined })} fillsCell />
          <Chip label="Math" selected={filters.module === 'math'} onClick={() => onChange({ module: 'math' })} fillsCell />
          <Chip label="Reading & Writing" selected={filters.module === 'english'} onClick={() => onChange({ module: 'english' })} fillsCell />
        </FilterChipGrid>
      </FilterFormCard>

      <FilterFormCard title="Difficulty">
        <FilterChipGrid columns={cols}>
          <Chip label="All" selected={!filters.difficulty} onClick={() => onChange({ difficulty: undefined })} fillsCell />
          {Object.entries(DIFFICULTY_LABELS).map(([value, label]) => (
            <Chip
              key={value}
              label={label}
              selected={filters.difficulty === value}
              onClick={() => onChange({ difficulty: value })}
              fillsCell
            />
          ))}
        </FilterChipGrid>
      </FilterFormCard>

      <FilterFormCard title="Status">
        <FilterChipGrid columns={cols}>
          {(
            [
              ['all', 'All'],
              ['unanswered', 'New'],
              ['incorrect', 'Wrong'],
              ['correct', 'Correct'],
            ] as const
          ).map(([value, label]) => (
            <Chip
              key={value}
              label={label}
              selected={filters.answerStatus === value}
              onClick={() => onChange({ answerStatus: value })}
              fillsCell
            />
          ))}
        </FilterChipGrid>
      </FilterFormCard>

      <FilterFormCard title="Question source">
        <FilterChipGrid columns={cols}>
          <Chip
            label="Any"
            selected={!filters.cbVerifiedInactive}
            onClick={() => onChange({ cbVerifiedInactive: undefined })}
            fillsCell
          />
          <Chip
            label="Extra official questions"
            selected={filters.cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests'}
            onClick={() =>
              onChange({
                cbVerifiedInactive:
                  filters.cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests'
                    ? undefined
                    : 'onlyVerifiedOffCBPracticeTests',
              })
            }
            fillsCell
          />
        </FilterChipGrid>
      </FilterFormCard>

      <FilterFormCard title="Question count">
        <FilterChipGrid columns={cols}>
          <Chip
            label="No limit"
            selected={!filters.questionLimit}
            onClick={() => onChange({ questionLimit: undefined })}
            fillsCell
          />
          {[10, 20, 30, 50].map(n => (
            <Chip
              key={n}
              label={String(n)}
              selected={filters.questionLimit === n}
              onClick={() => onChange({ questionLimit: n })}
              fillsCell
            />
          ))}
        </FilterChipGrid>
      </FilterFormCard>

      <FilterFormCard title="Order">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
          <Chip
            label="Random"
            sublabel="Shuffle each session"
            icon={<Shuffle size={14} aria-hidden="true" />}
            selected={filters.shuffled}
            onClick={() => onChange({ shuffled: true })}
            className="w-full"
          />
          <Chip
            label="In order"
            sublabel="Stable sequence"
            icon={<ArrowDownUp size={14} aria-hidden="true" />}
            selected={!filters.shuffled}
            onClick={() => onChange({ shuffled: false })}
            className="w-full"
          />
        </div>
      </FilterFormCard>
    </div>
  )
}
