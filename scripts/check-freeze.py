#!/usr/bin/env python3
"""Fail if a page with executable code has no frozen output, or its output is older than its source.

Quarto stores the MD5 of each source file in _freeze/<path>/execute-results/html.json.
CI never runs Python, so a mismatch means the published page would fail to build.
"""
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP = {"_site", "_freeze", ".quarto", ".venv", ".git", "node_modules"}
# Engine cells only; {ojs} runs in the browser and is never frozen.
CELL = re.compile(r"^```+\s*\{(python|r|julia)\b", re.MULTILINE)


def main() -> int:
    problems = []
    for src in sorted(ROOT.rglob("*.qmd")):
        rel = src.relative_to(ROOT)
        # Quarto ignores files and folders whose names start with "_" or ".".
        if any(part in SKIP or part.startswith(("_", ".")) for part in rel.parts):
            continue
        text = src.read_text(encoding="utf-8")
        if not CELL.search(text):
            continue
        frozen = ROOT / "_freeze" / rel.with_suffix("") / "execute-results" / "html.json"
        if not frozen.exists():
            problems.append(f"{rel}: no frozen output")
            continue
        stored = json.loads(frozen.read_text(encoding="utf-8")).get("hash")
        if stored != hashlib.md5(src.read_bytes()).hexdigest():
            problems.append(f"{rel}: frozen output is out of date")

    if problems:
        print("Stale or missing _freeze/ output. Run `make render` and commit _freeze/:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1
    print("All frozen outputs are up to date.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
