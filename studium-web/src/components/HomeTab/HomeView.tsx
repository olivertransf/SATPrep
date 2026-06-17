import { useMemo } from 'react'
import type { Question, QuestionProgress, SavedQuiz } from '../../types'
import {
  BookOpen, Calculator, Layers, BookMarked, BarChart2, ArrowRight, TrendingUp,
} from 'lucide-react'
import { ContinueQuizCard } from '../PracticeTab/ContinueQuizCard'

interface HomeViewProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
  savedQuizzes: SavedQuiz[]
  onStartSection: (module: 'math' | 'english') => void
  onGoToPractice: () => void
  onGoToVocab: () => void
  onGoToReference: () => void
  onGoToStats: () => void
  onResumeQuiz: (quiz: SavedQuiz) => void
  onDeleteQuiz: (id: string) => void
}

function moduleLabel(module: string) {
  return module.toLowerCase() === 'english' ? 'Reading & Writing' : 'Math'
}

function describeQuiz(quiz: SavedQuiz): string {
  const parts: string[] = []
  if (quiz.filters.module) parts.push(moduleLabel(quiz.filters.module))
  if (quiz.filters.primaryClassCdDesc) parts.push(quiz.filters.primaryClassCdDesc)
  if (quiz.filters.skillDesc) parts.push(quiz.filters.skillDesc)
  return parts.length > 0 ? parts.join(' · ') : 'Mixed practice'
}

