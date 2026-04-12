import { useState, useMemo } from 'react'
import type {
  Question, QuestionProgress, FilterOptions, SavedQuiz, AnswerStatus,
  BluebookFilter, CBVerifiedInactiveFilter,
} from '../../types'
import {
  getFilteredQuestions, getAvailableModules, getAvailablePrimaryClasses, getAvailableSkills,
} from '../../utils/questions'
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
const DIFFICULTY_COLORS: Record<string, string> = { E: '#16a34a', M: '#ea580c', H: '#dc2626' }

const CARD_ACCENTS = [
  '#6366f1','#3b82f6','#8b5cf6','#ec4899',
  '#14b8a6','#f97316','#16a34a','#ef4444',
  '#eab308','#06b6d4','#a855f7','#84cc16',
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

const PRACTICE_TESTS = {
  group: 'Practice tests',
  all: 'All',
  only: 'Practice tests only',
  excludeActive: 'Exclude active',
  help:
    '“Exclude active” matches the Question Bank option to hide questions already used on full-length practice tests (when this bank tags them).',
} as const

const CB_VERIFIED = {
  group: 'CB verified pool',
  any: 'Any',
  only: 'Verified off practice tests',
  help:
    'Only IDs from an Educator Question Bank export with “Exclude Active Questions” (sidecar JSON).',
} as const

// ─── Small filter chip ────────────────────────────────────────────────────────

function Chip({
  label, selected, color, onClick,
}: { label: string; selected: boolean; color?: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="px-3 py-1.5 rounded-lg border text-sm font-medium transition-all whitespace-nowrap"
      style={selected
        ? { background: color ?? 'var(--accent)', color: '#fff', borderColor: color ?? 'var(--accent)' }
        : { background: 'var(--card)', color: 'var(--muted)', borderColor: 'var(--border)' }
      }
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
    <div className="rounded-xl border overflow-hidden"
      style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>

      {/* Accent top stripe */}
      <div className="h-0.5" style={{ background: accent }} />

      <div className="px-4 pt-3 pb-3 space-y-3">
        {/* Title + count */}
        <div className="flex items-start justify-between gap-2">
          <span className="text-sm font-semibold leading-snug" style={{ color: 'var(--text)' }}>
            {cat.id}
          </span>
          <span className="text-xs tabular-nums shrink-0 pt-0.5" style={{ color: 'var(--muted)' }}>
            {cat.count}
          </span>
        </div>

        {/* Progress bar + stats */}
        <div className="space-y-1">
          <div className="h-1.5 rounded-full overflow-hidden" style={{ background: 'var(--surface)' }}>
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
        <div className="flex gap-2">
          <button
            onClick={() => onPractice(cat.id)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold flex-1 justify-center transition-all"
            style={{ background: accent, color: '#fff' }}
          >
            <Play size={11} aria-hidden="true" />
            Practice
          </button>
          <button
            onClick={onToggle}
            className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-medium border transition-all"
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
                className="flex items-center gap-3 px-4 py-2.5 border-b last:border-0"
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
                  className="px-2.5 py-1 rounded-md text-[11px] font-medium border shrink-0 transition-all"
                  style={{ borderColor: accent, color: accent }}
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
  const [module,       setModule]       = useState<string | undefined>()
  const [primaryClass, setPrimaryClass] = useState<string | undefined>()
  const [skillDesc,    setSkillDesc]    = useState<string | undefined>()
  const [difficulty,   setDifficulty]   = useState<string | undefined>()
  const [answerStatus, setAnswerStatus] = useState<AnswerStatus>('all')
  const [isBluebook,   setIsBluebook]   = useState<BluebookFilter | undefined>()
  const [cbVerifiedInactive, setCbVerifiedInactive] = useState<CBVerifiedInactiveFilter | undefined>()
  const [shuffled,     setShuffled]     = useState(true)
  const [useLimit,     setUseLimit]     = useState(false)
  const [questionLimit, setQuestionLimit] = useState<number | undefined>()

  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set())

  const modules = getAvailableModules(questions)
  const classes = useMemo(() => getAvailablePrimaryClasses(questions, module), [questions, module])
  const skills    = useMemo(() => getAvailableSkills(questions, module, primaryClass), [questions, module, primaryClass])
  const verifiedInBank = useMemo(
    () => questions.filter(q => cbVerifiedNotOnPracticeTestIds.has(q.questionId.toLowerCase())).length,
    [questions, cbVerifiedNotOnPracticeTestIds],
  )

  const currentFilters: FilterOptions = useMemo(() => ({
    module,
    difficulty,
    primaryClassCdDesc: primaryClass,
    skillDesc,
    answerStatus,
    isBluebook,
    cbVerifiedInactive,
    shuffled: false,
    questionLimit: useLimit ? questionLimit : undefined,
  }), [module, difficulty, primaryClass, skillDesc, answerStatus, isBluebook, cbVerifiedInactive, useLimit, questionLimit])

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

  function setModuleAndClearDomain(m: string | undefined) {
    setModule(m)
    setPrimaryClass(undefined)
    setSkillDesc(undefined)
  }

  function resetAllFilters() {
    setModule(undefined)
    setPrimaryClass(undefined)
    setSkillDesc(undefined)
    setDifficulty(undefined)
    setAnswerStatus('all')
    setIsBluebook(undefined)
    setCbVerifiedInactive(undefined)
    setShuffled(true)
    setUseLimit(false)
    setQuestionLimit(undefined)
  }

  // Accuracy color
  const accuracyColor = stats.accuracy === null ? 'var(--muted)'
    : stats.accuracy >= 75 ? 'var(--success)'
    : stats.accuracy >= 50 ? 'var(--warning)'
    : 'var(--error)'

  return (
    <div className="flex-1 overflow-y-auto" style={{ background: 'var(--bg)' }}>

      {/* ═══ FILTER BAR ═══ */}
      <div className="sticky top-0 z-10 border-b"
        style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
        <div className="px-4 lg:px-6 py-3 space-y-2.5">

          {/* Row 1: section + difficulty + status + actions */}
          <div className="flex items-center gap-2 flex-wrap">
            {/* Section */}
            <div className="flex gap-1">
              <Chip label="All" selected={!module} onClick={() => setModuleAndClearDomain(undefined)} />
              {modules.map(m => (
                <Chip key={m} label={sectionLabel(m)} selected={module === m}
                  onClick={() => setModuleAndClearDomain(module === m ? undefined : m)} />
              ))}
            </div>

            <div className="w-px h-5 shrink-0 hidden sm:block" style={{ background: 'var(--border)' }} />

            {/* Difficulty */}
            <div className="flex gap-1">
              <Chip label="All" selected={!difficulty} onClick={() => setDifficulty(undefined)} />
              {Object.entries(DIFFICULTY_LABELS).map(([k, label]) => (
                <Chip key={k} label={label} selected={difficulty === k} color={DIFFICULTY_COLORS[k]}
                  onClick={() => setDifficulty(difficulty === k ? undefined : k)} />
              ))}
            </div>

            <div className="w-px h-5 shrink-0 hidden sm:block" style={{ background: 'var(--border)' }} />

            {/* Status */}
            <div className="flex gap-1">
              {([
                { value: 'all',        label: 'All'     },
                { value: 'unanswered', label: 'New'     },
                { value: 'incorrect',  label: 'Wrong'   },
                { value: 'correct',    label: 'Correct' },
              ] as const).map(opt => (
                <Chip key={opt.value} label={opt.label} selected={answerStatus === opt.value}
                  onClick={() => setAnswerStatus(opt.value)} />
              ))}
            </div>

            {/* Push right */}
            <div className="flex-1" />

            {/* Shuffle toggle */}
            <button
              onClick={() => setShuffled(s => !s)}
              title={shuffled ? 'Random order (click for sequential)' : 'Sequential order (click for random)'}
              className="p-2 rounded-lg border transition-all"
              style={shuffled
                ? { background: 'var(--accent)', borderColor: 'var(--accent)', color: '#fff' }
                : { background: 'var(--card)', borderColor: 'var(--border)', color: 'var(--muted)' }
              }
            >
              {shuffled ? <Shuffle size={15} /> : <ArrowDownUp size={15} />}
            </button>

            {/* Start quiz */}
            <button
              onClick={() => handleStart()}
              disabled={matchingCount === 0}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all disabled:opacity-40"
              style={{ background: 'var(--accent)', color: '#fff' }}
            >
              <Play size={14} aria-hidden="true" />
              Start
              <span className="tabular-nums opacity-80 text-xs">({matchingCount})</span>
            </button>
          </div>

          {module && (
            <div className="space-y-1.5 pt-1 border-t" style={{ borderColor: 'var(--border)' }}>
              <div className="text-[11px] font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>Domain</div>
              <div className="flex flex-wrap gap-1">
                <Chip label="All" selected={!primaryClass}
                  onClick={() => { setPrimaryClass(undefined); setSkillDesc(undefined) }} />
                {classes.map(c => (
                  <Chip key={c} label={c} selected={primaryClass === c}
                    onClick={() => {
                      setPrimaryClass(primaryClass === c ? undefined : c)
                      setSkillDesc(undefined)
                    }} />
                ))}
              </div>
            </div>
          )}

          {module && primaryClass && (
            <div className="space-y-1.5">
              <div className="text-[11px] font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>Skill</div>
              <div className="flex flex-wrap gap-1">
                <Chip label="All" selected={!skillDesc} onClick={() => setSkillDesc(undefined)} />
                {skills.map(s => (
                  <Chip key={s} label={s} selected={skillDesc === s}
                    onClick={() => setSkillDesc(skillDesc === s ? undefined : s)} />
                ))}
              </div>
            </div>
          )}

          <div className="space-y-1.5 pt-2 border-t" style={{ borderColor: 'var(--border)' }}>
            <div className="text-[11px] font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>{PRACTICE_TESTS.group}</div>
            <div className="flex flex-wrap gap-1">
              <Chip label={PRACTICE_TESTS.all} selected={!isBluebook} onClick={() => setIsBluebook(undefined)} />
              <Chip label={PRACTICE_TESTS.only} selected={isBluebook === 'bluebook'}
                onClick={() => setIsBluebook(isBluebook === 'bluebook' ? undefined : 'bluebook')} />
              <Chip label={PRACTICE_TESTS.excludeActive} selected={isBluebook === 'notBluebook'}
                onClick={() => setIsBluebook(isBluebook === 'notBluebook' ? undefined : 'notBluebook')} />
            </div>
            <p className="text-[11px] leading-snug" style={{ color: 'var(--muted)' }}>{PRACTICE_TESTS.help}</p>
          </div>

          <div className="space-y-1.5">
            <div className="text-[11px] font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>{CB_VERIFIED.group}</div>
            <div className="flex flex-wrap gap-1">
              <Chip label={CB_VERIFIED.any} selected={!cbVerifiedInactive} onClick={() => setCbVerifiedInactive(undefined)} />
              <Chip label={CB_VERIFIED.only} selected={cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests'}
                onClick={() => setCbVerifiedInactive(
                  cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests' ? undefined : 'onlyVerifiedOffCBPracticeTests',
                )} />
            </div>
            <p className="text-[11px] leading-snug" style={{ color: 'var(--muted)' }}>{CB_VERIFIED.help}</p>
            <p className="text-[11px] leading-snug" style={{ color: 'var(--muted)' }}>
              Sidecar: {cbVerifiedNotOnPracticeTestIds.size} IDs · {verifiedInBank} in this bank
            </p>
          </div>

          <div className="space-y-2 rounded-xl border p-3" style={{ background: 'var(--input)', borderColor: 'var(--border)' }}>
            <div className="flex items-center justify-between gap-3">
              <span className="text-xs font-semibold" style={{ color: 'var(--text)' }}>Limit question count</span>
              <button type="button" onClick={() => setUseLimit(u => !u)}
                className="relative w-11 h-6 rounded-full shrink-0 transition-colors"
                style={{ background: useLimit ? 'var(--accent)' : 'var(--border)' }}
                aria-pressed={useLimit}>
                <span className="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform"
                  style={{ transform: useLimit ? 'translateX(20px)' : 'translateX(0)' }} />
              </button>
            </div>
            {useLimit && (
              <div className="flex flex-wrap gap-1">
                {[10, 20, 30, 50].map(n => (
                  <Chip key={n} label={String(n)} selected={questionLimit === n}
                    onClick={() => setQuestionLimit(questionLimit === n ? undefined : n)} />
                ))}
              </div>
            )}
          </div>

          <button type="button" onClick={resetAllFilters}
            className="flex items-center justify-center gap-2 py-2 text-xs font-medium rounded-lg border transition-all w-full sm:w-auto"
            style={{ color: 'var(--muted)', borderColor: 'var(--border)' }}>
            <RotateCcw size={13} />
            Reset all filters
          </button>

          {/* Row: live stats strip */}
          <div className="flex items-center gap-4 text-xs pt-1 border-t" style={{ color: 'var(--muted)', borderColor: 'var(--border)' }}>
            {stats.accuracy !== null && (
              <span>
                Accuracy{' '}
                <span className="font-semibold" style={{ color: accuracyColor }}>
                  {stats.accuracy}%
                </span>
              </span>
            )}
            <span>
              Answered{' '}
              <span className="font-semibold" style={{ color: 'var(--text)' }}>{stats.answered}</span>
            </span>
            <span>
              Remaining{' '}
              <span className="font-semibold" style={{ color: 'var(--text)' }}>{stats.remaining}</span>
            </span>
            {stats.answered > 0 && (
              <>
                <div className="flex-1 hidden md:block h-1.5 rounded-full overflow-hidden max-w-[200px]"
                  style={{ background: 'var(--surface)' }}>
                  <div className="h-full rounded-full transition-all"
                    style={{
                      width: `${matchingCount > 0 ? Math.round((stats.answered / matchingCount) * 100) : 0}%`,
                      background: 'var(--accent)',
                    }} />
                </div>
                <span className="hidden md:inline">
                  {matchingCount > 0 ? Math.round((stats.answered / matchingCount) * 100) : 0}%
                </span>
              </>
            )}
          </div>
        </div>
      </div>

      {/* ═══ CONTENT ═══ */}
      <div className="px-4 lg:px-6 py-5 space-y-6">

        {/* Saved quizzes */}
        {savedQuizzes.length > 0 && (
          <div className="space-y-3">
            <div className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>
              Continue
            </div>
            <div className="flex gap-3 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
              {savedQuizzes.map(quiz => {
                const answered = Object.values(quiz.answerStates).filter(s => s.hasSubmitted).length
                const correct  = Object.values(quiz.answerStates).filter(s => s.isCorrect).length
                const pct = quiz.questionIds.length > 0 ? (answered / quiz.questionIds.length) * 100 : 0
                return (
                  <div key={quiz.id}
                    className="rounded-xl border shrink-0 w-56 overflow-hidden"
                    style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
                    <div className="h-0.5" style={{ background: 'var(--surface)' }}>
                      <div className="h-full transition-all"
                        style={{ width: `${pct}%`, background: pct >= 100 ? 'var(--success)' : 'var(--accent)' }} />
                    </div>
                    <div className="p-3 space-y-2">
                      <div className="text-xs font-medium leading-snug line-clamp-2" style={{ color: 'var(--text)' }}>
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
                          className="flex-1 py-1.5 rounded-lg text-xs font-semibold"
                          style={{ background: 'var(--accent)', color: '#fff' }}>
                          Resume
                        </button>
                        <button onClick={() => handleDeleteQuiz(quiz.id)}
                          className="px-2 py-1.5 rounded-lg border"
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
        <div className="space-y-3">
          <div className="flex items-baseline justify-between">
            <h2 className="text-sm font-semibold" style={{ color: 'var(--text)' }}>
              Browse by Topic
            </h2>
            <span className="text-xs" style={{ color: 'var(--muted)' }}>
              {conceptCategories.length} topics · {matchingCount} questions
            </span>
          </div>

          {conceptCategories.length === 0 ? (
            <div className="text-center py-16 text-sm" style={{ color: 'var(--muted)' }}>
              No questions match these filters
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
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
