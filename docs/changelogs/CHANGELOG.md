# Changelog

All notable changes to this project will be documented in this file.
Format: consolidated entries grouped by feature, not per-file edits.
Rolling policy: archive to CHANGELOG.YYYY-MM-DD.md when exceeding 500 lines.

## 2026-05-21 — v0.7.0

### Added (from cross-codebase bug pattern analysis of 120+ bugs across 13 projects)

- **Frontend Patterns steering** (`frontend-patterns.md`, fileMatch: tsx/jsx) — React hooks rules (hooks before early returns), event propagation discipline (DnD listeners, Escape layering, portal outside-click), CSS layout rules (min-h-0, overflow-hidden, header/body alignment), cache invalidation rules, component completeness checklist
- **API Contract Discipline steering** (`api-contract-discipline.md`, fileMatch: api/routes/services) — contract-first development (define schema before implementing), response shape verification, error response contracts, rate limiting guidance
- **Async Discipline** in `error-handling-performance.md` — `mutateAsync` + await for dependent operations, never block async event loops with sync I/O, auth token timing, sequenced mutations
- **State Persistence Rule** in `reusable-architecture.md` — explicit persistence strategy for all state, module-level variables are ephemeral, single source of truth, sync on startup
- **Fix Depth Rule** in `change-discipline.md` — two-fix limit, map all paths before fix #3, root cause not symptoms, document what you tried
- **Copy-Paste Verification** in `change-discipline.md` — review all values after copying, check return types, check message objects, check config references
- **Package Manifest Verification** in `change-discipline.md` — verify npm files array, pyproject.toml include, bin entries, declared dependencies
- **Comment-Safe Patterns** in `code-commenting-standards.md` — no unescaped `*/` in JSDoc, no nested `/*`, regex in backticks
- **Auth Implementation Skill** (`.kiro/skills/auth-implementation/SKILL.md`) — comprehensive SSO/OAuth checklist: happy path, expired token, missing session, provider quirks, redirect loop prevention (max 2), graceful degradation, testing requirements
- **Fix Spiral Detector hook** (UserPromptSubmit) — checks git log for 3+ consecutive fix commits, appends root-cause-analysis warning
- **Type Check on Stop hook** (Agent Stop) — runs `tsc --noEmit` or `ruff check` after agent finishes responding
- **Package Manifest Verify hook** (File Edit on package.json/pyproject.toml) — runs `npm pack --dry-run` to verify published artifact
- **Completeness Verification phase** in TDD task template — mandatory final phase checking error/loading/empty states, persistence, destructive action UX, API contract verification, cache invalidation

### Strengthened

- **Security Tier 1 hook** — added T1-S10 (exception details in responses) and T1-S11 (missing input validation on new routes)
- **Comment Standards hook** — now detects parser-breaking comments (unescaped `*/` inside JSDoc blocks)

## 2026-04-12

### Added
- **Themed Dialogs rule** in engineering-standards.md - all confirmation dialogs, alerts, and popups must use themed components. Native browser dialogs (`window.alert`, `window.confirm`, `window.prompt`) are forbidden. Includes accessibility requirements (focus trap, Escape, ARIA roles). Propagated to all projects.
