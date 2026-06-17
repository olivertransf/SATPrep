import type { QuestionProgress } from '../types'
import { loadDeletedProgress, tombstoneAllProgress, clearProgressTombstone } from './deleted'
import { notifyLocalDataChanged } from '../lib/localDataEvents'

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
  notifyLocalDataChanged()
}

export function markSeen(
  progress: Record<string, QuestionProgress>,
  questionId: string
): Record<string, QuestionProgress> {
  clearProgressTombstone(questionId)
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
  clearProgressTombstone(questionId)
  const existing = progress[questionId] ?? { seen: false }
  return {
    ...progress,
    [questionId]: { ...existing, seen: true, correct, lastAttempted: Date.now() },
  }
}

export function resetAll(): Record<string, QuestionProgress> {
  const existing = loadProgress()
  tombstoneAllProgress(existing)
  localStorage.removeItem(KEY)
  notifyLocalDataChanged()
  return {}
}

export function exportDeletedProgress(): Record<string, number> {
  return loadDeletedProgress()
}
