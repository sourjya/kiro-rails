# Design: Bug Scribe

## Architecture

Two-trigger model: documentation starts at *discovery*, diff capture happens at *commit*.

```
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: DISCOVERY (fileEdit)                                    │
│                                                                   │
│ Developer notices bug → types # bug: CATEGORY — description      │
│ → saves file                                                      │
│         │                                                         │
│         ▼                                                         │
│ ┌─────────────────────────────────────────┐                      │
│ │  .kiro/hooks/bug-scribe-on-fix          │                      │
│ │  trigger: fileEdit on *.{py,ts,js,...}  │                      │
│ │  action: runCommand                      │                      │
│ └────────────────┬────────────────────────┘                      │
│                  │                                                │
│                  ▼                                                │
│ ┌─────────────────────────────────────────┐                      │
│ │  scripts/bug-scribe.sh discover "$FILE" │                      │
│ │                                          │                      │
│ │  1. Grep for marker in file              │                      │
│ │  2. Check near-misses, warn if found     │                      │
│ │  3. Check idempotency (already processed)│                      │
│ │  4. Determine next BUG-### number        │                      │
│ │  5. Extract code context around marker   │                      │
│ │  6. Scaffold bug doc from template       │                      │
│ │  7. Append chokepoint log entry          │                      │
│ │  8. Log what was created                 │                      │
│ │  (NO diff yet — bug just reported)       │                      │
│ └────────────────┬────────────────────────┘                      │
│                  │ creates                                        │
│                  ▼                                                │
│ ┌──────────────────────────────────────┐                         │
│ │  docs/bugs/BUG-###-category.md       │  ← Status: OPEN        │
│ │  docs/engineering/chokepoint-log.md  │                         │
│ └──────────────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘

          ... developer fixes the bug (now or later) ...

┌─────────────────────────────────────────────────────────────────┐
│ PHASE 2: RESOLUTION (beforeCommit)                               │
│                                                                   │
│ Developer stages fix (file still has the marker) → commits       │
│         │                                                         │
│         ▼                                                         │
│ ┌─────────────────────────────────────────┐                      │
│ │  .kiro/hooks/bug-scribe-capture-diff    │                      │
│ │  trigger: beforeCommit                   │                      │
│ │  action: runCommand                      │                      │
│ └────────────────┬────────────────────────┘                      │
│                  │                                                │
│                  ▼                                                │
│ ┌─────────────────────────────────────────┐                      │
│ │  scripts/bug-scribe.sh resolve          │                      │
│ │                                          │                      │
│ │  1. Scan staged files for markers        │                      │
│ │  2. Find the matching BUG-### doc        │                      │
│ │  3. Extract git diff --cached (the fix!) │                      │
│ │  4. Inject diff into existing bug doc    │                      │
│ │  5. Update status: OPEN → IN_PROGRESS    │                      │
│ │  6. Stage the updated bug doc            │                      │
│ └────────────────┬────────────────────────┘                      │
│                  │ updates + stages                               │
│                  ▼                                                │
│ ┌──────────────────────────────────────┐                         │
│ │  docs/bugs/BUG-###-category.md       │  ← Status: IN_PROGRESS │
│ │  (now has the fix diff embedded)     │                         │
│ └──────────────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘

          ... optionally, on next edit of bug doc ...

┌─────────────────────────────────────────────────────────────────┐
│ PHASE 3: PATTERN ANALYSIS (askAgent, optional)                   │
│                                                                   │
│ ┌─────────────────────────────────────────┐                      │
│ │  .kiro/hooks/bug-scribe-pattern-detect  │                      │
│ │  trigger: fileEdit on docs/bugs/BUG-*   │                      │
│ │  action: askAgent                        │                      │
│ └─────────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

### Why two triggers, not one

The marker means "I found a bug" — not "I fixed a bug." These are different moments:

| Moment | What exists | What to capture |
|--------|-------------|-----------------|
| Discovery (fileEdit) | The bug, the context, the category, the developer's description | Bug doc scaffold — everything *except* the fix |
| Resolution (beforeCommit) | The staged fix diff | The diff injected into the existing bug doc |

If we only trigger on `beforeCommit`:
- Developer loses the thought if they don't fix immediately
- Bugs noticed but deferred never get documented
- The "aha" moment description is forgotten by commit time

If we only trigger on `fileEdit`:
- No diff exists yet (the fix hasn't happened)
- The bug doc is incomplete

Both triggers, one script with two subcommands (`discover` and `resolve`), gives us the full lifecycle.

## Key Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Template substitution via `sed` + `awk` | Zero dependencies beyond bash/coreutils; reuses existing template file as single source of truth | Heredoc in script (embeds template, diverges from manual docs); Python script (adds dependency) |
| Two-pass for diff injection | `sed` can't handle multi-line content with special chars; `awk` handles the diff block separately | Python one-liner (cleaner but adds dep); temp file concatenation (fragile) |
| Case-insensitive trigger, strict structure | Reduces friction (don't remember if it's BUG or bug) while keeping parsing reliable | Fully strict (annoying); fully fuzzy (ambiguous parsing) |
| Em-dash as separator | Unambiguous — never appears in category names or typical descriptions; visually distinct from hyphens in kebab-case | Pipe `|` (ugly); double-hyphen `--` (conflicts with CLI flags in comments); colon `:` (already used after BUG) |
| Marker stays in code permanently | Useful context for future readers ("why does this code exist in this form"); grep-able for pattern analysis | Remove after processing (loses context); move to doc only (invisible in code) |
| Idempotency via processed-markers log | Simple append-only file; fast grep check; survives branch switches | Content-hash in bug doc (requires reading all docs); git blame check (slow, fragile) |
| Category list read from chokepoint-log.md | Single source of truth; no separate config to maintain | Hardcoded array (drifts); separate YAML file (over-engineering) |

## File Layout

```
scripts/
└── bug-scribe.sh              # The deterministic shell script (main logic)

