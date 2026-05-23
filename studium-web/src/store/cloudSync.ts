import type { QuestionProgress, SavedQuiz } from '../types'
import { supabase } from '../lib/supabase'
import { getSyncRowId } from '../lib/syncAuth'
import { loadProgress, saveProgress } from './progress'
import {
  type VocabBucketsPayload,
  loadVocabPayload,
  mergeVocabLWW,
  saveVocabPayload,
  wireBucketToWeb,
  webBucketToWire,
} from './vocabBuckets'
const DELETED_PROGRESS_KEY = 'studium_deleted_progress'
const QUIZZES_KEY = 'studium_saved_quizzes'
const DELETED_QUIZZES_KEY = 'studium_deleted_quizzes'

export interface StudiumSyncRow {
  id: string
  progress: Record<string, QuestionProgress>
  deleted_progress: Record<string, number>
  saved_quizzes: SavedQuiz[]
  deleted_quizzes: Record<string, number>
  vocab_buckets: VocabBucketsPayload | null
  updated_at: string
}

function loadDeletedProgress(): Record<string, number> {
  try {
    return JSON.parse(localStorage.getItem(DELETED_PROGRESS_KEY) ?? '{}') as Record<string, number>
  } catch {
    return {}
  }
}

function saveDeletedProgress(map: Record<string, number>) {
  localStorage.setItem(DELETED_PROGRESS_KEY, JSON.stringify(map))
}

function loadDeletedQuizzes(): Record<string, number> {
  try {
    return JSON.parse(localStorage.getItem(DELETED_QUIZZES_KEY) ?? '{}') as Record<string, number>
  } catch {
    return {}
  }
}

function saveDeletedQuizzes(map: Record<string, number>) {
  localStorage.setItem(DELETED_QUIZZES_KEY, JSON.stringify(map))
}


function loadQuizzes(): SavedQuiz[] {
  try {
    return JSON.parse(localStorage.getItem(QUIZZES_KEY) ?? '[]') as SavedQuiz[]
  } catch {
    return []
  }
}

function saveQuizzes(quizzes: SavedQuiz[]) {
  localStorage.setItem(QUIZZES_KEY, JSON.stringify(quizzes))
}

function progressTime(p: QuestionProgress): number {
  return p.lastAttempted ?? 0
}

function mergeProgress(
  local: Record<string, QuestionProgress>,
  remote: Record<string, QuestionProgress>,
  localDel: Record<string, number>,
  remoteDel: Record<string, number>,
): { progress: Record<string, QuestionProgress>; deleted: Record<string, number> } {
  const deleted: Record<string, number> = { ...localDel }
  for (const [id, t] of Object.entries(remoteDel)) {
    deleted[id] = Math.max(deleted[id] ?? 0, t)
  }

  const merged: Record<string, QuestionProgress> = {}
  const ids = new Set([...Object.keys(local), ...Object.keys(remote)])

  for (const id of ids) {
    const l = local[id]
    const r = remote[id]
    const delAt = deleted[id]

    if (l && delAt && progressTime(l) <= delAt && (!r || progressTime(r) <= delAt)) continue
    if (r && delAt && progressTime(r) <= delAt && (!l || progressTime(l) <= delAt)) continue

    if (!l) {
      if (r) merged[id] = r
      continue
    }
    if (!r) {
      merged[id] = l
      continue
    }
    merged[id] = progressTime(l) >= progressTime(r) ? l : r
  }

  return { progress: merged, deleted }
}

function mergeQuizzes(
  local: SavedQuiz[],
  remote: SavedQuiz[],
  localDel: Record<string, number>,
  remoteDel: Record<string, number>,
): { quizzes: SavedQuiz[]; deleted: Record<string, number> } {
  const deleted: Record<string, number> = { ...localDel }
  for (const [id, t] of Object.entries(remoteDel)) {
    deleted[id] = Math.max(deleted[id] ?? 0, t)
  }

  const byId = new Map<string, SavedQuiz>()
  for (const q of [...local, ...remote]) {
    const delAt = deleted[q.id]
    if (delAt && q.lastSaved <= delAt) continue

    const existing = byId.get(q.id)
    if (!existing || q.lastSaved > existing.lastSaved) {
      byId.set(q.id, q)
    }
  }

  return {
    quizzes: [...byId.values()].sort((a, b) => b.lastSaved - a.lastSaved).slice(0, 10),
    deleted,
  }
}

export function packLocalSnapshot(): Omit<StudiumSyncRow, 'id' | 'updated_at'> & {
  vocab_buckets: VocabBucketsPayload
} {
  return {
    progress: loadProgress(),
    deleted_progress: loadDeletedProgress(),
    saved_quizzes: loadQuizzes(),
    deleted_quizzes: loadDeletedQuizzes(),
    vocab_buckets: loadVocabPayload(),
  }
}

