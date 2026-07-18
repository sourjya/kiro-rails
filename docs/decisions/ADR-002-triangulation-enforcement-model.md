# ADR-002: Triangulation Enforcement Model — Steering × Hooks × Prompts

**Date:** 2026-07-18
**Status:** Accepted
**Deciders:** Sourjya S. Sen
**Ticket:** KRL-18

---

## Context

kiro-rails encodes engineering discipline across three mechanisms:

1. **Steering files** (22 files, always-on context) — tell the agent *how* to behave
2. **Hooks** (24 automated triggers) — detect conditions and act/warn in real-time
3. **Prompts** (17 review prompts) — deep audits invoked on-demand at checkpoints

These mechanisms grew organically. Bug Scribe (v0.19.0) proved that all three can work together as a closed loop: steering mandates the behavior → hook enforces it automatically → pattern detection flags drift. The question this ADR addresses: **should every engineering concern be covered by all three layers, and if so, which concerns are currently unprotected?**

---

## Decision

**Every engineering concern that kiro-rails enforces MUST be covered by at least two of the three layers (steering + hook minimum). Three-layer coverage (steering + hook + prompt) is the target for any concern that has a codebase-wide drift risk.**

The rationale:
- **Steering alone fails** because the agent may not read/remember the rule in a long session, especially when context is compacted.
- **Hooks alone fail** because they catch symptoms without the agent understanding *why* — the steering gives the reasoning.
- **Prompts alone fail** because they're point-in-time and only catch drift retrospectively, after it accumulates.

The combination creates defense-in-depth:

| Layer | When it fires | Failure mode | Compensated by |
|-------|--------------|--------------|----------------|
| Steering | Every agent turn | Agent forgets/ignores under context pressure | Hook catches the violation anyway |
| Hook | On file save or commit | False negatives (regex misses) | Prompt catches what hooks miss at audit time |
| Prompt | Sprint end / feature complete | Only periodic, drift accumulates between | Hook catches violations in real-time between audits |

---

## Methodology: Concern Classification

Each concern is classified by:

1. **Detection method** — can the violation be detected mechanically (regex, AST, file existence) or does it require judgment?
2. **Action on detection** — can the fix be applied automatically (scaffold, rewrite) or does it need human/agent decision?
3. **Drift risk** — does this concern drift codebase-wide over time, or is it a per-file/per-commit issue?

| Detection × Action | Hook type | Example |
|--------------------|-----------|---------|
| Mechanical detection + mechanical fix | `runCommand` only | Import path rewrite (`../../` → `@/`) |
| Mechanical detection + judgment fix | `runCommand` detect + `askAgent` fix | Chokepoint promotion (count is mechanical, rule drafting needs judgment) |
| Judgment detection + judgment fix | `askAgent` only | ADR trigger (is this change significant?) |
| No real-time detection possible | Prompt only | Observability completeness (requires reading whole service) |

---

## The 20 Concerns: Current Coverage & Gap Analysis

### Tier A: Fully Triangulated (3/3) — no action needed

These are the model. Every other concern should look like these.

| # | Concern | Steering | Hook | Prompt | Why it works |
|---|---------|----------|------|--------|--------------|
| A1 | **Secret/credential exposure** | `change-discipline.md` ("never commit secrets") | `security-tier1-precommit` — blocks the commit | `/review-code-security` — catches what regex missed | Mechanical detection (regex for patterns), blocks action (hard stop), periodic audit catches edge cases |
| A2 | **Code commenting** | `code-commenting-standards.md` (what to document) | `comment-standards-check` — pre-commit validation + fix | `/review-code-maintainability` — audits comment quality | Partially mechanical (detect missing docstrings), agent fills content |
| A3 | **Bug documentation** | `git-and-focus-discipline.md` (bug workflow) | Bug Scribe (3 hooks: discover, capture-diff, pattern-detect) | — (bug doc IS the documentation) | Fully automated lifecycle: marker → doc → diff → pattern |
| A4 | **Spec quality** | `documentation-standards.md` (spec standards) | `spec-validation-gate` — validates completeness | `/review-spec-readiness` — deep hardening audit | Mechanical check (file exists, sections present) + judgment audit |

