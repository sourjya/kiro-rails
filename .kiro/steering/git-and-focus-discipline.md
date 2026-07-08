---
inclusion: always
description: Git branching, commit cadence, and agent focus - branch isolation, defensive checkpoints, request triage, and merge-and-delete hygiene in one place
---

# Git & Focus Discipline

This file governs one behavioral domain: how an agent uses git and how it stays
focused on one task at a time. The two are inseparable - undisciplined focus
(thrashing between tasks) is what entangles unrelated changes on the wrong branch,
and undisciplined git (uncommitted work, branch sprawl) is what makes lost focus
unrecoverable.

Two failure modes this file exists to prevent. Both are invisible when they happen
and expensive much later:

1. **Branch sprawl & divergence** - branches that are never merged-and-deleted pile
   up, silently diverge, and produce duplicate-but-different versions of the same file.
2. **Task thrashing & lost work** - dropping the current job to chase a new request,
   or ending a session with work uncommitted, so the thread (and sometimes the code)
   evaporates.

> The hard "never" rules referenced throughout live in `agent-boundaries.md` - the
> shortest file in this set. Read it first; this file is the detailed "how".

---

## Core Principle

**Every concrete piece of work gets its own branch. Commit every meaningful
checkpoint within that branch. Merge to main when it works, then delete the branch.
Never mix unrelated work on the same branch.**

```
main ──→ feat/A ──→ merge+delete ──→ fix/B ──→ merge+delete ──→ feat/C ──→ ...
```

---

# Part 1 - Branch Hygiene

**A branch exists to isolate one task and then disappear. A branch that outlives its
task is a liability.** These rules come first because branch divergence is the
most common and most damaging failure mode.

1. **One task, one branch.** Never reuse a branch for a second, unrelated task.
2. **Check before you branch.** Before creating a branch in a feature area, confirm
   no branch already touches it:
   ```bash
   bash scripts/branch-check.sh <area>
   ```
   If one exists, build on the latest of it (rebased on main) or merge it first. Do
   **not** create a parallel branch that will fork into a duplicate file.
3. **Never start new work with a branch still open.** Reach Definition of Done, or
   explicitly park the current branch, *before* creating another. Unmerged branch +
   new work = guaranteed divergence.
4. **Merge-and-delete is a single motion.** The moment work merges to main, delete
   the branch:
   ```bash
   git checkout main && git merge --no-ff feat/x && git branch -d feat/x
   ```
   Do not keep it "just in case" - main has the history.
5. **Detect collisions while you work.** Run `bash scripts/branch-check.sh` (no args)
   to list other unmerged branches editing the same files you are - the early-warning
   signal for silent divergence.
6. **Prune merged branches regularly:**
   ```bash
   git branch --merged main | grep -v '^\*\|main' | xargs -r git branch -d
   ```
7. **If two branches have already diverged on the same file**, do not re-type or
   guess. Identify the superset version (the most complete, correct one), restore that
   single file onto the surviving branch, commit it immediately, then delete the dead
   branch. **Uncommitted reconciliation is itself a root cause** - commit it before
   doing anything else.

### The anti-pattern this kills

> ~200 branches, almost none merged-and-deleted. Two independently touched the same
> feature area on the same day, producing duplicate-but-divergent files. The workflow
> said "merge then delete"; in practice they piled up and silently diverged.

Branch sprawl is not cosmetic. Every un-deleted branch is a chance for the next task
to fork reality.

### Parallel agent sessions

If more than one agent session may touch this repo (or a sibling tree) at once, each
session gets its **own git worktree on its own branch** - never a shared working
directory. `scripts/branch-check.sh` is the *detective* control (warns after the
fact); worktrees are the *preventive* control. See `session-isolation.md` for the
full cross-session safety rules.

---

# Part 2 - Branch Types & Naming

| Situation | Branch type | Example |
|---|---|---|
| Building a new feature or spec | `feat/` | `feat/ingredient-analysis` |
| Fixing a reported bug | `fix/` | `fix/bug-003-score-calc` |
| UI/UX change only | `ui/` | `ui/dashboard-layout` |
| Tests only | `test/` | `test/auth-regression` |
| Tooling, config, deps | `chore/` | `chore/update-deps` |
| Documentation only | `docs/` | `docs/adr-001-tech-stack` |
| Refactor (no behaviour change) | `refactor/` | `refactor/extract-service` |

**Rules:**
- Always kebab-case after the `/`
- 3-5 words max
- Include BUG-### for bug fixes: `fix/bug-034-description`
- Include spec name for spec work: `feat/spec-name`

---

# Part 3 - Commit Discipline

