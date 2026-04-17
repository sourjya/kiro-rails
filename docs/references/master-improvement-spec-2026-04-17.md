# Kiro Rails - Master Improvement Spec

## Source

Gap analysis based on `docs/references/making-kiro-rails-a-stronger-out-of-the-box-agent-control-pack-2026-04-17.md`, cross-referenced against current repo state as of 2026-04-17.

---

## Gap Analysis Summary

### What we have vs what the analysis recommends

| Area | Current State | Gap | Priority |
|------|--------------|-----|----------|
| Steering files | 14 focused, self-contained files | ✅ Strong. Analysis confirms separation of concerns is the right design. | - |
| Installer | Version-tracked, interactive prompts, stale cleanup | ✅ Strong. Upgrade path is clean. | - |
| User customization | Single `user-project-overrides.md` | ✅ Strong. Analysis validates this pattern. | - |
| Skills/workflows | None | ❌ No `.kiro/skills/` directory. No packaged procedures. | P1 |
| Powers (MCP) | None | ❌ No `.kiro/powers/` directory. No MCP-backed integrations. | P2 |
| Cross-tool export | Kiro-only | ❌ No AGENTS.md, CLAUDE.md, .cursorrules, .windsurfrules generation | P1 |
| Agent roster | 1 agent (security reviewer) | ⚠️ Maintainability prompt exists but isn't an agent. Missing architecture, test-failure, release-readiness agents. | P2 |
| Hook scope | 4 hooks, Python-centric | ⚠️ Lint hook runs whole repo. Security hook is Pydantic-specific. No stack-aware variants. | P2 |
| Stack presets | Generic with Python defaults | ⚠️ Hooks, security checks, and examples are Python-first. No Ruby/Go/Node presets. | P3 |
| Deterministic verification | Advisory hooks only | ⚠️ No machine-checkable scripts (secret scan, license audit, schema diff, link validation). | P2 |
| Memory/context layer | None | ⚠️ No handoff file or session context mechanism. | P3 |
| Doctor command | Listed as future feature | ❌ No implementation. Would catch dead cross-refs, missing files, contradictory rules. | P2 |
| Settings | Empty `.kiro/settings/` directory | ⚠️ Ships no starter MCP or code intelligence config. | P3 |
| Comment standards | Requires docs on every property/private helper | ⚠️ Analysis says this is too aggressive - risks documentation theater. | P1 |
| Security agent resources | Narrow (Python/Node/Docker only) | ⚠️ Missing CI workflows, infra code, Ruby manifests, Terraform, K8s. | P2 |
| project-conventions.md | Contradicts itself (no pipes vs tee) | ⚠️ Minor but erodes rule trust. | P1 |

---

## Phase 1: Quick Wins (Low effort, high impact)

### 1.1 Fix contradictions and over-aggressive rules

**project-conventions.md** - The "NO pipes" rule contradicts the `tee` logging mandate. Fix: ban truncating pipes (`tail`, `head`, `grep` on test output) but explicitly allow `tee` for logging.

**code-commenting-standards.md** - Relax from "document every property and private helper" to "document modules, public APIs, complex private logic, non-obvious decisions, and security/performance rationale." Preserves intent, reduces boilerplate.

### 1.2 Cross-tool export: AGENTS.md

Generate an `AGENTS.md` at repo root that other tools (Claude Code, Cline, Copilot, Windsurf) can consume. This should be auto-generated from the steering files by a script, not hand-maintained. Content: project conventions summary, testing requirements, commit rules, security requirements.

Add to installer: generate `AGENTS.md` on install, add to `MANAGED_FILES` so it updates on upgrade.

### 1.3 Expand security agent resources

Add to `code-security-reviewer.json` resources:
```json
"file://.github/**/*.yml",
"file://.github/**/*.yaml",
"file://Gemfile",
"file://Gemfile.lock",
"file://go.mod",
"file://go.sum",
"file://Cargo.toml",
"file://Cargo.lock",
"file://terraform/**/*.tf",
"file://k8s/**/*.yaml",
"file://helm/**/*.yaml",
"file://.env.example",
"file://nginx*.conf",
"file://Makefile"
```

### 1.4 Promote maintainability prompt to agent

Create `.kiro/agents/code-maintainability-reviewer.json` mirroring the security agent pattern:
- Prompt: `file://../prompts/review-code-maintainability.md`
- Tools: read, grep, glob, knowledge (read-only)
- Resources: source code, tests, docs

---

## Phase 2: Capability Layer (Medium effort, high impact)

### 2.1 Add skills directory with starter skills

Create `.kiro/skills/` with focused, portable procedure files:

| Skill | Purpose |
|-------|---------|
| `feature-spec-author` | Guides agent through creating requirements.md, design.md, tasks.md for a new feature |
| `bug-triage` | Walks through bug identification, BUG-### creation, branch setup, regression test planning |
| `release-manager` | Version bump checklist: update version files, changelog, tag, push |
| `dependency-upgrade-audit` | Check outdated deps, review changelogs, assess breaking changes, update |
| `api-contract-review` | Validate API endpoints match schemas, check backward compatibility |

Each skill should be a short markdown file with:
- Description (one line - this is what triggers activation)
- Steps (the procedure)
- References (which steering files or docs to consult)

### 2.2 Deterministic verification scripts

Create `scripts/verify/` with machine-checkable scripts:

