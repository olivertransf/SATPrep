import type { QuestionProgress } from '../types'

const KEY = 'studium_progress'

export function loadProgress(): Record<string, QuestionProgress> {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return {}
    return JSON.parse(raw) as Record<string, QuestionProgress>
  } catch {
    return {}
  }
}

export function saveProgress(progress: Record<string, QuestionProgress>): void {
  localStorage.setItem(KEY, JSON.stringify(progress))
}

export function markSeen(
  progress: Record<string, QuestionProgress>,
  questionId: string
): Record<string, QuestionProgress> {
  const existing = progress[questionId] ?? { seen: false }
  return {
    ...progress,
    [questionId]: { ...existing, seen: true, lastAttempted: Date.now() },
  }
}

export function markAnswered(
  progress: Record<string, QuestionProgress>,
  questionId: string,
  correct: boolean
): Record<string, QuestionProgress> {
  const existing = progress[questionId] ?? { seen: false }
  return {
    ...progress,
    [questionId]: { ...existing, seen: true, correct, lastAttempted: Date.now() },
  }
}

export function resetAll(): Record<string, QuestionProgress> {
  localStorage.removeItem(KEY)
  return {}
}
