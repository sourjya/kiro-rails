# Findings → Kiro-Rails Translation Map

**Date:** 2026-05-21
**Purpose:** Map each bug pattern finding to the optimal Kiro mechanism, with justification for why that mechanism (not another) is the right fit.

---

## Kiro Mechanisms Available (Current State of the Art)

| Mechanism | What It Does | When It Fires | Cost |
|---|---|---|---|
| **Steering (always)** | Persistent rules loaded every interaction | Every chat turn | Free (context tokens) |
| **Steering (fileMatch)** | Rules loaded only when working with matching files | File pattern match | Free |
| **Steering (auto)** | Rules loaded when request matches description | Semantic match | Free |
| **Steering (manual)** | Rules loaded on-demand via `/name` | User invokes | Free |
| **Skills (SKILL.md)** | On-demand instruction packages, auto-activate by description | Semantic match or `/slash` | Free (context tokens) |
| **Hooks: Pre Tool Use** | Intercept before agent uses a tool (can block) | Before tool call | Shell=free, Agent=credits |
| **Hooks: Post Tool Use** | Run after agent uses a tool | After tool call | Shell=free, Agent=credits |
| **Hooks: File Save** | Run when files matching pattern are saved | File save | Shell=free, Agent=credits |
| **Hooks: File Create** | Run when new files are created | File create | Shell=free, Agent=credits |
| **Hooks: Agent Stop** | Run after agent finishes responding | End of turn | Shell=free, Agent=credits |
| **Hooks: Pre Task Execution** | Run before a spec task begins | Task starts | Shell=free, Agent=credits |
| **Hooks: Post Task Execution** | Run after a spec task completes | Task completes | Shell=free, Agent=credits |
| **Hooks: Prompt Submit** | Append to user prompt or block it | User sends message | Shell=free, Agent=credits |
| **Hooks: Manual Trigger** | On-demand execution | User invokes | Shell=free, Agent=credits |
| **Custom Agents** | Restricted tool access, custom prompts, specific MCP servers | Agent swap | Free |
| **Specs (Feature)** | requirements.md → design.md → tasks.md | Feature work | Free |
| **Specs (Bugfix)** | Root cause → fix design → regression prevention | Bug work | Free |
| **Specs (Quick Plan)** | Auto-generate all three in one pass | Rapid prototyping | Free |
| **Powers** | Packaged tools + steering + MCP for specific workflows | Keyword activation | Free |
| **Prompts** | Reusable review/audit prompts (manual trigger) | User invokes | Credits |

---

## Translation Map: Finding → Mechanism

### Finding #1: Incomplete Implementation

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Hook: Post Task Execution** | Fires after EVERY spec task completes. Agent prompt asks: "Verify this task has: error state, loading state, empty state, persistence across reload, undo for destructive actions. If any are missing, add them before marking complete." This catches incompleteness at the atomic task level. |
| **Secondary** | **Steering (always)** | Add a "Completeness Checklist" section to existing `testing-standards.md`. Always-on means the agent sees it every turn. But steering alone is passive — the agent can ignore it under pressure. |
| **Why not a skill?** | Skills activate on semantic match. Completeness applies to ALL implementation, not a specific workflow. Always-on steering + post-task hook is more reliable. |

---

### Finding #2: API Response Shape Mismatch

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (fileMatch)** | New file `api-contract-discipline.md` with `fileMatch: ["**/api/**", "**/routes/**", "**/services/**/*.ts", "**/hooks/use*.ts"]`. Loads when touching API or frontend service files. Rules: "Define response type FIRST, implement both sides against it, never assume shape." |
| **Secondary** | **Hook: File Create** on `**/api/**` or `**/routes/**` | When a new API route is created, prompt: "Define the response TypeScript interface/Pydantic schema for this endpoint before implementing the handler." |
| **Why not always-on steering?** | This is a large rule set that only matters when working on API boundaries. fileMatch keeps context lean for non-API work. |

---

### Finding #3: Auth/SSO Flow Errors

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Skill: `auth-implementation`** | A dedicated SKILL.md that activates when the agent detects auth/SSO/OIDC/OAuth keywords. Contains the full checklist: all paths (happy, expired, missing session, provider quirks, redirect loop prevention, graceful degradation). Skills are the right fit because auth is a specialized domain that doesn't need to load for every interaction. |
| **Secondary** | **Steering (auto)** | `auth-flow-completeness.md` with `inclusion: auto` and description "Authentication, SSO, OAuth, OIDC implementation patterns." Auto-loads when relevant. |
| **Why not always-on?** | Auth rules are large and only relevant during auth work. Loading them every turn wastes context on non-auth tasks. |

---

