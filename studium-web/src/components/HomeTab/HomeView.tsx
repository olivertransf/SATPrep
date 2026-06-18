import { useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import type { Question, QuestionProgress, SavedQuiz } from '../../types'
import { BookOpen, Calculator, Layers, BookMarked, ArrowRight, TrendingUp } from 'lucide-react'
import { ContinueQuizCard } from '../PracticeTab/ContinueQuizCard'
import { Button } from '../ui/Button'
import { PageHeader } from '../ui/PageHeader'
import { useAppData } from '../../context/AppDataContext'

interface HomeViewProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
  savedQuizzes: SavedQuiz[]
  onDeleteQuiz: (id: string) => void
}

import { quizFilterTags } from '../../lib/quizFilterTags'
export default function HomeView({
  questions, progress, savedQuizzes, onDeleteQuiz,
}: HomeViewProps) {
  const navigate = useNavigate()
  const { setPracticeModulePreset } = useAppData()

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

    return { total, answered, accuracy, math: sectionStats(mathQs), rw: sectionStats(rwQs) }
  }, [questions, progress])

  function startSection(module: 'math' | 'english') {
    setPracticeModulePreset(module)
    navigate('/practice')
  }

  return (
    <div className="flex-1 overflow-y-auto studium-screen">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-8 sm:py-10 space-y-8">
        <PageHeader
          eyebrow="Free SAT practice"
          title="Study smarter for the Digital SAT"
          subtitle="Thousands of official-style questions, vocab flashcards, formula sheets, and a built-in Desmos calculator."
          action={
            <Button onClick={() => navigate('/practice')} className="hidden sm:inline-flex">
              Start practicing
            </Button>
          }
        />

        <Button fullWidth onClick={() => navigate('/practice')} className="sm:hidden">
          Start practicing
        </Button>

        {stats.accuracy !== null && (
          <div className="studium-card hidden md:flex items-center gap-4 p-4 sm:p-5 bg-[var(--hero-gradient)]">
            <div className="shrink-0 flex items-center justify-center rounded-xl w-12 h-12 studium-bg-math-chip">
              <TrendingUp size={24} aria-hidden="true" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium text-[var(--muted)]">Your accuracy so far</div>
              <div className="text-2xl font-bold tabular-nums text-[var(--accent)]">{stats.accuracy}%</div>
              <div className="text-sm text-[var(--muted)]">
                {stats.answered} of {stats.total} questions attempted
              </div>
            </div>
            <Button variant="secondary" onClick={() => navigate('/stats')} className="shrink-0 hidden sm:inline-flex">
              View progress
            </Button>
          </div>
        )}

        <section>
          <h2 className="text-lg font-semibold m-0 mb-4 text-[var(--text)]">Pick a section</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <button type="button" onClick={() => startSection('math')} className="studium-quick-card group text-left">
              <div className="studium-quick-card__icon studium-bg-math-chip">
                <Calculator size={28} aria-hidden="true" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-lg font-semibold text-[var(--text)]">Math</div>
                <div className="text-sm mt-1 text-[var(--muted)]">
                  {stats.math.total.toLocaleString()} questions
                  {stats.math.accuracy !== null && (
                    <span className="hidden sm:inline">{` · ${stats.math.accuracy}% accuracy`}</span>
                  )}
                </div>
              </div>
              <ArrowRight size={20} className="shrink-0 text-[var(--accent)] transition-transform group-hover:translate-x-0.5" aria-hidden="true" />
            </button>

            <button type="button" onClick={() => startSection('english')} className="studium-quick-card group text-left">
              <div className="studium-quick-card__icon studium-bg-rw-chip">
                <BookOpen size={28} aria-hidden="true" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-lg font-semibold text-[var(--text)]">Reading & Writing</div>
                <div className="text-sm mt-1 text-[var(--muted)]">
                  {stats.rw.total.toLocaleString()} questions
                  {stats.rw.accuracy !== null && (
                    <span className="hidden sm:inline">{` · ${stats.rw.accuracy}% accuracy`}</span>
                  )}
                </div>
              </div>
              <ArrowRight size={20} className="shrink-0 text-[var(--rw)] transition-transform group-hover:translate-x-0.5" aria-hidden="true" />
            </button>
          </div>
        </section>

        {savedQuizzes.length > 0 && (
          <section>
            <h2 className="text-lg font-semibold m-0 mb-4 text-[var(--text)]">Continue where you left off</h2>
            <div className="flex flex-col gap-3">
              {savedQuizzes.slice(0, 5).map(quiz => {
                const answered = Object.values(quiz.answerStates).filter(s => s.hasSubmitted).length
                return (
                  <ContinueQuizCard
                    key={quiz.id}
                    tags={quizFilterTags(quiz.filters)}
                    answered={answered}
                    total={quiz.questionIds.length}
                    onResume={() => navigate(`/practice/quiz/${quiz.id}`)}
                    onDelete={() => onDeleteQuiz(quiz.id)}
                  />
                )
              })}
            </div>
          </section>
        )}

        <section>
          <h2 className="text-lg font-semibold m-0 mb-4 text-[var(--text)]">Study tools</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <button type="button" onClick={() => navigate('/vocab')} className="studium-tool-card">
              <Layers size={22} className="text-[var(--accent)] shrink-0" aria-hidden="true" />
              <div>
                <div className="font-semibold text-sm text-[var(--text)]">Vocabulary</div>
                <div className="text-xs mt-0.5 text-[var(--muted)]">Flashcards</div>
              </div>
            </button>
            <button type="button" onClick={() => navigate('/reference')} className="studium-tool-card">
              <BookMarked size={22} className="text-[var(--accent)] shrink-0" aria-hidden="true" />
              <div>
                <div className="font-semibold text-sm text-[var(--text)]">Reference</div>
                <div className="text-xs mt-0.5 text-[var(--muted)]">Formulas & rules</div>
              </div>
            </button>
            <button type="button" onClick={() => navigate('/desmos')} className="studium-tool-card">
              <Calculator size={22} className="text-[var(--accent)] shrink-0" aria-hidden="true" />
              <div>
                <div className="font-semibold text-sm text-[var(--text)]">Desmos</div>
                <div className="text-xs mt-0.5 text-[var(--muted)]">Graphing calculator</div>
              </div>
            </button>
          </div>
        </section>
      </div>
    </div>
  )
}
