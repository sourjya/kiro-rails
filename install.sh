#!/usr/bin/env bash
set -euo pipefail

# Kiro Project Starter - One-click installer
# Usage: curl -fsSL https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.sh | bash

REPO="sourjya/kiro-rails"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

echo "Installing Kiro Project Starter into $(pwd)..."

# Prevent running in home directory or root
if [ "$(pwd)" = "$HOME" ] || [ "$(pwd)" = "/" ]; then
  echo "Error: don't run this in your home or root directory. cd into your project first."
  exit 1
fi

# Download file list and fetch each one
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

FILES=(
  .kiro/steering/code-organization.md
  .kiro/steering/testing-standards.md
  .kiro/steering/reusable-architecture.md
  .kiro/steering/error-handling-performance.md
  .kiro/steering/change-discipline.md
  .kiro/steering/documentation-standards.md
  .kiro/steering/git-workflow.md
  .kiro/steering/code-commenting-standards.md
  .kiro/steering/project-conventions.md
  .kiro/steering/database-conventions.md
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

# Create directories
for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
done

# Download files (skip if already exists to avoid overwriting customizations)
downloaded=0
skipped=0
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    skipped=$((skipped + 1))
  else
    if curl -fsSL "$BASE_URL/$file" -o "$file" 2>/dev/null; then
      downloaded=$((downloaded + 1))
    else
      echo "  Warning: could not download $file"
    fi
  fi
done

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

echo ""
echo "Done! $downloaded files installed, $skipped skipped (already exist)."
echo ""
echo "Next steps:"
echo "  1. Edit .kiro/steering/engineering-standards.md - set your tech stack and ports"
echo "  2. Edit .kiro/steering/project-conventions.md - set project-specific rules"
echo "  3. git add .kiro/ docs/ scripts/ && git commit -m 'feat: add kiro steering files'"
