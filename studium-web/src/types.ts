export interface AnswerOption {
  id: string
  content: string
  label?: string
}

export interface AnswerObject {
  style?: string
  choices?: Record<string, { body: string }>
  correct_choice?: string
  rationale?: string
}

export interface QuestionContent {
  rationale?: string
  stem?: string
  stimulus?: string
  type?: string
  answerOptions?: AnswerOption[]
  correct_answer?: string[]
  prompt?: string
  body?: string
  answer?: AnswerObject
  keys?: string[]
  origin?: string
}

export interface Question {
  id: string
  uId: string
  questionId: string
  program: string
  module: string
  difficulty: string
  primaryClassCd: string
  primaryClassCdDesc: string
  skillCd?: string
  skillDesc: string
  scoreBandRangeCd?: number
  ibn?: string
  externalId?: string
  pPcc?: string
  updateDate?: number
  createDate?: number
  content: QuestionContent
}

export interface QuestionData {
  version: string
  totalQuestions: number
  questions: Question[]
}

// Derived helpers
export function getDisplayStem(q: Question): string {
  return q.content.stem ?? q.content.prompt ?? ''
}

export function getDisplayStimulus(q: Question): string {
  return q.content.stimulus ?? q.content.body ?? ''
}

export function getDisplayAnswerOptions(q: Question): AnswerOption[] {
  const c = q.content
  if (c.answerOptions && c.answerOptions.length > 0) {
    return c.answerOptions.map((opt, i) => ({
      ...opt,
      label: opt.label ?? String.fromCharCode(65 + i),
    }))
  }
  if (c.answer?.choices) {
    const sorted = Object.entries(c.answer.choices).sort(([a], [b]) => a.localeCompare(b))
    return sorted.map(([key, val], i) => ({
      id: key,
      content: val.body,
      label: String.fromCharCode(65 + i),
    }))
  }
  return []
}

export function getCorrectAnswer(q: Question): string[] {
  const c = q.content
  if (c.correct_answer && c.correct_answer.length > 0) return c.correct_answer
  if (c.answer?.correct_choice) return [c.answer.correct_choice.toUpperCase()]
  return []
}

export function isFreeResponse(q: Question): boolean {
  return getDisplayAnswerOptions(q).length === 0
}

// Progress
export interface QuestionProgress {
  seen: boolean
  correct?: boolean
  lastAttempted?: number
}

// Filters
export type AnswerStatus = 'all' | 'unanswered' | 'incorrect' | 'correct'
export type BluebookFilter = 'bluebook' | 'notBluebook'

/** Educator Bank HTML scrape (exclude active); matches Swift FilterOptions.CBVerifiedInactiveFilter. */
export type CBVerifiedInactiveFilter = 'onlyVerifiedOffCBPracticeTests'

export interface FilterOptions {
  module?: string
  difficulty?: string
  primaryClassCdDesc?: string
  skillDesc?: string
  answerStatus: AnswerStatus
  isBluebook?: BluebookFilter
  cbVerifiedInactive?: CBVerifiedInactiveFilter
  shuffled: boolean
  questionLimit?: number
}

export function defaultFilters(): FilterOptions {
  return { answerStatus: 'all', shuffled: true }
}

// Saved quiz
export interface QuestionAnswerState {
  selectedAnswerId?: string
  hasSubmitted: boolean
  isCorrect?: boolean
}

export interface SavedQuiz {
  id: string
  questionIds: string[]
  currentIndex: number
  filters: FilterOptions
  answerStates: Record<string, QuestionAnswerState>
  lastSaved: number
}

// Vocab
export interface VocabWord {
  id: string
  word: string
  definition: string
  partOfSpeech: string
}

export interface VocabData {
  words: VocabWord[]
}
