import { useMemo } from 'react'
import type { Question, QuestionProgress } from '../../types'

interface StatsViewProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
}

function StatCard({ label, value, sub, accent }: { label: string; value: string | number; sub?: string; accent?: string }) {
  return (
    <div className="studium-card p-4">
      <div className="text-2xl font-bold tabular-nums" style={{ color: accent ?? 'var(--text)' }}>{value}</div>
      <div className="text-sm mt-0.5" style={{ color: 'var(--text)' }}>{label}</div>
      {sub && <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>{sub}</div>}
    </div>
  )
}

function ProgressBar({ value, max, accent }: { value: number; max: number; accent: string }) {
  const pct = max > 0 ? Math.round((value / max) * 100) : 0
  return (
    <div className="flex items-center gap-3">
      <div className="flex-1 h-1 rounded-full overflow-hidden" style={{ background: 'var(--border)' }}>
        <div className="h-full rounded-full transition-all duration-500" style={{ width: `${pct}%`, background: accent }} />
      </div>
      <span className="text-xs w-9 text-right tabular-nums" style={{ color: 'var(--muted)' }}>{pct}%</span>
    </div>
  )
}

export default function StatsView({ questions, progress }: StatsViewProps) {
  const stats = useMemo(() => {
    const total = questions.length
    const seen = questions.filter(q => progress[q.questionId]?.seen).length
    const answered = questions.filter(q => progress[q.questionId]?.correct !== undefined).length
    const correct = questions.filter(q => progress[q.questionId]?.correct === true).length
    const accuracy = answered > 0 ? Math.round((correct / answered) * 100) : 0

    const modules = [...new Set(questions.map(q => q.module))]
    const byModule = modules.map(m => {
      const qs = questions.filter(q => q.module === m)
      const ans = qs.filter(q => progress[q.questionId]?.correct !== undefined)
      const cor = qs.filter(q => progress[q.questionId]?.correct === true)
      return {
        module: m,
        total: qs.length,
        answered: ans.length,
        correct: cor.length,
        accuracy: ans.length > 0 ? Math.round((cor.length / ans.length) * 100) : 0,
      }
    })

    const difficulties = ['E', 'M', 'H']
    const byDifficulty = difficulties.map(d => {
      const qs = questions.filter(q => q.difficulty === d)
      const ans = qs.filter(q => progress[q.questionId]?.correct !== undefined)
      const cor = qs.filter(q => progress[q.questionId]?.correct === true)
      return {
        difficulty: d,
        label: d === 'E' ? 'Easy' : d === 'M' ? 'Medium' : 'Hard',
        accent: d === 'E' ? 'var(--success)' : d === 'M' ? 'var(--warning)' : 'var(--error)',
        total: qs.length,
        answered: ans.length,
        correct: cor.length,
        accuracy: ans.length > 0 ? Math.round((cor.length / ans.length) * 100) : 0,
      }
    })

    return { total, seen, answered, correct, accuracy, byModule, byDifficulty }
  }, [questions, progress])

  const accuracyAccent = stats.accuracy >= 80
    ? 'var(--success)'
    : stats.accuracy >= 60
      ? 'var(--warning)'
      : 'var(--error)'

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-6 space-y-5">

        {/* Overview grid */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-2.5">
          <StatCard label="Accuracy" value={`${stats.accuracy}%`}
            accent={accuracyAccent}
            sub={`${stats.correct} correct`} />
          <StatCard label="Attempted" value={stats.answered} sub={`of ${stats.total} total`} />
          <StatCard label="Seen" value={stats.seen} sub={`${stats.total > 0 ? Math.round((stats.seen / stats.total) * 100) : 0}%`} />
          <StatCard label="Total" value={stats.total} />
        </div>

        {/* By Module */}
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-2.5">
          <div className="studium-card p-4 space-y-3">
            <div className="text-base font-semibold" style={{ color: 'var(--text)' }}>By Module</div>
            {stats.byModule.map(m => (
              <div key={m.module} className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="font-medium capitalize" style={{ color: 'var(--text)' }}>{m.module}</span>
                  <span style={{ color: 'var(--muted)' }}>{m.answered}/{m.total} · {m.accuracy}%</span>
                </div>
                <ProgressBar value={m.correct} max={m.answered || 1} accent="var(--accent)" />
              </div>
            ))}
          </div>

          {/* By Difficulty */}
          <div className="studium-card p-4 space-y-3">
            <div className="text-base font-semibold" style={{ color: 'var(--text)' }}>By Difficulty</div>
            {stats.byDifficulty.map(d => (
              <div key={d.difficulty} className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="font-medium" style={{ color: d.accent }}>{d.label}</span>
                  <span style={{ color: 'var(--muted)' }}>{d.answered}/{d.total} · {d.accuracy}%</span>
                </div>
                <ProgressBar value={d.correct} max={d.answered || 1} accent={d.accent} />
              </div>
            ))}
          </div>
        </div>

        {stats.answered === 0 && (
          <div className="text-center py-8 text-sm" style={{ color: 'var(--muted)' }}>
            Complete some questions to see your stats here
          </div>
        )}
      </div>
    </div>
  )
}
