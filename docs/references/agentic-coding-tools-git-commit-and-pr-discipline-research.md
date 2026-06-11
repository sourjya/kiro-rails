# Agentic Coding Tools — Git Commit & PR Discipline
## Deep Research Report + Steering Recommendations for ChaosLabz / Kiro
**Date:** June 2026 | **Scope:** Kiro, Claude Code, Cursor, OpenAI Codex, GitHub Copilot, Devin

---

## 1. The Landscape in 2026

The shift from "AI-assisted coding" to full agentic coding happened fast. By mid-2025, tools like Claude Code and Codex could autonomously edit files, run tests, and commit changes. By 2026, the developer's job has moved from context management to outcome specification — and from "write code" to "govern agent behavior."

Git discipline is where the wheels fall off most often. Agents are fluent in git mechanics; they are not inherently disciplined about when to commit, what to branch, or when to stop and ask. That discipline is entirely externally imposed — via configuration files, steering documents, hooks, and human-in-the-loop gates. If you don't configure it, you get chaos.

---

## 2. Configuration Formats — The Cross-Agent Landscape

Each tool reads a different primary config file. This is the biggest source of duplication pain for multi-agent shops.

| Tool | Primary Config | Secondary / Fallback |
|---|---|---|
| **Kiro** | `.kiro/steering/*.md` | `.kiro/hooks/` |
| **Claude Code** | `CLAUDE.md` | Falls back to `AGENTS.md` if no CLAUDE.md |
| **OpenAI Codex** | `AGENTS.md` (nearest file wins; deeply nested overrides outer) | `codex.md` |
| **GitHub Copilot** | `.github/copilot-instructions.md` | `AGENTS.md` (proximity rules apply) |
| **Cursor** | `.cursor/rules/*.mdc` (modern) or `.cursorrules` (legacy) | `agents.md` fallback |
| **Gemini CLI** | `GEMINI.md` | Can be configured to read `AGENTS.md` |
| **Devin** | `AGENTS.md` | — |
| **Windsurf** | `.windsurfrules` | `AGENTS.md` |

### The emerging standard: AGENTS.md

`AGENTS.md` was released by OpenAI in August 2025 and transferred to the Linux Foundation's Agentic AI Foundation alongside Anthropic and other vendors. It is now the de facto cross-tool standard. As of May 2026, it is natively read by Codex CLI, GitHub Copilot, Cursor, Aider, Devin, Sourcegraph Amp, Windsurf, Amazon Q, and more.

Claude Code reads `CLAUDE.md` natively; the standard workaround for cross-tool teams is a one-line `CLAUDE.md` that imports `AGENTS.md`:

```markdown
@AGENTS.md
```

**Practical rule for ChaosLabz:** Kiro's `.kiro/steering/` is your primary system, but adding a root `AGENTS.md` + a thin `CLAUDE.md` bridge ensures any other agent you onboard picks up your conventions without a separate file to maintain.

---

## 3. Commit Discipline — What Agents Do By Default vs. What You Should Configure

### 3.1 Default behaviors (without configuration)

**Kiro:** No autonomous commits by default. Commits only happen when triggered via a hook or when the user explicitly asks. The agent hooks system (`fileEdited`, `taskCompleted` etc.) is where you wire up automated commit behavior.

**Claude Code:** Will commit when instructed, but does not commit autonomously during a session. Context loss mid-session is a known failure mode — work can evaporate at compaction if not committed. Official guidance: "Commit frequently, dump progress to files, treat every session as disposable."

**Cursor:** No auto-commit by default. Best practice from the community: defensive checkpoint commits before any multi-file refactor (`git add -A && git commit -m "checkpoint: before <task>"`). Cursor 3.0's `Background Agent` (cloud, sandboxed) does commit automatically as part of the issue-to-PR flow.

**Codex:** Operates in an isolated cloud sandbox per task. Each task ends with a proposed diff for human review — Codex does not push to main autonomously. The commit-to-PR flow is fully managed; humans approve before anything lands.

