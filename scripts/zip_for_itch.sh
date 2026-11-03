#!/usr/bin/env bash
# Package build/web for itch.io (index.html at the zip root).
# Usage: ./scripts/zip_for_itch.sh      → dist/shift-web.zip
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
src="$ROOT/build/web"
[[ -f "$src/index.html" ]] || { echo "build/web missing: run ./scripts/export_web.sh" >&2; exit 1; }
mkdir -p "$ROOT/dist"
out="$ROOT/dist/shift-web.zip"
rm -f "$out"
(cd "$src" && zip -q -r "$out" .)
echo "$out ($(du -h "$out" | cut -f1))"
echo "itch.io: Kind of project = HTML; upload the zip; tick 'This file will be played in the browser';"
echo "viewport 1280x720; enable 'Fullscreen button'; SharedArrayBuffer support NOT needed (threads are off)."
