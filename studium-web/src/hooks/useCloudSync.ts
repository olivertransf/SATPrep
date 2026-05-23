import { useCallback, useEffect, useState } from 'react'
import type { QuestionProgress, SavedQuiz } from '../types'
import {
  emailAuthConfigured,
  gatePasswordConfigured,
  getSyncAuthMode,
  isCloudSyncActive,
  signOutCloudSync,
  unlockCloudSync,
} from '../lib/syncAuth'
import { isSupabaseConfigured, supabase } from '../lib/supabase'
import { flushCloudPush, pullCloudSync, scheduleCloudPush } from '../store/cloudSync'

export interface CloudSyncMerged {
  progress: Record<string, QuestionProgress>
  savedQuizzes: SavedQuiz[]
}

interface UseCloudSyncOptions {
  onMerged: (data: CloudSyncMerged) => void
  enabled: boolean
}

export function useCloudSync({ onMerged, enabled }: UseCloudSyncOptions) {
  const [active, setActive] = useState(false)
  const [syncing, setSyncing] = useState(false)
  const [lastError, setLastError] = useState<string | null>(null)
  const [lastSyncedAt, setLastSyncedAt] = useState<number | null>(null)

  const configured = isSupabaseConfigured()
  const canUseGate = gatePasswordConfigured()
  const canUseEmail = emailAuthConfigured()

  const refreshActive = useCallback(async () => {
    setActive(await isCloudSyncActive())
  }, [])

  useEffect(() => {
    void refreshActive()
    if (!configured) return

    if (!supabase) return
    const { data: { subscription } } = supabase.auth.onAuthStateChange(() => {
      void refreshActive()
    })
    return () => subscription.unsubscribe()
  }, [configured, refreshActive])

  useEffect(() => {
    if (!enabled || !configured) return
    let cancelled = false

    void (async () => {
      if (!(await isCloudSyncActive())) return
      setSyncing(true)
      setLastError(null)
      const result = await pullCloudSync()
      if (cancelled) return
      setSyncing(false)
      if (result.ok && result.merged) {
        setLastSyncedAt(Date.now())
        onMerged({
          progress: result.merged.progress,
          savedQuizzes: result.merged.saved_quizzes,
        })
      } else if (result.error) {
        setLastError(result.error)
      }
      await refreshActive()
    })()

    return () => {
      cancelled = true
    }
  }, [enabled, configured, onMerged, refreshActive])

  useEffect(() => {
    if (!enabled || !configured) return

    const pullOnFocus = () => {
      if (document.visibilityState !== 'visible') return
      void (async () => {
        if (!(await isCloudSyncActive())) return
        setSyncing(true)
        setLastError(null)
        const result = await pullCloudSync()
        setSyncing(false)
        if (result.ok && result.merged) {
          setLastSyncedAt(Date.now())
          onMerged({
            progress: result.merged.progress,
            savedQuizzes: result.merged.saved_quizzes,
          })
        } else if (result.error) {
          setLastError(result.error)
        }
      })()
    }

    document.addEventListener('visibilitychange', pullOnFocus)
    window.addEventListener('focus', pullOnFocus)
    const flush = () => {
      void isCloudSyncActive().then(ok => {
        if (ok) void flushCloudPush()
      })
    }
    window.addEventListener('pagehide', flush)

    return () => {
      document.removeEventListener('visibilitychange', pullOnFocus)
      window.removeEventListener('focus', pullOnFocus)
      window.removeEventListener('pagehide', flush)
    }
  }, [enabled, configured, onMerged])

  const unlock = useCallback(async (password: string) => {
    setSyncing(true)
    setLastError(null)
    const result = await unlockCloudSync(password)
    if (!result.ok) {
      setSyncing(false)
      setLastError(result.error ?? 'Unlock failed')
      return false
    }
    setActive(true)
    const pull = await pullCloudSync()
    setSyncing(false)
    if (pull.ok && pull.merged) {
      setLastSyncedAt(Date.now())
      onMerged({
        progress: pull.merged.progress,
        savedQuizzes: pull.merged.saved_quizzes,
      })
    } else if (pull.error) {
      setLastError(pull.error)
    }
    return true
  }, [onMerged])

  const syncNow = useCallback(async () => {
    if (!(await isCloudSyncActive())) return false
    setSyncing(true)
    setLastError(null)
    const result = await pullCloudSync()
    setSyncing(false)
    if (result.ok && result.merged) {
      setLastSyncedAt(Date.now())
      onMerged({
        progress: result.merged.progress,
        savedQuizzes: result.merged.saved_quizzes,
      })
      return true
    }
    setLastError(result.error ?? 'Sync failed')
    return false
  }, [onMerged])

  const signOut = useCallback(async () => {
    await signOutCloudSync()
    setActive(false)
    setLastSyncedAt(null)
  }, [])

  const notifyLocalChange = useCallback(() => {
    void isCloudSyncActive().then(ok => {
      if (ok) scheduleCloudPush()
    })
  }, [])

  return {
    configured,
    canUseGate,
    canUseEmail,
    active,
    syncing,
    lastError,
    lastSyncedAt,
    authMode: getSyncAuthMode,
    unlock,
    syncNow,
    signOut,
    notifyLocalChange,
    refreshActive,
  }
}
