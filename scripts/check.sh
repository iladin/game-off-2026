#!/usr/bin/env bash
# The gate. Verifies the hub and games without a human, all in ONE Godot project:
#   import/parse → per game: game.json, smoke run, autoplay round (must call
#   finish()), selftest → hub boot → attract-mode tour through every hub game.
# Usage: ./scripts/check.sh <slug> [<slug>...] | hub | all
# Prints PASS or FAIL as the last line. GODOT=/path/to/godot overrides the binary
# (default: .tools/godot if present, else `godot` on PATH).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${GODOT:-}" ]]; then
  if [[ -x "$ROOT/.tools/godot" ]]; then GODOT="$ROOT/.tools/godot"; else GODOT=godot; fi
fi
BAD='SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Invalid access|Invalid assignment|Cannot call|Nonexistent function|Node not found|ARCADE no such game|must extend MicroGame|^ERROR:|^USER ERROR:'
AUTOPLAY_FRAMES=3600   # 60 s of game time: the bot must finish a round by then

if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
  echo "FAIL godot not found (GODOT=/path/to/godot, or bash scripts/install_godot.sh)"
  exit 2
fi

run() { # name, expect-regex ('' for none), godot args...
  local name="$1" expect="$2"; shift 2
  local log
  log="$(timeout 300 "$GODOT" --headless --path "$ROOT" "$@" 2>&1)"
  if grep -Eq "$BAD" <<<"$log"; then
    echo "--- $name: errors ---"
    grep -En -B2 -A4 "$BAD" <<<"$log" | head -60
    return 1
  fi
  if [[ -n "$expect" ]] && ! grep -Eq "$expect" <<<"$log"; then
    echo "--- $name: expected /$expect/ in output; last lines: ---"
    tail -15 <<<"$log"
    return 1
  fi
  return 0
}

import_once() {
  run import '' --import >/dev/null || { echo "FAIL import: parse/import errors (see above)"; return 1; }
}

check_game() {
  local slug="$1" dir="$ROOT/games/$1"
  echo "== $slug"
  [[ -f "$dir/game.tscn" ]] || { echo "FAIL $slug: games/$slug/game.tscn missing"; return 1; }
  python3 - "$dir/game.json" <<'PY' || { echo "FAIL $slug: game.json"; return 1; }
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
missing = [k for k in ("title", "tagline", "controls", "accent") if not str(d.get(k, "")).strip()]
if missing:
    sys.exit(f"game.json missing: {', '.join(missing)}")
PY
  run smoke "ARCADE launch $slug" --fixed-fps 60 --quit-after 300 -- --game="$slug" \
    || { echo "FAIL $slug: errors on start (no input)"; return 1; }
  run autoplay "ARCADE finished $slug" --fixed-fps 60 --quit-after "$AUTOPLAY_FRAMES" -- --game="$slug" --autoplay \
    || { echo "FAIL $slug: autoplay round (errors, or the bot never reached finish() within 60 s)"; return 1; }
  if [[ -f "$dir/selftest.gd" ]]; then
    run selftest "SELFTEST OK" --script "res://games/$slug/selftest.gd" \
      || { echo "FAIL $slug: selftest"; return 1; }
  else
    echo "FAIL $slug: selftest.gd missing"; return 1
  fi
  echo "PASS $slug"
}

check_hub() {
  echo "== hub"
  run hub "ARCADE hub" --fixed-fps 60 --quit-after 300 || { echo "FAIL hub: boot"; return 1; }
  local n
  n="$(python3 -c "import json;print(len(json.load(open('$ROOT/games/registry.json'))['order']))" 2>/dev/null || echo 0)"
  if [[ "$n" -gt 0 ]]; then
    local frames=$(( (n * 5 + 10) * 60 ))
    run tour "ARCADE tour done" --fixed-fps 60 --quit-after "$frames" -- --tour \
      || { echo "FAIL hub: tour through $n hub game(s)"; return 1; }
  fi
  echo "PASS hub ($n game(s) in hub)"
}

[[ $# -gt 0 ]] || { echo "usage: $0 <slug>...|hub|all"; exit 1; }
status=0
python3 "$ROOT/scripts/glyph_lint.py" || status=1
import_once || { echo "FAIL"; exit 1; }
targets=("$@")
if [[ "$1" == "all" ]]; then
  targets=(hub)
  for p in "$ROOT"/games/*/game.tscn; do targets+=("$(basename "$(dirname "$p")")"); done
fi
for t in "${targets[@]}"; do
  if [[ "$t" == "hub" ]]; then check_hub || status=1; else check_game "$t" || status=1; fi
done
[[ $status -eq 0 ]] && echo "PASS" || echo "FAIL"
exit $status
