#!/usr/bin/env bash
# scripts/bug-scribe.sh — Automated bug documentation from inline markers
#
# Two subcommands:
#   discover <file>  — Triggered on fileEdit. Detects # bug: markers, scaffolds bug doc.
#   resolve          — Triggered on beforeCommit. Captures fix diff into existing bug doc.
#
# Marker format (case-insensitive on trigger word and category):
#   # bug: CATEGORY — description
#   // bug: CATEGORY — description
#
# Zero external dependencies: bash 4+, sed, awk, git, sha256sum/shasum.
# Zero LLM calls. Deterministic, instant, identical every time.
#
# See: .kiro/specs/bug-scribe/design.md for full architecture.

set -euo pipefail

# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────

# Source the reusable template library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/template.sh"

BUGS_DIR="docs/bugs"
TEMPLATE="${BUGS_DIR}/BUG-000-template.md"
PROCESSED_LOG="${BUGS_DIR}/.bug-scribe-processed"
CHOKEPOINT_LOG="docs/engineering/chokepoint-log.md"

# Regex patterns
# Case-insensitive on bug/BUG/Bug, category normalized to uppercase by script
# Structure: (# or //) space bug: space CATEGORY space em-dash space description
FIRE_PATTERN='(#|//)[[:space:]]+[Bb][Uu][Gg]:[[:space:]]+([A-Za-z_]+)[[:space:]]+—[[:space:]]+(.+)$'

# Near-miss: looks like a bug marker but doesn't match strict structure
NEARMISS_PATTERN='(#|//)[[:space:]]*[Bb][Uu][Gg][[:space:]]*:'

# Known categories (read from chokepoint log if it exists)
KNOWN_CATEGORIES="ROUTE_ORDERING CSS_OVERSIGHT LAYOUT_OVERFLOW QUERY_INVALIDATION TYPE_MISMATCH IMPORT_ERROR DEPLOY_REGRESSION TOOL_MISUSE STATE_SYNC RACE_CONDITION"

# ──────────────────────────────────────────────
# Utility Functions
# ──────────────────────────────────────────────

# Compute SHA-256 checksum for idempotency
compute_checksum() {
    local input="$1"
    if command -v sha256sum &>/dev/null; then
        echo -n "$input" | sha256sum | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        echo -n "$input" | shasum -a 256 | cut -d' ' -f1
    else
        # Fallback: use md5 (less ideal but available everywhere)
        echo -n "$input" | md5sum | cut -d' ' -f1
    fi
}

# Check if a marker has already been processed
is_processed() {
    local checksum="$1"
    if [ -f "$PROCESSED_LOG" ]; then
        grep -q "^${checksum}$" "$PROCESSED_LOG" 2>/dev/null
        return $?
    fi
    return 1
}

# Mark a marker as processed
mark_processed() {
    local checksum="$1"
    echo "$checksum" >> "$PROCESSED_LOG"
}

# Get the next BUG number
next_bug_number() {
    local highest
    highest=$(ls "${BUGS_DIR}"/BUG-*.md 2>/dev/null \
        | grep -oE 'BUG-[0-9]+' \
        | sed 's/BUG-//' \
        | sort -n \
        | tail -1)
    if [ -z "$highest" ]; then
        echo 1
    else
        echo $((highest + 1))
    fi
}

# Get the next CP (chokepoint) number
next_cp_number() {
    if [ ! -f "$CHOKEPOINT_LOG" ]; then
        echo 1
        return
    fi
    local highest
    highest=$(grep -oE 'CP-[0-9]+' "$CHOKEPOINT_LOG" 2>/dev/null \
        | sed 's/CP-//' \
        | sort -n \
        | tail -1)
    if [ -z "$highest" ]; then
        echo 1
    else
        echo $((highest + 1))
    fi
}

# Validate category against known taxonomy
validate_category() {
    local category="$1"
    if echo "$KNOWN_CATEGORIES" | grep -qw "$category"; then
        return 0
    fi
    # Also check chokepoint log for dynamically added categories
    if [ -f "$CHOKEPOINT_LOG" ] && grep -q "Pattern:.*${category}" "$CHOKEPOINT_LOG" 2>/dev/null; then
        return 0
    fi
    return 1
}

# ──────────────────────────────────────────────
# Subcommand: discover
# ──────────────────────────────────────────────

