import { useRef, useState } from 'react'
import { BookOpen, Calculator, Layers } from 'lucide-react'
import { Modal } from '../ui/Modal'
import { Button } from '../ui/Button'

interface ContinueQuizCardProps {
  tags: string[]
  answered: number
  total: number
  onResume: () => void
  onDelete: () => void
}

export function ContinueQuizCard({
  tags, answered, total, onResume, onDelete,
}: ContinueQuizCardProps) {
  const progress = total > 0 ? answered / total : 0
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const longPressTimer = useRef<number | null>(null)
  const title = tags[0] === 'All questions' ? 'All practice' : (tags[0] ?? 'Practice set')
  const subtitleParts = tags.slice(1, 3)
  const subtitle = subtitleParts.length > 0 ? subtitleParts.join(' · ') : 'Mixed SAT practice'
  const supportingTags = tags.slice(3, 6)
  const isRW = title === 'Reading & Writing'
  const isMath = title === 'Math'
  const Icon = isMath ? Calculator : (isRW ? BookOpen : Layers)
  const iconClass = isRW ? 'studium-bg-rw-chip' : 'studium-bg-math-chip'

  function startLongPress() {
    longPressTimer.current = window.setTimeout(() => setShowDeleteConfirm(true), 500)
  }

  function cancelLongPress() {
    if (longPressTimer.current !== null) {
      window.clearTimeout(longPressTimer.current)
      longPressTimer.current = null
    }
  }

  function confirmDelete() {
    setShowDeleteConfirm(false)
    onDelete()
  }

  return (
    <>
      <article className="studium-card w-full flex flex-col gap-3 p-4 shadow-none">
        <div className="flex items-center gap-3">
          <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${iconClass}`}>
            <Icon size={20} aria-hidden="true" />
          </div>

          <div
            className="min-w-0 flex-1 select-none touch-manipulation"
            onPointerDown={startLongPress}
            onPointerUp={cancelLongPress}
            onPointerLeave={cancelLongPress}
            onPointerCancel={cancelLongPress}
            onContextMenu={(e) => {
              e.preventDefault()
              setShowDeleteConfirm(true)
            }}
          >
            <h3 className="m-0 text-base font-semibold leading-tight text-[var(--text)] truncate">
              {title}
            </h3>
            <p className="m-0 mt-1 text-sm leading-snug text-[var(--muted)] line-clamp-2">
              {subtitle}
            </p>
          </div>

          <button type="button" onClick={onResume} className="studium-btn-primary shrink-0">
            Resume
          </button>
        </div>

        {supportingTags.length > 0 && (
          <div className="flex gap-1.5 overflow-hidden pl-[52px]">
            {supportingTags.map(tag => (
              <span
                key={tag}
                className="min-w-0 max-w-[11rem] truncate rounded-full px-2.5 py-1 text-xs font-medium text-[var(--muted)] bg-[var(--fill-secondary)]"
              >
                {tag}
              </span>
            ))}
          </div>
        )}

        <div className="pl-[52px]">
          <div
            className="flex-1 min-w-0 h-1.5 rounded-full overflow-hidden"
            style={{ background: 'var(--fill-tertiary)' }}
            role="progressbar"
            aria-valuenow={Math.round(progress * 100)}
            aria-valuemin={0}
            aria-valuemax={100}
            aria-label="Quiz progress"
          >
            <div
              className="h-full rounded-full transition-all"
              style={{ width: `${progress * 100}%`, background: isRW ? 'var(--rw)' : 'var(--accent)' }}
            />
          </div>
        </div>
      </article>

      <Modal
        open={showDeleteConfirm}
        onClose={() => setShowDeleteConfirm(false)}
        title="Delete saved quiz?"
        footer={(
          <div className="flex gap-2 justify-end">
            <Button variant="secondary" onClick={() => setShowDeleteConfirm(false)}>Cancel</Button>
            <Button variant="destructive" onClick={confirmDelete}>Delete</Button>
          </div>
        )}
      >
        <p className="text-sm m-0 text-[var(--muted)]">
          Long press the card details to remove this saved quiz.
        </p>
      </Modal>
    </>
  )
}
