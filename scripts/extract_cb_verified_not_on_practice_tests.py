#!/usr/bin/env python3
"""
Extract 8-char hex question IDs from College Board Educator Question Bank
HTML exports (results with “Exclude Active Questions” on). Writes
Studium/cb-verified-not-on-practice-tests.json

Usage:
  python3 scripts/extract_cb_verified_not_on_practice_tests.py ~/Downloads
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ID_RE = re.compile(r"(?<![0-9a-f])([0-9a-f]{8})(?![0-9a-f])")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "html_dir",
        type=Path,
        help="Directory containing *.html exports (e.g. ~/Downloads)",
    )
    ap.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "Studium" / "cb-verified-not-on-practice-tests.json",
    )
    args = ap.parse_args()
    d = args.html_dir.expanduser()
    ids: set[str] = set()
    for f in sorted(d.glob("*.html")):
        text = f.read_text(errors="replace").lower()
        ids.update(m.group(1) for m in ID_RE.finditer(text))
    out = sorted(ids)
    payload = {
        "source": (
            "College Board SAT Suite Educator Question Bank results HTML, "
            'with “Exclude Active Questions” enabled (items not also on full-length practice tests).'
        ),
        "scrapedFromGlob": str(d / "*.html"),
        "idCount": len(out),
        "questionIds": out,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(out)} ids to {args.output}")


if __name__ == "__main__":
    main()
