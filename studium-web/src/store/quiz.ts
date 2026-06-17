import type { SavedQuiz } from '../types'
import { tombstoneQuiz } from './deleted'
import { notifyLocalDataChanged } from '../lib/localDataEvents'

const KEY = 'studium_saved_quizzes'

export function loadAllQuizzes(): SavedQuiz[] {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return []
    return JSON.parse(raw) as SavedQuiz[]
  } catch {
    return []
  }
}

export function saveQuiz(quiz: SavedQuiz): void {
  const all = loadAllQuizzes().filter(q => q.id !== quiz.id)
  localStorage.setItem(KEY, JSON.stringify([quiz, ...all].slice(0, 10)))
  notifyLocalDataChanged()
}

export function deleteQuiz(id: string): void {
  tombstoneQuiz(id)
  const all = loadAllQuizzes().filter(q => q.id !== id)
  localStorage.setItem(KEY, JSON.stringify(all))
  notifyLocalDataChanged()
}

export function generateQuizId(): string {
  return `quiz_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`
}
