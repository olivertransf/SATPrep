import { useEffect, useRef, type ReactNode } from 'react'

interface ModalProps {
  open: boolean
  onClose: () => void
  title: string
  children: ReactNode
  footer?: ReactNode
}

export function Modal({ open, onClose, title, children, footer }: ModalProps) {
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
    <div className="studium-modal-overlay" role="presentation" onClick={onClose}>
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="studium-modal-title"
        tabIndex={-1}
        className="studium-modal space-y-4"
        onClick={e => e.stopPropagation()}
      >
        <h2 id="studium-modal-title" className="text-base font-semibold m-0 text-[var(--text)]">
          {title}
        </h2>
        <div>{children}</div>
        {footer}
      </div>
    </div>
  )
}
