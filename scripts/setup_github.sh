#!/usr/bin/env bash
# One-time: publish this folder as the public GitHub repo iladin/game-off-2026 and turn on Pages.
# Run from WSL (where your gh login / SSH key live):
#   cd /mnt/c/git/game-off-2026 && bash scripts/setup_github.sh
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="iladin/game-off-2026"
command -v gh >/dev/null || { echo "Install the GitHub CLI (gh) and run 'gh auth login' first."; exit 1; }
if git remote get-url origin >/dev/null 2>&1; then
  echo "origin already set: $(git remote get-url origin)"
else
  gh repo create "$REPO" --public --source . --remote origin \
    --description "SHIFT: a collection of small games for GitHub Game Off 2026 (Godot 4, web)"
fi
git push -u origin main
# Pages from GitHub Actions (the workflow deploys build/web on every push to main).
gh api -X POST "repos/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 \
  || gh api -X PUT "repos/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 \
  || echo "Pages: set Settings → Pages → Source: GitHub Actions by hand."
gh repo edit "$REPO" --add-topic game-off --add-topic game-off-2026 --add-topic godot --add-topic html5-game >/dev/null || true
echo "Done: https://github.com/$REPO  (play: https://iladin.github.io/game-off-2026/ after the first Actions run)"
echo "Next: ./scripts/push_loop.sh  (keep it running so the hourly studio's commits get published)"