**GitHub Copilot Coding Agent:** Provisions a `copilot/issue-{number}` branch, does all work there, opens a PR — cannot touch main or any protected branch. PR is gated behind human approval + full CI. This is the most constrained architecture of the major tools.

**Devin:** Maximum autonomy — plan to pull request, no mandatory human checkpoint mid-task. Best for fully delegatable bounded tasks. Requires strong AGENTS.md constraints to compensate.

### 3.2 What high-performing teams configure

The consensus across practitioner write-ups and community research:

1. **Commit at task checkpoints, not at file-save.** A checkpoint is: code written + tests pass + no failing lint. Uncommitted checkpoints are the root cause of the context-loss regression pattern.

2. **One logical change per commit.** One well-cited pattern from Claude Code best practices: separate commits per file when multiple files change for different reasons. Do NOT bundle unrelated changes — makes rollback impossible.

3. **Commit message = Conventional Commits format.** Virtually all tools can be steered to produce `feat(scope): description`, `fix(scope): description` etc. Enforce this via a steering rule or pre-commit hook. Agents generally produce better commit messages than developers do when explicitly instructed to follow a format.

4. **Defensive checkpoint before any multi-file refactor.** This is cited independently by Cursor, Claude Code, and Codex communities. Make it a hook: before any session that will touch >3 files, create a labeled checkpoint commit.

5. **After every successful test run, commit immediately.** Do not let a passing state sit uncommitted — context compression, agent session end, or a bad subsequent step will erase it.

---

## 4. Branch Strategy — What Agents Do and What Works

### 4.1 Kiro (GitHub integration)

Kiro's autonomous GitHub agent creates a feature branch per task, commits with clear messages, pushes to the remote, and opens a PR with implementation approach and trade-offs documented. Co-authorship is recorded in every commit. This is a well-designed flow.

**Gap:** Kiro does not have built-in branch collision detection for multi-session or multi-developer scenarios. That is exactly the problem your `focus-and-branch-discipline.md` file addresses.

### 4.2 Copilot Coding Agent

The cleanest isolation model in the industry. Scoped strictly to `copilot/*` branches. Cannot touch main or develop. GitHub Actions pipelines require human approval to trigger on agent PRs. AGENTS.md is the hard constraint layer — code style, testing thresholds, prohibited patterns, commit conventions.

### 4.3 Cursor Background Agent

Sandboxed cloud VM with its own ephemeral checkout. Can read a GitHub issue, branch, implement, push, and open a PR without the developer's laptop being open. Cursor 3.0 added `/worktree` command for branch-isolated task sandboxing in the local Agents Window. This solves the same-file divergence problem that your current steering files address.

### 4.4 Codex

Each task gets its own isolated sandbox preloaded with the repository. There is no shared branch state between parallel tasks — parallel execution is safe by design. The output is always a proposed diff for review, not an automatic push.

### 4.5 Common anti-patterns (across all tools)

These failure modes are well-documented and appear repeatedly across practitioner research:

| Anti-pattern | Root cause | Mitigation |
|---|---|---|
| **Branch divergence** | Two sessions touch the same files on different branches; neither is merged first | Branch collision check before starting (`scripts/branch-check.sh` pattern); one branch per feature area |
| **Uncommitted work at context boundary** | Agent session ends mid-task; work is in working tree but not in git | Mandatory checkpoint commits at defined milestones; never declare "done" without a commit |
| **Silent conflict resolution** | Agent uses `--ours` or `--theirs` blanket resolution | Explicitly ban these in steering; per-file conflict resolution only |
| **Parallel agent write collision** | Two agents modify the same file concurrently | Git worktrees (one per agent task); never share a working directory across agents |
| **Feature branch accumulation** | Branches created but never merged or deleted | Merge-and-delete rule; branch lifecycle managed as part of task completion criteria |
| **Stale base branch** | Agent branches from a feature branch, not main | Always branch from the freshest point; merge outstanding branches before creating new ones |
| **Confident wrong guess on conflict** | Agent resolves ambiguity by assuming rather than asking | Explicit "stop and clarify" rules in steering for genuine conflicts |
| **Test modification to pass tests** | Agent modifies tests rather than fixing implementation | Explicit steering rule: never modify tests to make them pass; commit safety net before implementation |

