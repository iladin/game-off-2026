#!/usr/bin/env python3
"""Fail on symbols the web build can't draw.

The exported game uses Godot's built-in fallback font, which has Latin text and
basic punctuation but no arrows, geometric shapes, box drawing or emoji. On the
web those render as empty boxes (desktop runs hide this by borrowing system
fonts). Draw shapes instead (draw_circle, draw_polygon) or write words.

  python3 scripts/glyph_lint.py [paths...]   default: games hub shared
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BAD = re.compile(r"[←-⯿☀-➿-\U0001f000-\U0001faff]")
STRING = re.compile(r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'')


def scan(path: Path) -> list[str]:
    out = []
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if line.lstrip().startswith("#"):
            continue  # comment line
        for lit in STRING.findall(line):
            for ch in set(BAD.findall(lit)):
                out.append(f"{path.relative_to(ROOT)}:{n}: '{ch}' (U+{ord(ch):04X}) in {lit[:60]}")
    return out


def main() -> int:
    targets = [ROOT / a for a in (sys.argv[1:] or ["games", "hub", "shared"])]
    files = [f for t in targets for f in ([t] if t.is_file() else sorted(t.rglob("*.gd")))]
    problems = [p for f in files for p in scan(f)]
    for p in problems:
        print(p)
    if problems:
        print(f"FAIL glyph lint: {len(problems)} symbol(s) the web font can't draw (use shapes or words)")
        return 1
    print("glyph lint OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