export default function HomeView({
  questions, progress, savedQuizzes,
  onStartSection, onGoToPractice, onGoToVocab, onGoToReference, onGoToStats,
  onResumeQuiz, onDeleteQuiz,
}: HomeViewProps) {
  const stats = useMemo(() => {
    const total = questions.length
    const mathQs = questions.filter(q => q.module.toLowerCase() === 'math')
    const rwQs = questions.filter(q => q.module.toLowerCase() === 'english')
    const answered = questions.filter(q => progress[q.questionId]?.correct !== undefined).length
    const correct = questions.filter(q => progress[q.questionId]?.correct === true).length
    const accuracy = answered > 0 ? Math.round((correct / answered) * 100) : null

    const sectionStats = (qs: Question[]) => {
      const ans = qs.filter(q => progress[q.questionId]?.correct !== undefined).length
      const cor = qs.filter(q => progress[q.questionId]?.correct === true).length
      return {
        total: qs.length,
        answered: ans,
        accuracy: ans > 0 ? Math.round((cor / ans) * 100) : null,
      }
    }

    return {
      total,
      answered,
      accuracy,
      math: sectionStats(mathQs),
      rw: sectionStats(rwQs),
    }
  }, [questions, progress])

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-8 sm:py-10 space-y-8">

        <header className="space-y-2">
          <p className="studium-eyebrow m-0">Free SAT practice</p>
          <h1 className="text-3xl sm:text-4xl font-bold tracking-tight m-0" style={{ color: 'var(--text)' }}>
            Study smarter for the Digital SAT
          </h1>
          <p className="studium-page-subtitle m-0 max-w-2xl text-base">
            Thousands of official-style questions, vocab flashcards, formula sheets, and a built-in Desmos calculator.
          </p>
        </header>

        {stats.accuracy !== null && (
          <div
            className="studium-card flex items-center gap-4 p-4 sm:p-5"
            style={{ background: 'var(--hero-gradient)' }}
          >
            <div
              className="shrink-0 flex items-center justify-center rounded-xl"
              style={{ width: 48, height: 48, background: 'var(--accent-chip-fill)', color: 'var(--accent)' }}
            >
              <TrendingUp size={24} aria-hidden="true" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium" style={{ color: 'var(--muted)' }}>Your accuracy so far</div>
              <div className="text-2xl font-bold tabular-nums" style={{ color: 'var(--accent)' }}>
                {stats.accuracy}%
              </div>
              <div className="text-sm" style={{ color: 'var(--muted)' }}>
                {stats.answered} of {stats.total} questions attempted
              </div>
            </div>
            <button type="button" onClick={onGoToStats} className="studium-btn-secondary shrink-0 hidden sm:inline-flex">
              View stats
            </button>
          </div>
        )}

        <section>
          <h2 className="text-lg font-semibold m-0 mb-4" style={{ color: 'var(--text)' }}>Start practicing</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <button
              type="button"
              onClick={() => onStartSection('math')}
              className="studium-quick-card group text-left"
            >
              <div className="studium-quick-card__icon" style={{ background: 'rgba(37, 99, 235, 0.1)', color: '#2563eb' }}>
                <Calculator size={28} aria-hidden="true" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-lg font-semibold" style={{ color: 'var(--text)' }}>Math</div>
                <div className="text-sm mt-1" style={{ color: 'var(--muted)' }}>
                  {stats.math.total.toLocaleString()} questions
                  {stats.math.accuracy !== null && ` · ${stats.math.accuracy}% accuracy`}
                </div>
              </div>
              <ArrowRight
                size={20}
                className="shrink-0 transition-transform group-hover:translate-x-0.5"
                style={{ color: 'var(--accent)' }}
                aria-hidden="true"
              />
            </button>

            <button
              type="button"
              onClick={() => onStartSection('english')}
              className="studium-quick-card group text-left"
            >
              <div className="studium-quick-card__icon" style={{ background: 'rgba(124, 58, 237, 0.1)', color: '#7c3aed' }}>
                <BookOpen size={28} aria-hidden="true" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-lg font-semibold" style={{ color: 'var(--text)' }}>Reading & Writing</div>
                <div className="text-sm mt-1" style={{ color: 'var(--muted)' }}>
                  {stats.rw.total.toLocaleString()} questions
                  {stats.rw.accuracy !== null && ` · ${stats.rw.accuracy}% accuracy`}
                </div>
              </div>
              <ArrowRight
                size={20}
                className="shrink-0 transition-transform group-hover:translate-x-0.5"
                style={{ color: 'var(--accent)' }}
                aria-hidden="true"
              />
            </button>
          </div>
        </section>

        {savedQuizzes.length > 0 && (
          <section>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold m-0" style={{ color: 'var(--text)' }}>Continue where you left off</h2>
              <button type="button" onClick={onGoToPractice} className="text-sm font-medium" style={{ color: 'var(--accent)' }}>
                All practice
              </button>
            </div>
            <div className="flex flex-col sm:flex-row gap-3 overflow-x-auto pb-1">
              {savedQuizzes.slice(0, 3).map(quiz => {
                const answered = Object.values(quiz.answerStates).filter(s => s.hasSubmitted).length
                return (
                  <ContinueQuizCard
                    key={quiz.id}
                    title={describeQuiz(quiz)}
                    answered={answered}
                    total={quiz.questionIds.length}
                    onResume={() => onResumeQuiz(quiz)}
                    onDelete={() => onDeleteQuiz(quiz.id)}
                  />
                )
              })}
            </div>
          </section>
        )}

        <section>
          <h2 className="text-lg font-semibold m-0 mb-4" style={{ color: 'var(--text)' }}>Study tools</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <button type="button" onClick={onGoToVocab} className="studium-tool-card">
              <Layers size={22} style={{ color: 'var(--accent)' }} aria-hidden="true" />
              <div>
                <div className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Vocabulary</div>
                <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>Flashcard decks</div>
              </div>
            </button>
            <button type="button" onClick={onGoToReference} className="studium-tool-card">
              <BookMarked size={22} style={{ color: 'var(--accent)' }} aria-hidden="true" />
              <div>
                <div className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Reference</div>
                <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>Formulas & rules</div>
              </div>
            </button>
            <button type="button" onClick={onGoToStats} className="studium-tool-card">
              <BarChart2 size={22} style={{ color: 'var(--accent)' }} aria-hidden="true" />
              <div>
                <div className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Progress</div>
                <div className="text-xs mt-0.5" style={{ color: 'var(--muted)' }}>Accuracy breakdown</div>
              </div>
            </button>
          </div>
        </section>

      </div>
    </div>
  )
}
