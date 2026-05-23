import { useState, useMemo } from 'react'
import type {
  Question, QuestionProgress, FilterOptions, SavedQuiz,
} from '../../types'
import { getFilteredQuestions } from '../../utils/questions'
import { deleteQuiz } from '../../store/quiz'
import { Play, SlidersHorizontal, X } from 'lucide-react'
import { useWidePracticeLayout } from '../../hooks/useMediaQuery'
import { PRACTICE_SIDEBAR_WIDTH_PX } from '../../design/tokens'
import { SectionEyebrow } from '../ui/SectionEyebrow'
import { PracticeFiltersPanel, type PracticeFilterState } from './PracticeFiltersPanel'
import { ContinueQuizCard } from './ContinueQuizCard'
import { ConceptCard, type ConceptCategoryData } from './ConceptCard'

interface PracticeHomeProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
  savedQuizzes: SavedQuiz[]
  cbVerifiedNotOnPracticeTestIds: Set<string>
  onStartQuiz: (filters: FilterOptions) => void
  onResumeQuiz: (quiz: SavedQuiz) => void
  onQuizzesChange: (quizzes: SavedQuiz[]) => void
}

const DIFFICULTY_LABELS: Record<string, string> = { E: 'Easy', M: 'Medium', H: 'Hard' }

const CARD_ACCENTS = ['#007aff', '#0a84ff', '#3f9bff', '#5caeff']

function sectionLabel(m: string) {
  const l = m.toLowerCase()
  if (l === 'english') return 'Reading & Writing'
  if (l === 'math') return 'Math'
  return m.charAt(0).toUpperCase() + m.slice(1)
}

