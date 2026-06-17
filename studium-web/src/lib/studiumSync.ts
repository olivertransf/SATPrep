import { doc, getDoc, setDoc } from 'firebase/firestore'
import { db } from './firebase'
import { mergeSyncPayloads } from './mergeSync'
import { EMPTY_SYNC_PAYLOAD, type StudiumSyncPayload, type SyncStatus } from './syncTypes'
export type { SyncStatus } from './syncTypes'
import { notifyLocalDataFromSync, notifySyncApplied } from './localDataEvents'
import { loadProgress } from '../store/progress'
import { loadDeletedProgress, loadDeletedQuizzes } from '../store/deleted'
import { loadAllQuizzes } from '../store/quiz'
import { loadVocabPayload } from '../store/vocabBuckets'

const DEBOUNCE_MS = 2500
const SYNC_DOC_ID = 'data'
const PROGRESS_KEY = 'studium_progress'
const QUIZZES_KEY = 'studium_saved_quizzes'
const VOCAB_KEY = 'studium_vocab_buckets'
const DELETED_PROGRESS_KEY = 'studium_deleted_progress'
const DELETED_QUIZZES_KEY = 'studium_deleted_quizzes'

let activeUid: string | null = null
let pushTimer: ReturnType<typeof setTimeout> | null = null
let pushInFlight = false
let pullInFlight = false
let applyingRemote = false

type SyncListener = (state: { status: SyncStatus; lastSyncedAt: number | null; error: string | null }) => void
const listeners = new Set<SyncListener>()

let syncState: { status: SyncStatus; lastSyncedAt: number | null; error: string | null } = {
  status: 'idle',
  lastSyncedAt: null,
  error: null,
}

function emitState(patch: Partial<typeof syncState>) {
  syncState = { ...syncState, ...patch }
  for (const fn of listeners) fn(syncState)
}

export function subscribeSyncState(fn: SyncListener): () => void {
  listeners.add(fn)
  fn(syncState)
  return () => listeners.delete(fn)
}

export function getSyncState() {
  return syncState
}

export function setSyncUid(uid: string | null) {
  activeUid = uid
  if (!uid) {
    cancelScheduledPush()
    emitState({ status: 'idle', error: null })
  }
}

function syncDocRef(uid: string) {
  if (!db) throw new Error('Firestore not configured')
  return doc(db, 'users', uid, 'sync', SYNC_DOC_ID)
}

export function loadLocalSyncPayload(): StudiumSyncPayload {
  return {
    progress: loadProgress(),
    deletedProgress: loadDeletedProgress(),
    savedQuizzes: loadAllQuizzes(),
    deletedQuizzes: loadDeletedQuizzes(),
    vocabBuckets: loadVocabPayload(),
    clientUpdatedAt: Date.now(),
  }
}

export function applySyncPayloadToLocal(payload: StudiumSyncPayload): void {
  applyingRemote = true
  try {
    localStorage.setItem(PROGRESS_KEY, JSON.stringify(payload.progress))
    localStorage.setItem(DELETED_PROGRESS_KEY, JSON.stringify(payload.deletedProgress))
    localStorage.setItem(QUIZZES_KEY, JSON.stringify(payload.savedQuizzes))
    localStorage.setItem(DELETED_QUIZZES_KEY, JSON.stringify(payload.deletedQuizzes))
    localStorage.setItem(VOCAB_KEY, JSON.stringify(payload.vocabBuckets))
    notifyLocalDataFromSync()
    notifySyncApplied()
  } finally {
    applyingRemote = false
  }
}

function payloadForFirestore(payload: StudiumSyncPayload) {
  return {
    progress: payload.progress,
    deletedProgress: payload.deletedProgress,
    savedQuizzes: payload.savedQuizzes,
    deletedQuizzes: payload.deletedQuizzes,
    vocabBuckets: payload.vocabBuckets,
    clientUpdatedAt: payload.clientUpdatedAt,
  }
}

function parseRemotePayload(raw: Record<string, unknown>): StudiumSyncPayload {
  const base = EMPTY_SYNC_PAYLOAD()
  return {
    progress: (raw.progress as StudiumSyncPayload['progress']) ?? base.progress,
    deletedProgress: (raw.deletedProgress as StudiumSyncPayload['deletedProgress']) ?? base.deletedProgress,
    savedQuizzes: (raw.savedQuizzes as StudiumSyncPayload['savedQuizzes']) ?? base.savedQuizzes,
    deletedQuizzes: (raw.deletedQuizzes as StudiumSyncPayload['deletedQuizzes']) ?? base.deletedQuizzes,
    vocabBuckets: (raw.vocabBuckets as StudiumSyncPayload['vocabBuckets']) ?? base.vocabBuckets,
    clientUpdatedAt: typeof raw.clientUpdatedAt === 'number' ? raw.clientUpdatedAt : 0,
  }
}

export async function pullRemotePayload(uid: string): Promise<StudiumSyncPayload | null> {
  const snap = await getDoc(syncDocRef(uid))
  if (!snap.exists()) return null
  return parseRemotePayload(snap.data() as Record<string, unknown>)
}

export async function pushLocalPayload(uid: string, payload?: StudiumSyncPayload): Promise<void> {
  const body = payload ?? loadLocalSyncPayload()
  body.clientUpdatedAt = Date.now()
  await setDoc(syncDocRef(uid), payloadForFirestore(body))
}

export async function pullAndMerge(uid: string): Promise<StudiumSyncPayload> {
  if (pullInFlight) return loadLocalSyncPayload()
  pullInFlight = true
  if (!navigator.onLine) {
    emitState({ status: 'offline', error: null })
    pullInFlight = false
    return loadLocalSyncPayload()
  }

  emitState({ status: 'syncing', error: null })
  try {
    const local = loadLocalSyncPayload()
    const remote = await pullRemotePayload(uid)
    const merged = remote ? mergeSyncPayloads(local, remote) : local
    applySyncPayloadToLocal(merged)

    if (merged.clientUpdatedAt > (remote?.clientUpdatedAt ?? 0)) {
      await pushLocalPayload(uid, merged)
    }

    emitState({ status: 'synced', lastSyncedAt: Date.now(), error: null })
    return merged
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Sync failed'
    emitState({ status: 'error', error: message })
    throw e
  } finally {
    pullInFlight = false
  }
}

export function cancelScheduledPush() {
  if (pushTimer) {
    clearTimeout(pushTimer)
    pushTimer = null
  }
}

export function scheduleStudiumSync() {
  if (applyingRemote || !activeUid) return
  cancelScheduledPush()
  pushTimer = setTimeout(() => {
    pushTimer = null
    void flushStudiumSync()
  }, DEBOUNCE_MS)
}

export async function flushStudiumSync(): Promise<void> {
  const uid = activeUid
  if (!uid || pushInFlight) return
  if (!navigator.onLine) {
    emitState({ status: 'offline', error: null })
    return
  }

  pushInFlight = true
  emitState({ status: 'syncing', error: null })
  try {
    const local = loadLocalSyncPayload()
    const remote = await pullRemotePayload(uid)
    const merged = remote ? mergeSyncPayloads(local, remote) : local
    applySyncPayloadToLocal(merged)
    await pushLocalPayload(uid, merged)
    emitState({ status: 'synced', lastSyncedAt: Date.now(), error: null })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Sync failed'
    emitState({ status: 'error', error: message })
  } finally {
    pushInFlight = false
  }
}
