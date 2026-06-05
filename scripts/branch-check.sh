#!/bin/bash
# branch-check.sh - detect branch collisions before they become duplicate-divergent files.
#
# Branch sprawl's worst symptom is two unmerged branches editing the same files
# and silently diverging into duplicate-but-different versions. This surfaces
# that signal early.
#
# Usage:
#   bash scripts/branch-check.sh <area>   # BEFORE branching: does any branch already touch <area>?
#   bash scripts/branch-check.sh          # no args: which other unmerged branches edit the files I'm editing?
#
# See .kiro/steering/focus-and-branch-discipline.md
set -uo pipefail

MAIN="${MAIN_BRANCH:-main}"
AREA="${1:-}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository."
  exit 1
fi

# Branches that are NOT yet fully merged into main (excluding main itself).
unmerged_branches() {
  local b
  for b in $(git for-each-ref --format='%(refname:short)' refs/heads | grep -vx "$MAIN"); do
    git merge-base --is-ancestor "$b" "$MAIN" 2>/dev/null && continue
    echo "$b"
  done
}

# ── Mode 1: check a named area before creating a branch ────────────────────────
if [ -n "$AREA" ]; then
  echo "Branches whose name matches '$AREA':"
  matches=$(git branch --all --list "*$AREA*" | sed 's/^/  /')
  [ -n "$matches" ] && echo "$matches" || echo "  (none)"
  echo ""
  echo "Files matching '$AREA' touched by unmerged branches:"
  found=0
  while IFS= read -r b; do
    [ -z "$b" ] && continue
    files=$(git diff --name-only "$MAIN...$b" 2>/dev/null | grep -i "$AREA")
    if [ -n "$files" ]; then
      found=1
      echo "  [$b] (last commit $(git log -1 --format='%ci' "$b" 2>/dev/null)):"
      echo "$files" | sed 's/^/      /'
    fi
  done < <(unmerged_branches)
  [ "$found" -eq 0 ] && echo "  none - safe to create a new branch for '$AREA'."
  exit 0
fi

# ── Mode 2: compare the current branch's files against other unmerged branches ─
CURRENT=$(git branch --show-current)
if [ -z "$CURRENT" ] || [ "$CURRENT" = "$MAIN" ]; then
  echo "On '$CURRENT'. Switch to a feature branch, or pass an <area> to check before branching."
  exit 0
fi

mine=$( { git diff --name-only "$MAIN...$CURRENT" 2>/dev/null
          git diff --name-only 2>/dev/null
          git diff --name-only --cached 2>/dev/null; } | sort -u | grep -v '^$')
if [ -z "$mine" ]; then
  echo "No changed files on '$CURRENT' vs $MAIN yet."
  exit 0
fi

echo "Files changed on '$CURRENT':"
echo "$mine" | sed 's/^/  /'
echo ""
echo "Other unmerged branches that also touch these files:"
collision=0
while IFS= read -r b; do
  [ -z "$b" ] || [ "$b" = "$CURRENT" ] && continue
  theirs=$(git diff --name-only "$MAIN...$b" 2>/dev/null | sort -u)
  overlap=$(comm -12 <(echo "$mine") <(echo "$theirs"))
  if [ -n "$overlap" ]; then
    collision=1
    echo "  ⚠️  [$b] (last commit $(git log -1 --format='%ci' "$b" 2>/dev/null)) overlaps on:"
    echo "$overlap" | sed 's/^/        /'
  fi
done < <(unmerged_branches)
[ "$collision" -eq 0 ] && echo "  none - no divergence risk detected."
