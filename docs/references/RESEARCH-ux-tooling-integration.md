# Research & Build Handoff: UX Review Tooling for kiro-rails

Status: research complete, ready for spec
Author context: prepared for the Kiro agent to build out. This document is self-contained - it assumes no memory of the conversation that produced it.
Date: 2026-07-07
Target repo: `sourjya/kiro-rails`

---

## 0. How to use this document

You (Kiro) are being asked to add a UX review capability to the kiro-rails template. This doc gives you the full context, the evidence base with verified citations, the design decisions those citations force, and a work-item breakdown with acceptance criteria. Read sections 1-4 before writing any spec. Section 5 is the work items. Section 6 is how to run these as live agents in Claude Code and Kiro CLI (invocation, orchestration, report generation). Section 7 is what NOT to do. Section 8 is the citation list - every claim in this doc traces to it.

Do not treat this doc as instructions to execute literally. It is a research brief. Turn it into a proper `.kiro/specs/<name>/` spec (requirements -> design -> tasks) per the repo's own spec-driven workflow before implementing. See the honest warning in section 3 about why literal, maximal instruction-following is itself a documented failure mode.

---

## 1. Background: what already exists

### 1.1 The kiro-rails template (this repo)
kiro-rails is an opinionated template that gives AI coding agents persistent engineering discipline via steering files, hooks, prompts, and a docs taxonomy. Relevant existing assets:

- `.kiro/steering/ux-expert-persona.md` - inclusion: **manual**. An on-demand senior UX persona covering WCAG 2.2 AA, Nielsen heuristics, content design, state/flow coverage.
- `.kiro/prompts/review-ux-audit.md` - persona cards, journey maps, heuristic sweep, anti-patterns.
- `.kiro/prompts/review-css-architecture.md` - CSS/styling consistency, tokens, specificity.
- `.kiro/prompts/review-frontend-performance.md` - Core Web Vitals, React rendering, bundle, CLS/INP.
- `.kiro/steering/review-policy.md` - inclusion: always. Defines when security and maintainability reviews trigger, output conventions, report numbering.
- `scripts/` - currently holds `git-commit-push.sh`.
- `docs/references/` - research materials (already holds a steering-research doc).

### 1.2 The external asset being folded in
A separate Claude skill, `ux-audit`, was built and field-tested against a live internal app. It contains:
- `rubric.md` - a **console-idiom** rubric (details in 1.3) with 9 check families, severity scoring, and a release-gate threshold.
- A live browser-walk protocol (9 steps, side-effect boundary, evidence discipline).
- `scripts/style-survey.js` - a computed-style census script (font-size histogram, weight census, radii count, button widths) run in-page to produce quantitative evidence.
- A stub Playwright crawler for unattended runs.

The gap this work closes: kiro-rails' existing UX assets are **generic** (Nielsen, WCAG, textbook heuristics). The skill's rubric is **specific** to the house console idiom (e.g. body font 13-14px, one save pattern per app, read-first rows). Today the CLI coders review against textbook UX while the browser skill reviews against house UX. They should share one standard.

### 1.3 The rubric's 9 families (the asset to be made canonical)
D (Density & Type), S (Surfaces & Layout), R (Read-first Editing), V (Save Model), T (Tables & Lists), E (Empty States & Feedback), C (Copy & Correctness), A (Accessibility & States), K (Consistency & Tokens). Each check has an ID (e.g. D-1, V-2), a severity (Sev-1 data-loss/blocking/misleading, Sev-2 idiom/flow break, Sev-3 polish), and a scoring model (start 100; Sev-1 -15, Sev-2 -5, Sev-3 -1; gate = zero Sev-1 and no page below 70).

### 1.4 The field test that validated the approach
The rubric + browser protocol were run once against an internal app's alpha (6 routes). Result: 2 Sev-1 (a non-modal dialog with no focus trap/Escape that blocked interaction; a missing confirmation on a destructive action), 11 Sev-2 (multiple save patterns on one page, 15px body font with four font weights, a pluralization bug, unnamed form controls, and other idiom breaks), gate FAIL. Two screenshot-only findings were retracted after live verification. This is the evidence that the rubric catches real, specific defects that generic heuristics miss, and that live verification matters.

---

## 2. Objective

