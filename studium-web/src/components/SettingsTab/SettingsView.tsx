import { useState } from 'react'
import type { QuestionProgress } from '../../types'
import { resetAll } from '../../store/progress'
import { loadAllQuizzes } from '../../store/quiz'
import { tombstoneAllQuizzes } from '../../store/deleted'
import { saveVocabPayload } from '../../store/vocabBuckets'
import { useAuth } from '../../context/AuthContext'
import { useSync } from '../../context/SyncContext'
import { notifyLocalDataChanged } from '../../lib/localDataEvents'
import { Sun, Moon, AlertTriangle, Loader2, Cloud } from 'lucide-react'

interface SettingsViewProps {
  progress: Record<string, QuestionProgress>
  onProgressChange: (p: Record<string, QuestionProgress>) => void
  onQuizzesChange: (quizzes: import('../../types').SavedQuiz[]) => void
  onToggleTheme: () => void
  isDark: boolean
  fontSize: number
  onFontSizeChange: (size: number) => void
}

function SettingRow({ label, sub, right }: { label: string; sub?: string; right: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between px-4 py-2.5 border-b last:border-0"
      style={{ borderColor: 'var(--border)' }}>
      <div>
        <div className="text-sm font-medium" style={{ color: 'var(--text)' }}>{label}</div>
        {sub && <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>{sub}</div>}
      </div>
      <div>{right}</div>
    </div>
  )
}

