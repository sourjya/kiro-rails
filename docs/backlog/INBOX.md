# Request Inbox

The request queue for the **Focus & Branch Discipline** protocol
(`.kiro/steering/focus-and-branch-discipline.md`).

When a request arrives mid-task and it is **not** a refinement of the current
work and **not** an explicit divert order, the agent appends it here, tells you
it's noted, and finishes the current task. After reaching Definition of Done,
the agent drains this queue top to bottom.

**Format**

```
- [ ] YYYY-MM-DD | <request> | context: <what was in progress when it arrived>
```

Mark `[x]` when done and move it to **Done** at the bottom.

---

## Queue

- [ ] 2026-06-05 | Add Claude-specific tooling to kiro-rails (skills, subagents, slash commands, hooks via settings.json, CLAUDE.md export) keeping parity with the Kiro tools | context: filed while building the focus-and-branch-discipline feature
- [ ] 2026-06-05 | Complete the README hook/steering tables - several shipped hooks (ux-preflight-gate, spec-validation-gate) and the ux/steering files are missing from the README tables and the headline counts drift from install.sh; also reconcile install.ps1 drift vs install.sh (ps1 missing spec-* skills, export-to-tools.sh, agents) | context: noticed while wiring this feature into install.sh
- [ ] 2026-06-05 | Concurrent-session / cross-repo isolation steering - prevent one Claude/Kiro session from mutating another repo's git (shared working tree, colliding checkouts/commits across projects). Rules: stay within your own repo root, use git worktrees for parallel work, never `cd` into a sibling project, detect foreign actors on the working tree | context: reported by planiq - another agent session reached into the planiq repo and corrupted git state

- [ ] 2026-06-05 | Fix 4 hook files that are not strict-JSON parseable (fail jq + python json): security-tier1-precommit, security-tier2-feature, security-tier3-sprint have raw newlines inside JSON strings; spec-validation-gate uses YAML frontmatter instead of JSON. They're skipped by export-to-claude.sh so the Claude layer loses them | context: discovered while building the Claude bonus layer generator

## Done

<!-- move completed items here with [x] and the date completed -->
