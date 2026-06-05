# Kiro -> Claude Code Compatibility Analysis

**Date:** 2026-06-05
**Question:** Claude Code sessions report that "most kiro-rails stuff is not compatible and needs to be rebuilt for Claude." Is that true, and what do we ship to close the gap?

## Verdict

Partly true. kiro-rails artifacts fall into three buckets:

| Bucket | Artifacts | Status |
|---|---|---|
| **Portable as-is** | `docs/` taxonomy, templates, the prose *content* of steering/prompts/skills | Work in any tool. No change needed. |
| **Portable via concatenation** | Steering files (`inclusion: always`) | Already handled - `export-to-tools.sh` concatenates them into `.claude/CLAUDE.md`. |
| **Needs format translation** | Hooks, agents, prompts-as-commands, MCP config, conditional steering | This is the real gap. Different files, different schemas. Claude does not read `.kiro/`. |

So Claude users were right that hooks/agents don't "just work" - but the fix is a **generator**, not a rewrite. Kiro files stay the single source of truth; we emit a native `.claude/` tree from them.

## Mapping table

| Kiro artifact | Claude Code equivalent | Translation |
|---|---|---|
| `.kiro/steering/*.md` `inclusion: always` | `.claude/CLAUDE.md` (project memory) | Concatenate (overrides first). |
| `.kiro/steering/*.md` `inclusion: fileMatch` | (no native conditional include) | **Degrades** - folded into CLAUDE.md as always-on, or promote to a skill. Documented limitation. |
| `.kiro/steering/*.md` `inclusion: manual` | `.claude/commands/*.md` or skill | Manual-load rule becomes an explicit command/skill. |
| `.kiro/hooks/*.kiro.hook` (`when.type`) | `.claude/settings.json` `hooks.{Event}` | Event remap: `userPromptSubmit`->`UserPromptSubmit`, `fileEdit`/`fileSave`->`PostToolUse` (matcher `Edit\|Write\|MultiEdit`), `agentStop`/`stop`->`Stop`. |
| Kiro pre-commit hooks | (no git-commit event in Claude) | **Gap** - approximate with `PreToolUse` matcher `Bash` + command regex on `git commit`, or keep as a real git hook. Not auto-translated. |
| `.kiro/agents/*.json` | `.claude/agents/*.md` (subagents) | JSON -> markdown frontmatter (`name`, `description`, `tools`) + body from the referenced `prompt` file. Tool names remap: `read`->`Read`, `grep`->`Grep`, `glob`->`Glob`, `shell`->`Bash`; `knowledge` has no Claude tool (dropped). |
| `.kiro/prompts/*.md` (manual review prompts) | `.claude/commands/*.md` (slash commands) | Add `description` frontmatter; body is portable. |
| `.kiro/skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` | **Format is compatible** - copy as-is. |
| `.kiro/settings/mcp.json` | `.mcp.json` (project root) | Translated: enabled servers pass through (`command`/`args`/`env`); `disabled` servers are omitted; `autoApprove` tools become `settings.json` `permissions.allow` (`mcp__<server>__<tool>`). |

## Claude-only capability we exploit

Claude's `PreToolUse` hook can **block** a tool call before it runs (exit code 2). Kiro's hook model has no pre-Bash gate. We use this to turn the `session-isolation.md` rules from *advice* into *enforcement*: `.claude/hooks/guard-bash.sh` hard-blocks `git -C` / destructive git that targets paths outside the project root - exactly the planiq cross-repo corruption incident. **This is why session isolation was built before the Claude layer:** the Claude layer is where those rules become mechanically enforced.

## What we ship (the "BONUS for Claude")

1. `scripts/export-to-claude.sh` - generator (single source of truth = `.kiro/*`). Emits `.claude/{CLAUDE.md, settings.json, hooks/guard-bash.sh, agents/, commands/, skills/}` plus a project-root `.mcp.json` when MCP servers are enabled.
2. `scripts/claude-guard-bash.sh` - the `PreToolUse` cross-repo git guard (copied into `.claude/hooks/` by the generator).
3. A **committed** generated `.claude/` tree (zero-step for cloners), kept fresh by:
4. `scripts/check-claude-fresh.sh` - regenerates to a temp dir and diffs against the committed `.claude/`; non-zero exit on drift. Run before tagging a release (see `versioning.md` checklist).
5. `claude-export-freshness` hook - reminds to re-run the generator when `.kiro/` source changes.

## Known limitations (documented, not hidden)

- `fileMatch` steering becomes always-on in CLAUDE.md (no native conditional include).
- Kiro pre-commit hooks are not auto-translated (no Claude commit event).
- **`askAgent` hooks don't translate to Claude command-hooks.** The security tiers (`security-tier1/2/3`) and `spec-validation-gate` use `then.type: askAgent` (a Kiro action that hands the agent a prompt). Claude's hook system runs *commands*, not agent prompts, so the generator skips these (they have no `then.command`). They are now all valid JSON (fixed 2026-06-05 - the security hooks had unescaped newlines in string values; `spec-validation-gate` was YAML and is now JSON on the `when`/`fileEdited` schema), so JSON tooling parses them cleanly; they're simply not command-translatable.
- A `.mcp.json` is only generated when at least one MCP server is enabled in `.kiro/settings/mcp.json` (the shipped template's lone server is `disabled`, so no `.mcp.json` is produced by default).
- The `PreToolUse` guard requires `jq` at runtime; if absent it fails open (no block).
- The guard strips quoted spans and heredoc bodies before matching (so commit messages or `echo`/docs that merely mention `git -C` aren't blocked), and its destructive-git path check only considers genuine absolute-path arguments at a word boundary (so branch names like `fix/x`, refs like `origin/main`, and URLs aren't misread as cross-repo paths). Trade-off: a cross-repo git hidden inside a quoted command substitution (e.g. `"$(git -C /other ...)"`), or one using a relative path without `-C`, would not be blocked. Bare cross-repo invocations - the realistic accident - are still caught.
