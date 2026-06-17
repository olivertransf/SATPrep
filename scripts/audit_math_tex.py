#!/usr/bin/env python3
"""Audit math questions for unconverted spoken-math inside \\( … \\) spans."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUESTIONS = ROOT / 'studium-web' / 'public' / 'questions.json'

INLINE_OPEN = '\\('
INLINE_CLOSE = '\\)'

SPOKEN_RE = re.compile(
    r'\b(?:end\s+(?:fraction|root|power|subscript)|'
    r'the\s*-?\s*fraction|raised\s+to|parenthesis\s+\d|'
    r'the\s+(?:cube|square|fourth|fifth|sixth|seventh|eighth|ninth|tenth)\s+root\s+of|'
    r'to\s+the\s+power|'
    r'\bpower\}|'
    r'subscript\s+\d|'
    r'f\s*\(\s*open\s*\)|'
    r'\+\s+or\s+-\s+)',
    re.I,
)

sys.path.insert(0, str(ROOT))
from scripts.fix_spoken_math import _repair_inner  # noqa: E402


def collect_html(q: dict) -> str:
    c = q.get('content', {})
    parts: list[str] = []
    for k in ('prompt', 'stem', 'body', 'rationale'):
        v = c.get(k)
        if isinstance(v, str):
            parts.append(v)
    ans = c.get('answer', {})
    if isinstance(ans, dict):
        for ch in (ans.get('choices') or {}).values():
            if isinstance(ch, dict) and ch.get('body'):
                parts.append(ch['body'])
    return '\n'.join(parts)


def extract_spans(html: str) -> list[str]:
    spans: list[str] = []
    i = 0
    ol, cl = len(INLINE_OPEN), len(INLINE_CLOSE)
    while i < len(html):
        start = html.find(INLINE_OPEN, i)
        if start < 0:
            break
        end = html.find(INLINE_CLOSE, start + ol)
        if end < 0:
            break
        spans.append(html[start + ol:end])
        i = end + cl
    return spans


def main() -> None:
    data = json.loads(QUESTIONS.read_text(encoding='utf-8'))
    math_qs = [q for q in data['questions'] if q.get('module', '').lower() == 'math']

    broken_before: list[tuple[str, str]] = []
    broken_after: list[tuple[str, str, str]] = []
    math_img: list[str] = []

    for q in math_qs:
        qid = q.get('questionId', '?')
        html = collect_html(q)
        if 'math-img' in html or 'role=\\"math\\"' in html:
            math_img.append(qid)

        for inner in extract_spans(html):
            if SPOKEN_RE.search(inner):
                broken_before.append((qid, inner))
            rep_inner = _repair_inner(inner)
            if SPOKEN_RE.search(rep_inner):
                broken_after.append((qid, inner, rep_inner))

    print(f'Math questions: {len(math_qs)}')
    print(f'Inline spans with spoken artifacts before repair: {len(broken_before)}')
    print(f'Inline spans still broken after repair: {len(broken_after)}')
    print(f'Questions with math-img (base64, no LaTeX): {len(math_img)}')

    if broken_after:
        print('\nStill broken:')
        seen: set[str] = set()
        for qid, inner, rep in broken_after:
            if qid in seen:
                continue
            seen.add(qid)
            print(f'  {qid}')
            print(f'    IN:  {inner[:120]!r}')
            print(f'    OUT: {rep[:120]!r}')

    if math_img:
        print('\nmath-img question IDs:', ', '.join(math_img))


if __name__ == '__main__':
    main()
