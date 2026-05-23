/** Fetch JSON with service-worker / Cache Storage fallback when offline. */
export async function fetchJSON<T>(path: string): Promise<T> {
  const url = path.startsWith('/') ? path : `/${path}`

  try {
    const res = await fetch(url)
    if (!res.ok) throw new Error(`${path} HTTP ${res.status}`)
    return (await res.json()) as T
  } catch (networkError) {
    if (typeof caches === 'undefined') throw networkError

    const direct = await caches.match(url)
    if (direct) return (await direct.json()) as T

    for (const name of await caches.keys()) {
      const hit = await caches.open(name).then(c => c.match(url))
      if (hit) return (await hit.json()) as T
    }

    throw networkError
  }
}

export function isOffline(): boolean {
  return typeof navigator !== 'undefined' && !navigator.onLine
}
