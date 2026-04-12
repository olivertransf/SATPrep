/**
 * Fix corrupted spoken-math fragments inside MathJax inline delimiters \\( … \\).
 * Content here is already JSON-unescaped (one backslash before parens).
 */

const OPEN = '\\('
const CLOSE = '\\)'

const SPOKEN_FRAC_SUFFIX: Record<string, string> = {
  half: '2', halves: '2',
  third: '3', thirds: '3',
  fourth: '4', fourths: '4', quarter: '4', quarters: '4',
  fifth: '5', fifths: '5',
  sixth: '6', sixths: '6',
  seventh: '7', sevenths: '7',
  eighth: '8', eighths: '8',
  ninth: '9', ninths: '9',
  tenth: '10', tenths: '10',
}

function repairInner(inner: string): string {
  let fixed = inner.replace(/\\+$/, '').trimEnd()

  fixed = fixed.replace(
    /([a-zA-Z])\s*\(\s*open\s*\)\s*parenthesis\s+([^)]+?)\s*\)/gi,
    (_m, fn: string, arg: string) => fn + '(' + arg.replace(/\s+/g, '') + ')',
  )

  fixed = fixed.replace(
    /\b([a-zA-Z])\s+of\s+(\([^()]*\))/g,
    (_m, a: string, b: string) => a + b,
  )
  fixed = fixed.replace(
    /\b([a-zA-Z])\s+of\s+([a-zA-Z0-9]+)\b/g,
    (_m, a: string, b: string) => a + '(' + b + ')',
  )
  fixed = fixed.replace(/\bf\((\d+)\)\s+x\b/g, 'f($1x)')

  const sufKeys = Object.keys(SPOKEN_FRAC_SUFFIX).sort((a, b) => b.length - a.length)
  const sufPat = sufKeys.map(k => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')
  fixed = fixed.replace(
    new RegExp(`(\\d+)\\s+(${sufPat})\\b`, 'gi'),
    (_m, num: string, word: string) => `\\frac{${num}}{${SPOKEN_FRAC_SUFFIX[word.toLowerCase()]}}`,
  )
  return fixed
}

export function repairInlineMathTex(html: string): string {
  let out = ''
  let i = 0
  while (i < html.length) {
    const start = html.indexOf(OPEN, i)
    if (start < 0) {
      out += html.slice(i)
      return out
    }
    out += html.slice(i, start)
    const bodyStart = start + OPEN.length
    const end = html.indexOf(CLOSE, bodyStart)
    if (end < 0) {
      out += html.slice(start)
      return out
    }
    const inner = html.slice(bodyStart, end)
    out += OPEN + repairInner(inner) + CLOSE
    i = end + CLOSE.length
  }
  return out
}
