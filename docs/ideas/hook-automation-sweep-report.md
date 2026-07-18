# KRL-18: Hook Automation Sweep — Triangulation Report & Implementation Plan

**Date:** 2026-07-18
**Ticket:** KRL-18
**Status:** Planning

---

## The Triangulation Model

kiro-rails has three enforcement layers. Each operates at a different time and with different strength:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    THE TRIANGULATION                                  │
│                                                                       │
│  STEERING (constitution)     HOOKS (reflex)      PROMPTS (audit)    │
│  ────────────────────────    ─────────────────    ────────────────   │
│  Always loaded in context    Fire automatically   Invoked on demand  │
│  Shapes agent behavior       Detect + act/warn    Deep analysis      │
│  Preventive (design-time)    Reactive (runtime)   Retrospective      │
│                                                                       │
│  "Never do X"                "You just did X"     "Let's review X"  │
│  "Always do Y first"        "Y wasn't done"      "How well was Y    │
│                              "Here, I did Y        done across the   │
│                               for you"             whole project?"   │
└─────────────────────────────────────────────────────────────────────┘
```

**The insight:** These three layers should form *closed loops*, not isolated rules. Every engineering concern should be covered by all three angles:

| Angle | Role | Failure mode if missing |
|-------|------|------------------------|
| Steering | Prevents the mistake from being made | Agent forgets between sessions |
| Hook | Catches the mistake in real-time | Detection without action = ignored |
| Prompt | Audits for systemic drift across the codebase | Point-in-time only, no prevention |

**The sweep's goal:** Close the loops. Where a steering rule exists without a hook, add one. Where a hook reminds but doesn't act, upgrade it. Where a prompt reveals patterns, wire the detection into a hook so it fires automatically.

---

## Current State: Triangulation Gaps

### Fully Triangulated (all 3 layers active) ✅

| Concern | Steering | Hook | Prompt |
|---------|----------|------|--------|
| Security (secrets, auth bypass) | `change-discipline.md` | `security-tier1-precommit` (blocks) | `/review-code-security` |
| Bug documentation | `git-and-focus-discipline.md` | `bug-scribe-on-fix` + `capture-diff` + `pattern-detect` | — |
| Code comments | `code-commenting-standards.md` | `comment-standards-check` (pre-commit) | `/review-code-maintainability` |
| TDD discipline | `testing-standards.md` | — (steering only, no hook) | `/review-test-quality` |
| Branch hygiene | `git-and-focus-discipline.md` | `branch-hygiene-check` (warns) | — |
| Fix spirals | `change-discipline.md` | `fix-spiral-detector` (warns) | — |
| Focus (task thrashing) | `git-and-focus-discipline.md` | `focus-guard` (reminds) | — |
| Session isolation | `session-isolation.md` | `session-guard-check` (warns) | — |

### Partially Triangulated (missing one layer) ⚠️

| Concern | Has Steering | Has Hook | Has Prompt | Gap |
|---------|-------------|----------|------------|-----|
| **Changelog discipline** | `change-discipline.md` | `changelog-maintenance` (reminds) | — | Hook reminds, doesn't act. No audit prompt. |
| **Variant search** | `git-and-focus-discipline.md` | `variant-search-on-fix-branch` (reminds) | — | Hook reminds, doesn't execute the search. |
| **ADR creation** | `documentation-standards.md` | `adr-trigger-infra-changes` (asks agent) | — | Hook uses agent (expensive). No scaffold. |
| **Import paths** | `import-path-rules.md` | — | — | Steering only. No hook to catch `../../`. No prompt. |
| **Test file naming** | `naming-conventions.md` | — | `/review-test-quality` | No hook to scaffold matching test file. |
| **Spec quality** | `documentation-standards.md` | `spec-validation-gate` (validates) | `/review-spec-readiness` | Hook validates but doesn't scaffold missing pieces. |
| **UX patterns** | `frontend-patterns.md` | `ux-preflight-gate` (checks intent) | `/review-ux-live` + `/review-ux-audit` | No hook that catches UX violations in real-time. |
| **API contracts** | `api-contract-discipline.md` | — | `/review-api-contracts` | No hook. Steering + prompt only. |
| **Hardcoded values** | `reusable-architecture.md` | — | `/review-hardcoded-values` | No hook to catch magic numbers on save. |
| **Chokepoint promotion** | `chokepoint-logging.md` | (Bug Scribe logs to it) | — | No hook that auto-promotes at 3+ occurrences. |
| **Dependency hygiene** | `change-discipline.md` | `package-manifest-verify` (acts) | `/review-dependency-risk` | Partially covered — verify on edit but no pre-add audit. |

### Not Triangulated (single layer only) ❌

| Concern | Only layer | Missing |
|---------|-----------|---------|
| **Database conventions** | Steering (`database-conventions.md`) | No hook detects N+1, no prompt audits query patterns |
| **Error handling** | Steering (`error-handling-performance.md`) | No hook catches empty `catch {}`, no prompt |
| **State persistence** | Steering (`reusable-architecture.md`) | No hook verifies persistence strategy |
| **Async discipline** | Steering (`error-handling-performance.md`) | No hook catches fire-and-forget `mutate()` |
| **Observability** | Steering (`error-handling-performance.md`) | No hook, only `/review-observability` prompt |

---

## Implementation Plan: Closing the Loops

### Tier 1: Upgrade Existing Hooks (remind → act)

These hooks already fire. They just need to DO the thing instead of asking.

| # | Hook | Current | Upgrade | Mechanism | Effort |
|---|------|---------|---------|-----------|--------|
| 1 | `changelog-maintenance` | askAgent: "check if changelog updated" | `runCommand`: draft entry from `git log --oneline` since last changelog commit | Shell: `git log`, append to CHANGELOG.md | 1h |
| 2 | `variant-search-on-fix-branch` | runCommand: prints reminder | `runCommand`: actually grep for the pattern + `askAgent`: classify results | Shell: grep + report; agent: evaluate | 1h |
| 3 | `adr-trigger-infra-changes` | askAgent: "should you write an ADR?" | `runCommand`: scaffold `ADR-###.md` from template + `askAgent`: fill content | Shell: template.sh + next number | 1h |
| 4 | `branch-hygiene-check` | runCommand: prints warning | `runCommand`: auto-delete merged branches + log what was deleted | Shell: `git branch --merged | xargs git branch -d` | 30m |
| 5 | `changelog-consolidation-reminder` | runCommand: prints warning | `runCommand`: draft grouped entry from commits + `askAgent`: refine | Shell: `git log --format`, group by prefix | 1h |
| 6 | `fix-spiral-detector` | runCommand: prints warning | `runCommand`: auto-create chokepoint entry with commit sequence | Shell: extract commit messages, append to log | 30m |

