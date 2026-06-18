import type { Question, QuestionProgress } from '../types'

export function moduleDisplayName(module: string) {
  return module.toLowerCase() === 'english' ? 'Reading & Writing' : 'Math'
}

export function getProgressSummary(
  questions: Question[],
  progress: Record<string, QuestionProgress>,
) {
  const total = questions.length
  const seen = questions.filter(q => progress[q.questionId]?.seen).length
  const answered = questions.filter(q => progress[q.questionId]?.correct !== undefined).length
  const correct = questions.filter(q => progress[q.questionId]?.correct === true).length
  const accuracy = answered > 0 ? Math.round((correct / answered) * 100) : null
  return { total, seen, answered, correct, accuracy }
}

export interface ModuleBreakdown {
  module: string
  label: string
  total: number
  answered: number
  correct: number
  accuracy: number
  accent: string
}

export function getModuleBreakdown(
  questions: Question[],
  progress: Record<string, QuestionProgress>,
): ModuleBreakdown[] {
  const modules = [...new Set(questions.map(q => q.module))]
  return modules.map(module => {
    const qs = questions.filter(q => q.module === module)
    const answeredQs = qs.filter(q => progress[q.questionId]?.correct !== undefined)
    const correctQs = qs.filter(q => progress[q.questionId]?.correct === true)
    return {
      module,
      label: moduleDisplayName(module),
      total: qs.length,
      answered: answeredQs.length,
      correct: correctQs.length,
      accuracy: answeredQs.length > 0 ? Math.round((correctQs.length / answeredQs.length) * 100) : 0,
      accent: module.toLowerCase() === 'english' ? 'var(--rw)' : 'var(--math)',
    }
  })
}

export interface DifficultyBreakdown {
  difficulty: 'E' | 'M' | 'H'
  label: string
  total: number
  answered: number
  correct: number
  accuracy: number
  accent: string
}

export function getDifficultyBreakdown(
  questions: Question[],
  progress: Record<string, QuestionProgress>,
): DifficultyBreakdown[] {
  const difficulties = ['E', 'M', 'H'] as const
  return difficulties.map(difficulty => {
    const qs = questions.filter(q => q.difficulty === difficulty)
    const answeredQs = qs.filter(q => progress[q.questionId]?.correct !== undefined)
    const correctQs = qs.filter(q => progress[q.questionId]?.correct === true)
    return {
      difficulty,
      label: difficulty === 'E' ? 'Easy' : difficulty === 'M' ? 'Medium' : 'Hard',
      accent: difficulty === 'E' ? 'var(--success)' : difficulty === 'M' ? 'var(--warning)' : 'var(--error)',
      total: qs.length,
      answered: answeredQs.length,
      correct: correctQs.length,
      accuracy: answeredQs.length > 0 ? Math.round((correctQs.length / answeredQs.length) * 100) : 0,
    }
  })
}
