# Changelog

All notable changes to this project will be documented in this file.
Format: consolidated entries grouped by feature, not per-file edits.
Rolling policy: archive to CHANGELOG.YYYY-MM-DD.md when exceeding 500 lines.

## Unreleased

### Security

- **KRL-16 - Redacted internal identifiers leaking from `docs/references/` and the changelog.** The new `leak-scan` tooling, run against kiro-rails itself, found the org name and internal product/codenames (and a few internal-app feature details) in five tracked docs of this publicly-installable template. All were redacted to role-based generics that preserve each doc's meaning: org name → "the org"/"house"; product names → "an internal app"; product categories and specific feature descriptions (e.g. invite/anti-enumeration behaviors, a specific bug list) → neutral equivalents; the internal tracker and product-specific tool/filenames in the cross-repo audit → generic descriptors. kiro-rails' own `KRL-NN` ticket refs are kept (self-references). Variant search: scanned all tracked files for the full Tier-A/B term set plus the redacted feature phrases - 0 remaining. **Caveat:** these names persist in the git *history* of the affected files; removing them there needs a deliberate, confirm-first history rewrite, not covered here.

## 2026-07-17 - v0.18.0 - Claude Layer: Fidelity, Discoverability, Activation

Adapts the generated Claude Code layer to the upgraded Kiro prompt set: broken
cross-references are rewritten, the whole toolbox is made discoverable through a
generated index skill, every source→target translation is recorded in an
auto-emitted sync ledger, and the installers now actually deliver and activate the
layer. Also bumps the installers off their stale 0.15.0 pin and adds them to the
version-file list so they stop drifting.

### Fixed (installers)

- **KRL-13 - `install.sh`/`install.ps1` manifest drift + no `.claude/` on install.** Two distribution defects. (1) The managed-file manifests had fallen behind `.kiro/`: `review-ux-live` (prompt), `incident-response` and `review-guide` (skills), and `ux-reviewer` (agent) were never downloaded, so target projects silently missed the newest capabilities. All four are added to both installers, with their skill directories added to the created-dirs lists. (2) Both installers *shipped* `scripts/export-to-claude.sh` but never ran it, so the native Claude Code layer was never generated on install - a Claude Code user got nothing until they discovered the script by hand. Both installers now run the export at the end (bash+jq; on Windows via Git Bash/WSL), **non-fatally** (the `.kiro/` files are already placed, so a generation hiccup cannot fail the install) and print the one command to run when jq/bash is absent. A `jq` row was added to the dependency check, and the fresh-install next-steps now `git add .claude/ .mcp.json`. Verified end-to-end: a from-working-tree install produces `.claude/` (17 commands, the `kiro-rails` index skill) and the sync ledger with zero download warnings; smoke test passes for both installers.

### Added

- **KRL-15 - Generated `kiro-rails` index skill (agent power-distribution).** kiro-rails' capabilities were not auto-discoverable: review capabilities ship as slash-commands (which the model does not surface on its own), and nothing said "here is everything kiro-rails offers, and when to reach for each." `export-to-claude.sh` now generates `.claude/skills/kiro-rails/SKILL.md` - a single routing index whose description carries discovery triggers, listing every review command, skill, subagent, and the spec-driven workflow, each with a one-line *when-to-use* pulled from that artifact's own frontmatter/description, plus a pointer into the always-loaded `CLAUDE.md` steering. It is derived from the same sources the export already walks (so it can never drift), routes rather than duplicates, and is recorded in the sync ledger under "Generated (no single .kiro source)." Skill count 7 → 8. Deterministic; `check-claude-fresh.sh` OK.
- **KRL-14 - Auto-emitted Kiro→Claude capability sync ledger.** `export-to-claude.sh` now writes `docs/references/kiro-claude-sync-ledger.md` on every run: one row per `.kiro` source artifact (steering, prompt, agent, skill, hook) → its generated Claude target, with the source's **git blob hash**, a **fidelity** grade (`verbatim`/`adapted`/`lossy`/`dropped`), and a note. Hook rows are captured *inline* during translation so the ledger reflects what actually shipped (e.g. the two disabled security hooks show `dropped`; the `beforeCommit`/`preTaskExecution` approximations show `lossy`) rather than a re-derivation that could drift. The ledger is fully deterministic - hashes are of content only, rows are sorted, no timestamp or HEAD is embedded - so a `git diff` on the file names exactly which capabilities moved when a Kiro prompt is upgraded, and `git log -p` of it is the upgrade history. `CLAUDE.md`'s generated header links the ledger so a freshly-started Claude session knows where to look. `check-claude-fresh.sh` now diffs the ledger too (it lives under `docs/`, outside the `.claude/` tree), so drift is caught before release. Verified: two back-to-back generations are byte-identical; a simulated un-regenerated prompt upgrade is reported STALE and the changed prompt's ledger row is named.

### Fixed

