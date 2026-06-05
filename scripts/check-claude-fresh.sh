#!/usr/bin/env bash
# check-claude-fresh.sh - verify the committed .claude/ matches what export-to-claude.sh produces.
#
# The committed .claude/ tree is a GENERATED artifact (source of truth = .kiro/*). It drifts if
# someone edits .kiro/ without regenerating. Run this before tagging a release; non-zero exit = stale.
#
# Usage: bash scripts/check-claude-fresh.sh
# See versioning.md release checklist and docs/references/kiro-to-claude-compatibility-2026-06-05.md
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if [ ! -d .claude ]; then
  echo "No committed .claude/ to check. Run: bash scripts/export-to-claude.sh"
  exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

bash scripts/export-to-claude.sh "$TMP/.claude" >/dev/null 2>&1 || { echo "Generator failed."; exit 1; }

# settings.local.json is user-local (gitignored) - never part of the generated artifact.
if diff -rq --exclude='settings.local.json' .claude "$TMP/.claude" >/dev/null 2>&1; then
  echo "OK: committed .claude/ is in sync with .kiro/ source."
  exit 0
else
  echo "STALE: committed .claude/ differs from generated output. Regenerate before release:"
  echo "  bash scripts/export-to-claude.sh && git add .claude"
  echo "--- drift ---"
  diff -rq --exclude='settings.local.json' .claude "$TMP/.claude" 2>&1 | sed 's/^/  /'
  exit 1
fi
