---
inclusion: always
description: Stay on the task at hand - queue unrelated requests, finish before switching, and keep branches merged-and-deleted
---

# Focus & Branch Discipline

Two failure modes this file exists to prevent. Both are invisible when they happen and expensive much later:

1. **Task thrashing** - dropping the current job halfway to chase a newly-arrived request, losing the thread of the original and leaving it half-done.
2. **Branch sprawl** - branches that are never merged-and-deleted pile up, silently diverge, and produce duplicate-but-different versions of the same file.

---

## The Request Queue Protocol - MANDATORY

**When a new request arrives while you are mid-task, the default is to FILE it, not DO it.**

### Triage, don't thrash

When the user sends a request while you have unfinished work in progress, classify it:

1. **Same task** - a clarification, correction, or refinement of what you're already doing → fold it in and keep going.
2. **Explicit divert** - the user clearly says to switch now ("stop", "drop that", "this is critical, fix it first") → switch, but **commit or stash the current work first** so it is not lost.
3. **Unrelated new request** (the common case) → **file it and continue.**

### How to file it

1. Append the request to `docs/backlog/INBOX.md` (create it if missing) with the date and what you were doing when it arrived.
2. **Acknowledge in one line:** "Noted *[request]* in the backlog - I'll finish *[current task]* first, then pick it up."
3. Return to the task at hand. Do **not** start the new work.

### Why this is strict

Switching tasks mid-stream is the root cause of:
- Half-finished features abandoned on branches.
- **Unrelated changes bleeding into the wrong branch** - you're on `feat/auth` fixing auth, an unrelated CSS or logic fix gets committed there too, and now two unrelated changes are entangled so neither can be reverted cleanly.
- Lost context - the original task's plan evaporates and is never completed.

A filed request is never lost. An abandoned task usually is. **Only the user may authorize a divert** - you do not divert on your own judgment that the new thing is "quick."

---

## Definition of Done - MANDATORY

A task is **not** done when the code works. It is done when ALL of the following are true, **in order**:

1. The change is complete and matches the request.
2. Tests are written and **passing** (TDD - see `testing-standards.md`).
3. The changelog and any affected docs are updated.
4. The work is **committed** on its own branch.
5. The branch is **merged to main**.
6. The merged branch is **deleted**.
7. The backlog is checked - drain the next `docs/backlog/INBOX.md` item or report what remains.

Only after step 7 do you start the next piece of work. "I'll commit it later" is how branches pile up and diverge.

---

## Branch Hygiene - MANDATORY

**A branch exists to isolate one task and then disappear. A branch that outlives its task is a liability.**

1. **One task, one branch.** Never reuse a branch for a second, unrelated task. (Branch types and naming live in `git-workflow.md`.)
2. **Merge-and-delete is a single motion.** The moment work merges to main, delete the branch:
   ```bash
   git checkout main && git merge --no-ff feat/x && git branch -d feat/x
   ```
   Do not keep it "just in case" - main has the history.
3. **Never start new work with a branch still open.** Reach Definition of Done, or explicitly park the current branch, *before* creating another. Unmerged branch + new work = guaranteed divergence.
4. **Check before you branch.** Before creating a branch in a feature area, confirm no branch already touches it:
   ```bash
   bash scripts/branch-check.sh <area>
   ```
   If one exists, build on the latest of it (rebased on main) or merge it first. Do **not** create a parallel branch that will fork into a duplicate file.
5. **Detect collisions while you work.** Run `bash scripts/branch-check.sh` (no args) to list other unmerged branches editing the same files you are - the early-warning signal for silent divergence.
6. **Prune merged branches regularly:**
   ```bash
   git branch --merged main | grep -v '^\*\|main' | xargs -r git branch -d
   ```
7. **If two branches have already diverged on the same file**, do not re-type or guess. Identify the superset version (the most complete, correct one), restore that single file onto the surviving branch, commit it immediately, then delete the dead branch. **Uncommitted reconciliation is itself a root cause** - commit it before doing anything else.

### The anti-pattern this kills

> ~200 branches, almost none merged-and-deleted. Two independently touched the same feature area on the same day, producing duplicate-but-divergent files. The workflow said "merge then delete"; in practice they piled up and silently diverged.

Branch sprawl is not cosmetic. Every un-deleted branch is a chance for the next task to fork reality.

---

## Cross-references

- `git-workflow.md` - branch types, naming, commit format, the standard lifecycle, conflict resolution.
- `change-discipline.md` - change-scope discipline (keep unrelated edits out of the diff), fix-depth rule.
- `scripts/branch-check.sh` - branch collision detector used by the rules above.
- `docs/backlog/INBOX.md` - the request queue this protocol writes to.
