import type { QuestionProgress, QuestionAnswerState, SavedQuiz } from '../types'
import { mergeVocabLWW } from '../store/vocabBuckets'
import type { StudiumSyncPayload } from './syncTypes'

function progressTime(p: QuestionProgress | undefined): number {
  return p?.lastAttempted ?? 0
}

function pickProgress(a: QuestionProgress, b: QuestionProgress): QuestionProgress {
  const at = progressTime(a)
  const bt = progressTime(b)
  if (at > bt) return a
  if (bt > at) return b
  if (a.correct !== undefined && b.correct === undefined) return a
  if (b.correct !== undefined && a.correct === undefined) return b
  return a
}

export function mergeProgressMaps(
  local: Record<string, QuestionProgress>,
  remote: Record<string, QuestionProgress>,
  deletedLocal: Record<string, number>,
  deletedRemote: Record<string, number>,
): { progress: Record<string, QuestionProgress>; deletedProgress: Record<string, number> } {
  const deletedProgress: Record<string, number> = { ...deletedLocal }
  for (const [id, t] of Object.entries(deletedRemote)) {
    deletedProgress[id] = Math.max(deletedProgress[id] ?? 0, t)
  }

  const progress: Record<string, QuestionProgress> = {}
  const ids = new Set([...Object.keys(local), ...Object.keys(remote)])

  for (const id of ids) {
    const lp = local[id]
    const rp = remote[id]
    const maxAttempt = Math.max(progressTime(lp), progressTime(rp))
    const tomb = deletedProgress[id] ?? 0

    if (tomb > 0 && tomb >= maxAttempt) continue

    const winner = lp && rp ? pickProgress(lp, rp) : (lp ?? rp)
    if (!winner) continue

    progress[id] = winner
    if (maxAttempt > tomb) delete deletedProgress[id]
  }

  return { progress, deletedProgress }
}

function mergeAnswerStates(
  a: Record<string, QuestionAnswerState>,
  b: Record<string, QuestionAnswerState>,
): Record<string, QuestionAnswerState> {
  const out: Record<string, QuestionAnswerState> = { ...a }
  for (const [qid, remote] of Object.entries(b)) {
    const local = out[qid]
    if (!local) {
      out[qid] = remote
      continue
    }
    if (remote.hasSubmitted && !local.hasSubmitted) {
      out[qid] = remote
      continue
    }
    if (local.hasSubmitted && remote.hasSubmitted) {
      out[qid] = local.isCorrect !== undefined ? local : remote
    }
  }
  return out
}

function mergeTwoQuizzes(a: SavedQuiz, b: SavedQuiz): SavedQuiz {
  const [winner, loser] = a.lastSaved >= b.lastSaved ? [a, b] : [b, a]
  return {
    ...winner,
    answerStates: mergeAnswerStates(winner.answerStates, loser.answerStates),
  }
}

export function mergeQuizLists(
  local: SavedQuiz[],
  remote: SavedQuiz[],
  deletedLocal: Record<string, number>,
  deletedRemote: Record<string, number>,
): { savedQuizzes: SavedQuiz[]; deletedQuizzes: Record<string, number> } {
  const deletedQuizzes: Record<string, number> = { ...deletedLocal }
  for (const [id, t] of Object.entries(deletedRemote)) {
    deletedQuizzes[id] = Math.max(deletedQuizzes[id] ?? 0, t)
  }

  const byId = new Map<string, SavedQuiz>()
  for (const quiz of [...local, ...remote]) {
    const tomb = deletedQuizzes[quiz.id] ?? 0
    if (tomb > quiz.lastSaved) continue

    const existing = byId.get(quiz.id)
    byId.set(quiz.id, existing ? mergeTwoQuizzes(existing, quiz) : quiz)
  }

  const savedQuizzes = [...byId.values()]
    .sort((x, y) => y.lastSaved - x.lastSaved)
    .slice(0, 10)

  return { savedQuizzes, deletedQuizzes }
}

export function mergeSyncPayloads(local: StudiumSyncPayload, remote: StudiumSyncPayload): StudiumSyncPayload {
  const { progress, deletedProgress } = mergeProgressMaps(
    local.progress,
    remote.progress,
    local.deletedProgress,
    remote.deletedProgress,
  )
  const { savedQuizzes, deletedQuizzes } = mergeQuizLists(
    local.savedQuizzes,
    remote.savedQuizzes,
    local.deletedQuizzes,
    remote.deletedQuizzes,
  )
  const vocabBuckets = mergeVocabLWW(local.vocabBuckets, remote.vocabBuckets)

  return {
    progress,
    deletedProgress,
    savedQuizzes,
    deletedQuizzes,
    vocabBuckets,
    clientUpdatedAt: Math.max(local.clientUpdatedAt, remote.clientUpdatedAt, Date.now()),
  }
}
