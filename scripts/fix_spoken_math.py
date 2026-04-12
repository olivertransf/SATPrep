#!/usr/bin/env python3
"""
Convert CB spoken-math accessibility descriptions inside studium-bank-tex-text
spans from ``\\(`` ... ``\\text{spoken}`` ... ``\\)`` markup to proper LaTeX math notation.

Usage:
    python3 scripts/fix_spoken_math.py
    python3 scripts/fix_spoken_math.py --dry-run   # preview only, no write

The script rewrites Studium/cb-digital-questions.json in place (with a .bak backup).
"""

import json
import re
import sys
import shutil
from pathlib import Path

# ---------------------------------------------------------------------------
# Word-number maps used for ordinal fractions: "three halves" → \frac{3}{2}
# ---------------------------------------------------------------------------
WORD_TO_INT = {
    'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
    'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
    'ten': '10', 'eleven': '11', 'twelve': '12', 'thirteen': '13',
    'fourteen': '14', 'fifteen': '15', 'sixteen': '16', 'seventeen': '17',
    'eighteen': '18', 'nineteen': '19', 'twenty': '20', 'thirty': '30',
    'forty': '40', 'fifty': '50', 'sixty': '60', 'seventy': '70',
    'eighty': '80', 'ninety': '90',
}

ORDINAL_DENOM = {
    'half': '2', 'halves': '2',
    'third': '3', 'thirds': '3',
    'fourth': '4', 'fourths': '4', 'quarter': '4', 'quarters': '4',
    'fifth': '5', 'fifths': '5',
    'sixth': '6', 'sixths': '6',
    'seventh': '7', 'sevenths': '7',
    'eighth': '8', 'eighths': '8',
    'ninth': '9', 'ninths': '9',
    'tenth': '10', 'tenths': '10',
    'twelfth': '12', 'twelfths': '12',
}

GREEK = {
    'theta': r'\theta', 'pi': r'\pi', 'alpha': r'\alpha', 'beta': r'\beta',
    'gamma': r'\gamma', 'delta': r'\delta', 'phi': r'\phi', 'omega': r'\omega',
    'sigma': r'\sigma', 'mu': r'\mu', 'lambda': r'\lambda',
}

TRIG = {
    'sine': r'\sin', 'cosine': r'\cos', 'tangent': r'\tan',
    'sin': r'\sin', 'cos': r'\cos', 'tan': r'\tan',
}

POWER_WORDS = {
    'first': '1', 'second': '2', 'third': '3', 'fourth': '4', 'fifth': '5',
    'sixth': '6', 'seventh': '7', 'eighth': '8', 'ninth': '9', 'tenth': '10',
    'eleventh': '11', 'twelfth': '12', 'thirteenth': '13', 'fourteenth': '14',
    'fifteenth': '15', 'sixteenth': '16', 'seventeenth': '17', 'eighteenth': '18',
    'nineteenth': '19', 'twentieth': '20', 'twenty': '20',
    **{f'twenty {k}': str(20 + int(v)) for k, v in {
        'first': '1', 'second': '2', 'third': '3', 'fourth': '4', 'fifth': '5',
        'sixth': '6', 'seventh': '7', 'eighth': '8', 'ninth': '9',
    }.items()},
    **{f'twenty ninth': '29', 'twenty first': '21', 'twenty second': '22',
       'twenty third': '23'},
}


# ---------------------------------------------------------------------------
# Core converter
# ---------------------------------------------------------------------------

def spoken_to_latex(raw: str) -> str:
    """Convert a spoken-math string to LaTeX. Returns LaTeX (no delimiters)."""
    # Normalize escape sequences that appear in JSON strings
    s = raw.replace('\\n', '\n').replace('\\t', ' ')
    s = s.strip().strip(',').strip()

    # Prose-heavy strings: keep as \text but clean them up
    prose_markers = [
        r'(?i)^the equation .+added to',
        r'(?i)^(each|this) (option|answer choice)',
        r'(?i)^data set [a-z] consists',
        r'(?i)^the (seven|five|eight|nine|\d+) data value',
        r'(?i)^inequality \d',
        r'(?i)^statement \d',
    ]
    for pat in prose_markers:
        if re.search(pat, s):
            return r'\text{' + _minimal_clean(s) + '}'

    # Multi-line system (lines separated by \nand\n or similar)
    lines = re.split(r',?\s*\n\s*and[,.]?\s*\n\s*', s)
    if len(lines) > 1:
        converted = [_convert_expr(ln.strip()) for ln in lines if ln.strip()]
        return r'\begin{cases}' + r' \\ '.join(converted) + r'\end{cases}'

    # ", and," connector for inline systems — split before stripping commas
    parts = re.split(r',\s*and,\s*', s)
    if len(parts) > 1 and all(_looks_like_math(p) for p in parts):
        return ' \\text{ and } '.join(_convert_expr(p.strip()) for p in parts)

    return _convert_expr(s)


