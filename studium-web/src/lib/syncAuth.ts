import { supabase } from './supabase'

export const SYNC_UNLOCK_KEY = 'studium_sync_gate_unlocked'

export type SyncAuthMode = 'auth' | 'gate' | null

export function gatePasswordConfigured(): boolean {
  const gate = import.meta.env.VITE_SYNC_GATE_PASSWORD
  return typeof gate === 'string' && gate.length > 0
}

export function emailAuthConfigured(): boolean {
  const email = import.meta.env.VITE_SYNC_EMAIL
  return typeof email === 'string' && email.trim().length > 0
}

export async function getSyncAuthMode(): Promise<SyncAuthMode> {
  if (!supabase) return null
  const { data: { session } } = await supabase.auth.getSession()
  if (session?.user) return 'auth'
  if (localStorage.getItem(SYNC_UNLOCK_KEY) === '1' && gatePasswordConfigured()) return 'gate'
  return null
}

export async function getSyncRowId(): Promise<string | null> {
  if (!supabase) return null
  const { data: { session } } = await supabase.auth.getSession()
  if (session?.user?.id) return session.user.id
  if (localStorage.getItem(SYNC_UNLOCK_KEY) === '1') return 'default'
  return null
}

export async function isCloudSyncActive(): Promise<boolean> {
  return (await getSyncRowId()) !== null
}

/** Password field unlocks Supabase Auth (email in env) or gate row (env gate password). */
export async function unlockCloudSync(password: string): Promise<{ ok: boolean; error?: string }> {
  if (!supabase) {
    return { ok: false, error: 'Supabase is not configured (.env.local)' }
  }

  const email = import.meta.env.VITE_SYNC_EMAIL?.trim()
  if (email) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) return { ok: false, error: error.message }
    localStorage.removeItem(SYNC_UNLOCK_KEY)
    return { ok: true }
  }

  const gate = import.meta.env.VITE_SYNC_GATE_PASSWORD
  if (!gate) {
    return { ok: false, error: 'Set VITE_SYNC_EMAIL or VITE_SYNC_GATE_PASSWORD in .env.local' }
  }
  if (password !== gate) {
    return { ok: false, error: 'Wrong password' }
  }
  localStorage.setItem(SYNC_UNLOCK_KEY, '1')
  return { ok: true }
}

export async function signOutCloudSync(): Promise<void> {
  localStorage.removeItem(SYNC_UNLOCK_KEY)
  if (supabase) await supabase.auth.signOut()
}
