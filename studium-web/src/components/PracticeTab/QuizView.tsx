import { useState, useEffect, useRef, type CSSProperties, type PointerEvent as ReactPointerEvent } from 'react'
import type {
  Question,
  QuestionProgress,
  SavedQuiz,
  QuestionAnswerState,
} from '../../types'
import {
  getDisplayStem,
  getDisplayStimulus,
  getDisplayAnswerOptions,
  getCorrectAnswer,
  isFreeResponse,
} from '../../types'
import { markSeen, markAnswered } from '../../store/progress'
import { saveQuiz } from '../../store/quiz'
import { checkAnswer } from '../../utils/questions'
import {
  ArrowLeft,
  ArrowRight,
  X,
  CheckCircle,
  XCircle,
  ChevronLeft,
  ChevronRight,
  GripVertical,
  Type,
  Minus,
  Plus,
} from 'lucide-react'
import { HtmlBlock } from '../HtmlBlock'
import { Button } from '../ui/Button'

const PASSAGE_SPLIT_STORAGE_KEY = 'studium-passage-split-pct'
const MATH_DESMOS_SPLIT_STORAGE_KEY = 'studium-math-desmos-split-pct'
/** Hit target width; must match flex-basis on the handle and `clientXToPct` track math */
const PASSAGE_SPLIT_HANDLE_PX = 16
const PASSAGE_SPLIT_MIN_PCT = 22
const PASSAGE_SPLIT_MAX_PCT = 78

function passagePointerXToPct(clientX: number, container: HTMLElement): number {
  const rect = container.getBoundingClientRect()
  const track = Math.max(1, rect.width - PASSAGE_SPLIT_HANDLE_PX)
  const leftPx = clientX - rect.left - PASSAGE_SPLIT_HANDLE_PX / 2
  const pct = (leftPx / track) * 100
  return Math.min(PASSAGE_SPLIT_MAX_PCT, Math.max(PASSAGE_SPLIT_MIN_PCT, pct))
}

function readInitialPassageSplitPct(): number {
  try {
    const n = Number(localStorage.getItem(PASSAGE_SPLIT_STORAGE_KEY))
    if (Number.isFinite(n) && n >= PASSAGE_SPLIT_MIN_PCT && n <= PASSAGE_SPLIT_MAX_PCT) return n
  } catch {
    /* ignore */
  }
  return 50
}

function readInitialMathDesmosSplitPct(): number {
  try {
    const n = Number(localStorage.getItem(MATH_DESMOS_SPLIT_STORAGE_KEY))
    if (Number.isFinite(n) && n >= PASSAGE_SPLIT_MIN_PCT && n <= PASSAGE_SPLIT_MAX_PCT) return n
  } catch {
    /* ignore */
  }
  return 40
}

interface QuizViewProps {
  quiz: SavedQuiz
  questions: Question[]
  progress: Record<string, QuestionProgress>
  onProgressChange: (p: Record<string, QuestionProgress>) => void
  onExit: () => void
  isDark: boolean
  fontSize: number
  onFontSizeChange: (size: number) => void
  answerChoiceFontSize: number
  onAnswerChoiceFontSizeChange: (size: number) => void
}

function FontSizeRow({
  label,
  value,
  min,
  max,
  onChange,
}: {
  label: string
  value: number
  min: number
  max: number
  onChange: (size: number) => void
}) {
  return (
    <div className="flex items-center gap-3">
      <span className="text-xs font-medium w-14 shrink-0 text-[var(--muted)]">{label}</span>
      <button
        type="button"
        className="p-1 rounded-md border border-[var(--border)] text-[var(--muted)] disabled:opacity-40"
        disabled={value <= min}
        onClick={() => onChange(Math.max(min, value - 1))}
        aria-label={`Decrease ${label.toLowerCase()} font size`}
      >
        <Minus size={14} aria-hidden="true" />
      </button>
      <span className="text-sm studium-mono w-10 text-center tabular-nums text-[var(--text)]">{value}px</span>
      <button
        type="button"
        className="p-1 rounded-md border border-[var(--border)] text-[var(--muted)] disabled:opacity-40"
        disabled={value >= max}
        onClick={() => onChange(Math.min(max, value + 1))}
        aria-label={`Increase ${label.toLowerCase()} font size`}
      >
        <Plus size={14} aria-hidden="true" />
      </button>
    </div>
  )
}

