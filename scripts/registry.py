#!/usr/bin/env python3
"""Rebuild games/registry.json, the list of games the hub shows, in slot order.

A game is in the hub when its game.json has "status": "shipped". Order comes from
the optional "slot" number in game.json (lowest first), then title. Only the
Producer runs this, after a game passes verification and the Creative Director's
greenlight, so parallel builders never edit the same file.

  python3 scripts/registry.py          # write games/registry.json, print it
  python3 scripts/registry.py --check  # exit 1 if registry.json is stale
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAMES = ROOT / "games"
REG = GAMES / "registry.json"


def build() -> dict:
    rows = []
    for meta in sorted(GAMES.glob("*/game.json")):
        slug = meta.parent.name
        if slug.startswith("_") or not (meta.parent / "game.tscn").exists():
            continue
        d = json.loads(meta.read_text(encoding="utf-8"))
        if d.get("status") == "shipped":
            rows.append((d.get("slot", 99), d.get("title", slug), slug))
    rows.sort()
    return {"order": [slug for _, _, slug in rows]}


def main() -> int:
    want = build()
    text = json.dumps(want, indent=2) + "\n"
    if "--check" in sys.argv:
        have = REG.read_text(encoding="utf-8") if REG.exists() else ""
        if have != text:
            print("registry.json is stale; run python3 scripts/registry.py")
            return 1
        print("registry.json up to date")
        return 0
    REG.write_text(text, encoding="utf-8")
    print(text, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