---

### Tier B: Partially Triangulated (2/3) — hook upgrade or addition needed

These have steering + either a weak hook (reminds only) or a prompt but no hook.

| # | Concern | Has | Missing | Gap analysis | Proposed fix |
|---|---------|-----|---------|--------------|-------------|
| B1 | **Changelog discipline** | Steering: `change-discipline.md`<br>Hook: `changelog-maintenance` (asks agent) | Hook that ACTS (not asks) | Current hook uses `askAgent` for a task that's 80% mechanical: `git log --oneline` since last edit produces the draft. Agent should refine, not produce from scratch. | Upgrade to `runCommand` draft + `askAgent` refine |
| B2 | **Variant search execution** | Steering: `git-and-focus-discipline.md`<br>Hook: `variant-search-on-fix-branch` (prints reminder) | Hook that EXECUTES the search | Hook says "remember to search." It should grep for the pattern, report findings, and THEN ask the agent to evaluate. The grep is free. | Upgrade: `runCommand` grep → report → `askAgent` classify |
| B3 | **ADR scaffolding** | Steering: `documentation-standards.md`<br>Hook: `adr-trigger-infra-changes` (asks agent) | Deterministic scaffold before agent judgment | Hook asks "should you write an ADR?" using agent tokens. The detection (infra file changed) is already done by the trigger. Should scaffold the template first, THEN ask if it's warranted. | Upgrade: `runCommand` scaffold → `askAgent` decide keep/delete |
| B4 | **Branch hygiene** | Steering: `git-and-focus-discipline.md`<br>Hook: `branch-hygiene-check` (prints warning) | Hook that ACTS (deletes merged branches) | Merged branches are definitionally safe to delete (main has their content). Warning → action. | Upgrade: `runCommand` auto-delete + log |
| B5 | **Fix spiral logging** | Steering: `change-discipline.md`<br>Hook: `fix-spiral-detector` (prints warning) | Hook that LOGS to chokepoint automatically | If 3+ fix commits detected, that IS a chokepoint by definition. Should log it, not just warn. | Upgrade: `runCommand` append to chokepoint-log |
| B6 | **Changelog consolidation** | Steering: `change-discipline.md`<br>Hook: `changelog-consolidation-reminder` (prints warning) | Hook that DRAFTS the consolidation | 10+ commits behind = mechanical: `git log --oneline` grouped by conventional-commit type. | Upgrade: `runCommand` draft grouped entry |
| B7 | **Test file naming** | Steering: `naming-conventions.md`<br>Prompt: `/review-test-quality` | Hook that scaffolds matching test file on new source file | Purely mechanical: source path → test path (mirror). Zero judgment. | New: `test-file-scaffold` hook |
| B8 | **Import path rules** | Steering: `import-path-rules.md` | Hook + prompt both missing | `../../` is detectable by regex. Rewrite to `@/` is deterministic for TS. Python package imports need more care. | New: `import-path-autofix` hook (TS confident, Python warn-only) |
| B9 | **Hardcoded values** | Steering: `reusable-architecture.md`<br>Prompt: `/review-hardcoded-values` | Hook that catches on save | Common patterns (UUIDs, URLs, port numbers, IP addresses) are regex-detectable. | New: `hardcoded-value-scan` hook |
| B10 | **Chokepoint promotion** | Steering: `chokepoint-logging.md` ("promote at 3+") | Hook that auto-counts and flags | Category count is mechanical (`grep -c`). Drafting the rule needs judgment. | New: `chokepoint-auto-promote` (runCommand count + askAgent draft) |
| B11 | **UX violations** | Steering: `frontend-patterns.md`<br>Hook: `ux-preflight-gate` (checks intent exists)<br>Prompt: `/review-ux-live` + `/review-ux-audit` | Hook that catches violations in real-time | Some violations are regex-detectable: `window.alert`, `justify-between` on section actions. Others need visual review (prompt territory). | New: `ux-violation-detect` for the mechanical subset |

