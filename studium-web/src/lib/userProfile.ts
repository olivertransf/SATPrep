import type { User } from 'firebase/auth'
import { doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore'
import { db } from './firebase'

export interface StudiumUserProfile {
  email: string | null
  displayName: string | null
  photoURL: string | null
  createdAt?: unknown
  updatedAt?: unknown
  lastSignInAt?: unknown
}

export async function upsertUserProfile(user: User): Promise<void> {
  if (!db) return

  const ref = doc(db, 'users', user.uid)
  const snap = await getDoc(ref)
  const now = serverTimestamp()
  const fields = {
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
    updatedAt: now,
    lastSignInAt: now,
  }

  if (!snap.exists()) {
    await setDoc(ref, { ...fields, createdAt: now })
  } else {
    await setDoc(ref, fields, { merge: true })
  }
}