### Finding #4: Race Conditions / Async Timing

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (always)** | Add to `error-handling-performance.md`. These rules are short and universally applicable: "Use `mutateAsync` + await for dependent operations. Never block async event loops with sync I/O." Always-on because race conditions can appear in ANY code. |
| **Why not a hook?** | Race conditions are design-time decisions, not something detectable by a post-save or post-task check. The agent needs to know the rule BEFORE writing the code. |

---

### Finding #5: Event Propagation / Handler Conflicts

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (fileMatch)** | New section in a file with `fileMatch: ["**/*.tsx", "**/*.jsx"]`. Rules about event propagation, DnD listener scoping, React synthetic vs native events. Only loads for React/frontend work. |
| **Secondary** | **Skill: `event-handling`** | For complex event system work (DnD, keyboard shortcuts, modals). Activates on "drag and drop", "event handler", "keyboard shortcut", "escape key" keywords. |
| **Why not always-on?** | Event propagation rules are frontend-specific. Backend-only work shouldn't pay the context cost. |

---

### Finding #6: CSS/Layout Issues

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (fileMatch)** | Add to a file with `fileMatch: ["**/*.css", "**/*.tsx", "**/*.jsx", "**/*.scss"]`. Rules: "Set `min-h-0` + `overflow-hidden` on flex intermediates. Use same layout strategy for header and body. Verify popover positioning matches trigger location." |
| **Why not a hook?** | CSS issues are design-time. The agent needs the rules before writing styles, not after. |

---

### Finding #7: Missing State Persistence

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (always)** | Add to `reusable-architecture.md`. Short rule: "For any state that must survive reload, explicitly choose persistence mechanism. Module-level variables are ephemeral." Universal because persistence decisions happen across all code. |
| **Secondary** | **Hook: Post Task Execution** | After task completion, prompt: "Does this task introduce any state? If yes, will it survive page reload? If not, is that intentional?" |
| **Why always-on?** | Persistence is a cross-cutting concern. Every feature can introduce state that needs persistence consideration. |

---

### Finding #8: Platform/Packaging Misunderstanding

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Hook: Post Tool Use** on `write` tool, matching `package.json` or `pyproject.toml` | After writing to package manifests, shell command runs `npm pack --dry-run 2>&1 | head -20` or equivalent to verify the published artifact includes expected files. Deterministic, no credits. |
| **Secondary** | **Steering (fileMatch)** | `fileMatch: ["**/package.json", "**/pyproject.toml", "**/tsup.config.*", "**/vite.config.*"]`. Rules about verifying `files` array, bin entries, build output paths. |
| **Why a hook?** | This is verifiable mechanically. A shell hook can actually run `npm pack --dry-run` and catch missing files before they ship. Steering alone is passive. |

---

### Finding #9: Copy-Paste / Forgotten Config Updates

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (always)** | Add to `change-discipline.md`. Short rule: "After copying code from another context, review EVERY field/value. Check defaults, identifiers, paths, URLs." Always-on because copy-paste happens everywhere. |
| **Why not a hook?** | Copy-paste is undetectable by hooks — there's no "paste" event. The agent needs the discipline rule in context before it copies. |

---

### Finding #10: Stale State / Caching Issues

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (fileMatch)** | `fileMatch: ["**/hooks/use*.ts", "**/queries/**", "**/services/**"]`. Rules: "When setting staleTime, document invalidation scenarios. After mutations, verify cache invalidation." Loads when working on data-fetching code. |
| **Why fileMatch?** | Caching rules only matter when writing React Query hooks or service layers. Not relevant for backend-only or CSS work. |

---

### Finding #11: Iterative Debugging Spirals

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (always)** | Add to `change-discipline.md`. Rule: "If fix #1 introduces a new failure, STOP. Map ALL code paths through the system before attempting fix #2. Never chain 3+ fixes for the same issue without stepping back." Always-on because this is a behavioral discipline, not domain-specific. |
| **Secondary** | **Hook: Agent Stop** | After agent finishes a turn, shell script checks git log for 3+ consecutive `fix:` commits on the same topic. If detected, inject warning: "You appear to be in a fix spiral. Step back and map the full system." |
| **Why both?** | Steering provides the rule. The hook provides mechanical detection when the agent violates it anyway. |

---

### Finding #12: React Hooks / Lifecycle Violations

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (fileMatch)** | `fileMatch: ["**/*.tsx", "**/*.jsx"]`. Rules: "ALL hooks at top of component, before any early returns. Verify required providers exist in ancestor tree." |
| **Secondary** | **Hook: File Save** on `*.tsx` | Shell command: run ESLint with `react-hooks/rules-of-hooks` rule on saved file. Block if violations found. Zero credits, deterministic. |
| **Why fileMatch + shell hook?** | fileMatch gives the agent the rule. The shell hook catches violations mechanically without LLM cost. |

---

