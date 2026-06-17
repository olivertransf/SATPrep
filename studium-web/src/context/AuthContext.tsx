import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signOut as firebaseSignOut,
  type User,
} from 'firebase/auth'
import { auth, isFirebaseConfigured } from '../lib/firebase'
import { upsertUserProfile } from '../lib/userProfile'

interface AuthContextValue {
  user: User | null
  loading: boolean
  configured: boolean
  error: string | null
  signInWithGoogle: () => Promise<void>
  signOut: () => Promise<void>
  clearError: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

const googleProvider = new GoogleAuthProvider()
googleProvider.setCustomParameters({ prompt: 'select_account' })

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(isFirebaseConfigured())
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!auth) {
      setLoading(false)
      return
    }

    return onAuthStateChanged(auth, u => {
      void (async () => {
        if (u) {
          try {
            await upsertUserProfile(u)
          } catch (e) {
            console.error('Failed to update user profile', e)
          }
        }
        setUser(u)
        setLoading(false)
      })()
    })
  }, [])

  const signInWithGoogle = useCallback(async () => {
    if (!auth) {
      setError('Sign-in is not configured.')
      return
    }
    setError(null)
    try {
      await signInWithPopup(auth, googleProvider)
    } catch (e) {
      const code = (e as { code?: string }).code
      if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') {
        return
      }
      setError(e instanceof Error ? e.message : 'Could not sign in with Google.')
    }
  }, [])

  const signOut = useCallback(async () => {
    if (!auth) return
    setError(null)
    await firebaseSignOut(auth)
  }, [])

  const clearError = useCallback(() => setError(null), [])

  const value = useMemo<AuthContextValue>(() => ({
    user,
    loading,
    configured: isFirebaseConfigured(),
    error,
    signInWithGoogle,
    signOut,
    clearError,
  }), [user, loading, error, signInWithGoogle, signOut, clearError])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return ctx
}
