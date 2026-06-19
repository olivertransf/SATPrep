import { useRef, useState, useEffect, useId, useMemo, useCallback } from 'react'
import { buildHtml, type HtmlProfile } from '../utils/buildHtml'
import { htmlEmbedSurfaceBackground, type HtmlEmbedSurface } from '../design/tokens'

interface HtmlBlockProps {
  html: string
  isDark: boolean
  fontSize?: number
  profile?: HtmlProfile
  compact?: boolean
  surface?: HtmlEmbedSurface
  /** Match native `embedded` HTML — card-colored background, no extra inset padding. */
  embedded?: boolean
  /** When false, pointer events are disabled so clicks pass through to a parent button/div */
  interactive?: boolean
  className?: string
}

const IFRAME_SANDBOX = 'allow-scripts allow-same-origin'

function minIframeHeight(compact: boolean): number {
  return compact ? 28 : 56
}

/**
 * Renders question bank HTML in an isolated iframe with MathJax, DPR-aware images, and auto height.
 */
export function HtmlBlock({
  html,
  isDark,
  fontSize = 16,
  profile = 'standard',
  compact = false,
  surface = 'card',
  embedded = true,
  interactive = true,
  className,
}: HtmlBlockProps) {
  const rawId = useId()
  const frameId = rawId.replace(/:/g, '')

  const iframeRef = useRef<HTMLIFrameElement>(null)
  const heightPad = compact ? 0 : 4
  const floorHeight = minIframeHeight(compact)
  const [height, setHeight] = useState(floorHeight)
  const blockBackground = htmlEmbedSurfaceBackground(isDark, surface)

  const srcDoc = useMemo(
    () => buildHtml(html, isDark, fontSize, compact, profile, frameId, embedded, surface),
    [html, isDark, fontSize, compact, profile, frameId, embedded, surface],
  )

  const applyHeight = useCallback(
    (raw: number) => {
      if (raw <= 0 || raw >= 10000) return
      setHeight(prev => Math.max(floorHeight, raw + heightPad, prev))
    },
    [floorHeight, heightPad],
  )

  const measureFromDocument = useCallback(() => {
    try {
      const doc = iframeRef.current?.contentDocument
      if (!doc?.body) return
      const h = Math.max(doc.body.scrollHeight, doc.documentElement.scrollHeight)
      if (h > 0) applyHeight(h)
    } catch {
      /* postMessage path handles it */
    }
  }, [applyHeight])

  useEffect(() => {
    setHeight(floorHeight)
  }, [srcDoc, floorHeight])

  useEffect(() => {
    function handleMessage(event: MessageEvent) {
      if (
        event.data?.type === 'studium-height' &&
        event.data?.id === frameId &&
        typeof event.data.value === 'number'
      ) {
        applyHeight(event.data.value as number)
      }
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [frameId, applyHeight])

  useEffect(() => {
    const delays = [120, 400, 900, 1800]
    const timers = delays.map(ms => window.setTimeout(measureFromDocument, ms))
    return () => timers.forEach(window.clearTimeout)
  }, [srcDoc, measureFromDocument])

  return (
    <iframe
      ref={iframeRef}
      srcDoc={srcDoc}
      onLoad={measureFromDocument}
      sandbox={IFRAME_SANDBOX}
      title="Question content"
      className={className}
      style={{
        width: '100%',
        height,
        minHeight: floorHeight,
        border: 'none',
        display: 'block',
        overflow: 'hidden',
        backgroundColor: embedded ? blockBackground : 'transparent',
        colorScheme: isDark ? 'dark' : 'light',
        pointerEvents: interactive ? 'auto' : 'none',
      }}
    />
  )
}
