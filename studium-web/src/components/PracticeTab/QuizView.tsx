import { useState, useEffect, useRef } from 'react'
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
import { ArrowLeft, ArrowRight, X, CheckCircle, XCircle, ChevronLeft, GripVertical } from 'lucide-react'
import { HtmlBlock } from '../HtmlBlock'

const PASSAGE_SPLIT_STORAGE_KEY = 'studium-passage-split-pct'
const PASSAGE_SPLIT_HANDLE_PX = 8
const PASSAGE_SPLIT_MIN_PCT = 22
const PASSAGE_SPLIT_MAX_PCT = 78

function readInitialPassageSplitPct(): number {
  try {
    const n = Number(localStorage.getItem(PASSAGE_SPLIT_STORAGE_KEY))
    if (Number.isFinite(n) && n >= PASSAGE_SPLIT_MIN_PCT && n <= PASSAGE_SPLIT_MAX_PCT) return n
  } catch {
    /* ignore */
  }
  return 50
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

  useEffect(() => {
    if (!splitDragging) return
    function onMove(e: PointerEvent) {
      const el = splitContainerRef.current
      if (!el) return
      const rect = el.getBoundingClientRect()
      const pct = ((e.clientX - rect.left) / rect.width) * 100
      const clamped = Math.min(PASSAGE_SPLIT_MAX_PCT, Math.max(PASSAGE_SPLIT_MIN_PCT, pct))
      setPassagePanePct(clamped)
    }
    function onUp() {
      setSplitDragging(false)
      try {
        localStorage.setItem(PASSAGE_SPLIT_STORAGE_KEY, String(passageSplitPctRef.current))
      } catch {
        /* ignore */
      }
    }
    window.addEventListener('pointermove', onMove)
    window.addEventListener('pointerup', onUp)
    window.addEventListener('pointercancel', onUp)
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'
    return () => {
      window.removeEventListener('pointermove', onMove)
      window.removeEventListener('pointerup', onUp)
      window.removeEventListener('pointercancel', onUp)
      document.body.style.cursor = ''
      document.body.style.userSelect = ''
    }
  }, [splitDragging])

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
  /** English/R&W: split pane on large screens when there is a passage. Math: always single column. */
  const useSplitPassageLayout = hasStimulus && !isMathModule

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
    <div className="space-y-2.5">
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
            className="w-full text-left border rounded-xl p-4 transition-all cursor-pointer select-none"
            style={{ borderColor, background: bgColor, color: textColor }}
          >
            <div className="flex gap-3 items-start">
              <span className="font-bold text-sm mt-0.5 shrink-0 w-5 text-center" style={{ color: labelColor }}>
                {opt.label}
              </span>
              <div className="flex-1 min-w-0">
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

      {/* ── Passage + question: English uses split on lg+; math always stacked ── */}
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
            className="hidden lg:flex flex-1 overflow-hidden min-h-0 min-w-0"
          >
            <div
              className="overflow-y-auto min-h-0 min-w-0 border-r px-3 py-3"
              style={{
                borderColor: 'var(--border)',
                flex: `0 0 ${passagePanePct}%`,
              }}
            >
              <div className="max-w-[680px] mx-auto">
                <HtmlBlock html={stimulus} isDark={isDark} fontSize={fontSize} profile="passage" />
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
              className="shrink-0 flex flex-col items-center justify-center cursor-col-resize touch-none select-none rounded-sm hover:opacity-90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-[-2px] focus-visible:outline-[var(--accent)]"
              style={{
                flex: `0 0 ${PASSAGE_SPLIT_HANDLE_PX}px`,
                background: splitDragging ? 'color-mix(in srgb, var(--accent) 18%, transparent)' : 'var(--input)',
              }}
              onPointerDown={e => {
                e.preventDefault()
                setSplitDragging(true)
              }}
              onKeyDown={e => {
                if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
                  e.preventDefault()
                  const delta = e.key === 'ArrowLeft' ? -2 : 2
                  setPassagePanePct(p => {
                    const next = Math.min(PASSAGE_SPLIT_MAX_PCT, Math.max(PASSAGE_SPLIT_MIN_PCT, p + delta))
                    try {
                      localStorage.setItem(PASSAGE_SPLIT_STORAGE_KEY, String(next))
                    } catch {
                      /* ignore */
                    }
                    return next
                  })
                }
              }}
            >
              <GripVertical size={14} style={{ color: 'var(--muted)' }} aria-hidden />
            </div>
            <div className="flex-1 min-h-0 min-w-0 overflow-y-auto">
              <div className="max-w-[600px] mx-auto px-3 py-3 space-y-5">
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
