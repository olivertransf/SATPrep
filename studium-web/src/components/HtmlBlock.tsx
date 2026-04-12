import { useRef, useState, useEffect, useId } from 'react'
import { buildHtml, type HtmlProfile } from '../utils/buildHtml'

interface HtmlBlockProps {
  html: string
  isDark: boolean
  fontSize?: number
  profile?: HtmlProfile
  compact?: boolean
  /** When false, pointer events are disabled so clicks pass through to a parent button/div */
  interactive?: boolean
  className?: string
}

/**
 * Renders question bank HTML in an isolated iframe with:
 * - MathJax 3 for LaTeX rendering
 * - DPR-aware scaling for CB bitmap PNGs
 * - Dark mode white plates for block images
 * - Auto-sizing height via postMessage from iframe
 */
export function HtmlBlock({
  html,
  isDark,
  fontSize = 16,
  profile = 'standard',
  compact = false,
  interactive = true,
  className,
}: HtmlBlockProps) {
  const rawId = useId()
  // useId produces ":r0:" — strip colons so it's safe as a JS string key
  const frameId = rawId.replace(/:/g, '')

  const iframeRef = useRef<HTMLIFrameElement>(null)
  const [height, setHeight] = useState(60)

  const srcDoc = buildHtml(html, isDark, fontSize, compact, profile, frameId)

  useEffect(() => {
    function handleMessage(event: MessageEvent) {
      if (
        event.data?.type === 'studium-height' &&
        event.data?.id === frameId &&
        typeof event.data.value === 'number'
      ) {
        const h = event.data.value as number
        if (h > 0 && h < 10000) setHeight(h + 4)
      }
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [frameId])

  function handleLoad() {
    // Fallback: read scrollHeight directly if postMessage hasn't fired yet
    try {
      const doc = iframeRef.current?.contentDocument
      if (doc) {
        const h = doc.body.scrollHeight
        if (h > 0) setHeight(h + 4)
      }
    } catch {
      // cross-origin — postMessage path handles it
    }
  }

  return (
    <iframe
      ref={iframeRef}
      srcDoc={srcDoc}
      onLoad={handleLoad}
      sandbox="allow-scripts"
      title="Question content"
      className={className}
      style={{
        width: '100%',
        height,
        border: 'none',
        display: 'block',
        overflow: 'hidden',
        pointerEvents: interactive ? 'auto' : 'none',
      }}
    />
  )
}
