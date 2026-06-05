# Changelog

All notable changes to this project will be documented in this file.
Format: consolidated entries grouped by feature, not per-file edits.
Rolling policy: archive to CHANGELOG.YYYY-MM-DD.md when exceeding 500 lines.

## 2026-06-05 - v0.10.0

### Added - Focus & Branch Discipline

Two recurring process failures - mid-task request thrashing and branch sprawl - are now encoded as first-class kiro-rails guardrails (steering + hooks + a tool), ported from patterns proven downstream in planiq.

- **`focus-and-branch-discipline.md` steering** (`inclusion: always`) - the Request Queue Protocol (file unrelated mid-task requests to the backlog, acknowledge, finish the current task; divert only on explicit user order), a strict Definition of Done (code -> tests -> commit -> merge -> delete branch -> drain backlog), and Branch Hygiene rules (one task per branch, merge-and-delete as one motion, check before branching, prune merged, reconcile divergence by committing immediately).
- **`docs/backlog/INBOX.md`** - the on-disk request queue the protocol writes to, plus a new `docs/backlog/` directory in the taxonomy. Shipped as a download-if-missing template so a user's queue is never overwritten on upgrade.
- **`scripts/branch-check.sh`** - branch collision detector. `branch-check.sh <area>` shows whether any unmerged branch already touches an area before you fork a parallel one; with no args it lists other unmerged branches editing the same files as the current branch, with commit dates - the early-warning signal for silent divergence.
- **`focus-guard` hook** (prompt submit) - when there's uncommitted work on a non-main branch, reminds the agent to queue unrelated requests instead of thrashing.
- **`branch-hygiene-check` hook** (prompt submit) - flags branches merged into main but not deleted, and warns when the local branch count grows large.

### Changed

- Steering file count: 18 -> 19; hook count: 13 -> 15; docs directories: 13 -> 14.
- Both installers (`install.sh`, `install.ps1`) updated to manage the new steering file, hooks, script, `docs/backlog/` directory, and INBOX template. Version bumped to 0.10.0.
- README: new discipline rows in the "with steering" table, steering and hooks table entries, project-structure tree entries.

## 2026-06-01 - v0.9.1

### Added (from Claude-BugHunter adaptation + cross-repo audit)

- **AI/Agentic Surface Review prompt** (`.kiro/prompts/review-ai-agent-surface.md`) - comprehensive security audit for AI-powered features aligned to OWASP Top 10 for Agentic Applications (ASI01-10), LLM Applications (2025), and MCP Top 10. Covers: prompt injection/goal hijack, tool scope/misuse, agent identity/privilege, MCP supply chain, code execution, memory poisoning, inter-agent comms, confidence gating, action provenance, cascading failures. Includes severity calibration, verification pass, gap-finding behavior, three-property test (attributable, reversible, gated), and agent surface matrix. Reports as `AISR-{###}-{YYYY-MM-DD}.md`. Informed by [Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter)'s `hunt-llm-ai` skill and 7-Question validation gate.
- **Security Enhancement Spec** (`docs/references/kiro-rails-security-enhancement-spec.md`) - research document covering the Claude-BugHunter adaptation plan: what translates to kiro-rails (per-vuln-class review checklists, validation gates, AI surface review), what doesn't (offensive recon, red-team tooling), and proposed future skills (security-hunt/, security-triage/).
- **Cross-Repo Audit** (`docs/references/cross-repo-audit-2026-06-01.md`) - full audit of 3 internal production repos documenting what's already synchronized, what's project-specific, evolution history of each agent/prompt/skill, and decision criteria for inclusion.
- **AISR report type** in `review-policy.md` output convention table - `AISR-{###}-{YYYY-MM-DD}.md` for AI Surface Reviews.
- **Claude-BugHunter acknowledgment** in README - credits Sachin Sharma's per-vulnerability-class skill architecture and 7-Question validation gate.

### Changed

- Review prompt count: 13 → 14 (added review-ai-agent-surface.md)
- README "What's included" line updated to reflect 14 prompts

## 2026-05-31 - v0.9.0

### Added (from Anthropic "Using LLMs to Secure Source Code" gap analysis + cross-project steering audit)