### Finding #13: Missing Dependencies / Wiring

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Hook: Post Tool Use** on `write` tool | After writing any source file, shell command checks for new imports and verifies they resolve. For Python: `python -c "import X"`. For TS: `tsc --noEmit` on the file. |
| **Secondary** | **Steering (always)** | Add to `change-discipline.md`: "After adding any import, verify the dependency is declared in the manifest." |
| **Why a hook?** | Missing dependencies are mechanically detectable. A type-check or import-check after writes catches them immediately. |

---

### Finding #14: Security Gaps

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Existing hooks** (security-tier1-precommit already exists) | Strengthen the existing pre-commit hook to also check for: exception details in API responses, missing input validation on new endpoints, CSP headers. |
| **Secondary** | **Steering (always)** | Add to `error-handling-performance.md`: "All API error responses use generic messages. Never expose exception details, stack traces, or internal paths." |
| **Why strengthen existing?** | kiro-rails already has a 3-tier security review system. The gap is that Tier 1 doesn't catch info leakage. Extend it rather than adding new mechanisms. |

---

### Finding #15: AI-Generated Comments Breaking Code

| Approach | Mechanism | Justification |
|---|---|---|
| **Primary** | **Steering (always)** | Add to `code-commenting-standards.md`: "Never include unescaped `*/` or `/*` sequences inside comments. Escape glob patterns and regex that contain comment-closing sequences." |
| **Secondary** | **Hook: File Save** on `*.ts, *.tsx, *.py` | Shell command: grep for `*/` inside JSDoc blocks or `/*` patterns that could break parsing. Warn if found. |
| **Why both?** | Steering prevents it. Hook catches it if the agent slips. |

---

## Implementation Plan (Approved)

### New Steering Files

| File | Inclusion | Content |
|---|---|---|
| `frontend-patterns.md` | `fileMatch: ["**/*.tsx", "**/*.jsx"]` | React hooks rules, event propagation, CSS flex/grid gotchas, cache invalidation for React Query |
| `api-contract-discipline.md` | `fileMatch: ["**/api/**", "**/routes/**", "**/services/**"]` | Contract-first development, response shape verification |

### Modifications to Existing Steering Files

| File | Additions |
|---|---|
| `error-handling-performance.md` | Async discipline (mutateAsync + await), generic error responses, rate limit guidance |
| `reusable-architecture.md` | State persistence rule |
| `change-discipline.md` | Fix depth rule, copy-paste verification, package manifest verification |
| `code-commenting-standards.md` | Comment-safe patterns (no unescaped `*/`) |

### New Skills

| Skill | Activates On | Content |
|---|---|---|
| `.kiro/skills/auth-implementation/SKILL.md` | "auth", "SSO", "OAuth", "OIDC", "login", "redirect", "token" | Full auth flow checklist: happy path, expired token, missing session, provider quirks, redirect loop prevention (max 2), graceful degradation |

### New Hooks

| Hook | Type | Action | Details |
|---|---|---|---|
| `fix-spiral-detector` | UserPromptSubmit | Shell | Check `git log --oneline -5` for 3+ consecutive fix commits. If detected, append warning to context. |
| `type-check-on-stop` | Agent Stop | Shell | Run `tsc --noEmit 2>&1 \| head -20`. Warn agent if type errors found. |
| `package-manifest-verify` | Post Tool Use (write) on `package.json`/`pyproject.toml` | Shell | Run `npm pack --dry-run` or equivalent to verify published artifact. |

### Template Modification

| Template | Change |
|---|---|
| `.kiro/templates/tasks-template-tdd.md` | Add mandatory final phase: "Completeness Verification" — verify error/loading/empty states, persistence across reload, undo for destructive actions |

### Existing Hooks to Strengthen

| Hook | Enhancement |
|---|---|
| `security-tier1-precommit` | Add checks for: exception details in API responses, missing input validation on new endpoints |
| `comment-standards-check` | Add check for unescaped `*/` inside comment blocks |

---

## Final Decisions (Approved 2026-05-21)

### Decision 1: fileMatch for frontend rules
**Choice:** New `frontend-patterns.md` with `fileMatch: ["**/*.tsx", "**/*.jsx"]`
**Rationale:** Avoids polluting backend context with React/CSS rules. Only loads when working on frontend files.

### Decision 2: Completeness check mechanism
**Choice:** Bake into the TDD task template as a mandatory final phase
**Rationale:** No hook needed. Every spec's tasks.md gets a final phase: "Phase N: Completeness Verification — verify error/loading/empty states, persistence across reload, undo for destructive actions." The agent executes it as a normal task. Zero noise, guaranteed execution because it's part of the spec workflow.
**Rejected:** Post Task Execution hook (too noisy — fires after every task), manual trigger (easy to forget).