.kiro/hooks/
├── bug-scribe-on-fix.kiro.hook           # fileEdit trigger → runCommand
└── bug-scribe-pattern-detect.kiro.hook   # fileEdit trigger → askAgent (optional)

docs/bugs/
├── BUG-000-template.md        # MODIFIED: add {{PLACEHOLDER}} markers
└── .bug-scribe-processed      # Idempotency log (gitignored)

docs/engineering/
└── chokepoint-log.md          # MODIFIED: entries appended by script
```

## Template Modification

Each bug doc is a **self-contained, importable ticket** — everything needed to understand the bug, its fix, and its lessons in one document. Structured for direct import into Tactiq or any ticket system.

### After (with placeholders — the importable unit)

```markdown
# {{BUG_ID}}: {{DESCRIPTION}}

## Metadata

| Field | Value |
|-------|-------|
| **ID** | {{BUG_ID}} |
| **Severity** | {{SEVERITY}} |
| **Status** | {{STATUS}} |
| **Category** | {{CATEGORY}} |
| **File** | `{{FILE}}` |
| **Reported** | {{DATE}} |
| **Fixed** | - |
| **Branch** | `{{BRANCH}}` |
| **Commit** | - |

## Problem

{{DESCRIPTION}}

## Code Context (auto-captured at discovery)

\`\`\`
{{CONTEXT}}
\`\`\`

## Root Cause

<!-- Fill in: why did this happen? What was the incorrect assumption? -->

## Solution

<!-- Auto-filled from commit message at resolution. Manual override OK. -->
{{SOLUTION}}

## Diff (auto-captured at commit)

\`\`\`diff
{{DIFF}}
\`\`\`

## Impact

<!-- What was affected? Users? Data? Other systems? -->

## Regression Tests

| Test | Type | Status |
|------|------|--------|
| `test_{{BUG_ID_LOWER}}_negative` | Reproduces bug (RED) | [ ] Written |
| `test_{{BUG_ID_LOWER}}_positive` | Confirms fix (GREEN) | [ ] Written |

## Variant Search

- [ ] Searched for same pattern at all call sites
- [ ] Found ___ additional instances
- [ ] All variants fixed in same branch

## Lessons / Pattern

<!-- What should the team learn from this? Is this a recurring class? -->
- **Category:** {{CATEGORY}}
- **Recurrence:** (auto-filled by pattern detection if 2+ in same category)
- **Guardrail candidate:** (auto-filled if 3+ — promote to steering rule?)

## Timeline

| Event | Date | Actor |
|-------|------|-------|
| Discovered | {{DATE}} | Bug Scribe (auto) |
| Fix started | - | - |
| Fix committed | - | - |
| Regression tests | - | - |
| Closed | - | - |
```

