import { notifyLocalDataChanged } from '../lib/localDataEvents'

export type WebVocabBucket = 'learn' | 'review' | 'mastered'

export type VocabBucketsPayload = {
  words: Record<string, string>
  roots: Record<string, string>
  wordTimestamps?: Record<string, number>
  rootTimestamps?: Record<string, number>
}

const VOCAB_KEY = 'studium_vocab_buckets'

/** Native app uses `known`; web UI uses `mastered`. */
export function wireBucketToWeb(value: string): WebVocabBucket {
  if (value === 'known') return 'mastered'
  if (value === 'review') return 'review'
  return 'learn'
}

export function webBucketToWire(value: string): string {
  if (value === 'mastered') return 'known'
  return value
}

export function loadVocabPayload(): VocabBucketsPayload {
  try {
    const raw = JSON.parse(localStorage.getItem(VOCAB_KEY) ?? '{}') as VocabBucketsPayload & Record<string, string>
    if (raw && typeof raw === 'object' && ('words' in raw || 'roots' in raw)) {
      return {
        words: raw.words ?? {},
        roots: raw.roots ?? {},
        wordTimestamps: raw.wordTimestamps ?? {},
        rootTimestamps: raw.rootTimestamps ?? {},
      }
    }
    const flat = (raw as Record<string, string>) ?? {}
    const words: Record<string, string> = {}
    for (const [id, bucket] of Object.entries(flat)) {
      words[id] = webBucketToWire(bucket)
    }
    return { words, roots: {}, wordTimestamps: {}, rootTimestamps: {} }
  } catch {
    return { words: {}, roots: {}, wordTimestamps: {}, rootTimestamps: {} }
  }
}

export function saveVocabPayload(payload: VocabBucketsPayload) {
  localStorage.setItem(VOCAB_KEY, JSON.stringify(payload))
  notifyLocalDataChanged()
}

export function loadWordBucketsForUI(): Record<string, WebVocabBucket> {
  const { words } = loadVocabPayload()
  const out: Record<string, WebVocabBucket> = {}
  for (const [id, bucket] of Object.entries(words)) {
    out[id] = wireBucketToWeb(bucket)
  }
  return out
}

export function saveWordBucketsFromUI(buckets: Record<string, WebVocabBucket>) {
  const current = loadVocabPayload()
  const words: Record<string, string> = {}
  const wordTimestamps = { ...(current.wordTimestamps ?? {}) }
  const now = Date.now()
  for (const [id, bucket] of Object.entries(buckets)) {
    const wire = webBucketToWire(bucket)
    if (wire === 'learn') {
      delete words[id]
      delete wordTimestamps[id]
    } else {
      words[id] = wire
      wordTimestamps[id] = now
    }
  }
  saveVocabPayload({ ...current, words, wordTimestamps })
}

export function mergeVocabLWW(
  local: VocabBucketsPayload,
  remote: VocabBucketsPayload,
): VocabBucketsPayload {
  const mergeMaps = (
    localBuckets: Record<string, string>,
    localTs: Record<string, number>,
    remoteBuckets: Record<string, string>,
    remoteTs: Record<string, number>,
  ) => {
    const buckets = { ...localBuckets }
    const timestamps = { ...localTs }
    for (const [id, remoteTime] of Object.entries(remoteTs)) {
      const localTime = timestamps[id] ?? 0
      if (remoteTime > localTime) {
        timestamps[id] = remoteTime
        const bucket = remoteBuckets[id]
        if (bucket) buckets[id] = bucket
        else delete buckets[id]
      }
    }
    return { buckets, timestamps }
  }

  const words = mergeMaps(
    local.words,
    local.wordTimestamps ?? {},
    remote.words ?? {},
    remote.wordTimestamps ?? {},
  )
  const roots = mergeMaps(
    local.roots,
    local.rootTimestamps ?? {},
    remote.roots ?? {},
    remote.rootTimestamps ?? {},
  )

  return {
    words: words.buckets,
    roots: roots.buckets,
    wordTimestamps: words.timestamps,
    rootTimestamps: roots.timestamps,
  }
}
