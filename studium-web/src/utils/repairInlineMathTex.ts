/**
 * Fix corrupted spoken-math fragments inside MathJax inline delimiters \( … \).
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

const ORDINAL_ROOT: Record<string, string> = {
  square: '2',
  cube: '3',
  fourth: '4',
  fifth: '5',
  sixth: '6',
  seventh: '7',
  eighth: '8',
  ninth: '9',
  tenth: '10',
}

function normalizeExponentBody(body: string): string {
  let exp = body.trim()
  exp = exp.replace(/\s+over\s+/gi, ' / ')
  const overMatch = /^(.+?)\s+\/\s+(.+)$/.exec(exp)
  if (overMatch) {
    const num = overMatch[1].trim()
    const den = overMatch[2].trim()
    return `\\frac{${num}}{${den}}`
  }
  return exp.replace(/\s+/g, '')
}

function repairInner(inner: string): string {
  let fixed = inner.replace(/\\+$/, '').trimEnd()

  fixed = fixed.replace(/\s+\+\s+or\s+-\s+/gi, ' \\pm ')
  fixed = fixed.replace(/\bor\s+-\b/gi, '\\pm')

  fixed = fixed.replace(
    /\bthe\s*-?\s*fraction\s+(.+?)\s+over\s+(.+?)\s+end\s+fraction\b/gi,
    (_m, num: string, den: string) => `\\frac{${num.trim()}}{${den.trim()}}`,
  )

  fixed = fixed.replace(
    /(\d+)-(half|third|fourth|quarter|fifth|sixth|seventh|eighth|ninth|tenth)\b/gi,
    (_m, num: string, word: string) => {
      const den = SPOKEN_FRAC_SUFFIX[word.toLowerCase()] ?? word
      return `\\frac{${num}}{${den}}`
    },
  )

  fixed = fixed.replace(
    /(\w+)\s+subscript\s+(\w+)\b/gi,
    (_m, base: string, sub: string) => `${base}_{${sub}}`,
  )

  fixed = fixed.replace(
    /(\S+)\s+to\s+the\s+power\s+(\\frac\{[^}]+\}\{[^}]+\})/gi,
    (_m, base: string, exp: string) => `${base}^{${exp}}`,
  )

  fixed = fixed.replace(
    /(\S+)\s+to\s+the\s+power\s+of\s+(.+?)(?=\s*(?:$|\)|,|\\times|\\cdot|\+|-))/gi,
    (_m, base: string, exp: string) => `${base}^{${normalizeExponentBody(exp)}}`,
  )

  fixed = fixed.replace(
    /(\S+)\s+to\s+the\s+power\s+(-?[\w.]+)\b/gi,
    (_m, base: string, exp: string) => `${base}^{${exp}}`,
  )

  const rootKeys = Object.keys(ORDINAL_ROOT).sort((a, b) => b.length - a.length)
  const rootPat = rootKeys.join('|')
  fixed = fixed.replace(
    new RegExp(`\\bthe\\s+(${rootPat})\\s+root\\s+of\\s+(.+?)(?:\\s+end\\s+root)?(?=\\s*(?:$|[=,+\\-)]|\\\\times|\\\\cdot))`, 'gi'),
    (_m, kind: string, body: string) => {
      const n = ORDINAL_ROOT[kind.toLowerCase()] ?? '2'
      return n === '2' ? `\\sqrt{${body.trim()}}` : `\\sqrt[${n}]{${body.trim()}}`
    },
  )

  fixed = fixed.replace(
    /\bthe cube root of\s+(.+?)(?=\s*(?:$|[=,+\-)]|(?:\s+end\s+root)))/gi,
    (_m, body: string) => `\\sqrt[3]{${body.trim()}}`,
  )

  fixed = fixed.replace(
    /\\sqrt\{([^}]+)\}\s*\+\s*([^+\s]+(?:\s+[^+\s]+)*?)\s+end\s+root/gi,
    (_m, a: string, b: string) => `\\sqrt{${a.trim()} + ${b.trim()}}`,
  )

  fixed = fixed.replace(/\s+end\s+root\b/gi, '')
  fixed = fixed.replace(/\s+end\s+fraction\b/gi, '')
  fixed = fixed.replace(/\s+end\s+power\b/gi, '')

  fixed = fixed.replace(
    /\braised\s+to\s+(?:the\s+)?\\frac\{([^}]+)\}\{([^}\s]+)\s+power\}/gi,
    (_m, a: string, b: string) => `^{\\frac{${a}}{${b}}}`,
  )

  fixed = fixed.replace(
    /\braised\s+to\s+(?:the\s+)?\\frac\{([^}]+)\}\{([^}]+)\}\s+power\b/gi,
    (_m, a: string, b: string) => `^{\\frac{${a}}{${b}}}`,
  )

  fixed = fixed.replace(
    /\braised\s+to\s+the\s+(.+?)\s+power\b/gi,
    (_m, body: string) => `^{${normalizeExponentBody(body)}}`,
  )

  fixed = fixed.replace(
    /([^\s^]+)\s+raised\s+to\s+the\s+(-?[\w.]+)\s+power\b/gi,
    (_m, base: string, exp: string) => `${base}^{${exp}}`,
  )

  fixed = fixed.replace(/(\w)\s*\^\s*\{([^}]+)\}/g, '$1^{$2}')

  fixed = fixed.replace(
    /\bparenthesis\s+(.+?)\s*\)/gi,
    (_m, body: string) => `(${body.trim()})`,
  )

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
