#!/usr/bin/env bash
# scripts/lib/detect.sh — Shared preamble for file-scanning detection scripts
#
# Provides detect_init() which sets $FILE and $EXT, handles early-exit for
# missing/empty args and non-existent files. Source this at the top of any
# detection script to avoid repeating the same 4 lines.
#
# Usage:
#   source "${SCRIPT_DIR}/lib/detect.sh"
#   detect_init "$1"
#   # $FILE and $EXT are now set; script exited if file missing

detect_init() {
    FILE="${1:-}"
    [ -z "$FILE" ] && exit 0
    [ -f "$FILE" ] || exit 0
    EXT="${FILE##*.}"
}
