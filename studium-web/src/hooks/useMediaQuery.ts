import { useEffect, useState } from 'react'
import { WIDE_BREAKPOINT_PX } from '../design/tokens'

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() => {
    if (typeof window === 'undefined') return false
    return window.matchMedia(query).matches
  })

  useEffect(() => {
    const mq = window.matchMedia(query)
    const onChange = () => setMatches(mq.matches)
    onChange()
    mq.addEventListener('change', onChange)
    return () => mq.removeEventListener('change', onChange)
  }, [query])

  return matches
}

export function useWidePracticeLayout(): boolean {
  return useMediaQuery(`(min-width: ${WIDE_BREAKPOINT_PX}px)`)
}
