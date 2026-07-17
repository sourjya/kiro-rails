#!/usr/bin/env bash
set -euo pipefail

# Kiro Rails - Installer with upgrade support
# Usage: curl -fsSL https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.sh | bash
#
# Behavior:
#   Fresh install  - downloads everything, prompts for project overrides, writes version file
#   Upgrade        - overwrites all managed files, never touches user-project-overrides.md
#   Manual install - detects existing files without version, treats as upgrade from v0.0.0

REPO="sourjya/kiro-rails"
BRANCH="main"
# Base URL for fetching files. Overridable via KIRO_RAILS_BASE_URL (e.g. file:///path
# for pre-push/local testing); defaults to this repo's raw GitHub content.
BASE_URL="${KIRO_RAILS_BASE_URL:-https://raw.githubusercontent.com/$REPO/$BRANCH}"
CURRENT_VERSION="0.19.0"
VERSION_FILE=".kiro/.kiro-rails-version"
OVERRIDES_FILE=".kiro/steering/user-project-overrides.md"

# ──────────────────────────────────────────────
# All managed files - overwritten on every upgrade
# ──────────────────────────────────────────────
MANAGED_FILES=(
  .kiro/steering/code-organization.md
  .kiro/steering/testing-standards.md
  .kiro/steering/reusable-architecture.md
  .kiro/steering/error-handling-performance.md
  .kiro/steering/change-discipline.md
  .kiro/steering/documentation-standards.md
  .kiro/steering/git-and-focus-discipline.md
  .kiro/steering/agent-boundaries.md
  .kiro/steering/code-commenting-standards.md
  .kiro/steering/project-conventions.md
  .kiro/steering/database-conventions.md
  .kiro/steering/import-path-rules.md
  .kiro/steering/naming-conventions.md
  .kiro/steering/versioning.md
  .kiro/steering/review-policy.md
  .kiro/steering/chokepoint-logging.md
  .kiro/steering/session-isolation.md
  .kiro/steering/frontend-patterns.md
  .kiro/steering/api-contract-discipline.md
  .kiro/steering/ux-pattern-registry.md
  .kiro/hooks/comment-standards-check.kiro.hook
  .kiro/hooks/changelog-maintenance.kiro.hook
  .kiro/hooks/lint-python-files.kiro.hook
  .kiro/hooks/security-tier1-precommit.kiro.hook
  .kiro/hooks/security-tier2-feature.kiro.hook
  .kiro/hooks/security-tier3-sprint.kiro.hook
  .kiro/hooks/fix-spiral-detector.kiro.hook
  .kiro/hooks/type-check-on-stop.kiro.hook
  .kiro/hooks/commit-checkpoint-on-stop.kiro.hook
  .kiro/hooks/package-manifest-verify.kiro.hook
  .kiro/hooks/changelog-consolidation-reminder.kiro.hook
  .kiro/hooks/bug-doc-completion-check.kiro.hook
  .kiro/hooks/adr-trigger-infra-changes.kiro.hook
  .kiro/hooks/ux-preflight-gate.kiro.hook
  .kiro/hooks/spec-validation-gate.kiro.hook
  .kiro/hooks/focus-guard.kiro.hook
  .kiro/hooks/branch-hygiene-check.kiro.hook
  .kiro/hooks/variant-search-on-fix-branch.kiro.hook
  .kiro/hooks/session-guard-check.kiro.hook
  .kiro/hooks/claude-export-freshness.kiro.hook
  .kiro/skills/auth-implementation/SKILL.md
  .kiro/skills/incident-response/SKILL.md
  .kiro/skills/review-guide/SKILL.md
  .kiro/skills/spec-propose/SKILL.md
  .kiro/skills/spec-implement/SKILL.md
  .kiro/skills/spec-verify/SKILL.md
  .kiro/skills/spec-archive/SKILL.md
  .kiro/agents/code-security-reviewer.json
  .kiro/agents/ux-red-team.json
  .kiro/agents/security-verifier.json
  .kiro/agents/ux-reviewer.json
  .kiro/prompts/review-code-security.md
  .kiro/prompts/review-code-maintainability.md
  .kiro/prompts/review-test-quality.md
  .kiro/prompts/review-css-architecture.md
  .kiro/prompts/review-api-contracts.md
  .kiro/prompts/review-dependency-risk.md
  .kiro/prompts/review-observability.md
  .kiro/prompts/review-iac-consistency.md
  .kiro/prompts/review-cicd-pipeline.md
  .kiro/prompts/review-frontend-performance.md
  .kiro/prompts/review-ux-audit.md
  .kiro/prompts/review-ux-live.md
  .kiro/prompts/review-ux-preflight.md
  .kiro/prompts/review-spec-readiness.md
  .kiro/prompts/review-ai-agent-surface.md
  .kiro/prompts/review-commit-pr-discipline.md
  .kiro/prompts/review-hardcoded-values.md
  .kiro/templates/tasks-template-tdd.md
  scripts/git-commit-push.sh
  scripts/export-to-tools.sh
  scripts/branch-check.sh
  scripts/session-guard.sh
  scripts/export-to-claude.sh
  scripts/claude-guard-bash.sh
  scripts/check-claude-fresh.sh
)

