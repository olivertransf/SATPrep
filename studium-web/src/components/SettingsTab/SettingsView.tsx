import { useState } from 'react'
import type { QuestionProgress } from '../../types'
import { resetAll } from '../../store/progress'
import { loadAllQuizzes } from '../../store/quiz'
import { Sun, Moon, AlertTriangle } from 'lucide-react'

interface SettingsViewProps {
  progress: Record<string, QuestionProgress>
  onProgressChange: (p: Record<string, QuestionProgress>) => void
  onToggleTheme: () => void
  isDark: boolean
  fontSize: number
  onFontSizeChange: (size: number) => void
}

function SettingRow({ label, sub, right }: { label: string; sub?: string; right: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between px-4 py-3.5 border-b last:border-0"
      style={{ borderColor: 'var(--border)' }}>
      <div>
        <div className="text-sm font-medium" style={{ color: 'var(--text)' }}>{label}</div>
        {sub && <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>{sub}</div>}
      </div>
      <div>{right}</div>
    </div>
  )
}

export default function SettingsView({ progress, onProgressChange, onToggleTheme, isDark, fontSize, onFontSizeChange }: SettingsViewProps) {
  const [showConfirm, setShowConfirm] = useState(false)

  const attempted = Object.values(progress).filter(p => p.correct !== undefined).length
  const seen = Object.values(progress).filter(p => p.seen).length
  const savedQuizCount = loadAllQuizzes().length

  function handleReset() {
    const cleared = resetAll()
    onProgressChange(cleared)
    localStorage.removeItem('studium_saved_quizzes')
    localStorage.removeItem('studium_vocab_buckets')
    setShowConfirm(false)
  }

  return (
    <div className="flex-1 overflow-y-auto" style={{ background: 'var(--bg)' }}>
      <div className="max-w-lg mx-auto px-4 py-6 space-y-5">

        {/* App info */}
        <div className="rounded-xl border overflow-hidden"
          style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
          <div className="px-4 py-4 border-b" style={{ borderColor: 'var(--border)' }}>
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

        {/* Appearance */}
        <div className="rounded-xl border overflow-hidden"
          style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
          <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>Appearance</div>
          </div>
          <SettingRow
            label={isDark ? 'Dark Mode' : 'Light Mode'}
            sub="Toggle between light and dark"
            right={
              <button onClick={onToggleTheme}
                className="flex items-center gap-2 px-3 py-1.5 rounded-lg border text-sm font-medium transition-all"
                style={{ borderColor: 'var(--border)', color: 'var(--text)', background: 'var(--input)' }}>
                {isDark ? <Sun size={15} /> : <Moon size={15} />}
                {isDark ? 'Light' : 'Dark'}
              </button>
            }
          />
          <div className="flex items-center justify-between px-4 py-3.5 border-b last:border-0"
            style={{ borderColor: 'var(--border)' }}>
            <div>
              <div className="text-sm font-medium" style={{ color: 'var(--text)' }}>Question Font Size</div>
              <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>
                Applies to questions and passages
              </div>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-xs font-mono w-8 text-right" style={{ color: 'var(--muted)' }}>
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

        {/* Data */}
        <div className="rounded-xl border overflow-hidden"
          style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
          <div className="px-4 py-3 border-b" style={{ borderColor: 'var(--border)' }}>
            <div className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>Data</div>
          </div>
          <div className="px-4 py-3 border-b text-sm" style={{ color: 'var(--muted)', borderColor: 'var(--border)' }}>
            Progress is saved locally in your browser. Nothing is synced to the cloud.
          </div>
          <div className="px-4 py-3">
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
          <div className="rounded-2xl shadow-2xl p-6 max-w-xs w-full space-y-4 border"
            style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
            <div className="flex items-center gap-2">
              <AlertTriangle size={20} style={{ color: 'var(--error)' }} />
              <div className="text-base font-semibold" style={{ color: 'var(--text)' }}>Reset All Progress?</div>
            </div>
            <div className="text-sm leading-relaxed" style={{ color: 'var(--muted)' }}>
              This will clear all question progress, saved quizzes, and vocab buckets. This cannot be undone.
            </div>
            <div className="flex gap-3">
              <button onClick={() => setShowConfirm(false)}
                className="flex-1 py-2.5 border rounded-xl text-sm font-medium transition-all"
                style={{ borderColor: 'var(--border)', color: 'var(--text)' }}>
                Cancel
              </button>
              <button onClick={handleReset}
                className="flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all"
                style={{ background: 'var(--error)', color: '#fff' }}>
                Reset
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
