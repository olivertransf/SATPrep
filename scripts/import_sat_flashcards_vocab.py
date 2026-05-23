#!/usr/bin/env python3
"""Import window.DEFAULT_VOCAB from sat-flashcards/vocab.js into Studium JSON decks."""
from __future__ import annotations

import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
VOCAB_JS = REPO.parent / "sat-flashcards" / "vocab.js"
NATIVE_JSON = REPO / "Studium/Resources/sat-vocab-flashcards.json"
WEB_JSON = REPO / "studium-web/public/vocab.json"

POS_RE = re.compile(r"^\(([^)]+)\)\s*")


def parse_pos(definition: str) -> str:
    m = POS_RE.match(definition.strip())
    if not m:
        return "other"
    tag = m.group(1).lower().strip(".")
    if tag in {"v", "verb"}:
        return "verb"
    if tag in {"n", "noun"}:
        return "noun"
    if tag in {"adj", "adjective"}:
        return "adj"
    if tag in {"adv", "adverb"}:
        return "adverb"
    return "other"


def strip_pos_prefix(definition: str) -> str:
    return POS_RE.sub("", definition.strip(), count=1).strip()


def load_vocab_js(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8")
    # vocab.js is `window.DEFAULT_VOCAB = [ {...}, ... ];`
    start = text.find("[")
    end = text.rfind("]")
    if start < 0 or end < 0:
        raise SystemExit(f"Could not find JSON array in {path}")
    items = json.loads(text[start : end + 1])
    out: list[dict[str, str]] = []
    seen: set[str] = set()
    for item in items:
        term = (item.get("term") or "").strip()
        if not term:
            continue
        key = term.lower()
        if key in seen:
            continue
        seen.add(key)
        definition = (item.get("definition") or "").strip()
        out.append(
            {
                "term": term,
                "definition": definition,
                "partOfSpeech": parse_pos(definition),
                "definitionClean": strip_pos_prefix(definition),
            }
        )
    return out


def main() -> None:
    if not VOCAB_JS.is_file():
        raise SystemExit(f"Missing {VOCAB_JS}")

    terms = load_vocab_js(VOCAB_JS)
    roots: list[dict] = []
    if NATIVE_JSON.is_file():
        roots = json.loads(NATIVE_JSON.read_text(encoding="utf-8")).get("roots") or []

    native_words = [
        {
            "id": str(i + 1),
            "word": t["term"],
            "definition": t["definitionClean"] or t["definition"],
            "partOfSpeech": t["partOfSpeech"],
        }
        for i, t in enumerate(terms)
    ]

    native_payload = {"words": native_words, "roots": roots}
    NATIVE_JSON.write_text(json.dumps(native_payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    web_words = [
        {
            "id": str(i + 1),
            "word": t["term"],
            "definition": t["definitionClean"] or t["definition"],
            "partOfSpeech": t["partOfSpeech"],
        }
        for i, t in enumerate(terms)
    ]
    WEB_JSON.write_text(json.dumps({"words": web_words}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"Wrote {len(native_words)} words (+ {len(roots)} roots) to {NATIVE_JSON.name}")
    print(f"Wrote {len(web_words)} words to {WEB_JSON.name}")


if __name__ == "__main__":
    main()
