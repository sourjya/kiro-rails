# Cross-Repo Audit: Agents, Prompts & Skills

**Date:** 2026-06-01
**Repos scanned:** 3 internal production projects using kiro-rails
**Purpose:** Identify tools/agents/prompts from sibling projects that should be adopted into kiro-rails as generic, reusable components.

---

## Summary

**Result: No new items to adopt.** All generic/reusable components from the three repos are already present in kiro-rails. The unique items in each repo are project-specific and correctly belong in `user-project-overrides.md` territory.

---

## What Kiro-Rails Already Has (Confirmed Present)

| Item | Type | Location | Status |
|------|------|----------|--------|
| `ux-red-team.json` | Agent | `.kiro/agents/` | ✅ Identical across all 4 repos |
| `code-security-reviewer.json` | Agent | `.kiro/agents/` | ✅ Identical |
| `security-verifier.json` | Agent | `.kiro/agents/` | ✅ Identical |
| `ux-preflight-gate.kiro.hook` | Hook | `.kiro/hooks/` | ✅ Identical |
| `review-ux-preflight.md` | Prompt | `.kiro/prompts/` | ✅ Identical |
| `ux-pattern-registry.md` | Steering | `.kiro/steering/` | ✅ Identical |
| `frontend-patterns.md` | Steering | `.kiro/steering/` | ✅ Identical |
| All 5 spec-* skills | Skills | `.kiro/skills/` | ✅ Identical |
| `auth-implementation` skill | Skill | `.kiro/skills/` | ✅ Identical |

---

## Items Found in Other Repos - NOT Adopted (with Justification)

### Project A (task management SaaS)

| Item | Type | Why NOT adopted |
|------|------|-----------------|
| `ux-patterns.md` (41KB) | Steering | Project-specific UI patterns for task management screens. Too domain-specific. Kiro-rails ships the generic `ux-pattern-registry.md` (3.8KB) with common screen-type patterns; projects extend it in overrides. |
| `devtools-testing.md` | Steering | Project-specific DevTools/Playwright testing conventions. Generic testing standards are already in `testing-standards.md`. |
| `vg-*.md` prompts (11 files) | Prompts | Product-specific visual debugging prompts (diff, capture, ideate, etc.). These are workflow shortcuts, not generic review prompts. |
| `viewgraph-*.md` steering (3 files) | Steering | ViewGraph-specific rules (hostile DOM handling, workflow, resolution). |
| `wsl-shell-commands.md` | Steering | WSL-specific shell workarounds. Environment-specific, not generic. |

### Project B (developer platform)

| Item | Type | Why NOT adopted |
|------|------|-----------------|
| `tracepulse-subagent-rules.md` | Steering | Rules for how to use TracePulse MCP tools. Project-specific to repos that use TracePulse. Users who install TracePulse should add this to their overrides. |
| `webwright-browser-agent.md` | Steering | Browser automation agent rules using Microsoft WebWright. Product-specific integration. |
| `dev-queue.md` | Steering | Agentic development queue conventions. Product-specific architecture. |
| `ui-spacing-typography.md` | Steering | Project-specific spacing/typography tokens. Generic spacing rules are in `frontend-patterns.md`. |
| `new-project-checklist.md` | Steering | Checklist for bootstrapping sub-projects. The kiro-rails installer serves this purpose for new projects. |
| `strengthen-project-spec.md` (20KB) | Prompt | Spec hardening prompt. Overlaps significantly with `review-spec-readiness.md` which is already in kiro-rails. This version is tuned to a specific domain. |
| `enforce-tracepulse-usage.kiro.hook` | Hook | Forces TracePulse over raw shell for tests/builds. Product-specific to TracePulse users. |

### Project C (ticket/issue tracking)

| Item | Type | Why NOT adopted |
|------|------|-----------------|
| `ux-design-sprint.md` | Prompt | UX design sprint workflow prompt. Interesting but too opinionated for a generic template - assumes a specific design sprint methodology. Projects can add to overrides. |
| `tp-*.md` prompts (5 files) | Prompts | TracePulse shortcut prompts (tp-start, tp-test, tp-debug, tp-health, tp-diagnose). Product-specific to TracePulse users. |
| `tp-shell-intercept.kiro.hook` | Hook | Intercepts shell commands to route through TracePulse. Product-specific. |
| `ui-component-standards.md` | Steering | Project-specific component library conventions. Generic component rules are in `frontend-patterns.md` and `reusable-architecture.md`. |
| `import-path-aliases.md` | Steering | Project-specific path alias config. Generic rules are in `import-path-rules.md`. |

---

## Evolution History

This audit documents how kiro-rails' agent/prompt library evolved:

| Version | Addition | Source | Justification |
|---------|----------|--------|---------------|
| v0.1.0 | `code-security-reviewer.json` | Original | Three-tier security review needs a restricted-tool auditor agent |
| v0.5.0 | `security-verifier.json` | Anthropic "Using LLMs to Secure Source Code" (May 2026) | Adversarial verification halves false positives per Anthropic's research |
| v0.7.0 | `ux-red-team.json` | Original (informed by internal UX pain points) | Hostile UX review catches interaction locality, hierarchy, and density issues that cooperative review misses |
| v0.7.0 | `ux-preflight-gate.kiro.hook` | Original (internal workflow) | Pre-task UX intent check prevents coding before layout decisions are made |
| v0.7.0 | `review-ux-preflight.md` | Original | Structured pre-implementation UX gate with 10-point checklist |
| v0.7.0 | `ux-pattern-registry.md` | Original (extracted from a 41KB project-specific version) | Generic screen-type patterns (task detail, data table, form, dashboard, modal, empty state) |
| v0.9.0 | `review-ai-agent-surface.md` | Claude-BugHunter `hunt-llm-ai` skill (adapted) | Defensive counterpart to offensive AI hunting - OWASP ASI01-10, MCP Top 10, confidence gates |
| v0.9.0 | Spec workflow skills (4) | OpenSpec by Fission AI (adapted) | Structured spec lifecycle (propose → implement → verify → archive) |
| v0.9.0 | `auth-implementation` skill | Original | Comprehensive SSO/OAuth checklist covering all edge cases |

---

## Decision: What Belongs in Kiro-Rails vs. User Overrides

**Kiro-rails ships generic, framework-agnostic, reusable components.** The test for inclusion:

1. Would >50% of projects benefit from this? → Include
2. Is it tied to a specific product, domain, or tool? → User override
3. Does it duplicate something already in kiro-rails? → Don't include

Items that are project-specific (TracePulse rules, product-specific prompts, queue conventions) correctly live in each project's `user-project-overrides.md` or as additional steering files that the installer doesn't manage.

---

## Recommendations for Future Versions

None at this time. The three repos are well-synchronized with kiro-rails. The installer's upgrade mechanism (`kiro-rails-version` marker + managed file overwrite) keeps them in sync.

If a pattern emerges across 3+ projects (e.g., TracePulse usage rules appearing in all repos), that's a signal to consider promoting it to kiro-rails core. Currently `tracepulse-subagent-rules.md` exists in 2/3 repos - one more adoption would trigger promotion consideration.