### Why "importable unit"

Each bug doc should be directly importable as a ticket into Tactiq (or any system) without additional context. The document contains:

- **What went wrong** (Problem + Code Context)
- **Why it went wrong** (Root Cause)
- **What fixed it** (Solution + Diff)
- **What it affected** (Impact)
- **How to prevent recurrence** (Regression Tests + Variant Search + Lessons)
- **Full lifecycle** (Timeline)

A future `bug-scribe.sh import` subcommand could push this directly to Tactiq via MCP:
```bash
scripts/bug-scribe.sh import docs/bugs/BUG-042-type-mismatch.md
# → creates a ticket with title, description, labels, and all fields populated
```

## Idempotency Mechanism

File: `docs/bugs/.bug-scribe-processed` (gitignored)

Format: one line per processed marker

```
<sha256 of FILE:LINE_NUMBER:MARKER_TEXT>
```

On each run:
1. Compute the checksum of the marker line + file path
2. Grep `.bug-scribe-processed` for this checksum
3. If found → exit 0 (already processed)
4. If not found → proceed, append checksum after successful creation

## Category Extraction

The script reads known categories from `docs/engineering/chokepoint-log.md` by grepping for the pattern tags:

```bash
KNOWN_CATS=$(grep -oE '\*\*Pattern:\*\* [A-Z_]+' docs/engineering/chokepoint-log.md \
             | sed 's/\*\*Pattern:\*\* //' | sort -u)
```

Fallback: if chokepoint-log.md doesn't exist or has no entries, accept any category without warning.

## Hook Definitions

### bug-scribe-on-fix.kiro.hook (discovery)

```json
{
  "name": "bug-scribe-on-fix",
  "version": "0.1.0",
  "description": "Scaffolds bug doc + chokepoint entry when a # bug: marker is detected in a saved file",
  "trigger": {
    "type": "fileEdit",
    "filePattern": "**/*.{py,ts,tsx,js,jsx,go,rs,java,css,scss}"
  },
  "action": {
    "type": "runCommand",
    "command": "bash scripts/bug-scribe.sh discover \"${filePath}\""
  }
}
```

### bug-scribe-capture-diff.kiro.hook (resolution)

```json
{
  "name": "bug-scribe-capture-diff",
  "version": "0.1.0",
  "description": "Captures fix diff into existing bug doc when staged files contain a # bug: marker",
  "trigger": {
    "type": "beforeCommit"
  },
  "action": {
    "type": "runCommand",
    "command": "bash scripts/bug-scribe.sh resolve"
  }
}
```

Note: `resolve` subcommand scans all staged files for markers, finds the matching existing bug doc, and injects `git diff --cached`.

### bug-scribe-pattern-detect.kiro.hook

```json
{
  "name": "bug-scribe-pattern-detect",
  "version": "0.1.0",
  "description": "Analyzes bug patterns when a bug doc is created/updated (optional, agent-powered)",
  "trigger": {
    "type": "fileEdit",
    "filePattern": "docs/bugs/BUG-*.md"
  },
  "action": {
    "type": "askAgent",
    "prompt": "A bug doc was just created or updated at ${filePath}. Read it and read docs/engineering/chokepoint-log.md. Count how many entries share the same category as this bug. If 2+ share the category, flag the trend. If 3+, recommend promoting it to a steering rule per the chokepoint promotion policy in .kiro/steering/chokepoint-logging.md."
  }
}
```

## Script Subcommands

The single script `scripts/bug-scribe.sh` has two subcommands:

### `discover` — triggered on fileEdit (bug found)

```bash
scripts/bug-scribe.sh discover "$FILE"
```

1. Grep file for marker (`FIRE_PATTERN`)
2. Check near-misses, warn if found
3. Check idempotency (already processed this marker?)
4. Determine next BUG-### number
5. Extract code context (±5 lines around marker)
6. Scaffold bug doc from template (no diff yet — `{{DIFF}}` section says "Pending fix")
7. Append chokepoint log entry
8. Log what was created

