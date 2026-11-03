#!/usr/bin/env bash
# Export the whole collection (hub + every game) to build/web/ as ONE HTML5 build.
# Needs the web export templates (bash scripts/install_godot.sh installs them).
# Usage: ./scripts/export_web.sh [debug]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${GODOT:-}" ]]; then
  if [[ -x "$ROOT/.tools/godot" ]]; then GODOT="$ROOT/.tools/godot"; else GODOT=godot; fi
fi
mode="--export-release"; [[ "${1:-}" == "debug" ]] && mode="--export-debug"
mkdir -p "$ROOT/build/web"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT" "$mode" "Web" "$ROOT/build/web/index.html" 2>&1 | grep -Ev '^\s*$|^Godot Engine' | tail -20
[[ -f "$ROOT/build/web/index.html" ]] || { echo "export FAILED"; exit 1; }
pck_kb=$(du -k "$ROOT/build/web/index.pck" | cut -f1)
echo "exported build/web: engine $(du -h "$ROOT/build/web/index.wasm" | cut -f1) + game data $(( pck_kb / 1024 )) MB (pck)"
if (( pck_kb > 20480 )); then echo "WARNING: game data (index.pck) is over 20 MB; trim assets"; fi