---

## 5. PR Discipline — How Each Tool Handles It

| Tool | PR creation | PR description quality | Human gate |
|---|---|---|---|
| **Kiro** | Automatic after task completion | Detailed: changes, approach, trade-offs | Optional — configurable |
| **Copilot Coding Agent** | Automatic after task completion | Structured, includes security scan findings | Mandatory human approval before CI triggers |
| **Cursor Background Agent** | Automatic after task completion | Issue-sourced context, diff summary | Human review before merge |
| **Codex** | Proposes diff; PR opened with human opt-in | Mirrors PR preferences trained via RL | Human approval always required |
| **Devin** | Fully autonomous by default | Variable quality | Optional — configurable per team |
| **Claude Code** | Manual (developer-initiated) or via hooks | As good as the commit message discipline | Always manual |

**Key finding:** At OpenAI, Codex reviews 100% of pull requests. The teams extracting the most value from this do so because their tests are good enough to make the review meaningful. Test quality is the multiplier — automated review on a poorly-tested codebase produces noise, not signal.

### PR description best practice (universal)

The most impactful single steering rule for PR quality: require the agent to document **what changed, why, and what trade-offs were considered** — not just what files were modified. Kiro does this by default; others need it explicitly in their config.

---

## 6. Hook and Automation Integration

### Kiro hooks

Kiro's hook system is the most flexible of any tool reviewed. Hooks fire on IDE events (`fileEdited`, `taskCompleted`, `onSave`, git events) and trigger predefined agent actions. Hooks run inside the IDE during development — before code reaches a CI/CD pipeline. Teams commit hooks to version control for shared enforcement. Practical uses documented in production:

- Auto-generate changelog from git diff
- Commit message helper (format enforcement)
- Compliance check against coding standards
- Test synchronization (update test file after Python file change)
- API documentation update on code change
- Pre-commit security scan (comment standards check)

### Claude Code hooks / commands

Custom slash commands in `.claude/commands/` allow pre-built commit workflows. A `commit.md` command can: review the diff, determine if multiple commits would be appropriate, enforce Conventional Commits format, auto-detect GitHub issue references, and stage only what's relevant. Skills watch the conversation and activate when the described task matches.

### Cursor rules

`.cursor/rules/*.mdc` files can encode defensive commit rules. Well-adopted community pattern:

```markdown
# Defensive Commits
- Before any multi-file refactoring: git add -A && git commit -m "checkpoint: before <task>"
- After every successful test run: commit immediately
- NEVER commit without user review
- NEVER delete config files without explicit confirmation
```

### Copilot Coding Agent

AGENTS.md is the primary constraint surface. Three security scanning layers run inside the agent's own workflow before a human sees the PR. Findings surface as PR comments. The agent is read-only on main/develop; branch protections apply identically to agent PRs as to human PRs.

---

## 7. Cross-Agent Comparison Summary

