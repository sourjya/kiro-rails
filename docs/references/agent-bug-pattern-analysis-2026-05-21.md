# Agent Bug Pattern Analysis — Cross-Codebase Scan

**Date:** 2026-05-21
**Scope:** 13 active codebases, ~120 documented bugs, 140+ fix commits, 50+ log files
**Purpose:** Identify recurring AI agent coding mistakes to improve kiro-rails steering files

---

## Executive Summary

Across 13 codebases, **70-80% of documented bugs are agent-introduced**. The top failure modes are predictable and preventable with better steering rules. The most damaging patterns are:

1. **Incomplete implementation** — agent builds happy path, skips edge cases
2. **API response shape mismatch** — frontend/backend contract drift
3. **Iterative debugging spirals** — fix-on-fix chains (up to 7 commits for one issue)
4. **Missing state persistence** — ephemeral state lost on reload
5. **Platform/packaging ignorance** — npm, ESM, build tool behaviors misunderstood

---

## Codebases Scanned

13 projects of varying size and maturity, spanning fullstack web apps, CLI tools, browser extensions, shared libraries, and backend services. Mix of Python and TypeScript stacks.

---

## Top 15 Bug Patterns (Ranked by Frequency)

### 1. Incomplete Implementation (22+ instances)
**What happens:** Agent implements the happy path but skips error states, loading states, empty states, UX patterns (toast+undo, confirmation dialogs), and specced features.

**Examples:**
- Section headers rendered but grouping logic never wired
- Attachment delete — no confirmation, no activity log, no optimistic update
- Custom field cells empty — API doesn't return data, no inline editor
- Screenshot data never sent to server — the send function doesn't exist

**Root cause:** Agent satisfies the immediate visual requirement without implementing the full interaction model.

---

### 2. API Response Shape Mismatch (15+ instances)
**What happens:** Frontend assumes one response structure, backend returns another. Common variants: array vs `{items: [...]}` wrapper, `resp.data.message` vs unwrapped JSON, missing fields in response schema.

**Examples:**
- Frontend expected array, API returned `{items: [...]}`
- Chat response accessed `resp.data.message` but API returns unwrapped JSON
- Generate endpoint returns `{data: {project, critic}}` but client typed as `Project`
- `field.options` stored as comma-separated string but renderer calls `.map()`

**Root cause:** Agent writes frontend and backend in separate passes without verifying the contract matches. No schema validation at the boundary.

---

### 3. Auth/SSO Flow Errors (12+ instances)
**What happens:** Infinite redirect loops, wrong redirect URIs, hardcoded localhost, provider-specific incompatibilities.

**Examples:**
- 7+ commits fixing SSO redirect — each fix broke another path
- `prompt=none` used but identity provider doesn't support it
- `redirect_uri` hardcoded to localhost instead of `window.location.origin`
- OIDC breaks app when identity provider is unavailable

**Root cause:** Auth flows have many edge cases (expired tokens, missing sessions, provider quirks). Agent implements the happy path without testing failure modes.

---

### 4. Race Conditions / Async Timing (8+ instances)
**What happens:** Fire-and-forget mutations before dependent operations, auth tokens not ready when requests fire, event handler ordering issues.

**Examples:**
- `mutate()` (fire-and-forget) then immediately `publishDraft.mutate()` — save hadn't completed
- Config request fires before auth token available, gets 401, staleTime prevents retry
- ComboSelect open/close race condition
- Sync LLM call (30s-3min) on asyncio event loop without `run_in_executor`

**Root cause:** Agent uses `mutate` instead of `mutateAsync` + await. Doesn't consider operation ordering or blocking calls on async loops.

---

### 5. Event Propagation / Handler Conflicts (6+ instances)
**What happens:** `stopPropagation` missing, DnD listeners capturing all clicks, Escape key leaking through layers, React synthetic vs native event mismatch.

**Examples:**
- Escape key toggles drawer — missing stopPropagation
- React `stopPropagation()` doesn't stop native DOM event
- dnd-kit `{...listeners}` on folder wrapper captured all pointer events
- Record mode blocks page interaction — annotate mode's onClick not disabled

**Root cause:** Agent doesn't understand event bubbling/capture phases, or that React synthetic events don't stop native DOM propagation.

---

### 6. CSS/Layout Issues (6+ instances)
**What happens:** Overflow clipping, flex min-height defaults, positioning mismatches between header and body, wrong positioning for context.

**Examples:**
- Calendar positioned absolute inside container with `overflow: hidden`
- Header uses CSS grid 72px gutter, row uses flex gap-1 — misaligned
- Missing `overflow-hidden` and `min-h-0` on flex container
- Popover positioned `right: 0` but trigger is in top-left corner

**Root cause:** Agent doesn't verify visual output matches intent. Doesn't understand flex/grid interaction with overflow.

---

### 7. Missing State Persistence (5+ instances)
**What happens:** State stored in module-level variables or React state, lost on page reload or content script reload.

