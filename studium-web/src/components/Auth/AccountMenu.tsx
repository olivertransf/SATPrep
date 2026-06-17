import { useState, useRef, useEffect } from 'react'
import { CircleUser, LogOut, Loader2, Cloud, CloudOff } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { useSync } from '../../context/SyncContext'

function GoogleMark() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
    </svg>
  )
}

function SyncGlyph({ status }: { status: string }) {
  if (status === 'offline') return <CloudOff size={14} aria-hidden="true" />
  if (status === 'syncing') return <Loader2 size={14} className="animate-spin" aria-hidden="true" />
  return <Cloud size={14} aria-hidden="true" />
}

function syncLabel(status: string, lastSyncedAt: number | null): string {
  if (status === 'syncing') return 'Syncing…'
  if (status === 'offline') return 'Offline'
  if (status === 'error') return 'Sync error'
  if (lastSyncedAt) return `Synced ${new Date(lastSyncedAt).toLocaleTimeString()}`
  return 'Synced'
}

export default function AccountMenu({ compact = false }: { compact?: boolean }) {
  const { user, loading, configured, signInWithGoogle, signOut } = useAuth()
  const { status, lastSyncedAt, error: syncError, syncNow, canSync } = useSync()
  const [open, setOpen] = useState(false)
  const [busy, setBusy] = useState(false)
  const rootRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    function onDocClick(e: MouseEvent) {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onDocClick)
    return () => document.removeEventListener('mousedown', onDocClick)
  }, [open])

  if (!configured) return null

  async function handleSignIn() {
    setBusy(true)
    try {
      await signInWithGoogle()
      setOpen(false)
    } finally {
      setBusy(false)
    }
  }

  async function handleSignOut() {
    setBusy(true)
    try {
      await signOut()
      setOpen(false)
    } finally {
      setBusy(false)
    }
  }

  if (loading) {
    return (
      <button type="button" className="studium-btn-ghost" disabled aria-label="Loading account">
        <Loader2 size={18} className="animate-spin" aria-hidden="true" />
      </button>
    )
  }

  if (!user) {
    if (compact) {
      return (
        <button
          type="button"
          className="studium-btn-ghost"
          aria-label="Sign in with Google"
          disabled={busy}
          onClick={() => void handleSignIn()}
        >
          {busy ? <Loader2 size={18} className="animate-spin" /> : <CircleUser size={20} strokeWidth={1.75} />}
        </button>
      )
    }

    return (
      <button
        type="button"
        className="studium-btn-secondary min-h-[36px] gap-2"
        disabled={busy}
        onClick={() => void handleSignIn()}
      >
        {busy ? <Loader2 size={16} className="animate-spin" /> : <GoogleMark />}
        <span>Sign in</span>
      </button>
    )
  }

  const label = user.displayName ?? user.email ?? 'Account'

  return (
    <div className="relative" ref={rootRef}>
      <button
        type="button"
        className="studium-btn-ghost gap-2 max-w-[160px] relative"
        aria-expanded={open}
        aria-haspopup="menu"
        aria-label="Account menu"
        onClick={() => setOpen(o => !o)}
      >
        {user.photoURL ? (
          <img
            src={user.photoURL}
            alt=""
            className="w-7 h-7 rounded-full shrink-0 ring-2 ring-[var(--border)]"
            referrerPolicy="no-referrer"
          />
        ) : (
          <span
            className="w-7 h-7 rounded-full shrink-0 flex items-center justify-center"
            style={{ background: 'var(--accent-chip-fill)', color: 'var(--accent)' }}
            aria-hidden="true"
          >
            <CircleUser size={18} strokeWidth={1.75} />
          </span>
        )}
        {canSync && status === 'synced' && (
          <span
            className="absolute bottom-0 right-0 w-2 h-2 rounded-full border"
            style={{ background: 'var(--success, #22c55e)', borderColor: 'var(--card)' }}
            aria-hidden="true"
          />
        )}
        {!compact && (
          <span className="text-sm font-medium truncate hidden sm:inline" style={{ color: 'var(--text)' }}>
            {label}
          </span>
        )}
      </button>

      {open && (
        <div
          role="menu"
          className="absolute right-0 top-full mt-2 w-60 rounded-xl border shadow-lg z-50 overflow-hidden"
          style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
        >
          <div className="px-3 py-2.5 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="text-sm font-semibold truncate" style={{ color: 'var(--text)' }}>{label}</div>
            {user.email && (
              <div className="text-xs truncate mt-0.5" style={{ color: 'var(--muted)' }}>{user.email}</div>
            )}
          </div>

          {canSync && (
            <div
              className="px-3 py-2 border-b flex items-center justify-between gap-2"
              style={{ borderColor: 'var(--border)' }}
            >
              <div className="flex items-center gap-2 text-xs min-w-0" style={{ color: 'var(--muted)' }}>
                <SyncGlyph status={status} />
                <span className="truncate">{syncLabel(status, lastSyncedAt)}</span>
              </div>
              <button
                type="button"
                className="text-xs font-medium shrink-0 px-2 py-1 rounded-md hover:bg-[var(--fill-tertiary)]"
                style={{ color: 'var(--accent)' }}
                disabled={status === 'syncing'}
                onClick={() => void syncNow()}
              >
                Sync now
              </button>
            </div>
          )}

          {syncError && (
            <div className="px-3 py-2 text-xs border-b" style={{ color: 'var(--error)', borderColor: 'var(--border)' }}>
              {syncError}
            </div>
          )}

          <button
            type="button"
            role="menuitem"
            className="w-full flex items-center gap-2 px-3 py-2.5 text-sm text-left hover:bg-[var(--fill-tertiary)]"
            style={{ color: 'var(--text)' }}
            disabled={busy}
            onClick={() => void handleSignOut()}
          >
            <LogOut size={16} aria-hidden="true" />
            Sign out
          </button>
        </div>
      )}
    </div>
  )
}
