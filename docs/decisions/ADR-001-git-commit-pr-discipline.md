# ADR-001: Consolidate git/focus steering and add commit-discipline guardrails

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-06-11 |
| **Decision Makers** | Sourjya S. Sen (maintainer), Claude (agent) |

## Context

A deep-research report (`docs/references/agentic-coding-tools-git-commit-and-pr-discipline-research.md`)
surveyed git commit & PR discipline across agentic coding tools (Kiro, Claude Code,
Cursor, Codex, Copilot, Devin) and benchmarked kiro-rails' steering against the
field. It found kiro-rails already ahead on branch-divergence and context-loss
guardrails, but identified six gaps - most importantly the absence of an explicit
*commit-cadence* discipline (defensive checkpoints, "commit every meaningful
checkpoint", never-end-a-session-with-uncommitted-work), which practitioner sources
cite as the single most common missing discipline.

It also recommended a structural change: the two files governing the same behavioral
domain (`git-workflow.md` and `focus-and-branch-discipline.md`) should be one file, so
an agent loading one cannot miss rules in the other; and a short, always-on
"hard stops" file stating the non-negotiables plainly.

## Decision Drivers

- Commit-cadence gaps are the highest-cited cause of lost agent work (context
  compaction erasing uncommitted passing states).
- Two separate always-on files for one domain risk partial loading / missed rules.
- The hard "never" rules were scattered across `change-discipline.md` and
  `git-workflow.md`; no single sharp surface stated them.
- The framework is consumed via installers + a generated `.claude/` bonus layer, so
  any file rename has a manifest/cleanup blast radius that must be handled.

## Considered Options

1. **Keep both files; add rules in place.** Lowest churn, but preserves the
   partial-load risk the research flagged and leaves the domain split.
2. **Merge into one file + add a short hard-stops file + commit-cadence rules.**
   Higher churn (rename ripples through installers, `.claude`, cross-refs) but
   resolves the structural and content gaps together.
3. **Adopt a thin cross-tool `AGENTS.md` bridge** (research Gap 2). Diverges from
   this repo's generated-full-export model; deferred.

## Decision

Chose **Option 2**.

- Merged `git-workflow.md` + `focus-and-branch-discipline.md` →
  **`git-and-focus-discipline.md`**, impact-ordered (branch hygiene → branch types →
  commit discipline → lifecycle → focus/queue → Definition of Done → bug workflow →
  conflict resolution), folding in the new commit-cadence rules: **defensive
  checkpoints**, the **"meaningful checkpoint" definition** (compiles + affected tests
  pass + lint clean), and **never end a session with uncommitted work**.
- Added **`agent-boundaries.md`** (`inclusion: always`): the shortest file in the set,
  stating the hard "never"/"always" rules with `→` pointers to the detailed files.
- Reduced `change-discipline.md` §"Commit Discipline" to a cross-reference (avoids a
  weaker duplicate of the authoritative rules).
- Strengthened `session-isolation.md` with a one-worktree-per-concurrent-session
  preventive-control note.
- Added two hooks: **`commit-checkpoint-on-stop`** (agentStop; warns on uncommitted
  work at the session boundary) and **`variant-search-on-fix-branch`** (userPromptSubmit;
  reminds to search for defect variants while a `fix/` branch is fresh, with a
  commit-count guard to avoid prompt fatigue).
- Added the **`review-commit-pr-discipline`** prompt (→ a `/review-commit-pr-discipline`
  Claude command) operationalizing the rules and a What/Why/Trade-offs PR description.

The drafted changes were independently reviewed by headless `kiro-cli` (read-only),
which returned SHIP-WITH-TWEAKS; its tweaks (README refresh, the change-discipline
reduction, and the variant-search fatigue guard) were folded in before merge.

## Consequences

**Positive**
- One always-on file per domain; no partial-load gap.
- Explicit commit cadence backed by a stop-time hook closes the lost-work failure mode.
- All six research gaps addressed except the deliberately-deferred AGENTS.md bridge.

**Negative / costs**
- File rename rippled through both installers' `MANAGED_FILES`, a `STALE_FILES` entry
  to clean the old files on upgrade, the generated `.claude/` layer, the README, and
  cross-references. All handled and smoke-tested.

**Follow-ups (not in this change)**
- AGENTS.md cross-tool bridge (research Gap 2) - deferred; the generated full-export
  model stands.
- Automated agent PR review pre-open (research §9) - future.

## Cross-references

- Research: `docs/references/agentic-coding-tools-git-commit-and-pr-discipline-research.md`
- Steering: `.kiro/steering/git-and-focus-discipline.md`, `.kiro/steering/agent-boundaries.md`
- Headless review log: `logs/kiro-steering-review.log`
