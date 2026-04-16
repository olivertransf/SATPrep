import { useState, useMemo } from 'react'
import type {
  Question, QuestionProgress, FilterOptions, SavedQuiz, AnswerStatus,
  CBVerifiedInactiveFilter,
} from '../../types'
import { getFilteredQuestions } from '../../utils/questions'
import { deleteQuiz } from '../../store/quiz'
import {
  Play, Trash2, ChevronDown, ChevronUp,
  Shuffle, ArrowDownUp, RotateCcw,
} from 'lucide-react'

interface PracticeHomeProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
  savedQuizzes: SavedQuiz[]
  cbVerifiedNotOnPracticeTestIds: Set<string>
  onStartQuiz: (filters: FilterOptions) => void
  onResumeQuiz: (quiz: SavedQuiz) => void
  onQuizzesChange: (quizzes: SavedQuiz[]) => void
}

interface ConceptSkill    { id: string; count: number }
interface ConceptCategory { id: string; count: number; skills: ConceptSkill[] }

const DIFFICULTY_LABELS: Record<string, string> = { E: 'Easy', M: 'Medium', H: 'Hard' }

const CARD_ACCENTS = [
  '#007aff', '#0a84ff', '#3f9bff', '#5caeff',
]

function sectionLabel(m: string) {
  const l = m.toLowerCase()
  if (l === 'english') return 'Reading & Writing'
  if (l === 'math')    return 'Math'
  return m.charAt(0).toUpperCase() + m.slice(1)
}

function describeFilters(f: FilterOptions): string {
  const parts: string[] = []
  if (f.module)             parts.push(sectionLabel(f.module))
  if (f.primaryClassCdDesc) parts.push(f.primaryClassCdDesc)
  if (f.skillDesc)          parts.push(f.skillDesc)
  if (f.difficulty)         parts.push(DIFFICULTY_LABELS[f.difficulty] ?? f.difficulty)
  if (f.answerStatus !== 'all') parts.push(f.answerStatus)
  if (f.isBluebook === 'bluebook') parts.push('Practice tests only')
  if (f.isBluebook === 'notBluebook') parts.push('Exclude active')
  if (f.cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests') parts.push('CB verified pool')
  if (f.questionLimit) parts.push(`Max ${f.questionLimit}`)
  return parts.length > 0 ? parts.join(' · ') : 'All Questions'
}

const CB_VERIFIED = {
  group: 'CB verified pool',
  any: 'Any',
  only: 'Verified off practice tests',
  help:
    'Only IDs from an Educator Question Bank export with “Exclude Active Questions” (sidecar JSON).',
} as const

function PillButton({
  label, active, onClick,
}: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="px-2.5 py-1 rounded-full text-[11px] font-semibold border transition-all"
      style={active
        ? { background: 'var(--accent)', color: '#fff', borderColor: 'var(--accent)' }
        : { background: 'transparent', color: 'var(--muted)', borderColor: 'var(--border)' }}
    >
      {label}
    </button>
  )
}

// ─── Concept card ─────────────────────────────────────────────────────────────

interface ConceptCardProps {
  cat: ConceptCategory
  accent: string
  progress: Record<string, QuestionProgress>
  filteredQuestions: Question[]
  expanded: boolean
  onToggle: () => void
  onPractice: (catId: string, skillId?: string) => void
}

