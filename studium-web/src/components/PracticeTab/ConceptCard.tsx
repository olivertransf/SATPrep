import { ChevronRight } from 'lucide-react'

export interface ConceptCategoryData {
  id: string
  count: number
  skills: { id: string; count: number }[]
}

interface ConceptCardProps {
  category: ConceptCategoryData
  accent: string
  onPractice: () => void
  onPracticeSkill: (skillId: string) => void
}

export function ConceptCard({ category, accent, onPractice, onPracticeSkill }: ConceptCardProps) {
  return (
    <article className="studium-card overflow-hidden flex flex-col">
      <div className="flex gap-3 p-4">
        <div
          className="shrink-0 flex items-center justify-center rounded-[10px]"
          style={{
            width: 40,
            height: 40,
            background: `color-mix(in srgb, ${accent} 14%, transparent)`,
            color: accent,
          }}
          aria-hidden="true"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M4 8h4V4H4v4zm6 12h4v-4h-4v4zm-6 0h4v-4H4v4zm0-6h4v-4H4v4zm6 0h4v-4h-4v4zm6-10v4h4V4h-4zm0 6h4v-4h-4v4zm0 6h4v-4h-4v4zm6-10v4h4V4h-4zm0 6h4v-4h-4v4zm0 6h4v-4h-4v4z" />
          </svg>
        </div>
        <div className="min-w-0 flex-1">
          <h3 className="text-base font-semibold leading-snug m-0" style={{ color: 'var(--text)' }}>
            {category.id}
          </h3>
          <p className="text-sm mt-1 m-0" style={{ color: 'var(--muted)' }}>
            {category.count} question{category.count === 1 ? '' : 's'}
          </p>
        </div>
      </div>

      <div style={{ borderTop: '0.5px solid var(--border)' }}>
        {category.skills.map((skill, index) => (
          <button
            key={skill.id}
            type="button"
            onClick={() => onPracticeSkill(skill.id)}
            className="w-full flex items-center gap-3 px-4 py-3 min-h-[44px] text-left border-0 bg-transparent cursor-pointer transition-colors hover:bg-[var(--fill-tertiary)]"
            style={{
              borderBottom: index < category.skills.length - 1 ? '0.5px solid var(--border)' : undefined,
            }}
          >
            <span className="flex-1 text-[15px] leading-snug" style={{ color: 'var(--text)' }}>
              {skill.id}
            </span>
            <span className="text-sm font-medium tabular-nums" style={{ color: 'var(--muted)' }}>
              {skill.count}
            </span>
            <ChevronRight size={14} style={{ color: 'var(--muted)' }} aria-hidden="true" />
          </button>
        ))}
      </div>

      <div className="p-4" style={{ borderTop: '0.5px solid var(--border)' }}>
        <button type="button" onClick={onPractice} className="studium-btn-primary w-full">
          Practice category
        </button>
      </div>
    </article>
  )
}
