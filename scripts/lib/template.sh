#!/usr/bin/env bash
# scripts/lib/template.sh — Reusable template rendering for bash scripts
#
# Renders a template file by replacing {{KEY}} placeholders with values.
# Handles both single-line values and multi-line content injection.
#
# Usage:
#   source scripts/lib/template.sh
#
#   render_template <template> <output> KEY=value KEY2=value KEY3=@filepath ...
#
# Interface:
#   KEY=value       — replaces all {{KEY}} occurrences with the literal value (single-line)
#   KEY=@filepath   — replaces the line containing {{KEY}} with the full file contents (multi-line)
#
# The @filepath convention handles diffs, code context, and any multi-line content
# without escaping issues. The template file remains human-editable.
#
# Portability: bash 4+, sed (POSIX), awk (POSIX). Works on Linux and macOS.
# Dependencies: none beyond coreutils.
#
# Example:
#   render_template docs/bugs/BUG-000-template.md docs/bugs/BUG-042-type_mismatch.md \
#       "BUG_ID=BUG-042" \
#       "CATEGORY=TYPE_MISMATCH" \
#       "DATE=2026-07-18" \
#       "CONTEXT=@/tmp/context.txt" \
#       "DIFF=@/tmp/diff.txt"

# ──────────────────────────────────────────────
# render_template — the single public function
# ──────────────────────────────────────────────

render_template() {
    local template="$1"
    local output="$2"
    shift 2

    if [ ! -f "$template" ]; then
        echo "template.sh: ERROR — template not found: $template" >&2
        return 1
    fi

    # Work on a temp copy so we never modify the template
    local workfile
    workfile=$(mktemp)
    trap "rm -f '$workfile' '${workfile}.new'" RETURN

    cp "$template" "$workfile"

    # Process each KEY=value pair
    for pair in "$@"; do
        local key="${pair%%=*}"
        local val="${pair#*=}"

        if [[ "$val" == @* ]]; then
            # Multi-line injection: read from file
            local filepath="${val#@}"

            if [ ! -f "$filepath" ]; then
                echo "template.sh: WARNING — file not found for {{${key}}}: $filepath" >&2
                # Replace placeholder with an error note instead of crashing
                _template_sed_replace "$workfile" "$key" "[File not found: $filepath]"
                continue
            fi

            # awk: replace the line containing {{KEY}} with file contents
            awk -v file="$filepath" -v placeholder="{{${key}}}" '
                index($0, placeholder) { while ((getline line < file) > 0) print line; next }
                { print }
            ' "$workfile" > "${workfile}.new" && mv "${workfile}.new" "$workfile"

        else
            # Single-line substitution
            _template_sed_replace "$workfile" "$key" "$val"
        fi
    done

    mv "$workfile" "$output"
}

# ──────────────────────────────────────────────
# _template_sed_replace — portable sed in-place
# ──────────────────────────────────────────────
# Handles the macOS vs Linux sed -i difference.
# Uses | as delimiter to avoid conflicts with / in file paths.
# Escapes & in replacement (sed special char).

_template_sed_replace() {
    local file="$1"
    local key="$2"
    local val="$3"

    # Escape sed special characters in the replacement value
    # & is special in sed replacement, \ needs escaping, | is our delimiter
    local escaped_val
    escaped_val=$(printf '%s' "$val" | sed -e 's/[&\|]/\\&/g')

    # Portable in-place sed (works on both macOS and Linux)
    if sed --version 2>/dev/null | grep -q GNU; then
        # GNU sed (Linux)
        sed -i "s|{{${key}}}|${escaped_val}|g" "$file"
    else
        # BSD sed (macOS) — requires '' after -i
        sed -i '' "s|{{${key}}}|${escaped_val}|g" "$file"
    fi
}

# ──────────────────────────────────────────────
# render_template_string — render from a string (no file)
# ──────────────────────────────────────────────
# For cases where the template content is already in a variable.

render_template_string() {
    local template_content="$1"
    local output="$2"
    shift 2

    local tmptemplate
    tmptemplate=$(mktemp)
    echo "$template_content" > "$tmptemplate"

    render_template "$tmptemplate" "$output" "$@"
    rm -f "$tmptemplate"
}