cmd_discover() {
    local file="$1"

    if [ ! -f "$file" ]; then
        exit 0
    fi

    # Check for valid markers
    local matches
    matches=$(grep -nE "$FIRE_PATTERN" "$file" 2>/dev/null || true)

    if [ -z "$matches" ]; then
        # Check for near-misses
        local near_misses
        near_misses=$(grep -nE "$NEARMISS_PATTERN" "$file" 2>/dev/null || true)

        if [ -n "$near_misses" ]; then
            # Filter out lines that actually match the fire pattern (already handled above)
            local real_near_misses
            real_near_misses=$(echo "$near_misses" | grep -vE "$FIRE_PATTERN" || true)

            if [ -n "$real_near_misses" ]; then
                echo "Bug Scribe: Near-miss marker detected in $file"
                echo "  Found: $(echo "$real_near_misses" | head -1 | cut -d: -f2-)"
                echo "  Expected format: # bug: CATEGORY — description"
                echo "  (case-insensitive on 'bug' and category; em-dash required)"
            fi
        fi
        exit 0
    fi

    # Process each marker in the file
    while IFS= read -r match_line; do
        local line_num category description

        line_num=$(echo "$match_line" | cut -d: -f1)
        # Extract category and description using sed
        category=$(echo "$match_line" | sed -E "s/.*[Bb][Uu][Gg]:[[:space:]]+([A-Za-z_]+)[[:space:]]+—.*/\1/")
        description=$(echo "$match_line" | sed -E "s/.*[Bb][Uu][Gg]:[[:space:]]+[A-Za-z_]+[[:space:]]+—[[:space:]]+(.*)/\1/")

        # Normalize category to UPPER_SNAKE_CASE
        category=$(echo "$category" | tr '[:lower:]' '[:upper:]')

        # Idempotency check
        local checksum_input="${file}:${line_num}:${category}:${description}"
        local checksum
        checksum=$(compute_checksum "$checksum_input")

        if is_processed "$checksum"; then
            continue
        fi

        # Determine bug number and ID
        local bug_num bug_id bug_id_lower slug
        bug_num=$(next_bug_number)
        bug_id=$(printf "BUG-%03d" "$bug_num")
        bug_id_lower=$(echo "$bug_id" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
        slug=$(echo "$category" | tr '[:upper:]' '[:lower:]')

        # Extract code context (±5 lines around marker)
        local total_lines context_start context_end context
        total_lines=$(wc -l < "$file")
        context_start=$((line_num - 5))
        [ "$context_start" -lt 1 ] && context_start=1
        context_end=$((line_num + 5))
        [ "$context_end" -gt "$total_lines" ] && context_end="$total_lines"
        context=$(sed -n "${context_start},${context_end}p" "$file")

        # Get current date and branch
        local date_str branch
        date_str=$(date +%Y-%m-%d)
        branch=$(git branch --show-current 2>/dev/null || echo "unknown")

        # Create temp files for multi-line injection
        local ctx_tmp
        ctx_tmp=$(mktemp)
        trap "rm -f '$ctx_tmp'" EXIT

        echo "$context" > "$ctx_tmp"

        # Generate bug doc from template
        local output_file="${BUGS_DIR}/${bug_id}-${slug}.md"

        if [ ! -f "$TEMPLATE" ]; then
            echo "Bug Scribe: ERROR — template not found at $TEMPLATE"
            exit 1
        fi

        # Render template using the reusable library
        render_template "$TEMPLATE" "$output_file" \
            "BUG_ID=${bug_id}" \
            "BUG_ID_LOWER=${bug_id_lower}" \
            "CATEGORY=${category}" \
            "FILE=${file}" \
            "DATE=${date_str}" \
            "BRANCH=${branch}" \
            "DESCRIPTION=${description}" \
            "STATUS=OPEN" \
            "SEVERITY=TBD" \
            "SOLUTION=Pending — will be captured from commit message" \
            "DIFF=Pending fix — will be captured on commit" \
            "CONTEXT=@${ctx_tmp}"

        # Category validation
        if ! validate_category "$category"; then
            echo "Bug Scribe: Unknown category '${category}' — add to chokepoint-logging.md taxonomy if recurring."
        fi

        # Append to chokepoint log
        if [ -f "$CHOKEPOINT_LOG" ]; then
            local cp_num
            cp_num=$(next_cp_number)
            local cp_id
            cp_id=$(printf "CP-%03d" "$cp_num")
            cat >> "$CHOKEPOINT_LOG" << EOF

### ${cp_id}: ${description} | ${file} | ${category} | auto-generated by Bug Scribe
- **Date:** ${date_str}
- **Bug:** ${bug_id}
- **Pattern:** ${category}
- **File:** \`${file}\`
- **Status:** Open — pending resolution
EOF
        fi

        # Mark as processed
        mark_processed "$checksum"

        # Clean up temp
        rm -f "$ctx_tmp"
        trap - EXIT

        echo "Bug Scribe: Created ${output_file} (${bug_id}: ${description})"

    done <<< "$matches"
}

# ──────────────────────────────────────────────
# Subcommand: resolve
# ──────────────────────────────────────────────

cmd_resolve() {
    # Scan staged files for bug markers
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null || true)

    if [ -z "$staged_files" ]; then
        exit 0
    fi

    local found_any=false

    while IFS= read -r file; do
        # Skip non-existent files (deleted)
        [ -f "$file" ] || continue

        # Check staged version for markers
        local markers
        markers=$(git show ":${file}" 2>/dev/null | grep -nE "$FIRE_PATTERN" || true)

        if [ -z "$markers" ]; then
            continue
        fi

        while IFS= read -r match_line; do
            local category description

            # Extract category and description
            category=$(echo "$match_line" | sed -E "s/.*[Bb][Uu][Gg]:[[:space:]]+([A-Za-z_]+)[[:space:]]+—.*/\1/")
            category=$(echo "$category" | tr '[:lower:]' '[:upper:]')
            description=$(echo "$match_line" | sed -E "s/.*[Bb][Uu][Gg]:[[:space:]]+[A-Za-z_]+[[:space:]]+—[[:space:]]+(.*)/\1/")

            local slug
            slug=$(echo "$category" | tr '[:upper:]' '[:lower:]')

            # Find matching bug doc (by file reference or category slug in filename)
            local bug_doc
            bug_doc=$(grep -rl "| \`${file}\`" "${BUGS_DIR}"/BUG-*.md 2>/dev/null | head -1 || true)

            if [ -z "$bug_doc" ]; then
                # Try matching by category slug in filename
                bug_doc=$(ls "${BUGS_DIR}"/BUG-*-${slug}.md 2>/dev/null | tail -1 || true)
            fi

            if [ -z "$bug_doc" ]; then
                # No matching doc found — discover might not have run yet, skip
                continue
            fi

            # Check if diff already captured (idempotency)
            if ! grep -q "Pending fix" "$bug_doc" 2>/dev/null; then
                # Already resolved, skip
                continue
            fi

            # Capture the staged diff for this file
            local diff_content
            diff_content=$(git diff --cached -- "$file" 2>/dev/null || echo "No diff available")

            # Capture commit message (solution)
            local commit_msg
            commit_msg=$(cat .git/COMMIT_EDITMSG 2>/dev/null || echo "No commit message captured")

            # Get current date
            local date_str
            date_str=$(date +%Y-%m-%d)

            # Create temp files for multi-line injection
            local diff_tmp msg_tmp
            diff_tmp=$(mktemp)
            msg_tmp=$(mktemp)
            trap "rm -f '$diff_tmp' '$msg_tmp'" EXIT

            echo "$diff_content" > "$diff_tmp"
            echo "$commit_msg" > "$msg_tmp"

            # Inject diff and solution using awk (multi-line replacement)
            awk -v diff_file="$diff_tmp" '
                /Pending fix/ { while ((getline line < diff_file) > 0) print line; next }
                { print }
            ' "$bug_doc" > "${bug_doc}.tmp" && mv "${bug_doc}.tmp" "$bug_doc"

            awk -v msg_file="$msg_tmp" '
                /Pending — will be captured from commit message/ { while ((getline line < msg_file) > 0) print line; next }
                { print }
            ' "$bug_doc" > "${bug_doc}.tmp" && mv "${bug_doc}.tmp" "$bug_doc"

            # Update status, date, timeline (single-line replacements — portable sed)
            _template_sed_replace "$bug_doc" "dummy" "dummy" 2>/dev/null || true  # ensure function is loaded
            if sed --version 2>/dev/null | grep -q GNU; then
                sed -i 's/| OPEN/| IN_PROGRESS/' "$bug_doc"
                sed -i "s/| \*\*Fixed\*\* | -/| **Fixed** | ${date_str}/" "$bug_doc"
                sed -i "s/| Fix committed | - | -/| Fix committed | ${date_str} | Bug Scribe (auto)/" "$bug_doc"
            else
                sed -i '' 's/| OPEN/| IN_PROGRESS/' "$bug_doc"
                sed -i '' "s/| \*\*Fixed\*\* | -/| **Fixed** | ${date_str}/" "$bug_doc"
                sed -i '' "s/| Fix committed | - | -/| Fix committed | ${date_str} | Bug Scribe (auto)/" "$bug_doc"
            fi

            # Stage the updated bug doc
            git add "$bug_doc"

            # Clean up
            rm -f "$diff_tmp" "$msg_tmp"
            trap - EXIT

            found_any=true
            echo "Bug Scribe: Updated ${bug_doc} with fix diff + solution"

        done <<< "$markers"
    done <<< "$staged_files"

    if [ "$found_any" = false ]; then
        # Silent exit — no markers in staged files needing resolution
        exit 0
    fi
}

# ──────────────────────────────────────────────
# Main: Route to subcommand
# ──────────────────────────────────────────────

main() {
    local subcommand="${1:-}"

    case "$subcommand" in
        discover)
            if [ -z "${2:-}" ]; then
                echo "Bug Scribe: ERROR — discover requires a file path"
                echo "Usage: bug-scribe.sh discover <file>"
                exit 1
            fi
            cmd_discover "$2"
            ;;
        resolve)
            cmd_resolve
            ;;
        *)
            echo "Bug Scribe: Automated bug documentation from inline markers"
            echo ""
            echo "Usage:"
            echo "  bug-scribe.sh discover <file>   # Scaffold bug doc on marker detection"
            echo "  bug-scribe.sh resolve           # Capture fix diff on commit"
            echo ""
            echo "Marker format: # bug: CATEGORY — description"
            exit 0
            ;;
    esac
}

main "$@"
