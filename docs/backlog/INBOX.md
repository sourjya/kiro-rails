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

- [ ] 2026-06-05 | Complete the README hook/steering tables - several shipped hooks (ux-preflight-gate, spec-validation-gate) and the ux/steering files are missing from the README tables and the headline counts drift from install.sh; also reconcile install.ps1 drift vs install.sh (ps1 missing spec-* skills, export-to-tools.sh, agents) | context: noticed while wiring this feature into install.sh
- [ ] 2026-06-05 | Fix 4 hook files that are not strict-JSON parseable (fail jq + python json): security-tier1-precommit, security-tier2-feature, security-tier3-sprint have raw newlines inside JSON strings; spec-validation-gate uses YAML frontmatter instead of JSON. They're skipped by export-to-claude.sh so the Claude layer loses them | context: discovered while building the Claude bonus layer generator
- [ ] 2026-06-05 | Refine the Claude PreToolUse guard (claude-guard-bash.sh) to reduce false positives - it currently pattern-matches the whole command string, so the trigger text appearing inside a quoted string / heredoc (e.g. a commit message that mentions the `-C` flag) is wrongly blocked. Consider matching only command-leading positions or parsing the command | context: hit this live while committing the Claude bonus layer - the guard blocked its own commit message
- [ ] 2026-06-05 | Translate MCP config (.kiro/settings/mcp.json -> .mcp.json) in export-to-claude.sh - the only Claude-parity surface not yet generated | context: deferred during the Claude bonus layer build (noted in the compatibility doc)

## Done

- [x] 2026-06-05 | Concurrent-session / cross-repo isolation - DONE in v0.11.0 (session-isolation.md steering + scripts/session-guard.sh + session-guard-check hook; Claude PreToolUse guard added in v0.12.0 actually blocks cross-repo git).
- [x] 2026-06-05 | Claude-specific tooling parity - DONE in v0.12.0 (export-to-claude.sh generates .claude/ with settings.json hooks, subagents, slash commands, skills, CLAUDE.md + PreToolUse guard). Remaining gap split out as the MCP-translation item above.
