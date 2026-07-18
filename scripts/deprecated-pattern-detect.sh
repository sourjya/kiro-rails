#!/usr/bin/env bash
# scripts/deprecated-pattern-detect.sh — Detect banned/deprecated patterns on save
#
# Scans a file for patterns explicitly banned in steering files:
#   - datetime.utcnow() → use datetime.now(timezone.utc)
#   - window.alert/confirm/prompt → use themed dialog
#   - console.log in non-test files → use structured logging (warn only)
#
# Configurable: add patterns to the PATTERNS array below.
# Per project-conventions.md, frontend-patterns.md, error-handling-performance.md.
#
# Usage: deprecated-pattern-detect.sh <file>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/detect.sh"

main() {
    detect_init "${1:-}"
    local findings=""

    # ──────────────────────────────────────────
    # Python patterns
    # ──────────────────────────────────────────
    if [[ "$EXT" == "py" ]]; then
        # datetime.utcnow() — deprecated since Python 3.12
        local utcnow
        utcnow=$(grep -n 'datetime\.utcnow\s*(' "$FILE" 2>/dev/null || true)
        if [ -n "$utcnow" ]; then
            findings+="  ⚠️ datetime.utcnow() is deprecated. Use datetime.now(timezone.utc)"$'\n'
            findings+="$(echo "$utcnow" | sed 's/^/    Line /')"$'\n'
        fi

        # utcfromtimestamp — also deprecated
        local utcfrom
        utcfrom=$(grep -n 'datetime\.utcfromtimestamp\s*(' "$FILE" 2>/dev/null || true)
        if [ -n "$utcfrom" ]; then
            findings+="  ⚠️ datetime.utcfromtimestamp() is deprecated. Use datetime.fromtimestamp(ts, tz=timezone.utc)"$'\n'
            findings+="$(echo "$utcfrom" | sed 's/^/    Line /')"$'\n'
        fi

        # print() in non-test, non-script files (should use logging)
        if [[ "$FILE" != *"test_"* ]] && [[ "$FILE" != *"/scripts/"* ]]; then
            local prints
            prints=$(grep -n '^\s*print\s*(' "$FILE" 2>/dev/null | head -3 || true)
            if [ -n "$prints" ]; then
                local count
                count=$(grep -c '^\s*print\s*(' "$FILE" 2>/dev/null || echo 0)
                findings+="  💡 ${count}x print() found. Consider structured logging (info-only, not blocking)."$'\n'
            fi
        fi
    fi

    # ──────────────────────────────────────────
    # JavaScript/TypeScript patterns
    # ──────────────────────────────────────────
    if [[ "$EXT" == "ts" || "$EXT" == "tsx" || "$EXT" == "js" || "$EXT" == "jsx" ]]; then
        # window.alert / window.confirm / window.prompt
        local native_dialogs
        native_dialogs=$(grep -n 'window\.\(alert\|confirm\|prompt\)\s*(' "$FILE" 2>/dev/null || true)
        if [ -n "$native_dialogs" ]; then
            findings+="  🚫 Native browser dialogs forbidden. Use themed dialog components."$'\n'
            findings+="$(echo "$native_dialogs" | sed 's/^/    Line /')"$'\n'
        fi

        # Bare alert/confirm/prompt (without window. prefix)
        local bare_dialogs
        bare_dialogs=$(grep -n '^\s*\(alert\|confirm\|prompt\)\s*(' "$FILE" 2>/dev/null || true)
        if [ -n "$bare_dialogs" ]; then
            findings+="  🚫 Native browser dialogs forbidden. Use themed dialog components."$'\n'
            findings+="$(echo "$bare_dialogs" | sed 's/^/    Line /')"$'\n'
        fi

        # console.log in non-test files
        if [[ "$FILE" != *".test."* ]] && [[ "$FILE" != *".spec."* ]] && [[ "$FILE" != *"/tests/"* ]]; then
            local console_logs
            console_logs=$(grep -c 'console\.log\s*(' "$FILE" 2>/dev/null || echo 0)
            if [ "$console_logs" -ge 3 ]; then
                findings+="  💡 ${console_logs}x console.log() found. Consider structured logging for production code."$'\n'
            fi
        fi

        # var keyword (should be const/let)
        local vars
        vars=$(grep -n '^\s*var\s\+' "$FILE" 2>/dev/null || true)
        if [ -n "$vars" ]; then
            local var_count
            var_count=$(echo "$vars" | wc -l | tr -d ' ')
            findings+="  ⚠️ ${var_count}x 'var' keyword. Use 'const' or 'let' instead."$'\n'
        fi
    fi

    # ──────────────────────────────────────────
    # Output
    # ──────────────────────────────────────────
    if [ -n "$findings" ]; then
        echo "⚠️ DEPRECATED PATTERNS in ${FILE}:"
        echo "$findings"
    fi
}

main "$@"