### Tier 2: New Hooks (fill the gaps)

These concerns have steering but no hook. Adding one closes the loop.

| # | Hook | Trigger | Action | Triangulates with |
|---|------|---------|--------|-------------------|
| 7 | `test-file-scaffold` | `fileEdited` on new `*.py`/`*.ts` | `runCommand`: create matching test file | `naming-conventions.md` + `/review-test-quality` |
| 8 | `import-path-autofix` | `fileEdited` on `*.ts`/`*.py` | `runCommand`: detect `../../` → rewrite to `@/` or package | `import-path-rules.md` |
| 9 | `chokepoint-auto-promote` | `fileEdited` on `chokepoint-log.md` | `runCommand`: count categories + `askAgent`: draft rule if 3+ | `chokepoint-logging.md` |
| 10 | `hardcoded-value-scan` | `fileEdited` on `*.py`/`*.ts` | `runCommand`: regex for common magic numbers/URLs/UUIDs | `reusable-architecture.md` + `/review-hardcoded-values` |
| 11 | `empty-catch-detector` | `fileEdited` on `*.py`/`*.ts`/`*.js` | `runCommand`: regex for `except:` / `catch {}` / `catch (e) {}` | `error-handling-performance.md` |

### Tier 3: New Prompts (audit → detection pipeline)

Where a prompt finds patterns, wire the detection back into a hook.

