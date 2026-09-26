#!/usr/bin/env python3
"""Post-render: give link previews the plain-text description instead of raw LaTeX.

Quarto writes og:description and twitter:description from the front matter before filters
run, so a description with math shows up as "\\(\\lambda = \\ln 2\\)". _filters/description-text.lua
puts a plain-text version ("λ = ln 2") in <meta name="description">; this copies it over.
"""
import os
import re
from pathlib import Path

META = re.compile(r'<meta name="description" content="([^"]*)">')
SOCIAL = re.compile(r'(<meta (?:property="og:description"|name="twitter:description") content=")([^"]*)(">)')


def fix(path: Path) -> bool:
    html = path.read_text(encoding="utf-8")
    plain = META.search(html)
    if not plain:
        return False
    new = SOCIAL.sub(lambda m: m[1] + plain[1] + m[3] if "\\(" in m[2] or "\\[" in m[2] else m[0], html)
    if new == html:
        return False
    path.write_text(new, encoding="utf-8")
    return True


def main() -> None:
    listed = os.environ.get("QUARTO_PROJECT_OUTPUT_FILES", "").split("\n")
    files = [Path(f) for f in listed if f.endswith(".html")]
    if not files:
        files = list(Path(os.environ.get("QUARTO_PROJECT_OUTPUT_DIR", "_site")).rglob("*.html"))
    fixed = [f for f in files if f.exists() and fix(f)]
    if fixed:
        print(f"Plain-text social descriptions in {len(fixed)} page(s).")


if __name__ == "__main__":
    main()
