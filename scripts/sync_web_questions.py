#!/usr/bin/env python3
"""
Rebuild studium-web/public/questions.json from Studium/cb-digital-questions.json.

The iOS/macOS app bundle uses cb-digital-questions.json (including spoken-math → LaTeX
fixes from fix_spoken_math.py). The web app must use the same source so MathJax renders
\\(...\\) instead of fuzzy base64 math-img PNGs.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NATIVE_PATH = ROOT / "Studium" / "cb-digital-questions.json"
WEB_PATH = ROOT / "studium-web" / "public" / "questions.json"
VERSION = "1.0"


def convert_question(n: dict) -> dict:
    return {
        "id": n["uId"],
        "uId": n["uId"],
        "questionId": n["questionId"],
        "program": n["program"],
        "module": n["module"],
        "difficulty": n["difficulty"],
        "primaryClassCd": n["primary_class_cd"],
        "primaryClassCdDesc": n["primary_class_cd_desc"],
        "skillCd": n.get("skill_cd"),
        "skillDesc": n["skill_desc"],
        "scoreBandRangeCd": n.get("score_band_range_cd"),
        "ibn": n.get("ibn"),
        "externalId": n.get("external_id"),
        "pPcc": n.get("pPcc"),
        "updateDate": n.get("updateDate"),
        "createDate": n.get("createDate"),
        "content": n["content"],
    }


def main() -> None:
    if not NATIVE_PATH.is_file():
        print(f"ERROR: {NATIVE_PATH} not found", file=sys.stderr)
        sys.exit(1)

    raw = json.loads(NATIVE_PATH.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        print("ERROR: expected object at top level", file=sys.stderr)
        sys.exit(1)

    questions = [convert_question(v) for v in raw.values()]
    # Stable order helps reproducible bundles (optional)
    questions.sort(key=lambda q: q["questionId"])

    out = {
        "version": VERSION,
        "totalQuestions": len(questions),
        "questions": questions,
    }
    WEB_PATH.parent.mkdir(parents=True, exist_ok=True)
    WEB_PATH.write_text(
        json.dumps(out, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"Wrote {len(questions)} questions to {WEB_PATH}")


if __name__ == "__main__":
    main()
