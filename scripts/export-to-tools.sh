#!/usr/bin/env bash
set -euo pipefail

# kiro-rails-export: Generate AI tool config files from kiro-rails steering files
# Exports to: .cursorrules, .github/copilot-instructions.md, AGENTS.md
#             .claude/ is delegated to scripts/export-to-claude.sh (its single owner).
#
# Usage: ./scripts/export-to-tools.sh [--all | --cursor | --claude | --copilot | --codex]
#
# The header() below stamps a generation timestamp. That is fine for the three targets
# written here (none are byte-compared by a freshness gate) but MUST NOT reach
# .claude/ - see export_claude() and KRL-8.

STEERING_DIR=".kiro/steering"
OVERRIDES_FILE="$STEERING_DIR/user-project-overrides.md"

# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────
header() {
  cat <<EOF
# Project Rules (auto-generated from kiro-rails steering files)
# Source: .kiro/steering/*.md
# Do not edit directly — modify the steering files and re-export.
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

EOF
}

collect_steering() {
  local output=""
  # Project overrides first (if exists)
  if [ -f "$OVERRIDES_FILE" ]; then
    output+="$(cat "$OVERRIDES_FILE")"
    output+=$'\n\n---\n\n'
  fi
  # Then all other steering files (sorted, skip overrides)
  for file in $(find "$STEERING_DIR" -name "*.md" -not -name "user-project-overrides.md" | sort); do
    output+="$(cat "$file")"
    output+=$'\n\n---\n\n'
  done
  echo "$output"
}

# ──────────────────────────────────────────────
# Exporters
# ──────────────────────────────────────────────
export_cursor() {
  echo "  → .cursorrules"
  {
    header
    collect_steering
  } > .cursorrules
}

# The Claude layer is NOT generated here. scripts/export-to-claude.sh is its single
# owner: it emits the whole tree (CLAUDE.md, settings.json hooks, agents/, commands/,
# skills/, hooks/), and the committed .claude/ tree is a release gate verified by
# scripts/check-claude-fresh.sh.
#
# Writing CLAUDE.md from here would (a) clobber that file with a degraded, differently
# -headed copy, and (b) stamp header()'s wall-clock timestamp into a checked-in
# artifact, making it non-idempotent and flipping check-claude-fresh.sh to STALE on
# every run. Delegate instead. See KRL-8.
export_claude() {
  echo "  → .claude/ (delegating to export-to-claude.sh)"
  bash "$(dirname "${BASH_SOURCE[0]}")/export-to-claude.sh"
}

export_copilot() {
  echo "  → .github/copilot-instructions.md"
  mkdir -p .github
  {
    header
    collect_steering
  } > .github/copilot-instructions.md
}

export_codex() {
  echo "  → AGENTS.md"
  {
    header
    collect_steering
  } > AGENTS.md
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
if [ ! -d "$STEERING_DIR" ]; then
  echo "Error: $STEERING_DIR not found. Run this from your project root with kiro-rails installed."
  exit 1
fi

target="${1:---all}"

echo "Exporting kiro-rails steering to AI tool configs..."

case "$target" in
  --cursor)  export_cursor ;;
  --claude)  export_claude ;;
  --copilot) export_copilot ;;
  --codex)   export_codex ;;
  --all)
    export_cursor
    export_claude
    export_copilot
    export_codex
    ;;
  *)
    echo "Usage: $0 [--all | --cursor | --claude | --copilot | --codex]"
    exit 1
    ;;
esac

echo "Done. Add generated files to .gitignore or commit them — your choice."