### `resolve` — triggered on beforeCommit (fix committed)

```bash
scripts/bug-scribe.sh resolve
```

1. Scan staged files for markers (`git diff --cached --name-only`)
2. For each marker found, locate the matching `docs/bugs/BUG-###-*.md`
3. Extract the full staged diff: `git diff --cached -- "$FILE"`
4. **Capture the solution:** extract the commit message (passed via `$GIT_COMMIT_MSG` or read from `.git/COMMIT_EDITMSG`) as the "Fix Description"
5. Inject diff into the existing bug doc's `{{DIFF}}` / "Diff" section
6. Inject commit message into the "Fix Description" section
7. Update status: `OPEN` → `IN_PROGRESS`
8. Update "Fixed" date field
9. Stage the updated bug doc

The commit message is the developer's own words describing what they fixed — this becomes the solution narrative in the bug doc automatically. No extra effort.

---

## Multi-Line Injection (used by both subcommands)

The two-pass approach for template substitution:

```bash
# Pass 1: sed handles single-line placeholders
sed -e "s|{{BUG_ID}}|${BUG_ID}|g" \
    -e "s|{{BUG_ID_LOWER}}|${BUG_ID_LOWER}|g" \
    -e "s|{{CATEGORY}}|${CATEGORY}|g" \
    -e "s|{{FILE}}|${FILE}|g" \
    -e "s|{{DATE}}|${DATE}|g" \
    -e "s|{{BRANCH}}|${BRANCH}|g" \
    -e "s|{{DESCRIPTION}}|${DESCRIPTION}|g" \
    -e "s|{{STATUS}}|OPEN|g" \
    -e "s|{{SEVERITY}}|TBD|g" \
    docs/bugs/BUG-000-template.md > "${OUTPUT_FILE}"

# Pass 2: awk injects multi-line content for {{DIFF}} and {{CONTEXT}}
awk -v diff_file="${DIFF_TMPFILE}" -v ctx_file="${CTX_TMPFILE}" '
  /\{\{DIFF\}\}/ { while ((getline line < diff_file) > 0) print line; next }
  /\{\{CONTEXT\}\}/ { while ((getline line < ctx_file) > 0) print line; next }
  { print }
' "${OUTPUT_FILE}" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "${OUTPUT_FILE}"
```

For the `resolve` subcommand, the same awk approach injects the diff and commit message into the existing bug doc (replacing the "Pending fix" placeholder).

```bash
# resolve: inject diff + solution into existing bug doc
COMMIT_MSG=$(cat .git/COMMIT_EDITMSG 2>/dev/null || echo "No commit message captured")
DIFF=$(git diff --cached -- "$FILE")

# Write to temp files (avoids escaping hell)
echo "$DIFF" > "${DIFF_TMPFILE}"
echo "$COMMIT_MSG" > "${MSG_TMPFILE}"

# Replace placeholder sections in the existing bug doc
awk -v diff_file="${DIFF_TMPFILE}" -v msg_file="${MSG_TMPFILE}" '
  /Pending fix/ { while ((getline line < diff_file) > 0) print line; next }
  /<!-- Fill in after fix -->/ { while ((getline line < msg_file) > 0) print line; next }
  { print }
' "${BUG_DOC}" > "${BUG_DOC}.tmp" && mv "${BUG_DOC}.tmp" "${BUG_DOC}"

# Update status and date
sed -i "s|OPEN|IN_PROGRESS|" "${BUG_DOC}"
sed -i "s|**Fixed** \| -|**Fixed** \| ${DATE}|" "${BUG_DOC}"

# Stage the updated doc into the commit
git add "${BUG_DOC}"
```

Temp files are cleaned up on exit via `trap`.

## Dependencies

- **bash 4+** (for `${var,,}` lowercase, associative arrays if needed)
- **sed** (POSIX)
- **awk** (POSIX)
- **git** (for `git diff`, `git branch --show-current`)
- **sha256sum** or **shasum** (for idempotency checksums)
- No Python, no npm, no external packages