function ConceptCard({ cat, accent, progress, filteredQuestions, expanded, onToggle, onPractice }: ConceptCardProps) {
  const catQs   = filteredQuestions.filter(q => q.primaryClassCdDesc === cat.id)
  const answered = catQs.filter(q => progress[q.questionId]?.correct !== undefined).length
  const correct  = catQs.filter(q => progress[q.questionId]?.correct === true).length
  const accuracy = answered > 0 ? Math.round((correct / answered) * 100) : null
  const pct      = cat.count > 0 ? Math.round((answered / cat.count) * 100) : 0

  return (
    <div className="rounded-sm border overflow-hidden"
      style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>

      {/* Accent top stripe */}
      <div className="h-px" style={{ background: accent }} />

      <div className="px-3.5 pt-3 pb-3 space-y-2.5">
        {/* Title + count */}
        <div className="flex items-start justify-between gap-2">
          <span className="text-sm font-medium leading-snug" style={{ color: 'var(--text)' }}>
            {cat.id}
          </span>
          <span className="text-xs tabular-nums shrink-0 pt-0.5" style={{ color: 'var(--muted)' }}>
            {cat.count}
          </span>
        </div>

        {/* Progress bar + stats */}
        <div className="space-y-1">
          <div className="h-1 rounded-full overflow-hidden" style={{ background: 'var(--surface)' }}>
            <div className="h-full rounded-full transition-all duration-500"
              style={{ width: `${pct}%`, background: accent }} />
          </div>
          <div className="flex items-center justify-between text-xs" style={{ color: 'var(--muted)' }}>
            <span>{answered}/{cat.count} done</span>
            {accuracy !== null && (
              <span style={{
                color: accuracy >= 70 ? 'var(--success)'
                  : accuracy >= 50 ? 'var(--warning)'
                  : 'var(--error)',
              }}>
                {accuracy}% acc
              </span>
            )}
          </div>
        </div>

        {/* Buttons */}
        <div className="flex gap-1.5">
          <button
            onClick={() => onPractice(cat.id)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-sm text-xs font-semibold flex-1 justify-center transition-all border"
            style={{ background: 'var(--accent)', borderColor: 'var(--accent)', color: '#fff' }}
          >
            <Play size={11} aria-hidden="true" />
            Practice
          </button>
          <button
            onClick={onToggle}
            className="flex items-center gap-1 px-3 py-1.5 rounded-sm text-xs font-medium border transition-all"
            style={{ borderColor: 'var(--border)', color: 'var(--muted)' }}
          >
            {expanded ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
            {cat.skills.length}
          </button>
        </div>
      </div>

      {/* Skills list */}
      {expanded && (
        <div className="border-t" style={{ borderColor: 'var(--border)' }}>
          {cat.skills.map(s => {
            const sQs  = catQs.filter(q => q.skillDesc === s.id)
            const sAns = sQs.filter(q => progress[q.questionId]?.correct !== undefined).length
            const sCor = sQs.filter(q => progress[q.questionId]?.correct === true).length
            const sAcc = sAns > 0 ? Math.round((sCor / sAns) * 100) : null
            return (
              <div key={s.id}
                className="flex items-center gap-2.5 px-3.5 py-2 border-b last:border-0"
                style={{ borderColor: 'var(--border)' }}>
                <div className="flex-1 min-w-0">
                  <div className="text-xs font-medium leading-snug" style={{ color: 'var(--text)' }}>{s.id}</div>
                  <div className="text-[11px]" style={{ color: 'var(--muted)' }}>
                    {s.count} q
                    {sAcc !== null && (
                      <span style={{
                        color: sAcc >= 70 ? 'var(--success)' : sAcc >= 50 ? 'var(--warning)' : 'var(--error)',
                      }}>
                        {' · '}{sAcc}%
                      </span>
                    )}
                  </div>
                </div>
                <button
                  onClick={() => onPractice(cat.id, s.id)}
                  className="px-2.5 py-1 rounded-sm text-[11px] font-medium border shrink-0 transition-all"
                  style={{ borderColor: 'var(--accent)', color: 'var(--accent)' }}
                >
                  Practice
                </button>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

// ─── Main component ───────────────────────────────────────────────────────────

export default function PracticeHome({
  questions, progress, savedQuizzes, cbVerifiedNotOnPracticeTestIds,
  onStartQuiz, onResumeQuiz, onQuizzesChange,
}: PracticeHomeProps) {
  const [difficulty,   setDifficulty]   = useState<string | undefined>()
  const [answerStatus, setAnswerStatus] = useState<AnswerStatus>('all')
  const [cbVerifiedInactive, setCbVerifiedInactive] = useState<CBVerifiedInactiveFilter | undefined>()
  const [shuffled,     setShuffled]     = useState(true)
  const [questionLimit, setQuestionLimit] = useState<number | undefined>()

  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set())

  const verifiedInBank = useMemo(
    () => questions.filter(q => cbVerifiedNotOnPracticeTestIds.has(q.questionId.toLowerCase())).length,
    [questions, cbVerifiedNotOnPracticeTestIds],
  )

  const currentFilters: FilterOptions = useMemo(() => ({
    module: undefined,
    difficulty,
    primaryClassCdDesc: undefined,
    skillDesc: undefined,
    answerStatus,
    isBluebook: undefined,
    cbVerifiedInactive,
    shuffled: false,
    questionLimit,
  }), [difficulty, answerStatus, cbVerifiedInactive, questionLimit])

  const filteredQuestions = useMemo(
    () => getFilteredQuestions(questions, currentFilters, progress, cbVerifiedNotOnPracticeTestIds),
    [questions, currentFilters, progress, cbVerifiedNotOnPracticeTestIds]
  )

  const matchingCount = filteredQuestions.length

  const stats = useMemo(() => {
    const answered  = filteredQuestions.filter(q => progress[q.questionId]?.correct !== undefined).length
    const correct   = filteredQuestions.filter(q => progress[q.questionId]?.correct === true).length
    const remaining = filteredQuestions.filter(q => !progress[q.questionId]?.seen).length
    const accuracy  = answered > 0 ? Math.round((correct / answered) * 100) : null
    return { answered, correct, remaining, accuracy }
  }, [filteredQuestions, progress])

  const conceptCategories: ConceptCategory[] = useMemo(() => {
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
      shuffled,
      ...(catId ? { primaryClassCdDesc: catId } : {}),
      ...(skillId ? { skillDesc: skillId } : {}),
    })
  }

  function handleDeleteQuiz(id: string) {
    deleteQuiz(id)
    onQuizzesChange(savedQuizzes.filter(q => q.id !== id))
  }

  function toggleCategory(id: string) {
    setExpandedCategories(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }

  function resetAllFilters() {
    setDifficulty(undefined)
    setAnswerStatus('all')
    setCbVerifiedInactive(undefined)
    setShuffled(true)
    setQuestionLimit(undefined)
  }

  // Accuracy color
  const accuracyColor = stats.accuracy === null ? 'var(--muted)'
    : stats.accuracy >= 75 ? 'var(--success)'
    : stats.accuracy >= 50 ? 'var(--warning)'
    : 'var(--error)'

  return (
    <div className="flex-1 overflow-y-auto" style={{ background: 'var(--bg)' }}>

      {/* Filters — in document flow (scrolls with content) */}
      <div className="border-b" style={{ borderColor: 'var(--border)' }}>
        <div className="max-w-6xl mx-auto px-3 sm:px-4 lg:px-5 py-2.5 w-full min-w-0">
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_auto] gap-3 items-start">
            <div className="space-y-2">
              <div>
                <h1 className="text-sm font-semibold" style={{ color: 'var(--text)' }}>Practice questions</h1>
                <p className="text-[11px] mt-0.5" style={{ color: 'var(--muted)' }}>
                  Filter quickly, then start. Topic-level practice is available below.
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-1.5">
                <span className="text-[10px] font-semibold uppercase tracking-wide mr-1" style={{ color: 'var(--muted)' }}>
                  Difficulty
                </span>
                <PillButton label="All" active={!difficulty} onClick={() => setDifficulty(undefined)} />
                {Object.entries(DIFFICULTY_LABELS).map(([value, label]) => (
                  <PillButton key={value} label={label} active={difficulty === value} onClick={() => setDifficulty(value)} />
                ))}
              </div>

              <div className="flex flex-wrap items-center gap-1.5">
                <span className="text-[10px] font-semibold uppercase tracking-wide mr-1" style={{ color: 'var(--muted)' }}>
                  Status
                </span>
                <PillButton label="All" active={answerStatus === 'all'} onClick={() => setAnswerStatus('all')} />
                <PillButton label="New" active={answerStatus === 'unanswered'} onClick={() => setAnswerStatus('unanswered')} />
                <PillButton label="Wrong" active={answerStatus === 'incorrect'} onClick={() => setAnswerStatus('incorrect')} />
                <PillButton label="Correct" active={answerStatus === 'correct'} onClick={() => setAnswerStatus('correct')} />
              </div>

              <div className="flex flex-wrap items-center gap-1.5">
                <span className="text-[10px] font-semibold uppercase tracking-wide mr-1" style={{ color: 'var(--muted)' }}>
                  {CB_VERIFIED.group}
                </span>
                <PillButton
                  label={CB_VERIFIED.any}
                  active={!cbVerifiedInactive}
                  onClick={() => setCbVerifiedInactive(undefined)}
                />
                <PillButton
                  label={CB_VERIFIED.only}
                  active={cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests'}
                  onClick={() => setCbVerifiedInactive(
                    cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests' ? undefined : 'onlyVerifiedOffCBPracticeTests',
                  )}
                />
              </div>

              <div className="flex flex-wrap items-center gap-1.5">
                <span className="text-[10px] font-semibold uppercase tracking-wide mr-1" style={{ color: 'var(--muted)' }}>
                  Question count
                </span>
                <PillButton label="No limit" active={!questionLimit} onClick={() => setQuestionLimit(undefined)} />
                {[10, 20, 30, 50].map(n => (
                  <PillButton key={n} label={String(n)} active={questionLimit === n} onClick={() => setQuestionLimit(n)} />
                ))}
              </div>
            </div>

            <div className="w-full lg:w-[250px] rounded-sm border p-2 space-y-2" style={{ borderColor: 'var(--border)', background: 'var(--surface)' }}>
              <button
                type="button"
                onClick={() => handleStart()}
                disabled={matchingCount === 0}
                className="w-full flex items-center justify-center gap-2 min-h-[2.2rem] px-3 rounded-sm text-xs font-semibold border transition-all disabled:opacity-40"
                style={{ background: 'var(--accent)', borderColor: 'var(--accent)', color: '#fff' }}
              >
                <Play size={13} aria-hidden="true" />
                Start
                <span className="tabular-nums opacity-80">({matchingCount})</span>
              </button>

              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={resetAllFilters}
                  className="flex items-center justify-center gap-1.5 min-h-[2.1rem] px-2.5 rounded-sm text-[11px] font-semibold border transition-all"
                  style={{ borderColor: 'var(--border)', color: 'var(--muted)' }}
                >
                  <RotateCcw size={12} />
                  Reset
                </button>
                <button
                  type="button"
                  onClick={() => setShuffled(s => !s)}
                  title={shuffled ? 'Random order' : 'Sequential order'}
                  className="flex items-center justify-center gap-1.5 min-h-[2.1rem] px-2.5 rounded-sm text-[11px] font-semibold border transition-all"
                  style={{ borderColor: 'var(--border)', color: 'var(--muted)' }}
                >
                  {shuffled ? <Shuffle size={12} /> : <ArrowDownUp size={12} />}
                  {shuffled ? 'Random' : 'In order'}
                </button>
              </div>

              <div className="text-[11px] space-y-1" style={{ color: 'var(--muted)' }}>
                {stats.accuracy !== null && (
                  <div>
                    Accuracy <span className="font-semibold" style={{ color: accuracyColor }}>{stats.accuracy}%</span>
                  </div>
                )}
                <div>
                  Answered <span className="font-semibold" style={{ color: 'var(--text)' }}>{stats.answered}</span> · Remaining{' '}
                  <span className="font-semibold" style={{ color: 'var(--text)' }}>{stats.remaining}</span>
                </div>
                <div className="h-1 rounded-full overflow-hidden" style={{ background: 'var(--bg)' }}>
                  <div
                    className="h-full transition-all"
                    style={{
                      width: `${matchingCount > 0 ? Math.round((stats.answered / matchingCount) * 100) : 0}%`,
                      background: 'var(--accent)',
                    }}
                  />
                </div>
                <div className="text-[10px]">Sidecar: {cbVerifiedNotOnPracticeTestIds.size} IDs · {verifiedInBank} in bank</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ═══ CONTENT ═══ */}
      <div className="max-w-6xl mx-auto px-3 sm:px-4 lg:px-5 py-4 space-y-4">

        {/* Saved quizzes */}
        {savedQuizzes.length > 0 && (
          <div className="space-y-2.5">
            <div className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>
              Continue where you left off
            </div>
            <div className="flex gap-2.5 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
              {savedQuizzes.map(quiz => {
                const answered = Object.values(quiz.answerStates).filter(s => s.hasSubmitted).length
                const correct  = Object.values(quiz.answerStates).filter(s => s.isCorrect).length
                const pct = quiz.questionIds.length > 0 ? (answered / quiz.questionIds.length) * 100 : 0
                return (
                  <div key={quiz.id}
                    className="rounded-sm border shrink-0 w-56 overflow-hidden"
                    style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
                    <div className="h-px" style={{ background: 'var(--surface)' }}>
                      <div className="h-full transition-all"
                        style={{ width: `${pct}%`, background: pct >= 100 ? 'var(--success)' : 'var(--accent)' }} />
                    </div>
                    <div className="p-3 space-y-2">
                      <div className="text-xs leading-snug line-clamp-2" style={{ color: 'var(--text)' }}>
                        {describeFilters(quiz.filters)}
                      </div>
                      <div className="text-[11px]" style={{ color: 'var(--muted)' }}>
                        {answered}/{quiz.questionIds.length} answered
                        {answered > 0 && (
                          <span style={{ color: 'var(--success)' }}> · {correct} ✓</span>
                        )}
                      </div>
                      <div className="flex gap-1.5">
                        <button onClick={() => onResumeQuiz(quiz)}
                          className="flex-1 py-1.5 rounded-sm text-xs font-semibold"
                          style={{ background: 'var(--accent)', color: '#fff' }}>
                          Resume
                        </button>
                        <button onClick={() => handleDeleteQuiz(quiz.id)}
                          className="px-2 py-1.5 rounded-sm border"
                          style={{ borderColor: 'var(--border)', color: 'var(--error)' }}
                          aria-label="Delete quiz">
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        )}

        {/* Concept grid */}
        <div className="space-y-2.5">
          <div className="flex items-baseline justify-between">
            <h2 className="text-sm font-semibold" style={{ color: 'var(--text)' }}>
              Browse by Topic
            </h2>
            <span className="text-xs" style={{ color: 'var(--muted)' }}>
              {conceptCategories.length} topics · {matchingCount} questions
            </span>
          </div>

          {conceptCategories.length === 0 ? (
            <div className="text-center py-12 text-sm" style={{ color: 'var(--muted)' }}>
              No questions match these filters
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-2.5">
              {conceptCategories.map((cat, i) => (
                <ConceptCard
                  key={cat.id}
                  cat={cat}
                  accent={CARD_ACCENTS[i % CARD_ACCENTS.length]}
                  progress={progress}
                  filteredQuestions={filteredQuestions}
                  expanded={expandedCategories.has(cat.id)}
                  onToggle={() => toggleCategory(cat.id)}
                  onPractice={handleStart}
                />
              ))}
            </div>
          )}
        </div>
      </div>

    </div>
  )
}
