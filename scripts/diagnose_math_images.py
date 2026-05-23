#!/usr/bin/env python3
"""
Scan cb-digital-questions.json for tiny math-img PNGs (blur risk on Retina).

Usage (from repo root):
    python3 scripts/diagnose_math_images.py
    python3 scripts/diagnose_math_images.py --full   # per-question list
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

TINY_W, TINY_H = 48, 48
IMG_RE = re.compile(
    r'<img[^>]*class="[^"]*math-img[^"]*"[^>]*>',
    re.IGNORECASE,
)
DIM_RE = re.compile(r'width="(\d+)"[^>]*height="(\d+)"', re.IGNORECASE)
DIM_RE2 = re.compile(r'height="(\d+)"[^>]*width="(\d+)"', re.IGNORECASE)


def dims(tag: str) -> tuple[int, int] | None:
    m = DIM_RE.search(tag) or DIM_RE2.search(tag)
    if not m:
        return None
    return int(m.group(1)), int(m.group(2))


def scan_html(html: str, field: str) -> list[dict]:
    out = []
    for tag in IMG_RE.findall(html):
        d = dims(tag)
        if d is None:
            continue
        w, h = d
        tiny = w <= TINY_W and h <= TINY_H
        alt_m = re.search(r'alt="([^"]*)"', tag, re.I)
        out.append({
            "field": field,
            "dims": [w, h],
            "tiny": tiny,
            "alt": (alt_m.group(1)[:60] if alt_m else ""),
        })
    return out


def scan_question(qid: str, q: dict) -> dict | None:
    imgs: list[dict] = []
    content = q.get("content") or {}
    for key in ("stem", "stimulus", "prompt"):
        if isinstance(content.get(key), str):
            imgs.extend(scan_html(content[key], key))
    answer = content.get("answer") or {}
    choices = answer.get("choices") or {}
    if isinstance(choices, dict):
        for ck, cv in choices.items():
            body = cv.get("body") if isinstance(cv, dict) else None
            if isinstance(body, str):
                imgs.extend(scan_html(body, f"choice:{ck}"))
    if not imgs:
        return None
    tiny = [i for i in imgs if i["tiny"]]
    return {
        "questionId": qid,
        "total": len(imgs),
        "tiny": len(tiny),
        "minW": min(i["dims"][0] for i in imgs),
        "minH": min(i["dims"][1] for i in imgs),
        "examples": tiny[:3] or imgs[:3],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--full", action="store_true", help="Write diagnostics-math-image-risk-full.json")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    json_path = root / "Studium" / "cb-digital-questions.json"
    bank = json.loads(json_path.read_text(encoding="utf-8"))

    rows = []
    for qid, q in bank.items():
        row = scan_question(qid, q)
        if row:
            rows.append(row)

    with_tiny = [r for r in rows if r["tiny"] > 0]
    top = sorted(with_tiny, key=lambda r: (-r["tiny"], -r["total"]))[:25]

    summary = {
        "totalQuestions": len(bank),
        "questionsWithMathImages": len(rows),
        "questionsWithTinyMathImages": len(with_tiny),
        "topRisk": [
            {k: v for k, v in r.items() if k != "examples" or True}
            for r in top
        ],
    }
    for i, r in enumerate(summary["topRisk"]):
        summary["topRisk"][i] = {
            "questionId": r["questionId"],
            "mathImgCount": r["total"],
            "tinyMathImgCount": r["tiny"],
            "examples": r["examples"],
        }

    out_path = root / "diagnostics-math-image-risk.json"
    out_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"Wrote {out_path}")
    print(
        f"{summary['questionsWithMathImages']} questions with math-img; "
        f"{summary['questionsWithTinyMathImages']} with tiny images"
    )

    if args.full:
        compact = [
            {
                "questionId": r["questionId"],
                "total": r["total"],
                "tiny": r["tiny"],
                "minW": r["minW"],
                "minH": r["minH"],
            }
            for r in rows
        ]
        full_path = root / "diagnostics-math-image-risk-full.json"
        full_path.write_text(json.dumps(compact, indent=2), encoding="utf-8")
        print(f"Wrote {full_path}")


if __name__ == "__main__":
    main()
