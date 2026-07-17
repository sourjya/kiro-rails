# Hook Automation Sweep: Remind → Act

**Date:** 2026-07-18
**Status:** Idea
**Depends on:** Auto-COE (proof-of-concept for the pattern)
**Scope:** All kiro-rails hooks that currently remind/suggest but could act/scaffold

---

## Problem Statement

kiro-rails has 21 hooks. Most of them follow the "remind" pattern: they detect a condition and tell the agent "hey, you should do X." The agent then has to do X manually. This works, but it's friction — and friction means things get skipped when context is tight or sessions are long.

The Auto-COE idea proved a better pattern: **the hook does X (or scaffolds 90% of X) deterministically via `runCommand`, leaving only judgment calls for `askAgent`.**

This idea is the systematic audit: which of our existing hooks can be upgraded from "remind" to "act"?

---

## The Pattern

```
BEFORE (remind):  hook detects condition → tells agent "you should do X"
AFTER (act):      hook detects condition → does X (or scaffolds X) → tells agent what it did
```

The deterministic layer (`runCommand`) handles anything that's:
- Template-based (file creation with known structure)
- Computable (counting, grepping, diffing)
- Mechanical (file moves, index updates, timestamp injection)

The agent layer (`askAgent`) handles anything that's:
- Judgment-dependent (should we? is this the right category?)
- Content-generative (writing descriptions, analyzing patterns)
- Context-dependent (needs to read surrounding code to decide)

---

## Audit: Current Hooks → Automation Potential

### High potential (could act today)

| Hook | Currently does | Could do instead | Mechanism |
|------|---------------|-----------------|-----------|
| **changelog-maintenance** | Reminds to update changelog | Draft entry from recent commits (`git log --oneline` since last entry) | `runCommand`: `git log` → append to CHANGELOG.md |
| **bug-doc-completion-check** | Checks fields are filled | Pre-fill knowable fields (file, branch, date, diff) at creation time | `runCommand`: `sed` template substitution (Auto-COE pattern) |
| **variant-search-on-fix-branch** | Reminds to search for variants | Actually run the search: `grep -rn` for the pattern, report results | `runCommand`: grep + report; `askAgent`: classify results |
| **adr-trigger-infra-changes** | Asks "should you write an ADR?" | Scaffold `ADR-###.md` with pre-filled context (what file changed, what decision is implied) | `runCommand`: template + next number; `askAgent`: fill decision content |
| **branch-hygiene-check** | Flags merged-but-not-deleted branches | Auto-delete merged branches (with confirmation log) | `runCommand`: `git branch --merged main \| xargs git branch -d` |
| **comment-standards-check** | Verifies docstrings on staged files | Could scaffold missing docstrings (function signature → template) | `runCommand`: detect missing; `askAgent`: generate content |

### Medium potential (partially automatable)

| Hook | Currently does | Could partially automate | Blocker |
|------|---------------|------------------------|---------|
| **changelog-consolidation-reminder** | Warns if 10+ commits since last update | Could draft consolidated entry grouped by type | Needs judgment to group meaningfully |
| **fix-spiral-detector** | Warns if 3+ fix commits | Could auto-create a chokepoint entry with the commit sequence | Needs root-cause analysis (agent) |
| **session-guard-check** | Warns if another session holds the tree | Could auto-stash and report instead of just warning | Risk: might stash work the other session needs |
| **review-suggest** | Suggests which review to run | Could auto-trigger the review if confidence is high enough | Risk: expensive (full review = many tokens) |

### Low potential (correctly remind-only)

| Hook | Why it should stay as "remind" |
|------|-------------------------------|
| **security-tier1-precommit** | Already acts (blocks commit) — not a reminder |
| **focus-guard** | The decision to divert vs file requires user intent — can't be automated |
| **claude-export-freshness** | Regeneration is a command, but deciding *when* is judgment |
| **package-manifest-verify** | Already acts (runs `npm pack --dry-run`) — reports, doesn't just remind |

---

## New Hooks to Create (not upgrades, entirely new)

| Hook | Trigger | Action | Mechanism |
|------|---------|--------|-----------|
| **test-file-scaffold** | New source file created (`*.py`, `*.ts`) | Create matching test file with correct path, imports, class skeleton | `runCommand`: mirror path, generate boilerplate |
| **spec-index-update** | New folder in `.kiro/specs/` | Append entry to `.kiro/specs/README.md` index | `runCommand`: detect new folder, append line |
| **roadmap-link-on-adr** | New `ADR-###.md` created | Append link to `docs/roadmap/roadmap.md` under current milestone | `runCommand`: detect ADR, append to roadmap |
| **import-path-autofix** | `../../` detected in edited file | Rewrite to `@/` alias (TS) or package import (Python) | `runCommand`: deterministic regex transform |
| **chokepoint-auto-promote** | 3+ entries with same category in chokepoint log | Draft steering rule addition + flag for review | `runCommand`: count; `askAgent`: draft the rule |

---

## Implementation Order

1. **Auto-COE** — proves the pattern (deterministic scaffold + optional agent completion)
2. **test-file-scaffold** — lowest risk, highest frequency, purely mechanical
3. **changelog-maintenance upgrade** — high value, git log is deterministic
4. **variant-search execution** — grep is deterministic; classification is agent
5. **adr-trigger upgrade** — moderate complexity, template-based
6. **Sweep the rest** — batch the remaining upgrades in a single sprint

---

## Success Criteria

The sweep is done when:
- Every hook in `.kiro/hooks/` is classified as "acts" or "correctly remind-only" (with justification)
- No hook says "you should do X" when X is mechanically doable
- New hooks from the "entirely new" table are implemented
- Each automated action logs what it did (observability — no silent file creation)

---

## Risk: Over-automation

Not everything should be automated. The "remind" pattern is correct when:
- The action requires user intent (focus-guard: "should I switch tasks?")
- The action is expensive and might be unwanted (full security review)
- The action is irreversible (deleting branches with unmerged work)
- Getting it wrong is worse than not doing it (wrong ADR content misleads)

The rule: **automate the scaffold, not the judgment. If in doubt, scaffold and flag.**

---

## References

- Auto-COE idea doc: `docs/ideas/auto-coe-bug-postmortem-automation.md`
- Kiro hooks docs: https://kiro.dev/docs/hooks/
- Existing hooks: `.kiro/hooks/` (21 hooks)
- Chokepoint promotion rules: `.kiro/steering/chokepoint-logging.md`
