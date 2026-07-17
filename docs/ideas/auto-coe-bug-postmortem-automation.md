# Bug Scribe: Automated Bug Documentation & Pattern Tracking

**Date:** 2026-07-18
**Status:** Implemented (spec: `.kiro/specs/bug-scribe/`)
**Inspiration:** [Auto-COE](https://lnkd.in/g296rCEz) — proved the two-layer deterministic+agent pattern for bug automation. Credit in README.
**Relevance:** Directly implementable with the existing kiro-rails hook + steering infrastructure

---

## Problem Statement

kiro-rails already mandates bug docs, TDD regression tests, variant searches, and chokepoint logging. The discipline exists. What's missing is **friction reduction at the moment of the fix:**

- **Bug docs get written after the fact** — by then you've forgotten the exact diff context, the surrounding code state, and the "aha" moment of the root cause
- **Chokepoint logging requires attempt #2+** — so the first instance of a pattern is never logged, and you only start tracking after you've already been bitten twice
- **The BUG-### file creation is manual** — remembering to check the next number, create the file, fill the template, name it correctly... friction that makes developers delay it
- **No one connects two bugs as the same pattern until sprint retro** — by which time the third instance has already shipped

The discipline is there. The automation to make it *frictionless* is not.

---

## Proposed Solution: Bug Scribe Hook

A Kiro hook that fires when a bug fix is saved, automatically:

1. **Drafts the postmortem** — what happened + the exact diff that fixed it
2. **Generates a regression test skeleton** that FAILS until completed (can't be silently skipped)
3. **Tracks recurring bug patterns** across the codebase, flagging trends unprompted

### Key Design Insight

The original implementation splits into two layers, mapped to Kiro's two hook action types:

| Layer | Kiro action type | Mechanism | Cost | What it produces |
|-------|-----------------|-----------|------|------------------|
| Hook 1 | **`runCommand`** | Deterministic shell script | Zero credits, instant, identical every time | Bug doc scaffold (with diff context), deliberately-failing test skeleton, chokepoint log entry |
| Hook 2 | **`askAgent`** | Prompt passed to the agent (LLM) | Token cost | Completed test body, pattern classification, trend flagging, guardrail promotion |

**Critical constraint:** `runCommand` can create files (including test files) but cannot write *meaningful* test logic — that requires code understanding. What it CAN do is produce a test skeleton with `assert False, "INCOMPLETE: ..."` that's already in the test suite and already failing. The forcing function is the file's existence, not its content.

**The `askAgent` hook** passes a predetermined prompt to the agent, which then has full tool access and can read the bug doc + diff, write the actual test body, analyze patterns, etc. This is optional — the deterministic layer is useful on its own as a forcing function.

**User choice:**
- Hook 1 only (free, instant) → developer completes tests manually, but the scaffolding and the red test force the issue
- Hook 1 + Hook 2 (token cost) → agent completes the test body and does pattern analysis automatically

---

## How It Maps to kiro-rails

### Already have (just need wiring)

| Existing infrastructure | Role in Bug Scribe |
|------------------------|------------------|
| `.kiro/hooks/` system | Trigger mechanism (file edit events) |
| `docs/bugs/BUG-###-*.md` template | Output format for postmortems |
| `docs/engineering/chokepoint-log.md` | Pattern tracking destination |
| `git-and-focus-discipline.md` variant search | Already mandates "search for same bug class" |
| `testing-standards.md` TDD mandate | Already requires regression tests for bugs |
| `change-discipline.md` chokepoint logging | Already requires logging on attempt #2+ |

### Need to build

| Component | Description |
|-----------|-------------|
| **Marker convention** | Standard comment format: `# BUG: <category> — <description>` or `// BUG: ...` |
| **Detection hook** (deterministic) | Shell script that detects BUG markers in edited files, extracts the surrounding diff, scaffolds the bug doc + test skeleton |
| **Pattern analysis hook** (agent-powered, optional) | Reads `chokepoint-log.md` + recent bug docs, classifies the pattern, flags trends when 2+ bugs share a category |
| **Test skeleton generator** | Language-aware template that produces a deliberately-failing test (`assert False, "TODO: complete regression test for BUG-###"`) |
| **Cross-language marker detection** | Regex that works across Python (`# BUG:`), JS/TS (`// BUG:`), Go (`// BUG:`), Rust (`// BUG:`), Java (`// BUG:`) |

---

## Implementation Sketch

### Hook 1: `bug-scribe-on-fix` (deterministic, zero-cost)

**Trigger:** `fileEdit` on source files (`*.py`, `*.ts`, `*.js`, `*.go`, `*.rs`, `*.java`)
**Condition:** File contains a `BUG:` marker comment that wasn't there before (or is on a `fix/` branch)

**Actions (shell script):**

```bash
#!/usr/bin/env bash
# scripts/bug-scribe.sh — deterministic, no LLM

set -euo pipefail

FILE="$1"
BUG_MARKER=$(grep -n '# BUG:\|// BUG:' "$FILE" | head -1)

if [ -z "$BUG_MARKER" ]; then
  exit 0  # No marker, nothing to do
fi

# Extract category and description from marker
CATEGORY=$(echo "$BUG_MARKER" | sed -E 's/.*BUG: ([^ —]+).*/\1/')
DESCRIPTION=$(echo "$BUG_MARKER" | sed -E 's/.*BUG: [^ —]+ — (.*)/\1/')

# Get next bug number
NEXT_NUM=$(ls docs/bugs/BUG-*.md 2>/dev/null | wc -l)
NEXT_NUM=$((NEXT_NUM + 1))
BUG_ID=$(printf "BUG-%03d" $NEXT_NUM)

# Extract the diff context (what changed around the marker)
LINE_NUM=$(echo "$BUG_MARKER" | cut -d: -f1)
CONTEXT=$(sed -n "$((LINE_NUM-5)),$((LINE_NUM+5))p" "$FILE")

# Scaffold bug doc
cat > "docs/bugs/${BUG_ID}-${CATEGORY}.md" << EOF
# ${BUG_ID}: ${DESCRIPTION}

| Field | Value |
|-------|-------|
| ID | ${BUG_ID} |
| Severity | TBD |
| Status | IN_PROGRESS |
| Category | ${CATEGORY} |
| File | ${FILE} |
| Date | $(date +%Y-%m-%d) |
| Branch | $(git branch --show-current) |

## What Happened

<!-- Auto-generated from BUG marker. Fill in context. -->

## Fix Context (auto-extracted)

\`\`\`
${CONTEXT}
\`\`\`

## Diff

\`\`\`diff
$(git diff -- "$FILE" 2>/dev/null || echo "No staged diff yet")
\`\`\`

## Root Cause

<!-- Fill in: why did this happen? -->

## Regression Test

- [ ] Test written: \`tests/unit/test_${BUG_ID,,}.py\` (or .test.ts)
- [ ] Test fails without fix (RED confirmed)
- [ ] Test passes with fix (GREEN confirmed)

## Variant Search

- [ ] Searched for same pattern at all call sites
- [ ] Found ___ additional instances
EOF

# Scaffold failing regression test
if [[ "$FILE" == *.py ]]; then
  TEST_FILE="tests/unit/test_bug_$(printf '%03d' $NEXT_NUM)_${CATEGORY}.py"
  cat > "$TEST_FILE" << EOF
"""
Regression test for ${BUG_ID}: ${DESCRIPTION}

This test was auto-generated by Auto-COE. It deliberately FAILS
until you complete the implementation. This ensures the regression
test cannot be silently skipped.
"""
import pytest


class TestBug${NEXT_NUM}Regression:
    """Regression tests for ${BUG_ID} — ${CATEGORY}."""

    def test_bug_${NEXT_NUM}_negative_case(self):
        """Reproduces the original bug — must FAIL on unfixed code."""
        # TODO: Write the reproduction case
        assert False, "INCOMPLETE: Implement regression test for ${BUG_ID}"

    def test_bug_${NEXT_NUM}_positive_case(self):
        """Confirms the fix works — must PASS after fix."""
        # TODO: Write the positive verification
        assert False, "INCOMPLETE: Implement positive test for ${BUG_ID}"
EOF
fi

echo "Bug Scribe: Created ${BUG_ID} doc + regression test skeleton"
```

### Hook 2: `bug-scribe-pattern-detect` (agent-powered, optional)

**Trigger:** `fileEdit` on `docs/bugs/BUG-*.md` (fires after the doc is created/filled)
**Condition:** 2+ bug docs share a category tag

**Action:** `askAgent` — analyze recent bug docs + chokepoint log, flag if a pattern is emerging, suggest a steering rule or guardrail promotion.

---

## Pattern Tracking Integration

The chokepoint log (`docs/engineering/chokepoint-log.md`) already has categories:

```
ROUTE_ORDERING, CSS_OVERSIGHT, LAYOUT_OVERFLOW, QUERY_INVALIDATION,
TYPE_MISMATCH, IMPORT_ERROR, DEPLOY_REGRESSION, STATE_SYNC, RACE_CONDITION
```

Auto-COE's `BUG:` marker categories should use the **same taxonomy**. When 3+ bugs share a category, the existing chokepoint promotion rule already fires: "promote to steering rules."

Auto-COE just makes the *logging* automatic instead of relying on developer discipline.

---

## Marker Format — DECIDED

### Canonical format

```
# bug: CATEGORY — description
// bug: CATEGORY — description
/* bug: CATEGORY — description */
```

### Case sensitivity rules

| Part | Case | Normalized to |
|------|------|---------------|
| Trigger word (`bug`) | **Case-insensitive** — `BUG`, `bug`, `Bug` all work | Irrelevant (just a trigger) |
| Category | **Case-insensitive** — `type_mismatch`, `TYPE_MISMATCH`, `Type_Mismatch` | Uppercased by script → `TYPE_MISMATCH` |
| Description | Freeform | As-written |

### Detection regex (two-pass)

```bash
# Pass 1: Structural match (fires automation)
# Case-insensitive on trigger + category, strict on structure
FIRE_PATTERN='(#|//)[[:space:]]+[Bb][Uu][Gg]:[[:space:]]+([A-Za-z_]+)[[:space:]]+—[[:space:]]+(.+)$'

# Pass 2: Near-miss detection (warns but doesn't fire)
NEARMISS_PATTERN='(#|//)\s*[Bb][Uu][Gg]\s*:'
```

### What fires vs what warns

| Input | Result |
|-------|--------|
| `# BUG: TYPE_MISMATCH — wrong shape` | ✅ Fires, category = TYPE_MISMATCH |
| `# bug: type_mismatch — wrong shape` | ✅ Fires, category = TYPE_MISMATCH |
| `// Bug: Race_Condition — timing issue` | ✅ Fires, category = RACE_CONDITION |
| `# bug: new_thing — something novel` | ✅ Fires + warns "unknown category" |
| `#BUG: no space after hash` | ⚠️ Near-miss warning, doesn't fire |
| `# BUG:no space after colon` | ⚠️ Near-miss warning, doesn't fire |
| `# BUG: stuff without em-dash` | ⚠️ Near-miss (no `—` separator) |
| `# TODO: fix this bug later` | ❌ Ignored entirely |

### Structural requirements (strict)

- Space after comment prefix (`#` or `//`)
- Space after colon
- Em-dash (`—`) as separator between category and description (not hyphen `-`)
- Category must be a single word (letters + underscores only)

### Category validation

Known categories from `chokepoint-logging.md`:
```
ROUTE_ORDERING | CSS_OVERSIGHT | LAYOUT_OVERFLOW | QUERY_INVALIDATION |
TYPE_MISMATCH | IMPORT_ERROR | DEPLOY_REGRESSION | TOOL_MISUSE |
STATE_SYNC | RACE_CONDITION
```

Unknown category → still fires (might be a new pattern) but logs: `"Bug Scribe: Unknown category 'FOOBAR' — add to chokepoint-logging.md taxonomy if recurring."`

### Marker lifecycle

The `# bug:` comment **stays in the code permanently** — it's useful context for future readers, like a `# NOTE:` comment. It documents *why* this code exists in this form.

---

## Language Support

The marker format is language-agnostic by design:

| Language | Marker format |
|----------|--------------|
| Python | `# bug: CATEGORY — description` |
| JavaScript/TypeScript | `// bug: CATEGORY — description` |
| Go | `// bug: CATEGORY — description` |
| Rust | `// bug: CATEGORY — description` |
| Java | `// bug: CATEGORY — description` |
| CSS/SCSS | `/* bug: CATEGORY — description */` |

---

## What This Actually Adds (vs Current kiro-rails)

The TDD mandate, regression test requirement, and variant search are **already enforced**. Bug Scribe doesn't add discipline — it removes friction from the discipline we already have.

| Current (manual, discipline-dependent) | With Bug Scribe (automated, zero-friction) |
|----------------------------------------|------------------------------------------|
| Developer manually creates `BUG-###.md`, looks up next number, fills template | Hook creates it the instant you type `# BUG:` in your fix |
| Diff context reconstructed later from `git log` | Diff captured at fix-time, embedded in the doc automatically |
| Chokepoint logging starts at attempt #2+ | Pattern tracking starts at attempt #1 via the marker |
| Pattern connections discovered at sprint retro (if at all) | Agent flags "3rd TYPE_MISMATCH this week" in real-time |
| Bug doc and fix are disconnected artifacts | Bug doc contains the exact code context + diff from the moment of the fix |
| Variant search is a reminder ("did you check?") | Could be automated: grep for same pattern across codebase |

**What it does NOT add** (already handled by kiro-rails):
- ~~Failing test skeletons~~ → TDD mandate already requires RED-first
- ~~Regression test enforcement~~ → bug workflow already mandates it
- ~~"You should document bugs"~~ → bug doc template + hook already exists

---

## Documentation Mechanism

**Question: How does the shell script (`runCommand`) actually produce the bug doc?**

Options:

| Mechanism | Pros | Cons |
|-----------|------|------|
| **`cat > file << EOF`** (heredoc in bash) | Zero deps, works everywhere, deterministic | Escaping issues with diffs containing `$`, backticks; template embedded in script |
| **`sed` / `envsubst` on a template file** | Template is a separate, editable `.md` file; script just fills variables | Needs the template to ship with kiro-rails; delimiter choice matters |
| **`scripts/auto-coe.sh` reads `docs/bugs/BUG-000-template.md` and substitutes** | Reuses existing template; single source of truth for bug doc format | Template syntax needs to be machine-parseable (e.g., `{{CATEGORY}}` placeholders) |

**Recommendation: Template-based substitution using the existing `BUG-000-template.md`.**

The template already exists. Add machine-readable placeholders alongside the human instructions:

```markdown
# {{BUG_ID}}: {{DESCRIPTION}}

| Field | Value |
|-------|-------|
| ID | {{BUG_ID}} |
| Severity | {{SEVERITY}} |
| Status | IN_PROGRESS |
| Category | {{CATEGORY}} |
| File | {{FILE}} |
| Date | {{DATE}} |
| Branch | {{BRANCH}} |

## What Happened

{{CONTEXT}}

## Diff (auto-captured)

\`\`\`diff
{{DIFF}}
\`\`\`

## Root Cause

<!-- Fill in -->

## Fix Description

<!-- Fill in -->

## Regression Tests

- [ ] Negative test (RED): reproduces the bug
- [ ] Positive test (GREEN): confirms the fix

## Variant Search

- [ ] Searched for same pattern at all call sites
- [ ] Found ___ additional instances
```

The shell script does:
```bash
sed -e "s|{{BUG_ID}}|$BUG_ID|g" \
    -e "s|{{CATEGORY}}|$CATEGORY|g" \
    -e "s|{{FILE}}|$FILE|g" \
    -e "s|{{DATE}}|$(date +%Y-%m-%d)|g" \
    -e "s|{{BRANCH}}|$(git branch --show-current)|g" \
    -e "s|{{DESCRIPTION}}|$DESCRIPTION|g" \
    docs/bugs/BUG-000-template.md > "docs/bugs/${BUG_ID}-${SLUG}.md"

# Inject diff (multi-line, can't sed it)
DIFF=$(git diff -- "$FILE" 2>/dev/null)
# Use awk or python one-liner to replace {{DIFF}} block
```

This keeps the template human-editable, the script simple, and the output format consistent with manually-created bug docs.

---

## Broader Automation Opportunities (Post-Implementation Review)

Once Auto-COE is built, audit all existing kiro-rails workflows for the same pattern: **things that are currently "discipline + reminder" that could be "automatic + zero-friction."**

Areas to investigate:

| Current workflow | Currently triggered by | Could be automated how |
|-----------------|----------------------|------------------------|
| **ADR creation** | `adr-trigger-infra-changes` hook *suggests* an ADR | Could scaffold `ADR-###.md` with pre-filled context (what file changed, what infra was touched) |
| **Changelog entry** | `changelog-maintenance` hook *reminds* to update | Could draft the entry from commit messages since last changelog update |
| **Spec index update** | Manual after creating a spec | `runCommand` could append to `.kiro/specs/README.md` when a new spec folder is detected |
| **Roadmap linking** | Manual — "link this ADR/spec to roadmap" | Could auto-append to roadmap when an ADR or spec is created with a milestone tag |
| **Variant search execution** | `variant-search-on-fix-branch` hook *reminds* | `askAgent` could actually *run* the search and report results, not just remind |
| **Chokepoint promotion** | Manual at "3+ occurrences" | `runCommand` could count occurrences; `askAgent` fires when threshold hit to draft the steering rule |
| **Bug doc completion check** | Hook checks fields are filled | Could pre-fill more fields deterministically (file, branch, date, diff are all knowable) |
| **Branch collision detection** | `branch-check.sh` run manually or via hook reminder | Could auto-run on branch creation and *block* (not just warn) if collision detected |
| **Test file scaffolding** | Manual — developer creates test file | On new source file creation, could scaffold matching test file with correct path + imports |
| **Import path violation fix** | Lint catches `../../` | Could auto-rewrite to `@/` alias (deterministic transform, no LLM needed) |

**The pattern:** anywhere a hook currently says "hey, you should do X" → ask whether the hook could just *do* X (or scaffold 90% of X) via `runCommand`, leaving only judgment calls for `askAgent`.

This is a separate idea doc / spec once Auto-COE proves the pattern works.

1. **Marker lifecycle** — should the `# BUG:` comment stay in the code permanently (as documentation) or be removed after the bug doc is complete? Leaning: keep it, like a `# NOTE:` — it's useful context for future readers.

2. **Existing `fix/` branch convention** — should the hook also fire when you're on a `fix/bug-###-*` branch without a marker? Could detect branch name and scaffold even without the comment.

3. **Test skeleton language detection** — the shell script needs to pick the right test framework. Could read from `user-project-overrides.md` or detect from existing test files.

4. **Integration with Tactiq** — should Auto-COE also create/update a ticket? Or is the bug doc sufficient?

5. **Git hook vs Kiro hook** — the deterministic part could also be a git pre-commit hook for non-Kiro users. Worth shipping both?

---

## Priority & Next Steps

- **Priority:** Medium-high — this fills a real gap between "policy says do it" and "it actually happens"
- **Effort:** ~2-3 hours for the deterministic hook + test skeleton; another 2-3 for the pattern detection agent hook
- **Dependencies:** None — can be built on current kiro-rails infrastructure
- **Spec candidate:** Yes — promote to `.kiro/specs/auto-coe/` when ready to build

---

## References

- **Inspiration:** [Auto-COE](https://lnkd.in/g296rCEz) by LinkedIn community — proved the two-layer deterministic+agent pattern for automated bug documentation. The "deterministic shell, not an LLM call" insight directly shaped Bug Scribe's architecture. Credit in kiro-rails README Acknowledgments.
- kiro-rails chokepoint logging: `.kiro/steering/chokepoint-logging.md`
- kiro-rails bug workflow: `.kiro/steering/git-and-focus-discipline.md` (Part 7)
- kiro-rails bug doc template: `docs/bugs/BUG-000-template.md`
- Kiro hooks documentation: https://kiro.dev/docs/hooks/
