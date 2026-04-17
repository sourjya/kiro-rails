#!/usr/bin/env bash
set -euo pipefail

# Kiro Rails - Installer with upgrade support
# Usage: curl -fsSL https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.sh | bash
#
# Behavior:
#   Fresh install  - downloads everything, writes version file
#   Upgrade        - overwrites managed files, skips customizable files, removes stale files
#   Manual install - detects existing files without version, treats as upgrade from v0.0.0

REPO="sourjya/kiro-rails"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"
CURRENT_VERSION="0.2.0"
VERSION_FILE=".kiro/.kiro-rails-version"

# ──────────────────────────────────────────────
# Customizable files - users edit these, SKIP on upgrade
# ──────────────────────────────────────────────
CUSTOMIZABLE_FILES=(
  .kiro/steering/code-organization.md
  .kiro/steering/project-conventions.md
  .kiro/steering/database-conventions.md
)

# ──────────────────────────────────────────────
# Managed files - we own these, OVERWRITE on upgrade
# ──────────────────────────────────────────────
MANAGED_FILES=(
  .kiro/steering/testing-standards.md
  .kiro/steering/reusable-architecture.md
  .kiro/steering/error-handling-performance.md
  .kiro/steering/change-discipline.md
  .kiro/steering/documentation-standards.md
  .kiro/steering/git-workflow.md
  .kiro/steering/code-commenting-standards.md
  .kiro/steering/import-path-rules.md
  .kiro/steering/naming-conventions.md
  .kiro/steering/versioning.md
  .kiro/steering/ux-expert-persona.md
  .kiro/hooks/comment-standards-check.kiro.hook
  .kiro/hooks/changelog-maintenance.kiro.hook
  .kiro/hooks/lint-python-files.kiro.hook
  .kiro/hooks/security-checkpoint.kiro.hook
  .kiro/agents/code-security-reviewer.json
  .kiro/prompts/review-code-security.md
  .kiro/prompts/review-code-maintainability.md
  .kiro/templates/tasks-template-tdd.md
  scripts/git-commit-push.sh
)

# ──────────────────────────────────────────────
# Stale files - removed during upgrade (keyed by the version that removed them)
# Add entries here when files are renamed or deleted in a new release.
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
)

# ──────────────────────────────────────────────
# Directories to create
# ──────────────────────────────────────────────
DIRS=(
  .kiro/steering
  .kiro/hooks
  .kiro/agents
  .kiro/prompts
  .kiro/specs
  .kiro/templates
  .kiro/settings
  docs/decisions
  docs/architecture
  docs/roadmap
  docs/changelogs
  docs/bugs
  docs/ideas
  docs/technical-debt
  docs/testing
  docs/runbooks
  docs/references
  docs/engineering
  docs/security
  scripts
  logs
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
  # Files exist but no version file - manual install or pre-versioning install
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
# Download files
# ──────────────────────────────────────────────
downloaded=0
skipped=0
updated=0
failed=0

download_file() {
  local file="$1"
  if curl -fsSL "$BASE_URL/$file" -o "$file" 2>/dev/null; then
    return 0
  else
    echo "  Warning: could not download $file"
    return 1
  fi
}

# Customizable files: download only if missing (never overwrite user edits)
for file in "${CUSTOMIZABLE_FILES[@]}"; do
  if [ -f "$file" ]; then
    skipped=$((skipped + 1))
  else
    if download_file "$file"; then
      downloaded=$((downloaded + 1))
    else
      failed=$((failed + 1))
    fi
  fi
done

# Managed files: download if missing (fresh) or overwrite (upgrade)
for file in "${MANAGED_FILES[@]}"; do
  if [ "$install_type" = "fresh" ]; then
    if download_file "$file"; then
      downloaded=$((downloaded + 1))
    else
      failed=$((failed + 1))
    fi
  else
    # Upgrade: always overwrite managed files
    if [ -f "$file" ]; then
      if download_file "$file"; then
        updated=$((updated + 1))
      else
        failed=$((failed + 1))
      fi
    else
      if download_file "$file"; then
        downloaded=$((downloaded + 1))
      else
        failed=$((failed + 1))
      fi
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
# Write version file
# ──────────────────────────────────────────────
echo "$CURRENT_VERSION" > "$VERSION_FILE"

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo ""
if [ "$install_type" = "fresh" ]; then
  echo "Done! $downloaded files installed."
  echo ""
  echo "Next steps:"
  echo "  1. Edit .kiro/steering/code-organization.md - set your tech stack and ports"
  echo "  2. Edit .kiro/steering/project-conventions.md - set project-specific rules"
  echo "  3. git add .kiro/ docs/ scripts/ && git commit -m 'feat: add kiro-rails steering files'"
else
  echo "Done! $downloaded new, $updated updated, $skipped unchanged, $removed removed."
  [ $removed -gt 0 ] && echo "  Stale files from previous versions were cleaned up."
  echo ""
  echo "Review changes with: git diff"
fi