- **Severity Calibration Rubric** in `review-code-security.md` - structured questions (reachability, attacker control, preconditions, authentication, impact type, blast radius) that must be answered before assigning severity to any T2/T3 finding
- **Deduplication Rules** in `review-code-security.md` - group findings by root cause, report missing global protections once (not per-endpoint), same file + same category + lines within 10 = one finding
- **Verification Pass** in `review-code-security.md` - after producing findings, adversarially re-examine each HIGH+ finding assuming it is a false positive; search for compensating controls; downgrade or remove disproved findings
- **Verification Pass** in `review-code-maintainability.md` - check if "duplication" is intentional (documented in ADRs), if proposed abstraction would create worse coupling, if fix cost exceeds maintenance cost
- **Verification Pass** in `review-api-contracts.md` - check if "inconsistency" is documented intentional exception, if endpoint is internal-only, if middleware already enforces the concern globally
- **Context-reading preamble** added to all 13 review prompts - each prompt now reads `docs/decisions/` ADRs and domain-specific docs before scanning; documented exceptions are not flagged as findings
- **Security Verifier agent** (`.kiro/agents/security-verifier.json`) - adversarial read-only agent that assumes each finding is a false positive and searches for compensating controls. Reports DISPROVED/CONFIRMED/DOWNGRADE per finding.
- **Chokepoint Logging steering** (`.kiro/steering/chokepoint-logging.md`) - log recurring errors on attempt #2+, categorize by pattern (ROUTE_ORDERING, CSS_OVERSIGHT, TYPE_MISMATCH, STATE_SYNC, RACE_CONDITION, etc.), promote to steering rules after 3 occurrences. Generalized from internal projects.
- **Variant Analysis** in bug resolution workflow (`git-workflow.md`) - after identifying root cause, search for same pattern at all other call sites and same vulnerability class elsewhere; fix ALL variants in the same branch

### Changed

- Review prompt count unchanged (13) but all now include context-reading preamble
- Agent count: 2 → 3 (added security-verifier)
- Steering file count: 17 → 18 (added chokepoint-logging)
- Bug resolution workflow: 7 steps → 8 steps (variant search inserted as step 4)

## 2026-05-21 - v0.7.0

### Added (from cross-codebase bug pattern analysis of 120+ bugs across 13 projects)

- **Frontend Patterns steering** (`frontend-patterns.md`, fileMatch: tsx/jsx) - React hooks rules (hooks before early returns), event propagation discipline (DnD listeners, Escape layering, portal outside-click), CSS layout rules (min-h-0, overflow-hidden, header/body alignment), cache invalidation rules, component completeness checklist
- **API Contract Discipline steering** (`api-contract-discipline.md`, fileMatch: api/routes/services) - contract-first development (define schema before implementing), response shape verification, error response contracts, rate limiting guidance
- **Async Discipline** in `error-handling-performance.md` - `mutateAsync` + await for dependent operations, never block async event loops with sync I/O, auth token timing, sequenced mutations
- **State Persistence Rule** in `reusable-architecture.md` - explicit persistence strategy for all state, module-level variables are ephemeral, single source of truth, sync on startup
- **Fix Depth Rule** in `change-discipline.md` - two-fix limit, map all paths before fix #3, root cause not symptoms, document what you tried
- **Copy-Paste Verification** in `change-discipline.md` - review all values after copying, check return types, check message objects, check config references
- **Package Manifest Verification** in `change-discipline.md` - verify npm files array, pyproject.toml include, bin entries, declared dependencies
- **Comment-Safe Patterns** in `code-commenting-standards.md` - no unescaped `*/` in JSDoc, no nested `/*`, regex in backticks
- **Auth Implementation Skill** (`.kiro/skills/auth-implementation/SKILL.md`) - comprehensive SSO/OAuth checklist: happy path, expired token, missing session, provider quirks, redirect loop prevention (max 2), graceful degradation, testing requirements
- **Fix Spiral Detector hook** (UserPromptSubmit) - checks git log for 3+ consecutive fix commits, appends root-cause-analysis warning
- **Type Check on Stop hook** (Agent Stop) - runs `tsc --noEmit` or `ruff check` after agent finishes responding
- **Package Manifest Verify hook** (File Edit on package.json/pyproject.toml) - runs `npm pack --dry-run` to verify published artifact
- **Changelog Consolidation Reminder hook** (UserPromptSubmit) - warns if 10+ commits since last changelog update, triggers consolidation
- **Bug Doc Completion Check hook** (File Edit on BUG-*.md) - verifies root cause, fix, regression tests, and status fields are filled
- **ADR Trigger hook** (File Edit on infrastructure files) - suggests creating an Architecture Decision Record when docker-compose, Dockerfile, Terraform, CI/CD workflows are modified
- **Completeness Verification phase** in TDD task template - mandatory final phase checking error/loading/empty states, persistence, destructive action UX, API contract verification, cache invalidation

### Strengthened

- **Security Tier 1 hook** - added T1-S10 (exception details in responses) and T1-S11 (missing input validation on new routes)
- **Comment Standards hook** - now detects parser-breaking comments (unescaped `*/` inside JSDoc blocks)

## 2026-04-12

### Added
- **Themed Dialogs rule** in engineering-standards.md - all confirmation dialogs, alerts, and popups must use themed components. Native browser dialogs (`window.alert`, `window.confirm`, `window.prompt`) are forbidden. Includes accessibility requirements (focus trap, Escape, ARIA roles). Propagated to all projects.
