export const colors = {
  accent: '#007AFF',
  accentDark: '#0A84FF',
  math: '#007AFF',
  mathDark: '#0A84FF',
  rw: '#5856D6',
  rwDark: '#5E5CE6',
} as const

/** Mirrors `StudiumDesignSystem.swift` + `LayoutMetrics` for web layout. */
export const WIDE_BREAKPOINT_PX = 900
export const PRACTICE_SIDEBAR_WIDTH_PX = 348

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
} as const

export const radius = {
  chip: 10,
  card: 14,
  sheet: 16,
} as const

/** Colors for CB HTML embedded in iframes — aligned with `index.css` `--card` / text tokens. */
export const htmlEmbedTheme = {
  light: {
    bg: '#ffffff',
    fg: '#0f172a',
    border: '#e2e8f0',
    headerBg: '#f1f5f9',
    rowAlt: '#f8fafc',
    blockquote: '#cbd5e1',
    input: '#f8fafc',
  },
  dark: {
    bg: '#1e293b',
    fg: '#f1f5f9',
    border: '#334155',
    headerBg: '#334155',
    rowAlt: '#1e293b',
    blockquote: '#475569',
    input: '#1e293b',
  },
} as const

export type HtmlEmbedSurface = 'card' | 'input'

export function htmlEmbedSurfaceBackground(isDark: boolean, surface: HtmlEmbedSurface = 'card'): string {
  const theme = htmlEmbedTheme[isDark ? 'dark' : 'light']
  return surface === 'input' ? theme.input : theme.bg
}

export function htmlEmbedCardBackground(isDark: boolean): string {
  return htmlEmbedSurfaceBackground(isDark, 'card')
}