- **KRL-12 - Exported Claude artifacts pointed at `.kiro/steering/*.md` paths.** Kiro prompt and steering bodies reference sibling steering docs by their `.kiro/` path (e.g. `` `.kiro/steering/ux-console-idiom.md` ``). On the Claude side steering has no such home - every doc is concatenated into `CLAUDE.md` - so the reference pointed at content the agent would have to re-`Read` instead of the copy already in its context, and dangled entirely where `.kiro/` was not installed beside `.claude/`. `export-to-claude.sh` now builds a filename→H1 map from the steering files themselves and rewrites each **backticked** `` `.kiro/steering/<f>.md` `` to name the `CLAUDE.md` section it now lives under (e.g. *the "UX Console-Idiom Rubric" rules in `CLAUDE.md`*). Applied to both generated `CLAUDE.md` and the review commands (8 references across 4 prompts, plus 1 in `review-policy` inside `CLAUDE.md`). Deterministic, so generated output stays byte-stable for `check-claude-fresh.sh`. Bare-name mentions and HTML-comment notes are intentionally left as-is.

## 2026-07-08 - v0.17.3 - Agent Tool Mapping: Subsumed vs Lost

### Fixed

- **`map_tool()` reported subsumed tools as lost capability.** `code` and `knowledge` were dropped with a "no Claude equivalent" note, implying `code-security-reviewer` and `ux-red-team` had been degraded. They had not. Both tools are read-only and already covered by tools those agents hold: `code` (read-only code inspection) is `Read`/`Grep`/`Glob`; `knowledge` (retrieval over the agent's `resources:` file globs) is `Read`/`Glob`. `map_tool` now expands a Kiro tool to *several* Claude tools and de-duplicates. **The emitted agent frontmatter is byte-identical** (`Read, Grep, Glob` / `Read, Glob, Grep`) - that identity is the proof no privilege changed, and is the reason this is safe. Neither expansion includes a write tool.
- **Variant, latent: `web_search` and `web_fetch` had no mapping either.** `ux-red-team.json` declares both in `tools`. They are not dropped today only because the exporter reads `allowedTools` (which excludes them); promoting either into `allowedTools` would have silently dropped it. Now mapped to `WebSearch`/`WebFetch`.
- The exporter now emits **no agent-tool warning at all**, because nothing shipped is genuinely unmappable. Truly unknown tool names are still dropped and named on stderr, and the fail-closed degrade-to-`Read` path is untouched.

### Corrected

- The v0.17.2 notes and KRL-9 stated that mapping `knowledge`/`code` "would widen the sandbox" of the two restricted agents. **That was wrong.** `export-to-claude.sh:98` already reads `(.allowedTools // .tools)`, so `shell` / `web_search` / `web_fetch` were never eligible for export in the first place. There was no privilege leak to prevent. The real defect was a misleading diagnostic, not a missing guard.

Tickets: KRL-10 (this), KRL-9 (assessment corrected).

## 2026-07-08 - v0.17.2 - UX Preflight Gate Reaches Claude

### Fixed

- **`export-to-claude.sh` silently dropped the `ux-preflight-gate` hook.** Kiro's `when.type: preTaskExecution` has no Claude event, so the hook fell through the `case` to the unmapped branch and its `askAgent` prompt was deleted as an orphan. Claude users got no UX Intent Block gate at all - the hook was enabled in `.kiro/` and simply did not exist in `.claude/`. It is now approximated with a `PreToolUse` hook (matcher `Edit|Write|MultiEdit`) that reads the hook payload's `.tool_input.file_path` and fires only on `.tsx`/`.jsx`/`.css`/`.scss` - the same self-gating stdin trick already used to approximate `beforeCommit`. Exported hook count 18 -> 19.
- **`PreToolUse` could only ever emit one matcher block.** The `jq` assembly hardcoded a single `{matcher: "Bash"}` entry, so any second `PreToolUse` matcher would have overwritten it via object addition. It now builds an array.
- **The compatibility doc claimed pre-commit hooks were "not auto-translated"**, contradicting its own mapping table, which documents the `beforeCommit` approximation. Corrected.

### Notes

- The Claude gate fires **per UI-file write**, where Kiro fires **per spec task** - strictly noisier, but non-blocking by design (the guard exits 0 on both paths). Documented as an accepted fidelity trade-off alongside `beforeCommit`.
- ~~The two dropped agent tools reported by the same stderr warning (`code-security-reviewer:knowledge`, `ux-red-team:code`) are **deliberately not mapped**... inventing a mapping would widen the sandbox.~~ **Superseded by v0.17.3 - this reasoning was wrong.** The exporter already reads `allowedTools`, so no sandbox could have been widened. Both tools are read-only and subsumed; they are now mapped, with byte-identical output. The fail-closed behavior does stay.

Ticket: KRL-9. The issue tracker's `Kiro-Rails` folder gained `Bugs`/`Feature Requests` subfolders; all 9 tickets routed, aliases preserved.

## 2026-07-08 - v0.17.1 - Single Owner for the Claude Layer

### Fixed

- **`export-to-tools.sh --claude` clobbered the generated Claude layer.** Its `export_claude()` wrote `.claude/CLAUDE.md` itself, producing a degraded, differently-headed copy (2633 vs 2652 lines) and leaving `settings.json`, `agents/`, `commands/` and `skills/` untouched. Whichever exporter ran last won.
- **It also made the release gate non-deterministic.** `export-to-tools.sh`'s `header()` stamps `# Generated: <ISO timestamp>` into its output. `.claude/` is a committed artifact byte-compared by `check-claude-fresh.sh`, which `versioning.md` makes a release gate, so *any* run flipped the gate to `STALE` on the timestamp alone - even with no change to `.kiro/`.
- `export_claude()` now delegates to `scripts/export-to-claude.sh`, the single owner of `.claude/`. As a side benefit, `--all` now emits the *full* Claude layer (hooks, agents, commands, skills) rather than a lone degraded `CLAUDE.md`. The three non-gated targets (`.cursorrules`, `.github/copilot-instructions.md`, `AGENTS.md`) keep their timestamped headers.

Verified: `--claude` and `--all` both leave `check-claude-fresh.sh` printing `OK`; two consecutive runs produce byte-identical `.claude/`; no `Generated:` line reaches `CLAUDE.md`. Variant search: no other script under `scripts/` writes to `.claude/`.

Ticket: KRL-8.

## 2026-07-08 - v0.17.0 - Claude Export Fidelity

### Fixed - the generated `.claude/` layer was missing 37% of enabled hooks

- **`askAgent` hooks were silently discarded.** `scripts/export-to-claude.sh` only ever read `.then.command`, so all 7 enabled `then.type: askAgent` hooks vanished with no warning, regardless of `when.type`. This removed the *entire* tiered security review system (Tier 1 pre-commit gate), the comment-standards check, the spec-validation gate, the ADR trigger, the bug-doc completion check, and changelog maintenance from the Claude layer. They are now translated: the prompt is written to `.claude/hooks/prompts/<hook>.txt` and invoked via `cat`, relying on Claude surfacing hook stdout to the model. Exported hooks: **12 -> 18**.
- **`preToolUse` hooks were dropped.** The `when.type` remap handled `postToolUse` but not `preToolUse`, so it fell through the catch-all. Now maps to `PreToolUse` (matcher `Bash`), appended after the cross-repo guard.
- **`beforeCommit` hooks were dropped.** Now approximated as `PreToolUse`/`Bash` gated on the hook's stdin payload matching `git commit` or `git-commit-push.sh`, as the compatibility doc always prescribed but the generator never implemented.
- **No more silent drops.** Untranslatable hooks, unmapped agent tools, and prompts lacking a `description:` are all reported on stderr. `preTaskExecution` (`ux-preflight-gate`) remains the one hook with no Claude analog, and now says so.

### Fixed - agent tool mapping failed open (security)

- If every tool an agent declared was unmappable, `ctools` came out empty and **no `tools:` frontmatter line was emitted at all** - which makes a Claude subagent inherit *every* tool, including `Write` and `Bash`. A Kiro agent deliberately sandboxed to read-only would have become fully privileged. The generator now **fails closed** to `tools: Read` and warns. Latent, not triggered by any shipped agent, but the affected agents (`ux-reviewer`, `ux-red-team`, `code-security-reviewer`, `security-verifier`) exist precisely to be sandboxed.

### Fixed - slash-command routing was broken by malformed descriptions

- The generator derived each command's `description` from the **first non-empty line** of the prompt, yielding `description: "---"` for frontmatter-led prompts, `"<!--"` for comment-led ones, and a sentence truncated mid-word for the rest. Claude routes slash commands and skills by description, so this actively undercut the v0.16.0 Interactive Review Guide.
- `description` is now read from the prompt's own frontmatter (folded YAML `>` scalars supported), and the source frontmatter is stripped from the emitted body so exactly one frontmatter block exists. The same strip applies to agent bodies sourced via `file://`.
- **Added `name:` + `description:` frontmatter to all 14 `.kiro/prompts/*.md` that lacked it.**

### Fixed - versioning

- Backfilled the missing annotated tags **v0.14.0, v0.15.0, v0.16.0** (the changelog documented them; only `v0.13.0` was tagged).
- `.kiro/steering/versioning.md` listed `pyproject.toml` and `package.json` under "Files to Update on Version Bump". Neither exists in this repo, so the step silently never ran. The git tag is now stated as the authoritative version, with the manifest block marked optional and a verification snippet added.

### Changed

- `docs/references/kiro-to-claude-compatibility-2026-06-05.md` - translation table corrected: it claimed pre-commit hooks were "not auto-translated" and omitted `then.type` entirely. Now documents both `when.type` and `then.type` remaps, the fail-closed tool rule, and the `code` tool drop (previously only `knowledge` was noted).

### Known gaps

- `ux-preflight-gate` (`when.type: preTaskExecution`) has no Claude event and is not exported. Warned at generation time.
- Agent tools `knowledge` and `code` have no Claude equivalent and are dropped (Kiro is unaffected - it reads the JSON natively).
- The `file-ticket` skill wants `.claude/ticketing.json`, but `check-claude-fresh.sh` diffs the whole generated tree and would report `STALE`. Tracked as KRL-7; not fixed here because it touches a shared cross-repo skill convention.

Tickets: KRL-3 (hooks), KRL-4 (descriptions), KRL-5 (fail-open tools), KRL-6 (versioning), KRL-7 (ticketing.json).

## 2026-07-08 - v0.16.0 - UX Review Tooling + Interactive Review Guide

### Added - Interactive Review Guide (3-layer onboarding)

- **New `.kiro/skills/review-guide/SKILL.md`** - interactive skill that guides novice users to the right review prompt. Auto-matches on "what reviews should I run?", "which prompt?", "how do I audit?". 3-step protocol: understand context → recommend 1-3 reviews → offer to run. Includes full catalog knowledge (17 prompts), tiered model explanation, and common Q&A.
- **New `.kiro/hooks/review-suggest.kiro.hook`** - prompt-submit hook that detects review-worthy checkpoints (5+ commits with frontend/API/auth changes) and suggests the right review with a one-line nudge. Never blocking, never verbose. Points to `/review-guide` for deeper help.
- **Quick Reference table in `review-policy.md`** - 8-row "you just... → run this" lookup table (~150 tokens) giving the agent ambient awareness to suggest reviews organically in any conversation.
- **"Getting Started with Reviews" section in README** - user-friendly onboarding right below Quick Start. Shows the system is self-guiding: just ask, or keep working and it suggests for you. Includes cheat sheet and tier explanation.

### Added - Console-idiom UX rubric and live browser-walk review

- **New `.kiro/steering/ux-console-idiom.md`** - console-idiom UX quality rubric with 9 check families (D/S/R/V/T/E/C/A/K), 44 checks, severity-weighted scoring (Sev-1 −15, Sev-2 −5, Sev-3 −1), and a ship gate (zero Sev-1 + no page below 70). `inclusion: manual` - loaded on-demand for reviews, not always-on (per context-bloat research evidence).
- **New `.kiro/prompts/review-ux-live.md`** - 9-step per-page live browser-walk protocol with side-effect boundary (observer-only), evidence discipline (5 evidence types with strength ratings), mandatory Corrections/Retractions section, and report structure (6 fixed-order sections). Requires a browser MCP at runtime.
- **New `.kiro/agents/ux-reviewer.json`** - restricted-tool UX auditor agent (read, grep, glob only; no write/delete/send). Enforces the side-effect boundary at the tool-permission layer.
- **New `scripts/style-survey.js`** - in-page computed-style census for quantitative rubric evidence. Collects font-size histogram, weight census, border-radius set, button dimensions, heading hierarchy, nav/tab active states, table alignment, unlabelled form controls, color values, and spacing values. Runnable in DevTools or via browser MCP.
- **New `docs/ux-reviews/` taxonomy directory** - UXR report placement rules, gate definition, and cross-references.
- **Design tokens section in `user-project-overrides.md`** - placeholder block for team-specific UX rubric thresholds (typography, surfaces, consistency, save model, tables, timing, date format).

### Changed

- **`review-ux-audit.md`** - added House Standard section requiring rubric IDs on findings, ship-now/fix-soon/defer bucketing, and gate pass/fail scoring.
- **`review-css-architecture.md`** - added rubric reference for D and K families, style-survey.js evidence preference for token audits.
- **`review-policy.md`** - added UX Review section (trigger conditions, agent/rubric/prompt references, gate behavior, report location `docs/ux-reviews/UXR-{###}`), updated output convention table, report numbering, and folder structure.
- README updated: prompts 16 → 17, agents 3 → 4, docs dirs 13 → 14, steering table adds `ux-console-idiom.md`, project structure tree updated.

## 2026-07-03 - v0.15.0

### Added - Hardcoded value scan prompt

- **New `review-hardcoded-values.md` prompt** - 6-category structured scan for embedded literals: hardcoded identifiers (C1), URLs/domains (C2), magic numbers (C3), string-literal enum values (C4), credentials/secrets (C5), and environment assumptions (C6). Includes suppression convention (`scan:allow`), per-language adaptation appendix (Python, TypeScript, Go), hook pairing guidance for automated pre-commit coverage, and tiered review cadence integration. Produces a findings report with scan manifest proving completeness.
- Installers (`install.sh`, `install.ps1`) updated to include the new prompt file.
- README updated: prompt count 15 → 16.

## 2026-06-28 - v0.14.0

### Added - Security review enhancements (informed by Anthropic-Cybersecurity-Skills)

Evaluation of [Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) (817 skills, 29 domains, 6 compliance frameworks) identified gaps in our security review coverage. See `docs/references/eval-anthropic-cybersecurity-skills-2026-06-28.md`.

- **New `incident-response` skill** (`.kiro/skills/incident-response/SKILL.md`) - 6-phase structured response: immediate containment, scope assessment, communication (with notification template), remediation, recovery verification, post-incident review. Auto-activates on breach/compromise/incident keywords.
- **Supply chain integrity checks** added to `review-dependency-risk.md` - namespace squatting prevention (@org/ scoping), SBOM generation readiness, Sigstore/SLSA provenance verification, reproducible build checks. 4 new Do Not Miss checklist items.
- **NIST CSF + ATT&CK + D3FEND framework tagging** added to `review-code-security.md` - T2 and T3 SRR findings now include compliance framework mappings per finding.
- **Cloud security baseline** added to `review-iac-consistency.md` - new section 13 covering CloudTrail, GuardDuty, AWS Config, root MFA, SCPs, WAF on public endpoints, TLS 1.2+ enforcement, KMS rotation, public exposure checks. 7 new checklist items.
- **GraphQL security** added to `review-api-contracts.md` - new section 11 covering introspection disabled in prod, query depth/complexity limits, batching attack prevention, field-level authorization, persisted queries, alias abuse. 4 new checklist items.
- **Activation Triggers sections** added to 5 review prompts (dependency-risk, iac-consistency, api-contracts, code-maintainability, test-quality) - self-documenting when each review should run.

## 2026-06-11 - v0.13.0

### Added / Changed - Git commit & PR discipline

Implements the recommendations of `docs/references/agentic-coding-tools-git-commit-and-pr-discipline-research.md` ([ADR-001](../decisions/ADR-001-git-commit-pr-discipline.md)).

- **Merged `git-workflow.md` + `focus-and-branch-discipline.md` into one always-on `git-and-focus-discipline.md`**, impact-ordered (branch hygiene → branch types → commit discipline → lifecycle → focus/queue → Definition of Done → bug workflow → conflict resolution). One file per behavioral domain so an agent can't load one and miss rules in the other.
- **New commit-cadence rules** (the field's most-cited missing discipline): defensive checkpoint commits before any multi-file/multi-session task, an explicit "meaningful checkpoint" definition (compiles + affected tests pass + lint clean → commit), and a never-end-a-session-with-uncommitted-work rule.
- **New `agent-boundaries.md`** (always-on): the hard "never"/"always" non-negotiables in their shortest form with pointers to the detailed files - the first thing an agent should read. `change-discipline.md` §"Commit Discipline" reduced to a cross-reference to avoid a weaker duplicate.
- **New hooks:** `commit-checkpoint-on-stop` (agentStop - warns when work is left uncommitted on a branch at the session boundary) and `variant-search-on-fix-branch` (userPromptSubmit - on a fresh `fix/` branch, reminds to search for the same defect class at every call site; commit-count guard prevents prompt fatigue).
- **New prompt `review-commit-pr-discipline`** (→ `/review-commit-pr-discipline` Claude command) - reviews branch/commit granularity/messages and drafts a What/Why/Trade-offs PR description.
- **`session-isolation.md`** strengthened with a one-worktree-per-concurrent-session preventive-control note.
- Installers (`install.sh`/`install.ps1`) updated: new files added to `MANAGED_FILES`, the two merged-away files added to `STALE_FILES` so upgrades clean them up; `.claude/` bonus layer regenerated; README counts and tables refreshed.
- Drafted changes were independently reviewed by headless `kiro-cli` (read-only) - verdict SHIP-WITH-TWEAKS; tweaks folded in. See `logs/kiro-steering-review.log`.
- Version 0.13.0.

## 2026-06-05 - v0.12.4

### Changed - Cross-platform install.ps1 + release smoke testing

- **`install.ps1` now works on cross-platform PowerShell 7 (macOS/Linux), not just Windows.** It used Windows-only backslash path joins (`.Replace("/", "\")`, `"$cwd\..."`) that produced wrong paths on non-Windows `pwsh` - e.g. the version file silently wasn't written. Switched to forward-slash / `Join-Path` paths, which are correct on every platform including Windows. (Surfaced by running the installer under PowerShell 7 on Linux via the new smoke test.)
- **`install.ps1` retries transient download failures** (3 attempts) - more robust on flaky networks, and fixes intermittent drops in the `Invoke-WebRequest` fallback path used when `curl.exe` is absent.
- **`KIRO_RAILS_BASE_URL` override** in both installers - lets them fetch from an arbitrary base (e.g. a local server) for testing; defaults to this repo's raw GitHub content, inert for normal installs.
- **`scripts/smoke-test-install.sh` gained a `--local` (pre-push) mode** - serves the working tree over a local http server and installs from it, running both installers natively, so un-pushed changes are validated before pushing. The default mode remains post-push (install from a published ref). See `docs/runbooks/release-process.md`.
- Version 0.12.4.

## 2026-06-05 - v0.12.3

### Fixed - Guard path-scan precision

- **The Claude `PreToolUse` guard's destructive-git path check no longer false-positives on non-path slashes.** It previously matched any `/segment` token, so a slash-containing branch name (`git reset --hard ...` alongside `fix/x`), a ref like `origin/main`, or a URL was misread as a cross-repo path and blocked. It now only inspects genuine absolute-path arguments at a word boundary. Verified: `branch + reset --hard`, `reset --hard origin/main`, and in-repo resets ALLOW; `cd /abs/other && reset`, `clean -fd /abs/other`, and `git -C /abs/other` BLOCK; the v0.12.2 quote/heredoc cases still ALLOW. (Complements the v0.12.2 quote/heredoc fix; closes the guard's precision gap.)
- Version 0.12.3.

## 2026-06-05 - v0.12.2

### Fixed / Changed - Hook reliability, guard precision, MCP translation

- **All 18 hook files are now valid strict JSON.** `security-tier1/2/3` had unescaped newlines inside string values (re-serialized losslessly); `spec-validation-gate` was YAML and is now JSON on the `when`/`fileEdited` schema. All parse with `jq` and `python json`. (These four use `then.askAgent` - a Kiro action with no Claude command equivalent - so they remain Kiro-only, now cleanly; documented in the compatibility doc.)
- **Claude `PreToolUse` guard no longer false-positives on quoted text.** It strips heredoc bodies and quoted spans before matching, so commit messages or `echo`/docs that merely mention `git -C` aren't blocked - it had been blocking its own commit messages. Bare cross-repo invocations are still blocked (verified across 5 cases).
- **MCP config translation in `export-to-claude.sh`.** Generates a project-root `.mcp.json` from `.kiro/settings/mcp.json` (enabled servers only, `disabled` omitted) and maps each server's `autoApprove` tools to `settings.json` `permissions.allow` (`mcp__<server>__<tool>`). `check-claude-fresh.sh` now verifies `.mcp.json` too. (The shipped template's only server is disabled, so no `.mcp.json` is produced by default.)
- Version 0.12.2.

