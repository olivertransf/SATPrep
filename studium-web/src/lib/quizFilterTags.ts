import type { FilterOptions } from '../types'

const DIFFICULTY_LABELS: Record<string, string> = { E: 'Easy', M: 'Medium', H: 'Hard' }
const ANSWER_STATUS_LABELS: Record<string, string> = {
  all: 'All',
  unanswered: 'New',
  incorrect: 'Wrong',
  correct: 'Correct',
}

function sectionLabel(m: string): string {
  const l = m.toLowerCase()
  if (l === 'english') return 'Reading & Writing'
  if (l === 'math') return 'Math'
  return m.charAt(0).toUpperCase() + m.slice(1)
}

export function quizFilterTags(f: FilterOptions): string[] {
  const parts: string[] = []
  if (f.module) parts.push(sectionLabel(f.module))
  if (f.primaryClassCdDesc) parts.push(f.primaryClassCdDesc)
  if (f.skillDesc) parts.push(f.skillDesc)
  if (f.difficulty) parts.push(DIFFICULTY_LABELS[f.difficulty] ?? f.difficulty)
  if (f.answerStatus && f.answerStatus !== 'all') {
    parts.push(ANSWER_STATUS_LABELS[f.answerStatus] ?? f.answerStatus)
  }
  if (f.isBluebook === 'bluebook') parts.push('Practice tests only')
  if (f.isBluebook === 'notBluebook') parts.push('Exclude active tests')
  if (f.cbVerifiedInactive === 'onlyVerifiedOffCBPracticeTests') parts.push('Extra official questions')
  if (f.questionLimit) parts.push(`Max ${f.questionLimit}`)
  return parts.length > 0 ? parts : ['All questions']
}

export function describeQuizFilters(f: FilterOptions): string {
  return quizFilterTags(f).join(' · ')
}