Make the console-idiom rubric the single source of truth for UX quality across every surface that reviews or generates UI: Kiro (generation-time), the CLI coders' review prompts (review-time), and CI (gate-time). One rubric, multiple consumers, so every internal app inherits the same standard instead of each reinventing "settings page" badly.

---

## 3. Evidence base and the honest tension (READ THIS)

This is the most important section. The naive version of this project - "dump the rubric into an always-on steering file so the agent always follows it" - is **contradicted by current research**. The plan below is shaped to respect the evidence, not ignore it.

### 3.1 Context files do not reliably improve task success, and cost more
Gloaguen et al. (ETH Zurich / LogicStar.ai, arXiv:2602.11988, Feb 2026) evaluated repository-level context files (AGENTS.md / CLAUDE.md) across multiple agents and LLMs on SWE-bench tasks and a purpose-built benchmark of repos with developer-committed context files. Finding: context files **do not generally improve task success rates and increase inference cost by over 20% on average**, holding for both LLM-generated and human-written files. Their conclusion: unnecessary requirements make tasks harder, and human-written context files should describe **only minimal requirements** [1].

A follow-up (Shepard & Albrecht, arXiv:2606.20512) reports the mechanism: agents follow the files' instructions **literally even when counterproductive** - in one case a tool named in the context file was invoked ~160x more often than without it [2].

