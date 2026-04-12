import { useState } from 'react'
import type {
  FilterOptions,
  AnswerStatus,
  BluebookFilter,
  CBVerifiedInactiveFilter,
  Question,
  QuestionProgress,
} from '../../types'
import {
  getAvailableModules,
  getAvailablePrimaryClasses,
  getAvailableSkills,
  getFilteredQuestions,
} from '../../utils/questions'
import { X, RotateCcw } from 'lucide-react'

interface FilterPanelProps {
  questions: Question[]
  progress: Record<string, QuestionProgress>
  cbVerifiedNotOnPracticeTestIds: Set<string>
  onStart: (filters: FilterOptions) => void
  onClose: () => void
}

const DIFFICULTY_LABELS: Record<string, string> = {
  E: 'Easy', M: 'Medium', H: 'Hard',
}

/** College Board Question Bank: section names (JSON uses `english` for R&W). */
function sectionChipTitle(module: string): string {
  const m = module.toLowerCase()
  if (m === 'english') return 'Reading & Writing'
  if (m === 'math') return 'Math'
  return m.charAt(0).toUpperCase() + m.slice(1)
}

const PRACTICE_TESTS = {
  group: 'Practice tests',
  all: 'All',
  only: 'Practice tests only',
  excludeActive: 'Exclude active',
  help:
    '“Exclude active” matches the Question Bank checkbox: hide questions already used on full-length practice tests, when this bank tags them (item booklet id).',
} as const

const CB_VERIFIED = {
  group: 'CB verified pool',
  any: 'Any',
  only: 'Verified off practice tests',
  help:
    'Only IDs from an Educator Question Bank HTML export with “Exclude Active Questions” on (sidecar JSON).',
} as const

const ANSWER_STATUS_OPTIONS: { value: AnswerStatus; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'unanswered', label: 'New' },
  { value: 'incorrect', label: 'Wrong' },
  { value: 'correct', label: 'Correct' },
]

function Chip({
  label,
  selected,
  onClick,
}: {
  label: string
  selected: boolean
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      className="px-3 py-1.5 rounded-lg border text-sm font-medium transition-all"
      style={selected
        ? { background: 'var(--accent)', color: '#fff', borderColor: 'var(--accent)' }
        : { background: 'var(--input)', color: 'var(--muted)', borderColor: 'var(--border)' }
      }
    >
      {label}
    </button>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="space-y-2.5">
      <div className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--muted)' }}>
        {title}
      </div>
      {children}
    </div>
  )
}

