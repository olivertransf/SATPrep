import type { QuestionProgress, SavedQuiz } from '../types'
import type { VocabBucketsPayload } from '../store/vocabBuckets'

export interface StudiumSyncPayload {
  progress: Record<string, QuestionProgress>
  deletedProgress: Record<string, number>
  savedQuizzes: SavedQuiz[]
  deletedQuizzes: Record<string, number>
  vocabBuckets: VocabBucketsPayload
  clientUpdatedAt: number
}

export type SyncStatus = 'idle' | 'syncing' | 'synced' | 'error' | 'offline'

export const EMPTY_SYNC_PAYLOAD = (): StudiumSyncPayload => ({
  progress: {},
  deletedProgress: {},
  savedQuizzes: [],
  deletedQuizzes: {},
  vocabBuckets: { words: {}, roots: {}, wordTimestamps: {}, rootTimestamps: {} },
  clientUpdatedAt: 0,
})
