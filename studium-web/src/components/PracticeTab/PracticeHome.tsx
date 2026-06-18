import { useState, useMemo, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import type {
  Question, QuestionProgress, FilterOptions, SavedQuiz,
} from '../../types'
import { getFilteredQuestions } from '../../utils/questions'
import { deleteQuiz } from '../../store/quiz'
import { Play, SlidersHorizontal } from 'lucide-react'
import { useWidePracticeLayout } from '../../hooks/useMediaQuery'
import { PRACTICE_SIDEBAR_WIDTH_PX } from '../../design/tokens'
import { SectionEyebrow } from '../ui/SectionEyebrow'
import { PracticeFiltersPanel, type PracticeFilterState } from './PracticeFiltersPanel'
import { ContinueQuizCard } from './ContinueQuizCard'
import { ConceptCard, type ConceptCategoryData } from './ConceptCard'
import { PageHeader } from '../ui/PageHeader'
import { Button } from '../ui/Button'
import { EmptyState } from '../ui/EmptyState'

interface PracticeHomeProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
  savedQuizzes: SavedQuiz[]
  cbVerifiedNotOnPracticeTestIds: Set<string>
  initialModule?: 'math' | 'english'
  onModulePresetConsumed?: () => void
  onStartQuiz: (filters: FilterOptions) => string | null
  onQuizzesChange: (quizzes: SavedQuiz[]) => void
}

import { quizFilterTags } from '../../lib/quizFilterTags'

