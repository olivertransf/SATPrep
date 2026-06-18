import { useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import type { Question, QuestionProgress } from '../../types'
import { PageHeader } from '../ui/PageHeader'
import { StatBlock, ProgressBar } from '../ui/StatBlock'
import { Button } from '../ui/Button'
import { useAppData } from '../../context/AppDataContext'

interface StatsViewProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
}

function moduleDisplayName(module: string) {
  return module.toLowerCase() === 'english' ? 'Reading & Writing' : 'Math'
}

export default function StatsView({ questions, progress }: StatsViewProps) {
  const navigate = useNavigate()
  const { setPracticeModulePreset } = useAppData()

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
        label: moduleDisplayName(m),
        total: qs.length,
        answered: ans.length,
        correct: cor.length,
        accuracy: ans.length > 0 ? Math.round((cor.length / ans.length) * 100) : 0,
        accent: m.toLowerCase() === 'english' ? 'var(--rw)' : 'var(--math)',
      }
    })

    const difficulties = ['E', 'M', 'H'] as const
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

  const weakest = stats.byModule
    .filter(m => m.answered > 0)
    .sort((a, b) => a.accuracy - b.accuracy)[0]

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-8 space-y-5">
        <PageHeader
          title="Progress"
          subtitle="Track accuracy across sections and difficulty levels"
        />

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-2.5">
          <StatBlock label="Accuracy" value={`${stats.accuracy}%`} accent={accuracyAccent} sub={`${stats.correct} correct`} />
          <StatBlock label="Attempted" value={stats.answered} sub={`of ${stats.total} total`} />
          <StatBlock label="Seen" value={stats.seen} sub={`${stats.total > 0 ? Math.round((stats.seen / stats.total) * 100) : 0}% of bank`} />
          <StatBlock label="Question bank" value={stats.total} />
        </div>

        {weakest && (
          <div className="studium-card p-4 flex flex-col sm:flex-row sm:items-center gap-3">
            <div className="flex-1 min-w-0">
              <div className="text-sm font-semibold text-[var(--text)]">Practice your weak areas</div>
              <div className="text-sm text-[var(--muted)] mt-0.5">
                {weakest.label} is at {weakest.accuracy}% accuracy ({weakest.answered} attempted)
              </div>
            </div>
            <Button
              variant="secondary"
              onClick={() => {
                setPracticeModulePreset(weakest.module.toLowerCase() === 'english' ? 'english' : 'math')
                navigate('/practice')
              }}
            >
              Practice {weakest.label}
            </Button>
          </div>
        )}

        <div className="grid grid-cols-1 xl:grid-cols-2 gap-2.5">
          <div className="studium-card p-4 space-y-3">
            <div className="text-base font-semibold text-[var(--text)]">By section</div>
            {stats.byModule.map(m => (
              <div key={m.module} className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="font-medium text-[var(--text)]">{m.label}</span>
                  <span className="text-[var(--muted)]">{m.answered}/{m.total} · {m.accuracy}%</span>
                </div>
                <ProgressBar value={m.correct} max={m.answered || 1} accent={m.accent} />
              </div>
            ))}
          </div>

          <div className="studium-card p-4 space-y-3">
            <div className="text-base font-semibold text-[var(--text)]">By difficulty</div>
            {stats.byDifficulty.map(d => (
              <div key={d.difficulty} className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="font-medium" style={{ color: d.accent }}>{d.label}</span>
                  <span className="text-[var(--muted)]">{d.answered}/{d.total} · {d.accuracy}%</span>
                </div>
                <ProgressBar value={d.correct} max={d.answered || 1} accent={d.accent} />
              </div>
            ))}
          </div>
        </div>

        {stats.answered === 0 && (
          <p className="text-center py-8 text-sm text-[var(--muted)]">
            Complete some questions to see your progress here.
          </p>
        )}
      </div>
    </div>
  )
}
