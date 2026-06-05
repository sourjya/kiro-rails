#!/usr/bin/env bash
# smoke-test-install.sh - release sanity check for the kiro-rails installers.
#
# Installs kiro-rails from a published git ref into throwaway directories and verifies
# a clean install by examining the output. Run AFTER pushing tags, to confirm the
# release is actually installable (catches uncommitted managed files, 404s, version
# mismatches - e.g. the kind of bug where a manifest entry has no published file).
#
# This is a MAINTAINER tool for the kiro-rails repo itself (it targets this repo's raw
# URLs); it is intentionally NOT shipped as a managed file into user projects.
#
# Usage: bash scripts/smoke-test-install.sh [git-ref]    # default ref: main
#
#   install.sh  - piped run; asserts exit 0, zero download warnings, correct version,
#                 a "Done!" line, and that no installer file is left behind.
#   install.ps1 - if `pwsh` is installed, runs it the same way; otherwise verifies every
#                 managed URL resolves (HTTP 200) and notes the native run was skipped.
set -uo pipefail

REF="${1:-main}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RAW="https://raw.githubusercontent.com/sourjya/kiro-rails/$REF"
EXP_VER=$(grep -m1 'CURRENT_VERSION=' "$REPO_ROOT/install.sh" | sed -E 's/.*"([^"]+)".*/\1/')

fails=0
pass()  { printf '  \033[32m✓\033[0m %s\n' "$*"; }
flunk() { printf '  \033[31m✗\033[0m %s\n' "$*"; fails=$((fails + 1)); }

echo "kiro-rails install smoke test @ ref '$REF' (expected version: ${EXP_VER:-?})"
command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }

# ── install.sh (bash, piped) ───────────────────────────────────────────────────
echo "[install.sh]"
td=$(mktemp -d)
( cd "$td" && curl -fsSL "$RAW/install.sh" | bash ) >"$td/.out" 2>&1
ec=$?
[ "$ec" -eq 0 ] && pass "exit 0" || flunk "exit $ec"
w=$(grep -c 'Warning: could not download' "$td/.out" 2>/dev/null)
[ "${w:-0}" -eq 0 ] && pass "no download warnings" || flunk "$w download warning(s)"
v=$(cat "$td/.kiro/.kiro-rails-version" 2>/dev/null)
[ "$v" = "$EXP_VER" ] && pass "version $v" || flunk "version '$v' != expected '$EXP_VER'"
grep -q 'Done!' "$td/.out" 2>/dev/null && pass "completed ('Done!')" || flunk "no 'Done!' line in output"
[ ! -f "$td/install.sh" ] && pass "no installer left behind (piped run)" || flunk "install.sh left behind"
rm -rf "$td"

# ── install.ps1 (PowerShell, or URL check fallback) ─────────────────────────────
echo "[install.ps1]"
if command -v pwsh >/dev/null 2>&1; then
  td=$(mktemp -d)
  ( cd "$td" && curl -fsSL "$RAW/install.ps1" -o install.ps1 \
      && pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1 ) >"$td/.out" 2>&1
  ec=$?
  [ "$ec" -eq 0 ] && pass "exit 0 (pwsh $(pwsh --version 2>/dev/null))" || flunk "exit $ec (pwsh)"
  v=$(cat "$td/.kiro/.kiro-rails-version" 2>/dev/null)
  [ "$v" = "$EXP_VER" ] && pass "version $v" || flunk "version '$v' != expected '$EXP_VER'"
  [ ! -f "$td/install.ps1" ] && pass "no installer left behind (self-clean)" || flunk "install.ps1 left behind"
  rm -rf "$td"
else
  echo "  (pwsh not installed - skipping native run; verifying every managed URL resolves)"
  miss=0; n=0
  while IFS= read -r p; do
    [ -z "$p" ] && continue; n=$((n + 1))
    code=$(curl -fsS -o /dev/null -w '%{http_code}' "$RAW/$p" 2>/dev/null)
    [ "$code" = "200" ] || { flunk "HTTP $code for $p"; miss=1; }
  done < <(awk '/\$ManagedFiles = @\(/{f=1;next} /^\)/{f=0} f{gsub(/[ \t"]/,"");print}' "$REPO_ROOT/install.ps1" | grep .)
  [ "$miss" -eq 0 ] && pass "all $n managed URLs return 200"
fi

echo
if [ "$fails" -eq 0 ]; then echo "SMOKE TEST PASSED"; exit 0; else echo "SMOKE TEST FAILED ($fails check(s))"; exit 1; fi
