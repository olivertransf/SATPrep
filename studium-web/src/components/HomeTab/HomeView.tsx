import { useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import type { Question, QuestionProgress, SavedQuiz } from '../../types'
import { BookOpen, Calculator, Layers, BookMarked, ArrowRight, TrendingUp } from 'lucide-react'
import { quizFilterTags } from '../../lib/quizFilterTags'
import { getModuleBreakdown, getProgressSummary } from '../../lib/stats'
import { ContinueQuizCard } from '../PracticeTab/ContinueQuizCard'
import { Button } from '../ui/Button'
import { PageHeader } from '../ui/PageHeader'
import { PageContainer } from '../ui/PageContainer'
import { SectionHeading } from '../ui/SectionHeading'
import { useAppData } from '../../context/AppDataContext'

interface HomeViewProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
  savedQuizzes: SavedQuiz[]
  onDeleteQuiz: (id: string) => void
}

export default function HomeView({
  questions, progress, savedQuizzes, onDeleteQuiz,
}: HomeViewProps) {
  const navigate = useNavigate()
  const { setPracticeModulePreset } = useAppData()

  const summary = useMemo(() => getProgressSummary(questions, progress), [questions, progress])
  const modules = useMemo(() => getModuleBreakdown(questions, progress), [questions, progress])
  const mathModule = modules.find(m => m.module.toLowerCase() === 'math')
  const rwModule = modules.find(m => m.module.toLowerCase() === 'english')

  function startSection(module: 'math' | 'english') {
    setPracticeModulePreset(module)
    navigate('/practice')
  }

  return (
    <PageContainer>
      <PageHeader
        eyebrow="Free SAT practice"
        title="Study smarter for the Digital SAT"
        subtitle="Thousands of official-style questions, vocab flashcards, formula sheets, and a built-in Desmos calculator."
        action={(
          <Button onClick={() => navigate('/practice')} className="w-full sm:w-auto">
            Start practicing
          </Button>
        )}
      />

      {summary.accuracy !== null && (
        <div className="studium-card hidden md:flex items-center gap-4 p-4 sm:p-5 bg-[var(--hero-gradient)]">
          <div className="shrink-0 flex items-center justify-center rounded-xl w-12 h-12 studium-bg-math-chip">
            <TrendingUp size={24} aria-hidden="true" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-sm font-medium text-[var(--muted)]">Your accuracy so far</div>
            <div className="text-2xl font-bold tabular-nums text-[var(--accent)]">{summary.accuracy}%</div>
            <div className="text-sm text-[var(--muted)]">
              {summary.answered} of {summary.total} questions attempted
            </div>
          </div>
          <Button variant="secondary" onClick={() => navigate('/stats')} className="shrink-0 hidden sm:inline-flex">
            View progress
          </Button>
        </div>
      )}

      <section>
        <SectionHeading>Pick a section</SectionHeading>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <button type="button" onClick={() => startSection('math')} className="studium-quick-card group text-left">
            <div className="studium-quick-card__icon studium-bg-math-chip">
              <Calculator size={28} aria-hidden="true" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-lg font-semibold text-[var(--text)]">Math</div>
              <div className="text-sm mt-1 text-[var(--muted)]">
                {mathModule?.total.toLocaleString() ?? 0} questions
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
                {rwModule?.total.toLocaleString() ?? 0} questions
              </div>
            </div>
            <ArrowRight size={20} className="shrink-0 text-[var(--rw)] transition-transform group-hover:translate-x-0.5" aria-hidden="true" />
          </button>
        </div>

        <button
          type="button"
          onClick={() => navigate('/practice')}
          className="studium-quick-card group text-left w-full mt-4"
        >
          <div className="studium-quick-card__icon studium-bg-math-chip">
            <Layers size={28} aria-hidden="true" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-lg font-semibold text-[var(--text)]">All practice</div>
            <div className="text-sm mt-1 text-[var(--muted)]">Filters, topics, and custom sets</div>
          </div>
          <ArrowRight size={20} className="shrink-0 text-[var(--accent)] transition-transform group-hover:translate-x-0.5" aria-hidden="true" />
        </button>
      </section>

      {savedQuizzes.length > 0 && (
        <section>
          <SectionHeading>Continue where you left off</SectionHeading>
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

      <section className="hidden lg:block">
        <SectionHeading>Study tools</SectionHeading>
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
    </PageContainer>
  )
}
