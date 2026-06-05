#!/bin/bash
# session-guard.sh - guard against concurrent-session interference on a shared working tree.
#
# Records a per-session lock (PID, branch, HEAD) under logs/ (gitignored) and warns if:
#   - another LIVE session holds a lock on this tree, or
#   - HEAD/branch moved unexpectedly since this session last checkpointed.
#
# Usage:
#   bash scripts/session-guard.sh           # record/refresh this session's lock and check for collisions
#   bash scripts/session-guard.sh --status  # report only, do not write the lock
#
# Set KIRO_SESSION_PID to a stable id if your harness reuses shells across calls.
# See .kiro/steering/session-isolation.md
set -uo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository."
  exit 1
fi

ROOT=$(git rev-parse --show-toplevel)
LOCK="$ROOT/logs/.session-lock"
SELF_PID=${KIRO_SESSION_PID:-$PPID}
BRANCH=$(git -C "$ROOT" branch --show-current 2>/dev/null)
HEAD=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)
MODE="${1:-}"

echo "Project root: $ROOT"
echo "Branch: ${BRANCH:-<detached>}  HEAD: $HEAD  PID: $SELF_PID"

alive() { kill -0 "$1" 2>/dev/null; }

if [ -f "$LOCK" ]; then
  IFS='|' read -r oPID oBR oHEAD _oTS < "$LOCK"
  if [ -n "${oPID:-}" ] && [ "$oPID" != "$SELF_PID" ] && alive "$oPID"; then
    echo "⚠️  ANOTHER LIVE SESSION holds this tree: PID $oPID on branch ${oBR:-?} (HEAD ${oHEAD:-?})."
    echo "    Do NOT run destructive git here. Coordinate, or isolate: git worktree add ../$(basename "$ROOT")-wt ${BRANCH:-main}"
  fi
  if [ "${oPID:-}" = "$SELF_PID" ] && [ -n "${oHEAD:-}" ] && [ "$oHEAD" != "$HEAD" ]; then
    echo "⚠️  HEAD MOVED since your last checkpoint (${oHEAD} -> ${HEAD}). If you did not move it, a foreign actor touched the tree - STOP and verify before any git write."
  fi
fi

if [ "$MODE" != "--status" ]; then
  mkdir -p "$(dirname "$LOCK")"
  printf '%s|%s|%s|%s\n' "$SELF_PID" "$BRANCH" "$HEAD" "$(date +%s)" > "$LOCK"
fi
