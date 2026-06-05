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


## Done

- [x] 2026-06-05 | Concurrent-session / cross-repo isolation - DONE in v0.11.0 (session-isolation.md steering + scripts/session-guard.sh + session-guard-check hook; Claude PreToolUse guard added in v0.12.0 actually blocks cross-repo git).
- [x] 2026-06-05 | Claude-specific tooling parity - DONE in v0.12.0 (export-to-claude.sh generates .claude/ with settings.json hooks, subagents, slash commands, skills, CLAUDE.md + PreToolUse guard). Remaining gap split out as the MCP-translation item above.
- [x] 2026-06-05 | README hook/steering tables + headline counts - DONE in v0.12.0 (fixed hooks 17->18 and docs dirs 14->13, added the ux-preflight-gate/spec-validation-gate rows, corrected stale ux-expert-persona -> ux-pattern-registry). install.ps1 parity split out as its own item above.
- [x] 2026-06-05 | Reconcile install.ps1 drift vs install.sh - DONE: ps1 now identical to sh (added spec-validation-gate hook, 4 spec skills, export-to-tools.sh, 4 spec-skill dirs; removed bogus ux-expert-persona.md entry). Verified MANAGED 68=68, DIRS 27=27, all paths exist.
- [x] 2026-06-05 | Translate MCP config in export-to-claude.sh - DONE: enabled servers -> project-root .mcp.json (command/args/env; disabled omitted), autoApprove -> settings.json permissions.allow (mcp__server__tool). check-claude-fresh now verifies .mcp.json too. Logic tested against a sample enabled config; template's disabled server correctly yields no .mcp.json.
- [x] 2026-06-05 | Refine Claude PreToolUse guard false positives - DONE: now strips heredoc bodies + quoted spans before matching, so commit messages/echo that mention `git -C` aren't blocked. Tested 5 cases (bare cross-repo + cd-other still BLOCK; message/heredoc/in-repo ALLOW). Trade-off documented.
- [x] 2026-06-05 | Fix 4 non-JSON hook files - DONE: security-tier1/2/3 re-serialized (escaped newlines in string values), spec-validation-gate converted from YAML to JSON on the when/fileEdited schema. All 18 hooks now parse as strict JSON (jq + python). They use askAgent so remain Claude-untranslatable, but cleanly (documented in the compatibility doc).
- [x] 2026-06-05 | Installer self-cleanup - DONE in v0.12.1: both installers remove their own bootstrap file when run as a downloaded script, no-op when piped, never delete a git-tracked install.sh/ps1 (tested all 3 cases). README Windows commands simplified (dropped redundant Remove-Item).
- [x] 2026-06-05 | Release v0.10.0-v0.12.0 - DONE: pushed main to origin (GitHub) + codecommit mirror, tagged v0.10.0/v0.11.0/v0.12.0, cut GH release https://github.com/sourjya/kiro-rails/releases/tag/v0.12.0, roadmap Current Version + Completed table updated.
