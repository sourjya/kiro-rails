# Kiro Project Starter

An opinionated project template for [Kiro](https://kiro.dev)-driven development. It provides a complete scaffolding of steering files, automated hooks, documentation taxonomy, and workflow scripts so that every new project starts with enforced engineering discipline — TDD, spec-driven planning, security reviews, and structured documentation — out of the box.

## Why Use This Template

Starting a project with Kiro is powerful, but without guardrails the AI can drift: skipping tests, inlining secrets, creating ad-hoc file structures, or ignoring changelogs. This template solves that by encoding your engineering standards as steering files that Kiro follows on every interaction.

What you get:

- Mandatory TDD (RED → GREEN → REFACTOR) enforced via steering rules
- Spec-driven development workflow (requirements → design → tasks)
- Automated quality hooks that run on every file edit and commit
- A complete documentation taxonomy with 13 purpose-specific directories
- Git workflow rules that prevent direct commits to `main`
- Security review process with OWASP-aligned audit categories
- Changelog management with automatic rolling archives
- Bug tracking workflow with mandatory regression tests
- Reusable component architecture with design-time reuse mindset
- Infrastructure abstraction with adapter pattern for all external services
- Centralized configuration and constants — zero embedded literals
- Comprehensive code commenting standards for human and AI readability
- PostgreSQL database conventions with least-privilege access patterns

## Quick Start

```bash
# 1. Clone or copy the template
cp -r ~/coding/kiro-project-starter ~/coding/your-project
cd ~/coding/your-project

# 2. Reinitialize git
rm -rf .git && git init

# 3. Customize steering files for your stack
#    - .kiro/steering/engineering-standards.md  → runtime, directory structure, ports
#    - .kiro/steering/project-conventions.md    → project-specific rules, ports, venv

# 4. Register your ports in ~/coding/PORT_REGISTRY.md

# 5. Initial commit
git add -A && git commit -m "feat: initialize from kiro-project-starter"
```

## Project Structure

```
.kiro/
├── steering/           # AI behavioral rules (always-on and on-demand)
│   ├── engineering-standards.md      # TDD, task-first discipline, test locations
│   ├── execution-discipline.md       # Dependency minimalism, docs taxonomy, bug workflow
│   ├── git-workflow.md               # Branch types, forbidden actions, commit format
│   ├── code-commenting-standards.md  # Docstrings, cross-references, section separators
│   ├── project-conventions.md        # Project-specific rules, ports, logging
│   ├── import-path-rules.md          # No deep relative imports — use aliases
│   ├── naming-conventions.md         # Test file naming mirrors source (auto-included)
│   └── ux-expert-persona.md          # On-demand UX expert persona (manual)
├── hooks/              # Automated quality gates
│   ├── comment-standards-check       # Verifies docstrings on staged files before commit
│   ├── changelog-check               # Reminds to update changelog when source files change
│   ├── changelog-rolling             # Archives changelog when it exceeds 500 lines
│   ├── lint-python-files             # Runs ruff check --fix on edited Python files
│   └── security-checkpoint           # Flags security issues in auth/API/model files
├── agents/
│   └── code-security-reviewer.json   # Restricted-tool security auditor agent
├── prompts/
│   ├── code-review.md                # 12-category security + quality audit scope
│   └── security-review.md            # Periodic security review workflow
├── specs/              # Feature specifications (requirements → design → tasks)
├── templates/
│   └── tasks-template-tdd.md         # TDD task template with RED/GREEN/REFACTOR phases
└── settings/           # LSP and MCP configuration

docs/
├── decisions/          # ADR-###-name.md — Architecture Decision Records
├── architecture/       # Living technical documentation
├── roadmap/            # Planning, milestones, and sprint tracking
├── changelogs/         # CHANGELOG.md + dated rolling archives
├── bugs/               # BUG-###-name.md — bug reports with regression test requirements
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

| File | Inclusion | Purpose |
|------|-----------|---------|
| `engineering-standards.md` | always | TDD, folder organization, reusable architecture, infrastructure abstraction, centralized config, test organization, task-first discipline, commit rules |
| `execution-discipline.md` | always | Dependency minimalism, documentation taxonomy, bug workflow, API versioning, observability-first design |
| `git-workflow.md` | always | Branch naming, forbidden actions, conventional commits, merge lifecycle |
| `code-commenting-standards.md` | always | Module/class/method/property docstrings, agent-readability, cross-references |
| `project-conventions.md` | always | Project-specific conventions, ports, PostgreSQL setup, logging |
| `import-path-rules.md` | always | Ban on deep relative imports, `@/` alias for TS, package imports for Python |
| `naming-conventions.md` | auto | Test files mirror source file names |
| `ux-expert-persona.md` | manual | Senior UX expert persona for accessibility and usability guidance |

### What Each Steering File Covers

- **[engineering-standards.md](.kiro/steering/engineering-standards.md)** — Folder organization (layer-first backend, feature-sliced frontend, graduation policy), reusable component architecture, infrastructure abstraction (adapter pattern, factory instantiation, secure defaults, idempotency, observability), centralized config & constants, test folder organization, task-first discipline, TDD mandate, commit rules.
- **[execution-discipline.md](.kiro/steering/execution-discipline.md)** — Dependency minimalism, documentation taxonomy (13 `docs/` subdirectories with placement rules), spec quality standards, observability-first design for pipelines/background processes, bug reporting workflow, API versioning, ADR-roadmap linking.
- **[git-workflow.md](.kiro/steering/git-workflow.md)** — Branch naming (`feat/`, `fix/`, `ui/`, `test/`, `chore/`, `docs/`, `refactor/`), forbidden actions (no direct commits to main, no mixing features on one branch), conventional commit format, merge lifecycle, per-file conflict resolution.
- **[code-commenting-standards.md](.kiro/steering/code-commenting-standards.md)** — Module/class/method/property docstrings at all visibility levels, agent-readability requirement, method justification, cross-references, enum/constant documentation, section separators.
- **[project-conventions.md](.kiro/steering/project-conventions.md)** — Project-specific rules: port registry, PostgreSQL database conventions (central instance, least-privilege users, Alembic migration rules), domain constants strategy, code style, command output logging.
- **[import-path-rules.md](.kiro/steering/import-path-rules.md)** — Ban on `../../` or deeper relative imports. `@/` alias for TypeScript, package imports for Python. One-level relative imports only for tightly coupled files.
- **[naming-conventions.md](.kiro/steering/naming-conventions.md)** — Test file names mirror source file names (`auth_service.py` → `test_auth_service.py`, `auth.service.ts` → `auth.service.test.ts`).
- **[ux-expert-persona.md](.kiro/steering/ux-expert-persona.md)** — On-demand senior UX expert persona for accessibility (WCAG 2.2 AA), usability (Nielsen heuristics), content design, and state/flow coverage.

### Customization Points

Files marked with `<!-- CUSTOMIZE -->` comments need project-specific values:

- `engineering-standards.md` — backend/frontend tech stack, directory structure, dev server ports
- `project-conventions.md` — port allocations, venv location, PostgreSQL database names, domain-specific rules

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
   - `requirements.md` — what the feature must do
   - `design.md` — how it will be built
   - `tasks.md` — ordered implementation steps (TDD phases)
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

- One branch per feature/fix — never mix unrelated work
- Never commit directly to `main`
- Use `bash scripts/git-commit-push.sh "feat: description"` to commit, merge, and push
- Branch types: `feat/`, `fix/`, `ui/`, `test/`, `chore/`, `docs/`, `refactor/`
- Conventional commit messages required

### Bug Workflow

1. Assign the next `BUG-###` number
2. Create `docs/bugs/BUG-###-description.md`
3. Fix on a dedicated `fix/bug-###-description` branch
4. Add regression tests (both negative and positive) — non-negotiable
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

## License

<!-- CUSTOMIZE: Add your license -->
