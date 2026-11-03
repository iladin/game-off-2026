#!/usr/bin/env bash
# Move aside git lock files that git couldn't delete.
# In the Claude sandbox on Daniel's computer, deleting files in a connected folder is
# not permitted, so git (which deletes its own .lock files) leaves them behind and the
# NEXT git command fails with "...lock': File exists". Moving them is allowed.
#   bash scripts/git_unlock.sh          # before git writes: only locks older than 2 min (stale)
#   bash scripts/git_unlock.sh --now    # right after your own git command exited: all locks
# Locks go to .git/stale-<time>-<path> (directly under .git, never under .git/refs).
set -uo pipefail
cd "$(dirname "$0")/.."
age=2
[[ "${1:-}" == "--now" ]] && age=0
ts="$(date +%s)"
moved=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  flat="$(printf '%s' "${f#.git/}" | tr '/' '_')"
  mv -- "$f" ".git/stale-$ts-$flat" && moved=$((moved + 1))
done < <(if [[ $age -gt 0 ]]; then find .git -name '*.lock' -type f -mmin +"$age"; else find .git -name '*.lock' -type f; fi)
echo "git_unlock: moved $moved lock file(s)"
