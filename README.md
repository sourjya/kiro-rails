# Kiro Rails

An opinionated project template for [Kiro](https://kiro.dev)-driven development. Steering files, automated hooks, documentation taxonomy, and workflow scripts that give your agentic IDE or CLI assistant persistent engineering discipline - TDD, spec-driven planning, security reviews, and structured documentation - from the first commit.

## Quick Start

```bash
# One-line install into your existing project
cd ~/coding/your-project
curl -fsSL https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.sh | bash
```

This downloads all steering files, hooks, prompts, templates, and creates the `docs/` taxonomy - without cloning the repo. Existing files are never overwritten.

**What the installer does:**

1. Creates `.kiro/steering/`, `.kiro/hooks/`, `.kiro/agents/`, `.kiro/prompts/`, `.kiro/templates/`, `.kiro/settings/`, `.kiro/specs/`
2. Creates 13 `docs/` subdirectories (decisions, architecture, roadmap, changelogs, bugs, ideas, technical-debt, testing, runbooks, references, engineering, security)
3. Creates `scripts/` and `logs/` directories
4. Downloads 9 steering files, 4 hooks, 1 agent config, 3 prompts, 1 task template, and 1 git script
5. Skips any file that already exists in your project - safe to re-run

**What it does NOT do:** modify existing files, touch your source code, install dependencies, or initialize git.

**After installing**, customize for your stack:
- `.kiro/steering/engineering-standards.md` - set your runtime, directory structure, dev server ports
- `.kiro/steering/project-conventions.md` - set project-specific rules, ports, database config

**Or clone the full template:**

```bash
# 1. Clone or copy the template
cp -r ~/coding/kiro-rails ~/coding/your-project
cd ~/coding/your-project

# 2. Reinitialize git
rm -rf .git && git init

# 3. Customize steering files for your stack
#    - .kiro/steering/engineering-standards.md  → runtime, directory structure, ports
#    - .kiro/steering/project-conventions.md    → project-specific rules, ports, venv

# 4. Register your ports in ~/coding/PORT_REGISTRY.md

# 5. Initial commit
git add -A && git commit -m "feat: initialize from kiro-rails"
```

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

## Project Structure

```
.kiro/
├── steering/           # AI behavioral rules (always-on and on-demand)
│   ├── engineering-standards.md      # TDD, folder organization, reusable architecture, infrastructure abstraction, centralized config, test organization, task-first discipline, commit rules
│   ├── execution-discipline.md       # Dependency minimalism, docs taxonomy, bug workflow, observability, spec quality standards
│   ├── git-workflow.md               # Branch types, forbidden actions, commit format
│   ├── code-commenting-standards.md  # Docstrings, cross-references, section separators
│   ├── project-conventions.md        # Project-specific rules, ports, logging
│   ├── import-path-rules.md          # No deep relative imports - use aliases
│   ├── naming-conventions.md         # Test file naming mirrors source (auto-included)
│   ├── versioning.md                 # Semver, git tagging, release checklist (auto-included)
│   └── ux-expert-persona.md          # On-demand UX expert persona (manual)
├── hooks/              # Automated quality gates
│   ├── comment-standards-check       # Verifies docstrings on staged files before commit
│   ├── changelog-maintenance         # Pre-commit: ensures changelog updated + rolls at 500 lines
│   ├── lint-python-files             # Runs ruff check --fix on edited Python files
│   └── security-checkpoint           # Flags security issues in auth/API/model files
├── agents/
│   └── code-security-reviewer.json   # Restricted-tool security auditor agent
├── prompts/
│   ├── code-review.md                # 12-category security + quality audit scope
│   ├── security-review.md            # Periodic security review workflow
│   └── review-maintainability.md     # 30-point maintainability + refactor audit
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

Steering files in `.kiro/steering/` control how Kiro behaves in your project. They are included based on their `inclusion` setting:

| File | Inclusion | What It Covers |
|------|-----------|----------------|
| [engineering-standards.md](.kiro/steering/engineering-standards.md) | always | Folder organization (layer-first backend, feature-sliced frontend, graduation policy), reusable component architecture, infrastructure abstraction (adapter pattern, factory instantiation, secure defaults, idempotency, observability), centralized config & constants, test folder organization, task-first discipline, TDD mandate, themed dialogs (no native browser dialogs), error handling, performance guidelines, permission boundaries, consistency rules, change scope discipline, commit rules |
| [execution-discipline.md](.kiro/steering/execution-discipline.md) | always | Dependency minimalism (justify, audit, pin versions, check overlap), documentation taxonomy (13 `docs/` subdirectories with placement rules), spec quality standards, observability-first design, bug reporting workflow, API versioning, ADR-roadmap linking |
| [git-workflow.md](.kiro/steering/git-workflow.md) | always | Branch naming (`feat/`, `fix/`, `ui/`, `test/`, `chore/`, `docs/`, `refactor/`), forbidden actions (no direct commits to main, no mixing features on one branch), conventional commit format, merge lifecycle, per-file conflict resolution |
| [code-commenting-standards.md](.kiro/steering/code-commenting-standards.md) | always | Module/class/method/property docstrings at all visibility levels, agent-readability requirement, method justification, cross-references, enum/constant documentation, section separators |
| [project-conventions.md](.kiro/steering/project-conventions.md) | always | Port registry, PostgreSQL database conventions (central instance, least-privilege users, Alembic migration rules), domain constants strategy, code style, command output logging |
| [import-path-rules.md](.kiro/steering/import-path-rules.md) | always | Ban on `../../` or deeper relative imports. `@/` alias for TypeScript, package imports for Python. One-level relative imports only for tightly coupled files |
| [naming-conventions.md](.kiro/steering/naming-conventions.md) | auto | Test file names mirror source file names (`auth_service.py` → `test_auth_service.py`, `auth.service.ts` → `auth.service.test.ts`) |
| [versioning.md](.kiro/steering/versioning.md) | auto | Semver, git tagging, release checklist, when to tag vs when not to tag, pre-1.0 beta rules |
| [ux-expert-persona.md](.kiro/steering/ux-expert-persona.md) | manual | On-demand senior UX expert persona for accessibility (WCAG 2.2 AA), usability (Nielsen heuristics), content design, and state/flow coverage |

### Customization Points

Files marked with `<!-- CUSTOMIZE -->` comments need project-specific values:

- `engineering-standards.md` - backend/frontend tech stack, directory structure, dev server ports
- `project-conventions.md` - port allocations, venv location, PostgreSQL database names, domain-specific rules

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

1. Update tech stack in `engineering-standards.md` (Python/FastAPI + TypeScript/React is the default)
2. Set your port allocations in `project-conventions.md` and `~/coding/PORT_REGISTRY.md`
3. Adjust directory structures if your project differs from the default layout
4. Add project-specific steering rules to `project-conventions.md`
5. Create your first ADR in `docs/decisions/ADR-001-tech-stack.md`
6. Build your roadmap in `docs/roadmap/roadmap.md`

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