def _minimal_clean(s: str) -> str:
    """Light cleanup for prose kept inside \\text{}."""
    return s.strip()


def _looks_like_math(s: str) -> bool:
    """Heuristic: does this fragment look like a math expression vs prose?"""
    prose_words = {'equation', 'consists', 'each', 'option', 'choice', 'data',
                   'statement', 'inequality', 'represents', 'given', 'written'}
    words = set(re.findall(r'[a-z]+', s.lower()))
    return not bool(words & prose_words)


def _sub(pattern: str, repl: str, s: str, flags: int = re.I) -> str:
    """re.sub with repl treated as a literal string (backslashes not special)."""
    return re.sub(pattern, lambda _: repl, s, flags=flags)


def _convert_expr(s: str) -> str:
    """Convert a single math expression (no multi-line split)."""
    s = s.strip().strip(',').strip()

    # Remove thousands commas: "1,100" → "1100", "20,000" → "20000"
    s = re.sub(r'(\d),(\d{3})\b', r'\1\2', s)

    # Strip CB speech-pause commas (not math commas; the word "comma" stays).
    # E.g. "120 a, plus 100 b, is …" → "120 a plus 100 b is …"
    # Do this BEFORE other substitutions so operators aren't left dangling.
    s = re.sub(r',\s+', ' ', s)
    s = s.strip().strip(',').strip()

    # "zero point 4" → "0.4"
    s = _sub(r'\bzero point\b', '0.', s)
    # "N point D D D" → "N.DDD"  (stop at last consecutive digit, don't eat trailing space)
    s = re.sub(r'(\d)\s+point\s+(\d(?:\s*\d)*)',
               lambda m: m.group(1) + '.' + re.sub(r'\s+', '', m.group(2)), s, flags=re.I)

    # Complex fraction: "the fraction with numerator X and denominator Y end fraction"
    def replace_frac(m: re.Match) -> str:
        num = _convert_expr(m.group(1).strip().rstrip(','))
        den = _convert_expr(m.group(2).strip().rstrip(','))
        return '\\frac{' + num + '}{' + den + '}'

    # "the fraction with numerator X and denominator Y [end fraction]"
    s = re.sub(
        r'the fraction with numerator (.+?)\s+and denominator (.+?)(?:\s*end fraction|$)',
        replace_frac, s, flags=re.I
    )
    # "the fraction X over Y end fraction"
    s = re.sub(r'the fraction (.+?) over (.+?)\s*end fraction', replace_frac, s, flags=re.I)
    # "the fraction X over Y" (no end marker; use lookahead for following operator or EOL)
    s = re.sub(
        r'the fraction\s+(.+?)\s+over\s+(.+?)'
        r'(?=\s*(?:equals|plus|minus|times|is\b|and\b|$|\Z))',
        replace_frac, s, flags=re.I
    )

    # Square root
    s = re.sub(
        r'the square root of,?\s*(.+?)(?=\s*(?:,|$|\s+(?:equals|plus|minus)))',
        lambda m: '\\sqrt{' + _convert_expr(m.group(1).strip().rstrip(',')) + '}',
        s, flags=re.I
    )

    # Absolute value
    s = _sub(r'the absolute value of\s+', '|', s)

    # Ordinal fractions: "three halves" → \frac{3}{2}
    word_num_pat = '|'.join(re.escape(k) for k in sorted(WORD_TO_INT, key=len, reverse=True))
    denom_pat    = '|'.join(re.escape(k) for k in sorted(ORDINAL_DENOM, key=len, reverse=True))

    def replace_ordinal(m: re.Match) -> str:
        n = WORD_TO_INT.get(m.group(1).lower(), m.group(1))
        d = ORDINAL_DENOM.get(m.group(2).lower(), m.group(2))
        return '\\frac{' + n + '}{' + d + '}'

    s = re.sub(rf'({word_num_pat})\s+({denom_pat})\b', replace_ordinal, s, flags=re.I)

    # "the negative of"
    s = _sub(r'\bthe negative of\b,?\s*', '-', s)

    # Powers
    power_word_pat = '|'.join(re.escape(k) for k in sorted(POWER_WORDS, key=len, reverse=True))

    def replace_power_word(m: re.Match) -> str:
        exp = POWER_WORDS.get(m.group(1).lower())
        return '^{' + exp + '}' if exp else m.group(0)

    s = re.sub(rf'\bto the\s+({power_word_pat})\s+power\b', replace_power_word, s, flags=re.I)
    s = re.sub(r'\bto the\s+(\d+)(?:th|st|nd|rd)?\s+power\b',
               lambda m: '^{' + m.group(1) + '}', s, flags=re.I)
    s = re.sub(r'\bto the\s+([a-zA-Z])\s+power\b',
               lambda m: '^{' + m.group(1) + '}', s, flags=re.I)
    s = _sub(r'\bsquared\b', '^{2}', s)
    s = _sub(r'\bcubed\b', '^{3}', s)

    # Subscripts
    s = re.sub(r'\bsubscript\s+(\w+),?\s+end subscript\b',
               lambda m: '_{' + m.group(1) + '}', s, flags=re.I)
    s = re.sub(r'(\w)\s+sub\s+(\w+)\b',
               lambda m: m.group(1) + '_{' + m.group(2) + '}', s, flags=re.I)

    # Trig
    for word, cmd in TRIG.items():
        s = _sub(rf'\b{word}\s+of\s+', cmd + ' ', s)

    # Greek letters
    for word, sym in GREEK.items():
        s = _sub(rf'\b{word}\b', sym, s)

    # Spoken parentheses BEFORE "letter of …" so "f of open parenthesis 3 x" → f(3 x), not f(open)…
    s = _sub(r'\bopen outer parenthesis\b', '(', s)
    s = _sub(r'\bclose outer parenthesis\b', ')', s)
    s = _sub(r'\bopen inner parenthesis\b', '(', s)
    s = _sub(r'\bclose inner parenthesis\b', ')', s)
    s = _sub(r'\bopen parenthesis\b', '(', s)
    s = _sub(r'\bclose parenthesis\b', ')', s)
    s = _sub(r'\bopen bracket\b', '[', s)
    s = _sub(r'\bclose bracket\b', ']', s)
    s = _sub(r'\bopen brace\b', '\\{', s)
    s = _sub(r'\bclose brace\b', '\\}', s)

    # Function notation: "h of t" → h(t), "f of ( … )" → f( … )
    s = re.sub(
        r'\b([a-zA-Z])\s+of\s+(\([^()]*\))',
        lambda m: m.group(1) + m.group(2),
        s,
    )
    s = re.sub(
        r'\b([a-zA-Z])\s+of\s+(\S+)',
        lambda m: m.group(1) + '(' + m.group(2) + ')',
        s,
    )

    # Inequalities (longest match first)
    s = _sub(r'\bis\s+less\s+than\s+or\s+equal\s+to\b', '\\leq', s)
    s = _sub(r'\bis\s+greater\s+than\s+or\s+equal\s+to\b', '\\geq', s)
    s = _sub(r'\bis\s+approximately\s+equal\s+to\b', '\\approx', s)
    s = _sub(r'\bis\s+less\s+than\b', '<', s)
    s = _sub(r'\bis\s+greater\s+than\b', '>', s)
    s = _sub(r'\bis\s+equal\s+to\b', '=', s)
    s = _sub(r'\bnot\s+equal\s+to\b', '\\neq', s)

    # Operators
    s = _sub(r'\bplus\b', '+', s)
    s = _sub(r'\bminus\b', '-', s)
    s = _sub(r'\btimes\b', '\\times', s)
    s = _sub(r'\bdivided by\b', '\\div', s)
    s = _sub(r'\bequals\b', '=', s)

    # Geometry prefixes — must run BEFORE "point" → "." to avoid "the point with" → "the . with"
    # Coordinate pairs: wrap in parens → "the point with coordinates negative 3 comma 0" → "(-3, 0)"
    def wrap_coords(m: re.Match) -> str:
        inner = _convert_expr(m.group(1).strip())
        return '(' + inner + ')'
    s = re.sub(
        r'(?:the ordered pair|the points? with coordinates|with coordinates)\s+(.+?)$',
        wrap_coords, s, flags=re.I
    )
    # Fallback strip if wrap didn't fire
    s = _sub(r'\bthe ordered pair\b,?\s*', '', s)
    s = _sub(r'\bwith coordinates\b,?\s*', '', s)
    s = _sub(r'\bthe points? with\b,?\s*', '', s)
    s = _sub(r'\bangle\b\s*', '', s)
    s = re.sub(r'\bline segment\b\s*(\w+)\s*,?\s*(\w+)\b',
               lambda m: '\\overline{' + m.group(1) + m.group(2) + '}', s, flags=re.I)
    s = _sub(r'\btriangle\b\s*', '\\triangle ', s)

    # Negation
    s = _sub(r'\bnegative\s+', '-', s)

    # Decimal point (only standalone "point" remaining after geometry prefix removal)
    s = _sub(r'\bpoint\b', '.', s)

    # "comma" standalone
    s = _sub(r'\bcomma\b', ',', s)

    # Units
    s = _sub(r'\bpercent\b', '\\%', s)
    s = _sub(r'\bdegrees Fahrenheit\b', '^{\\circ}\\text{F}', s)
    s = _sub(r'\bdegrees Celsius\b', '^{\\circ}\\text{C}', s)
    s = _sub(r'\bdegrees\b', '^{\\circ}', s)
    s = _sub(r'\binfinity\b', '\\infty', s)

    for unit in ['cubic inches', 'cubic inch', 'centimeters', 'centimeter',
                 'inches', 'inch', 'feet', 'foot', 'meters', 'meter',
                 'kilometers', 'kilometer', 'miles', 'mile',
                 'seconds', 'second', 'minutes', 'minute', 'hours', 'hour',
                 'dollars', 'dollar', 'pounds', 'pound', 'ounces', 'ounce',
                 'million', 'billion', 'thousand']:
        s = _sub(rf'\b{re.escape(unit)}\b', '\\text{' + unit + '}', s)

    # Remaining word numbers → digits
    for word, digit in sorted(WORD_TO_INT.items(), key=lambda x: len(x[0]), reverse=True):
        s = re.sub(
            rf'(?<![a-zA-Z\\]){re.escape(word)}(?![a-zA-Z])',
            lambda _, d=digit: d, s, flags=re.I
        )

    # Tidy up spacing
    s = re.sub(r'\s+', ' ', s)
    s = s.strip().strip(',').strip()

    return s


