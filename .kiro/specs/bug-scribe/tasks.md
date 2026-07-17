# Tasks: Bug Scribe

## Overview

Implement the Bug Scribe hook system: a deterministic shell script that scaffolds bug documentation on commit, plus an optional agent-powered pattern detector.

**Architecture References:**
- Design: `.kiro/specs/bug-scribe/design.md`
- Existing bug template: `docs/bugs/BUG-000-template.md`
- Chokepoint log: `docs/engineering/chokepoint-log.md`

**Key Principles:**
- Zero external dependencies (bash + coreutils + git only)
- Template-based substitution (single source of truth for bug doc format)
- Trigger on `beforeCommit` (captures the full fix diff, not a partial state)
- Case-insensitive matching, strict structure

**Development Approach - TDD MANDATORY:**
- RED → GREEN → REFACTOR for the shell script (test with fixture files)
- Test each detection case independently before combining

## Tasks

### Phase 1: Template + Infrastructure

#### Step 1: Create Importable Bug Doc Template

- [ ] 1.1 Rewrite `docs/bugs/BUG-000-template.md` as the importable ticket template
  - Self-contained unit: Metadata, Problem, Context, Root Cause, Solution, Diff, Impact, Regression Tests, Variant Search, Lessons/Pattern, Timeline
  - All `{{PLACEHOLDER}}` markers for machine substitution
  - Template remains usable for manual creation (placeholders are self-documenting)
  - _Requirements: REQ-2_

- [ ] 1.2 Create `.gitignore` entry for `docs/bugs/.bug-scribe-processed`
  - Append to project `.gitignore`
  - _Requirements: REQ-7_

- [ ] 1.3 Create `docs/bugs/.bug-scribe-processed` with header comment explaining format
  - Format: one SHA-256 checksum per line
  - _Requirements: REQ-7_

#### Checkpoint: Phase 1 Complete
- [ ] Template is a complete importable unit
- [ ] `.gitignore` updated
- [ ] Changes committed

---

### Phase 2: Core Shell Script — Detection Logic

#### Step 2: Marker Detection (the regex engine)

**RED Phase:**
- [ ] 2.1 Create test fixtures: `tests/fixtures/bug-scribe/`
  - `valid-python.py` — contains `# bug: TYPE_MISMATCH — wrong shape`
  - `valid-js.ts` — contains `// BUG: RACE_CONDITION — async timing`
  - `valid-mixed-case.py` — contains `# Bug: State_Sync — drift`
  - `nearmiss-no-space.py` — contains `#BUG: TYPE_MISMATCH — stuff`
  - `nearmiss-no-colon-space.py` — contains `# BUG:stuff`
  - `nearmiss-hyphen.py` — contains `# BUG: TYPE_MISMATCH - wrong (hyphen not em-dash)`
  - `no-marker.py` — normal code, no marker
  - `multiple-markers.py` — two markers in one file
  - File: `tests/fixtures/bug-scribe/`
  - _Requirements: REQ-1, REQ-5_

**GREEN Phase:**
- [ ] 2.2 Implement `scripts/bug-scribe.sh` — marker detection section
  - `FIRE_PATTERN` regex (case-insensitive trigger, structural match)
  - `NEARMISS_PATTERN` regex (catches common mistakes)
  - Scan staged files (`git diff --cached --name-only`)
  - Read staged file content (`git show ":${FILE}"`)
  - Extract category + description from match
  - Normalize category to UPPER_SNAKE_CASE
  - Print near-miss warnings with expected format
  - Exit 0 if no markers found (silent no-op)
  - _Requirements: REQ-1, REQ-4, REQ-5_

**REFACTOR Phase:**
- [ ] 2.3 Verify all fixture files produce correct output
  - Valid markers → extracted category + description
  - Near-misses → warning message with correct format shown
  - No-marker → silent exit
  - _Requirements: REQ-1, REQ-5_

#### Checkpoint: Phase 2 Complete
- [ ] Detection logic works for all test fixtures
- [ ] Near-miss warnings are helpful
- [ ] No false positives on normal code
- [ ] Changes committed

---

### Phase 3: Core Shell Script — Doc Generation + Resolution

#### Step 3: Bug Doc Scaffolding (`discover` subcommand)

