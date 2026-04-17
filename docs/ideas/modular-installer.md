# Idea: Modular Installer with Pick-and-Choose Features

**Date**: 2026-04-17
**Status**: Planned
**Priority**: Medium - v1 uses flag-based approach, v2 adds manifest system

## Problem

The current installer is all-or-nothing. Projects have different needs - a backend-only API doesn't need frontend rules, a personal tool doesn't need PostgreSQL conventions, a prototype doesn't need full security hooks.

## v1: Flag-Based Installer

Core files always installed. Optional modules selected via flags:

```bash
# Everything (default)
curl -fsSL .../install.sh | bash

# Core + specific modules
curl -fsSL .../install.sh | bash -s -- --hooks --security --database

# Interactive mode - prompts for each module
curl -fsSL .../install.sh | bash -s -- --interactive
```

### Core (always installed)
- `engineering-standards.md` - folder organization, TDD, task-first, commit rules
- `git-workflow.md` - branching, commits, merge lifecycle
- `code-commenting-standards.md` - docstrings, agent-readability
- `naming-conventions.md` - test file naming
- `tasks-template-tdd.md` - TDD task template
- `git-commit-push.sh` - git script
- All `docs/` directories

### Optional Modules

| Flag | What it installs |
|------|-----------------|
| `--hooks` | changelog-maintenance, comment-standards-check, lint-python, security-checkpoint |
| `--security` | code-security-reviewer agent, code-review prompt, security-review prompt |
| `--database` | project-conventions.md with PostgreSQL conventions |
| `--frontend` | import-path-rules.md, ux-expert-persona.md |
| `--versioning` | versioning.md |
| `--maintainability` | review-maintainability.md prompt |
| `--all` | everything (current behavior, default) |

## v2: Module System with Manifests

Each concern becomes a self-contained module with a manifest:

```
modules/
├── database/
│   ├── manifest.json
│   ├── postgres.md
│   └── sqlite.md
├── api/
│   ├── manifest.json
│   ├── versioning.md
│   ├── error-handling.md
│   └── pagination.md
├── logging/
│   ├── manifest.json
│   ├── observability.md
│   └── structured-logging.md
├── security/
│   ├── manifest.json
│   ├── hooks/
│   ├── agents/
│   └── prompts/
├── frontend/
│   ├── manifest.json
│   ├── themed-dialogs.md
│   ├── import-path-rules.md
│   └── ux-expert-persona.md
├── testing/
│   ├── manifest.json
│   ├── tdd-rules.md
│   └── test-organization.md
├── docs/
│   ├── manifest.json
│   ├── taxonomy/
│   └── changelog-hooks/
└── infra/
    ├── manifest.json
    ├── adapter-pattern.md
    └── config-constants.md
```

### manifest.json format
```json
{
  "name": "database",
  "description": "PostgreSQL conventions, migrations, least-privilege access",
  "depends_on": ["core"],
  "files": ["postgres.md"],
  "install_to": ".kiro/steering/"
}
```

The installer reads manifests, resolves dependency graph, and installs only what's needed. Modules can depend on other modules.

### Benefits of v2
- Community can contribute modules for specific stacks (Django, Rails, Go, etc.)
- Modules are independently versioned
- `kiro-rails update --module database` updates just one module
- `kiro-rails list` shows installed vs available modules