# ---------------------------------------------------------------------------
# JSON patch: find and replace \text{spoken} inside studium-bank-tex-text
# ---------------------------------------------------------------------------

TEXT_PATTERN = re.compile(
    r'(\\\\text\{)([^}]{1,500})(\})'
)


def _json_encode_str(s: str) -> str:
    """Encode a Python string for insertion into a raw JSON string literal."""
    return (s
        .replace('\\', '\\\\')   # backslash first (must be first)
        .replace('\n', '\\n')    # literal newline → JSON \n
        .replace('\r', '\\r')
        .replace('\t', '\\t')
    )


def process_text_match(m: re.Match) -> str:
    spoken = m.group(2)
    latex = spoken_to_latex(spoken)
    return _json_encode_str(latex)


# Pattern for the ORIGINAL format: <img role="math" class="math-img" alt="spoken" src="..."/>
# In raw JSON the quotes are escaped as \", so we match on \\\" sequences.
IMG_MATH_PATTERN = re.compile(
    r'<img\s[^<>]*?'           # opening tag
    r'role=\\"math\\"[^<>]*?'  # role="math"
    r'alt=\\"([^\\]{1,500})\\"'  # alt="spoken text"  ← capture group 1
    r'[^<>]*?/?>'              # rest of tag
)

# Also handle alt-before-role ordering
IMG_MATH_PATTERN_ALT_FIRST = re.compile(
    r'<img\s[^<>]*?'
    r'alt=\\"([^\\]{1,500})\\"'
    r'[^<>]*?role=\\"math\\"'
    r'[^<>]*?/?>'
)


