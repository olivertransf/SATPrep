const DELETED_PROGRESS_KEY = 'studium_deleted_progress'
const DELETED_QUIZZES_KEY = 'studium_deleted_quizzes'

export function loadDeletedProgress(): Record<string, number> {
  try {
    return JSON.parse(localStorage.getItem(DELETED_PROGRESS_KEY) ?? '{}') as Record<string, number>
  } catch {
    return {}
  }
}

export function saveDeletedProgress(map: Record<string, number>) {
  localStorage.setItem(DELETED_PROGRESS_KEY, JSON.stringify(map))
}

export function loadDeletedQuizzes(): Record<string, number> {
  try {
    return JSON.parse(localStorage.getItem(DELETED_QUIZZES_KEY) ?? '{}') as Record<string, number>
  } catch {
    return {}
  }
}

export function saveDeletedQuizzes(map: Record<string, number>) {
  localStorage.setItem(DELETED_QUIZZES_KEY, JSON.stringify(map))
}

export function tombstoneAllProgress(progress: Record<string, unknown>): Record<string, number> {
  const deleted = loadDeletedProgress()
  const now = Date.now()
  for (const id of Object.keys(progress)) {
    deleted[id] = Math.max(deleted[id] ?? 0, now)
  }
  saveDeletedProgress(deleted)
  return deleted
}

export function tombstoneAllQuizzes(quizzes: { id: string }[]): Record<string, number> {
  const deleted = loadDeletedQuizzes()
  const now = Date.now()
  for (const q of quizzes) {
    deleted[q.id] = Math.max(deleted[q.id] ?? 0, now)
  }
  saveDeletedQuizzes(deleted)
  return deleted
}

export function tombstoneQuiz(id: string) {
  const deleted = loadDeletedQuizzes()
  deleted[id] = Date.now()
  saveDeletedQuizzes(deleted)
}
