/**
 * Fix corrupted spoken-math fragments inside MathJax inline delimiters \\( … \\).
 * Content here is already JSON-unescaped (one backslash before parens).
 */

const OPEN = '\\('
const CLOSE = '\\)'

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