export default function QuizView({
  quiz, questions, progress, onProgressChange, onExit, isDark, fontSize, onFontSizeChange,
  answerChoiceFontSize, onAnswerChoiceFontSizeChange,
}: QuizViewProps) {
  const [currentIndex, setCurrentIndex] = useState(quiz.currentIndex)
  const [answerStates, setAnswerStates] = useState<Record<string, QuestionAnswerState>>(quiz.answerStates)
  const [selectedId, setSelectedId] = useState<string | undefined>()
  const [freeText, setFreeText] = useState('')
  const [hasSubmitted, setHasSubmitted] = useState(false)
  const [showExplanation, setShowExplanation] = useState(false)
  const [showJumper, setShowJumper] = useState(false)
  const [showFontPopover, setShowFontPopover] = useState(false)
  const [passagePanePct, setPassagePanePct] = useState(readInitialPassageSplitPct)
  const [splitDragging, setSplitDragging] = useState(false)
  const splitContainerRef = useRef<HTMLDivElement>(null)
  const passageSplitPctRef = useRef(passagePanePct)
  passageSplitPctRef.current = passagePanePct

  const [desmosPanePct, setDesmosPanePct] = useState(readInitialMathDesmosSplitPct)
  const [desmosSplitDragging, setDesmosSplitDragging] = useState(false)
  const desmosSplitContainerRef = useRef<HTMLDivElement>(null)
  const desmosSplitPctRef = useRef(desmosPanePct)
  desmosSplitPctRef.current = desmosPanePct

  const question = questions[currentIndex]

  useEffect(() => {
    if (!question) return
    const state = answerStates[question.questionId]
    if (state) {
      setSelectedId(isFreeResponse(question) ? undefined : state.selectedAnswerId)
      setFreeText(isFreeResponse(question) ? (state.selectedAnswerId ?? '') : '')
      setHasSubmitted(state.hasSubmitted)
      setShowExplanation(state.hasSubmitted)
    } else {
      setSelectedId(undefined)
      setFreeText('')
      setHasSubmitted(false)
      setShowExplanation(false)
    }
    const newProgress = markSeen(progress, question.questionId)
    onProgressChange(newProgress)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentIndex, question?.questionId])

  const answerStatesRef = useRef(answerStates)
  const currentIndexRef = useRef(currentIndex)
  const selectedIdRef = useRef(selectedId)
  const freeTextRef = useRef(freeText)
  const hasSubmittedRef = useRef(hasSubmitted)
  answerStatesRef.current = answerStates
  currentIndexRef.current = currentIndex
  selectedIdRef.current = selectedId
  freeTextRef.current = freeText
  hasSubmittedRef.current = hasSubmitted

  useEffect(() => {
    const flush = () => {
      const q = questions[currentIndexRef.current]
      if (!q) return
      let base = answerStatesRef.current
      if (!hasSubmittedRef.current) {
        const hasDraft = isFreeResponse(q)
          ? freeTextRef.current.trim().length > 0
          : !!selectedIdRef.current
        if (hasDraft) {
          const id = isFreeResponse(q) ? freeTextRef.current : selectedIdRef.current!
          base = { ...base, [q.questionId]: { selectedAnswerId: id, hasSubmitted: false } }
        }
      }
      saveQuiz({
        ...quiz,
        currentIndex: currentIndexRef.current,
        answerStates: base,
        lastSaved: Date.now(),
      })
    }
    window.addEventListener('pagehide', flush)
    return () => window.removeEventListener('pagehide', flush)
  }, [quiz, questions])

  // Keyboard nav
  useEffect(() => {
    function handler(e: KeyboardEvent) {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return
      if (e.key === 'ArrowRight' && currentIndex < questions.length - 1) goTo(currentIndex + 1)
      if (e.key === 'ArrowLeft' && currentIndex > 0) goTo(currentIndex - 1)
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasSubmitted, currentIndex])

  function persistQuiz(newAnswerStates: Record<string, QuestionAnswerState>, idx: number) {
    saveQuiz({ ...quiz, currentIndex: idx, answerStates: newAnswerStates, lastSaved: Date.now() })
  }

  /** Persist unsubmitted MC / free-response input when leaving a question. */
  function answerStatesWithCurrentDraft(base: Record<string, QuestionAnswerState>): Record<string, QuestionAnswerState> {
    if (!question || hasSubmitted) return base
    const hasDraft = isFreeResponse(question)
      ? freeText.trim().length > 0
      : !!selectedId
    if (!hasDraft) return base
    const id = isFreeResponse(question) ? freeText : selectedId!
    return { ...base, [question.questionId]: { selectedAnswerId: id, hasSubmitted: false } }
  }

  function handleSubmit() {
    if (!question) return
    const answer = isFreeResponse(question) ? freeText : (selectedId ?? '')
    const correct = checkAnswer(question, answer)
    const newProgress = markAnswered(progress, question.questionId, correct)
    onProgressChange(newProgress)

    const newState: QuestionAnswerState = { selectedAnswerId: answer, hasSubmitted: true, isCorrect: correct }
    const newAnswerStates = { ...answerStates, [question.questionId]: newState }
    setAnswerStates(newAnswerStates)
    setHasSubmitted(true)
    setShowExplanation(true)
    persistQuiz(newAnswerStates, currentIndex)
  }

  function goTo(idx: number) {
    const nextStates = answerStatesWithCurrentDraft(answerStates)
    if (nextStates !== answerStates) setAnswerStates(nextStates)
    persistQuiz(nextStates, idx)
    setCurrentIndex(idx)
    setShowJumper(false)
  }

  function handleExit() {
    const nextStates = answerStatesWithCurrentDraft(answerStates)
    if (nextStates !== answerStates) setAnswerStates(nextStates)
    persistQuiz(nextStates, currentIndex)
    onExit()
  }

  /** Drag uses CSS var updates only (no React re-render per frame); commit on pointerup. */
  function handleSplitPointerDown(e: ReactPointerEvent<HTMLDivElement>) {
    if (e.button !== 0) return
    e.preventDefault()
    const handle = e.currentTarget
    if (!splitContainerRef.current) return

    handle.setPointerCapture(e.pointerId)
    setSplitDragging(true)
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'

    function apply(clientX: number) {
      const root = splitContainerRef.current
      if (!root) return
      const pct = passagePointerXToPct(clientX, root)
      passageSplitPctRef.current = pct
      root.style.setProperty('--passage-split-pct', `${pct}%`)
    }
    apply(e.clientX)

    function onMove(ev: PointerEvent) {
      apply(ev.clientX)
    }
    function onEnd(ev: PointerEvent) {
      handle.removeEventListener('pointermove', onMove)
      handle.removeEventListener('pointerup', onEnd)
      handle.removeEventListener('pointercancel', onEnd)
      try {
        if (handle.hasPointerCapture(ev.pointerId)) handle.releasePointerCapture(ev.pointerId)
      } catch {
        /* ignore */
      }
      setSplitDragging(false)
      document.body.style.cursor = ''
      document.body.style.userSelect = ''
      const finalPct = passageSplitPctRef.current
      setPassagePanePct(finalPct)
      try {
        localStorage.setItem(PASSAGE_SPLIT_STORAGE_KEY, String(finalPct))
      } catch {
        /* ignore */
      }
    }
    handle.addEventListener('pointermove', onMove)
    handle.addEventListener('pointerup', onEnd)
    handle.addEventListener('pointercancel', onEnd)
  }

  /** Math: drag handle between Desmos and question column (lg+ only). */
  function handleDesmosSplitPointerDown(e: ReactPointerEvent<HTMLDivElement>) {
    if (e.button !== 0) return
    e.preventDefault()
    const handle = e.currentTarget
    if (!desmosSplitContainerRef.current) return

    handle.setPointerCapture(e.pointerId)
    setDesmosSplitDragging(true)
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'

    function apply(clientX: number) {
      const root = desmosSplitContainerRef.current
      if (!root) return
      const pct = passagePointerXToPct(clientX, root)
      desmosSplitPctRef.current = pct
      root.style.setProperty('--desmos-split-pct', `${pct}%`)
    }
    apply(e.clientX)

    function onMove(ev: PointerEvent) {
      apply(ev.clientX)
    }
    function onEnd(ev: PointerEvent) {
      handle.removeEventListener('pointermove', onMove)
      handle.removeEventListener('pointerup', onEnd)
      handle.removeEventListener('pointercancel', onEnd)
      try {
        if (handle.hasPointerCapture(ev.pointerId)) handle.releasePointerCapture(ev.pointerId)
      } catch {
        /* ignore */
      }
      setDesmosSplitDragging(false)
      document.body.style.cursor = ''
      document.body.style.userSelect = ''
      const finalPct = desmosSplitPctRef.current
      setDesmosPanePct(finalPct)
      try {
        localStorage.setItem(MATH_DESMOS_SPLIT_STORAGE_KEY, String(finalPct))
      } catch {
        /* ignore */
      }
    }
    handle.addEventListener('pointermove', onMove)
    handle.addEventListener('pointerup', onEnd)
    handle.addEventListener('pointercancel', onEnd)
  }

  const answeredCount = Object.values(answerStates).filter(s => s.hasSubmitted).length
  const isCorrect     = hasSubmitted && question ? answerStates[question.questionId]?.isCorrect : undefined
  const answerOptions = question ? getDisplayAnswerOptions(question) : []
  const correctAnswer = question ? getCorrectAnswer(question) : []
  const stem          = question ? getDisplayStem(question) : ''
  const stimulus      = question ? getDisplayStimulus(question) : ''
  const rationale     = question?.content.rationale ?? question?.content.answer?.rationale ?? ''
  const progressPct   = questions.length > 0 ? (answeredCount / questions.length) * 100 : 0
  const hasStimulus   = stimulus.trim().length > 0
  const isMathModule  = question?.module.toLowerCase() === 'math'
  /** English/R&W: split pane on large screens when there is a passage. */
  const useSplitPassageLayout = hasStimulus && !isMathModule
  /** Math: split Desmos | question on large screens (same interaction model as English passage split). */
  const useMathDesmosSplitLayout = isMathModule

  if (!question) {
    return (
      <div className="flex flex-col items-center justify-center flex-1 p-8 text-center">
        <div className="text-xl font-semibold mb-2" style={{ color: 'var(--text)' }}>No questions found</div>
        <button type="button" onClick={handleExit} className="studium-btn-primary px-6">
          Go back
        </button>
      </div>
    )
  }

  // ─── Shared meta row ───────────────────────────────────────────────────────

  const metaRow = (
    <div className="flex flex-wrap gap-2">
      <span className="px-2.5 py-1 rounded-md text-xs font-medium border"
        style={{ borderColor: 'var(--border)', color: 'var(--muted)', background: 'var(--fill-tertiary)' }}>
        {question.module.charAt(0).toUpperCase() + question.module.slice(1)}
      </span>
      <span className="px-2.5 py-1 rounded-md text-xs font-medium border"
        style={{
          borderColor: 'var(--border)', background: 'var(--input)',
          color: question.difficulty === 'E' ? 'var(--success)' : question.difficulty === 'M' ? 'var(--warning)' : 'var(--error)',
        }}>
        {question.difficulty === 'E' ? 'Easy' : question.difficulty === 'M' ? 'Medium' : 'Hard'}
      </span>
      <span className="px-2.5 py-1 rounded-md text-xs font-medium border truncate max-w-[240px]"
        style={{ borderColor: 'var(--border)', color: 'var(--muted)', background: 'var(--fill-tertiary)' }}>
        {question.skillDesc}
      </span>
      <span className="px-2.5 py-1 rounded-[10px] text-xs studium-mono border"
        style={{ borderColor: 'var(--border)', color: 'var(--muted)', background: 'var(--fill-tertiary)' }}>
        {question.questionId}
      </span>
    </div>
  )

  // ─── Answer options / free response ───────────────────────────────────────

  const answerArea = isFreeResponse(question) ? (
    <div className="space-y-3">
      <label className="text-sm font-medium" style={{ color: 'var(--muted)' }}>Your Answer</label>
      <input
        value={freeText}
        onChange={e => setFreeText(e.target.value)}
        disabled={hasSubmitted}
        placeholder="Enter your answer…"
        className="w-full rounded-xl px-4 py-3 text-base border transition-colors outline-none"
        style={{ background: 'var(--input)', borderColor: 'var(--border)', color: 'var(--text)' }}
        onFocus={e => { e.currentTarget.style.borderColor = 'var(--accent)' }}
        onBlur={e => { e.currentTarget.style.borderColor = 'var(--border)' }}
      />
      {hasSubmitted && correctAnswer.length > 0 && (
        <div className="flex items-center gap-2 px-4 py-3 rounded-xl text-sm font-medium border"
          style={isCorrect
            ? { background: 'rgba(34,197,94,0.1)', borderColor: 'var(--success)', color: 'var(--success)' }
            : { background: 'rgba(239,68,68,0.1)', borderColor: 'var(--error)', color: 'var(--error)' }
          }>
          {isCorrect
            ? <><CheckCircle size={16} /> Correct!</>
            : <><XCircle size={16} /> Correct: {correctAnswer.join(', ')}</>
          }
        </div>
      )}
    </div>
  ) : (
    <div className="space-y-2">
      {answerOptions.map(opt => {
        const isSelected  = selectedId === opt.id
        const isCorrectOpt = hasSubmitted && correctAnswer.some(c => c.trim().toUpperCase() === opt.label?.toUpperCase())

        return (
          <button
            key={opt.id}
            type="button"
            onClick={() => !hasSubmitted && setSelectedId(opt.id)}
            disabled={hasSubmitted}
            aria-pressed={isSelected}
            className={[
              'studium-quiz-option',
              !hasSubmitted && isSelected ? 'studium-quiz-option--selected' : '',
              hasSubmitted && isCorrectOpt ? 'studium-quiz-option--correct' : '',
              hasSubmitted && isSelected && !isCorrectOpt ? 'studium-quiz-option--wrong' : '',
            ].filter(Boolean).join(' ')}
          >
            <div className="flex gap-2 items-start">
              <span
                className="font-bold text-sm leading-snug mt-px shrink-0 w-5 text-center"
                style={{ color: hasSubmitted ? (isCorrectOpt ? 'var(--success)' : isSelected ? 'var(--error)' : 'var(--muted)') : isSelected ? 'var(--accent)' : 'var(--muted)' }}
              >
                {opt.label}
              </span>
              <div className="flex-1 min-w-0 min-h-0">
                <HtmlBlock
                  html={opt.content}
                  isDark={isDark}
                  fontSize={answerChoiceFontSize}
                  profile="quizFigures"
                  compact
                  interactive={false}
                />
              </div>
            </div>
          </button>
        )
      })}
    </div>
  )

  // ─── Submit + explanation + nav ───────────────────────────────────────────

  const actionArea = (
    <>
      {!hasSubmitted && (
        <div className="flex gap-2 items-stretch max-lg:hidden">
          <Button
            variant="secondary"
            onClick={() => goTo(currentIndex - 1)}
            disabled={currentIndex === 0}
          >
            <ArrowLeft size={16} aria-hidden="true" /> Previous
          </Button>
          <Button
            fullWidth
            onClick={handleSubmit}
            disabled={isFreeResponse(question) ? !freeText.trim() : !selectedId}
          >
            Submit answer
          </Button>
          <Button
            variant="secondary"
            onClick={() => goTo(currentIndex + 1)}
            disabled={currentIndex >= questions.length - 1}
          >
            Next <ArrowRight size={16} aria-hidden="true" />
          </Button>
        </div>
      )}

      {hasSubmitted && rationale && (
        <div className="explanation-reveal space-y-2">
          <button onClick={() => setShowExplanation(!showExplanation)}
            className="text-sm font-medium" style={{ color: 'var(--accent)' }}>
            {showExplanation ? 'Hide' : 'Show'} Explanation
          </button>
          {showExplanation && (
            <div className="explanation-reveal rounded-xl overflow-hidden border"
              style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
              <HtmlBlock html={rationale} isDark={isDark} fontSize={fontSize - 1} profile="standard" />
            </div>
          )}
        </div>
      )}

      {hasSubmitted && (
        <div className="flex gap-3 pb-6 max-lg:hidden">
          {currentIndex > 0 && (
            <Button variant="secondary" fullWidth onClick={() => goTo(currentIndex - 1)}>
              <ArrowLeft size={16} aria-hidden="true" /> Previous
            </Button>
          )}
          {currentIndex < questions.length - 1 ? (
            <Button fullWidth onClick={() => goTo(currentIndex + 1)}>
              Next <ArrowRight size={16} aria-hidden="true" />
            </Button>
          ) : (
            <Button fullWidth onClick={handleExit} className="studium-btn-primary" style={{ background: 'var(--success)' }}>
              Finish quiz
            </Button>
          )}
        </div>
      )}
    </>
  )

  // ─── Header bar (shared across layouts) ───────────────────────────────────

  const header = (
    <>
      <div className="shrink-0 border-b px-4 py-3 flex items-center justify-between gap-3 bg-[var(--card)] border-[var(--border)]">
        <button
          type="button"
          onClick={handleExit}
          className="flex items-center gap-1.5 text-sm font-medium text-[var(--muted)] border-0 bg-transparent cursor-pointer min-h-[44px]"
        >
          <ChevronLeft size={16} aria-hidden="true" /> Exit
        </button>
        <button
          type="button"
          onClick={() => setShowJumper(true)}
          className="text-sm font-semibold px-3 py-2 rounded-lg border min-h-[44px] text-[var(--text)] border-[var(--border)] bg-[var(--input)] cursor-pointer"
          aria-label="Jump to question"
        >
          Question {currentIndex + 1} of {questions.length}
        </button>
        <span className="studium-mono text-xs text-[var(--muted)] hidden sm:inline" title="Question ID">
          {question.questionId}
        </span>
        <div className="relative">
          <button
            type="button"
            onClick={() => setShowFontPopover(v => !v)}
            className="flex items-center justify-center w-10 h-10 rounded-lg border text-[var(--muted)] border-[var(--border)] bg-[var(--input)] cursor-pointer"
            aria-label="Text size"
            aria-expanded={showFontPopover}
          >
            <Type size={16} aria-hidden="true" />
          </button>
          {showFontPopover && (
            <>
              <button
                type="button"
                className="fixed inset-0 z-40 cursor-default border-0 bg-transparent"
                aria-label="Close text size menu"
                onClick={() => setShowFontPopover(false)}
              />
              <div
                className="absolute right-0 top-full mt-2 z-50 w-56 rounded-xl border p-4 space-y-3 shadow-lg bg-[var(--card)] border-[var(--border)]"
                role="dialog"
                aria-label="Font size"
              >
                <div className="text-sm font-semibold text-center text-[var(--text)]">Font size</div>
                <FontSizeRow label="Content" value={fontSize} min={13} max={22} onChange={onFontSizeChange} />
                <FontSizeRow label="Choices" value={answerChoiceFontSize} min={13} max={22} onChange={onAnswerChoiceFontSizeChange} />
                <button
                  type="button"
                  className="text-xs w-full text-center text-[var(--muted)] border-0 bg-transparent cursor-pointer"
                  onClick={() => {
                    onFontSizeChange(16)
                    onAnswerChoiceFontSizeChange(15)
                  }}
                >
                  Reset
                </button>
              </div>
            </>
          )}
        </div>
      </div>
      <div className="shrink-0 h-0.5 bg-[var(--border)]" role="progressbar" aria-valuenow={Math.round(progressPct)} aria-valuemin={0} aria-valuemax={100}>
        <div className="h-full transition-all duration-500 bg-[var(--accent)]" style={{ width: `${progressPct}%` }} />
      </div>
    </>
  )

  const mobileQuizBar = (
    <div className="lg:hidden shrink-0 border-t px-4 py-2 flex gap-2 bg-[var(--card)] border-[var(--border)] studium-bottom-nav">
      {!hasSubmitted ? (
        <>
          <Button variant="secondary" onClick={() => goTo(currentIndex - 1)} disabled={currentIndex === 0} aria-label="Previous question">
            <ArrowLeft size={16} aria-hidden="true" />
          </Button>
          <Button
            fullWidth
            onClick={handleSubmit}
            disabled={isFreeResponse(question) ? !freeText.trim() : !selectedId}
          >
            Submit
          </Button>
          <Button variant="secondary" onClick={() => goTo(currentIndex + 1)} disabled={currentIndex >= questions.length - 1} aria-label="Next question">
            <ArrowRight size={16} aria-hidden="true" />
          </Button>
        </>
      ) : currentIndex < questions.length - 1 ? (
        <>
          <Button variant="secondary" onClick={() => goTo(currentIndex - 1)} disabled={currentIndex === 0}>
            Previous
          </Button>
          <Button fullWidth onClick={() => goTo(currentIndex + 1)}>Next</Button>
        </>
      ) : (
        <Button fullWidth onClick={handleExit} style={{ background: 'var(--success)' }}>Finish quiz</Button>
      )}
    </div>
  )

  return (
    <div className="flex flex-col h-full bg-[var(--bg)]">
      {header}

      {/* ── English: passage | question split on lg+. Math: Desmos | question split on lg+. ── */}
      {useSplitPassageLayout ? (
        <>
          <div className="lg:hidden flex-1 overflow-y-auto">
            <div className="max-w-[720px] mx-auto px-4 py-6 space-y-5">
              {metaRow}
              <div className="rounded-xl overflow-hidden border-l-[3px]"
                style={{ background: 'var(--card)', border: '1px solid var(--border)', borderLeft: '3px solid var(--accent)' }}>
                <HtmlBlock html={stimulus} isDark={isDark} fontSize={fontSize} profile="passage" />
              </div>
              {stem && (
                <HtmlBlock html={stem} isDark={isDark} fontSize={fontSize} profile="quizFigures" />
              )}
              {answerArea}
              {actionArea}
            </div>
          </div>

          <div
            ref={splitContainerRef}
            className="hidden lg:flex flex-1 flex-row items-stretch overflow-hidden min-h-0 min-w-0"
            style={{ '--passage-split-pct': `${passagePanePct}%` } as CSSProperties}
          >
            <div
              className="flex flex-col h-full min-h-0 min-w-0 w-full overflow-hidden border-r box-border min-w-0"
              style={{
                borderColor: 'var(--border)',
                background: 'var(--card)',
                flexGrow: 0,
                flexShrink: 0,
                flexBasis: 'var(--passage-split-pct)',
              }}
            >
              <div className="flex-1 min-h-0 min-w-0 flex flex-col px-3 py-3 box-border">
                <HtmlBlock
                  fillViewport
                  html={stimulus}
                  isDark={isDark}
                  fontSize={fontSize}
                  profile="passage"
                />
              </div>
            </div>
            <div
              role="separator"
              aria-orientation="vertical"
              aria-label="Resize passage and question columns"
              aria-valuenow={Math.round(passagePanePct)}
              aria-valuemin={PASSAGE_SPLIT_MIN_PCT}
              aria-valuemax={PASSAGE_SPLIT_MAX_PCT}
              tabIndex={0}
              className="shrink-0 self-stretch z-10 flex flex-col items-center justify-center cursor-col-resize touch-none select-none border-x rounded-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-[var(--accent)]"
              style={{
                flex: `0 0 ${PASSAGE_SPLIT_HANDLE_PX}px`,
                width: PASSAGE_SPLIT_HANDLE_PX,
                touchAction: 'none',
                borderColor: 'var(--border)',
                background: splitDragging
                  ? 'color-mix(in srgb, var(--accent) 22%, var(--input))'
                  : 'var(--input)',
              }}
              onPointerDown={handleSplitPointerDown}
              onKeyDown={e => {
                if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return
                e.preventDefault()
                const delta = e.key === 'ArrowLeft' ? -2 : 2
                setPassagePanePct(p => {
                  const next = Math.min(PASSAGE_SPLIT_MAX_PCT, Math.max(PASSAGE_SPLIT_MIN_PCT, p + delta))
                  passageSplitPctRef.current = next
                  splitContainerRef.current?.style.setProperty('--passage-split-pct', `${next}%`)
                  try {
                    localStorage.setItem(PASSAGE_SPLIT_STORAGE_KEY, String(next))
                  } catch {
                    /* ignore */
                  }
                  return next
                })
              }}
            >
              <span className="pointer-events-none flex flex-col items-center justify-center gap-0.5 py-1">
                <ChevronLeft
                  size={12}
                  strokeWidth={2.5}
                  aria-hidden
                  style={{ color: 'var(--muted)', opacity: 0.85 }}
                />
                <GripVertical
                  size={16}
                  strokeWidth={2.25}
                  aria-hidden
                  style={{ color: splitDragging ? 'var(--accent)' : 'var(--muted)' }}
                />
                <ChevronRight
                  size={12}
                  strokeWidth={2.5}
                  aria-hidden
                  style={{ color: 'var(--muted)', opacity: 0.85 }}
                />
              </span>
            </div>
            <div
              className="h-full min-h-0 min-w-0 flex-1 w-full overflow-y-auto box-border"
              style={{ background: 'var(--card)' }}
            >
              <div className="w-full max-w-none px-3 py-3 space-y-5 box-border">
                {metaRow}
                {stem && (
                  <HtmlBlock html={stem} isDark={isDark} fontSize={fontSize} profile="quizFigures" />
                )}
                {answerArea}
                {actionArea}
              </div>
            </div>
          </div>
        </>
      ) : useMathDesmosSplitLayout ? (
        <>
          <div className="lg:hidden flex-1 overflow-y-auto">
            <div className="max-w-[720px] mx-auto px-4 py-6 space-y-5">
              {metaRow}
              {hasStimulus && (
                <div className="rounded-xl overflow-hidden border-l-[3px]"
                  style={{ background: 'var(--card)', border: '1px solid var(--border)', borderLeft: '3px solid var(--accent)' }}>
                  <HtmlBlock html={stimulus} isDark={isDark} fontSize={fontSize} profile="passage" />
                </div>
              )}
              {stem && (
                <HtmlBlock html={stem} isDark={isDark} fontSize={fontSize} profile="quizFigures" />
              )}
              {answerArea}
              {actionArea}
              <div className="rounded-xl overflow-hidden border" style={{ borderColor: 'var(--border)', height: 300 }}>
                <iframe
                  src="https://www.desmos.com/testing/collegeboard/graphing"
                  className="w-full h-full border-0"
                  title="Desmos Graphing Calculator"
                  allow="fullscreen"
                />
              </div>
            </div>
          </div>

          <div
            ref={desmosSplitContainerRef}
            className="hidden lg:flex flex-1 flex-row items-stretch overflow-hidden min-h-0 min-w-0"
            style={{ '--desmos-split-pct': `${desmosPanePct}%` } as CSSProperties}
          >
            <div
              className="flex flex-col h-full min-h-0 min-w-0 w-full overflow-hidden border-r box-border min-w-0"
              style={{
                borderColor: 'var(--border)',
                background: 'var(--bg)',
                flexGrow: 0,
                flexShrink: 0,
                flexBasis: 'var(--desmos-split-pct)',
              }}
            >
              <iframe
                src="https://www.desmos.com/testing/collegeboard/graphing"
                className="flex-1 min-h-0 w-full border-0"
                title="Desmos Graphing Calculator"
                allow="fullscreen"
              />
            </div>
            <div
              role="separator"
              aria-orientation="vertical"
              aria-label="Resize calculator and question columns"
              aria-valuenow={Math.round(desmosPanePct)}
              aria-valuemin={PASSAGE_SPLIT_MIN_PCT}
              aria-valuemax={PASSAGE_SPLIT_MAX_PCT}
              tabIndex={0}
              className="shrink-0 self-stretch z-10 flex flex-col items-center justify-center cursor-col-resize touch-none select-none border-x rounded-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-[var(--accent)]"
              style={{
                flex: `0 0 ${PASSAGE_SPLIT_HANDLE_PX}px`,
                width: PASSAGE_SPLIT_HANDLE_PX,
                touchAction: 'none',
                borderColor: 'var(--border)',
                background: desmosSplitDragging
                  ? 'color-mix(in srgb, var(--accent) 22%, var(--input))'
                  : 'var(--input)',
              }}
              onPointerDown={handleDesmosSplitPointerDown}
              onKeyDown={e => {
                if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return
                e.preventDefault()
                const delta = e.key === 'ArrowLeft' ? -2 : 2
                setDesmosPanePct(p => {
                  const next = Math.min(PASSAGE_SPLIT_MAX_PCT, Math.max(PASSAGE_SPLIT_MIN_PCT, p + delta))
                  desmosSplitPctRef.current = next
                  desmosSplitContainerRef.current?.style.setProperty('--desmos-split-pct', `${next}%`)
                  try {
                    localStorage.setItem(MATH_DESMOS_SPLIT_STORAGE_KEY, String(next))
                  } catch {
                    /* ignore */
                  }
                  return next
                })
              }}
            >
              <span className="pointer-events-none flex flex-col items-center justify-center gap-0.5 py-1">
                <ChevronLeft
                  size={12}
                  strokeWidth={2.5}
                  aria-hidden
                  style={{ color: 'var(--muted)', opacity: 0.85 }}
                />
                <GripVertical
                  size={16}
                  strokeWidth={2.25}
                  aria-hidden
                  style={{ color: desmosSplitDragging ? 'var(--accent)' : 'var(--muted)' }}
                />
                <ChevronRight
                  size={12}
                  strokeWidth={2.5}
                  aria-hidden
                  style={{ color: 'var(--muted)', opacity: 0.85 }}
                />
              </span>
            </div>
            <div
              className="h-full min-h-0 min-w-0 flex-1 w-full overflow-y-auto box-border"
              style={{ background: 'var(--card)' }}
            >
              <div className="w-full max-w-none px-3 py-3 space-y-5 box-border">
                {metaRow}
                {hasStimulus && (
                  <div className="rounded-xl overflow-hidden border-l-[3px]"
                    style={{ background: 'var(--input)', border: '1px solid var(--border)', borderLeft: '3px solid var(--accent)' }}>
                    <HtmlBlock html={stimulus} isDark={isDark} fontSize={fontSize} profile="passage" />
                  </div>
                )}
                {stem && (
                  <HtmlBlock html={stem} isDark={isDark} fontSize={fontSize} profile="quizFigures" />
                )}
                {answerArea}
                {actionArea}
              </div>
            </div>
          </div>
        </>
      ) : hasStimulus ? (
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-[720px] lg:max-w-[860px] mx-auto px-4 lg:px-8 py-6 space-y-5">
            {metaRow}
            <div className="rounded-xl overflow-hidden border-l-[3px]"
              style={{ background: 'var(--card)', border: '1px solid var(--border)', borderLeft: '3px solid var(--accent)' }}>
              <HtmlBlock html={stimulus} isDark={isDark} fontSize={fontSize} profile="passage" />
            </div>
            {stem && (
              <HtmlBlock html={stem} isDark={isDark} fontSize={fontSize} profile="quizFigures" />
            )}
            {answerArea}
            {actionArea}
          </div>
        </div>
      ) : (
        /* No stimulus: single centered column, wider on large screens */
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-[720px] lg:max-w-[860px] mx-auto px-4 lg:px-8 py-6 space-y-5">
            {metaRow}
            {stem && (
              <HtmlBlock html={stem} isDark={isDark} fontSize={fontSize} profile="quizFigures" />
            )}
            {answerArea}
            {actionArea}
          </div>
        </div>
      )}

      {mobileQuizBar}

      {/* Question Jumper */}
      {showJumper && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center"
          style={{ background: 'rgba(0,0,0,0.6)' }}>
          <div className="w-full sm:max-w-sm sm:rounded-2xl rounded-t-2xl max-h-[70vh] flex flex-col overflow-hidden border shadow-2xl"
            style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
            <div className="flex items-center justify-between px-4 py-3 border-b"
              style={{ borderColor: 'var(--border)' }}>
              <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>Jump to Question</h3>
              <button onClick={() => setShowJumper(false)} className="p-1.5 rounded-lg"
                style={{ color: 'var(--muted)' }}>
                <X size={16} />
              </button>
            </div>
            <div className="overflow-y-auto p-4">
              <div className="grid grid-cols-5 gap-2">
                {questions.map((q, i) => {
                  const state = answerStates[q.questionId]
                  let bg = 'var(--input)', color = 'var(--muted)', border = 'transparent'
                  if (state?.hasSubmitted) {
                    bg = state.isCorrect ? 'rgba(34,197,94,0.15)' : 'rgba(239,68,68,0.15)'
                    color = state.isCorrect ? 'var(--success)' : 'var(--error)'
                    border = state.isCorrect ? 'var(--success)' : 'var(--error)'
                  }
                  if (i === currentIndex) { bg = 'var(--accent)'; color = '#fff'; border = 'var(--accent)' }
                  return (
                    <button key={q.questionId} onClick={() => goTo(i)}
                      className="aspect-square rounded-lg text-sm font-semibold transition-all border"
                      style={{ background: bg, color, borderColor: border }}>
                      {i + 1}
                    </button>
                  )
                })}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