# ──────────────────────────────────────────────
# Stale files - removed during upgrade
# ──────────────────────────────────────────────
STALE_FILES=(
  # Removed in 0.2.0: monolith steering files split into focused files
  .kiro/steering/engineering-standards.md
  .kiro/steering/execution-discipline.md
  # Removed in 0.2.0: prompt renames
  .kiro/prompts/code-review.md
  .kiro/prompts/security-review.md
  .kiro/prompts/review-maintainability.md
  .kiro/prompts/review-security.md
  .kiro/prompts/review-security-periodic.md
  # Removed in 0.2.0: single security hook replaced by tiered hooks
  .kiro/hooks/security-checkpoint.kiro.hook
  # Removed in 0.2.0: customizable files replaced by user-project-overrides.md
  # (only remove if they match the old template exactly - skip if user edited them)
  # Removed in 0.13.0: git-workflow.md + focus-and-branch-discipline.md merged into git-and-focus-discipline.md
  .kiro/steering/git-workflow.md
  .kiro/steering/focus-and-branch-discipline.md
)

# ──────────────────────────────────────────────
# Directories to create
# ──────────────────────────────────────────────
DIRS=(
  .kiro/steering .kiro/hooks .kiro/agents .kiro/prompts
  .kiro/specs .kiro/templates .kiro/settings
  .kiro/skills/auth-implementation
  .kiro/skills/incident-response .kiro/skills/review-guide
  .kiro/skills/spec-propose .kiro/skills/spec-implement
  .kiro/skills/spec-verify .kiro/skills/spec-archive
  docs/decisions docs/architecture docs/roadmap docs/changelogs
  docs/bugs docs/ideas docs/technical-debt docs/testing
  docs/runbooks docs/references docs/engineering docs/security
  docs/backlog
  scripts logs
)

# ──────────────────────────────────────────────
# Safety checks
# ──────────────────────────────────────────────
if [ "$(pwd)" = "$HOME" ] || [ "$(pwd)" = "/" ]; then
  echo "Error: don't run this in your home or root directory. cd into your project first."
  exit 1
fi

# ──────────────────────────────────────────────
# Detect install type
# ──────────────────────────────────────────────
installed_version=""
install_type="fresh"

if [ -f "$VERSION_FILE" ]; then
  installed_version=$(cat "$VERSION_FILE")
  if [ "$installed_version" = "$CURRENT_VERSION" ]; then
    echo "Kiro Rails v$CURRENT_VERSION is already installed. Nothing to do."
    exit 0
  fi
  install_type="upgrade"
  echo "Upgrading Kiro Rails: v$installed_version -> v$CURRENT_VERSION"