export default function PracticeHome({
  questions, progress, savedQuizzes, cbVerifiedNotOnPracticeTestIds,
  initialModule, onModulePresetConsumed,
  onStartQuiz, onQuizzesChange,
}: PracticeHomeProps) {
  const navigate = useNavigate()
  const useWideSplit = useWidePracticeLayout()
  const [showFilterSheet, setShowFilterSheet] = useState(false)

  const [filterState, setFilterState] = useState<PracticeFilterState>({
    answerStatus: 'all',
    shuffled: true,
    module: initialModule,
  })

  useEffect(() => {
    if (!initialModule) return
    setFilterState(prev => ({ ...prev, module: initialModule }))
    onModulePresetConsumed?.()
  }, [initialModule, onModulePresetConsumed])

  function patchFilters(patch: Partial<PracticeFilterState>) {
    setFilterState(prev => ({ ...prev, ...patch }))
  }

  const currentFilters: FilterOptions = useMemo(() => ({
    module: filterState.module,
    difficulty: filterState.difficulty,
    primaryClassCdDesc: undefined,
    skillDesc: undefined,
    answerStatus: filterState.answerStatus,
    isBluebook: undefined,
    cbVerifiedInactive: filterState.cbVerifiedInactive,
    shuffled: false,
    questionLimit: filterState.questionLimit,
  }), [filterState])

  const filteredQuestions = useMemo(
    () => getFilteredQuestions(questions, currentFilters, progress, cbVerifiedNotOnPracticeTestIds),
    [questions, currentFilters, progress, cbVerifiedNotOnPracticeTestIds],
  )

  const matchingCount = filteredQuestions.length

  const conceptCategories: ConceptCategoryData[] = useMemo(() => {
    const catMap: Record<string, Record<string, number>> = {}
    for (const q of filteredQuestions) {
      if (!catMap[q.primaryClassCdDesc]) catMap[q.primaryClassCdDesc] = {}
      catMap[q.primaryClassCdDesc][q.skillDesc] = (catMap[q.primaryClassCdDesc][q.skillDesc] ?? 0) + 1
    }
    return Object.entries(catMap)
      .map(([cat, skillsMap]) => ({
        id: cat,
        count: Object.values(skillsMap).reduce((a, b) => a + b, 0),
        skills: Object.entries(skillsMap)
          .map(([id, count]) => ({ id, count }))
          .sort((a, b) => b.count - a.count),
      }))
      .sort((a, b) => b.count - a.count)
  }, [filteredQuestions])

  function startQuiz(catId?: string, skillId?: string) {
    const id = onStartQuiz({
      ...currentFilters,
      shuffled: filterState.shuffled,
      ...(catId ? { primaryClassCdDesc: catId } : {}),
      ...(skillId ? { skillDesc: skillId } : {}),
    })
    if (id) navigate(`/practice/quiz/${id}`)
  }

  function handleDeleteQuiz(id: string) {
    deleteQuiz(id)
    onQuizzesChange(savedQuizzes.filter(q => q.id !== id))
  }

  const activeFilterBadges = useMemo(
    () => quizFilterTags(currentFilters).filter(tag => tag !== 'All questions'),
    [currentFilters],
  )

  const startButtonLabel = matchingCount === 1
    ? 'Start 1 question'
    : `Start ${matchingCount} questions`

  const startButton = (
    <Button fullWidth onClick={() => startQuiz()} disabled={matchingCount === 0}>
      <Play size={16} aria-hidden="true" />
      {startButtonLabel}
    </Button>
  )

  const mainColumn = (
    <div
      className="flex-1 min-w-0 overflow-y-auto studium-screen px-4 sm:px-6 py-4 lg:py-6"
      style={{ paddingBottom: useWideSplit ? undefined : '5.5rem' }}
    >
      {savedQuizzes.length > 0 && (
        <section className="mb-6">
          <SectionEyebrow>Continue</SectionEyebrow>
          <div className="mt-3 flex flex-col gap-3">
            {savedQuizzes.slice(0, 5).map(quiz => {
              const answered = Object.values(quiz.answerStates).filter(s => s.hasSubmitted).length
              return (
                <ContinueQuizCard
                  key={quiz.id}
                  tags={quizFilterTags(quiz.filters)}
                  answered={answered}
                  total={quiz.questionIds.length}
                  onResume={() => navigate(`/practice/quiz/${quiz.id}`)}
                  onDelete={() => handleDeleteQuiz(quiz.id)}
                />
              )
            })}
          </div>
        </section>
      )}

      <PageHeader
        title="Practice questions"
        subtitle={`${conceptCategories.length} topics · ${matchingCount} questions match`}
      />

      {activeFilterBadges.length > 0 && (
        <div className="flex flex-wrap gap-2 mb-4">
          {activeFilterBadges.map(b => (
            <span key={b} className="studium-filter-badge">{b}</span>
          ))}
        </div>
      )}

      {conceptCategories.length === 0 ? (
        <EmptyState
          title="No questions match these filters"
          description="Try removing a filter or choosing a broader section to see more questions."
          action={
            !useWideSplit ? (
              <Button variant="secondary" onClick={() => setShowFilterSheet(true)}>
                <SlidersHorizontal size={16} aria-hidden="true" />
                Change filters
              </Button>
            ) : undefined
          }
        />
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
          {conceptCategories.map((cat, i) => (
            <ConceptCard
              key={cat.id}
              category={cat}
              variant={filterState.module === 'english' ? 'rw' : i % 2 === 1 ? 'rw' : 'math'}
              onPractice={() => startQuiz(cat.id)}
              onPracticeSkill={skillId => startQuiz(cat.id, skillId)}
            />
          ))}
        </div>
      )}
    </div>
  )

  if (useWideSplit) {
    return (
      <div className="flex flex-1 min-h-0 overflow-hidden">
        <aside
          className="shrink-0 flex flex-col border-r studium-screen overflow-hidden border-[var(--border)]"
          style={{ width: PRACTICE_SIDEBAR_WIDTH_PX }}
        >
          <div className="px-5 pt-5 pb-3">
            <h2 className="studium-page-title m-0 text-[1.5rem]">Filters</h2>
            <p className="mt-2 m-0 flex items-baseline gap-2">
              <span className={`studium-stat-digit text-[1.5rem] ${matchingCount > 0 ? 'text-[var(--accent)]' : 'text-[var(--muted)]'}`}>
                {matchingCount}
              </span>
              <span className="studium-page-subtitle">
                {matchingCount === 1 ? 'question matches' : 'questions match'}
              </span>
            </p>
          </div>
          <div className="flex-1 overflow-y-auto px-4 pb-4">
            <PracticeFiltersPanel filters={filterState} onChange={patchFilters} sidebar />
          </div>
          <div className="shrink-0 p-4 border-t border-[var(--border)] bg-[var(--card)]">
            {startButton}
          </div>
        </aside>
        {mainColumn}
      </div>
    )
  }

  return (
    <div className="flex flex-1 min-h-0 flex-col overflow-hidden relative">
      <div className="shrink-0 border-b px-4 py-3 flex items-center gap-3 bg-[var(--card)] border-[var(--border)]">
        <div className="flex-1 min-w-0">
          <div className="text-base font-semibold text-[var(--text)]">Practice</div>
          <div className="text-sm mt-0.5 text-[var(--muted)]">
            <span className={matchingCount > 0 ? 'text-[var(--accent)] font-semibold' : ''}>{matchingCount}</span>
            {' '}{matchingCount === 1 ? 'question matches' : 'questions match'}
          </div>
        </div>
        <Button variant="secondary" onClick={() => setShowFilterSheet(true)}>
          <SlidersHorizontal size={16} aria-hidden="true" />
          Filters
        </Button>
      </div>

      {mainColumn}

      <div className="md:hidden fixed bottom-[calc(3.25rem+env(safe-area-inset-bottom))] left-0 right-0 z-20 border-t px-4 py-2 bg-[var(--card)] border-[var(--border)]">
        {startButton}
      </div>

      {showFilterSheet && (
        <div className="fixed inset-0 z-40 flex flex-col md:hidden" role="dialog" aria-modal="true" aria-label="Filters">
          <button
            type="button"
            className="absolute inset-0 bg-black/40 border-0 cursor-pointer"
            aria-label="Close filters"
            onClick={() => setShowFilterSheet(false)}
          />
          <div className="relative mt-auto max-h-[92vh] flex flex-col rounded-t-[var(--radius-sheet)] overflow-hidden studium-screen bg-[var(--bg)]">
            <div className="flex items-center justify-between px-4 py-3 border-b shrink-0 border-[var(--border)] bg-[var(--card)]">
              <h2 className="text-lg font-semibold m-0">Filters</h2>
              <Button variant="secondary" onClick={() => setShowFilterSheet(false)} aria-label="Close filters">
                Done
              </Button>
            </div>
            <div className="flex-1 overflow-y-auto px-4 py-4">
              <PracticeFiltersPanel filters={filterState} onChange={patchFilters} />
            </div>
            <div className="shrink-0 p-4 border-t border-[var(--border)] bg-[var(--card)] space-y-2">
              <p className="text-sm text-center m-0 text-[var(--muted)]">
                {matchingCount} {matchingCount === 1 ? 'question' : 'questions'} match
              </p>
              <Button
                fullWidth
                onClick={() => {
                  startQuiz()
                  setShowFilterSheet(false)
                }}
                disabled={matchingCount === 0}
              >
                {startButtonLabel}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