**RED Phase:**
- [ ] 3.1 Write test: running `bug-scribe.sh discover` on a file with a marker creates `docs/bugs/BUG-001-*.md`
  - Verify file exists with correct name
  - Verify BUG_ID, CATEGORY, FILE, DATE, BRANCH are substituted
  - Verify CONTEXT section contains surrounding lines
  - Verify DIFF section says "Pending fix" (no diff at discovery time)
  - Verify Status is OPEN
  - Verify Timeline shows "Discovered" entry
  - _Requirements: REQ-2_

**GREEN Phase:**
- [ ] 3.2 Implement `discover` subcommand in `scripts/bug-scribe.sh`
  - Next-number detection (`ls docs/bugs/BUG-*.md | grep -oE 'BUG-[0-9]+' | sort -t- -k2 -n | tail -1`)
  - Pass 1: `sed` substitution for single-line placeholders
  - Pass 2: `awk` injection for `{{CONTEXT}}` multi-line block
  - `{{DIFF}}` replaced with "Pending fix — will be captured on commit"
  - `{{SOLUTION}}` replaced with "Pending — will be captured from commit message"
  - Temp file handling with `trap` cleanup
  - _Requirements: REQ-2_

- [ ] 3.3 Implement category validation
  - Read known categories from `docs/engineering/chokepoint-log.md`
  - Warn (don't block) on unknown categories
  - _Requirements: REQ-4_

#### Step 4: Diff + Solution Capture (`resolve` subcommand)

**RED Phase:**
- [ ] 4.1 Write test: running `bug-scribe.sh resolve` on a commit with a marker updates the existing bug doc
  - Verify diff section now contains `git diff --cached` content
  - Verify solution section now contains commit message
  - Verify status changed from OPEN to IN_PROGRESS
  - Verify "Fixed" date is populated
  - Verify "Fix committed" timeline entry added
  - Verify updated doc is staged
  - _Requirements: REQ-2_

**GREEN Phase:**
- [ ] 4.2 Implement `resolve` subcommand in `scripts/bug-scribe.sh`
  - Scan staged files for markers (`git diff --cached --name-only`)
  - For each marker, find matching `docs/bugs/BUG-###-*.md` (by file path or category match)
  - Extract `git diff --cached -- "$FILE"` → inject into Diff section
  - Extract commit message from `.git/COMMIT_EDITMSG` → inject into Solution section
  - Update Status: OPEN → IN_PROGRESS
  - Update Fixed date
  - Add Timeline entry
  - `git add` the updated bug doc
  - _Requirements: REQ-2_

**REFACTOR Phase:**
- [ ] 4.3 Verify the complete bug doc is a self-contained importable ticket
  - All metadata filled
  - Problem + Context from discovery
  - Solution + Diff from resolution
  - Only Root Cause, Impact, and Lessons remain for human input
  - _Requirements: REQ-2_

#### Checkpoint: Phase 3 Complete
- [ ] `discover` creates a clean scaffold with context
- [ ] `resolve` enriches the doc with diff + solution
- [ ] Generated doc is a complete importable unit
- [ ] Changes committed

---

### Phase 4: Chokepoint Log + Idempotency

#### Step 5: Chokepoint Log Entry

**RED Phase:**
- [ ] 5.1 Write test: `discover` subcommand appends entry to `docs/engineering/chokepoint-log.md`
  - Verify entry format matches existing chokepoint entries
  - Verify next CP number is determined correctly
  - _Requirements: REQ-3_

**GREEN Phase:**
- [ ] 5.2 Implement chokepoint log append in `discover` subcommand
  - Determine next CP-NNN number
  - Append formatted entry with BUG_ID, category, file, date, description
  - Mark as "auto-generated by Bug Scribe"
  - _Requirements: REQ-3_

#### Step 6: Idempotency

**RED Phase:**
- [ ] 6.1 Write test: running `discover` twice on same file/marker does NOT create duplicate docs
  - First run: creates doc
  - Second run: exits silently (no new doc)
  - _Requirements: REQ-7_

- [ ] 6.2 Write test: running `resolve` on a bug doc that already has a non-placeholder diff is a no-op
  - _Requirements: REQ-7_

**GREEN Phase:**
- [ ] 6.3 Implement idempotency checks
  - `discover`: compute SHA-256 of `FILE:LINE_NUMBER:MARKER_TEXT`, check `.bug-scribe-processed`
  - `resolve`: check if bug doc Diff section still contains "Pending fix" placeholder
  - If already processed → exit 0
  - If not → proceed, append checksum after success
  - _Requirements: REQ-7_

#### Checkpoint: Phase 4 Complete
- [ ] Chokepoint log gets entry appended on discovery
- [ ] Duplicate discover calls are correctly ignored
- [ ] Duplicate resolve calls are correctly ignored
- [ ] Changes committed

---

### Phase 5: Hook Wiring

#### Step 7: Create Hook Definitions

- [ ] 7.1 Create `.kiro/hooks/bug-scribe-on-fix.kiro.hook`
  - Trigger: `fileEdit` on `**/*.{py,ts,tsx,js,jsx,go,rs,java,css,scss}`
  - Action: `runCommand` → `bash scripts/bug-scribe.sh discover "${filePath}"`
  - _Requirements: REQ-1, REQ-2, REQ-3_

- [ ] 7.2 Create `.kiro/hooks/bug-scribe-capture-diff.kiro.hook`
  - Trigger: `beforeCommit`
  - Action: `runCommand` → `bash scripts/bug-scribe.sh resolve`
  - _Requirements: REQ-2_

- [ ] 7.3 Create `.kiro/hooks/bug-scribe-pattern-detect.kiro.hook`
  - Trigger: `fileEdit` on `docs/bugs/BUG-*.md`
  - Action: `askAgent` with pattern analysis prompt
  - _Requirements: REQ-6_

#### Checkpoint: Phase 5 Complete
- [ ] All three hooks created and syntactically valid
- [ ] Changes committed

---

### Phase 6: Integration Testing

#### Step 8: End-to-End Verification

- [ ] 8.1 Test discovery flow: add marker to a file, save → bug doc scaffold created
  - Bug doc exists with OPEN status
  - Context captured, diff says "Pending fix"
  - Chokepoint log entry appended
  - _Requirements: REQ-1, REQ-2, REQ-3_

- [ ] 8.2 Test resolution flow: fix the bug, stage, commit → bug doc enriched
  - Diff section now has actual fix diff
  - Solution section has commit message
  - Status updated to IN_PROGRESS
  - Timeline updated
  - _Requirements: REQ-2_

- [ ] 8.3 Test importable ticket completeness: after resolve, the bug doc is a standalone unit
  - Has: Metadata, Problem, Context, Solution, Diff, Timeline
  - Only missing: Root Cause, Impact, Lessons (human judgment)
  - _Requirements: REQ-2_

- [ ] 8.4 Test cross-language: Python, TypeScript, Go markers all work
  - _Requirements: REQ-1_

- [ ] 8.5 Test near-miss flow: malformed markers produce warnings only
  - _Requirements: REQ-5_

- [ ] 8.6 Test idempotency: same marker on re-save doesn't duplicate; re-commit doesn't re-inject diff
  - _Requirements: REQ-7_

- [ ] 8.7 Test multiple markers in one session (two files, two markers)
  - Both get separate bug docs with sequential numbers
  - _Requirements: REQ-2_

- [ ] 8.8 Test "report only" flow: marker added, file saved, but no fix committed yet
  - Bug doc exists in OPEN state with context but no diff
  - Developer can fix later (same branch or different branch)
  - _Requirements: REQ-2_

#### Checkpoint: Phase 6 Complete
- [ ] All integration scenarios pass
- [ ] Changes committed

---

### Phase 7: Documentation + Cleanup

- [ ] 8.1 Update `docs/ideas/auto-coe-bug-postmortem-automation.md` status to "Implemented"
- [ ] 8.2 Add Bug Scribe to README.md hooks table
- [ ] 8.3 Update `.kiro/specs/README.md` spec index
- [ ] 8.4 Update KRL-17 ticket with completion notes
- [ ] 8.5 Update changelog

#### Checkpoint: Phase 7 Complete
- [ ] All docs updated
- [ ] Idea doc marked as implemented
- [ ] Ticket updated
- [ ] Changes committed

---

## Task Status Legend

- `[ ]` = Not started
- `[-]` = In progress
- `[x]` = Completed
