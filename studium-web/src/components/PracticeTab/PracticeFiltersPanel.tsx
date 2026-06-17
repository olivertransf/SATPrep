import type { AnswerStatus, CBVerifiedInactiveFilter } from '../../types'
import { FilterChip } from '../ui/FilterChip'
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
          <FilterChip label="All" selected={!filters.module} onClick={() => onChange({ module: undefined })} fillsCell />
          <FilterChip label="Math" selected={filters.module === 'math'} onClick={() => onChange({ module: 'math' })} fillsCell />
          <FilterChip label="Reading & Writing" selected={filters.module === 'english'} onClick={() => onChange({ module: 'english' })} fillsCell />
        </FilterChipGrid>
      </FilterFormCard>

      <FilterFormCard title="Difficulty">
        <FilterChipGrid columns={cols}>
          <FilterChip label="All" selected={!filters.difficulty} onClick={() => onChange({ difficulty: undefined })} fillsCell />
          {Object.entries(DIFFICULTY_LABELS).map(([value, label]) => (
            <FilterChip
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
            <FilterChip
              key={value}
              label={label}
              selected={filters.answerStatus === value}
              onClick={() => onChange({ answerStatus: value })}
              fillsCell
            />
          ))}
        </FilterChipGrid>
      </FilterFormCard>

      <FilterFormCard title="CB verified pool">
        <FilterChipGrid columns={cols}>
          <FilterChip
            label="Any"
            selected={!filters.cbVerifiedInactive}
            onClick={() => onChange({ cbVerifiedInactive: undefined })}
            fillsCell
          />
          <FilterChip
            label="Verified off practice tests"
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
          <FilterChip
            label="No limit"
            selected={!filters.questionLimit}
            onClick={() => onChange({ questionLimit: undefined })}
            fillsCell
          />
          {[10, 20, 30, 50].map(n => (
            <FilterChip
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
          <button
            type="button"
            onClick={() => onChange({ shuffled: true })}
            className={[
              'studium-chip w-full min-h-[48px] justify-start px-3',
              filters.shuffled ? 'studium-chip--selected' : '',
            ].join(' ')}
          >
            <span className="flex items-center gap-2">
              <Shuffle size={14} aria-hidden="true" />
              <span className="text-left">
                <span className="block text-sm font-semibold">Random</span>
                <span className="block text-xs font-normal" style={{ color: 'var(--muted)' }}>
                  Shuffle each session
                </span>
              </span>
            </span>
          </button>
          <button
            type="button"
            onClick={() => onChange({ shuffled: false })}
            className={[
              'studium-chip w-full min-h-[48px] justify-start px-3',
              !filters.shuffled ? 'studium-chip--selected' : '',
            ].join(' ')}
          >
            <span className="flex items-center gap-2">
              <ArrowDownUp size={14} aria-hidden="true" />
              <span className="text-left">
                <span className="block text-sm font-semibold">In order</span>
                <span className="block text-xs font-normal" style={{ color: 'var(--muted)' }}>
                  Stable sequence
                </span>
              </span>
            </span>
          </button>
        </div>
      </FilterFormCard>
    </div>
  )
}