| Dimension | Kiro | Claude Code | Cursor | Codex | Copilot Agent | Devin |
|---|---|---|---|---|---|---|
| **Config format** | `.kiro/steering/*.md` | `CLAUDE.md` | `.cursor/rules/*.mdc` | `AGENTS.md` | `AGENTS.md` | `AGENTS.md` |
| **Autonomous commits** | Via hooks | No | No (local); Yes (Background) | No (proposes diff) | Yes (own branch) | Yes (full auto) |
| **Branch per task** | Yes (GitHub integration) | Manual | Manual (local); Yes (Background) | Yes (sandboxed) | Yes (copilot/*) | Yes |
| **PR auto-create** | Yes | No (manual) | Background Agent only | Human opt-in | Yes | Yes |
| **Human gate** | Configurable | Always manual | Optional | Always | Mandatory | Optional |
| **Conflict resolution** | Manual unless scripted | Manual | Manual | Sandboxed (no conflict) | Per-file (protected) | Autonomous |
| **Hook/automation** | Native (rich) | Commands + Skills | Rules files | AGENTS.md + CI | AGENTS.md + CI | AGENTS.md |
| **Isolation model** | Session-based | Session-based | Worktree (v3.0) | Sandbox per task | Sandbox per task | Isolated VM |

---

## 8. Recommendations for Your Steering Files

### 8.1 What your current setup gets right

Your existing steering files are significantly ahead of most teams:

- `focus-and-branch-discipline.md` directly addresses the branch divergence and context-loss failure modes that the research identifies as the most common and damaging
- `git-workflow.md` has per-file conflict resolution rules (banning `--ours`/`--theirs`), conventional commits enforcement, and the bug-branch separation discipline
- The `scripts/branch-check.sh` pattern is exactly the collision detection approach the literature recommends
- Your "stop and clarify" rule in Part 3 of focus-and-branch-discipline.md matches the research finding that "2 minutes of clarification beats 20 hours of rebuilding"
- Tier 1 pre-commit hooks for security review are a best-in-class pattern

### 8.2 Gaps and improvements

**Gap 1: No defensive checkpoint commit rule**

Missing across all your steering files: the explicit "create a checkpoint commit before any multi-file refactor or long-running task." This is the single most-cited missing discipline in practitioner write-ups.

Recommended addition to `git-workflow.md`:

```markdown
## Defensive Checkpoints — MANDATORY

Before starting any task that will touch more than 3 files or take more than one
session to complete, create a labeled checkpoint commit:

git add -A && git commit -m "checkpoint: before <task-description>"

This creates a safe rollback point. A checkpoint is NOT a feature commit — it does
not need to pass tests or meet commit message standards. Its only job is to make
work recoverable.
```

**Gap 2: No AGENTS.md cross-tool bridge**

Your `.kiro/steering/` setup is Kiro-native. If you ever run Claude Code, Codex, or any other agent in your repos, they will not pick up your conventions. Cost: zero. Benefit: full portability.

Recommended action:
1. Create a root `AGENTS.md` that summarizes your key git conventions (branch naming, commit format, no `--ours`/`--theirs`, bug-branch separation, test requirements)
2. Create a root `CLAUDE.md` containing `@AGENTS.md` as the first line, then any Claude-specific additions

**Gap 3: No session-end commit checklist**

Agents (including Kiro) do not reliably commit at session end before context compaction. You have experienced this directly (the 3x search-box regression). Missing: an explicit hook or rule that triggers at natural session boundaries.

Recommended: a Kiro hook on `taskCompleted` event that:
1. Runs `git status`
2. If there are uncommitted changes: prompts to commit or stash before the task is marked done
3. Blocks task completion without a commit hash

**Gap 4: Commit granularity is under-specified**

Your `git-workflow.md` covers branch strategy well but is light on when within a task to commit. The "one branch per feature" rule is clear; the "commit every meaningful checkpoint within that branch" rule is not stated.

Recommended addition: define a "meaningful checkpoint" as: code compiles + affected tests pass + no new lint errors. That state should always be committed before moving to the next logical unit of work.

**Gap 5: No worktree strategy for parallel agent work**

If you ever run multiple Kiro sessions (or a Kiro + Claude Code combination) on the same repo, you will hit the concurrent-write collision problem documented in the multi-agent research. Git worktrees solve this structurally.

Recommend documenting a policy: each active agent session gets its own worktree on its own branch. The `scripts/branch-check.sh` pattern you have is a good detective control; worktrees are the preventive control.

**Gap 6: Bug-fix branch naming is correct but variant search is buried**

Your git-workflow.md has an excellent variant search requirement in the bug resolution workflow. However it lives inside a long sequential checklist. The research shows agents skip or shortcut long checklists. Consider making variant search a standalone hook that fires when a `fix/` branch is created.

### 8.3 Consolidation recommendations

Your steering files have some overlap. Suggested reorganization:

**Keep as-is (these are well-scoped and non-overlapping):**
- `code-commenting-standards.md`
- `review-policy.md`
- `versioning.md`
- `wsl-shell-commands.md`
- `ux-pattern-registry.md` (manual inclusion is correct)
- `ux-patterns-decisions.md`

**Consolidate these two into one file:**
- `focus-and-branch-discipline.md` + `git-workflow.md` → `git-and-focus-discipline.md`

**Rationale:** Both files govern the same behavioral domain (git operations + agent focus). Having them separate means an agent loading one might miss critical rules in the other. A single file with clear sections is harder to partially-load. The merged file should open with the branch collision rules (highest-impact), then commit discipline, then focus/triage rules, then the detailed bug workflow.

**Rename and scope-tighten:**
- `project-conventions.md` is partly WSL-specific (overlaps with `wsl-shell-commands.md`), partly architecture decisions, partly command logging. Consider splitting:
  - Architecture and domain conventions → keep in `project-conventions.md`
  - Command output logging and reusable scripts → merge into `wsl-shell-commands.md`

**Add (new file recommended):**
- `agent-boundaries.md` — A short file that explicitly tells the agent what it MUST NOT do autonomously, mirroring the pattern used in Cursor's `cursorrules-2026-best-practices.md`:
  - Never commit without a passing test run (unless checkpoint-flagged)
  - Never delete config files without explicit confirmation
  - Never use `--ours` or `--theirs`
  - Never rebase or force-push main
  - Never modify tests to make them pass
  - Always stop and ask on genuine conflicts (with the 2-minute / 20-hour framing)

This belongs as its own file because it needs `inclusion: always` and should be the shortest, sharpest document in your steering set — the first thing an agent reads, and the hardest constraints stated plainly.

---

## 9. The Cross-Agent Future: What to Prepare For

1. **AGENTS.md as your canonical source.** The fragmentation between `.kiro/steering/`, `CLAUDE.md`, `.cursorrules` is being resolved at the industry level. AGENTS.md is winning. Maintain your Kiro steering as the authoritative system, but export a summary AGENTS.md for portability.

2. **Git worktrees as first-class workflow.** Cursor 3.0's Agents Window (April 2026) treats worktrees as primitives. The pattern of one worktree per agent task will become standard. Your `scripts/branch-check.sh` is the right detective control today; plan for a worktree-based preventive control when Kiro adds native multi-agent support.

3. **Automated PR review by agents.** Codex reviews 100% of PRs at OpenAI. This pattern is coming to all tools. Your Tier 1/2/3 security review framework maps directly onto this — it just needs to be triggered pre-PR-open rather than post-commit in those cases.

4. **SKILL.md as the cross-agent skill standard.** Skills (reusable procedural instructions with YAML frontmatter) are converging on a cross-tool format. Your Kiro hooks are the equivalent. Consider migrating the most reusable ones to SKILL.md format for portability.

---

## 10. Summary: The 10 Non-Negotiable Rules (Universal Across All Agents)

These are the rules that every practitioner source, every platform's own documentation, and every failure post-mortem converges on:

1. **Every task gets its own branch.** No exceptions. Never commit directly to main.
2. **Create a defensive checkpoint before any multi-file refactor.** This is your rollback point.
3. **Commit every meaningful checkpoint within a branch** (code compiles + affected tests pass + lint clean). Do not let passing states sit uncommitted.
4. **Never let a session end with uncommitted work.** Stash or commit before the context boundary.
5. **One branch per feature area.** Check for existing branches before creating. Merge-and-delete after merging.
6. **Per-file conflict resolution only.** Never `--ours` or `--theirs` blanket resolution.
7. **Test before commit.** Never commit code that makes existing tests fail (unless the commit is explicitly a checkpoint).
8. **Never modify tests to make them pass.** Fix the implementation.
9. **Stop and ask on genuine conflicts.** A confident wrong guess is the expensive failure mode.
10. **Variant search after every bug fix.** The reported instance is rarely the only one.

---

*Research compiled from: Kiro official docs, Claude Code best practices community repos, Cursor community guidelines, OpenAI Codex documentation, GitHub Copilot architecture docs, Simon Willison's Agentic Engineering Patterns guide, Augment Code multi-agent research, DAPLab agent failure pattern analysis, and practitioner write-ups across DEV, Medium, and AWS Builder Center. All sources verified June 2026.*
