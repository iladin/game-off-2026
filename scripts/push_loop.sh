#!/usr/bin/env bash
# Push main to GitHub every N minutes. Run it from WSL, where your SSH key lives:
#   cd /mnt/c/git/game-off-2026 && ./scripts/push_loop.sh        # every 10 min
#   ./scripts/push_loop.sh 5                                       # every 5 min
# The hourly SHIFT factory commits its work to main on this computer but has no
# GitHub credentials; this loop publishes them (push to main -> Pages deploy).
set -uo pipefail
cd "$(dirname "$0")/.."
minutes="${1:-10}"
echo "Pushing main to origin every ${minutes} min. Ctrl+C to stop."
while true; do
  ts="$(date '+%F %T')"
  ahead="$(git rev-list --count origin/main..main 2>/dev/null || echo '?')"
  if [[ "$ahead" == "0" ]]; then
    git fetch -q origin main 2>/dev/null
    ahead="$(git rev-list --count origin/main..main 2>/dev/null || echo '?')"
  fi
  if [[ "$ahead" != "0" ]]; then
    if out="$(git push origin main 2>&1)"; then
      echo "$ts pushed $ahead commit(s) -> $(git log -1 --format='%h %s')"
    else
      echo "$ts push FAILED: $(tail -1 <<<"$out")"
    fi
  else
    echo "$ts up to date"
  fi
  sleep $(( minutes * 60 ))
done
