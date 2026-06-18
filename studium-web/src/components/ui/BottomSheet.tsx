import { useEffect, useRef, type ReactNode } from 'react'

interface BottomSheetProps {
  open: boolean
  onClose: () => void
  title: string
  children: ReactNode
  footer?: ReactNode
  headerAction?: ReactNode
  /** Defaults to "Filters" */
  ariaLabel?: string
}

export function BottomSheet({
  open,
  onClose,
  title,
  children,
  footer,
  headerAction,
  ariaLabel = 'Sheet',
}: BottomSheetProps) {
  const dialogRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open, onClose])

  useEffect(() => {
    if (!open) return
    const prev = document.activeElement as HTMLElement | null
    dialogRef.current?.focus()
    return () => prev?.focus()
  }, [open])

  if (!open) return null

  return (
    <div className="studium-sheet-overlay" role="presentation">
      <button
        type="button"
        className="studium-sheet-backdrop"
        aria-label={`Close ${ariaLabel.toLowerCase()}`}
        onClick={onClose}
      />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-label={ariaLabel}
        tabIndex={-1}
        className="studium-sheet"
      >
        <div className="studium-sheet-header">
          <h2 className="text-lg font-semibold m-0 text-[var(--text)]">{title}</h2>
          {headerAction}
        </div>
        <div className="studium-sheet-body">{children}</div>
        {footer && <div className="studium-sheet-footer">{footer}</div>}
      </div>
    </div>
  )
}
