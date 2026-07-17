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

### Project A (an internal web app)

| Item | Type | Why NOT adopted |
|------|------|-----------------|
| `ux-patterns.md` (41KB) | Steering | Project-specific UI patterns for the app's screens. Too domain-specific. Kiro-rails ships the generic `ux-pattern-registry.md` (3.8KB) with common screen-type patterns; projects extend it in overrides. |
| `devtools-testing.md` | Steering | Project-specific DevTools/Playwright testing conventions. Generic testing standards are already in `testing-standards.md`. |
| Product-specific prompts (11 files) | Prompts | Product-specific visual debugging prompts (diff, capture, ideate, etc.). These are workflow shortcuts, not generic review prompts. |
| Product-specific steering (3 files) | Steering | Project A-specific rules (DOM handling, workflow, resolution). |
| `wsl-shell-commands.md` | Steering | WSL-specific shell workarounds. Environment-specific, not generic. |

### Project B (an internal web app)

| Item | Type | Why NOT adopted |
|------|------|-----------------|
| MCP-usage steering | Steering | Rules for how to use a project-specific test/build MCP. Specific to repos that use that MCP; users who install it add this to their overrides. |
| Browser-agent steering | Steering | Browser-automation agent rules using a product-specific browser tool. Product-specific integration. |
| `dev-queue.md` | Steering | Agentic development queue conventions. Product-specific architecture. |
| `ui-spacing-typography.md` | Steering | Project-specific spacing/typography tokens. Generic spacing rules are in `frontend-patterns.md`. |
| `new-project-checklist.md` | Steering | Checklist for bootstrapping sub-projects. The kiro-rails installer serves this purpose for new projects. |
| `strengthen-project-spec.md` (20KB) | Prompt | Spec hardening prompt. Overlaps significantly with `review-spec-readiness.md` which is already in kiro-rails. This version is tuned to a specific domain. |
| MCP-enforcement hook | Hook | Forces a project-specific test/build MCP over raw shell for tests/builds. Product-specific to that MCP's users. |

### Project C (an internal web app)

| Item | Type | Why NOT adopted |
|------|------|-----------------|
| `ux-design-sprint.md` | Prompt | UX design sprint workflow prompt. Interesting but too opinionated for a generic template - assumes a specific design sprint methodology. Projects can add to overrides. |
| Product-specific prompts (5 files) | Prompts | Shortcut prompts for a project-specific test/build MCP (start, test, debug, health, diagnose). Product-specific. |
| Shell-intercept hook | Hook | Intercepts shell commands to route through a project-specific MCP. Product-specific. |
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

Items that are project-specific (project-specific MCP rules, product-specific prompts, queue conventions) correctly live in each project's `user-project-overrides.md` or as additional steering files that the installer doesn't manage.

---

## Recommendations for Future Versions

None at this time. The three repos are well-synchronized with kiro-rails. The installer's upgrade mechanism (`kiro-rails-version` marker + managed file overwrite) keeps them in sync.

If a pattern emerges across 3+ projects (e.g., project-specific MCP usage rules appearing in all repos), that's a signal to consider promoting it to kiro-rails core. Currently that MCP-usage steering exists in 2/3 repos - one more adoption would trigger promotion consideration.
