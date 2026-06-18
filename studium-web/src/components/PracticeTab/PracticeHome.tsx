import { useState, useMemo, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import type {
  Question, QuestionProgress, FilterOptions,
} from '../../types'
import { getFilteredQuestions } from '../../utils/questions'
import { Play, SlidersHorizontal } from 'lucide-react'
import { useWidePracticeLayout } from '../../hooks/useMediaQuery'
import { PRACTICE_SIDEBAR_WIDTH_PX } from '../../design/tokens'
import { quizFilterTags } from '../../lib/quizFilterTags'
import { PracticeFiltersPanel, type PracticeFilterState } from './PracticeFiltersPanel'
import { ConceptCard, type ConceptCategoryData } from './ConceptCard'
import { PageHeader } from '../ui/PageHeader'
import { Button } from '../ui/Button'
import { EmptyState } from '../ui/EmptyState'
import { BottomSheet } from '../ui/BottomSheet'

interface PracticeHomeProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
  cbVerifiedNotOnPracticeTestIds: Set<string>
  initialModule?: 'math' | 'english'
  onModulePresetConsumed?: () => void
  onStartQuiz: (filters: FilterOptions) => string | null
}

export default function PracticeHome({
  questions, progress, cbVerifiedNotOnPracticeTestIds,
  initialModule, onModulePresetConsumed,
  onStartQuiz,
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

  const topicSummary = conceptCategories.length === 1
    ? '1 topic'
    : `${conceptCategories.length} topics`

  const matchSummary = matchingCount === 1
    ? '1 question matches'
    : `${matchingCount} questions match`

  const browseContent = (
    <>
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
    </>
  )

  const mainColumn = (
    <div
      className="flex-1 min-w-0 overflow-y-auto studium-screen px-4 sm:px-6 py-4 lg:py-6"
      style={{ paddingBottom: useWideSplit ? undefined : '5.5rem' }}
    >
      {useWideSplit && (
        <PageHeader
          title="Practice questions"
          subtitle={`${topicSummary} · ${matchSummary}`}
        />
      )}

      {browseContent}
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
            {topicSummary}
            {' · '}
            <span className={matchingCount > 0 ? 'text-[var(--accent)] font-semibold' : ''}>
              {matchSummary}
            </span>
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

      <BottomSheet
        open={showFilterSheet}
        onClose={() => setShowFilterSheet(false)}
        title="Filters"
        ariaLabel="Filters"
        headerAction={(
          <Button variant="secondary" onClick={() => setShowFilterSheet(false)} aria-label="Close filters">
            Done
          </Button>
        )}
        footer={(
          <div className="space-y-2">
            <p className="text-sm text-center m-0 text-[var(--muted)]">{matchSummary}</p>
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
        )}
      >
        <PracticeFiltersPanel filters={filterState} onChange={patchFilters} />
      </BottomSheet>
    </div>
  )
}
