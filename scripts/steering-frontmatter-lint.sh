#!/usr/bin/env bash
# scripts/steering-frontmatter-lint.sh — Validate steering file frontmatter
#
# Every file in .kiro/steering/ must have explicit, valid frontmatter with:
# - inclusion: one of (always, fileMatch, manual)
# - fileMatchPattern: required if inclusion is fileMatch
#
# Per R7 from improvement recommendations research.
#
# Usage: steering-frontmatter-lint.sh [file]
#   If no file given, scans all .kiro/steering/*.md files.

set -euo pipefail

VALID_INCLUSIONS="always fileMatch manual"
ERRORS=0

lint_file() {
    local file="$1"
    local basename
    basename=$(basename "$file")

    # Skip the overrides file (user-managed)
    if [[ "$basename" == "user-project-overrides.md" ]]; then
        return 0
    fi

    # Check for frontmatter existence (starts with ---)
    local first_line
    first_line=$(head -1 "$file")
    if [[ "$first_line" != "---" ]]; then
        echo "⚠️ ${basename}: MISSING FRONTMATTER — no opening '---' found"
        ERRORS=$((ERRORS + 1))
        return
    fi

    # Extract inclusion value
    local inclusion
    inclusion=$(sed -n '/^---$/,/^---$/p' "$file" | grep -E '^inclusion:' | sed 's/inclusion:\s*//' | tr -d ' ')

    if [ -z "$inclusion" ]; then
        echo "⚠️ ${basename}: MISSING 'inclusion:' in frontmatter"
        ERRORS=$((ERRORS + 1))
        return
    fi

    # Validate inclusion value
    local valid=false
    for v in $VALID_INCLUSIONS; do
        if [[ "$inclusion" == "$v" ]]; then
            valid=true
            break
        fi
    done

    if [ "$valid" = false ]; then
        echo "⚠️ ${basename}: INVALID inclusion '${inclusion}' — must be one of: ${VALID_INCLUSIONS}"
        ERRORS=$((ERRORS + 1))
    fi

    # If fileMatch, check for pattern
    if [[ "$inclusion" == "fileMatch" ]]; then
        local has_pattern
        has_pattern=$(sed -n '/^---$/,/^---$/p' "$file" | grep -E '^fileMatch' || true)
        if [ -z "$has_pattern" ]; then
            echo "⚠️ ${basename}: inclusion is 'fileMatch' but no fileMatchPattern defined"
            ERRORS=$((ERRORS + 1))
        fi
    fi
}

main() {
    if [ -n "${1:-}" ]; then
        lint_file "$1"
    else
        # Scan all steering files
        for file in .kiro/steering/*.md; do
            [ -f "$file" ] || continue
            lint_file "$file"
        done
    fi

    if [ "$ERRORS" -gt 0 ]; then
        echo ""
        echo "steering-frontmatter-lint: ${ERRORS} issue(s) found."
        echo "Valid inclusion values: ${VALID_INCLUSIONS}"
    fi
}

main "$@"