function describeFilters(f: FilterOptions): string {
  const parts: string[] = []
  if (f.module) parts.push(sectionLabel(f.module))
  if (f.primaryClassCdDesc) parts.push(f.primaryClassCdDesc)
  if (f.skillDesc) parts.push(f.skillDesc)
  if (f.difficulty) parts.push(DIFFICULTY_LABELS[f.difficulty] ?? f.difficulty)
  if (f.answerStatus !== 'all') parts.push(f.answerStatus)
  if (f.isBluebook === 'bluebook') parts.push('Practice tests only')
  if (f.isBluebook === 'notBluebook') parts.push('Exclude active')
  if (f.cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests') parts.push('CB verified pool')
  if (f.questionLimit) parts.push(`Max ${f.questionLimit}`)
  return parts.length > 0 ? parts.join(' · ') : 'All Questions'
}

export default function PracticeHome({
  questions, progress, savedQuizzes, cbVerifiedNotOnPracticeTestIds,
  onStartQuiz, onResumeQuiz, onQuizzesChange,
}: PracticeHomeProps) {
  const useWideSplit = useWidePracticeLayout()
  const [showFilterSheet, setShowFilterSheet] = useState(false)

  const [filterState, setFilterState] = useState<PracticeFilterState>({
    answerStatus: 'all',
    shuffled: true,
  })

  function patchFilters(patch: Partial<PracticeFilterState>) {
    setFilterState(prev => ({ ...prev, ...patch }))
  }

  const currentFilters: FilterOptions = useMemo(() => ({
    module: undefined,
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

  function handleStart(catId?: string, skillId?: string) {
    onStartQuiz({
      ...currentFilters,
      shuffled: filterState.shuffled,
      ...(catId ? { primaryClassCdDesc: catId } : {}),
      ...(skillId ? { skillDesc: skillId } : {}),
    })
  }

  function handleDeleteQuiz(id: string) {
    deleteQuiz(id)
    onQuizzesChange(savedQuizzes.filter(q => q.id !== id))
  }

  const filterSummary = useMemo(() => {
    const parts: string[] = []
    if (filterState.difficulty) parts.push(DIFFICULTY_LABELS[filterState.difficulty] ?? filterState.difficulty)
    if (filterState.answerStatus !== 'all') parts.push(filterState.answerStatus)
    if (filterState.cbVerifiedInactive) parts.push('CB verified')
    if (filterState.questionLimit) parts.push(`Max ${filterState.questionLimit}`)
    return parts.join(' · ')
  }, [filterState])

  const mainColumn = (
    <div
      className="flex-1 min-w-0 overflow-y-auto studium-screen"
      style={{
        padding: 'var(--space-lg) var(--space-xl)',
        paddingBottom: useWideSplit ? 'var(--space-xl)' : '5.5rem',
      }}
    >
      {savedQuizzes.length > 0 && (
        <section className="mb-6">
          <SectionEyebrow>Continue</SectionEyebrow>
          <div className="mt-3 flex flex-col gap-3 md:hidden">
            {savedQuizzes.slice(0, 5).map(quiz => {
              const answered = Object.values(quiz.answerStates).filter(s => s.hasSubmitted).length
              return (
                <ContinueQuizCard
                  key={quiz.id}
                  fullWidth
                  title={describeFilters(quiz.filters)}
                  answered={answered}
                  total={quiz.questionIds.length}
                  onResume={() => onResumeQuiz(quiz)}
                  onDelete={() => handleDeleteQuiz(quiz.id)}
                />
              )
            })}
          </div>
          <div className="mt-3 hidden md:flex gap-4 overflow-x-auto pb-1">
            {savedQuizzes.slice(0, 5).map(quiz => {
              const answered = Object.values(quiz.answerStates).filter(s => s.hasSubmitted).length
              return (
                <ContinueQuizCard
                  key={quiz.id}
                  title={describeFilters(quiz.filters)}
                  answered={answered}
                  total={quiz.questionIds.length}
                  onResume={() => onResumeQuiz(quiz)}
                  onDelete={() => handleDeleteQuiz(quiz.id)}
                />
              )
            })}
          </div>
        </section>
      )}

      <header className="mb-5">
        <h2 className="studium-page-title m-0">Browse by topic</h2>
        <p className="studium-page-subtitle mt-1 mb-0">
          {conceptCategories.length} topics · {matchingCount} questions
        </p>
      </header>

      {conceptCategories.length === 0 ? (
        <p className="text-center py-16 studium-page-subtitle">No questions match these filters</p>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
          {conceptCategories.map((cat, i) => (
            <ConceptCard
              key={cat.id}
              category={cat}
              accent={CARD_ACCENTS[i % CARD_ACCENTS.length]}
              onPractice={() => handleStart(cat.id)}
              onPracticeSkill={skillId => handleStart(cat.id, skillId)}
            />
          ))}
        </div>
      )}
    </div>
  )

  const startButton = (
    <button
      type="button"
      onClick={() => handleStart()}
      disabled={matchingCount === 0}
      className="studium-btn-primary w-full"
    >
      <Play size={16} aria-hidden="true" />
      Start {matchingCount}
    </button>
  )

  if (useWideSplit) {
    return (
      <div className="flex flex-1 min-h-0 overflow-hidden">
        <aside
          className="shrink-0 flex flex-col border-r studium-screen overflow-hidden"
          style={{ width: PRACTICE_SIDEBAR_WIDTH_PX, borderColor: 'var(--border)' }}
        >
          <div className="px-5 pt-5 pb-3">
            <h2 className="studium-page-title m-0 text-[1.5rem]">Filters</h2>
            <p className="mt-2 m-0 flex items-baseline gap-2">
              <span
                className="studium-stat-digit"
                style={{ color: matchingCount > 0 ? 'var(--accent)' : 'var(--muted)', fontSize: '1.5rem' }}
              >
                {matchingCount}
              </span>
              <span className="studium-page-subtitle">
                {matchingCount === 1 ? 'question matches' : 'questions match'}
              </span>
            </p>
          </div>
          <div className="flex-1 overflow-y-auto px-4 pb-4">
            <PracticeFiltersPanel
              filters={filterState}
              onChange={patchFilters}
              sidebar
            />
          </div>
          <div
            className="shrink-0 p-4 border-t"
            style={{ borderColor: 'var(--border)', background: 'var(--card)' }}
          >
            {startButton}
          </div>
        </aside>
        {mainColumn}
      </div>
    )
  }

  return (
    <div className="flex flex-1 min-h-0 flex-col overflow-hidden relative">
      <div
        className="shrink-0 border-b px-4 py-3 flex items-center gap-3"
        style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
      >
        <div className="flex-1 min-w-0">
          <div className="text-base font-semibold" style={{ color: 'var(--text)' }}>Practice</div>
          <div className="text-sm mt-0.5" style={{ color: 'var(--muted)' }}>
            <span style={{ color: matchingCount > 0 ? 'var(--accent)' : undefined, fontWeight: 600 }}>
              {matchingCount}
            </span>{' '}
            match{matchingCount === 1 ? '' : 'es'}
          </div>
          {filterSummary && (
            <p className="text-xs mt-1 m-0 line-clamp-2" style={{ color: 'var(--muted)' }}>
              {filterSummary}
            </p>
          )}
        </div>
        <button type="button" onClick={() => setShowFilterSheet(true)} className="studium-btn-secondary shrink-0">
          <SlidersHorizontal size={16} aria-hidden="true" />
          Filters
        </button>
      </div>

      {mainColumn}

      <div
        className="md:hidden fixed bottom-[calc(3.25rem+env(safe-area-inset-bottom))] left-0 right-0 z-20 border-t px-4 py-2 flex gap-2"
        style={{ background: 'var(--card)', borderColor: 'var(--border)' }}
      >
        <button type="button" onClick={() => setShowFilterSheet(true)} className="studium-btn-secondary px-3" aria-label="Filters">
          <SlidersHorizontal size={18} aria-hidden="true" />
        </button>
        <div className="flex-1">{startButton}</div>
      </div>

      {showFilterSheet && (
        <div className="fixed inset-0 z-40 flex flex-col md:hidden" role="dialog" aria-modal="true" aria-label="Filters">
          <button
            type="button"
            className="absolute inset-0 bg-black/40 border-0 cursor-pointer"
            aria-label="Close filters"
            onClick={() => setShowFilterSheet(false)}
          />
          <div
            className="relative mt-auto max-h-[92vh] flex flex-col rounded-t-[var(--radius-sheet)] overflow-hidden studium-screen"
            style={{ background: 'var(--bg)' }}
          >
            <div
              className="flex items-center justify-between px-4 py-3 border-b shrink-0"
              style={{ borderColor: 'var(--border)', background: 'var(--card)' }}
            >
              <h2 className="text-lg font-semibold m-0">Filters</h2>
              <button type="button" onClick={() => setShowFilterSheet(false)} className="studium-btn-secondary px-3" aria-label="Done">
                <X size={18} aria-hidden="true" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto px-4 py-4">
              <PracticeFiltersPanel filters={filterState} onChange={patchFilters} />
            </div>
            <div className="shrink-0 p-4 border-t" style={{ borderColor: 'var(--border)', background: 'var(--card)' }}>
              <button
                type="button"
                className="studium-btn-primary w-full"
                onClick={() => {
                  handleStart()
                  setShowFilterSheet(false)
                }}
                disabled={matchingCount === 0}
              >
                Start {matchingCount}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