def process_img_match(m: re.Match) -> str:
    spoken = m.group(1)
    latex = spoken_to_latex(spoken)
    return '\\\\(' + _json_encode_str(latex) + '\\\\)'


# JSON string values store each TeX delimiter backslash doubled (\\… in file → \( in HTML).
_JSON_INLINE_OPEN = '\\\\('
_JSON_INLINE_CLOSE = '\\\\)'

# "4 thirds" / "one half" style inside corrupted \\( … \\) spans
_SPOKEN_FRAC_SUFFIX = {
    'half': '2', 'halves': '2',
    'third': '3', 'thirds': '3',
    'fourth': '4', 'fourths': '4', 'quarter': '4', 'quarters': '4',
    'fifth': '5', 'fifths': '5',
    'sixth': '6', 'sixths': '6',
    'seventh': '7', 'sevenths': '7',
    'eighth': '8', 'eighths': '8',
    'ninth': '9', 'ninths': '9',
    'tenth': '10', 'tenths': '10',
}
_SPOKEN_FRAC_SUFFIX_PAT = '|'.join(
    re.escape(k) for k in sorted(_SPOKEN_FRAC_SUFFIX, key=len, reverse=True)
)


def _extract_inline_tex_spans(s: str):
    """Yield (start, end_exclusive, inner) for each JSON-encoded \\\\( … \\\\) math span."""
    i = 0
    n = len(s)
    ol, cl = len(_JSON_INLINE_OPEN), len(_JSON_INLINE_CLOSE)
    while i < n:
        start = s.find(_JSON_INLINE_OPEN, i)
        if start < 0:
            return
        body_start = start + ol
        end = s.find(_JSON_INLINE_CLOSE, body_start)
        if end < 0:
            i = body_start
            continue
        yield start, end + cl, s[body_start:end]
        i = end + cl