| # | Existing Prompt | Pattern It Finds | Hook to Create | Feedback loop |
|---|----------------|-----------------|----------------|---------------|
| 12 | `/review-test-quality` | Files without test coverage | `test-file-scaffold` (Tier 2 #7) | Prompt finds gap → hook prevents it next time |
| 13 | `/review-hardcoded-values` | Magic numbers, inline URLs | `hardcoded-value-scan` (Tier 2 #10) | Prompt finds 20 → hook catches new ones |
| 14 | `/review-observability` | Missing structured logging | Future: `observability-check` hook | Prompt reveals gap → hook enforces on new code |
| 15 | `/review-api-contracts` | Response shape mismatches | Future: `api-shape-verify` hook | Prompt finds drift → hook catches on new endpoints |

### Tier 4: Steering → Hook Extraction (constitution → reflex)

Rules that currently rely entirely on the agent reading and remembering them.

| # | Steering Rule | Could Be a Hook | Detection method |
|---|--------------|-----------------|-----------------|
| 16 | "Never use `datetime.utcnow()`" | `deprecated-pattern-detect` | Regex on save: `/datetime\.utcnow/` |
| 17 | "No `window.alert()` or `window.confirm()`" | Same hook as #16 | Regex: `/window\.(alert|confirm|prompt)/` |
| 18 | "Use `mutateAsync` not `mutate` for dependent ops" | `async-discipline-check` | Regex: detect `mutate(` without `await` before next statement |
| 19 | "Every external call needs a timeout" | `timeout-enforcement` | AST-level (too complex for regex — agent-powered) |

---

## The Complete Triangulation Matrix (Target State)

After the sweep, every engineering concern has coverage at all three angles:

```
                          PREVENT          DETECT           AUDIT
Concern                   (Steering)       (Hook)           (Prompt)
─────────────────────────────────────────────────────────────────────
Security                  ✅ change-disc   ✅ tier1-precommit  ✅ /review-code-security
Bug documentation         ✅ git-focus     ✅ bug-scribe       —
Code comments             ✅ commenting    ✅ comment-check    ✅ /review-maintainability
TDD / test coverage       ✅ testing-std   🆕 test-scaffold    ✅ /review-test-quality
Branch hygiene            ✅ git-focus     🔄 auto-delete      —
Changelog                 ✅ change-disc   🔄 auto-draft       —
Variant search            ✅ git-focus     🔄 auto-execute     —
ADR creation              ✅ doc-standards 🔄 auto-scaffold    —
Import paths              ✅ import-rules  🆕 autofix          —
Hardcoded values          ✅ reusable-arch 🆕 scan             ✅ /review-hardcoded
Empty catch blocks        ✅ error-handle  🆕 detect           —
Chokepoint promotion      ✅ chokepoint    🆕 auto-promote     —
Fix spirals               ✅ change-disc   🔄 auto-log-entry   —
API contracts             ✅ api-contract  —(future)           ✅ /review-api-contracts
Observability             ✅ error-handle  —(future)           ✅ /review-observability
Deprecated patterns       ✅ project-conv  🆕 regex-detect     —

✅ = exists    🔄 = upgrade from remind    🆕 = new    — = not needed or future
```

---

## Implementation Sequence

### Sprint 1: Foundation (Tier 1 upgrades + highest-value Tier 2)

| Order | Item | Type | Effort | Value |
|-------|------|------|--------|-------|
| 1 | `test-file-scaffold` | New hook | 1h | Every new source file gets a test file automatically |
| 2 | `changelog-maintenance` upgrade | Upgrade | 1h | Never forget to update changelog again |
| 3 | `variant-search-on-fix-branch` upgrade | Upgrade | 1h | Actually runs the grep, not just reminds |
| 4 | `branch-hygiene-check` upgrade | Upgrade | 30m | Auto-deletes merged branches |
| 5 | `fix-spiral-detector` upgrade | Upgrade | 30m | Auto-creates chokepoint entry |
| 6 | `adr-trigger-infra-changes` upgrade | Upgrade | 1h | Scaffolds ADR from template |

**Sprint 1 total: ~5h**

### Sprint 2: Detection hooks (Tier 2 new + Tier 4 extractions)

| Order | Item | Type | Effort | Value |
|-------|------|------|--------|-------|
| 7 | `import-path-autofix` | New hook | 1h | Auto-rewrites `../../` to aliases |
| 8 | `chokepoint-auto-promote` | New hook | 1h | Flags patterns at 3+, drafts steering rule |
| 9 | `hardcoded-value-scan` | New hook | 1h | Catches magic numbers/URLs on save |
| 10 | `empty-catch-detector` | New hook | 30m | Catches silent error swallowing |
| 11 | `deprecated-pattern-detect` | New hook | 1h | Catches `utcnow()`, `window.alert()`, etc. |

**Sprint 2 total: ~4.5h**

### Sprint 3: Feedback loops (Tier 3 — prompt findings → hook creation)

| Order | Item | Type | Effort | Value |
|-------|------|------|--------|-------|
| 12 | Run `/review-hardcoded-values` on kiro-rails itself | Audit | 30m | Baseline for hardcoded-value-scan hook thresholds |
| 13 | Run `/review-test-quality` | Audit | 30m | Identify which file patterns need test-scaffold |
| 14 | Wire audit findings into hook configurations | Config | 1h | Prompts feed hooks, not just reports |

**Sprint 3 total: ~2h**

---

## Architecture: How the Layers Interconnect

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                       │
│   USER WRITES CODE                                                   │
│         │                                                             │
│         ▼                                                             │
│   ┌──────────────┐     ┌──────────────────┐                         │
│   │  STEERING    │────→│ Shapes what the   │ (prevention)            │
│   │  (always-on) │     │ agent writes      │                         │
│   └──────────────┘     └──────────────────┘                         │
│         │                                                             │
│         ▼ (file saved)                                                │
│   ┌──────────────┐     ┌──────────────────┐     ┌───────────────┐  │
│   │  HOOKS       │────→│ Detect violation  │────→│ ACT:          │  │
│   │  (fileEdit/  │     │ or scaffold need  │     │ - scaffold    │  │
│   │   commit)    │     │                    │     │ - autofix     │  │
│   └──────────────┘     └──────────────────┘     │ - log         │  │
│         │                                         │ - block       │  │
│         │                                         └───────────────┘  │
│         │                                                ↓            │
│         │                                         ┌───────────────┐  │
│         │                                         │ LEDGER/LOG    │  │
│         │                                         │ (structured)  │  │
│         │                                         └───────┬───────┘  │
│         │                                                 │           │
│         ▼ (sprint end / feature complete)                 │           │
│   ┌──────────────┐     ┌──────────────────┐             │           │
│   │  PROMPTS     │────→│ Audit codebase   │─────────────┘           │
│   │  (on-demand) │     │ for drift        │                         │
│   └──────────────┘     └──────────────────┘                         │
│         │                                                             │
│         ▼ (findings)                                                  │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │  FEEDBACK LOOP: Prompt findings → hook thresholds/patterns   │  │
│   │  Example: /review-hardcoded finds 20 inline URLs             │  │
│   │  → configure hardcoded-value-scan to catch that regex         │  │
│   │  → next time, hook catches it on save, not at sprint end     │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Reusable Infrastructure (already built)

| Component | Used by | Available for |
|-----------|---------|---------------|
| `scripts/lib/template.sh` | Bug Scribe | ADR scaffolding, test-file-scaffold, any template → output |
| `docs/bugs/ledger.json` pattern | Bug Scribe | Could add `docs/engineering/chokepoint-ledger.json` for promotion |
| `render_template KEY=value KEY=@file` | Bug Scribe | All scaffold hooks |
| `detect_function` | Bug Scribe | Could feed into test-file-scaffold (generate test for specific function) |
| Idempotency via checksum | Bug Scribe | Any hook that shouldn't fire twice on same input |
| Near-miss detection pattern | Bug Scribe | Import path violations, deprecated patterns |

---

## Success Metrics

| Metric | Before sweep | After sweep |
|--------|-------------|-------------|
| Hooks that "remind" | 8 | 0 (all upgraded to "act") |
| Hooks that "act" | 16 | 27+ (11 new) |
| Triangulated concerns (3/3 coverage) | 4 | 12+ |
| Single-layer concerns | 5 | 0 (all get at least 2) |
| Concerns with feedback loop (prompt → hook) | 0 | 3+ |

---

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Over-automation annoys developers | Every auto-action logs what it did; each hook has an `enabled: false` off-switch |
| False positive on hardcoded/deprecated detection | Start with high-confidence patterns only; tune from prompt audit findings |
| Auto-deleting branches scares people | Only delete branches confirmed merged into main; log before delete |
| Import autofix breaks code | Only fix `../../` → `@/` where tsconfig paths are configured; skip ambiguous cases |
| Changelog auto-draft is low quality | Draft as a starting point; agent refines; developer reviews before commit |

---

## Next Step

Start Sprint 1, item #1: **`test-file-scaffold`** hook.

Shell script: when a new source file is created, detect the language and path, generate the matching test file at the correct location with correct imports and class/function skeleton.