---

### Tier C: Single Layer Only (1/3) — needs both hook and prompt

These rely entirely on the agent reading the steering file and remembering. No safety net.

| # | Concern | Only has | Why it's dangerous | Proposed fix |
|---|---------|----------|-------------------|-------------|
| C1 | **Empty error handling** | Steering: `error-handling-performance.md` ("never silently ignore errors") | Empty `except:` / `catch {}` blocks are the #1 source of invisible bugs. Agent may write them under time pressure and steering won't stop it. | New hook: `empty-catch-detector` — regex scan on save. Zero false positives (an empty catch is always wrong). |
| C2 | **Deprecated patterns** | Steering: `project-conventions.md` + `frontend-patterns.md` (`datetime.utcnow()`, `window.alert()`) | These are explicitly banned but nothing catches them. Agent may generate them from training data. | New hook: `deprecated-pattern-detect` — configurable regex list, warns on save. |
| C3 | **Database conventions** | Steering: `database-conventions.md` (N+1, timeouts, parameterized queries) | N+1 queries and missing timeouts aren't detectable by regex. Need AST or runtime analysis. | Future (complex): `/review-database-patterns` prompt for now. Hook when AST tooling exists. |
| C4 | **Async discipline** | Steering: `error-handling-performance.md` (`mutateAsync` not `mutate` for dependent ops) | `mutate(` without `await` before the next dependent call is a race condition. Partially detectable. | New hook (partial): detect `mutate(` in `.tsx` files and warn. Full detection needs data-flow analysis. |
| C5 | **State persistence strategy** | Steering: `reusable-architecture.md` ("every piece of state must have a persistence strategy") | No way to detect "ephemeral state that should persist" mechanically — requires understanding intent. | Stays steering-only. Add to `/review-frontend-performance` prompt checklist. |

---

## Alternatives Considered

| Alternative | Why rejected |
|-------------|-------------|
| **All concerns get all 3 layers** | Some (C3, C5) genuinely can't be detected mechanically. Forcing a hook would mean false positives. |
| **Hooks only (drop steering)** | Hooks catch violations but don't teach WHY. Agent needs the reasoning to avoid the pattern in the first place. |
| **Prompts only (drop hooks)** | Prompts are periodic. A bug introduced on Monday isn't caught until Friday's sprint review. Unacceptable latency. |
| **Single mega-hook that checks everything** | Violates single-responsibility. Hard to disable one check without disabling all. Each concern = its own hook. |

---

## Consequences

### Positive
- No engineering concern silently degrades between sprint reviews
- Agent gets caught by hook even when context pressure causes it to forget steering rules
- Prompts become lighter (less to find, because hooks already caught the obvious)
- Feedback loop: prompt findings tune hook patterns over time

### Negative
- 11 new or upgraded hooks to maintain
- Risk of "hook fatigue" if too many fire on every save (mitigated: only warn/act when violation detected, silent otherwise)
- Some hooks (hardcoded-value-scan) will need threshold tuning per project

### Neutral
- Hook count rises from 24 to ~35
- Each hook is independently disablable (`enabled: false`)
- All new hooks follow the Bug Scribe pattern: `runCommand` for detection, `askAgent` only for judgment

---

## Implementation

See: `docs/ideas/hook-automation-sweep-report.md` for full implementation plan (3 sprints).

Sub-tickets below track each individual concern.

---

## Cross-references

- KRL-18: Hook Automation Sweep (parent ticket)
- `docs/ideas/hook-automation-sweep-report.md`: implementation plan
- `docs/ideas/hook-automation-sweep-remind-to-act.md`: original idea doc
- ADR-001: Git Commit/PR Discipline (related — that ADR drove `branch-hygiene-check`)