def repair_broken_inline_tex(s: str) -> str:
    """Fix bad \\( … \\) left by older passes (e.g. 'h of t', 'f(open) parenthesis')."""
    pieces: list[str] = []
    last = 0
    for start, end, inner in _extract_inline_tex_spans(s):
        pieces.append(s[last:start])
        fixed = inner.rstrip().rstrip('\\')
        # "f(open) parenthesis …" or "f(open)parenthesis …" (CB sometimes omits space)
        fixed = re.sub(
            r'([a-zA-Z])\s*\(\s*open\s*\)\s*parenthesis\s+([^)]+?)\s*\)',
            lambda m: m.group(1) + '(' + re.sub(r'\s+', '', m.group(2)) + ')',
            fixed,
            flags=re.I,
        )
        fixed = re.sub(
            r'\b([a-zA-Z])\s+of\s+(\([^()]*\))',
            lambda m: m.group(1) + m.group(2),
            fixed,
        )
        fixed = re.sub(
            r'\b([a-zA-Z])\s+of\s+([a-zA-Z0-9]+)\b',
            lambda m: m.group(1) + '(' + m.group(2) + ')',
            fixed,
        )
        # Corrupted "f of 3 x" → "f(3) x" in rationales; merge to f(3x)
        fixed = re.sub(r'\bf\((\d+)\)\s+x\b', r'f(\1x)', fixed)
        fixed = re.sub(
            rf'(\d+)\s+({_SPOKEN_FRAC_SUFFIX_PAT})\b',
            lambda m: '\\frac{' + m.group(1) + '}{' + _SPOKEN_FRAC_SUFFIX[m.group(2).lower()] + '}',
            fixed,
            flags=re.I,
        )
        pieces.append(_JSON_INLINE_OPEN + fixed + _JSON_INLINE_CLOSE)
        last = end
    pieces.append(s[last:])
    return ''.join(pieces)


def process_json(raw: str) -> str:
    """Process raw JSON string, replacing spoken math with LaTeX."""
    # Handle \text{spoken} intermediate format (from a previous preprocessing step)
    result = TEXT_PATTERN.sub(process_text_match, raw)
    # Handle original <img role="math" alt="spoken"> format
    result = IMG_MATH_PATTERN.sub(process_img_match, result)
    result = IMG_MATH_PATTERN_ALT_FIRST.sub(process_img_match, result)
    result = repair_broken_inline_tex(result)
    return result


# ---------------------------------------------------------------------------
# Preview / test helpers
# ---------------------------------------------------------------------------