export default function FilterPanel({ questions, progress, cbVerifiedNotOnPracticeTestIds, onStart, onClose }: FilterPanelProps) {
  const [module, setModule] = useState<string | undefined>()
  const [primaryClass, setPrimaryClass] = useState<string | undefined>()
  const [skillDesc, setSkillDesc] = useState<string | undefined>()
  const [difficulty, setDifficulty] = useState<string | undefined>()
  const [answerStatus, setAnswerStatus] = useState<AnswerStatus>('all')
  const [isBluebook, setIsBluebook] = useState<BluebookFilter | undefined>()
  const [cbVerifiedInactive, setCbVerifiedInactive] = useState<CBVerifiedInactiveFilter | undefined>()
  const [shuffled, setShuffled] = useState(true)
  const [useLimit, setUseLimit] = useState(false)
  const [limit, setLimit] = useState<number | undefined>()

  const previewFilters: FilterOptions = {
    module, difficulty, primaryClassCdDesc: primaryClass, skillDesc,
    answerStatus, isBluebook, cbVerifiedInactive, shuffled: false, questionLimit: undefined,
  }
  const verifiedInBank = questions.filter(q => cbVerifiedNotOnPracticeTestIds.has(q.questionId.toLowerCase())).length
  const matchingCount = getFilteredQuestions(questions, previewFilters, progress, cbVerifiedNotOnPracticeTestIds).length
  const effectiveCount = useLimit && limit ? Math.min(limit, matchingCount) : matchingCount

  const modules = getAvailableModules(questions)
  const programs = [...new Set(questions.map((q) => q.program))].sort()
  const classes = getAvailablePrimaryClasses(questions, module)
  const skills = getAvailableSkills(questions, module, primaryClass)

  function handleStart() {
    onStart({
      module, difficulty, primaryClassCdDesc: primaryClass, skillDesc,
      answerStatus, isBluebook, cbVerifiedInactive, shuffled,
      questionLimit: useLimit ? limit : undefined,
    })
  }

  function clearAll() {
    setModule(undefined); setPrimaryClass(undefined); setSkillDesc(undefined)
    setDifficulty(undefined); setAnswerStatus('all'); setIsBluebook(undefined)
    setCbVerifiedInactive(undefined)
    setShuffled(true); setUseLimit(false); setLimit(undefined)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center"
      style={{ background: 'rgba(0,0,0,0.6)' }}>
      <div className="w-full sm:max-w-lg max-h-[95vh] sm:rounded-2xl rounded-t-2xl overflow-hidden flex flex-col shadow-2xl border"
        style={{ background: 'var(--bg)', borderColor: 'var(--border)' }}>

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b"
          style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
          <button onClick={onClose} className="p-1.5 rounded-lg transition-colors"
            style={{ color: 'var(--muted)' }}>
            <X size={18} />
          </button>
          <h2 className="text-base font-semibold" style={{ color: 'var(--text)' }}>Filter Questions</h2>
          <button
            onClick={handleStart}
            disabled={matchingCount === 0}
            className="px-4 py-1.5 rounded-lg text-sm font-semibold transition-all disabled:opacity-40"
            style={{ background: 'var(--accent)', color: '#fff' }}
          >
            Start ({effectiveCount})
          </button>
        </div>

        <div className="overflow-y-auto flex-1 p-5 space-y-6">
          {programs.length === 1 && (
            <Section title="Assessment">
              <span className="text-sm font-medium" style={{ color: 'var(--text)' }}>{programs[0]}</span>
            </Section>
          )}
          {/* Section (CB Question Bank wording) */}
          <Section title="Section">
            <div className="flex flex-wrap gap-2">
              <Chip label="All" selected={!module} onClick={() => { setModule(undefined); setPrimaryClass(undefined); setSkillDesc(undefined) }} />
              {modules.map(m => (
                <Chip key={m} label={sectionChipTitle(m)} selected={module === m}
                  onClick={() => { setModule(module === m ? undefined : m); setPrimaryClass(undefined); setSkillDesc(undefined) }} />
              ))}
            </div>
            {module && (
              <div className="space-y-2 pl-0.5 border-l-2 pl-3" style={{ borderColor: 'var(--accent)' }}>
                <div className="text-xs font-medium" style={{ color: 'var(--muted)' }}>Domain</div>
                <div className="flex flex-wrap gap-2">
                  <Chip label="All" selected={!primaryClass} onClick={() => { setPrimaryClass(undefined); setSkillDesc(undefined) }} />
                  {classes.map(c => (
                    <Chip key={c} label={c} selected={primaryClass === c}
                      onClick={() => { setPrimaryClass(primaryClass === c ? undefined : c); setSkillDesc(undefined) }} />
                  ))}
                </div>
                {primaryClass && (
                  <div className="space-y-2">
                    <div className="text-xs font-medium" style={{ color: 'var(--muted)' }}>Skill</div>
                    <div className="flex flex-wrap gap-2">
                      <Chip label="All" selected={!skillDesc} onClick={() => setSkillDesc(undefined)} />
                      {skills.map(s => (
                        <Chip key={s} label={s} selected={skillDesc === s}
                          onClick={() => setSkillDesc(skillDesc === s ? undefined : s)} />
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </Section>

          {/* Difficulty */}
          <Section title="Difficulty">
            <div className="flex flex-wrap gap-2">
              <Chip label="All" selected={!difficulty} onClick={() => setDifficulty(undefined)} />
              {Object.entries(DIFFICULTY_LABELS).map(([key, label]) => (
                <Chip key={key} label={label} selected={difficulty === key}
                  onClick={() => setDifficulty(difficulty === key ? undefined : key)} />
              ))}
            </div>
          </Section>

          {/* Answer Status */}
          <Section title="Status">
            <div className="flex flex-wrap gap-2">
              {ANSWER_STATUS_OPTIONS.map(opt => (
                <Chip key={opt.value} label={opt.label} selected={answerStatus === opt.value}
                  onClick={() => setAnswerStatus(opt.value)} />
              ))}
            </div>
          </Section>

          <Section title={PRACTICE_TESTS.group}>
            <div className="flex flex-wrap gap-2">
              <Chip label={PRACTICE_TESTS.all} selected={!isBluebook} onClick={() => setIsBluebook(undefined)} />
              <Chip label={PRACTICE_TESTS.only} selected={isBluebook === 'bluebook'}
                onClick={() => setIsBluebook(isBluebook === 'bluebook' ? undefined : 'bluebook')} />
              <Chip label={PRACTICE_TESTS.excludeActive} selected={isBluebook === 'notBluebook'}
                onClick={() => setIsBluebook(isBluebook === 'notBluebook' ? undefined : 'notBluebook')} />
            </div>
            <p className="text-xs leading-snug" style={{ color: 'var(--muted)' }}>{PRACTICE_TESTS.help}</p>
          </Section>

          <Section title={CB_VERIFIED.group}>
            <div className="flex flex-wrap gap-2">
              <Chip label={CB_VERIFIED.any} selected={!cbVerifiedInactive} onClick={() => setCbVerifiedInactive(undefined)} />
              <Chip label={CB_VERIFIED.only} selected={cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests'}
                onClick={() => setCbVerifiedInactive(
                  cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests' ? undefined : 'onlyVerifiedOffCBPracticeTests',
                )} />
            </div>
            <p className="text-xs leading-snug" style={{ color: 'var(--muted)' }}>{CB_VERIFIED.help}</p>
            <p className="text-xs leading-snug" style={{ color: 'var(--muted)' }}>
              Sidecar: {cbVerifiedNotOnPracticeTestIds.size} IDs · {verifiedInBank} in this bank
            </p>
          </Section>

          {/* Quiz Options */}
          <Section title="Options">
            <div className="rounded-xl border p-4 space-y-4" style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
              <div>
                <div className="text-xs font-medium mb-2" style={{ color: 'var(--muted)' }}>Question Order</div>
                <div className="flex gap-2">
                  {[
                    { val: false, label: 'In Order' },
                    { val: true, label: 'Random' },
                  ].map(({ val, label }) => (
                    <button key={label} onClick={() => setShuffled(val)}
                      className="flex-1 py-2 rounded-lg border text-sm font-medium transition-all"
                      style={shuffled === val
                        ? { background: 'var(--accent)', color: '#fff', borderColor: 'var(--accent)' }
                        : { background: 'var(--input)', color: 'var(--muted)', borderColor: 'var(--border)' }
                      }>
                      {label}
                    </button>
                  ))}
                </div>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm" style={{ color: 'var(--text)' }}>Limit Questions</span>
                <button onClick={() => setUseLimit(!useLimit)}
                  className="relative w-11 h-6 rounded-full transition-colors"
                  style={{ background: useLimit ? 'var(--accent)' : 'var(--border)' }}>
                  <span className="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform"
                    style={{ transform: useLimit ? 'translateX(20px)' : 'translateX(0)' }} />
                </button>
              </div>
              {useLimit && (
                <div className="flex gap-2">
                  {[10, 20, 30, 50].map(n => (
                    <Chip key={n} label={String(n)} selected={limit === n} onClick={() => setLimit(limit === n ? undefined : n)} />
                  ))}
                </div>
              )}
            </div>
          </Section>

          <button onClick={clearAll}
            className="w-full flex items-center justify-center gap-2 py-2.5 text-sm font-medium rounded-lg border transition-all"
            style={{ color: 'var(--muted)', borderColor: 'var(--border)' }}>
            <RotateCcw size={14} />
            Reset All Filters
          </button>
        </div>
      </div>
    </div>
  )
}
