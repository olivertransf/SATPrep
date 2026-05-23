import { Play, Trash2 } from 'lucide-react'
import { CONTINUE_CARD_WIDTH_PX } from '../../design/tokens'

interface ContinueQuizCardProps {
  title: string
  answered: number
  total: number
  onResume: () => void
  onDelete: () => void
  fullWidth?: boolean
}

export function ContinueQuizCard({ title, answered, total, onResume, onDelete, fullWidth }: ContinueQuizCardProps) {
  const progress = total > 0 ? answered / total : 0

  return (
    <article
      className="studium-card flex flex-col shrink-0 overflow-hidden"
      style={{ width: fullWidth ? '100%' : CONTINUE_CARD_WIDTH_PX, padding: 'var(--space-lg)' }}
    >
      <button
        type="button"
        onClick={onResume}
        className="text-left w-full border-0 bg-transparent p-0 cursor-pointer"
      >
        <h3 className="text-base font-semibold leading-snug line-clamp-3 m-0" style={{ color: 'var(--text)' }}>
          {title}
        </h3>
      </button>

      <button
        type="button"
        onClick={onResume}
        className="text-left w-full border-0 bg-transparent p-0 cursor-pointer mt-3"
      >
        <div
          className="h-1 rounded-full overflow-hidden"
          style={{ background: 'var(--fill-tertiary)' }}
          role="progressbar"
          aria-valuenow={Math.round(progress * 100)}
          aria-valuemin={0}
          aria-valuemax={100}
        >
          <div
            className="h-full rounded-full transition-all"
            style={{ width: `${progress * 100}%`, background: 'var(--accent)' }}
          />
        </div>
        <p className="text-sm mt-2 m-0" style={{ color: 'var(--muted)' }}>
          {answered} of {total} answered
        </p>
      </button>

      <div className="flex gap-2 mt-4">
        <button type="button" onClick={onResume} className="studium-btn-primary flex-1">
          <Play size={14} aria-hidden="true" />
          Resume
        </button>
        <button
          type="button"
          onClick={onDelete}
          className="studium-btn-secondary px-3"
          aria-label="Delete saved quiz"
        >
          <Trash2 size={16} style={{ color: 'var(--error)' }} aria-hidden="true" />
        </button>
      </div>
    </article>
  )
}
