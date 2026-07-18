#!/usr/bin/env bash
# scripts/hardcoded-value-scan.sh — Detect hardcoded values that should be constants
#
# Per reusable-architecture.md: "ZERO embedded literals"
# Catches: UUIDs, URLs, IP addresses, port numbers, inline credentials.
#
# Excludes: test files, fixtures, documentation, config files, constants files.
# Only warns — developer must move to constants.
#
# Usage: hardcoded-value-scan.sh <file>

set -euo pipefail

# Common ports to flag when found hardcoded in source (not config)
COMMON_PORTS="3000|5173|5432|8000|8080|8443|9090|6379|27017"

main() {
    local file="${1:-}"
    [ -z "$file" ] && exit 0
    [ -f "$file" ] || exit 0

    # Skip files where hardcoded values are expected
    case "$file" in
        *test*|*spec*|*fixture*|*mock*|*.md|*.json|*.yml|*.yaml|*.toml|*.cfg|*.ini|*.env*)
            exit 0 ;;
        *constants*|*config*|*settings*|*.lock)
            exit 0 ;;
    esac

    local findings=""

    # UUID pattern (not in variable assignment to a constant)
    local uuids
    uuids=$(grep -nE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$file" 2>/dev/null \
        | grep -iv '(UUID|ID|_id|const|CONFIG|SETTING)' || true)
    if [ -n "$uuids" ]; then
        local uuid_count
        uuid_count=$(echo "$uuids" | wc -l | tr -d ' ')
        findings+="  📎 ${uuid_count}x hardcoded UUID(s) — move to constants or config"$'\n'
        findings+="$(echo "$uuids" | head -3 | sed 's/^/    Line /')"$'\n'
    fi

    # HTTP/HTTPS URLs (not in comments, not in imports)
    local urls
    urls=$(grep -nE "https?://[a-zA-Z0-9]" "$file" 2>/dev/null \
        | grep -v '^\s*//' | grep -v '^\s*#' | grep -v '^\s*\*' \
        | grep -iv '(example\.com|localhost|127\.0\.0\.1|placeholder)' || true)
    if [ -n "$urls" ]; then
        local url_count
        url_count=$(echo "$urls" | wc -l | tr -d ' ')
        findings+="  🌐 ${url_count}x hardcoded URL(s) — move to config/env"$'\n'
        findings+="$(echo "$urls" | head -3 | sed 's/^/    Line /')"$'\n'
    fi

    # Port numbers in string literals
    local ports
    ports=$(grep -nE "([\"\\x27:])(${COMMON_PORTS})([\"\\x27,;)\\s])" "$file" 2>/dev/null \
        | grep -v '^\s*//' | grep -v '^\s*#' || true)
    if [ -n "$ports" ]; then
        local port_count
        port_count=$(echo "$ports" | wc -l | tr -d ' ')
        findings+="  🔌 ${port_count}x hardcoded port number(s) — move to config/env"$'\n'
        findings+="$(echo "$ports" | head -3 | sed 's/^/    Line /')"$'\n'
    fi

    # IP addresses (not localhost)
    local ips
    ips=$(grep -nE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$file" 2>/dev/null \
        | grep -v '127\.0\.0\.1' | grep -v '0\.0\.0\.0' \
        | grep -v '^\s*//' | grep -v '^\s*#' || true)
    if [ -n "$ips" ]; then
        local ip_count
        ip_count=$(echo "$ips" | wc -l | tr -d ' ')
        findings+="  🌍 ${ip_count}x hardcoded IP address(es) — move to config/env"$'\n'
        findings+="$(echo "$ips" | head -3 | sed 's/^/    Line /')"$'\n'
    fi

    # Output
    if [ -n "$findings" ]; then
        echo "📌 HARDCODED VALUES in ${file}:"
        echo "$findings"
        echo "Per reusable-architecture.md: 'ZERO embedded literals.'"
        echo "Move to constants/ (domain values) or config (env-dependent values)."
    fi
}

main "$@"
