---
inclusion: always
description: Operate only inside your own project - never reach into sibling repos, never touch git trees or processes you don't own
---

# Session Isolation

Multiple agent sessions can run on one machine at the same time, sharing the filesystem and sibling git repositories. A session that reaches outside its own project corrupts another session's work. These rules keep each session in its lane.

This is the failure this file prevents:

> A session launched for repo **tactiq** reached into the sibling **planiq** repo - `git -C /home/sourjya/coding/planiq reset --hard`, a cherry-pick, a checkout, a PR - and corrupted the git state of a *different* session that was actively working planiq. Another session nearly ran `kill` on its own host terminal.

## The Boundary - MANDATORY

**Your project root is the directory you were launched in. Everything you do stays inside it.**

1. **Never operate on another repository.** Do not `cd` into a sibling project, do not run `git -C <other-path> ...`, and do not read/write/commit through absolute paths that point outside your project root.
2. **Never infer cross-repo intent.** If a task seems to need changes in another repository, STOP and tell the user to run that work in *that* repo's own session. Do not reach across on your own judgment - that is exactly how `git -C /other/repo reset --hard` happens.
3. **Branches and PRs belong to one repo.** Checking out a branch, cherry-picking, rebasing, or opening a PR in a repo that is not your project root is forbidden, even when asked indirectly ("also fix the thing in the other project").

## Concurrent Sessions - MANDATORY

**Assume another agent may be working in this tree, or a sibling tree, right now.**

1. **Verify before destructive git.** Before `reset --hard`, `checkout -f`, `clean -fd`, `cherry-pick`, `rebase`, or branch deletion, confirm: (a) you are in your own project root, and (b) the current branch and working-tree state are what you expect. If the branch or `HEAD` moved under you, a foreign actor touched the tree - STOP and report, do not "fix" it blindly.
2. **One worktree per concurrent session - the preventive control.** When more than one agent session may touch this repo at once, each session gets its **own git worktree on its own branch**: `git worktree add ../<name> <branch>`. Never switch branches in, or share, a single working tree across sessions - that is what collides on `HEAD`. `scripts/branch-check.sh` is the *detective* control (warns after a collision); worktrees *prevent* it.
3. **Run the guard.** `bash scripts/session-guard.sh` records this session's lock and warns if another live session holds the tree or if `HEAD` drifted unexpectedly.

## Processes - MANDATORY

1. **Never kill a process you did not spawn.** Your terminal, your MCP servers, and your parent session share one process tree - killing "the other agent" can be suicide (your own session) or sabotage (the user's other work).
2. **Identify before you signal.** Before any `kill`/`pkill`, map the process tree and confirm the target is something you started. When unsure, report the PIDs to the user and let them decide. Never `pkill` by name pattern across the machine.

## Cross-references

- `git-and-focus-discipline.md` - in-repo branch discipline, commit cadence, and focus (this file is about *cross*-repo and *cross*-session safety).
- `scripts/session-guard.sh` - session lock + working-tree integrity check.
