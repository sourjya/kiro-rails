# Kiro Rails

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub last commit](https://img.shields.io/github/last-commit/sourjya/kiro-rails)](https://github.com/sourjya/kiro-rails/commits/main)

An opinionated project template for [Kiro](https://kiro.dev)-driven development. Steering files, automated hooks, documentation taxonomy, and workflow scripts that give your agentic IDE or CLI assistant persistent engineering discipline - TDD, spec-driven planning, security reviews, and structured documentation - from the first commit.

**What's included:** [20 steering files](.kiro/steering/) · [18 automated hooks](.kiro/hooks/) · [14 review prompts](.kiro/prompts/) · [3 agents](.kiro/agents/) · [5 skills](.kiro/skills/) · [1 TDD task template](.kiro/templates/) · 3 doc templates · 13 docs directories · [multi-tool export](scripts/export-to-tools.sh) · [native Claude Code layer](#bonus-native-claude-code-support)

## Why Use This Template

AI coding agents (Kiro, Claude Code, Cursor, Windsurf, Cline) are powerful but stateless - they don't remember your engineering standards between sessions. Without persistent guardrails, agents drift: skipping tests, inlining secrets, creating ad-hoc file structures, ignoring changelogs, or producing inconsistent code across features.

This template solves that by encoding your engineering standards as **[steering files](https://kiro.dev/docs/steering/)** - persistent context documents that your agent reads on every interaction. The agent doesn't just write code; it follows your team's rules about how code should be written, tested, documented, and deployed.

**What changes when you add these steering files:**

| Category | Without steering | With steering |
|----------|-----------------|---------------|
| 📁 Structure | Ad-hoc folder structure | Layer-first backend, feature-sliced frontend, enforced |
| 📁 Structure | Magic numbers everywhere | Centralized constants - zero embedded literals |
| 🧪 Testing | Agent writes tests sometimes | TDD is mandatory - RED/GREEN/REFACTOR every time |
| 🔒 Security | Secrets slip into code | Pre-commit [hooks](https://kiro.dev/docs/hooks/) catch credentials automatically |
| 🔒 Security | AI features ship without audit | OWASP-aligned agentic surface review (ASI01-10, MCP Top 10) |
| 🎨 Frontend | `window.alert()` in UI code | Themed dialogs only - native browser dialogs forbidden |
| 🎨 Frontend | Extracted component passes empty props, looks broken | Prop parity audit mandatory - compare every prop against the original |
| 🔌 API | Frontend crashes on wrong response shape | Contract-first development - define schema before implementing |
| ⚡ Async | Race conditions from fire-and-forget | Async discipline - `mutateAsync` + await for dependent ops |
| 💾 State | State lost on page reload | Explicit persistence strategy required for all state |
| 📦 Packaging | Files missing from npm publish | Package manifest verification hook catches it automatically |
| 📋 Specs | Vague specs | [Spec](https://kiro.dev/docs/specs/) quality standards enforced before any code is written |
| 📄 Docs | No decision records | ADRs (Architecture Decision Records) linked to roadmap milestones |
| 📝 Docs | No changelogs | Agent updates changelog on every meaningful change |
| 🔧 Discipline | Agent refactors unrelated code | Change scope discipline - only touch what was asked |
| 🔄 Discipline | Fix-on-fix spirals (7+ commits) | Fix depth rule - stop after 2 failed fixes, map all paths |
| 🎯 Discipline | Stacked requests derail the current task | Request queue protocol - file it, finish current job, then drain the backlog |
| 🌿 Discipline | Branches pile up and silently diverge | Branch hygiene - merge-and-delete, collision detector before forking a branch |
| 🚧 Isolation | A parallel agent session corrupts another repo's git | Session isolation - stay in your project root, never `git -C` a sibling repo, working-tree lock detects foreign actors |

The steering files work with any [MCP](https://kiro.dev/docs/cli/mcp)-compatible agent. They're designed for [Kiro](https://kiro.dev) but the principles apply to any AI-assisted development workflow.

## Quick Start

**Linux / macOS / [Git Bash](https://gitforwindows.org/) / [WSL](https://learn.microsoft.com/en-us/windows/wsl/install):**

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.sh | bash
```

**[PowerShell](https://learn.microsoft.com/en-us/powershell/) (Windows):**

```powershell
cd your-project
curl.exe -fsSL https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.ps1 -o install.ps1; powershell -ExecutionPolicy Bypass -File install.ps1
```

> If `curl.exe` is blocked by corporate policy, use: `Invoke-WebRequest -Uri "https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.ps1" -OutFile install.ps1; powershell -ExecutionPolicy Bypass -File install.ps1`

This downloads all steering files, hooks, prompts, templates, and creates the `docs/` taxonomy - without cloning the repo. On fresh install, the installer prompts for your tech stack, ports, and database engine. Safe to re-run: on upgrade, all managed files are updated automatically while `user-project-overrides.md` (your only customization file) is never touched. Stale files from previous versions are cleaned up.

**Customization:** All steering files are managed and overwritten on upgrade. Your project-specific settings go in one file:

- `.kiro/steering/user-project-overrides.md` - tech stack, ports, database engine, code style, domain constants

> Alternatively, fork the full repo: `git clone https://github.com/sourjya/kiro-rails.git your-project && cd your-project && rm -rf .git && git init`

What you get:

- **Code quality** - TDD mandate, spec-driven workflow, automated hooks on every edit and commit, 13-directory documentation taxonomy, git workflow rules preventing direct commits to `main`
- **Security** - three-tier OWASP-aligned audit (pre-commit → feature → sprint), AI/agentic surface review (ASI01-10, MCP Top 10), adversarial verifier agent, mandatory regression tests for bugs
- **Architecture** - reusable component design, infrastructure abstraction (adapter pattern), centralized config/constants, contract-first APIs, async discipline, state persistence rules
- **Observability** - error handling standards, performance guidelines (caching, pagination, N+1 prevention), observability-first design for pipelines, structured logging
- **Discipline** - permission boundaries (Always / Ask First / Never), change scope enforcement, fix spiral detection, focus & branch discipline (queue mid-task requests, merge-and-delete branches, collision detection), session isolation (no cross-repo git, working-tree lock), consistency rules, dependency minimalism, code commenting standards
- **Tooling** - auth implementation skill (SSO/OAuth checklist), package manifest verification, versioning/release process, maintainability review (33-point audit), chokepoint logging

## Documentation That Writes Itself

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
│   ├── frontend-patterns.md          # React hooks, event propagation, CSS layout, caching, component extraction, completion verification (fileMatch: tsx/jsx)
│   ├── api-contract-discipline.md    # Contract-first dev, response shapes, error contracts (fileMatch: api/routes)
│   ├── ux-pattern-registry.md        # Reference patterns for common screen types (manual)
│   ├── review-policy.md              # When to trigger security and maintainability reviews
│   ├── chokepoint-logging.md         # Log recurring errors, categorize, promote to rules
│   ├── focus-and-branch-discipline.md # Queue mid-task requests, Definition of Done, branch hygiene
│   ├── session-isolation.md          # Stay in your repo, no cross-repo git, no killing foreign processes
│   └── user-project-overrides.md     # YOUR customizations - never overwritten on upgrade
├── hooks/              # Automated quality gates
│   ├── comment-standards-check       # Verifies docstrings on staged files before commit
│   ├── changelog-maintenance         # Pre-commit: ensures changelog updated + rolls at 500 lines
│   ├── lint-python-files             # Runs ruff check --fix on edited Python files
│   ├── security-tier1-precommit      # Pre-commit: blocks secrets, unsafe code, auth bypass
│   ├── security-tier2-feature        # Feature complete: full OWASP + business logic audit
│   ├── security-tier3-sprint         # Sprint end: full codebase + supply chain + headers
│   ├── fix-spiral-detector           # Prompt submit: warns if 3+ consecutive fix commits detected
│   ├── type-check-on-stop            # Agent stop: runs tsc/ruff after agent finishes responding
│   ├── package-manifest-verify       # File edit: verifies package.json/pyproject.toml includes
│   ├── changelog-consolidation-reminder # Prompt submit: warns if 10+ commits since last changelog
│   ├── bug-doc-completion-check      # File edit: verifies bug doc fields are complete
│   ├── adr-trigger-infra-changes     # File edit: suggests ADR when infrastructure changes
│   ├── focus-guard                   # Prompt submit: queue unrelated mid-task requests, don't thrash
│   ├── branch-hygiene-check          # Prompt submit: flag merged-undeleted and sprawling branches
│   ├── session-guard-check           # Prompt submit: detect cross-session interference on the working tree
│   └── claude-export-freshness       # .kiro/ edited: remind to regenerate the committed .claude/ layer
├── agents/
│   ├── code-security-reviewer.json   # Restricted-tool security auditor agent
│   └── security-verifier.json        # Adversarial agent that disproves false positives
├── skills/
│   └── auth-implementation/          # Auth/SSO/OAuth flow checklist (auto-activates on auth keywords)
│       └── SKILL.md
├── prompts/
│   ├── review-code-security.md            # Tier-aware security audit (T1 pre-commit, T2 feature, T3 sprint)
│   ├── review-code-maintainability.md     # 32-point maintainability + refactor audit
│   ├── review-test-quality.md             # Test suite quality, coverage gaps, flakiness audit
│   ├── review-css-architecture.md         # CSS/styling consistency, tokens, specificity audit
│   ├── review-api-contracts.md            # API contract consistency, error schemas, versioning
│   ├── review-dependency-risk.md          # Dependency bloat, license, supply chain, vendor lock-in
│   ├── review-observability.md            # Logging, tracing, metrics, SLI/SLO, 3 AM test
│   ├── review-iac-consistency.md          # IaC security, naming, tags, Lambda sizing, drift
│   ├── review-cicd-pipeline.md            # Pipeline security, OIDC, gating, artifact integrity
│   ├── review-frontend-performance.md     # Core Web Vitals, React rendering, bundle, memory, CLS/INP
│   ├── review-ux-audit.md                # Persona cards, journey maps, heuristic sweep, anti-patterns
│   ├── review-spec-readiness.md          # Pre-build spec hardening - 18 lenses, predicted issues, roadmap revision
│   └── review-ai-agent-surface.md        # AI/agentic feature audit - OWASP ASI01-10, MCP Top 10, confidence gates
├── specs/              # Feature specifications (requirements → design → tasks)
├── templates/
│   └── tasks-template-tdd.md         # TDD task template with RED/GREEN/REFACTOR phases
└── settings/           # LSP and MCP configuration

docs/
├── backlog/            # INBOX.md - request queue for the focus/branch discipline protocol
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
├── git-commit-push.sh  # Commit → merge to main → push (with log capture)
├── branch-check.sh     # Detect branch collisions before they become duplicate-divergent files
├── session-guard.sh    # Detect concurrent-session interference on a shared working tree
├── export-to-tools.sh  # Generate flat config for Cursor / Copilot / Codex / Claude CLAUDE.md
├── export-to-claude.sh # Generate the full native .claude/ layer (BONUS for Claude Code)
├── claude-guard-bash.sh # Claude PreToolUse guard: block cross-repo git (enforces session-isolation)
└── check-claude-fresh.sh # Verify the committed .claude/ is in sync with .kiro/ source

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
| [frontend-patterns.md](.kiro/steering/frontend-patterns.md) | fileMatch | React hooks rules, event propagation, CSS flex/grid layout, cache invalidation, component extraction & reuse (prop parity), completion verification (build ≠ done), component completeness checklist (loaded for `*.tsx`/`*.jsx` files) |
| [api-contract-discipline.md](.kiro/steering/api-contract-discipline.md) | fileMatch | Contract-first development, response shape verification, error response contracts, rate limiting guidance (loaded for `api/`, `routes/`, `services/` files) |
| [ux-pattern-registry.md](.kiro/steering/ux-pattern-registry.md) | manual | Reference layout patterns for common screen types; load with `/ux-pattern-registry` when designing or reviewing UI |
| [review-policy.md](.kiro/steering/review-policy.md) | always | When to trigger security and maintainability reviews, output conventions, sequencing rules, report numbering |
| [chokepoint-logging.md](.kiro/steering/chokepoint-logging.md) | always | Log recurring errors on attempt #2+, categorize by pattern, promote to steering rules after 3 occurrences |
| [focus-and-branch-discipline.md](.kiro/steering/focus-and-branch-discipline.md) | always | Request queue protocol (file mid-task requests, finish before switching), Definition of Done, branch hygiene (merge-and-delete, check before branching, prune merged) |
| [session-isolation.md](.kiro/steering/session-isolation.md) | always | Stay inside your project root, never operate on sibling repos (`git -C`/cross-repo PRs), verify before destructive git, never kill processes you didn't spawn |

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
| Security Tier 1 | Pre-commit | Blocks secrets, unsafe execution, auth bypass in staged files |
| Security Tier 2 | Feature complete (manual) | Full OWASP + business logic + BOLA/IDOR audit |
| Security Tier 3 | Sprint end (manual) | Full codebase + supply chain + headers + logging security |
| Fix Spiral Detector | Prompt submit | Warns if 3+ consecutive `fix:` commits detected - triggers root cause analysis |
| Type Check on Stop | Agent stop | Runs `tsc --noEmit` or `ruff check` after agent finishes responding |
| Package Manifest Verify | `package.json`/`pyproject.toml` edited | Runs `npm pack --dry-run` to verify published artifact includes expected files |
| Changelog Consolidation | Prompt submit | Warns if 10+ commits since last changelog update - triggers consolidation |
| Bug Doc Completion | `docs/bugs/BUG-*.md` edited | Verifies root cause, fix, regression tests, and status are filled |
| ADR Trigger | Infrastructure files edited | Asks if the change warrants an Architecture Decision Record |
| UX Preflight Gate | Spec task start | If a task involves UI work, verifies a UX Intent Block exists for the phase; skips silently for backend-only tasks |
| Spec Validation Gate | `.kiro/specs/` edited | Validates spec folder completeness and that proposal/requirements/design/tasks follow the required format |
| Focus Guard | Prompt submit | If there's uncommitted work on a non-main branch, reminds the agent to queue unrelated requests instead of thrashing |
| Branch Hygiene Check | Prompt submit | Flags branches merged into main but not deleted, and warns when local branch count grows large |
| Session Guard Check | Prompt submit | Warns if another live session holds this working tree or if HEAD drifted unexpectedly (cross-session interference) |
| Claude Export Freshness | `.kiro/` source edited | Reminds to regenerate the committed `.claude/` layer so the Claude bonus does not drift from its Kiro source |

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

Security reviews follow a three-tier model that matches review depth to development context:

- **Tier 1 (pre-commit):** Blocks secrets, unsafe execution, and auth bypass in staged files. Runs automatically on every commit.
- **Tier 2 (feature complete):** Full OWASP S1-S13 audit plus BOLA/IDOR, cryptographic quality, and file upload security. Run manually when a feature is ready.
- **Tier 3 (sprint end):** Full codebase scan including supply chain (D1-D5), secure headers/CORS, logging security, and rate limiting. Run manually at sprint boundaries.

Reports go in `docs/security/` as `SRR-{###}-{YYYY-MM-DD}-T{tier}.md`. See `review-policy.md` for trigger rules and sequencing.

## Focus, Branch & Session Discipline

Three of the most expensive failures in agentic development are invisible when they happen and only surface much later. kiro-rails encodes a guardrail for each - as always-on steering, backed by a hook and a real tool where the behavior is mechanically checkable.

**Task thrashing.** When you stack new requests mid-task, an agent tends to drop what it's doing and chase the latest one - leaving the original half-finished and bleeding unrelated changes (a CSS fix landing on an `auth` branch) into the wrong place. `focus-and-branch-discipline.md` makes the default *file it, don't do it*: unrelated mid-task requests go to `docs/backlog/INBOX.md`, the agent acknowledges them and finishes the current task to a committed, merged checkpoint, then drains the queue. It diverts only when you explicitly say so. The `focus-guard` hook reminds the agent whenever there's uncommitted work on a branch.

**Branch sprawl.** Branches that are never merged-and-deleted pile up and silently diverge - two branches touching the same files on the same day produce duplicate-but-different versions, and "merge then delete" never happens. The discipline is one task per branch, merge-and-delete as a single motion, and a Definition of Done that isn't met until the branch is gone. `scripts/branch-check.sh` detects collisions *before* you fork a parallel branch, and the `branch-hygiene-check` hook flags branches merged but not deleted.

**Cross-session interference.** When multiple agent sessions share a machine, one launched for repo A can reach into sibling repo B and corrupt a different session's git state (`git -C /other/repo reset --hard`), or even kill its own terminal. `session-isolation.md` confines each session to its project root: no cross-repo git, no operating on trees or processes you don't own. `scripts/session-guard.sh` detects foreign actors on the working tree, and in Claude Code the [`PreToolUse` guard](#bonus-native-claude-code-support) *hard-blocks* cross-repo git before it runs.

## Spec Workflow Skills

Kiro-rails includes four workflow skills that provide a structured spec-before-code lifecycle - similar to [OpenSpec](https://github.com/Fission-AI/OpenSpec)'s propose/apply/archive pattern, but integrated with Kiro's native skill system and enforced by the spec validation hook.

| Skill | Purpose | Trigger |
|-------|---------|---------|
| `spec-propose` | Create a structured spec folder (proposal → requirements → design → tasks) | Starting new work |
| `spec-implement` | Implement against the spec using TDD, checking off tasks as you go | After proposal is approved |
| `spec-verify` | Verify implementation against acceptance criteria, generate coverage report | After implementation is complete |
| `spec-archive` | Move completed spec to `docs/architecture/specs/`, update index | After verification passes |

The `spec-validation-gate` hook fires automatically when any file in `.kiro/specs/` is edited, validating:
- Folder completeness (all 4 artifacts present)
- Proposal has required sections (Problem Statement, Proposed Solution, Scope)
- Requirements have testable acceptance criteria
- Tasks use checkbox format and are atomic

## Multi-Tool Export

While kiro-rails is designed for Kiro, the engineering standards are valuable in any AI coding tool. The export script generates equivalent config files for other assistants:

```bash
./scripts/export-to-tools.sh --all
```

This generates:
- `.cursorrules` - for [Cursor](https://cursor.com)
- `.claude/CLAUDE.md` - for [Claude Code](https://claude.ai)
- `.github/copilot-instructions.md` - for [GitHub Copilot](https://github.com/features/copilot)
- `AGENTS.md` - for [Codex](https://openai.com/codex), [Cline](https://github.com/cline/cline), and other AGENTS.md-compatible tools

You can also export to a single tool: `--cursor`, `--claude`, `--copilot`, or `--codex`.

The generated files concatenate all steering files (with `user-project-overrides.md` first) into the target tool's expected format. Regenerate after any steering file change.

## BONUS: Native Claude Code Support

kiro-rails is built for [Kiro](https://kiro.dev), but it ships a **native [Claude Code](https://claude.com/claude-code) layer** so the same discipline works there too - not just a flat `CLAUDE.md`, but real Claude-native hooks, subagents, slash commands, and skills.

```bash
./scripts/export-to-claude.sh
```

generates a complete `.claude/` tree from your Kiro files (the single source of truth):

| Generated | From | Notes |
|---|---|---|
| `.claude/CLAUDE.md` | `.kiro/steering/*.md` | always-on rules |
| `.claude/settings.json` | `.kiro/hooks/*.kiro.hook` | hooks remapped to Claude events (`UserPromptSubmit`, `PostToolUse`, `Stop`) **plus a Claude-only `PreToolUse` guard** |
| `.claude/hooks/guard-bash.sh` | `scripts/claude-guard-bash.sh` | **blocks cross-repo git** (`git -C` / destructive git outside the project root) - enforcement Kiro's hook model can't express |
| `.claude/agents/*.md` | `.kiro/agents/*.json` | subagents (tools + prompt body) |
| `.claude/commands/*.md` | `.kiro/prompts/*.md` | review prompts as slash commands |
| `.claude/skills/` | `.kiro/skills/` | copied as-is (format compatible) |
| `.mcp.json` (project root) | `.kiro/settings/mcp.json` | enabled servers only (disabled omitted); `autoApprove` tools become `settings.json` `permissions.allow` entries (`mcp__server__tool`) |

The generated `.claude/` tree is **committed** so Claude Code works the moment you clone - no extra step. Because it is generated, Kiro stays the single source of truth; `scripts/check-claude-fresh.sh` verifies the committed copy is in sync (run before any release - see the `versioning.md` checklist), and the `claude-export-freshness` hook reminds you to regenerate after editing `.kiro/`.

See [docs/references/kiro-to-claude-compatibility-2026-06-05.md](docs/references/kiro-to-claude-compatibility-2026-06-05.md) for the full Kiro→Claude mapping, what translates cleanly, and known limitations. Requires `jq`.

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

The security review system (v0.9.0+) was significantly influenced by Anthropic's ["Using LLMs to Secure Source Code"](https://claude.com/blog/using-llms-to-secure-source-code) (May 2026), which describes a 6-step find-and-fix loop: Threat Model, Sandbox, Discovery, Verification, Triage, and Patching. Their key insight - that discovery is now trivially parallelizable but the bottleneck has shifted to verification and triage - directly shaped our adversarial verification model. We adopted their two-agent approach (discovery agent + independent verifier that assumes findings are false positives), their severity calibration rubric (reachability, preconditions, blast radius), their deduplication-by-root-cause rules, and their variant analysis requirement after patching. Their finding that teams with an adversarial verifier roughly halved false positive rates validated our decision to ship a dedicated `security-verifier` agent alongside the `code-security-reviewer`. See [docs/security/gap-analysis-anthropic-llm-security-2026-05-31.md](docs/security/gap-analysis-anthropic-llm-security-2026-05-31.md) for the full gap analysis.

Key sources:
- [Anthropic - "Using LLMs to Secure Source Code"](https://claude.com/blog/using-llms-to-secure-source-code) - 6-step security loop, adversarial verification, severity calibration
- [MSR 2026 - "Beyond the Prompt: An Empirical Study of Cursor Rules"](https://arxiv.org/html/2512.18925v2) - taxonomy of 401 repos
- [ETH Zurich - Context file effectiveness study](https://arxiv.org/abs/2602.11988) - human-curated vs auto-generated rules
- [AGENTS.md Standard](https://github.com/agentsmd/agents.md) - Linux Foundation cross-tool specification
- [Augment Code - How to Build Your AGENTS.md](https://www.augmentcode.com/guides/how-to-build-agents-md) - patterns from 2,500+ repos

## Acknowledgments

The spec workflow skills and multi-tool export features were inspired by [OpenSpec](https://github.com/Fission-AI/OpenSpec) by [Fission AI](https://fission.ai). Their work on schema-driven spec workflows, multi-tool adapter generation, and the propose/apply/archive lifecycle informed our approach to structured planning within kiro-rails. We adapted these ideas to work with Kiro's native skill system and always-on enforcement model rather than opt-in CLI commands.

The AI/agentic surface review prompt (`review-ai-agent-surface.md`) was informed by [Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter) by [Sachin Sharma](https://www.linkedin.com/in/sachinsharma8080/). Their per-vulnerability-class skill architecture, 7-Question validation gate, and the `hunt-llm-ai` skill covering ASI01-10 from the attacker's perspective directly shaped our defensive counterpart - a structured audit prompt for AI-powered features aligned to OWASP Top 10 for Agentic Applications, LLM Applications, and MCP Top 10. We adapted the offensive hunting patterns into a defensive review framework that integrates with our tiered security model and adversarial verifier workflow.

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
