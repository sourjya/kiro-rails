---
inclusion: always
description: The hard stops - what an agent must never do autonomously. The shortest, sharpest file in the steering set. Read it first.
---

# Agent Boundaries

The hardest constraints, stated plainly. Everything here is elaborated elsewhere;
this file exists so the rules are impossible to miss and impossible to "load past."
When any rule below conflicts with convenience, the rule wins.

## Never (without explicit user confirmation)

1. **Never commit directly to `main`, force-push it, or rebase it.** Every change goes
   on its own branch. → `git-and-focus-discipline.md`
2. **Never end a session or turn with uncommitted work on a branch.** Commit (feature
   or `checkpoint:`) or stash before the context boundary. → `git-and-focus-discipline.md`
3. **Never resolve conflicts with `git checkout --ours .` / `--theirs .`** or any
   blanket strategy. Per-file only. → `git-and-focus-discipline.md`
4. **Never modify a test to make it pass.** Fix the implementation. A failing test is
   information, not an obstacle. → `testing-standards.md`
5. **Never delete files, config, or `.env`, change CI/CD, or alter shared
   infrastructure** without explicit confirmation. → `change-discipline.md`
6. **Never add, remove, or upgrade a dependency** outside the task's stated need, and
   never via `pip`/`requirements.txt` (use `uv`). → `change-discipline.md`
7. **Never commit secrets, credentials, or `.env` contents.** → `change-discipline.md`
8. **Never change code outside the scope of the current task.** No drive-by refactors.
   → `change-discipline.md`
9. **Never reach into another repository or kill a process you did not spawn.**
   → `session-isolation.md`
10. **Never modify an already-applied database migration.** Create a new one.
    → `database-conventions.md`

## Always

1. **Always branch first, and check for an existing branch** in the area before
   creating one (`scripts/branch-check.sh`). → `git-and-focus-discipline.md`
2. **Always checkpoint before a multi-file or multi-session task**
   (`git commit -m "checkpoint: before <task>"`). → `git-and-focus-discipline.md`
3. **Always commit at every meaningful checkpoint** (compiles + affected tests pass +
   lint clean). Do not let a passing state sit uncommitted. → `git-and-focus-discipline.md`
4. **Always merge-and-delete** the branch as one motion when work lands on main.
   → `git-and-focus-discipline.md`
5. **Always run a variant search after a bug fix.** The reported instance is rarely
   the only one. → `git-and-focus-discipline.md`
6. **Always stop and ask on a genuine ambiguity or conflict.** Two minutes of
   clarification beats twenty hours of rebuilding; a confident wrong guess is the
   expensive failure mode. → `git-and-focus-discipline.md`

## When a new request arrives mid-task

File it to `docs/backlog/INBOX.md` and finish the current task first. Divert **only**
when the user explicitly orders it. → `git-and-focus-discipline.md`
