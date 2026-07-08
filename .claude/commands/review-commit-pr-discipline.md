---
description: "Review the current branch's commits and working tree for commit and pull-request discipline, then produce well-structured commit messages and a PR description."
---


Review the current branch's commits and working tree for commit and pull-request discipline, then produce well-structured commits and a high-quality PR description. Read `git-and-focus-discipline.md` and `agent-boundaries.md` first; this prompt operationalizes those rules.

Act as a release engineer and code historian who has to make every change reviewable, revertable, and self-explaining six months from now.

You are not reviewing the *correctness* of the code (other review prompts do that). You are reviewing how the change is **packaged**: branch, commits, and PR narrative.

---

# Inputs

Gather these before judging:

```bash
git branch --show-current                 # branch name + type
git log main..HEAD --oneline              # commits on this branch
git status --porcelain                    # uncommitted work
git diff --stat main...HEAD               # files + churn
```

If a commit message or diff is supplied directly, review that instead.

---

# What to check

## 1. Branch
- Is the branch named by type and scope (`feat/`, `fix/`, `ui/`, `chore/`, `docs/`, `test/`, `refactor/`), kebab-case, 3-5 words? Bug branches carry `bug-###`.
- Does the branch hold **one** logical task? Flag unrelated changes that belong on a separate branch.
- Is it branched from a fresh `main` (not from another feature branch)?

## 2. Commit granularity
- **One logical change per commit.** When files changed for different reasons are bundled together, recommend splitting (`git add -p` / per-file staging) and give the exact split.
- Were **meaningful checkpoints** committed as work progressed (compiles + affected tests pass + lint clean), rather than one giant end-of-task dump?
- Are `checkpoint:` commits present where a multi-file or multi-session task warranted a defensive rollback point? (Their absence on a large change is a smell, not an error.)
- Is there any **uncommitted work** sitting in the tree? That must be committed or stashed before the task is "done."

## 3. Commit messages
- Conventional Commits: `<type>(<scope>): <description>`, imperative mood, no trailing period in the subject.
- The body states **what changed and why** - not a restatement of the diff. Non-obvious decisions and trade-offs belong here.
- No secrets, file paths, or noise. Co-authorship trailer present where required.

## 4. Tests & checkpoints
- Does the change add or update tests for new behaviour (TDD)? Bug fixes carry both a negative (RED) and positive (GREEN) regression test named for the bug.
- No test was weakened or deleted to make a suite pass.

## 5. PR description quality - the highest-leverage check
A good PR answers three questions explicitly. Draft or upgrade it to include:
- **What changed** - a tight summary of the behaviour/structure delta, not a file list.
- **Why** - the motivating requirement, bug, or decision.
- **Trade-offs considered** - alternatives weighed and why this approach won; known limitations; follow-ups deferred.
- Plus: linked issue/spec/ADR, test evidence, and anything a reviewer must verify manually (UI, migrations).

---

# Output

1. **Verdict** - is this change packaged well enough to open a PR? (Ready / Needs work.)
2. **Findings** - ordered by severity, each with the exact remediation command or rewrite.
3. **Rewritten commit message(s)** - for any commit that needs it.
4. **A ready-to-paste PR description** - What / Why / Trade-offs / Testing / Reviewer notes.

Never invent trade-offs or motivations that are not evident from the diff and history - if the "why" is missing, say so and ask, rather than fabricating a rationale.