## 2026-06-05 - v0.12.1

### Fixed - Installer reliability

- **install.ps1 parity with install.sh** - Windows installs were missing files the Linux installer ships. Added the `spec-validation-gate` hook, the four `spec-*` skills, `export-to-tools.sh`, and the `.kiro/skills/spec-*` directories; removed a bogus `.kiro/steering/ux-expert-persona.md` entry (no such file - `ux-pattern-registry.md` was already listed - so it 404'd on every install). Verified the two installers now manage identical file (68) and directory (27) sets.
- **Installer self-cleanup** - both installers now remove their own bootstrap file when run as a downloaded script (`curl -O ... && bash install.sh`, or `-File install.ps1`), so it isn't left behind. No-op when piped (`curl ... | bash` leaves no file), and never removes a git-tracked `install.sh`/`install.ps1` (so running inside the kiro-rails repo won't delete its own copy). README Windows commands simplified - the trailing `Remove-Item install.ps1` is no longer needed.

## 2026-06-05 - v0.12.0

### Added - BONUS: Native Claude Code layer

kiro-rails now ships a native Claude Code setup generated from the Kiro files (single source of truth), so the discipline works in Claude Code, not just Kiro. Answers the recurring "kiro-rails isn't compatible with Claude" report - the fix is a generator, not a rewrite.

