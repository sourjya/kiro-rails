# Proposal: Bug Scribe

## Problem Statement

kiro-rails mandates bug documentation (`BUG-###.md`), regression tests, variant searches, and chokepoint logging. The discipline exists and is enforced by steering files + hooks. However, all of it requires *manual triggering* — the developer must remember to create the file, look up the next number, fill the template, and capture the diff context. This friction means:

1. Bug docs get written after the fact — by then the exact diff context and "aha" moment are forgotten
2. Chokepoint logging starts at attempt #2+ — the first instance of a recurring pattern is never captured
3. The BUG-### file creation ceremony (next number, naming, template) is friction that delays documentation
4. Pattern connections between bugs only surface at sprint retro, not in real-time

## Proposed Solution

A two-layer Kiro hook system ("Bug Scribe") that fires when a developer marks a fix with a `# bug:` comment:

- **Layer 1 (`runCommand`):** Deterministic shell script — zero tokens, instant. Detects the marker, extracts `git diff`, scaffolds the bug doc from the existing template with pre-filled fields, appends to the chokepoint log.
- **Layer 2 (`askAgent`):** Optional agent-powered analysis. Reads the bug doc + chokepoint log, classifies the pattern, flags trends when 2+ bugs share a category, recommends guardrail promotion at 3+.

The developer's workflow becomes: write the fix, add `# bug: CATEGORY — description` as a comment in the code, save. Done. The documentation happens.

## Scope

**In scope:**
- `scripts/bug-scribe.sh` — the deterministic shell script
- `.kiro/hooks/bug-scribe-on-fix.kiro.hook` — fileEdit trigger for source files
- `.kiro/hooks/bug-scribe-pattern-detect.kiro.hook` — optional agent hook for pattern analysis
- Machine-readable placeholders in `docs/bugs/BUG-000-template.md`
- Marker format specification (case-insensitive, cross-language)
- Near-miss detection with helpful warnings

**Out of scope:**
- Auto-generating regression test bodies (TDD mandate already handles the requirement)
- Integration with Tactiq tickets (future enhancement)
- Auto-running variant searches (separate ticket in KRL-18 Hook Automation Sweep)

## Success Criteria

1. Typing `# bug: TYPE_MISMATCH — API returns wrong shape` in any supported source file and saving triggers automatic bug doc creation
2. The generated bug doc contains the correct next BUG-### number, file path, branch, date, and captured diff
3. Near-miss variants (`#BUG:`, `# bug:no space`) produce a helpful warning without firing
4. The chokepoint log gets an entry appended automatically
5. The optional agent hook correctly identifies when 2+ bugs share a category
6. Works across Python, JavaScript, TypeScript, Go, Rust, and Java files

## Risks & Open Questions

- **Risk:** Em-dash (`—`) is not trivially typeable on all keyboards. Mitigation: document that Option+Shift+- (Mac) or AltGr+- (Linux) produces it; or consider accepting `--` as an alternative separator.
- **Risk:** Multi-line diff injection into markdown template requires careful escaping. Mitigation: two-pass approach (sed for single-line, awk/python for diff block).
- **Question:** Should the hook also fire on `fix/` branch detection without a marker? (Deferred — marker-only for v1.)
- **Question:** Should the generated bug doc be auto-staged for commit? (Leaning no — let the developer review it first.)

---

## Design Divergence: Auto-COE → Bug Scribe

Bug Scribe is inspired by [Auto-COE](https://lnkd.in/g296rCEz) but diverges in two significant ways — one from the original, one from convergence with our existing workflow.

### Divergence 1: Discovery-first vs Fix-first

Auto-COE starts from "I just fixed a bug" — the marker goes in alongside the fix, and the hook documents what you did. Bug Scribe starts from "I found a bug" — the marker triggers documentation at *discovery*, and the fix is captured separately at commit time.

| | Auto-COE (original) | Bug Scribe (ours) |
|---|---|---|
| Marker means | "I just fixed this" | "I found this" |
| Trigger | fileEdit (save) | fileEdit (discovery) + beforeCommit (resolution) |
| Diff captured | Immediately (assumes fix is done) | At commit time (when fix is actually complete) |
| "Report only" flow | Not supported | Supported — doc exists in OPEN state until fix lands |
| Solution | Inferred from diff | Explicit from commit message |

This matters because developers don't always fix what they find immediately. A bug noticed during feature work gets filed for later (per our existing branch discipline — "do NOT fix bugs on the current feature branch"). The discovery moment and the fix moment are often separated by hours or days.

### Divergence 2: Convergence with existing kiro-rails bug tracking

kiro-rails already had a complete bug workflow before Auto-COE existed:

- `docs/bugs/BUG-###.md` template with structured fields
- Bug numbering convention and naming rules
- Mandatory regression tests (TDD — RED then GREEN)
- Variant search requirement ("the reported instance is rarely the only one")
- Chokepoint logging with pattern categories and promotion rules
- `fix/bug-###-description` branch convention
- `variant-search-on-fix-branch` hook to remind about pattern search
- `bug-doc-completion-check` hook to verify fields are filled

What we *didn't* have was the automation trigger — all of the above required manual discipline. Auto-COE's key insight was: **a comment marker in the code can be the trigger that makes documentation happen automatically.**

Bug Scribe converges these two systems:

```
Auto-COE's contribution:     # bug: marker → automation trigger → zero-friction docs
kiro-rails' contribution:    Structured template + chokepoint categories + pattern promotion + TDD + variant search
Bug Scribe (the convergence): marker triggers the existing workflow automatically
```

The result is stronger than either alone:
- Auto-COE's deliberately-failing test skeleton → redundant (we already have TDD mandate)
- Auto-COE's pattern tracking → enhanced (we already have chokepoint categories + 3-occurrence promotion rule)
- kiro-rails' manual bug doc creation → eliminated (marker does it)
- kiro-rails' "remember to capture the diff" → eliminated (commit hook does it)
- kiro-rails' chokepoint logging at attempt #2+ → enhanced (now starts at attempt #1)

### Credit

The two-layer deterministic+agent pattern, the "comment marker as automation trigger" concept, and the proof that this can work with zero LLM cost on the primary path all came from Auto-COE. We adapted the idea to fit our existing infrastructure and extended the lifecycle from fix-time to discovery-time. Credit in the README Acknowledgments section.

### Public Context

From our LinkedIn response to the original Auto-COE post (2026-07-18):

> *"Auto-COE is automation, the reflex that captures it at save-time. [kiro-rails is] constitution, the standing rule. Not competitors, two halves: your hook does the capture, the steering ensures nobody, human or agent, ships the fix without it. They'd snap together in minutes, and the pattern-tracking across bug classes is the piece I don't have and now want."*

Bug Scribe is that snap-together: Auto-COE's capture reflex wired into kiro-rails' constitutional enforcement, with the pattern-tracking piece we said we wanted.