**Examples:**
- Toggle state in module variable, destroyed on content script reload
- Suggestions cache in-memory only, re-scan doesn't check existing data
- Mock user IDs not persisted — optimistic state lost on reload
- Auth token in three separate sources of truth, never synchronized

**Root cause:** Agent defaults to in-memory state without considering persistence requirements. Doesn't ask "what happens on reload?"

---

### 8. Platform/Packaging Misunderstanding (4+ instances)
**What happens:** npm `files` array not updated, npx resolution misunderstood, ESM + symlinks incompatible, build tool path flattening not accounted for.

**Examples:**
- `bin/` directory missing from npm package `files` array
- npx resolves by package name, not bin name
- Build tool flattens `welcome/index.html` → `welcome.html`, code used source path
- npm symlinks + ESM `import.meta.url` incompatibility

**Root cause:** Agent doesn't understand build tool transformations or package manager resolution algorithms.

---

### 9. Copy-Paste / Forgotten Configuration Updates (4+ instances)
**What happens:** Code copied from similar context with wrong defaults, config files not updated when new files/features added.

**Examples:**
- Standalone mode returned `isConnected: true` — copied from connected mode where it made sense
- `success` property references wrong model's fields (copy-paste from similar class)
- Created bin wrapper but forgot to update `files` array in package.json
- Constructed new message object without including required `requestId` field

**Root cause:** Agent copies patterns without adapting all fields. Doesn't verify the copied code makes sense in new context.

---

### 10. Stale State / Caching Issues (5+ instances)
**What happens:** React Query `staleTime` prevents refetch after invalidation, cached server info stale, old tokens not refreshed.

**Examples:**
- `staleTime: 60_000` prevented refetch after cache invalidation
- staleTime prevents retry after 401 error
- Extension caches first healthy server for 30s regardless of which project the page belongs to
- Dashboard page shows stale data (fixed twice — regression)

**Root cause:** Agent sets aggressive caching without considering invalidation scenarios.

---

### 11. Iterative Debugging Spirals (Anti-Pattern)
**What happens:** Agent makes a fix that introduces a new edge case, requiring another fix, creating chains of 3-7 commits for one issue.

**Worst examples:**
- SSO auth: 7+ commits over multiple sessions
- Metrics library integration: 4 consecutive commits
- Server startup: 4 consecutive commits adding missing functionality
- Rate limiting: 3 commits (too low → wrong scope → still too low)
- Chat bubble visibility: 3 commits for the same issue

**Root cause:** Agent fixes symptoms without understanding the full system. Each fix addresses one path while breaking another.

---

### 12. React Hooks / Lifecycle Violations (3+ instances)
**What happens:** Hooks placed after early returns, missing provider wrappers, useParams outside Route context.

**Examples:**
- `useCallback` hooks AFTER early returns — different hook count between renders
- `useParams()` returns empty outside Route context
- Missing `QueryClientProvider` since a previous sprint's refactor

**Root cause:** Agent doesn't consistently follow React rules of hooks or verify component tree context.

---

### 13. Missing Dependencies / Wiring (7+ instances)
**What happens:** Package used but not in manifest, lifecycle hooks not connected, missing provider wrappers.

**Examples:**
- `email-validator` required by Pydantic EmailStr but missing from pyproject.toml
- `fast-json-patch` missing from root package.json
- Event publisher startup/shutdown not wired into app lifecycle
- Constant not exported from shared package despite being imported elsewhere

**Root cause:** Agent uses features without verifying the dependency is declared and wired.

---

### 14. Security Gaps (4+ instances)
**What happens:** Missing input validation, CSP misconfiguration, secret duplication, information leakage in error responses.

**Examples:**
- Role escalation via registration endpoint
- Search input allows query injection + no length cap
- API endpoints leak exception details to client
- JSONB injection vulnerability in query builder

**Root cause:** Agent doesn't apply security thinking by default — treats it as an afterthought.

---

### 15. AI-Generated Comments Breaking Code (2 instances)
**What happens:** Agent writes JSDoc/docstring containing patterns that break the parser (e.g., `*/` from glob patterns closing a comment block).

**Examples:**
- JSDoc comment with glob pattern `*/` prematurely closed comment block — required TWO fix commits

**Root cause:** Agent doesn't validate that generated comments are syntactically safe.

---

## Actionable Kiro-Rails Improvements

### HIGH PRIORITY — New Steering Rules Needed