TESTS = [
    ('y equals, 18, minus 5 x',             'y = 18 - 5 x'),
    ('one half y equals 4',                  r'\frac{1}{2} y = 4'),
    ('a, plus b, is greater than or equal to 10', r'a + b \geq 10'),
    ('the fraction 7 over 2',                r'\frac{7}{2}'),
    ('negative x plus y, equals negative 3 point 5', r'-x + y = -3.5'),
    ('4 x plus 2 y, equals 86',              '4 x + 2 y = 86'),
    ('f of x equals, the fraction with numerator 2 x minus 1, and denominator 3',
     r'f(x) = \frac{2 x - 1}{3}'),
    ('y equals, the negative of the fraction a, x, over k, end fraction, plus, the fraction 6 over k',
     r'y = -\frac{a x}{k} + \frac{6}{k}'),
]


def run_tests():
    print('--- Conversion tests ---')
    for spoken, expected in TESTS:
        result = _convert_expr(spoken)
        ok = '✓' if result == expected else '?'
        print(f' {ok} {repr(spoken[:60])}')
        print(f'   → {result}')
        if result != expected:
            print(f'   ≠ {expected}')
    print()

    print('--- Inline repair (JSON-encoded delimiters) ---')
    _rep_cases = [
        (_JSON_INLINE_OPEN + 'h of t = 1' + _JSON_INLINE_CLOSE, _JSON_INLINE_OPEN + 'h(t) = 1' + _JSON_INLINE_CLOSE),
        (_JSON_INLINE_OPEN + 'f(open) parenthesis 3 x ) = x - 6' + _JSON_INLINE_CLOSE,
         _JSON_INLINE_OPEN + 'f(3x) = x - 6' + _JSON_INLINE_CLOSE),
        (_JSON_INLINE_OPEN + 'f(open)parenthesis 3 x ) = x - 6' + _JSON_INLINE_CLOSE,
         _JSON_INLINE_OPEN + 'f(3x) = x - 6' + _JSON_INLINE_CLOSE),
        (_JSON_INLINE_OPEN + 'f(3) x = 0' + _JSON_INLINE_CLOSE, _JSON_INLINE_OPEN + 'f(3x) = 0' + _JSON_INLINE_CLOSE),
        (_JSON_INLINE_OPEN + '4 thirds' + _JSON_INLINE_CLOSE, _JSON_INLINE_OPEN + '\\frac{4}{3}' + _JSON_INLINE_CLOSE),
    ]
    for a, b in _rep_cases:
        out = repair_broken_inline_tex(a)
        ok = '✓' if out == b else '?'
        print(f' {ok} {repr(a[:50])}…')
        if out != b:
            print(f'   → {out!r} ≠ {b!r}')
    print()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    dry_run = '--dry-run' in sys.argv
    json_path = Path('Studium/cb-digital-questions.json')

    if not json_path.exists():
        print(f'ERROR: {json_path} not found. Run from project root.')
        sys.exit(1)

    run_tests()

    raw = json_path.read_text(encoding='utf-8')
    text_count = len(TEXT_PATTERN.findall(raw))
    img_count  = len(IMG_MATH_PATTERN.findall(raw)) + len(IMG_MATH_PATTERN_ALT_FIRST.findall(raw))
    print(f'Found {text_count} \\text{{}} + {img_count} <img role="math"> occurrences\n')

    # Preview a few from whichever format is present
    print('--- Sample conversions ---')
    shown = 0
    patterns = [(TEXT_PATTERN, lambda m: m.group(2)),
                (IMG_MATH_PATTERN, lambda m: m.group(1)),
                (IMG_MATH_PATTERN_ALT_FIRST, lambda m: m.group(1))]
    for pat, getter in patterns:
        for m in pat.finditer(raw):
            spoken = getter(m)
            latex = spoken_to_latex(spoken)
            if shown < 20:
                print(f'  IN:  {repr(spoken[:80])}')
                print(f'  OUT: {repr(latex[:80])}')
                print()
                shown += 1
        if shown >= 20:
            break

    if dry_run:
        print('[dry-run] No files written.')
        return

    # Backup
    backup = json_path.with_suffix('.json.bak')
    shutil.copy2(json_path, backup)
    print(f'Backup written to {backup}')

    patched = process_json(raw)
    json_path.write_text(patched, encoding='utf-8')
    print(f'Wrote {json_path}')

    # Verify it still parses
    try:
        json.loads(patched)
        print('JSON validation: OK')
    except json.JSONDecodeError as e:
        print(f'JSON validation FAILED: {e}')
        print('Restoring backup...')
        shutil.copy2(backup, json_path)
        sys.exit(1)


if __name__ == '__main__':
    main()
