import { useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import type { Question, QuestionProgress } from '../../types'
import { getDifficultyBreakdown, getModuleBreakdown, getProgressSummary } from '../../lib/stats'
import { PageHeader } from '../ui/PageHeader'
import { PageContainer } from '../ui/PageContainer'
import { Card } from '../ui/Card'
import { StatBlock, ProgressBar } from '../ui/StatBlock'
import { Button } from '../ui/Button'
import { useAppData } from '../../context/AppDataContext'

interface StatsViewProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
}

export default function StatsView({ questions, progress }: StatsViewProps) {
  const navigate = useNavigate()
  const { setPracticeModulePreset } = useAppData()

  const summary = useMemo(() => getProgressSummary(questions, progress), [questions, progress])
  const byModule = useMemo(() => getModuleBreakdown(questions, progress), [questions, progress])
  const byDifficulty = useMemo(() => getDifficultyBreakdown(questions, progress), [questions, progress])

  const accuracy = summary.accuracy ?? 0
  const accuracyAccent = accuracy >= 80
    ? 'var(--success)'
    : accuracy >= 60
      ? 'var(--warning)'
      : 'var(--error)'

  const weakest = byModule
    .filter(m => m.answered > 0)
    .sort((a, b) => a.accuracy - b.accuracy)[0]

  return (
    <PageContainer stackClassName="space-y-5">
      <PageHeader
        title="Progress"
        subtitle="Track accuracy across sections and difficulty levels"
      />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-2.5">
        <StatBlock label="Accuracy" value={`${accuracy}%`} accent={accuracyAccent} sub={`${summary.correct} correct`} />
        <StatBlock label="Attempted" value={summary.answered} sub={`of ${summary.total} total`} />
        <StatBlock label="Seen" value={summary.seen} sub={`${summary.total > 0 ? Math.round((summary.seen / summary.total) * 100) : 0}% of bank`} />
        <StatBlock label="Question bank" value={summary.total} />
      </div>

      {weakest && (
        <Card className="flex flex-col sm:flex-row sm:items-center gap-3">
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
        </Card>
      )}

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-2.5">
        <Card className="space-y-3">
          <div className="text-base font-semibold text-[var(--text)]">By section</div>
          {byModule.map(m => (
            <div key={m.module} className="space-y-1">
              <div className="flex justify-between text-sm">
                <span className="font-medium text-[var(--text)]">{m.label}</span>
                <span className="text-[var(--muted)]">{m.answered}/{m.total} · {m.accuracy}%</span>
              </div>
              <ProgressBar value={m.correct} max={m.answered || 1} accent={m.accent} />
            </div>
          ))}
        </Card>

        <Card className="space-y-3">
          <div className="text-base font-semibold text-[var(--text)]">By difficulty</div>
          {byDifficulty.map(d => (
            <div key={d.difficulty} className="space-y-1">
              <div className="flex justify-between text-sm">
                <span className="font-medium" style={{ color: d.accent }}>{d.label}</span>
                <span className="text-[var(--muted)]">{d.answered}/{d.total} · {d.accuracy}%</span>
              </div>
              <ProgressBar value={d.correct} max={d.answered || 1} accent={d.accent} />
            </div>
          ))}
        </Card>
      </div>

      {summary.answered === 0 && (
        <p className="text-center py-8 text-sm text-[var(--muted)]">
          Complete some questions to see your progress here.
        </p>
      )}
    </PageContainer>
  )
}