export function applyLocalSnapshot(row: Pick<StudiumSyncRow, 'progress' | 'deleted_progress' | 'saved_quizzes' | 'deleted_quizzes' | 'vocab_buckets'>) {
  saveProgress(row.progress)
  saveDeletedProgress(row.deleted_progress ?? {})
  saveQuizzes(row.saved_quizzes ?? [])
  saveDeletedQuizzes(row.deleted_quizzes ?? {})
  if (row.vocab_buckets) {
    const v = row.vocab_buckets as VocabBucketsPayload & Record<string, string>
    if (v.words || v.roots || v.wordTimestamps) {
      saveVocabPayload({
        words: v.words ?? {},
        roots: v.roots ?? {},
        wordTimestamps: v.wordTimestamps ?? {},
        rootTimestamps: v.rootTimestamps ?? {},
      })
    } else {
      const words: Record<string, string> = {}
      const wordTimestamps: Record<string, number> = {}
      const now = Date.now()
      for (const [id, bucket] of Object.entries(v as Record<string, string>)) {
        if (typeof bucket !== 'string') continue
        words[id] = webBucketToWire(bucket)
        wordTimestamps[id] = now
      }
      saveVocabPayload({ words, roots: {}, wordTimestamps, rootTimestamps: {} })
    }
  }
  window.dispatchEvent(new Event('studium-cloud-sync'))
}

export async function pullCloudSync(): Promise<{
  ok: boolean
  merged?: ReturnType<typeof packLocalSnapshot>
  error?: string
}> {
  if (!supabase) return { ok: false, error: 'Supabase not configured' }

  const rowId = await getSyncRowId()
  if (!rowId) return { ok: false, error: 'Not signed in to cloud sync' }

  const { data, error } = await supabase
    .from('studium_sync')
    .select('*')
    .eq('id', rowId)
    .maybeSingle()

  if (error) return { ok: false, error: error.message }

  const local = packLocalSnapshot()

  if (!data) {
    await pushCloudSync(local)
    return { ok: true, merged: local }
  }

  const remote = data as StudiumSyncRow
  const { progress, deleted: deletedProgress } = mergeProgress(
    local.progress,
    remote.progress ?? {},
    local.deleted_progress,
    remote.deleted_progress ?? {},
  )
  const { quizzes, deleted: deletedQuizzes } = mergeQuizzes(
    local.saved_quizzes,
    (remote.saved_quizzes ?? []) as SavedQuiz[],
    local.deleted_quizzes,
    remote.deleted_quizzes ?? {},
  )

  const merged = {
    progress,
    deleted_progress: deletedProgress,
    saved_quizzes: quizzes,
    deleted_quizzes: deletedQuizzes,
    vocab_buckets: mergeVocabLWW(
      local.vocab_buckets,
      normalizeRemoteVocab(remote.vocab_buckets),
    ),
  }

  applyLocalSnapshot(merged)
  await pushCloudSync(merged)

  return { ok: true, merged }
}

export async function pushCloudSync(snapshot = packLocalSnapshot()): Promise<{ ok: boolean; error?: string }> {
  if (!supabase) return { ok: false, error: 'Supabase not configured' }

  const rowId = await getSyncRowId()
  if (!rowId) return { ok: false, error: 'Not signed in to cloud sync' }

  const { error } = await supabase.from('studium_sync').upsert({
    id: rowId,
    progress: snapshot.progress,
    deleted_progress: snapshot.deleted_progress,
    saved_quizzes: snapshot.saved_quizzes,
    deleted_quizzes: snapshot.deleted_quizzes,
    vocab_buckets: snapshot.vocab_buckets,
    updated_at: new Date().toISOString(),
  })

  if (error) return { ok: false, error: error.message }
  return { ok: true }
}

let pushTimer: ReturnType<typeof setTimeout> | null = null

export function scheduleCloudPush(delayMs = 2500) {
  if (pushTimer) clearTimeout(pushTimer)
  pushTimer = setTimeout(() => {
    pushTimer = null
    void pushCloudSync()
  }, delayMs)
}

export function flushCloudPush(): Promise<{ ok: boolean; error?: string }> {
  if (pushTimer) {
    clearTimeout(pushTimer)
    pushTimer = null
  }
  return pushCloudSync()
}

function normalizeRemoteVocab(
  remote: StudiumSyncRow['vocab_buckets'],
): VocabBucketsPayload {
  if (!remote) return { words: {}, roots: {} }
  const v = remote as VocabBucketsPayload & Record<string, string>
  if (v.words || v.roots || v.wordTimestamps) {
    return {
      words: v.words ?? {},
      roots: v.roots ?? {},
      wordTimestamps: v.wordTimestamps ?? {},
      rootTimestamps: v.rootTimestamps ?? {},
    }
  }
  const words: Record<string, string> = {}
  for (const [id, bucket] of Object.entries(v as Record<string, string>)) {
    if (typeof bucket !== 'string') continue
    words[id] = webBucketToWire(bucket)
  }
  return { words, roots: {} }
}

export { wireBucketToWeb }
