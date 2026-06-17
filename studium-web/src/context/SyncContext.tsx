import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { useAuth } from './AuthContext'
import {
  cancelScheduledPush,
  flushStudiumSync,
  pullAndMerge,
  scheduleStudiumSync,
  setSyncUid,
  subscribeSyncState,
} from '../lib/studiumSync'
import type { SyncStatus } from '../lib/syncTypes'

interface SyncContextValue {
  status: SyncStatus
  lastSyncedAt: number | null
  error: string | null
  syncNow: () => Promise<void>
  canSync: boolean
}

const SyncContext = createContext<SyncContextValue | null>(null)

export function SyncProvider({ children }: { children: ReactNode }) {
  const { user, configured } = useAuth()
  const [status, setStatus] = useState<SyncStatus>('idle')
  const [lastSyncedAt, setLastSyncedAt] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)

  const canSync = configured && Boolean(user)

  useEffect(() => subscribeSyncState(s => {
    setStatus(s.status)
    setLastSyncedAt(s.lastSyncedAt)
    setError(s.error)
  }), [])

  useEffect(() => {
    if (!user) {
      setSyncUid(null)
      cancelScheduledPush()
      return
    }

    const uid = user.uid
    setSyncUid(uid)
    void pullAndMerge(uid).catch(() => undefined)

    function onVisible() {
      if (document.visibilityState === 'visible') {
        void pullAndMerge(uid).catch(() => undefined)
      }
    }

    function onFocus() {
      void pullAndMerge(uid).catch(() => undefined)
    }

    function onPageHide() {
      void flushStudiumSync()
    }

    document.addEventListener('visibilitychange', onVisible)
    window.addEventListener('focus', onFocus)
    window.addEventListener('pagehide', onPageHide)

    return () => {
      setSyncUid(null)
      cancelScheduledPush()
      document.removeEventListener('visibilitychange', onVisible)
      window.removeEventListener('focus', onFocus)
      window.removeEventListener('pagehide', onPageHide)
    }
  }, [user])

  useEffect(() => {
    if (!user) return

    function onDataChange(e: Event) {
      const detail = (e as CustomEvent<{ fromSync?: boolean }>).detail
      if (detail?.fromSync) return
      scheduleStudiumSync()
    }

    window.addEventListener('studium-local-data-change', onDataChange)
    return () => window.removeEventListener('studium-local-data-change', onDataChange)
  }, [user])

  const syncNow = useCallback(async () => {
    if (!user) return
    await flushStudiumSync()
  }, [user])

  const value = useMemo<SyncContextValue>(() => ({
    status,
    lastSyncedAt,
    error,
    syncNow,
    canSync,
  }), [status, lastSyncedAt, error, syncNow, canSync])

  return <SyncContext.Provider value={value}>{children}</SyncContext.Provider>
}

export function useSync(): SyncContextValue {
  const ctx = useContext(SyncContext)
  if (!ctx) throw new Error('useSync must be used within SyncProvider')
  return ctx
}
