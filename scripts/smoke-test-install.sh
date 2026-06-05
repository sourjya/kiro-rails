#!/usr/bin/env bash
# smoke-test-install.sh - release sanity check for the kiro-rails installers.
#
# Installs kiro-rails into throwaway directories and verifies a clean install by
# examining the output. Two modes:
#
#   bash scripts/smoke-test-install.sh --local      # PRE-PUSH: serve the local working
#                                                   #   tree over http and install from it -
#                                                   #   validates un-pushed changes.
#   bash scripts/smoke-test-install.sh [git-ref]    # POST-PUSH: install from a published
#                                                   #   ref (default: main) via the real
#                                                   #   curl|bash flow - confirms it's live.
#
# Each installer is asserted: exit 0, zero download warnings, the version file matches
# install.sh's CURRENT_VERSION, a "Done!" line, and no installer left behind (self-clean).
# install.ps1 runs natively when `pwsh` is present; in post-push mode without pwsh it
# falls back to checking every managed URL returns HTTP 200 (catches the 404 class).
#
# Maintainer tool for the kiro-rails repo (targets this repo); not a shipped managed file.
set -uo pipefail

MODE="ref"; REF="main"
case "${1:-}" in
  --local|--pre) MODE="local" ;;
  "" )           ;;
  -* )           echo "usage: $0 [--local | <git-ref>]"; exit 2 ;;
  * )            REF="$1" ;;
esac

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RAW="https://raw.githubusercontent.com/sourjya/kiro-rails/$REF"
EXP_VER=$(grep -m1 'CURRENT_VERSION=' "$REPO_ROOT/install.sh" | sed -E 's/.*"([^"]+)".*/\1/')

fails=0
pass()  { printf '  \033[32m✓\033[0m %s\n' "$*"; }
flunk() { printf '  \033[31m✗\033[0m %s\n' "$*"; fails=$((fails + 1)); }
ps1_managed() { awk '/\$ManagedFiles = @\(/{f=1;next} /^\)/{f=0} f{gsub(/[ \t"]/,"");print}' "$REPO_ROOT/install.ps1" | grep .; }

command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }

# In --local mode, serve the working tree over http so the installers fetch exactly as
# they do in production (curl AND Invoke-WebRequest both speak http; file:// does not).
SRV_PID=""
cleanup() { [ -n "$SRV_PID" ] && kill "$SRV_PID" 2>/dev/null; }
trap cleanup EXIT
if [ "$MODE" = local ]; then
  command -v python3 >/dev/null 2>&1 || { echo "python3 is required for --local (local http server)"; exit 1; }
  PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')
  ( cd "$REPO_ROOT" && exec python3 -m http.server "$PORT" --bind 127.0.0.1 ) >/dev/null 2>&1 &
  SRV_PID=$!
  for _ in $(seq 1 30); do curl -fsS -o /dev/null "http://127.0.0.1:$PORT/install.sh" 2>/dev/null && break; sleep 0.2; done
  SRC="http://127.0.0.1:$PORT"
  echo "kiro-rails install smoke test - PRE-PUSH (local working tree @ $SRC), expected version ${EXP_VER:-?}"
else
  SRC="$RAW"
  echo "kiro-rails install smoke test - POST-PUSH @ ref '$REF', expected version ${EXP_VER:-?}"
fi

# Shared assertions over an install performed into directory $1, with output log $1/.out
verify_install() {  # $1 = install dir, $2 = installer filename, $3 = exit code
  local d="$1" inst="$2" ec="$3" w v
  [ "$ec" -eq 0 ] && pass "exit 0" || flunk "exit $ec"
  w=$(grep -c 'Warning: could not download' "$d/.out" 2>/dev/null)
  [ "${w:-0}" -eq 0 ] && pass "no download warnings" || flunk "$w download warning(s)"
  v=$(cat "$d/.kiro/.kiro-rails-version" 2>/dev/null)
  [ "$v" = "$EXP_VER" ] && pass "version $v" || flunk "version '$v' != expected '$EXP_VER'"
  grep -q 'Done!' "$d/.out" 2>/dev/null && pass "completed ('Done!')" || flunk "no 'Done!' line"
  [ ! -f "$d/$inst" ] && pass "no installer left behind (self-clean)" || flunk "$inst left behind"
}

# ── install.sh ─────────────────────────────────────────────────────────────────
echo "[install.sh]"
td=$(mktemp -d)
if [ "$MODE" = local ]; then
  cp "$REPO_ROOT/install.sh" "$td/install.sh"
  ( cd "$td" && KIRO_RAILS_BASE_URL="$SRC" bash install.sh ) >"$td/.out" 2>&1; ec=$?
else
  ( cd "$td" && curl -fsSL "$SRC/install.sh" | bash ) >"$td/.out" 2>&1; ec=$?
fi
verify_install "$td" install.sh "$ec"
rm -rf "$td"

# ── install.ps1 ────────────────────────────────────────────────────────────────
echo "[install.ps1]"
if command -v pwsh >/dev/null 2>&1; then
  td=$(mktemp -d)
  if [ "$MODE" = local ]; then
    cp "$REPO_ROOT/install.ps1" "$td/install.ps1"
    ( cd "$td" && KIRO_RAILS_BASE_URL="$SRC" pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1 ) >"$td/.out" 2>&1; ec=$?
  else
    ( cd "$td" && curl -fsSL "$SRC/install.ps1" -o install.ps1 && pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1 ) >"$td/.out" 2>&1; ec=$?
  fi
  verify_install "$td" install.ps1 "$ec"
  rm -rf "$td"
else
  echo "  (pwsh not installed - verifying every managed URL resolves at $SRC)"
  miss=0; n=0
  while IFS= read -r p; do
    [ -z "$p" ] && continue; n=$((n + 1))
    code=$(curl -fsS -o /dev/null -w '%{http_code}' "$SRC/$p" 2>/dev/null)
    [ "$code" = "200" ] || { flunk "HTTP $code for $p"; miss=1; }
  done < <(ps1_managed)
  [ "$miss" -eq 0 ] && pass "all $n managed URLs return 200"
fi

echo
if [ "$fails" -eq 0 ]; then echo "SMOKE TEST PASSED"; exit 0; else echo "SMOKE TEST FAILED ($fails check(s))"; exit 1; fi
