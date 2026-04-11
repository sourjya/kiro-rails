# Project Name

<!-- CUSTOMIZE: Replace with your project description -->

## Quick Start

```bash
# 1. Copy this template
cp -r ~/coding/kiro-project-starter ~/coding/your-project
cd ~/coding/your-project
rm -rf .git && git init

# 2. Customize steering files
# Edit .kiro/steering/project-conventions.md — ports, venv rules, language-specific conventions
# Edit .kiro/steering/engineering-standards.md — runtime, directory structure, ports

# 3. Register ports
# Update ~/coding/PORT_REGISTRY.md with your project's port allocations

# 4. Initial commit
git add -A && git commit -m "feat: initialize from kiro-project-starter"
```

## Project Structure

```
.kiro/
├── steering/       # AI behavioral rules (always/auto/fileMatch/manual)
├── hooks/          # Automated quality gates (fileEdited/preToolUse)
├── agents/         # Specialized AI agents (e.g., security reviewer)
├── prompts/        # Reusable workflow templates
├── templates/      # Task/spec templates
├── specs/          # Feature specifications (requirements → design → tasks)
└── settings/       # LSP and MCP configuration

docs/
├── decisions/      # ADR-###-name.md
├── architecture/   # Living technical docs
├── roadmap/        # Planning and milestones
├── changelogs/     # CHANGELOG.md + dated archives
├── bugs/           # BUG-###-name.md
├── ideas/          # Feature exploration (→ _archive/ when promoted)
├── technical-debt/ # Known debt and remediation
├── testing/        # Test strategy and coverage
├── runbooks/       # Operational guides
├── references/     # External docs and research
└── engineering/    # Process documentation

scripts/            # Git helpers, dev scripts
logs/               # Command output logs (gitignored)
```

## Kiro Discipline

This project follows spec-driven development:

1. **Ideas** → `docs/ideas/` (freeform exploration)
2. **Specs** → `.kiro/specs/<name>/` (requirements.md → design.md → tasks.md)
3. **Implementation** → One branch per spec, TDD mandatory
4. **Decisions** → `docs/decisions/ADR-###.md` (linked from roadmap)
5. **Bugs** → `docs/bugs/BUG-###.md` (mandatory regression tests)

## Steering Files

| File | Inclusion | Purpose |
|------|-----------|---------|
| execution-discipline.md | always | Dependency minimalism, docs taxonomy, bug workflow |
| engineering-standards.md | always | TDD, task-first discipline, coverage, changelog |
| git-workflow.md | always | Branch types, forbidden actions, conventional commits |
| code-commenting-standards.md | always | Docstrings, cross-references, section separators |
| project-conventions.md | always | Project-specific rules, ports, venv, logging |
| naming-conventions.md | auto | Test file naming mirrors source |
| ux-expert-persona.md | manual | On-demand UX expert persona |
