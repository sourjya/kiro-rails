#!/usr/bin/env bash
# claude-guard-bash.sh - Claude Code PreToolUse hook (matcher: Bash).
#
# Turns session-isolation.md from advice into enforcement: BLOCKS git operations
# that reach outside the project root - the cross-repo corruption Kiro's hook model
# can't prevent. Reads the Claude hook JSON on stdin; exit 2 = block (reason on stderr).
#
# Wired by export-to-claude.sh into .claude/settings.json:
#   "PreToolUse": [ { "matcher": "Bash",
#     "hooks": [ { "type": "command", "command": "bash .claude/hooks/guard-bash.sh" } ] } ]
#
# Requires jq. If jq is missing it fails open (does not block). See session-isolation.md.
set -uo pipefail

INPUT=$(cat 2>/dev/null)
command -v jq >/dev/null 2>&1 || exit 0
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$CMD" ] && exit 0

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

deny() { echo "BLOCKED by session-isolation: $1" >&2; exit 2; }

inside_root() {
  # $1 = path (may be relative); true if it resolves inside $ROOT
  local abs
  abs=$(cd "$1" 2>/dev/null && pwd) || abs="$1"
  case "$abs" in
    "$ROOT"|"$ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# 1) git -C <path> pointing outside the project root
if printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+-C[[:space:]]'; then
  target=$(printf '%s' "$CMD" | grep -oE '\bgit[[:space:]]+-C[[:space:]]+("[^"]+"|[^[:space:]]+)' | head -1 \
           | sed -E 's/^git[[:space:]]+-C[[:space:]]+//; s/^"//; s/"$//')
  if [ -n "$target" ] && ! inside_root "$target"; then
    deny "git -C targets '$target' outside the project root ($ROOT). Run that work in its own session."
  fi
fi

# 2) destructive git that references an absolute path outside the project root
if printf '%s' "$CMD" | grep -qE '\bgit\b.*(reset[[:space:]]+--hard|checkout[[:space:]]+-f|clean[[:space:]]+-[a-z]*f|cherry-pick|push[[:space:]]+(--force|-f))'; then
  for p in $(printf '%s' "$CMD" | grep -oE '/[A-Za-z0-9._/-]+'); do
    case "$p" in
      "$ROOT"|"$ROOT"/*|/usr/*|/bin/*|/etc/*|/tmp/*|/opt/*) : ;;
      *) inside_root "$p" || deny "destructive git references '$p' outside the project root ($ROOT)." ;;
    esac
  done
fi

exit 0
