# Kiro-Rails Feature Sheet

**Version:** 0.20.0
**Updated:** 2026-07-18
**License:** MIT
**Repository:** [github.com/sourjya/kiro-rails](https://github.com/sourjya/kiro-rails)

---

## The Problem

AI coding agents are powerful but stateless. Between sessions, they forget your engineering standards. Without persistent guardrails, agents drift: skipping tests, inlining secrets, creating ad-hoc structures, ignoring changelogs, producing inconsistent code across features. Each session starts from zero — the agent has no memory of how your team writes code, documents decisions, or handles bugs.

The result is invisible at first and expensive later. Hardcoded URLs accumulate. Empty catch blocks normalize. Bug fixes ship without documentation. The same bug class recurs because nobody connected the dots. The "we should add a regression test" promise dies because nothing forces it.

Teams try to solve this with onboarding docs, code review checklists, and "please remember to..." messages. None of these work with AI agents because they require the agent to *read and remember* — which it does inconsistently, especially under context pressure in long sessions.

## The Solution

Kiro-rails encodes engineering discipline as **machine-readable rules that the agent cannot ignore.** Not suggestions — enforcement. Three layers working together:

1. **Steering files** (22 always-on context documents) shape how the agent thinks and writes code. They're loaded into the agent's context on every interaction. The agent doesn't just write code; it follows your team's rules about *how* code should be written, tested, documented, and deployed. These are the constitution — the standing rules.

2. **Automated hooks** (30 triggers) detect violations and act in real-time — on every file save and every commit. They don't remind the agent to do something; they *do* it. A detection hook catches an empty `catch {}` block the moment it's written. A scaffolding hook creates the matching test file the moment a source file appears. A documentation hook captures the bug fix diff at commit time. These are the reflexes — they fire whether the agent remembers the rule or not.

3. **Review prompts** (17 on-demand audits) perform deep analysis at checkpoints — security scans, maintainability reviews, UX audits, dependency risk assessments. They catch what accumulated between hook firings: systemic drift, pattern families, codebase-wide inconsistencies that no single-file hook can see. These are the periodic health checks.

The three layers form a **closed loop**: steering prevents mistakes → hooks catch what steering missed → prompts audit for systemic drift → prompt findings tune hook patterns → hooks prevent recurrence. No concern relies on a single mechanism. Every rule has a backup. The system gets tighter over time as the feedback loop runs.

## How It Works In Practice

**Day 1:** Install kiro-rails (`curl | bash`). The agent now has 22 steering files in its context. It follows TDD, uses conventional commits, creates specs before code, respects branch discipline. No configuration needed — the defaults are opinionated and correct.

**Every file save:** Hooks fire silently. They check for deprecated patterns, deep relative imports, hardcoded values, empty catch blocks. If something's wrong, the hook speaks up with the specific violation and the correct alternative. If everything's clean, silence.

**Every commit:** Pre-commit hooks verify staged files. The changelog is drafted from `git log`. Bug Scribe captures fix diffs into bug documents. Secrets are blocked. Merged branches are auto-deleted.

**Feature complete:** Run 2-3 review prompts. Get a structured report with severity, evidence, and remediation. Findings become tickets. The worst patterns get wired into hooks so they're caught automatically next time.

**Bug discovered:** Type `# bug: TYPE_MISMATCH — API returns wrong shape` in the code. Save. Bug Scribe instantly creates a full bug document — metadata, code context, chokepoint log entry — zero tokens, deterministic. When you commit the fix, the diff and your commit message flow into the document as the solution. If the same bug category hits 3 times, the system recommends promoting it to a permanent steering rule.

**Sprint end:** Run Tier 3 security review + test quality audit. The reports prove the codebase is healthy. Drift that accumulated is identified and addressed. The cycle restarts.

## What Makes It Different

**It's enforcement, not documentation.** Most "rules for AI" projects produce markdown files that describe best practices. Kiro-rails *enforces* them with automated detection and action. The agent can't skip a regression test because the hook creates the test file automatically. It can't commit a secret because the pre-commit hook blocks it. It can't ignore a changelog because the draft is generated from `git log`.

**The primary path costs zero tokens.** Detection hooks are deterministic shell scripts — regex, grep, awk. They run in 10-60ms with no LLM call. Only the parts that genuinely need judgment (pattern classification, ADR content) use agent tokens. The system is fast, cheap, and identical every time.

**It gets smarter over time.** The feedback loop between prompts and hooks is the mechanism. Each review prompt run finds patterns the hooks don't catch yet. Those patterns become new hook regex. Next time, the hook catches it on save instead of waiting for the sprint review. The system converges toward zero drift.

**It works with any AI coding tool.** Designed for Kiro, but ships a native Claude Code layer and export scripts for Cursor, Copilot, and Codex. The engineering principles are universal; the enforcement mechanisms adapt to each tool's capabilities.

---

## One-Line Summary

An opinionated project template that gives AI coding agents persistent engineering discipline — TDD, spec-driven planning, security reviews, automated bug documentation, and structured enforcement — from the first commit.

---

## What It Is

Kiro-rails is a drop-in `.kiro/` directory (plus `scripts/` and `docs/` taxonomy) that turns any project into a disciplined engineering environment. It works by encoding your team's standards as **steering files** — persistent context documents that your AI assistant reads on every interaction — backed by **automated hooks** that detect and act on violations in real-time.

It's designed for [Kiro](https://kiro.dev) but works with any MCP-compatible AI coding tool. Ships with a native Claude Code layer and export scripts for Cursor, Copilot, and Codex.

---

## By The Numbers

| Metric | Count |
|--------|-------|
| Steering files (always-on context) | 22 |
| Automated hooks | 30 |
| Review prompts (on-demand audits) | 17 |
| Agent definitions | 4 |
| Skills (workflow automations) | 7 |
| Scripts (tooling) | 15 |
| Documentation directories | 14 |
| Supported export targets | 5 (Kiro, Claude Code, Cursor, Copilot, Codex) |

---

## Core Capabilities

### 1. Triangulation Enforcement Model (ADR-002)

Every engineering concern is covered by three layers working together:

| Layer | Role | Timing |
|-------|------|--------|
| **Steering** (prevention) | Tells the agent *how* to behave | Every interaction |
| **Hooks** (detection + action) | Catches violations and acts automatically | On file save / commit |
| **Prompts** (audit) | Deep codebase-wide drift analysis | On-demand at checkpoints |

The feedback loop: prompts find systemic issues → findings tune hook configurations → hooks prevent recurrence in real-time.

### 2. Bug Scribe — Automated Bug Documentation (v0.19.0+)

Type `# bug: CATEGORY — description` in any source file. Three hooks handle the rest:

| Hook | Trigger | What it does | Cost |
|------|---------|-------------|------|
| `bug-scribe-on-fix` | File saved | Scaffolds `BUG-###.md` with metadata, code context, chokepoint log entry | Zero tokens |
| `bug-scribe-capture-diff` | Commit | Injects fix diff + commit message (solution) into existing bug doc | Zero tokens |
| `bug-scribe-pattern-detect` | Bug doc edited | Counts bugs per category, flags trends at 2+, recommends guardrail promotion at 3+ | Agent-powered |

**Also supports marker disappearance:** teams that already tag bugs with `# BUG:` comments get automatic documentation when the marker is removed (the fix).

Each bug doc is a **self-contained importable ticket** — problem, context, root cause, solution, diff, impact, regression tests, variant search, lessons, timeline.

### 3. Detection Hooks — Real-Time Code Quality

| Hook | What it catches | False positive rate |
|------|----------------|-------------------|
| Empty catch detector | `except: pass`, `catch {}` | Zero — always wrong |
| Deprecated pattern detect | `datetime.utcnow()`, `window.alert()`, `var` keyword | Zero — explicitly banned |
| Import path autofix | `../../` deep relative imports | Zero — banned by rule |
| Hardcoded value scan | UUIDs, URLs, IPs, port numbers in source | Low — skips tests/config |
| Test file scaffold | New source file without matching test | N/A — creates, doesn't block |
| Chokepoint auto-promote | 3+ bugs in same category without a steering rule | N/A — agent evaluates |

### 4. Hook Upgrades — "Remind" → "Act"

Six existing hooks upgraded from printing reminders to taking action:

| Hook | Before | After |
|------|--------|-------|
| Changelog maintenance | Asks agent to check changelog | Drafts entry from `git log` grouped by type |
| Variant search | Prints "remember to search" | Executes the grep, reports findings |
| Branch hygiene | Lists merged branches | Auto-deletes them |
| Fix spiral detector | Warns "3+ fix commits" | Auto-logs chokepoint entry |
| ADR trigger | Asks "should you write an ADR?" | Scaffolds template with pre-filled context |
| Changelog consolidation | Warns "10+ commits behind" | Drafts grouped entry |

### 5. Security — Three-Tier Audit Model

| Tier | When | Scope | Action |
|------|------|-------|--------|
| Tier 1 | Every commit (automatic) | Staged files | Blocks secrets, unsafe execution, auth bypass |
| Tier 2 | Feature complete | Changed files | Full OWASP + BOLA/IDOR + crypto + file upload |
| Tier 3 | Sprint end | Full codebase | + supply chain + headers + logging + rate limiting |

Plus: adversarial verification agent (assumes findings are false positives and searches for compensating controls), AI/agentic surface review (OWASP ASI01-10, MCP Top 10).

### 6. Spec-Driven Development Workflow

```
Idea → Spec (proposal/requirements/design/tasks) → TDD Implementation → Verification → Archive
```

Four skills automate the lifecycle: `spec-propose`, `spec-implement`, `spec-verify`, `spec-archive`.

### 7. Git & Focus Discipline

- **One task, one branch, merge-and-delete** — no branch sprawl
- **Request queue protocol** — mid-task requests get filed to backlog, not chased
- **Defensive checkpoints** — commit at every passing state, never end with uncommitted work
- **Collision detection** — `scripts/branch-check.sh` warns before parallel branches diverge
- **Session isolation** — never reach into another repo, never kill processes you didn't spawn

### 8. UX Review System

- **Console-idiom rubric** — 9 check families, 44 checks, severity scoring, ship gate
- **Live browser-walk protocol** — agent drives Chrome DevTools, produces scored report
- **Pattern registry** — reference layouts for common screen types

### 9. Documentation Taxonomy

14 purpose-specific directories, each with defined placement rules:

```
docs/backlog/ · decisions/ · architecture/ · roadmap/ · changelogs/ · bugs/
     ideas/ · technical-debt/ · testing/ · runbooks/ · references/
     engineering/ · security/ · ux-reviews/
```

### 10. Multi-Tool Export

One command generates equivalent configs for 5 tools:

```bash
./scripts/export-to-tools.sh --all
# → .cursorrules, .github/copilot-instructions.md, AGENTS.md, .claude/ (native)
```

---

## Reusable Infrastructure

| Component | What it does | Used by |
|-----------|-------------|---------|
| `scripts/lib/template.sh` | Template rendering (`KEY=value`, `KEY=@filepath`) | Bug Scribe, future scaffolding |
| `scripts/lib/detect.sh` (planned) | Shared detection script preamble | All detection hooks |
| `docs/bugs/ledger.json` | Structured bug tracking (machine-parseable) | Bug Scribe, pattern detection |
| `docs/bugs/BUG-000-template.md` | Importable ticket template with `{{PLACEHOLDER}}` markers | Bug Scribe |
| Function detection (`detect_function`) | Per-language enclosing function finder | Bug Scribe, future hooks |

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Deterministic shell over LLM for detection | Zero tokens, instant, identical every time. LLM only for judgment. |
| Two-trigger model (discovery + resolution) | Bug marker means "I found this" not "I fixed this." Captures the full lifecycle. |
| Template-based scaffolding | Human-editable templates as single source of truth. Scripts fill placeholders. |
| Steering + Hook + Prompt triangulation | No single layer is sufficient. Three angles create defense-in-depth. |
| Independently disablable hooks | Each hook has `enabled: false`. No all-or-nothing. |
| Case-insensitive matching, strict structure | Reduce friction (case) while keeping parsing reliable (structure). |

---

## What's NOT Included (by design)

- No runtime application code — this is a template, not a framework
- No CI pipeline — projects bring their own CI; kiro-rails provides the local discipline
- No language lock-in — steering principles are language-agnostic; scripts detect per-language
- No paid services — zero external dependencies, zero API calls on the primary path
- No opinion on which AI tool — works with Kiro, Claude Code, Cursor, Copilot, Codex

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.sh | bash
```

Safe to re-run (upgrades managed files, never touches `user-project-overrides.md`).

---

## Versioning

- Semantic versioning (MAJOR.MINOR.PATCH)
- Currently pre-1.0 (beta): breaking changes allowed per minor bump
- Git tags: `v0.19.0` (Bug Scribe), `v0.20.0` (Hook Automation Sweep)

---

## Research & Inspirations

- [Anthropic - "Using LLMs to Secure Source Code"](https://claude.com/blog/using-llms-to-secure-source-code) — adversarial verification model
- [MSR 2026 - "Beyond the Prompt"](https://arxiv.org/html/2512.18925v2) — taxonomy of cursor rules across 401 repos
- [ETH Zurich - Context file effectiveness](https://arxiv.org/abs/2602.11988) — human-curated vs auto-generated
- [OpenSpec](https://github.com/Fission-AI/OpenSpec) — propose/apply/archive spec lifecycle
- [Auto-COE](https://github.com/yogeshselvarajan/kiro-auto-coe-hook) — deterministic bug documentation from inline markers
- [Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter) — OWASP ASI01-10 from attacker perspective
- [Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) — compliance framework mapping

---

## License

MIT — use it, fork it, adapt it, sell products built with it.
