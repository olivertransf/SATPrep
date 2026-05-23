import { useState } from 'react'
import type { QuestionProgress } from '../../types'
import { resetAll } from '../../store/progress'
import { loadAllQuizzes } from '../../store/quiz'
import { loadDeletedProgress, tombstoneAllQuizzes } from '../../store/deleted'
import { pushCloudSync } from '../../store/cloudSync'
import { Sun, Moon, AlertTriangle } from 'lucide-react'
import type { useCloudSync } from '../../hooks/useCloudSync'
import { CloudSyncSettings } from './CloudSyncSettings'

interface SettingsViewProps {
  progress: Record<string, QuestionProgress>
  onProgressChange: (p: Record<string, QuestionProgress>) => void
  onQuizzesChange: (quizzes: import('../../types').SavedQuiz[]) => void
  onToggleTheme: () => void
  isDark: boolean
  fontSize: number
  onFontSizeChange: (size: number) => void
  cloudSync: ReturnType<typeof useCloudSync>
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
  progress, onProgressChange, onQuizzesChange, onToggleTheme, isDark, fontSize, onFontSizeChange, cloudSync,
}: SettingsViewProps) {
  const [showConfirm, setShowConfirm] = useState(false)

  const attempted = Object.values(progress).filter(p => p.correct !== undefined).length
  const seen = Object.values(progress).filter(p => p.seen).length
  const savedQuizCount = loadAllQuizzes().length

  async function handleReset() {
    const quizzes = loadAllQuizzes()
    const deletedQuizzes = tombstoneAllQuizzes(quizzes)
    resetAll()
    const deletedProgress = loadDeletedProgress()
    onProgressChange({})
    localStorage.removeItem('studium_saved_quizzes')
    localStorage.removeItem('studium_vocab_buckets')
    onQuizzesChange([])
    window.dispatchEvent(new Event('studium-cloud-sync'))
    setShowConfirm(false)
    if (cloudSync.active) {
      await pushCloudSync({
        progress: {},
        deleted_progress: deletedProgress,
        saved_quizzes: [],
        deleted_quizzes: deletedQuizzes,
        vocab_buckets: { words: {}, roots: {} },
      })
    }
  }

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-6 space-y-5">

        <div className="studium-card overflow-hidden p-0">
          <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="font-semibold" style={{ color: 'var(--text)' }}>Studium</div>
            <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>SAT Prep Practice App</div>
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
            <div className="studium-eyebrow">Cloud sync</div>
          </div>
          <CloudSyncSettings sync={cloudSync} />
        </div>

        <div className="studium-card overflow-hidden p-0">
          <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="studium-eyebrow">Data</div>
          </div>
          <div className="px-4 py-2 border-b text-sm" style={{ color: 'var(--muted)', borderColor: 'var(--border)' }}>
            Local cache in this browser. When cloud sync is on, Supabase is the backup across devices.
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

      {/* Confirm modal */}
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
