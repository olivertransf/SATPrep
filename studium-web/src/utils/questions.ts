import type {
  Question,
  FilterOptions,
  QuestionProgress,
} from '../types'
import { getCorrectAnswer, getDisplayAnswerOptions, isFreeResponse } from '../types'

function isBluebookTagged(q: Question): boolean {
  const ibn = q.ibn?.trim()
  if (ibn) return true
  const o = q.content?.origin?.toLowerCase() ?? ''
  return o.includes('bluebook') || o.includes('blue book')
}

export function getFilteredQuestions(
  questions: Question[],
  filters: FilterOptions,
  progress: Record<string, QuestionProgress>,
  cbVerifiedNotOnPracticeTestIds: Set<string> = new Set()
): Question[] {
  let result = questions

  if (filters.module) {
    result = result.filter(q => q.module === filters.module)
  }

  if (filters.difficulty) {
    result = result.filter(q => q.difficulty === filters.difficulty)
  }

  if (filters.primaryClassCdDesc) {
    result = result.filter(q => q.primaryClassCdDesc === filters.primaryClassCdDesc)
  }

  if (filters.skillDesc) {
    result = result.filter(q => q.skillDesc === filters.skillDesc)
  }

  if (filters.isBluebook === 'bluebook') {
    result = result.filter(isBluebookTagged)
  } else if (filters.isBluebook === 'notBluebook') {
    result = result.filter(q => !isBluebookTagged(q))
  }

  if (filters.cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests') {
    result = result.filter(q => cbVerifiedNotOnPracticeTestIds.has(q.questionId.toLowerCase()))
  }

  if (filters.answerStatus === 'unanswered') {
    result = result.filter(q => !progress[q.questionId]?.seen)
  } else if (filters.answerStatus === 'correct') {
    result = result.filter(q => progress[q.questionId]?.correct === true)
  } else if (filters.answerStatus === 'incorrect') {
    result = result.filter(q => progress[q.questionId]?.correct === false)
  }

  if (filters.shuffled) {
    result = [...result].sort(() => Math.random() - 0.5)
  }

  if (filters.questionLimit && filters.questionLimit > 0) {
    result = result.slice(0, filters.questionLimit)
  }

  return result
}

export function getAvailableModules(questions: Question[]): string[] {
  return [...new Set(questions.map(q => q.module))].sort()
}

export function getAvailablePrimaryClasses(
  questions: Question[],
  module?: string
): string[] {
  let q = questions
  if (module) q = q.filter(x => x.module === module)
  return [...new Set(q.map(x => x.primaryClassCdDesc))].sort()
}

export function getAvailableSkills(
  questions: Question[],
  module?: string,
  primaryClass?: string
): string[] {
  let q = questions
  if (module) q = q.filter(x => x.module === module)
  if (primaryClass) q = q.filter(x => x.primaryClassCdDesc === primaryClass)
  return [...new Set(q.map(x => x.skillDesc))].sort()
}

export function checkAnswer(question: Question, selectedId: string): boolean {
  const correct = getCorrectAnswer(question)
  if (correct.length === 0) return false

  // Free response: loose text match
  if (isFreeResponse(question)) {
    const userAnswer = selectedId.trim().toUpperCase()
    return correct.some(c => c.trim().toUpperCase() === userAnswer)
  }

  // Multiple choice: find the label (A/B/C/D) of the selected option by its id,
  // then compare that label against the correct_answer letter
  const options = getDisplayAnswerOptions(question)
  const selectedOpt = options.find(o => o.id === selectedId)
  if (!selectedOpt?.label) return false
  const selectedLabel = selectedOpt.label.trim().toUpperCase()
  return correct.some(c => c.trim().toUpperCase() === selectedLabel)
}

export function getOverallStats(
  questions: Question[],
  progress: Record<string, QuestionProgress>
) {
  const total = questions.length
  const seen = questions.filter(q => progress[q.questionId]?.seen).length
  const answered = questions.filter(q => progress[q.questionId]?.correct !== undefined).length
  const correct = questions.filter(q => progress[q.questionId]?.correct === true).length
  const accuracy = answered > 0 ? Math.round((correct / answered) * 100) : 0
  return { total, seen, answered, correct, accuracy }
}
