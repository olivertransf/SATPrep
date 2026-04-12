import { useRef, useState, useEffect, useId, useMemo } from 'react'
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
  /**
   * Iframe fills the parent height; passage scrolls inside the document.
   * Use only when the parent has a definite height (e.g. split-pane passage column).
   */
  fillViewport?: boolean
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
  fillViewport = false,
}: HtmlBlockProps) {
  const rawId = useId()
  // useId produces ":r0:" — strip colons so it's safe as a JS string key
  const frameId = rawId.replace(/:/g, '')

  const iframeRef = useRef<HTMLIFrameElement>(null)
  const [height, setHeight] = useState(60)

  const srcDoc = useMemo(
    () => buildHtml(html, isDark, fontSize, compact, profile, frameId, fillViewport),
    [html, isDark, fontSize, compact, profile, frameId, fillViewport],
  )

  useEffect(() => {
    if (fillViewport) return
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
  }, [frameId, fillViewport])

  function handleLoad() {
    if (fillViewport) return
    try {
      const doc = iframeRef.current?.contentDocument
      if (doc) {
        const h = doc.body.scrollHeight
        if (h > 0) setHeight(h + 4)
      }
    } catch {
      /* cross-origin — postMessage path handles it */
    }
  }

  if (fillViewport) {
    return (
      <div className={`flex flex-1 flex-col min-h-0 w-full ${className ?? ''}`.trim()}>
        <iframe
          ref={iframeRef}
          srcDoc={srcDoc}
          onLoad={handleLoad}
          sandbox="allow-scripts"
          title="Question content"
          style={{
            width: '100%',
            flex: '1 1 0',
            minHeight: 0,
            border: 'none',
            display: 'block',
            overflow: 'hidden',
            pointerEvents: interactive ? 'auto' : 'none',
          }}
        />
      </div>
    )
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