**A branch is not a place to hoard uncommitted work. Commit at every meaningful
checkpoint so that no context boundary, crash, or bad next step can erase a good
state.** This is the discipline most agents lack by default.

## What counts as a "meaningful checkpoint"

A commit-worthy checkpoint is reached when **all three** hold:

1. The code **compiles / imports cleanly** (no syntax or import errors).
2. The **affected tests pass** (the tests touching the code you just changed).
3. There are **no new lint errors** introduced by the change.

The moment you reach that state, **commit before moving to the next logical unit of
work.** Do not let a passing state sit uncommitted while you start the next piece -
context compression, session end, or a bad subsequent step will erase it.

## Defensive Checkpoints - MANDATORY

Before starting any task that will **touch more than 3 files** or **span more than one
session**, create a labeled checkpoint commit first:

```bash
git add -A && git commit -m "checkpoint: before <task-description>"
```

This creates a safe rollback point. A checkpoint is **not** a feature commit - it does
**not** need to pass tests or meet the commit-message standard below. Its only job is
to make the pre-task state recoverable. (This is the one sanctioned exception to
"never commit failing code" - a checkpoint is explicitly flagged as such.)

## Never end a session with uncommitted work - MANDATORY

Agent sessions end abruptly - context compaction, a closed terminal, a crash. Work
left in the working tree but not in git is gone.

- At any natural stopping point (task done, turn ending, switching away), run
  `git status`. If there are uncommitted changes on a branch, **commit them**
  (feature commit if at a checkpoint, `checkpoint:` commit otherwise) **or stash them.**
- The `commit-checkpoint-on-stop` hook reminds you of this on agent stop, but the
  rule holds whether or not the hook fires.

## One logical change per commit - MANDATORY

- **One logical change per commit.** When multiple files change for *different*
  reasons, prefer separate commits per reason. Do **not** bundle unrelated changes -
  it makes rollback impossible.
- **Test before a feature commit.** Never commit code that makes existing tests fail,
  unless the commit is an explicitly-labeled `checkpoint:`.
- **Review your diff before committing.** Every changed line must relate to the
  task (see `change-discipline.md`).

## Commit Message Format

[Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <short description>
```

| Type | When |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `chore` | Tooling, deps, config |
| `docs` | Documentation only |
| `test` | Tests only |
| `refactor` | No behaviour change |
| `ui` | Frontend-only visual change |
| `perf` | Performance improvement |

(`checkpoint:` is the one non-Conventional prefix, reserved for the defensive
rollback commits described above.)

---

# Part 4 - The Standard Lifecycle

## Standard Git Scripts

All git operations MUST use the scripts in `scripts/` which pipe output through `tee`
to `logs/`. This ensures output is always captured.

| Script | Purpose | Log file |
|---|---|---|
| `./scripts/git-commit-push.sh "message"` | Commit, merge to main, push | `logs/git-commit-push.txt` |

## 1. Start from main
```bash
git checkout main && git checkout -b feat/my-work
```

## 2. Work and commit incrementally (at every meaningful checkpoint)
```bash
git add -A && git commit -m "feat: description of what changed"
```

## 3. Merge to main when done
```bash
bash scripts/git-commit-push.sh "feat: description"
```

## 4. Start the next piece of work from main
```bash
git checkout -b feat/next-thing
```

---

# Part 5 - Focus & The Request Queue Protocol

**When a new request arrives while you are mid-task, the default is to FILE it, not
DO it.**

### Triage, don't thrash

When the user sends a request while you have unfinished work in progress, classify it:

1. **Same task** - a clarification, correction, or refinement of what you're already
   doing → fold it in and keep going.
2. **Explicit divert** - the user clearly says to switch now ("stop", "drop that",
   "this is critical, fix it first") → switch, but **commit or stash the current work
   first** so it is not lost.
3. **Unrelated new request** (the common case) → **file it and continue.**

### How to file it

1. Append the request to `docs/backlog/INBOX.md` (create it if missing) with the date
   and what you were doing when it arrived.
2. **Acknowledge in one line:** "Noted *[request]* in the backlog - I'll finish
   *[current task]* first, then pick it up."
3. Return to the task at hand. Do **not** start the new work.

### Why this is strict

Switching tasks mid-stream is the root cause of:
- Half-finished features abandoned on branches.
- **Unrelated changes bleeding into the wrong branch** - you're on `feat/auth` fixing
  auth, an unrelated CSS or logic fix gets committed there too, and now two unrelated
  changes are entangled so neither can be reverted cleanly.
- Lost context - the original task's plan evaporates and is never completed.

A filed request is never lost. An abandoned task usually is. **Only the user may
authorize a divert** - you do not divert on your own judgment that the new thing is
"quick."

---

# Part 6 - Definition of Done

A task is **not** done when the code works. It is done when ALL of the following are
true, **in order**:

1. The change is complete and matches the request.
2. Tests are written and **passing** (TDD - see `testing-standards.md`).
3. The changelog and any affected docs are updated.
4. The work is **committed** on its own branch.
5. The branch is **merged to main**.
6. The merged branch is **deleted**.
7. The backlog is checked - drain the next `docs/backlog/INBOX.md` item or report what
   remains.

Only after step 7 do you start the next piece of work. "I'll commit it later" is how
branches pile up and diverge.

---

# Part 7 - Handling Bugs During Feature Work

**Do NOT fix bugs on the current feature branch.**

1. Note it down - add to `docs/bugs/`
2. Finish or stash the current feature
3. Create a dedicated fix branch from main
4. Fix, test, merge
5. Return to the feature branch and merge main

## Bug Resolution Workflow - MANDATORY

When a bug is identified, follow this workflow in full:

1. **Assign a bug number** - check `docs/bugs/` for the highest existing `BUG-###`
   number and increment by 1
2. **Create the bug document** - `docs/bugs/BUG-###-short-description.md` with: ID,
   Severity, Status, Description, Reproduction steps, Root cause, Fix description,
   Files changed, Regression tests added
3. **Fix the bug** - minimal and targeted fix on a `fix/bug-###-description` branch.
   Do not refactor unrelated code.
4. **Variant search - NON-NEGOTIABLE** - after identifying the root cause:
   - Search for the same pattern at all other call sites in the codebase
   - Search for the same vulnerability class elsewhere (e.g., if you found one SQL
     injection, search for all raw SQL)
   - Document: "Variant search: checked [locations]. Found [N] additional instances."
   - Fix ALL variants in the same branch, not just the reported instance
   - The `variant-search-on-fix-branch` hook reminds you of this whenever you work on
     a `fix/` branch - the reported instance is rarely the only one.
5. **Add regression tests - NON-NEGOTIABLE** - every bug fix requires both negative
   AND positive regression tests:
   - **Negative test**: reproduces the bug, must FAIL on unfixed code (RED phase)
   - **Positive test**: confirms the fix, passes after fix (GREEN phase)
   - Named after the bug: `test_bug###_<description>` (Python) or
     `it('BUG-###: <description>')` (TypeScript)
   - Never mark a bug `FIXED` without regression tests committed in the same change
6. **Link to the roadmap** - add a reference in the roadmap or spec tasks for
   traceability
7. **Update the changelog** - add entry to `docs/changelogs/CHANGELOG.md` under
   today's date
8. **Update the bug document status** - set `Status` to `FIXED`, fill in `Fixed` date
   and remaining fields

---

# Part 8 - Spec-Driven Work

1. Create `feat/<spec-name>` branch from main
2. Complete ALL tasks in the spec on that branch
3. Merge to main when the spec is complete
4. ONLY THEN create the next spec's branch

**Never start Phase 2 before Phase 1 is merged to main.**

---

# Part 9 - Forbidden Actions & Per-File Conflict Resolution

| Action | Why it's banned |
|---|---|
| Fixing a bug on a feature branch | Entangles unrelated changes |
| Creating a branch from another feature branch | Misses main's latest work |
| Committing directly to main | Bypasses branch isolation |
| Leaving a branch unmerged and starting new work | Creates divergence |
| Leaving a session with uncommitted work | Work evaporates at the context boundary |
| Mixing multiple features on one branch | Makes rollback impossible |
| Modifying a test to make it pass | Hides the real failure - fix the implementation |
| `git checkout --ours .` or `git checkout --theirs .` | Blanket conflict resolution reverts work |
| Force-pushing or rebasing `main` | Rewrites shared history |

## Per-File Conflict Resolution - MANDATORY

**FORBIDDEN:**
```bash
git checkout --ours .    # ← BANNED
git checkout --theirs .  # ← BANNED
```

Resolve each file individually based on which side has the correct work. On a genuine
ambiguity you cannot resolve from the code, **stop and ask** - two minutes of
clarification beats twenty hours of rebuilding. A confident wrong guess is the
expensive failure mode.

---

## Cross-references

- `agent-boundaries.md` - the hard "never" rules in their shortest form.
- `change-discipline.md` - change-scope discipline (keep unrelated edits out of the
  diff), fix-depth rule, permission boundaries.
- `session-isolation.md` - cross-repo and cross-session safety, worktree usage.
- `testing-standards.md` - TDD cycle, regression-test requirements.
- `scripts/branch-check.sh` - branch collision detector used by the rules above.
- `docs/backlog/INBOX.md` - the request queue the focus protocol writes to.