| Script | What it checks |
|--------|---------------|
| `secret-scan.sh` | Scans for hardcoded secrets, API keys, tokens (regex-based) |
| `lint-changed.sh` | Runs linter only on changed files (not whole repo) |
| `check-adr-links.sh` | Validates all ADR references in roadmap point to existing files |
| `check-docs-placement.sh` | Ensures no files in `docs/` root, all in subdirectories |

Wire these into hooks or make them available as manual verification steps.

### 2.3 Fix lint hook: changed files only

Replace the current `lint-python-files.kiro.hook` that runs `ruff check --fix .` (whole repo) with a version that only lints the edited file. The hook already receives the file path via the `fileEdited` trigger.

### 2.4 Make security hook stack-aware

Split `security-checkpoint.kiro.hook` into a generic version that doesn't reference Pydantic. The Pydantic-specific check ("max_length on string fields") should move to a Python preset or be generalized to "input validation constraints on all user-facing fields."

### 2.5 Add more agent profiles

| Agent | Purpose | Tools |
|-------|---------|-------|
| `architecture-reviewer` | Reviews system design, component boundaries, coupling | read, grep, glob |
| `test-failure-triager` | Analyzes test failures, identifies root cause, suggests fixes | read, grep, glob, shell |
| `release-readiness-reviewer` | Pre-release checklist: tests pass, changelog updated, version bumped, no TODOs | read, grep, glob |

### 2.6 Doctor command

Create `scripts/kiro-rails-doctor.sh` that validates:
- All steering files referenced in README exist on disk
- All files in `MANAGED_FILES` array exist
- No files in `docs/` root (only in subdirectories)
- ADR references in roadmap point to existing files
- No broken cross-references between steering files
- `user-project-overrides.md` exists
- Version file exists and matches expected format
- No stale files from previous versions remain

---

## Phase 3: Portability & Presets (Higher effort, strategic)

### 3.1 Cross-tool export compiler

Create `scripts/export-rules.sh` that generates from the steering files:
- `AGENTS.md` (Linux Foundation standard - Claude Code, Cline, Copilot)
- `.cursorrules` (Cursor)
- `.windsurfrules` (Windsurf)
- `.github/copilot-instructions.md` (GitHub Copilot)

Single source of truth in `.kiro/steering/`, compiled to each tool's format. Add to installer as optional step.

### 3.2 Stack presets

Restructure the installer to support preset modules:

| Preset | What it customizes |
|--------|-------------------|
| `python-fastapi` | Lint hook (ruff), security hook (Pydantic), test runner (pytest), deps (uv) |
| `python-django` | Lint hook (ruff), security hook (Django-specific), test runner (pytest), deps (pip/uv) |
| `node-express` | Lint hook (eslint), security hook (Express-specific), test runner (jest/vitest), deps (npm) |
| `node-next` | Lint hook (eslint), security hook (Next-specific), test runner (jest), deps (npm) |
| `ruby-rails` | Lint hook (rubocop), security hook (Rails-specific), test runner (rspec), deps (bundler) |
| `go-service` | Lint hook (golangci-lint), security hook (Go-specific), test runner (go test), deps (go mod) |
| `typescript-library` | Lint hook (eslint), test runner (vitest), deps (npm), no backend structure |

Each preset is a directory under `.kiro/presets/<name>/` containing override hooks, security checks, and test layout defaults. The installer applies the selected preset on top of the base files.

### 3.3 Memory/context layer

Add a lightweight `docs/context/` directory with:
- `current-focus.md` - what the team is working on right now (updated manually)
- `known-quirks.md` - non-obvious things about the codebase the agent should know
- `critical-commands.md` - commands the agent needs for this specific project

These are user-maintained handoff files, not auto-generated. The steering files reference them so the agent reads them on startup.

### 3.4 Powers directory

Create `.kiro/powers/` for MCP-backed integrations. Start with:
- `github-pr-review` - uses GitHub MCP to review PRs against steering rules
- `aws-deploy-check` - uses AWS MCP to validate deployment config

Powers are only relevant for teams using those specific MCP servers, so they should be opt-in via the installer.

### 3.5 Populate settings

Ship starter `.kiro/settings/mcp.json` with commented-out examples for common MCP servers (GitHub, AWS, database tools). Not active by default, but shows users what's possible.

---

## Phase 4: Polish & Ecosystem (Ongoing)

### 4.1 Eval suite

Create a small test suite that validates the pack itself:
- Does the installer run cleanly on a fresh directory?
- Does upgrade preserve `user-project-overrides.md`?
- Does upgrade remove stale files?
- Does doctor pass on a clean install?
- Do all cross-references resolve?

### 4.2 Community steering modules

Create a `community/` directory or separate repo for contributed steering files:
- Docker conventions
- CI/CD pipeline standards
- Monorepo conventions
- Microservices conventions
- Mobile app conventions

### 4.3 Interactive installer (npx)

Replace the bash installer with `npx create-kiro-project` that provides:
- Stack selection with preset application
- Database engine selection
- Optional cross-tool export
- Optional MCP server configuration
- Guided `user-project-overrides.md` population

---

## Implementation Order

```
Phase 1 (now)     → Fix contradictions, AGENTS.md, expand security agent, promote maintainability agent
Phase 2 (next)    → Skills, verification scripts, fix hooks, more agents, doctor command
Phase 3 (later)   → Cross-tool compiler, stack presets, memory layer, powers, settings
Phase 4 (ongoing) → Eval suite, community modules, npx installer
```

Each phase is independently shippable. Phase 1 can be done in a single session. Phase 2 is a week of focused work. Phase 3 is a multi-week effort. Phase 4 is ongoing community building.