- **`scripts/export-to-claude.sh`** - generates a complete `.claude/` tree: `CLAUDE.md` (steering), `settings.json` (hooks remapped to Claude events `UserPromptSubmit`/`PostToolUse`/`Stop`), `agents/*.md` (subagents from `.kiro/agents/*.json`), `commands/*.md` (slash commands from `.kiro/prompts/*.md`), and `skills/` (copied). Skips non-JSON hook files with a clear note rather than failing.
- **`scripts/claude-guard-bash.sh`** - Claude `PreToolUse` hook that **blocks** `git -C` / destructive git targeting paths outside the project root. This turns `session-isolation.md` from advice into enforcement (Kiro has no pre-Bash gate) - it blocks the exact cross-repo incident that motivated it.
- **Committed `.claude/` tree** - generated and committed so Claude Code works on clone with zero steps.
- **`scripts/check-claude-fresh.sh`** + **`claude-export-freshness` hook** - keep the committed `.claude/` from drifting: the check (used in the release checklist) regenerates to a temp dir and diffs; the hook reminds when `.kiro/` source changes.
- **`versioning.md` release checklist** - new mandatory step to regenerate and verify `.claude/` before tagging.
- **Compatibility analysis** - `docs/references/kiro-to-claude-compatibility-2026-06-05.md` documents the full Kiro->Claude mapping and known limitations (e.g. `fileMatch` steering degrades to always-on; 4 shipped hook files are currently not valid JSON and are skipped).
- Installers, README BONUS section, and counts updated (hooks 16 -> 17); version 0.12.0.

