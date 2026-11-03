#!/usr/bin/env bash
# Find or install a headless-capable Godot for studio sessions. Prints the binary path on the last line.
# Order: $GODOT → .tools/godot (right version) → godot on PATH (right version) → download into .tools/.
# Usage: bash scripts/ensure_godot.sh [--templates]   (--templates also installs web export templates, ~1 GB download)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="$(grep -Eo 'GODOT_VERSION: *"[0-9.]+"' "$ROOT/.github/workflows/pages.yml" 2>/dev/null | grep -Eo '[0-9.]+' || echo 4.7.2)"
TOOLS="$ROOT/.tools"
mkdir -p "$TOOLS"
ok() { [[ -x "$1" ]] && "$1" --version 2>/dev/null | grep -q "^${VER}\.stable"; }
BIN=""
if [[ -n "${GODOT:-}" ]] && ok "$GODOT"; then BIN="$GODOT"
elif ok "$TOOLS/godot"; then BIN="$TOOLS/godot"
elif command -v godot >/dev/null 2>&1 && ok "$(command -v godot)"; then BIN="$(command -v godot)"
else
  echo "Installing Godot $VER into .tools/ ..." >&2
  TMP="$TOOLS/dl-$$"
  mkdir -p "$TMP"
  curl -fsSL -o "$TMP/godot.zip" "https://github.com/godotengine/godot/releases/download/${VER}-stable/Godot_v${VER}-stable_linux.x86_64.zip"
  unzip -q -o "$TMP/godot.zip" -d "$TMP"
  mv -f "$TMP/Godot_v${VER}-stable_linux.x86_64" "$TOOLS/godot"
  chmod +x "$TOOLS/godot"
  BIN="$TOOLS/godot"
fi
if [[ "${1:-}" == "--templates" ]]; then
  TPL="$HOME/.local/share/godot/export_templates/${VER}.stable"
  if ! ls "$TPL"/web_nothreads_release.zip >/dev/null 2>&1; then
    echo "Installing web export templates ..." >&2
    mkdir -p "$TPL"
    curl -fsSL -o "$TOOLS/tpl.tpz" "https://github.com/godotengine/godot/releases/download/${VER}-stable/Godot_v${VER}-stable_export_templates.tpz"
    unzip -q -j -o "$TOOLS/tpl.tpz" 'templates/web_*' 'templates/version.txt' -d "$TPL"
  fi
fi
echo "$BIN"
