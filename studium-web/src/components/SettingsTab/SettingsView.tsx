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
import { PageHeader } from '../ui/PageHeader'
import { Button } from '../ui/Button'
import { Modal } from '../ui/Modal'

interface SettingsViewProps {
  progress: Record<string, QuestionProgress>
  onProgressChange: (p: Record<string, QuestionProgress>) => void
  onQuizzesChange: (quizzes: import('../../types').SavedQuiz[]) => void
  onToggleTheme: () => void
  isDark: boolean
  fontSize: number
  onFontSizeChange: (size: number) => void
  answerChoiceFontSize: number
  onAnswerChoiceFontSizeChange: (size: number) => void
}

function SettingRow({ label, sub, right }: { label: string; sub?: string; right: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between px-4 py-3 min-h-[52px] border-b last:border-0 border-[var(--border)]">
      <div className="min-w-0 pr-4">
        <div className="text-sm font-medium text-[var(--text)]">{label}</div>
        {sub && <div className="text-xs mt-0.5 text-[var(--muted)]">{sub}</div>}
      </div>
      <div className="shrink-0">{right}</div>
    </div>
  )
}

export default function SettingsView({
  progress, onProgressChange, onQuizzesChange, onToggleTheme, isDark, fontSize, onFontSizeChange,
  answerChoiceFontSize, onAnswerChoiceFontSizeChange,
}: SettingsViewProps) {
  const [showConfirm, setShowConfirm] = useState(false)
  const [authBusy, setAuthBusy] = useState(false)
  const { user, loading: authLoading, configured, error: authError, signInWithGoogle, signOut, clearError } = useAuth()
  const { status: syncStatus, lastSyncedAt, error: syncError, syncNow, canSync } = useSync()

  const attempted = Object.values(progress).filter(p => p.correct !== undefined).length
  const seen = Object.values(progress).filter(p => p.seen).length
  const savedQuizCount = loadAllQuizzes().length

  function syncStatusText() {
    if (syncStatus === 'syncing') return 'Syncing…'
    if (syncStatus === 'offline') return 'Offline — changes save locally'
    if (syncStatus === 'error') return syncError ?? 'Sync failed'
    if (lastSyncedAt) return `Last synced ${new Date(lastSyncedAt).toLocaleString()}`
    return 'Ready'
  }

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
        <PageHeader title="Settings" subtitle="Account, appearance, and data" />

        {configured && (
          <section className="studium-card overflow-hidden p-0">
            <div className="px-4 py-3 border-b border-[var(--border)]">
              <div className="font-semibold text-[var(--text)]">Account & sync</div>
              <div className="text-xs mt-0.5 text-[var(--muted)]">
                {user ? 'Progress syncs across your devices' : 'Sign in to sync progress across devices'}
              </div>
            </div>
            {authLoading ? (
              <div className="px-4 py-4 flex items-center gap-2 text-sm text-[var(--muted)]">
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
                      <img src={user.photoURL} alt="" className="w-9 h-9 rounded-full" referrerPolicy="no-referrer" />
                    ) : null
                  }
                />
                {canSync && (
                  <SettingRow
                    label="Cloud sync"
                    sub={syncStatusText()}
                    right={
                      <Button variant="secondary" disabled={syncStatus === 'syncing'} onClick={() => void syncNow()}>
                        {syncStatus === 'syncing' ? <Loader2 size={15} className="animate-spin" /> : <Cloud size={15} />}
                        Sync now
                      </Button>
                    }
                  />
                )}
                <div className="px-4 py-3 border-t border-[var(--border)]">
                  <Button variant="secondary" disabled={authBusy} onClick={() => { setAuthBusy(true); void signOut().finally(() => setAuthBusy(false)) }}>
                    {authBusy ? <Loader2 size={15} className="animate-spin" /> : 'Sign out'}
                  </Button>
                </div>
              </>
            ) : (
              <div className="px-4 py-3 space-y-2">
                {authError && <div className="text-sm text-[var(--error)]" role="alert">{authError}</div>}
                <Button
                  disabled={authBusy}
                  onClick={() => { clearError(); setAuthBusy(true); void signInWithGoogle().finally(() => setAuthBusy(false)) }}
                >
                  {authBusy ? <Loader2 size={15} className="animate-spin" /> : 'Sign in with Google'}
                </Button>
              </div>
            )}
          </section>
        )}

        <section className="studium-card overflow-hidden p-0">
          <div className="px-4 py-3 border-b border-[var(--border)]">
            <div className="font-semibold text-[var(--text)]">Your progress</div>
            <div className="text-xs mt-0.5 text-[var(--muted)]">Stored in this browser{user ? ' and synced to your account' : ''}</div>
          </div>
          <SettingRow label="Questions attempted" right={<span className="text-sm font-semibold text-[var(--text)]">{attempted}</span>} />
          <SettingRow label="Questions seen" right={<span className="text-sm font-semibold text-[var(--text)]">{seen}</span>} />
          <SettingRow label="Saved quizzes" right={<span className="text-sm font-semibold text-[var(--text)]">{savedQuizCount}</span>} />
        </section>

        <section className="studium-card overflow-hidden p-0">
          <div className="px-4 py-3 border-b border-[var(--border)]">
            <div className="font-semibold text-[var(--text)]">Appearance</div>
            <div className="text-xs mt-0.5 text-[var(--muted)]">Theme and question text size</div>
          </div>
          <SettingRow
            label={isDark ? 'Dark mode' : 'Light mode'}
            sub="Switch between light and dark"
            right={
              <Button variant="secondary" onClick={onToggleTheme}>
                {isDark ? <Sun size={15} aria-hidden="true" /> : <Moon size={15} aria-hidden="true" />}
                {isDark ? 'Light' : 'Dark'}
              </Button>
            }
          />
          <SettingRow
            label="Question font size"
            sub="Applies to questions and passages"
            right={
              <div className="flex items-center gap-3">
                <span className="text-xs studium-mono w-8 text-right tabular-nums text-[var(--muted)]">{fontSize}px</span>
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
            }
          />
          <SettingRow
            label="Answer choice font size"
            sub="Applies to A, B, C, D options only"
            right={
              <div className="flex items-center gap-3">
                <span className="text-xs studium-mono w-8 text-right tabular-nums text-[var(--muted)]">{answerChoiceFontSize}px</span>
                <input
                  type="range"
                  min={13}
                  max={20}
                  step={1}
                  value={answerChoiceFontSize}
                  onChange={e => onAnswerChoiceFontSizeChange(Number(e.target.value))}
                  className="w-28 accent-[var(--accent)]"
                  aria-label="Answer choice font size"
                />
              </div>
            }
          />
          <div className="px-4 py-3 border-t border-[var(--border)]">
            <p className="text-sm m-0 text-[var(--text)]" style={{ fontSize: `${fontSize}px` }}>
              Preview: The value of x is 12 when 2x + 3 = 27.
            </p>
            <p className="text-sm mt-2 mb-0 text-[var(--muted)]" style={{ fontSize: `${answerChoiceFontSize}px` }}>
              A) 12 &nbsp; B) 15 &nbsp; C) 27 &nbsp; D) 30
            </p>
          </div>
        </section>

        <section className="studium-card overflow-hidden p-0">
          <div className="px-4 py-3 border-b border-[var(--border)]">
            <div className="font-semibold text-[var(--text)]">Data</div>
            <div className="text-xs mt-0.5 text-[var(--muted)]">
              {user ? 'Reset clears local data and syncs the reset to your account.' : 'Progress is stored locally in your browser.'}
            </div>
          </div>
          <div className="px-4 py-3">
            <Button variant="destructive" onClick={() => setShowConfirm(true)}>
              Reset all progress
            </Button>
          </div>
        </section>
      </div>

      <Modal
        open={showConfirm}
        onClose={() => setShowConfirm(false)}
        title="Reset all progress?"
        footer={
          <div className="flex gap-3">
            <Button variant="secondary" fullWidth onClick={() => setShowConfirm(false)}>Cancel</Button>
            <Button variant="destructive" fullWidth onClick={handleReset}>Reset</Button>
          </div>
        }
      >
        <div className="flex items-start gap-2">
          <AlertTriangle size={20} className="text-[var(--error)] shrink-0 mt-0.5" aria-hidden="true" />
          <p className="text-sm leading-relaxed m-0 text-[var(--muted)]">
            This clears all question progress, saved quizzes, and vocab buckets. This cannot be undone.
          </p>
        </div>
      </Modal>
    </div>
  )
}
