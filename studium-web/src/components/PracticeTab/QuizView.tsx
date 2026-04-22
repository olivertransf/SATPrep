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
} from 'lucide-react'
import { HtmlBlock } from '../HtmlBlock'

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
}

export default function QuizView({ quiz, questions, progress, onProgressChange, onExit, isDark, fontSize }: QuizViewProps) {
  const [currentIndex, setCurrentIndex] = useState(quiz.currentIndex)
  const [answerStates, setAnswerStates] = useState<Record<string, QuestionAnswerState>>(quiz.answerStates)
  const [selectedId, setSelectedId] = useState<string | undefined>()
  const [freeText, setFreeText] = useState('')
  const [hasSubmitted, setHasSubmitted] = useState(false)
  const [showExplanation, setShowExplanation] = useState(false)
  const [showJumper, setShowJumper] = useState(false)
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
  const correctCount  = Object.values(answerStates).filter(s => s.isCorrect).length
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
        <button onClick={handleExit}
          className="mt-4 px-5 py-2.5 rounded-xl font-semibold text-sm"
          style={{ background: 'var(--accent)', color: '#fff' }}>
          Go Back
        </button>
      </div>
    )
  }

  // ─── Shared meta row ───────────────────────────────────────────────────────

  const metaRow = (
    <div className="flex flex-wrap gap-2">
      <span className="px-2.5 py-1 rounded-md text-xs font-medium border"
        style={{ borderColor: 'var(--border)', color: 'var(--muted)', background: 'var(--input)' }}>
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
        style={{ borderColor: 'var(--border)', color: 'var(--muted)', background: 'var(--input)' }}>
        {question.skillDesc}
      </span>
      <span className="px-2.5 py-1 rounded-md text-xs font-mono border"
        style={{ borderColor: 'var(--border)', color: 'var(--muted)', background: 'var(--input)' }}>
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
        let borderColor = 'var(--border)'
        let bgColor = 'var(--card)'
        let textColor = 'var(--text)'
        let labelColor = 'var(--muted)'

        if (hasSubmitted) {
          if (isCorrectOpt) { borderColor = 'var(--success)'; bgColor = 'rgba(34,197,94,0.08)'; labelColor = 'var(--success)' }
          else if (isSelected) { borderColor = 'var(--error)'; bgColor = 'rgba(239,68,68,0.08)'; textColor = 'var(--muted)'; labelColor = 'var(--error)' }
          else { bgColor = 'var(--input)'; textColor = 'var(--muted)'; labelColor = 'var(--muted)' }
        } else if (isSelected) {
          borderColor = 'var(--accent)'; bgColor = 'rgba(99,102,241,0.1)'; labelColor = 'var(--accent)'
        }

        return (
          <div key={opt.id}
            onClick={() => !hasSubmitted && setSelectedId(opt.id)}
            role="button"
            aria-pressed={isSelected}
            aria-disabled={hasSubmitted}
            tabIndex={hasSubmitted ? -1 : 0}
            onKeyDown={e => { if (!hasSubmitted && (e.key === 'Enter' || e.key === ' ')) setSelectedId(opt.id) }}
            className="w-full text-left border rounded-lg px-3 py-2 transition-all cursor-pointer select-none"
            style={{ borderColor, background: bgColor, color: textColor }}
          >
            <div className="flex gap-2 items-start">
              <span className="font-bold text-sm leading-snug mt-px shrink-0 w-5 text-center" style={{ color: labelColor }}>
                {opt.label}
              </span>
              <div className="flex-1 min-w-0 min-h-0">
                <HtmlBlock
                  html={opt.content}
                  isDark={isDark}
                  fontSize={fontSize - 1}
                  profile="quizFigures"
                  compact
                  interactive={false}
                />
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )

  // ─── Submit + explanation + nav ───────────────────────────────────────────

  const actionArea = (
    <>
      {!hasSubmitted && (
        <div className="flex gap-2 items-stretch">
          <button
            type="button"
            onClick={() => goTo(currentIndex - 1)}
            disabled={currentIndex === 0}
            className="flex items-center justify-center gap-1.5 shrink-0 px-3 py-3.5 rounded-xl text-sm font-medium border transition-all disabled:opacity-35"
            style={{ borderColor: 'var(--border)', color: 'var(--text)', background: 'var(--card)' }}
          >
            <ArrowLeft size={16} /> Back
          </button>
          <button
            type="button"
            onClick={handleSubmit}
            disabled={isFreeResponse(question) ? !freeText.trim() : !selectedId}
            className="flex-1 min-w-0 py-3.5 rounded-xl font-semibold text-sm transition-all disabled:opacity-40"
            style={{ background: 'var(--accent)', color: '#fff' }}
          >
            Submit Answer
          </button>
          <button
            type="button"
            onClick={() => goTo(currentIndex + 1)}
            disabled={currentIndex >= questions.length - 1}
            className="flex items-center justify-center gap-1.5 shrink-0 px-3 py-3.5 rounded-xl text-sm font-medium border transition-all disabled:opacity-35"
            style={{ borderColor: 'var(--border)', color: 'var(--text)', background: 'var(--card)' }}
          >
            Next <ArrowRight size={16} />
          </button>
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
        <div className="flex gap-3 pb-6">
          {currentIndex > 0 && (
            <button onClick={() => goTo(currentIndex - 1)}
              className="flex items-center gap-2 flex-1 py-3 border rounded-xl text-sm font-medium justify-center transition-all"
              style={{ borderColor: 'var(--border)', color: 'var(--text)', background: 'var(--card)' }}>
              <ArrowLeft size={16} /> Previous
            </button>
          )}
          {currentIndex < questions.length - 1 ? (
            <button onClick={() => goTo(currentIndex + 1)}
              className="flex items-center gap-2 flex-1 py-3 rounded-xl text-sm font-semibold justify-center transition-all"
              style={{ background: 'var(--accent)', color: '#fff' }}>
              Next <ArrowRight size={16} />
            </button>
          ) : (
            <button onClick={handleExit}
              className="flex-1 py-3 rounded-xl text-sm font-semibold transition-all"
              style={{ background: 'var(--success)', color: '#fff' }}>
              Finish Quiz
            </button>
          )}
        </div>
      )}
    </>
  )

  // ─── Header bar (shared across layouts) ───────────────────────────────────

  const header = (
    <>
      <div className="shrink-0 border-b px-4 py-3 flex items-center justify-between gap-3"
        style={{ background: 'var(--card)', borderColor: 'var(--border)' }}>
        <button onClick={handleExit}
          className="flex items-center gap-1.5 text-sm font-medium" style={{ color: 'var(--muted)' }}>
          <ChevronLeft size={16} /> Exit
        </button>
        <button onClick={() => setShowJumper(true)}
          className="text-sm font-semibold px-3 py-1 rounded-lg border"
          style={{ color: 'var(--text)', borderColor: 'var(--border)', background: 'var(--input)' }}>
          {currentIndex + 1} / {questions.length}
        </button>
        <div className="text-sm font-medium" style={{ color: answeredCount > 0 ? 'var(--success)' : 'var(--muted)' }}>
          {answeredCount > 0 ? `${correctCount}/${answeredCount}` : ''}
        </div>
      </div>
      <div className="shrink-0 h-0.5" style={{ background: 'var(--border)' }}>
        <div className="h-full transition-all duration-500"
          style={{ width: `${progressPct}%`, background: 'var(--accent)' }} />
      </div>
    </>
  )

  return (
    <div className="flex flex-col h-full" style={{ background: 'var(--bg)' }}>
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
                  src="https://www.desmos.com/calculator"
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
                src="https://www.desmos.com/calculator"
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
