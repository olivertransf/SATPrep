import { useEffect, useState } from 'react'
import { Cloud, CloudOff, Loader2 } from 'lucide-react'
import type { useCloudSync } from '../../hooks/useCloudSync'

type CloudSyncApi = ReturnType<typeof useCloudSync>

interface CloudSyncSettingsProps {
  sync: CloudSyncApi
}

export function CloudSyncSettings({ sync }: CloudSyncSettingsProps) {
  const [password, setPassword] = useState('')
  const [authMode, setAuthMode] = useState<'auth' | 'gate' | null>(null)

  useEffect(() => {
    void sync.authMode().then(setAuthMode)
  }, [sync.active, sync])

  if (!sync.configured) {
    return (
      <div className="px-4 py-3 text-sm" style={{ color: 'var(--muted)' }}>
        Add <code className="studium-mono text-xs">VITE_SUPABASE_URL</code> and{' '}
        <code className="studium-mono text-xs">VITE_SUPABASE_PUBLISHABLE_KEY</code> to{' '}
        <code className="studium-mono text-xs">.env.local</code>, then restart the dev server.
      </div>
    )
  }

  const hint = sync.canUseEmail
    ? 'Enter your sync password once. Session stays in this browser.'
    : sync.canUseGate
      ? 'Enter your sync password to enable cloud backup (solo mode).'
      : 'Set VITE_SYNC_EMAIL or VITE_SYNC_GATE_PASSWORD in .env.local'

  return (
    <>
      <div className="px-4 py-3 border-b text-sm" style={{ borderColor: 'var(--border)', color: 'var(--muted)' }}>
        {sync.active
          ? 'Progress, saved quizzes, and vocab buckets sync to Supabase.'
          : hint}
      </div>

      {sync.lastError && (
        <div className="px-4 py-2 text-xs" style={{ color: 'var(--error)' }}>
          {sync.lastError}
        </div>
      )}

      {sync.active ? (
        <div className="px-4 py-3 space-y-3">
          <div className="flex items-center gap-2 text-sm" style={{ color: 'var(--success)' }}>
            {sync.syncing ? <Loader2 size={16} className="animate-spin" /> : <Cloud size={16} />}
            <span>
              {sync.syncing
                ? 'Syncing…'
                : sync.lastSyncedAt
                  ? `Last synced ${new Date(sync.lastSyncedAt).toLocaleString()}`
                  : 'Connected'}
            </span>
            {authMode === 'gate' && (
              <span className="text-xs" style={{ color: 'var(--muted)' }}>
                (gate)
              </span>
            )}
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              className="studium-btn-secondary flex-1"
              disabled={sync.syncing}
              onClick={() => void sync.syncNow()}
            >
              Sync now
            </button>
            <button
              type="button"
              className="studium-btn-secondary flex-1"
              disabled={sync.syncing}
              onClick={() => void sync.signOut()}
            >
              <CloudOff size={14} aria-hidden="true" />
              Disconnect
            </button>
          </div>
        </div>
      ) : (
        <div className="px-4 py-3 space-y-2">
          {(sync.canUseEmail || sync.canUseGate) ? (
            <>
              <label className="text-xs font-medium" style={{ color: 'var(--muted)' }}>
                Sync password
              </label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                onKeyDown={e => {
                  if (e.key === 'Enter') void sync.unlock(password).then(ok => ok && setPassword(''))
                }}
                className="w-full px-3 py-2 text-sm border rounded-[10px] outline-none"
                style={{
                  background: 'var(--fill-tertiary)',
                  borderColor: 'var(--border)',
                  color: 'var(--text)',
                }}
                autoComplete="current-password"
              />
              <button
                type="button"
                className="studium-btn-primary w-full"
                disabled={sync.syncing || !password}
                onClick={() => void sync.unlock(password).then(ok => ok && setPassword(''))}
              >
                {sync.syncing ? 'Connecting…' : 'Enable cloud sync'}
              </button>
            </>
          ) : (
            <p className="text-sm m-0" style={{ color: 'var(--muted)' }}>
              {hint}
            </p>
          )}
        </div>
      )}
    </>
  )
}
