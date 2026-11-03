#!/usr/bin/env bash
# Install a headless-capable Godot (Linux x86_64) + ONLY the web export templates.
# Used by CI; also handy on a Linux dev box / WSL.
# Usage: ./scripts/install_godot.sh [version]   e.g. 4.7.2
set -euo pipefail

VER="${1:-${GODOT_VERSION:-4.7.2}}"
BIN_DIR="$HOME/.local/bin"
TPL_DIR="$HOME/.local/share/godot/export_templates/${VER}.stable"
BASE="https://github.com/godotengine/godot/releases/download/${VER}-stable"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$BIN_DIR" "$TPL_DIR"

if [[ -x "$BIN_DIR/godot" ]] && "$BIN_DIR/godot" --version 2>/dev/null | grep -q "^${VER}\.stable"; then
  echo "Godot $VER already installed"
else
  echo "Downloading Godot $VER..."
  curl -fsSL -o "$TMP/godot.zip" "$BASE/Godot_v${VER}-stable_linux.x86_64.zip"
  unzip -q -o "$TMP/godot.zip" -d "$TMP"
  mv "$TMP/Godot_v${VER}-stable_linux.x86_64" "$BIN_DIR/godot"
  chmod +x "$BIN_DIR/godot"
fi

if ls "$TPL_DIR"/web_nothreads_release.zip >/dev/null 2>&1; then
  echo "Web export templates already installed"
else
  echo "Downloading export templates (large, ~1 GB; only web files are kept)..."
  curl -fsSL -o "$TMP/tpl.tpz" "$BASE/Godot_v${VER}-stable_export_templates.tpz"
  unzip -q -j -o "$TMP/tpl.tpz" 'templates/web_*' 'templates/version.txt' -d "$TPL_DIR"
fi

echo "Godot: $("$BIN_DIR/godot" --version)"
ls -1 "$TPL_DIR"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "Add $BIN_DIR to PATH (CI does this automatically)";; esac
