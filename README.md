# Kiro Rails

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub last commit](https://img.shields.io/github/last-commit/sourjya/kiro-rails)](https://github.com/sourjya/kiro-rails/commits/main)

An opinionated project template for [Kiro](https://kiro.dev)-driven development. Steering files, automated hooks, documentation taxonomy, and workflow scripts that give your agentic IDE or CLI assistant persistent engineering discipline - TDD, spec-driven planning, security reviews, and structured documentation - from the first commit.

**What's included:** [14 steering files](.kiro/steering/) · [4 automated hooks](.kiro/hooks/) · [2 review prompts](.kiro/prompts/) · [1 security agent](.kiro/agents/) · [1 TDD task template](.kiro/templates/) · 3 doc templates · 13 docs directories

## Quick Start

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.sh | bash
```

This downloads all steering files, hooks, prompts, templates, and creates the `docs/` taxonomy - without cloning the repo. On fresh install, the installer prompts for your tech stack, ports, and database engine. Safe to re-run: on upgrade, all managed files are updated automatically while `user-project-overrides.md` (your only customization file) is never touched. Stale files from previous versions are cleaned up.

**Customization:** All steering files are managed and overwritten on upgrade. Your project-specific settings go in one file:

- `.kiro/steering/user-project-overrides.md` - tech stack, ports, database engine, code style, domain constants

> Alternatively, fork the full repo: `git clone https://github.com/sourjya/kiro-rails.git your-project && cd your-project && rm -rf .git && git init`

## Why Use This Template

AI coding agents (Kiro, Claude Code, Cursor, Windsurf, Cline) are powerful but stateless - they don't remember your engineering standards between sessions. Without persistent guardrails, agents drift: skipping tests, inlining secrets, creating ad-hoc file structures, ignoring changelogs, or producing inconsistent code across features.

This template solves that by encoding your engineering standards as **[steering files](https://kiro.dev/docs/steering/)** - persistent context documents that your agent reads on every interaction. The agent doesn't just write code; it follows your team's rules about how code should be written, tested, documented, and deployed.

**What changes when you add these steering files:**

| Category | Without steering | With steering |
|----------|-----------------|---------------|
| 📁 Core | Ad-hoc folder structure | Layer-first backend, feature-sliced frontend, enforced |
| 📁 Core | Magic numbers everywhere | Centralized constants - zero embedded literals |
| 🧪 Testing | Agent writes tests sometimes | TDD is mandatory - RED/GREEN/REFACTOR every time |
| 🔒 Security | Secrets slip into code | Pre-commit [hooks](https://kiro.dev/docs/hooks/) catch credentials automatically |
| 🎨 Visual | `window.alert()` in UI code | Themed dialogs only - native browser dialogs forbidden |
| 📄 Docs | No decision records | ADRs (Architecture Decision Records) linked to roadmap milestones |
| 📋 Process | Vague specs | [Spec](https://kiro.dev/docs/specs/) quality standards enforced before any code is written |
| 📝 Process | No changelogs | Agent updates changelog on every meaningful change |
| 🔧 Process | Agent refactors unrelated code | Change scope discipline - only touch what was asked |

The steering files work with any [MCP](https://kiro.dev/docs/cli/mcp)-compatible agent. They're designed for [Kiro](https://kiro.dev) but the principles apply to any AI-assisted development workflow.

What you get:

- Mandatory TDD (RED → GREEN → REFACTOR) enforced via steering rules
- Spec-driven development workflow (requirements → design → tasks)
- Automated quality hooks that run on every file edit and commit
- A complete documentation taxonomy with 13 purpose-specific directories
- Git workflow rules that prevent direct commits to `main`
- Security review process with OWASP-aligned audit categories
- Changelog management with automatic rolling archives
- Bug tracking workflow with mandatory regression tests
- Observability-first design rules for pipelines and background processes
- Spec quality standards (NON-NEGOTIABLE) for requirements, design, and tasks
- Versioning and release process with semver, git tagging, and release checklist
- Maintainability review prompt with 30-point audit scope
- Reusable component architecture with design-time reuse mindset
- Infrastructure abstraction with adapter pattern for all external services
- Centralized configuration and constants - zero embedded literals
- Comprehensive code commenting standards for human and AI readability
- PostgreSQL database conventions with least-privilege access patterns
- Error handling standards - explicit errors, no silent swallowing, contextual messages
- Performance guidelines - caching, pagination, N+1 prevention, timeouts
- Permission boundaries - three-tier system (Always / Ask First / Never)
- Consistency and change scope discipline - match existing patterns, minimal changes only

### Documentation That Writes Itself

Most teams say "we should document things" but have no enforcement. Kiro-rails makes documentation a side effect of the normal workflow - the agent does it automatically because the steering files and hooks require it.

**Changelogs are automated, not optional.** The `changelog-maintenance` hook fires on every code edit and reminds the agent to update `CHANGELOG.md`. When it exceeds 500 lines, it auto-archives to a dated file. Entries are consolidated by feature, not one-line-per-commit noise.

**Architecture Decision Records (ADRs)** capture the *why* behind technical choices - what was decided, what alternatives were considered, and what the consequences are. Kiro-rails mandates ADRs before major implementations and wires them into the roadmap so decisions are traceable to the milestone where they were made. Ships with a ready-to-use [template](docs/decisions/ADR-000-template.md).

**Roadmap is a living document.** Specs link to milestones, ADRs link to roadmap rows, security reviews have their own tracking table. Plan changes require updating the roadmap and documenting the reason.

**Bug tracking has teeth.** Every bug gets a [numbered document](docs/bugs/BUG-000-template.md) with reproduction steps, root cause, and fix description. Regression tests are non-negotiable. Bug documents link to the roadmap for traceability.

**13 purpose-specific directories prevent the junk drawer.** Each `docs/` subdirectory has a defined purpose and placement rules. No files in `docs/` root. Ideas graduate from `docs/ideas/` to specs, then to archive.

## Project Structure

```
.kiro/
├── steering/           # AI behavioral rules (always-on and on-demand)
│   ├── code-organization.md          # Runtime, folder structure, dev servers
│   ├── testing-standards.md          # Test folders, task-first discipline, TDD
│   ├── reusable-architecture.md      # Reuse, infra abstraction, centralized config
│   ├── error-handling-performance.md # Error handling, performance, observability, themed dialogs
│   ├── change-discipline.md          # Permissions, consistency, scope, deps, commits, changelog
│   ├── documentation-standards.md    # Docs taxonomy, spec quality, API versioning, roadmap
│   ├── git-workflow.md               # Branch types, forbidden actions, commit format, bug workflow
│   ├── code-commenting-standards.md  # Docstrings, cross-references, section separators
│   ├── project-conventions.md        # Project-specific rules, code style, logging
│   ├── database-conventions.md       # DB architecture, credentials, migrations, ORM
│   ├── import-path-rules.md          # No deep relative imports - use aliases
│   ├── naming-conventions.md         # Test file naming mirrors source (auto-included)
│   ├── versioning.md                 # Semver, git tagging, release checklist (auto-included)
│   ├── ux-expert-persona.md          # On-demand UX expert persona (manual)
│   └── user-project-overrides.md     # YOUR customizations - never overwritten on upgrade
├── hooks/              # Automated quality gates
│   ├── comment-standards-check       # Verifies docstrings on staged files before commit
│   ├── changelog-maintenance         # Pre-commit: ensures changelog updated + rolls at 500 lines
│   ├── lint-python-files             # Runs ruff check --fix on edited Python files
│   └── security-checkpoint           # Flags security issues in auth/API/model files
├── agents/
│   └── code-security-reviewer.json   # Restricted-tool security auditor agent
├── prompts/
│   ├── review-code-security.md            # 12-category security + quality audit scope with periodic review workflow
│   └── review-code-maintainability.md     # 30-point maintainability + refactor audit
├── specs/              # Feature specifications (requirements → design → tasks)
├── templates/
│   └── tasks-template-tdd.md         # TDD task template with RED/GREEN/REFACTOR phases
└── settings/           # LSP and MCP configuration

docs/
├── decisions/          # ADR-###-name.md - Architecture Decision Records
├── architecture/       # Living technical documentation
├── roadmap/            # Planning, milestones, and sprint tracking
├── changelogs/         # CHANGELOG.md + dated rolling archives
├── bugs/               # BUG-###-name.md - bug reports with regression test requirements
├── ideas/              # Feature exploration (promoted ideas → _archive/)
├── technical-debt/     # Known debt items and remediation plans
├── testing/            # Test strategy and coverage reports
├── runbooks/           # Operational guides and setup instructions
├── references/         # External docs, research materials, API guides
├── engineering/        # Engineering process documentation
└── security/           # Security review reports and findings log

scripts/
└── git-commit-push.sh  # Commit → merge to main → push (with log capture)

logs/                   # Command output logs (gitignored)
```

## Steering Files

Steering files in `.kiro/steering/` control how Kiro behaves in your project. Each file is a self-contained instruction set for one aspect of engineering discipline. The agent reads all `inclusion: always` files regardless, so splitting doesn't add context  - it just organizes it. Smaller focused files are easier for the agent to reason about than a monolith where TDD rules sit next to themed dialog rules.

They are included based on their `inclusion` setting:

| File | Inclusion | What It Covers |
|------|-----------|----------------|
| [code-organization.md](.kiro/steering/code-organization.md) | always | Runtime environment, folder organization (layer-first backend, feature-sliced frontend, graduation policy), dev server ports |
| [testing-standards.md](.kiro/steering/testing-standards.md) | always | Test folder organization, task-first discipline, TDD mandate (RED/GREEN/REFACTOR), testing requirements |
| [reusable-architecture.md](.kiro/steering/reusable-architecture.md) | always | Reusable component architecture, infrastructure abstraction (adapter pattern, factory instantiation, secure defaults, idempotency), centralized config & constants |
| [error-handling-performance.md](.kiro/steering/error-handling-performance.md) | always | Error handling standards, performance guidelines, themed dialogs (no native browser dialogs), observability-first design |
| [change-discipline.md](.kiro/steering/change-discipline.md) | always | Permission boundaries, consistency rules, change scope discipline, dependency minimalism, design principles, commit discipline, changelog rolling, repo hygiene, credentials |
| [documentation-standards.md](.kiro/steering/documentation-standards.md) | always | Documentation taxonomy (13 `docs/` subdirectories), spec quality standards, API versioning, roadmap planning, ADR-roadmap linking |
| [git-workflow.md](.kiro/steering/git-workflow.md) | always | Branch naming, forbidden actions, conventional commit format, merge lifecycle, bug resolution workflow, per-file conflict resolution |
| [code-commenting-standards.md](.kiro/steering/code-commenting-standards.md) | always | Module/class/method/property docstrings at all visibility levels, agent-readability requirement, cross-references, section separators |
| [project-conventions.md](.kiro/steering/project-conventions.md) | always | Project-specific rules, code style, command output logging |
| [database-conventions.md](.kiro/steering/database-conventions.md) | always | DB architecture, credentials, migrations, ORM conventions, transaction boundaries, connection pooling, engine-specific notes (PostgreSQL, MySQL, SQLite) |
| [import-path-rules.md](.kiro/steering/import-path-rules.md) | always | Ban on `../../` or deeper relative imports. `@/` alias for TypeScript, package imports for Python. One-level relative imports only for tightly coupled files |
| [naming-conventions.md](.kiro/steering/naming-conventions.md) | auto | Test file names mirror source file names (`auth_service.py` → `test_auth_service.py`, `auth.service.ts` → `auth.service.test.ts`) |
| [versioning.md](.kiro/steering/versioning.md) | auto | Semver, git tagging, release checklist, when to tag vs when not to tag, pre-1.0 beta rules |
| [ux-expert-persona.md](.kiro/steering/ux-expert-persona.md) | manual | On-demand senior UX expert persona for accessibility (WCAG 2.2 AA), usability (Nielsen heuristics), content design, and state/flow coverage |

### Customization Points

All steering files above are managed and overwritten on upgrade. Project-specific settings go in one file:

- `user-project-overrides.md` - tech stack, ports, database engine, code style, domain constants

## Automated Hooks

Hooks fire automatically on file edits or before tool use:

| Hook | Trigger | What It Does |
|------|---------|--------------|
| Comment Standards Check | Pre-commit | Scans staged `.py`/`.ts` files for missing docstrings and fixes violations |
| Changelog Check | `.py`/`.ts`/`.tsx` edited | Reminds to update `CHANGELOG.md` with a consolidated entry |
| Changelog Rolling | `CHANGELOG.md` edited | Archives changelog to a dated file when it exceeds 500 lines |
| Lint Python Files | `.py` edited | Runs `ruff check --fix` via `uvx` and logs output |
| Security Checkpoint | Auth/API/model files edited | Silently verifies no secrets, proper validation, parameterized SQL |

## Development Workflow

### Spec-Driven Development

Every feature follows the spec lifecycle:

1. Explore the idea in `docs/ideas/`
2. Create a spec in `.kiro/specs/<feature-name>/` with three files:
   - `requirements.md` - what the feature must do
   - `design.md` - how it will be built
   - `tasks.md` - ordered implementation steps (TDD phases)
3. Add the spec to `.kiro/specs/README.md` index and link it in `docs/roadmap/roadmap.md`
4. Create a `feat/<spec-name>` branch from `main`
5. Execute tasks in order, marking progress as you go
6. Merge to `main` when complete, then start the next spec

### TDD Cycle (Mandatory)

All implementation follows RED → GREEN → REFACTOR:

1. Write a failing test (RED)
2. Write minimal code to make it pass (GREEN)
3. Refactor while keeping tests green (REFACTOR)

No implementation code may be written before its test. The only exceptions are config files, migrations, docs, and build scripts.

### Git Workflow

```
main ──→ feat/A ──→ merge ──→ fix/B ──→ merge ──→ feat/C ──→ ...
```

- One branch per feature/fix - never mix unrelated work
- Never commit directly to `main`
- Use `bash scripts/git-commit-push.sh "feat: description"` to commit, merge, and push
- Branch types: `feat/`, `fix/`, `ui/`, `test/`, `chore/`, `docs/`, `refactor/`
- Conventional commit messages required

### Bug Workflow

1. Assign the next `BUG-###` number
2. Create `docs/bugs/BUG-###-description.md`
3. Fix on a dedicated `fix/bug-###-description` branch
4. Add regression tests (both negative and positive) - non-negotiable
5. Update changelog and roadmap
6. Merge to `main`

### Security Reviews

Periodic security reviews use the `code-security-reviewer` agent with a 12-category OWASP-aligned audit scope (S1–S9 security, Q1–Q3 code quality). Reports go in `docs/security/` and findings are tracked in `SECURITY_LOG.md`.

## Customizing for Your Project

1. Edit `user-project-overrides.md` - set your tech stack, ports, and database engine
2. Adjust directory structures if your project differs from the default layout
3. Add project-specific rules to `user-project-overrides.md`
4. Create your first ADR in `docs/decisions/ADR-001-tech-stack.md`
5. Build your roadmap in `docs/roadmap/roadmap.md`

## Future Features

- **Interactive installer** - `npx create-kiro-project` with prompts for stack selection (Python/Node/Go, frontend framework, database engine)
- **Stack presets** - strip frontend sections for backend-only projects, strip Python for TS-only, etc.
- **`kiro-rails doctor`** - validates steering files are consistent (checks for broken cross-references, missing `<!-- CUSTOMIZE -->` values)
- **Community steering modules** - contributed files for Docker, CI/CD, monorepos, and other common concerns
- **IDE structure screenshot** - visual diagram showing the `.kiro/` structure in an IDE

## Research

The steering rules in this template were informed by cross-tool research into AI coding agent conventions. See [docs/references/steering-research-2026-04-11.md](docs/references/steering-research-2026-04-11.md) for sources, methodology, and gap analysis.

Key sources:
- [MSR 2026 - "Beyond the Prompt: An Empirical Study of Cursor Rules"](https://arxiv.org/html/2512.18925v2) - taxonomy of 401 repos
- [ETH Zurich - Context file effectiveness study](https://arxiv.org/abs/2602.11988) - human-curated vs auto-generated rules
- [AGENTS.md Standard](https://github.com/agentsmd/agents.md) - Linux Foundation cross-tool specification
- [Augment Code - How to Build Your AGENTS.md](https://www.augmentcode.com/guides/how-to-build-agents-md) - patterns from 2,500+ repos

## License

MIT License

Copyright (c) 2026 Sourjya S. Sen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
