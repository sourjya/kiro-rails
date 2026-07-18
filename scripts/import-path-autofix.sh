#!/usr/bin/env bash
# scripts/import-path-autofix.sh — Detect and warn on deep relative imports
#
# Per import-path-rules.md: NEVER use ../../ or deeper relative paths.
# - TypeScript: should use @/ alias
# - Python: should use package imports
#
# This script WARNS (does not auto-rewrite) because:
# - TS rewrite requires tsconfig paths to be configured (can't verify here)
# - Python rewrite depends on package structure
#
# Usage: import-path-autofix.sh <file>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/detect.sh"

main() {
    detect_init "${1:-}"
    local findings=""

    case "$EXT" in
        ts|tsx|js|jsx)
            # Detect: from '../../...' or import '../../...'
            findings=$(grep -nE "(from|import)\s+['\"]\.\.\/\.\.\/" "$FILE" 2>/dev/null || true)
            if [ -n "$findings" ]; then
                echo "🚫 DEEP RELATIVE IMPORTS in ${FILE}:"
                echo "$findings" | while IFS= read -r line; do
                    echo "  Line $(echo "$line" | cut -d: -f1): $(echo "$line" | cut -d: -f2- | sed 's/^\s*//')"
                done
                echo ""
                echo "Per import-path-rules.md: Use @/ alias instead of ../../"
                echo "  Example: import { X } from '@/features/auth/service'"
            fi
            ;;
        py)
            # Detect: from ...module or from ....module (3+ dots)
            findings=$(grep -nE "^\s*from\s+\.{3,}" "$FILE" 2>/dev/null || true)
            if [ -n "$findings" ]; then
                echo "🚫 DEEP RELATIVE IMPORTS in ${FILE}:"
                echo "$findings" | while IFS= read -r line; do
                    echo "  Line $(echo "$line" | cut -d: -f1): $(echo "$line" | cut -d: -f2- | sed 's/^\s*//')"
                done
                echo ""
                echo "Per import-path-rules.md: Use absolute package imports instead of ../../"
                echo "  Example: from packages.common.models import X"
            fi
            ;;
    esac
}

main "$@"