export default function SettingsView({
  progress, onProgressChange, onQuizzesChange, onToggleTheme, isDark, fontSize, onFontSizeChange,
}: SettingsViewProps) {
  const [showConfirm, setShowConfirm] = useState(false)
  const [authBusy, setAuthBusy] = useState(false)
  const { user, loading: authLoading, configured, error: authError, signInWithGoogle, signOut, clearError } = useAuth()
  const { status: syncStatus, lastSyncedAt, error: syncError, syncNow, canSync } = useSync()

  const attempted = Object.values(progress).filter(p => p.correct !== undefined).length
  const seen = Object.values(progress).filter(p => p.seen).length
  const savedQuizCount = loadAllQuizzes().length

  function handleReset() {
    tombstoneAllQuizzes(loadAllQuizzes())
    resetAll()
    onProgressChange({})
    localStorage.removeItem('studium_saved_quizzes')
    saveVocabPayload({ words: {}, roots: {}, wordTimestamps: {}, rootTimestamps: {} })
    notifyLocalDataChanged()
    onQuizzesChange([])
    setShowConfirm(false)
  }

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8 space-y-5">

        <header className="mb-2">
          <h1 className="studium-page-title m-0">Settings</h1>
          <p className="studium-page-subtitle mt-1 mb-0">Customize your study experience</p>
        </header>

        {configured && (
          <div className="studium-card overflow-hidden p-0">
            <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
              <div className="font-semibold" style={{ color: 'var(--text)' }}>Account</div>
              <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>
                {user ? 'Progress syncs to your account across devices' : 'Sign in to sync progress across devices'}
              </div>
            </div>
            {authLoading ? (
              <div className="px-4 py-4 flex items-center gap-2 text-sm" style={{ color: 'var(--muted)' }}>
                <Loader2 size={16} className="animate-spin" aria-hidden="true" />
                Loading account…
              </div>
            ) : user ? (
              <>
                <SettingRow
                  label={user.displayName ?? 'Signed in'}
                  sub={user.email ?? undefined}
                  right={
                    user.photoURL ? (
                      <img
                        src={user.photoURL}
                        alt=""
                        className="w-9 h-9 rounded-full"
                        referrerPolicy="no-referrer"
                      />
                    ) : null
                  }
                />
                {canSync && (
                  <SettingRow
                    label="Cloud sync"
                    sub={
                      syncStatus === 'syncing'
                        ? 'Syncing…'
                        : syncStatus === 'offline'
                          ? 'Offline — changes save locally'
                          : syncStatus === 'error'
                            ? syncError ?? 'Sync failed'
                            : lastSyncedAt
                              ? `Last synced ${new Date(lastSyncedAt).toLocaleString()}`
                              : 'Ready'
                    }
                    right={
                      <button
                        type="button"
                        className="studium-btn-secondary min-h-[36px] gap-1.5"
                        disabled={syncStatus === 'syncing'}
                        onClick={() => void syncNow()}
                      >
                        {syncStatus === 'syncing'
                          ? <Loader2 size={15} className="animate-spin" />
                          : <Cloud size={15} />}
                        Sync
                      </button>
                    }
                  />
                )}
                <div className="px-4 py-2 border-t" style={{ borderColor: 'var(--border)' }}>
                  <button
                    type="button"
                    className="studium-btn-secondary min-h-[36px]"
                    disabled={authBusy}
                    onClick={() => {
                      setAuthBusy(true)
                      void signOut().finally(() => setAuthBusy(false))
                    }}
                  >
                    {authBusy ? <Loader2 size={15} className="animate-spin" /> : 'Sign out'}
                  </button>
                </div>
              </>
            ) : (
              <div className="px-4 py-3 space-y-2">
                {authError && (
                  <div className="text-sm" style={{ color: 'var(--error)' }} role="alert">
                    {authError}
                  </div>
                )}
                <button
                  type="button"
                  className="studium-btn-primary min-h-[36px]"
                  disabled={authBusy}
                  onClick={() => {
                    clearError()
                    setAuthBusy(true)
                    void signInWithGoogle().finally(() => setAuthBusy(false))
                  }}
                >
                  {authBusy ? <Loader2 size={15} className="animate-spin" /> : 'Sign in with Google'}
                </button>
              </div>
            )}
          </div>
        )}

        <div className="studium-card overflow-hidden p-0">
          <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="font-semibold" style={{ color: 'var(--text)' }}>Your progress</div>
            <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>
              {user ? 'Synced to your account when signed in' : 'Saved in this browser only'}
            </div>
          </div>
          <SettingRow label="Questions Attempted" right={
            <span className="text-sm font-semibold" style={{ color: 'var(--text)' }}>{attempted}</span>
          } />
          <SettingRow label="Questions Seen" right={
            <span className="text-sm font-semibold" style={{ color: 'var(--text)' }}>{seen}</span>
          } />
          <SettingRow label="Saved Quizzes" right={
            <span className="text-sm font-semibold" style={{ color: 'var(--text)' }}>{savedQuizCount}</span>
          } />
        </div>

        <div className="studium-card overflow-hidden p-0">
          <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="studium-eyebrow">Appearance</div>
          </div>
          <SettingRow
            label={isDark ? 'Dark Mode' : 'Light Mode'}
            sub="Toggle between light and dark"
            right={
              <button type="button" onClick={onToggleTheme} className="studium-btn-secondary min-h-[36px] py-1.5">
                {isDark ? <Sun size={15} /> : <Moon size={15} />}
                {isDark ? 'Light' : 'Dark'}
              </button>
            }
          />
          <div className="flex items-center justify-between px-4 py-3 border-b last:border-0"
            style={{ borderColor: 'var(--border)' }}>
            <div>
              <div className="text-sm font-medium" style={{ color: 'var(--text)' }}>Question Font Size</div>
              <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>
                Applies to questions and passages
              </div>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-xs studium-mono w-8 text-right tabular-nums" style={{ color: 'var(--muted)' }}>
                {fontSize}px
              </span>
              <input
                type="range"
                min={13}
                max={20}
                step={1}
                value={fontSize}
                onChange={e => onFontSizeChange(Number(e.target.value))}
                className="w-28 accent-[var(--accent)]"
                aria-label="Question font size"
              />
            </div>
          </div>
        </div>

        <div className="studium-card overflow-hidden p-0">
          <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="studium-eyebrow">Data</div>
          </div>
          <div className="px-4 py-2 border-b text-sm" style={{ color: 'var(--muted)', borderColor: 'var(--border)' }}>
            {user
              ? 'Reset clears local data and syncs the reset to your account.'
              : 'Progress is stored locally in your browser. Clearing site data will reset everything.'}
          </div>
          <div className="px-4 py-2">
            <button
              onClick={() => setShowConfirm(true)}
              className="text-sm font-medium transition-colors"
              style={{ color: 'var(--error)' }}
            >
              Reset All Progress
            </button>
          </div>
        </div>

      </div>

      {showConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4"
          style={{ background: 'rgba(0,0,0,0.6)' }}>
          <div className="studium-card p-6 max-w-xs w-full space-y-4 shadow-2xl">
            <div className="flex items-center gap-2">
              <AlertTriangle size={20} style={{ color: 'var(--error)' }} />
              <div className="text-base font-semibold" style={{ color: 'var(--text)' }}>Reset All Progress?</div>
            </div>
            <div className="text-sm leading-relaxed" style={{ color: 'var(--muted)' }}>
              This will clear all question progress, saved quizzes, and vocab buckets. This cannot be undone.
            </div>
            <div className="flex gap-3">
              <button type="button" onClick={() => setShowConfirm(false)} className="studium-btn-secondary flex-1">
                Cancel
              </button>
              <button type="button" onClick={handleReset}
                className="studium-btn-primary flex-1"
                style={{ background: 'var(--error)' }}>
                Reset
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
