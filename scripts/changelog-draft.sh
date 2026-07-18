#!/usr/bin/env bash
# scripts/changelog-draft.sh — Draft a changelog entry from git log
#
# Reads commits since the last CHANGELOG.md modification, groups them by
# conventional-commit type, and appends a draft entry to the changelog.
#
# Zero dependencies beyond bash + git. Deterministic.
#
# Usage: changelog-draft.sh [--dry-run]
#   --dry-run: print the draft to stdout without writing to the changelog

set -euo pipefail

# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────

CHANGELOG="docs/changelogs/CHANGELOG.md"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# ──────────────────────────────────────────────
# Determine the commit range
# ──────────────────────────────────────────────

if [ ! -f "$CHANGELOG" ]; then
    echo "changelog-draft: No changelog found at $CHANGELOG"
    exit 0
fi

# Find the last commit that modified the changelog
LAST_CHANGELOG_COMMIT=$(git log -1 --format=%H -- "$CHANGELOG" 2>/dev/null || true)

if [ -z "$LAST_CHANGELOG_COMMIT" ]; then
    # Changelog exists but was never committed — use all commits
    COMMIT_RANGE="HEAD"
    COMMITS=$(git log --oneline --format="%s" 2>/dev/null || true)
else
    # Commits since last changelog update
    COMMITS=$(git log --oneline --format="%s" "${LAST_CHANGELOG_COMMIT}..HEAD" 2>/dev/null || true)
fi

if [ -z "$COMMITS" ]; then
    echo "OK"
    exit 0
fi

COMMIT_COUNT=$(echo "$COMMITS" | wc -l | tr -d ' ')

if [ "$COMMIT_COUNT" -lt 1 ]; then
    echo "OK"
    exit 0
fi

# ──────────────────────────────────────────────
# Group commits by conventional-commit prefix
# ──────────────────────────────────────────────

DATE=$(date +%Y-%m-%d)

# Extract and group
FEATS=$(echo "$COMMITS" | grep -iE '^feat(\(|:)' | sed -E 's/^feat(\([^)]*\))?:\s*//' || true)
FIXES=$(echo "$COMMITS" | grep -iE '^fix(\(|:)' | sed -E 's/^fix(\([^)]*\))?:\s*//' || true)
DOCS=$(echo "$COMMITS" | grep -iE '^docs(\(|:)' | sed -E 's/^docs(\([^)]*\))?:\s*//' || true)
REFACTORS=$(echo "$COMMITS" | grep -iE '^refactor(\(|:)' | sed -E 's/^refactor(\([^)]*\))?:\s*//' || true)
CHORES=$(echo "$COMMITS" | grep -iE '^chore(\(|:)' | sed -E 's/^chore(\([^)]*\))?:\s*//' || true)
TESTS=$(echo "$COMMITS" | grep -iE '^test(\(|:)' | sed -E 's/^test(\([^)]*\))?:\s*//' || true)
UI=$(echo "$COMMITS" | grep -iE '^ui(\(|:)' | sed -E 's/^ui(\([^)]*\))?:\s*//' || true)
OTHER=$(echo "$COMMITS" | grep -ivE '^(feat|fix|docs|refactor|chore|test|ui)(\(|:)' || true)

# ──────────────────────────────────────────────
# Build the draft entry
# ──────────────────────────────────────────────

DRAFT=""
DRAFT+="## ${DATE} — Draft (${COMMIT_COUNT} commits since last update)"
DRAFT+=$'\n'

if [ -n "$FEATS" ]; then
    DRAFT+=$'\n### Added\n\n'
    while IFS= read -r line; do
        [ -n "$line" ] && DRAFT+="- ${line}"$'\n'
    done <<< "$FEATS"
fi

if [ -n "$FIXES" ]; then
    DRAFT+=$'\n### Fixed\n\n'
    while IFS= read -r line; do
        [ -n "$line" ] && DRAFT+="- ${line}"$'\n'
    done <<< "$FIXES"
fi

if [ -n "$REFACTORS" ]; then
    DRAFT+=$'\n### Changed\n\n'
    while IFS= read -r line; do
        [ -n "$line" ] && DRAFT+="- ${line}"$'\n'
    done <<< "$REFACTORS"
fi

if [ -n "$DOCS" ]; then
    DRAFT+=$'\n### Documentation\n\n'
    while IFS= read -r line; do
        [ -n "$line" ] && DRAFT+="- ${line}"$'\n'
    done <<< "$DOCS"
fi

if [ -n "$UI" ]; then
    DRAFT+=$'\n### UI\n\n'
    while IFS= read -r line; do
        [ -n "$line" ] && DRAFT+="- ${line}"$'\n'
    done <<< "$UI"
fi

if [ -n "$TESTS" ]; then
    DRAFT+=$'\n### Tests\n\n'
    while IFS= read -r line; do
        [ -n "$line" ] && DRAFT+="- ${line}"$'\n'
    done <<< "$TESTS"
fi

if [ -n "$CHORES" ]; then
    DRAFT+=$'\n### Maintenance\n\n'
    while IFS= read -r line; do
        [ -n "$line" ] && DRAFT+="- ${line}"$'\n'
    done <<< "$CHORES"
fi

if [ -n "$OTHER" ]; then
    DRAFT+=$'\n### Other\n\n'
    while IFS= read -r line; do
        [ -n "$line" ] && DRAFT+="- ${line}"$'\n'
    done <<< "$OTHER"
fi

# ──────────────────────────────────────────────
# Output or write
# ──────────────────────────────────────────────

if [ "$DRY_RUN" = true ]; then
    echo "$DRAFT"
    echo ""
    echo "changelog-draft: (dry-run) ${COMMIT_COUNT} commits grouped. Would insert above into ${CHANGELOG}."
else
    # Insert after the "## Unreleased" line (or at the top after the header)
    if grep -q "^## Unreleased" "$CHANGELOG"; then
        # Insert after "## Unreleased" line
        UNRELEASED_LINE=$(grep -n "^## Unreleased" "$CHANGELOG" | head -1 | cut -d: -f1)
        {
            head -n "$UNRELEASED_LINE" "$CHANGELOG"
            echo ""
            echo "$DRAFT"
            tail -n +"$((UNRELEASED_LINE + 1))" "$CHANGELOG"
        } > "${CHANGELOG}.tmp" && mv "${CHANGELOG}.tmp" "$CHANGELOG"
    else
        # No Unreleased section — prepend after the first header line
        {
            head -n 5 "$CHANGELOG"
            echo ""
            echo "$DRAFT"
            tail -n +6 "$CHANGELOG"
        } > "${CHANGELOG}.tmp" && mv "${CHANGELOG}.tmp" "$CHANGELOG"
    fi

    echo "changelog-draft: Drafted ${COMMIT_COUNT} commits (grouped by type) into ${CHANGELOG}"
fi