elif ls .kiro/steering/*.md &>/dev/null 2>&1; then
  install_type="upgrade"
  installed_version="0.0.0"
  echo "Detected existing Kiro Rails files (no version file). Upgrading to v$CURRENT_VERSION"
else
  echo "Installing Kiro Rails v$CURRENT_VERSION into $(pwd)..."
fi

# ──────────────────────────────────────────────
# Create directories
# ──────────────────────────────────────────────
for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
done

# ──────────────────────────────────────────────
# Download managed files
# ──────────────────────────────────────────────
downloaded=0
updated=0
failed=0

total=${#MANAGED_FILES[@]}
current=0

for file in "${MANAGED_FILES[@]}"; do
  current=$((current + 1))
  printf "\r  Downloading [%d/%d] %-60s" "$current" "$total" "$(basename "$file")"
  if [ -f "$file" ] && [ "$install_type" = "upgrade" ]; then
    if curl -fsSL "$BASE_URL/$file" -o "$file" 2>/dev/null; then
      updated=$((updated + 1))
    else
      echo ""
      echo "  Warning: could not download $file"
      failed=$((failed + 1))
    fi
  else
    if curl -fsSL "$BASE_URL/$file" -o "$file" 2>/dev/null; then
      downloaded=$((downloaded + 1))
    else
      echo ""
      echo "  Warning: could not download $file"
      failed=$((failed + 1))
    fi
  fi
done
echo ""

# ──────────────────────────────────────────────
# Doc templates - download only if missing (never overwrite user content)
# ──────────────────────────────────────────────
DOC_TEMPLATES=(
  docs/decisions/ADR-000-template.md
  docs/bugs/BUG-000-template.md
  docs/roadmap/roadmap.md
  docs/backlog/INBOX.md
  .kiro/settings/mcp.json
)

for file in "${DOC_TEMPLATES[@]}"; do
  if [ ! -f "$file" ]; then
    if curl -fsSL "$BASE_URL/$file" -o "$file" 2>/dev/null; then
      downloaded=$((downloaded + 1))
    fi
  fi
done

# ──────────────────────────────────────────────
# Remove stale files (upgrade only)
# ──────────────────────────────────────────────
removed=0
if [ "$install_type" = "upgrade" ]; then
  for file in "${STALE_FILES[@]}"; do
    if [ -f "$file" ]; then
      rm "$file"
      removed=$((removed + 1))
      echo "  Removed stale: $file"
    fi
  done
fi

# ──────────────────────────────────────────────
# Make scripts executable
# ──────────────────────────────────────────────
chmod +x scripts/*.sh 2>/dev/null || true

# ──────────────────────────────────────────────
# User project overrides - never overwrite, prompt on fresh install
# ──────────────────────────────────────────────
if [ -f "$OVERRIDES_FILE" ]; then
  echo ""
  echo "  user-project-overrides.md exists - not modified."
else
  # Download the template first
  curl -fsSL "$BASE_URL/$OVERRIDES_FILE" -o "$OVERRIDES_FILE" 2>/dev/null
  downloaded=$((downloaded + 1))

  # Interactive prompts (skip if not a terminal, e.g. piped install)
  if [ -t 0 ]; then
    echo ""
    read -rp "Configure project settings now? You can skip and edit .kiro/steering/user-project-overrides.md later. [Y/n] " configure
    configure="${configure:-Y}"

    if [[ "$configure" =~ ^[Yy] ]]; then
      echo ""
      echo "Press Enter to skip any section."
      echo ""

      # ── Tech Stack ──
      echo "── Tech Stack ──"
      read -rp "  Backend? (e.g., Python 3.12+ with FastAPI): " backend_stack
      read -rp "  Frontend? (e.g., TypeScript with React + Vite): " frontend_stack
      if [ -n "$backend_stack" ] || [ -n "$frontend_stack" ]; then
        tech_block="## Tech Stack\n"
        [ -n "$backend_stack" ] && tech_block+="- **Backend**: $backend_stack\n"
        [ -n "$frontend_stack" ] && tech_block+="- **Frontend**: $frontend_stack\n"
        sed -i "s|## Tech Stack|${tech_block}|" "$OVERRIDES_FILE" 2>/dev/null || true
        sed -i '/<!-- Uncomment and set your stack:/,/-->/d' "$OVERRIDES_FILE" 2>/dev/null || true
      fi

      # ── Dev Server Ports ──
      echo ""
      echo "── Dev Server Ports ──"
      read -rp "  Backend port? (default: 8000): " backend_port
      read -rp "  Frontend port? (default: 5173): " frontend_port
      if [ -n "$backend_port" ] || [ -n "$frontend_port" ]; then
        bp="${backend_port:-8000}"
        fp="${frontend_port:-5173}"
        ports_block="## Dev Server Ports\n- Backend: port $bp\n- Frontend: port $fp\n"
        sed -i "s|## Dev Server Ports|${ports_block}|" "$OVERRIDES_FILE" 2>/dev/null || true
        sed -i '/<!-- Uncomment and set your ports:/,/-->/d' "$OVERRIDES_FILE" 2>/dev/null || true
      fi

      # ── Database Engine ──
      echo ""
      echo "── Database Engine ──"
      echo "  1) PostgreSQL  2) MySQL  3) SQLite  4) Skip"
      read -rp "  Choose [1-4]: " db_choice
      case "$db_choice" in
        1) db_block="## Database Engine\n\n### PostgreSQL\n- Host: localhost, Port: 5432\n- Use JSONB over JSON for queryable structured data\n- Enable pg_stat_statements for query monitoring\n" ;;
        2) db_block="## Database Engine\n\n### MySQL\n- Host: localhost, Port: 3306\n- charset=utf8mb4, collation=utf8mb4_unicode_ci\n- Enable strict mode (STRICT_TRANS_TABLES)\n" ;;
        3) db_block="## Database Engine\n\n### SQLite\n- Path: ./data/app.db\n- Enable WAL mode for concurrent access\n" ;;
        *) db_block="" ;;
      esac
      if [ -n "$db_block" ]; then
        sed -i "s|## Database Engine|${db_block}|" "$OVERRIDES_FILE" 2>/dev/null || true
        sed -i '/<!-- Uncomment your engine/,/-->/d' "$OVERRIDES_FILE" 2>/dev/null || true
      fi

      # ── Migration Tool ──
      echo ""
      echo "── Migration Tool ──"
      echo "  1) Alembic (SQLAlchemy)  2) Prisma Migrate  3) Django Migrations  4) Knex  5) Skip"
      read -rp "  Choose [1-5]: " mig_choice
      case "$mig_choice" in
        1) mig_block="## Migration Tool\n- **Alembic** (SQLAlchemy) - migrations run with admin credentials via env.py\n" ;;
        2) mig_block="## Migration Tool\n- **Prisma Migrate** - schema.prisma is the source of truth\n" ;;
        3) mig_block="## Migration Tool\n- **Django Migrations** - manage.py migrate with admin DB URL\n" ;;
        4) mig_block="## Migration Tool\n- **Knex** - knexfile.js reads from .env\n" ;;
        *) mig_block="" ;;
      esac
      if [ -n "$mig_block" ]; then
        sed -i "s|## Migration Tool|${mig_block}|" "$OVERRIDES_FILE" 2>/dev/null || true
        sed -i '/<!-- Uncomment your migration tool:/,/-->/d' "$OVERRIDES_FILE" 2>/dev/null || true
      fi

      echo ""
      echo "Remaining sections (project rules, domain constants, code style, tooling)"
      echo "can be edited directly in: .kiro/steering/user-project-overrides.md"
    fi

    echo ""
  fi
fi

# ──────────────────────────────────────────────
# Write version file
# ──────────────────────────────────────────────
echo "$CURRENT_VERSION" > "$VERSION_FILE"

# ──────────────────────────────────────────────
# Dependency check
# ──────────────────────────────────────────────
echo ""
echo "Dependency check:"

dep_ok=0
dep_degraded=0

# git (required)
if command -v git &>/dev/null; then
  echo "  ✓ git $(git --version 2>/dev/null | sed 's/git version //')"
  dep_ok=$((dep_ok + 1))
else
  echo "  ✗ git (not found) — fix-spiral-detector, security hooks, git-commit-push.sh will not work"
  echo "    Install: https://git-scm.com/downloads"
  dep_degraded=$((dep_degraded + 1))
fi

# jq (required to generate the native Claude Code layer from .kiro/)
if command -v jq &>/dev/null; then
  echo "  ✓ jq $(jq --version 2>/dev/null | sed 's/jq-//')"
  dep_ok=$((dep_ok + 1))
else
  echo "  ✗ jq (not found) — the native Claude Code layer (.claude/) cannot be generated"
  echo "    Install: https://jqlang.github.io/jq/download/  then run: bash scripts/export-to-claude.sh"
  dep_degraded=$((dep_degraded + 1))
fi

# node/npm (for TypeScript projects)
if command -v node &>/dev/null; then
  echo "  ✓ node $(node --version 2>/dev/null)"
  dep_ok=$((dep_ok + 1))
else
  echo "  ✗ node (not found) — type-check-on-stop, package-manifest-verify skip TypeScript checks"
  echo "    Install: https://nodejs.org/"
  dep_degraded=$((dep_degraded + 1))
fi

if command -v npm &>/dev/null; then
  echo "  ✓ npm $(npm --version 2>/dev/null)"
  dep_ok=$((dep_ok + 1))
else
  echo "  ✗ npm (not found) — package-manifest-verify cannot run npm pack --dry-run"
  echo "    Install: https://nodejs.org/ (bundled with Node.js)"
  dep_degraded=$((dep_degraded + 1))
fi

# TypeScript compiler
if command -v tsc &>/dev/null || (command -v npx &>/dev/null && npx tsc --version &>/dev/null 2>&1); then
  tsc_ver=$(npx tsc --version 2>/dev/null || tsc --version 2>/dev/null)
  echo "  ✓ tsc ($tsc_ver)"
  dep_ok=$((dep_ok + 1))
else
  echo "  · tsc (not found) — type-check-on-stop will skip TypeScript checks"
  echo "    Install per-project: npm install -D typescript"
  dep_degraded=$((dep_degraded + 1))
fi

# uv/uvx (for Python projects)
if command -v uvx &>/dev/null; then
  echo "  ✓ uvx ($(uvx --version 2>/dev/null || echo 'available'))"
  dep_ok=$((dep_ok + 1))
elif command -v uv &>/dev/null; then
  echo "  ✓ uv $(uv --version 2>/dev/null) (uvx available via uv tool run)"
  dep_ok=$((dep_ok + 1))
else
  echo "  · uvx (not found) — lint-python-files hook will not work"
  echo "    Install: https://docs.astral.sh/uv/getting-started/installation/"
  dep_degraded=$((dep_degraded + 1))
fi

# ruff
if command -v ruff &>/dev/null; then
  echo "  ✓ ruff $(ruff --version 2>/dev/null | head -1)"
  dep_ok=$((dep_ok + 1))
elif command -v uvx &>/dev/null; then
  echo "  · ruff (via uvx) — lint-python-files will use uvx ruff"
  dep_ok=$((dep_ok + 1))
else
  echo "  · ruff (not found) — type-check-on-stop will skip Python checks"
  echo "    Install: https://docs.astral.sh/ruff/installation/"
  dep_degraded=$((dep_degraded + 1))
fi

echo ""
if [ $dep_degraded -eq 0 ]; then
  echo "All hooks fully operational ($dep_ok dependencies found)."
else
  echo "$dep_ok dependencies found, $dep_degraded optional dependencies missing."
  echo "Missing dependencies only affect specific hooks — steering files work regardless."
fi

# ──────────────────────────────────────────────
# Generate the native Claude Code layer (.claude/ + .mcp.json + sync ledger)
# The .kiro/ tree is the source of truth; scripts/export-to-claude.sh translates it
# into what Claude Code reads natively. Running it here means Claude Code users get a
# working setup on install instead of having to know to run it by hand. It is
# non-fatal: the .kiro/ files are already in place, so a generation problem must not
# abort the install. Requires jq; if absent we print the one command to run later.
# ──────────────────────────────────────────────
claude_generated=0
echo ""
if command -v jq &>/dev/null && [ -f scripts/export-to-claude.sh ]; then
  echo "Generating native Claude Code layer (.claude/)..."
  if bash scripts/export-to-claude.sh >/dev/null 2>&1; then
    claude_generated=1
    echo "  ✓ .claude/ generated (CLAUDE.md, commands, agents, skills, hooks, settings.json)"
  else
    echo "  · Could not generate .claude/ automatically. Run it yourself: bash scripts/export-to-claude.sh"
  fi
else
  echo "Skipping .claude/ generation (jq not found). After installing jq, run:"
  echo "  bash scripts/export-to-claude.sh"
fi

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo ""
if [ "$install_type" = "fresh" ]; then
  echo "Done! $downloaded files installed."
  echo ""
  echo "Your customization file: .kiro/steering/user-project-overrides.md"
  echo "  This is the only file you need to edit. All other steering files are"
  echo "  managed by kiro-rails and will be updated automatically on upgrade."
  echo ""
  echo "Next steps:"
  echo "  1. Review .kiro/steering/user-project-overrides.md"
  if [ "$claude_generated" -eq 1 ]; then
    echo "  2. git add .kiro/ .claude/ .mcp.json docs/ scripts/ && git commit -m 'feat: add kiro-rails'"
    echo "     (.claude/ is generated from .kiro/ - re-run scripts/export-to-claude.sh after editing steering)"
  else
    echo "  2. git add .kiro/ docs/ scripts/ && git commit -m 'feat: add kiro-rails steering files'"
  fi
else
  echo "Done! $downloaded new, $updated updated, $removed removed."
  [ $removed -gt 0 ] && echo "  Stale files from previous versions were cleaned up."
  echo ""
  echo "Your customization file was not modified: .kiro/steering/user-project-overrides.md"
  echo ""
  echo "Review changes with: git diff"
fi

# ──────────────────────────────────────────────
# Self-cleanup
# If this installer was run as a downloaded file (e.g. `curl -O ... && bash install.sh`),
# remove it so it isn't left behind in the project. This is a no-op when piped
# (`curl ... | bash` leaves no file), and it never removes a git-tracked install.sh
# (so running it inside the kiro-rails repo itself won't delete the repo's copy).
# ──────────────────────────────────────────────
self_src="${BASH_SOURCE[0]:-}"
if [ -n "$self_src" ] && [ -f "$self_src" ] && [ "$(basename "$self_src")" = "install.sh" ]; then
  if ! git ls-files --error-unmatch "$self_src" >/dev/null 2>&1; then
    rm -f "$self_src" && echo "" && echo "Cleaned up the downloaded installer ($self_src)."
  fi
fi