| # | Proposed Rule | Addresses Pattern | Where |
|---|---|---|---|
| 1 | **Contract-First Development**: When implementing frontend+backend, define the API response schema FIRST (as a type/interface), then implement both sides against it. Never assume response shape. | #2 API Shape Mismatch | `error-handling-performance.md` or new `api-contracts.md` |
| 2 | **Completeness Checklist**: Before marking any feature task done, verify: error state, loading state, empty state, edge cases, persistence across reload, undo/confirmation for destructive actions. | #1 Incomplete Implementation | `testing-standards.md` |
| 3 | **Async Discipline**: Always use `mutateAsync` + `await` when a subsequent operation depends on the result. Never fire-and-forget before dependent operations. Never run blocking I/O on async event loops. | #4 Race Conditions | `error-handling-performance.md` |
| 4 | **State Persistence Rule**: For any state that should survive page reload, explicitly choose a persistence mechanism (localStorage, chrome.storage, database, URL params). Module-level variables are ephemeral — document why if intentionally ephemeral. | #7 Missing Persistence | `reusable-architecture.md` |
| 5 | **Fix Depth Rule**: If a fix introduces a new failure, STOP. Read the full integration context (all related code paths, not just the failing one). Map all paths through the system before attempting fix #2. Never chain 3+ fixes for the same issue. | #11 Iterative Spirals | `change-discipline.md` |
| 6 | **Package Manifest Verification**: After creating any new file that should be published/deployed, verify it's included in the relevant manifest (`files` in package.json, `include` in pyproject.toml, build config). After adding any import, verify the dependency is declared. | #8 Platform/Packaging, #13 Missing Deps | `change-discipline.md` |
| 7 | **Event System Awareness**: When adding event handlers, document: what events are captured, what propagation is stopped, what other handlers exist on parent/child elements. When using DnD libraries, never spread `{...listeners}` on containers that have click handlers. | #5 Event Propagation | New section in `error-handling-performance.md` |
| 8 | **Auth Flow Completeness**: Auth implementations must handle ALL paths: happy path, expired token, missing session, provider-specific quirks, redirect loops (max 2 redirects then show error), graceful degradation when auth provider is unavailable. | #3 Auth/SSO Errors | `reusable-architecture.md` |
| 9 | **Cache Invalidation Rule**: When setting `staleTime` or any cache TTL, document what invalidation scenarios exist. After any mutation that changes server state, verify the cache is invalidated or the query is refetched. | #10 Stale State | `error-handling-performance.md` |
| 10 | **Copy-Paste Verification**: After copying code from another context, review EVERY field/value and verify it makes sense in the new context. Check: default values, field names, identifiers, paths, URLs. | #9 Copy-Paste Errors | `change-discipline.md` |

### MEDIUM PRIORITY — Strengthen Existing Rules

| # | Enhancement | Addresses Pattern | Where |
|---|---|---|---|
| 11 | Add to CSS rules: "When using flex containers, always set `min-h-0` and `overflow-hidden` on intermediate containers. Verify header/body alignment uses the same layout strategy." | #6 CSS/Layout | `error-handling-performance.md` |
| 12 | Add to React rules: "Hooks MUST be at the top of the component, before any early returns or conditional logic. Verify component has required providers in its ancestor tree." | #12 React Hooks | `testing-standards.md` |
| 13 | Add to testing: "After any file reorganization or refactor, run the FULL test suite AND verify all dynamic imports (React.lazy, import()) resolve correctly." | #1 Incomplete | `testing-standards.md` |
| 14 | Add to commenting: "Never include glob patterns, regex, or file paths containing `*/` or `/*` inside JSDoc/docstring comments without escaping." | #15 Comments Breaking Code | `code-commenting-standards.md` |
| 15 | Add to security: "All API error responses in production must use generic messages. Never expose exception details, stack traces, or internal paths to clients." | #14 Security Gaps | `error-handling-performance.md` |

### LOW PRIORITY — Process Improvements

| # | Enhancement | Addresses Pattern |
|---|---|---|
| 16 | Add a "pre-flight checklist" hook that fires before marking a spec task complete — checks for the completeness items in #2 above | #1 Incomplete Implementation |
| 17 | Add rate limit guidance: "Start with generous limits in dev (100+/min), tighten for production. Rate limits should be per-endpoint, not global middleware." | Rate limit iteration saga |
| 18 | Add build verification rule: "After any change to package exports, bin entries, or build config, run `npm pack --dry-run` or equivalent to verify the published artifact is correct." | #8 Platform/Packaging |

---

## Statistics

| Metric | Value |
|---|---|
| Codebases scanned | 13 |
| Documented bugs found | ~120 |
| Fix commits analyzed | 140+ |
| Log files reviewed | 50+ |
| Agent-introduced bug rate | 70-80% |
| Longest fix chain | 7+ commits for one auth issue |
| Most common pattern | Incomplete implementation |
| Most damaging pattern | Iterative debugging spirals |

---

## Codebase Bug Distribution

```
Codebase-01  ████████████████████████████████████████████████████████ 57
Codebase-02  ██████████████████████████████ 30
Codebase-03  ████████████████████████ 24
Codebase-04  ███████ 7
Codebase-05  ███ 3
Codebase-06  ███ 3
Codebase-07  ██ 2
Codebase-08  ██ 2
Codebase-09  █ 1
Codebase-10  █ 1
Codebase-11  ░ 0
Codebase-12  ░ 0
Codebase-13  ░ 0
```
