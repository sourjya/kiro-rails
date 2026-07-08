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
| `.kiro/hooks/*.kiro.hook` (`when.type`) | `.claude/settings.json` `hooks.{Event}` | Event remap: `userPromptSubmit`->`UserPromptSubmit`, `fileEdit`/`fileEdited`/`fileSave`/`postToolUse`->`PostToolUse` (matcher `Edit\|Write\|MultiEdit`), `agentStop`/`stop`->`Stop`, `preToolUse` (`toolTypes: ["shell"]`)->`PreToolUse` (matcher `Bash`). `preTaskExecution` has no Claude event - **approximated** with `PreToolUse` (matcher `Edit\|Write\|MultiEdit`) gated on the stdin payload's `.tool_input.file_path` matching a UI extension (`.tsx`/`.jsx`/`.css`/`.scss`); see "Kiro preTaskExecution" below. |
| `.kiro/hooks/*.kiro.hook` (`then.type`) | `hooks[].command` | `runCommand` -> the command verbatim. `askAgent` -> the prompt is written to `.claude/hooks/prompts/<hook>.txt` and the command becomes `cat <that file>`; Claude surfaces hook stdout to the model, which is how an "ask the agent" hook is emulated. |
| Kiro `beforeCommit` hooks | (no git-commit event in Claude) | Approximated: `PreToolUse` matcher `Bash`, wrapped in a guard that reads the hook's stdin payload and matches `.tool_input.command` against `git commit` / `git-commit-push.sh`. Emits `OK` otherwise. |
| `.kiro/agents/*.json` | `.claude/agents/*.md` (subagents) | JSON -> markdown frontmatter (`name`, `description`, `tools`) + body from the referenced `prompt` file. The **`allowedTools`** array is read in preference to `tools` - an agent may *declare* a tool it is not permitted to use (`code-security-reviewer` lists `shell` but disallows it), and reading `tools` would hand a sandboxed reviewer `Bash`. Tool names remap: `read`->`Read`, `grep`->`Grep`, `glob`->`Glob`, `shell`->`Bash`, `web_search`->`WebSearch`, `web_fetch`->`WebFetch`. Two Kiro tools have no single counterpart and are **subsumed** by several: `code` (read-only code inspection) -> `Read`/`Grep`/`Glob`, and `knowledge` (retrieval over the agent's `resources:` file globs) -> `Read`/`Glob`. Neither is a write tool; the expansion is de-duplicated, so for the two shipped agents the emitted frontmatter is byte-identical to before the mapping existed. Genuinely unmappable names are dropped and named on stderr. **Fails closed:** if no tool maps, the agent is emitted with `tools: Read` rather than no `tools:` line - an agent with no `tools:` frontmatter would inherit *every* tool, silently turning a sandboxed reviewer into a fully privileged one. |
| `.kiro/prompts/*.md` (manual review prompts) | `.claude/commands/*.md` (slash commands) | `description` is read from the prompt's own frontmatter (folded YAML `>` scalars supported) and the source frontmatter is stripped from the body, so exactly one frontmatter block is emitted. Prompts with no `description:` are warned about - Claude routes slash commands by description, so a missing one degrades routing. |
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
- Kiro pre-commit hooks have no Claude commit event; they are *approximated* with a `PreToolUse`/`Bash` hook that self-gates on the payload naming a commit (see the mapping table). Corrected 2026-07-08: this line previously read "not auto-translated", which contradicted the mapping table.
- **Kiro `preTaskExecution` (`ux-preflight-gate`) fires per UI-file write, not per spec task.** Claude has no per-task event, so the gate is approximated with `PreToolUse` (matcher `Edit|Write|MultiEdit`) gated on `.tool_input.file_path` matching `.tsx`/`.jsx`/`.css`/`.scss`. Trade-off: Kiro fires this once per spec task; the Claude version fires on *every* UI-file write, so it is strictly noisier. It is not a false gate - the hook is non-blocking by design ("Do not block the task - just ensure the intent is documented before coding begins"), the guard exits 0 on both paths, and a write to a `.tsx` file is precisely the moment coding begins. Consequence: the hook's own prompt still opens by asking the agent to decide whether the task is UI work, which the file-path guard has already decided; that branch is now dead but harmless, and the prompt is left unedited because `.kiro/` is the source of truth and Kiro still needs it. See KRL-9.
- **`askAgent` hooks don't translate to Claude command-hooks.** The security tiers (`security-tier1/2/3`) and `spec-validation-gate` use `then.type: askAgent` (a Kiro action that hands the agent a prompt). Claude's hook system runs *commands*, not agent prompts, so the generator skips these (they have no `then.command`). They are now all valid JSON (fixed 2026-06-05 - the security hooks had unescaped newlines in string values; `spec-validation-gate` was YAML and is now JSON on the `when`/`fileEdited` schema), so JSON tooling parses them cleanly; they're simply not command-translatable.
- A `.mcp.json` is only generated when at least one MCP server is enabled in `.kiro/settings/mcp.json` (the shipped template's lone server is `disabled`, so no `.mcp.json` is produced by default).
- The `PreToolUse` guard requires `jq` at runtime; if absent it fails open (no block).
- The guard strips quoted spans and heredoc bodies before matching (so commit messages or `echo`/docs that merely mention `git -C` aren't blocked), and its destructive-git path check only considers genuine absolute-path arguments at a word boundary (so branch names like `fix/x`, refs like `origin/main`, and URLs aren't misread as cross-repo paths). Trade-off: a cross-repo git hidden inside a quoted command substitution (e.g. `"$(git -C /other ...)"`), or one using a relative path without `-C`, would not be blocked. Bare cross-repo invocations - the realistic accident - are still caught.