## 2026-06-05 - v0.11.0

### Added - Session Isolation

Guardrails against concurrent agent sessions interfering with each other across sibling repositories (root cause: a session launched for one repo reached into a sibling repo and corrupted a different session's git state).

- **`session-isolation.md` steering** (`inclusion: always`) - operate only inside your project root; never `cd` into or `git -C` a sibling repo; never open cross-repo PRs/cherry-picks; verify branch/HEAD before destructive git; never kill processes you didn't spawn.
- **`scripts/session-guard.sh`** - records a per-session working-tree lock under `logs/` (gitignored) and warns when another live session holds the tree or when HEAD drifted unexpectedly (a foreign actor touched the tree).
- **`session-guard-check` hook** (prompt submit) - surfaces the guard's warnings each turn.
- Installers, README, and counts updated (steering 19 -> 20, hooks 15 -> 16); version 0.11.0.

## 2026-06-05 - v0.10.0

### Added - Focus & Branch Discipline

Two recurring process failures - mid-task request thrashing and branch sprawl - are now encoded as first-class kiro-rails guardrails (steering + hooks + a tool), ported from patterns proven downstream in a production app.

- **`focus-and-branch-discipline.md` steering** (`inclusion: always`) - the Request Queue Protocol (file unrelated mid-task requests to the backlog, acknowledge, finish the current task; divert only on explicit user order), a strict Definition of Done (code -> tests -> commit -> merge -> delete branch -> drain backlog), and Branch Hygiene rules (one task per branch, merge-and-delete as one motion, check before branching, prune merged, reconcile divergence by committing immediately).
- **`docs/backlog/INBOX.md`** - the on-disk request queue the protocol writes to, plus a new `docs/backlog/` directory in the taxonomy. Shipped as a download-if-missing template so a user's queue is never overwritten on upgrade.
- **`scripts/branch-check.sh`** - branch collision detector. `branch-check.sh <area>` shows whether any unmerged branch already touches an area before you fork a parallel one; with no args it lists other unmerged branches editing the same files as the current branch, with commit dates - the early-warning signal for silent divergence.
- **`focus-guard` hook** (prompt submit) - when there's uncommitted work on a non-main branch, reminds the agent to queue unrelated requests instead of thrashing.
- **`branch-hygiene-check` hook** (prompt submit) - flags branches merged into main but not deleted, and warns when the local branch count grows large.

### Changed

- Steering file count: 18 -> 19; hook count: 13 -> 15; docs directories: 13 -> 14.
- Both installers (`install.sh`, `install.ps1`) updated to manage the new steering file, hooks, script, `docs/backlog/` directory, and INBOX template. Version bumped to 0.10.0.
- README: new discipline rows in the "with steering" table, steering and hooks table entries, project-structure tree entries.

## 2026-06-01 - v0.9.1

### Added (from Claude-BugHunter adaptation + cross-repo audit)

- **AI/Agentic Surface Review prompt** (`.kiro/prompts/review-ai-agent-surface.md`) - comprehensive security audit for AI-powered features aligned to OWASP Top 10 for Agentic Applications (ASI01-10), LLM Applications (2025), and MCP Top 10. Covers: prompt injection/goal hijack, tool scope/misuse, agent identity/privilege, MCP supply chain, code execution, memory poisoning, inter-agent comms, confidence gating, action provenance, cascading failures. Includes severity calibration, verification pass, gap-finding behavior, three-property test (attributable, reversible, gated), and agent surface matrix. Reports as `AISR-{###}-{YYYY-MM-DD}.md`. Informed by [Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter)'s `hunt-llm-ai` skill and 7-Question validation gate.
- **Security Enhancement Spec** (`docs/references/kiro-rails-security-enhancement-spec.md`) - research document covering the Claude-BugHunter adaptation plan: what translates to kiro-rails (per-vuln-class review checklists, validation gates, AI surface review), what doesn't (offensive recon, red-team tooling), and proposed future skills (security-hunt/, security-triage/).
- **Cross-Repo Audit** (`docs/references/cross-repo-audit-2026-06-01.md`) - full audit of 3 internal production repos documenting what's already synchronized, what's project-specific, evolution history of each agent/prompt/skill, and decision criteria for inclusion.
- **AISR report type** in `review-policy.md` output convention table - `AISR-{###}-{YYYY-MM-DD}.md` for AI Surface Reviews.
- **Claude-BugHunter acknowledgment** in README - credits Sachin Sharma's per-vulnerability-class skill architecture and 7-Question validation gate.

### Changed

- Review prompt count: 13 → 14 (added review-ai-agent-surface.md)
- README "What's included" line updated to reflect 14 prompts

## 2026-05-31 - v0.9.0

### Added (from Anthropic "Using LLMs to Secure Source Code" gap analysis + cross-project steering audit)

- **Severity Calibration Rubric** in `review-code-security.md` - structured questions (reachability, attacker control, preconditions, authentication, impact type, blast radius) that must be answered before assigning severity to any T2/T3 finding
- **Deduplication Rules** in `review-code-security.md` - group findings by root cause, report missing global protections once (not per-endpoint), same file + same category + lines within 10 = one finding
- **Verification Pass** in `review-code-security.md` - after producing findings, adversarially re-examine each HIGH+ finding assuming it is a false positive; search for compensating controls; downgrade or remove disproved findings
- **Verification Pass** in `review-code-maintainability.md` - check if "duplication" is intentional (documented in ADRs), if proposed abstraction would create worse coupling, if fix cost exceeds maintenance cost
- **Verification Pass** in `review-api-contracts.md` - check if "inconsistency" is documented intentional exception, if endpoint is internal-only, if middleware already enforces the concern globally
- **Context-reading preamble** added to all 13 review prompts - each prompt now reads `docs/decisions/` ADRs and domain-specific docs before scanning; documented exceptions are not flagged as findings
- **Security Verifier agent** (`.kiro/agents/security-verifier.json`) - adversarial read-only agent that assumes each finding is a false positive and searches for compensating controls. Reports DISPROVED/CONFIRMED/DOWNGRADE per finding.
- **Chokepoint Logging steering** (`.kiro/steering/chokepoint-logging.md`) - log recurring errors on attempt #2+, categorize by pattern (ROUTE_ORDERING, CSS_OVERSIGHT, TYPE_MISMATCH, STATE_SYNC, RACE_CONDITION, etc.), promote to steering rules after 3 occurrences. Generalized from internal projects.
- **Variant Analysis** in bug resolution workflow (`git-workflow.md`) - after identifying root cause, search for same pattern at all other call sites and same vulnerability class elsewhere; fix ALL variants in the same branch

### Changed

- Review prompt count unchanged (13) but all now include context-reading preamble
- Agent count: 2 → 3 (added security-verifier)
- Steering file count: 17 → 18 (added chokepoint-logging)
- Bug resolution workflow: 7 steps → 8 steps (variant search inserted as step 4)

## 2026-05-21 - v0.7.0

### Added (from cross-codebase bug pattern analysis of 120+ bugs across 13 projects)

- **Frontend Patterns steering** (`frontend-patterns.md`, fileMatch: tsx/jsx) - React hooks rules (hooks before early returns), event propagation discipline (DnD listeners, Escape layering, portal outside-click), CSS layout rules (min-h-0, overflow-hidden, header/body alignment), cache invalidation rules, component completeness checklist
- **API Contract Discipline steering** (`api-contract-discipline.md`, fileMatch: api/routes/services) - contract-first development (define schema before implementing), response shape verification, error response contracts, rate limiting guidance
- **Async Discipline** in `error-handling-performance.md` - `mutateAsync` + await for dependent operations, never block async event loops with sync I/O, auth token timing, sequenced mutations
- **State Persistence Rule** in `reusable-architecture.md` - explicit persistence strategy for all state, module-level variables are ephemeral, single source of truth, sync on startup
- **Fix Depth Rule** in `change-discipline.md` - two-fix limit, map all paths before fix #3, root cause not symptoms, document what you tried
- **Copy-Paste Verification** in `change-discipline.md` - review all values after copying, check return types, check message objects, check config references
- **Package Manifest Verification** in `change-discipline.md` - verify npm files array, pyproject.toml include, bin entries, declared dependencies
- **Comment-Safe Patterns** in `code-commenting-standards.md` - no unescaped `*/` in JSDoc, no nested `/*`, regex in backticks
- **Auth Implementation Skill** (`.kiro/skills/auth-implementation/SKILL.md`) - comprehensive SSO/OAuth checklist: happy path, expired token, missing session, provider quirks, redirect loop prevention (max 2), graceful degradation, testing requirements
- **Fix Spiral Detector hook** (UserPromptSubmit) - checks git log for 3+ consecutive fix commits, appends root-cause-analysis warning
- **Type Check on Stop hook** (Agent Stop) - runs `tsc --noEmit` or `ruff check` after agent finishes responding
- **Package Manifest Verify hook** (File Edit on package.json/pyproject.toml) - runs `npm pack --dry-run` to verify published artifact
- **Changelog Consolidation Reminder hook** (UserPromptSubmit) - warns if 10+ commits since last changelog update, triggers consolidation
- **Bug Doc Completion Check hook** (File Edit on BUG-*.md) - verifies root cause, fix, regression tests, and status fields are filled
- **ADR Trigger hook** (File Edit on infrastructure files) - suggests creating an Architecture Decision Record when docker-compose, Dockerfile, Terraform, CI/CD workflows are modified
- **Completeness Verification phase** in TDD task template - mandatory final phase checking error/loading/empty states, persistence, destructive action UX, API contract verification, cache invalidation

### Strengthened

- **Security Tier 1 hook** - added T1-S10 (exception details in responses) and T1-S11 (missing input validation on new routes)
- **Comment Standards hook** - now detects parser-breaking comments (unescaped `*/` inside JSDoc blocks)

## 2026-04-12

### Added
- **Themed Dialogs rule** in engineering-standards.md - all confirmation dialogs, alerts, and popups must use themed components. Native browser dialogs (`window.alert`, `window.confirm`, `window.prompt`) are forbidden. Includes accessibility requirements (focus trap, Escape, ARIA roles). Propagated to all projects.
