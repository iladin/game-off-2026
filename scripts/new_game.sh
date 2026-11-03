#!/usr/bin/env bash
# Scaffold a new game from games/_template (inside the one Godot project).
# Usage: ./scripts/new_game.sh <slug> "<Title>"
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
slug="${1:-}"; title="${2:-}"
if [[ ! "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "usage: $0 <slug: lowercase-kebab> \"<Title>\"" >&2; exit 1
fi
[[ -n "$title" ]] || title="$(echo "$slug" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')"
dest="$ROOT/games/$slug"
[[ ! -e "$dest" ]] || { echo "games/$slug already exists" >&2; exit 1; }
mkdir -p "$dest"
# Copy everything except Godot's generated .uid files (duplicate UIDs break loading).
(cd "$ROOT/games/_template" && find . -type f ! -name '*.uid' ! -name '*.import' -print0 | while IFS= read -r -d '' f; do
  mkdir -p "$dest/$(dirname "$f")"; cp "$f" "$dest/$f"; done)
safe_title="$(printf '%s' "$title" | sed -e 's/[\\"]/\\&/g' -e 's/[&|]/\\&/g')"
grep -rlE "__TITLE__|games/_template/" "$dest" | while read -r f; do
  # No -i suffix: avoids .bak files that sandboxed folders can't delete.
  sed -i -e "s|__TITLE__|$safe_title|g" -e "s|games/_template/|games/$slug/|g" "$f"
done
echo "Created games/$slug (\"$title\")"
echo "Next: DESIGN.md → rules.gd + selftest.gd → game.gd → ./scripts/check.sh $slug"
