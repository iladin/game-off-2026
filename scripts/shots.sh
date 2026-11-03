#!/usr/bin/env bash
# Render screenshots with a real renderer (xvfb) so a human or a vision model can
# judge the look. Writes .tools/shots/<target>/<name>.png and prints the paths.
# Usage: ./scripts/shots.sh <slug>|hub [frames...]   default frames: 30 240 900
#   game: one shot of the start (no input) + autoplay shots at each frame count
#   hub:  the hub screen
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${GODOT:-}" ]]; then
  if [[ -x "$ROOT/.tools/godot" ]]; then GODOT="$ROOT/.tools/godot"; else GODOT=godot; fi
fi
target="${1:?usage: $0 <slug>|hub [frames...]}"; shift
frames=("$@"); [[ ${#frames[@]} -gt 0 ]] || frames=(30 240 900)
out="$ROOT/.tools/shots/$target"
mkdir -p "$out"
command -v xvfb-run >/dev/null || { echo "xvfb-run missing (apt-get install -y xvfb)"; exit 2; }

shot() { # name, frames, extra args...
  local name="$1" n="$2"; shift 2
  timeout 120 xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path "$ROOT" \
    --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --fixed-fps 60 -- "$@" \
    --shotfile="$out/$name.png" --shotframes="$n" 2>&1 | grep -E "ARCADE shot|SCRIPT ERROR|ERROR:" | head -5
}

if [[ "$target" == "hub" ]]; then
  shot hub 60
else
  shot start 30 --game="$target"
  for n in "${frames[@]}"; do shot "play-$n" "$n" --game="$target" --autoplay; done
fi
ls -1 "$out"/*.png 2>/dev/null