### 3.2 But specific, curated, minimal guidance is the exception that works
Two things reconcile this with the project being worthwhile:
- Lulla et al. (arXiv:2601.20404) find curated AGENTS.md files **improve efficiency** on focused pull requests (reported ~28.6% less runtime, ~16.6% fewer output tokens) - measuring cost, not correctness [3].
- Jiang & Nam ("Beyond the Prompt," arXiv:2512.18925, the paper already cited in this repo's own README) studied 401 repos and taxonomized what developers actually put in rule files into five themes: Conventions, Guidelines, Project Information, LLM Directives, Examples. Specific project conventions are the dominant, deliberate use [4].

### 3.3 What the evidence forces on our design
1. **On-demand, not always-on.** The rubric must NOT become an `inclusion: always` steering file. Always-on loading is exactly the context bloat the ETH study penalizes. It should be `inclusion: manual` (like the existing `ux-expert-persona.md`) or referenced only by the on-demand review prompts. This corrects the naive plan.
2. **Minimal and specific.** The rubric is already checkable and specific (numbers, IDs), which is the right shape. Do not pad it with prose rationale in the steering copy; keep rationale in this doc and in the prompt, not in always-loaded context.
3. **Literal-following is a feature here, not a bug.** For task-completion the literalness is a hazard; for a *review/lint* pass it is the point - "flag any body text above 14px" is meant to be applied literally. This is why the rubric belongs in review prompts and generation-time checks, not in the always-on task context.
4. **Generic heuristics are insufficient on their own.** Nielsen's 10 are explicitly "broad rules of thumb and not specific usability guidelines" [5]. Vercel's own Web Interface Guidelines state up front that they "reflect Vercel's brand & product choices" and "aren't universal guidelines" [6]. Both facts justify a house rubric layered on top of, not replacing, the standards.

### 3.4 The objective standards the rubric leans on (verified)
- **WCAG 2.2** is a W3C Recommendation. SC 1.4.3 (Contrast Minimum, Level AA) requires a contrast ratio of at least 4.5:1 for normal text and 3:1 for large text; these are binary thresholds, not goals (4.499:1 fails). SC 1.4.11 (Non-text Contrast) requires 3:1 for UI components and graphical objects such as icons and focus indicators [7]. The rubric's A-2 (contrast) and A-family map directly to these.
- **Nielsen's 10 usability heuristics** (NN/g) are the canonical heuristic-evaluation set, refined in 1994 from a factor analysis of 249 usability problems, and remain the default inspection method [5]. The rubric's E, T, and V families operationalize several of them (visibility of system status -> V-4/E-3; error prevention -> T-3; consistency -> K).

---

## 4. Reference implementations reviewed (and the build-vs-adopt call)

- **OneRedOak/claude-code-workflows (design-review).** A community workflow using Microsoft's Playwright MCP and Claude Code subagents, triggered on PRs or via a `/design-review` slash command, with design principles stored in CLAUDE.md and standards drawn from Stripe/Airbnb/Linear [8][9]. This is the closest existing harness to what we want for the live/CI mode.
- **Vercel Web Interface Guidelines** (vercel-labs/web-interface-guidelines) - 100 rules across 17 categories, based on WCAG + performance + UX, installable for Claude Code, with a companion skill that fetches fresh rules each run [6][10].

**Call: reimplement the good parts inside kiro-rails; do not add external repos as dependencies.** kiro-rails exists to prevent standard drift across tools. Bolting on OneRedOak's repo, AccessLint, or marketplace "expert panel" skills would fragment the standard across more tools - the exact failure the template is designed to prevent. Borrow the *pattern* (Playwright MCP walk, slash-command trigger, subagent) and point it at our rubric. The Vercel guidelines may be referenced as a secondary lint (code-level, complementary to our pixel-level walk) but our rubric is authoritative where they conflict, because ours encodes the house idiom and theirs encodes Vercel's.

---

## 5. Work items

Each item lists: what, why (with citation), target files, and acceptance criteria. Sequenced cheapest-first. This is a research brief - convert to a spec before executing.

### WI-1: Canonicalize the rubric as an on-demand steering file
**What:** Add `.kiro/steering/ux-console-idiom.md` with `inclusion: manual`. Content = the 9 rubric families (D/S/R/V/T/E/C/A/K), each check with ID, severity, and threshold. Keep it terse and checkable; no long rationale prose.
**Why:** Single source of truth (section 2). Manual inclusion is mandated by the context-bloat evidence [1] - see 3.3.1. Do NOT set `inclusion: always`.
**Targets:** new `.kiro/steering/ux-console-idiom.md`; update the steering table in `README.md`.
**Acceptance:** file exists with correct frontmatter (`inclusion: manual`); every check has a unique ID and a severity; README steering table lists it as manual; no check duplicates a WCAG SC without citing it.

### WI-2: Point the existing UX review prompts at the canonical rubric
**What:** Edit `review-ux-audit.md` and `review-css-architecture.md` to reference `ux-console-idiom.md` as the scoring standard, replacing generic-only heuristics. Keep Nielsen/WCAG as the *floor*, the rubric as the *house standard* layered on top.
**Why:** Generic heuristics are insufficient alone [5][6]; the field test showed the specific rubric catches defects the generic pass misses (section 1.4).
**Targets:** `.kiro/prompts/review-ux-audit.md`, `.kiro/prompts/review-css-architecture.md`.
**Acceptance:** both prompts cite the rubric by filename and require findings to carry a rubric ID + severity; output uses the ship-now/fix-soon/defer bucketing; Nielsen/WCAG still referenced as baseline.

### WI-3: Add the live browser-walk review prompt
**What:** Add `.kiro/prompts/review-ux-live.md` encoding the 9-step per-page protocol: (1) verify session/tab state first; (2) screenshot + accessibility-tree together; (3) run the style-survey script for quantitative evidence; (4) scroll the full page and capture each viewport; (5) safe dirty-state probe (type, navigate away, return, check URL writeback); (6) safe modal probe (Escape, click-behind, focus-trap check); (7) cross-page entity consistency check; (8) console-error check; (9) identify the in-app gold-standard page and cite it in fixes. Include the evidence-discipline rules (screenshot-only findings are provisional; Sev-1 requires reproduction; call out browser-extension artifacts) and a mandatory Corrections/Retractions section.
**Why:** The field test proved each step catches or prevents a real miss (e.g. a full section was invisible without full-page scroll; the worst Sev-1 was found only by the modal probe; two findings were wrongly asserted from static screenshots and had to be retracted). Live verification over static inference.
**Targets:** new `.kiro/prompts/review-ux-live.md`; requires a Playwright MCP or equivalent browser tool at run time.
**Acceptance:** prompt enumerates all 9 steps and the side-effect boundary (never send/delete/save/log-out/submit on a live env); mandates the retractions section; references `scripts/style-survey.js`.

### WI-4: Ship the style-survey script into the repo
**What:** Add `scripts/style-survey.js` (the in-page computed-style census) so any repo can run the font/weight/radii/button-width survey standalone, not locked in the skill bundle.
**Why:** The rubric's D and K families require numbers, not eyeballing ("15px body, 4 weights" is what made the abstract "childish" concrete). Reusable evidence generation.
**Targets:** new `scripts/style-survey.js`.
**Acceptance:** script returns font-size histogram, weight census, radii value set, button width+font list, heading census, tab active-state styles, table headers/first-cells; runnable via a browser MCP `javascript` tool or pasted into devtools.

### WI-5: Wire the UX review into review-policy.md
**What:** Extend `.kiro/steering/review-policy.md` to define UX review triggers: run `review-ux-live.md` on `ui/` branch merges and before a release (the repo's `versioning.md` already defines release checkpoints). Define report numbering/location consistent with the existing security-report convention (e.g. `docs/security/` analog for UX under `docs/` - pick a taxonomy dir and state it).
**Why:** Makes the audit a regression gate that lives in the template every internal repo already installs, rather than an ad-hoc manual step. Matches the repo's existing tiered-review philosophy.
**Targets:** `.kiro/steering/review-policy.md`; possibly a new `docs/` subdir for UX reports (state placement rules, no files in `docs/` root per the repo's own taxonomy rule).
**Acceptance:** review-policy names the UX trigger conditions, the prompt to run, and the report location + naming; release checklist in `versioning.md` cross-references it.

### WI-6: Seed the design tokens into user-project-overrides.md
**What:** Add a design-token block to `user-project-overrides.md` (the one non-overwritten customization file): body font 13-14px, two font weights (400/600), collapse the radii set to 2 values, a badge micro-label variant, one save-model pattern. These are the candidate tokens the audit surfaced.
**Why:** Closes the generation loop - if the tokens live where generation reads them, Kiro won't *write* the 15px that the audit would later flag. Prevention beats detection. Note the caution: keep this block minimal and specific per [1]; it is design constants, not architectural prose.
**Targets:** `.kiro/steering/user-project-overrides.md` (customization file, never overwritten on upgrade).
**Acceptance:** token block present and minimal; values match the rubric's D/K thresholds; no conflicting duplicate token definitions elsewhere.

### WI-7 (phase 2, defer): Unattended Playwright crawler as CI gate
**What:** Implement the headless crawler that runs the same protocol against local (dev_auth mock, zero credential handling) or a user-exported Playwright storageState, captures screenshots + computed styles + axe-core scans per route, emits an evidence bundle, and exits non-zero on any Sev-1 or axe-critical for CI gating.
**Why:** Turns the manual live walk into an automated pre-release gate. Deferred because the manual prompt (WI-3) delivers most value now and CI wiring is gold-plating before the ship-now UX fixes from the field test are even cleared.
**Targets:** `scripts/` crawler + a CI workflow snippet; route manifest per app.
**Acceptance:** runs against local without handling any credentials; produces the evidence bundle; CI exit code reflects gate pass/fail. Explicitly out of scope for the first spec.

---

## 6. Operationalizing as live agents (Claude Code + Kiro CLI)

Sections 1-5 define the artifacts. This section defines how a running agent invokes them and emits a report, in both runtimes. The design goal: **one rubric, one report contract, two runtimes**. An app dev on Claude Code and a CI job on Kiro CLI should produce byte-comparable reports scored against the same rubric.

### 6.1 The artifact-to-primitive mapping

Each kiro-rails artifact maps to a native primitive in each runtime. Build the artifacts once (section 5); the wiring below is thin.

| kiro-rails artifact | Claude Code primitive | Kiro CLI primitive |
|---|---|---|
| `ux-console-idiom.md` (rubric, WI-1) | Skill body / subagent preloaded context | Steering file, `inclusion: manual` |
| `review-ux-audit.md`, `review-css-architecture.md` (WI-2) | Skill `SKILL.md` (invocable `/ux-audit`) | Prompt invoked by an agent |
| `review-ux-live.md` (WI-3) | Subagent in `.claude/agents/` + browser MCP | Agent JSON in `.kiro/agents/` + browser MCP |
| `style-survey.js` (WI-4) | Script the subagent runs via browser MCP `javascript` tool | Same, invoked by the Kiro agent |
| review-policy triggers (WI-5) | Hook (`PreToolUse`/`SubagentStop`) or CI step | Kiro hook (pre-commit / branch) |
| design tokens (WI-6) | Loaded via `CLAUDE.md` reference | Steering `user-project-overrides.md` |

Verified runtime facts this rests on: Claude Code subagents are markdown files in `.claude/agents/` with YAML frontmatter, run in an isolated context window, and return only their final message to the parent; they are invoked via the Agent tool, `@agent-name`, or `claude --agent <name>` [11]. Claude Code skills live at `.claude/skills/<name>/SKILL.md`; only name+description load at session start and the body loads on invocation, either by `/name` or by auto-match, and skills are the recommended replacement for the legacy `.claude/commands/` slash-command format (unified in v2.1.101) [11][12]. Procedural review processes are explicitly recommended to live in a skill rather than always-on context [11]. Kiro's equivalents are demonstrated in this repo already: `.kiro/agents/code-security-reviewer.json` is a restricted-tool auditor agent, `.kiro/hooks/` holds pre-commit/edit-triggered hooks, and `.kiro/steering/` uses `inclusion: always | auto | manual`.

### 6.2 Claude Code wiring

**Primitive choice.** Use a **skill** for the review playbook (so a dev types `/ux-audit` or Claude auto-matches "review this screen") and a **subagent** for the live browser walk (so the verbose screenshot/a11y/style-survey capture stays in an isolated context and only the scored report returns to the main thread - this context-isolation is the documented reason to use a subagent over inlining [11]).

**Files to add (in a consuming app repo, or shipped by kiro-rails' installer):**
- `.claude/skills/ux-audit/SKILL.md` - the review playbook (WI-2 content). Frontmatter `name`/`description` written so auto-match fires on "audit/review/critique this UI". Body references the rubric and the report contract (6.4).
- `.claude/agents/ux-live-reviewer.md` - subagent for the live walk (WI-3 protocol). Frontmatter restricts `tools` to the browser MCP + read + the style-survey script; body is the 9-step protocol + side-effect boundary + retraction rule. Preload the rubric via the `skills:` frontmatter field so the rubric content is injected at subagent startup (subagents do NOT inherit parent skills; preload explicitly [70-style behavior is documented]).
- `.claude/commands/ux-audit.md` is optional and legacy; prefer the skill. If both exist with the same name, the skill wins [12].

**Invocation methodologies (three, escalating):**
1. **On-demand (dev inner loop):** dev runs `/ux-audit <url-or-route>`. The skill spawns `ux-live-reviewer` via the Agent tool, which walks the route, runs `style-survey.js`, scores against the rubric, and writes the report (6.4). The dev sees only the scored summary in-thread.
2. **Branch-triggered (pre-merge):** a `SubagentStop` or `Stop` hook, or more simply a CI job invoking `claude --agent ux-live-reviewer` in headless mode, runs on `ui/*` branch pushes. Non-zero exit on any Sev-1 blocks the merge.
3. **Pre-release gate:** the release checklist (repo's `versioning.md`) calls the same headless invocation across the full route manifest.

**Report generation flow (Claude Code):** subagent captures evidence -> scores each check -> fills the report template -> writes `docs/ux-reviews/UXR-{NNN}-{YYYY-MM-DD}-{app}.md` (6.4) -> returns a one-paragraph verdict + gate result to the main thread. The file is the durable artifact; the thread message is the summary.

### 6.3 Kiro CLI wiring

**Primitive choice.** Mirror the security-review pattern this repo already ships. `code-security-reviewer.json` is the template: a restricted-tool agent triggered by policy. Build `ux-reviewer.json` the same way.

**Files to add:**
- `.kiro/agents/ux-reviewer.json` - restricted-tool agent (browser MCP + read + script exec only; no write/delete/send, enforcing the side-effect boundary at the tool-permission layer, not just by instruction). Its system prompt = the `review-ux-live.md` protocol + a pointer to `ux-console-idiom.md`.
- `ux-console-idiom.md` steering with `inclusion: manual` so the agent pulls it on demand rather than every session (mandated by the context-bloat evidence, section 3.3).
- A Kiro **hook** (same class as the existing `security-tier2-feature` / `security-tier3-sprint` manual hooks) that invokes `ux-reviewer` at feature-complete and sprint/release boundaries.

**Invocation methodologies:**
1. **On-demand:** developer triggers the `ux-reviewer` agent against a route (mirrors running the Tier-2 security agent manually).
2. **Feature-complete hook:** analogous to `security-tier2-feature` - run when a UI feature is marked done.
3. **Sprint/release hook:** analogous to `security-tier3-sprint` - full route-manifest sweep at sprint end, gating the release.

**Report generation flow (Kiro):** identical output contract. Agent writes `docs/ux-reviews/UXR-{NNN}-{YYYY-MM-DD}-{app}.md`, updates the roadmap row if a gate fails (repo convention: reviews link to roadmap), and the hook's exit status gates the commit/release.

### 6.4 The shared report contract (both runtimes MUST match)

This is what makes the two runtimes interchangeable. Define it once in the rubric/prompt so Claude Code and Kiro emit the same shape.

- **Location & name:** `docs/ux-reviews/UXR-{NNN}-{YYYY-MM-DD}-{app}.md` (new `docs/` subdir; add its purpose + placement rule to `documentation-standards.md`, since the repo's taxonomy forbids files in `docs/` root). Numbering mirrors the security `SRR-{NNN}` convention.
- **Sections (fixed order):** Summary (pages, Sev counts, gate PASS/FAIL, one-paragraph verdict) -> Systemic findings table -> Per-page findings tables (each with score) -> Prioritized plan (ship-now / fix-soon / defer) -> Corrections/Retractions (mandatory) -> Notes (checks not verifiable in this mode; candidate tokens).
- **Every finding row:** rubric ID + severity + evidence (screenshot ref, computed value, or a11y node) + fix. No finding without a rubric ID.
- **Gate:** exit non-zero (CI) or FAIL (report) if any Sev-1 or any page below 70.

### 6.5 Proposal: the "prevention -> detection -> gate" operating model

Wire the three runtimes so each covers a different point in the lifecycle, matching the evidence (specific/minimal/on-demand, section 3.3):
- **Prevention (generation time):** design tokens in `user-project-overrides.md` (WI-6) so Kiro/Claude Code write compliant UI in the first place. Cheapest defect is the one never written.
- **Detection (review time):** on-demand `/ux-audit` (Claude Code) or `ux-reviewer` agent (Kiro) during the inner loop. Catches what generation missed.
- **Gate (release time):** the branch/feature/sprint hooks emit the report and block on Sev-1. This is the regression gate, the design-system sibling of the existing security tiers.

Deliberately do NOT run the live walk always-on or on every commit - it is expensive (browser automation) and the evidence penalizes always-on context [1]. On-demand plus targeted gates is the correct cadence.

---

## 7. What NOT to do (guardrails)

- **Do not** make the rubric `inclusion: always`. Evidence [1] penalizes always-on context; use manual/on-demand. This is the single most important constraint.
- **Do not** add external repos (OneRedOak, AccessLint, marketplace skills) as dependencies. Reimplement patterns inside the template (section 4).
- **Do not** pad the steering file with rationale prose. Keep it minimal and checkable [1].
- **Do not** enter credentials, send, delete, save, submit, or log out during any live walk on a real environment. Server-side authorization and anti-enumeration behaviors are phase-2 local-only work.
- **Do not** assert Sev-1/Sev-2 findings from static screenshots without live reproduction; retractions are mandatory when a prior claim is overturned.
- **Do not** treat the Vercel or Nielsen sets as authoritative over the house rubric where they conflict; both explicitly disclaim universality [5][6].
- **Do not** grant the live-review subagent/agent write, delete, send, or submit tools. Enforce the side-effect boundary at the tool-permission layer (restricted `tools:` frontmatter / restricted-tool agent JSON), not by instruction alone - instruction-only boundaries are unreliable given documented literal-following behavior [2].
- **Do not** run the live browser walk on every commit or as always-on context. It is expensive and the evidence penalizes always-on context [1]. Use on-demand + targeted gates (6.5).
- **Do not** let the two runtimes diverge in report format. The shared contract (6.4) is what makes them interchangeable; a change to one must change both.

---

## 8. Citations (all verified 2026-07-07)

[1] Gloaguen, T., Mündler, N., Müller, M., Raychev, V., Vechev, M. (2026). "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?" arXiv:2602.11988. ETH Zurich / LogicStar.ai. Finding: context files do not generally improve task success and increase inference cost >20%; human-written files should describe only minimal requirements. https://arxiv.org/abs/2602.11988

[2] Shepard, A., Albrecht, J. (2026). "Probe-and-Refine Tuning of Repository Guidance for Coding Agents." arXiv:2606.20512. Reports agents following context-file instructions literally even when counterproductive (a named tool used ~160x more). https://arxiv.org/abs/2606.20512

[3] Lulla, J.L., Mohsenimofidi, S., Galster, M., Zhang, J.M., Baltes, S., Treude, C. (2026). "On the Impact of AGENTS.md Files on the Efficiency of AI Coding Agents." arXiv:2601.20404. Curated files improve efficiency on focused PRs (~28.6% less runtime, ~16.6% fewer output tokens). https://arxiv.org/abs/2601.20404

[4] Jiang, S., Nam, D. (2025). "Beyond the Prompt: An Empirical Study of Cursor Rules." arXiv:2512.18925. Taxonomy of project context across 401 repos into five themes: Conventions, Guidelines, Project Information, LLM Directives, Examples. (Already cited in the kiro-rails README.) https://arxiv.org/abs/2512.18925

[5] Nielsen, J. "10 Usability Heuristics for User Interface Design." Nielsen Norman Group. Refined 1994 from a factor analysis of 249 usability problems; described by NN/g as "broad rules of thumb and not specific usability guidelines." https://www.nngroup.com/articles/ten-usability-heuristics/

[6] Vercel Labs. "Web Interface Guidelines." github.com/vercel-labs/web-interface-guidelines. 100 rules across 17 categories; repo states the preferences "reflect Vercel's brand & product choices" and "aren't universal guidelines." https://github.com/vercel-labs/web-interface-guidelines

[7] W3C. "Web Content Accessibility Guidelines (WCAG) 2.2" (W3C Recommendation). SC 1.4.3 Contrast (Minimum, AA): 4.5:1 normal text, 3:1 large text, treated as binary thresholds. SC 1.4.11 Non-text Contrast: 3:1 for UI components and graphical objects. https://www.w3.org/TR/WCAG22/

[8] OneRedOak. "claude-code-workflows / design-review." Playwright MCP + Claude Code subagents; PR-trigger and /design-review slash command; standards inspired by Stripe/Airbnb/Linear; CLAUDE.md memory integration. https://github.com/OneRedOak/claude-code-workflows/tree/main/design-review

[9] Same repo, methodology summary: multi-phase review covering interaction flows, responsiveness, visual polish, accessibility (WCAG AA+), robustness, code health, using live-environment Playwright testing rather than static analysis.

[10] Vercel Labs. "agent-skills / web-design-guidelines." Companion skill that fetches the latest guidelines each run and reviews UI files in file:line format. https://github.com/vercel-labs/agent-skills

[11] Anthropic. "Steering Claude Code: skills, hooks, subagents and more." Claude Code subagents are markdown files in `.claude/agents/` (YAML frontmatter, isolated context window, returns only final message); skills at `.claude/skills/<name>/SKILL.md` load body on invocation via `/name` or auto-match; procedural review processes belong in a skill rather than always-on context. https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more

[12] Anthropic. "Slash Commands in the SDK" (Claude Code docs). `.claude/commands/` is the legacy format; the recommended format is `.claude/skills/<name>/SKILL.md`, supporting `/name` invocation plus autonomous invocation; when a skill and command share a name, the skill takes precedence. https://code.claude.com/docs/en/agent-sdk/slash-commands

---

## 9. Suggested sequence for the spec

Cheapest-first, matching the repo's ship-now discipline: WI-1 (rubric steering, on-demand) -> WI-2 (repoint existing prompts) -> WI-4 (style-survey script) -> WI-6 (design tokens) -> WI-3 (live-audit prompt) -> WI-5 (review-policy trigger). WI-7 (CI crawler) is a separate later spec, explicitly deferred until the field-test's own ship-now UX fixes are cleared. Roughly half a day of work for WI-1 through WI-6.

The runtime wiring (section 6) layers on top and is cheap once the artifacts exist: the Claude Code skill + subagent (6.2) and the Kiro `ux-reviewer.json` agent + hook (6.3) are thin wrappers pointing at the same rubric and report contract (6.4). Build the artifacts first, wire second. Do the prevention -> detection -> gate model (6.5) incrementally: prevention (tokens) ships with WI-6, detection (on-demand invocation) ships as soon as the skill/agent exist, gate (hooks) ships with WI-5.