### Decision 3: Auth implementation guidance
**Choice:** Skill (`.kiro/skills/auth-implementation/SKILL.md`)
**Rationale:** Skills work in both IDE and CLI. Auth is a specialized domain with large context that shouldn't load every turn. Activates on keywords: "auth", "SSO", "OAuth", "OIDC", "login", "redirect", "token".
**Rejected:** Steering (auto) — skills are more portable and follow the open Agent Skills standard.

### Decision 4: Import/type resolution check
**Choice:** Agent Stop hook with shell action: `tsc --noEmit 2>&1 | head -20`
**Rationale:** Runs once after the agent finishes its full response (which may include multiple file writes). ~3-5s on most projects. If it fails, stderr warns the agent. Not per-file (too frequent), not pre-commit (too late).
**Rejected:** Post Tool Use on write (too frequent), File Save (still too frequent), Pre-commit (feedback too late).

### Decision 5: Fix spiral detector
**Choice:** UserPromptSubmit hook with shell action checking `git log --oneline -5`
**Rationale:** Runs when the user sends a message — checks if 3+ consecutive `fix:` commits exist on the same topic. If detected, appends a warning to the prompt context. Zero overhead during autonomous agent execution. Only fires on human interaction.
**Rejected:** Agent Stop (100ms every turn), Pre Tool Use on write (annoying mid-flow).

---

## Sources

- [kiro.dev/docs/steering](https://kiro.dev/docs/steering/) — Inclusion modes (always, fileMatch, auto, manual)
- [kiro.dev/docs/hooks](https://kiro.dev/docs/hooks/) — IDE hook types and actions
- [kiro.dev/docs/cli/hooks](https://kiro.dev/docs/cli/hooks/) — CLI hook types (AgentSpawn, PreToolUse, PostToolUse, Stop, UserPromptSubmit)
- [kiro.dev/docs/cli/skills](https://kiro.dev/docs/cli/skills/) — Skills format and activation
- [kiro.dev/docs/cli/custom-agents/creating](https://kiro.dev/docs/cli/custom-agents/creating/) — Custom agent configuration
- [kiro.dev/docs/powers/create](https://kiro.dev/docs/powers/create/) — Powers packaging format
- [kiro.dev/docs/specs/bugfix-specs](https://kiro.dev/docs/specs/bugfix-specs/) — Bugfix spec workflow
- [kiro.dev/docs/hooks/best-practices](https://kiro.dev/docs/hooks/best-practices/) — Hook design best practices

---

## Addendum: Periodic Documentation Update Hooks (Approved 2026-05-21)

### Design Rationale

Documentation rots because updates are decoupled from the moment changes happen. The solution is to trigger documentation checks at the exact moment when the relevant context is fresh — not on a schedule, but at natural workflow boundaries.

### Hook 1: Changelog Consolidation Reminder

**Trigger:** UserPromptSubmit (shell)
**Logic:** Check if 10+ commits exist since CHANGELOG.md was last modified. If yes, append a reminder.
**Justification:** Changelogs become useless when they're either a raw commit log or months behind. This catches the sweet spot — enough commits to consolidate meaningfully, triggered at the moment the user starts a new interaction (low noise, high relevance). Shell action = zero credits.
**Noise level:** Near-zero. Only fires when genuinely behind.

### Hook 2: Bug Document Completion Check

**Trigger:** File Save on `docs/bugs/BUG-*.md`
**Logic:** After saving a bug doc, verify all required fields are filled (root cause, fix description, regression tests, status).
**Justification:** Bug docs are created at report time but often abandoned after the fix ships. This fires at the natural moment — when someone edits the bug doc (presumably to update it after fixing). Catches incomplete docs before they go stale. Agent prompt = costs credits but only fires on bug doc edits (rare).
**Noise level:** Low. Only fires when editing bug docs.

### Hook 3: ADR Trigger on Infrastructure Changes

**Trigger:** File Save on infrastructure/config files (`docker-compose.yml`, `**/infrastructure/**`, `Dockerfile`, `*.tf`, `Caddyfile`)
**Logic:** After saving an infrastructure file, ask if this represents an architectural decision worth recording.
**Justification:** ADRs capture the "why" behind decisions. The hardest part is remembering to write them. This fires at the exact moment a decision is being implemented — when context is fresh and the "why" is still in the developer's head. Agent prompt = costs credits but infra file edits are infrequent.
**Noise level:** Low. Infrastructure files change rarely.

### Rejected Alternatives

| Approach | Why Rejected |
|---|---|
| Timer-based (every N hours) | Kiro has no cron/timer trigger. Would require external scheduler. |
| Post Task Execution for arch docs | Too noisy — fires after every spec task, most of which don't change architecture. |
| AgentSpawn stale docs check | Good idea but heavy — scanning all docs for broken links on every session start adds latency. Better as a manual trigger or cached with long TTL. |
| Roadmap sync on tag creation | No "git tag" trigger exists in Kiro hooks. Better as manual `/roadmap-sync` skill. |
