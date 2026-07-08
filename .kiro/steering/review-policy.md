
# Periodic Review Policy

## Purpose

This policy governs when and how automated code reviews are triggered during development. All reviews are powered by hooks in `.kiro/hooks/`. Results are stored in `docs/security/` and `docs/reviews/` respectively.

The security review system follows a three-tier model - one prompt, three hooks, three scopes - that matches review depth to development context. See `docs/tiered-review-methodology.md` for full rationale.

---

## Threat Modeling - Recommended Before First Review

Before running your first Tier 2 or Tier 3 security review, build a threat model for the project using the [AWS Labs Threat Modeling MCP Server](https://github.com/awslabs/threat-modeling-mcp-server). This produces a structured threat model (assets, trust boundaries, threat actors, data flows) that the security review prompts can reference to reduce false positives.

**Setup:** Add to `.kiro/settings/mcp.json`:
```json
{
  "mcpServers": {
    "threat-modeling": {
      "command": "uvx",
      "args": ["threat-modeling-mcp-server"]
    }
  }
}
```

**Workflow:** Run the threat modeling process → export to `docs/security/THREAT_MODEL.md` or `.threatmodel/` → the security review prompt reads it before scanning.

Without a threat model, the reviewer infers trust boundaries from code alone, which is the primary cause of false positives.

---

## Tier 1 - Pre-Commit (Every Commit)

**Hook:** `security-tier1-precommit.json`
**Trigger:** Automatically on every `git commit`
**Scope:** Staged files only

**Fires when:**
- Any `git commit` command is detected
- Any call to `scripts/git-commit-push.sh` is detected

**Checks:** Secrets, unsafe execution, auth bypass, missing input validation, PII in logs

**Output:** Inline block/warn response only - no SRR file generated
- CRITICAL and HIGH findings block the commit
- MEDIUM findings warn but allow

---

## Tier 2 - Feature Complete

**Hook:** `security-tier2-feature.json`
**Trigger:** After feature completion or manual invocation
**Scope:** Files changed since the last SRR, plus new integrations, routes, and IAM definitions

**Fires when:**
- A new route, Lambda handler, or service is added and marked complete
- Any external integration (OAuth, third-party API, database, message queue) is wired up
- A new IAM role, policy, or cloud resource is defined
- Manually triggered when a feature branch is ready for review

**Checks:** All Tier 1 categories plus OWASP S1-S13, BOLA/IDOR, cryptographic quality, file upload security

**Output:** Full SRR report - `docs/security/SRR-{###}-{YYYY-MM-DD}-T2.md`
- SECURITY_LOG.md updated
- CRITICAL/HIGH findings create immediate fix tasks
- MEDIUM/LOW findings added to roadmap

---

## Tier 3 - Sprint or Phase End

**Hook:** `security-tier3-sprint.json`
**Trigger:** Manual invocation at sprint or phase end
**Scope:** Full codebase

**Fires when:**
- End of each development sprint or phase
- Before any major release or deployment
- Manually triggered when systemic drift is suspected
- Any dependency manifest (`package.json`, `requirements.txt`, etc.) has had significant changes across the sprint

**Checks:** All Tier 1 and Tier 2 categories plus supply chain (D1-D5), secure headers and CORS (S15), logging security (S16), rate limiting systemic review (S14-EXT), AI-generation artifact review, test coverage delta

**Output:** Full SRR report - `docs/security/SRR-{###}-{YYYY-MM-DD}-T3.md`
- SECURITY_LOG.md updated
- CRITICAL/HIGH findings create immediate fix tasks
- MEDIUM/LOW findings added to roadmap
- Dependency manifest snapshot recorded in `docs/security/dep-snapshot-{YYYY-MM-DD}.md`

---

## Maintainability Review

**Trigger:** Manual invocation at feature completion and sprint end
**Scope:** Changed files at feature completion; full codebase at sprint end

**Fires when:**
- A feature or module is marked complete
- Before any major commit or PR
- At the end of each development sprint or phase
- Manually triggered when structural drift is suspected

**Output:** Full MRR report - `docs/reviews/MRR-{###}-{YYYY-MM-DD}.md`
- REVIEW_LOG.md updated
- Phase 1 quick wins added to active sprint backlog
- Phase 2 and Phase 3 items added to roadmap

---

## UX Review — Live Browser Walk

**Prompt:** `.kiro/prompts/review-ux-live.md`
**Agent:** `.kiro/agents/ux-reviewer.json` (restricted-tool: browser MCP + read + script exec only)
**Rubric:** `.kiro/steering/ux-console-idiom.md` (loaded on-demand, NOT always-on)
**Trigger:** Manual invocation at UI feature completion or pre-release
**Scope:** All user-facing routes (or subset specified by the invoker)

**Fires when:**
- A `ui/` or `feat/` branch with frontend changes is marked feature-complete
- Before any release (per the release checklist in `versioning.md`)
- Manually triggered when UX regression is suspected
- After a significant design system or layout change

**Does NOT fire:**
- On every commit (too expensive — browser automation)
- On backend-only changes with no UI impact
- As always-on context (per research evidence on context-bloat cost)

**Checks:** Console-idiom rubric (9 families, 44 checks): Density & Type, Surfaces & Layout, Read-First Editing, Save Model, Tables & Lists, Empty States & Feedback, Copy & Correctness, Accessibility & States, Consistency & Tokens

**Output:** Full UXR report — `docs/ux-reviews/UXR-{###}-{YYYY-MM-DD}.md`
- Systemic findings + per-page findings with rubric IDs
- Prioritized plan (ship-now / fix-soon / defer)
- Mandatory Corrections/Retractions section
- Gate: PASS (zero Sev-1, no page below 70) or FAIL

**Gate behavior:**
- FAIL blocks release (same weight as a Tier 2 security finding)
- Sev-1 findings create immediate fix tasks
- Sev-2 findings added to next sprint backlog

---

## Sequencing Rule

When both a security review and a maintainability review are due at the same checkpoint (e.g., end of sprint or feature complete), run in this order:

1. Tier 2 or Tier 3 security review first
2. Maintainability review second

Security findings may surface structural issues that the maintainability review should account for.

---

## Adversarial Verification - Reducing False Positives

Security reviews use a two-pass approach to reduce false positives:

### Pass 1: Discovery (built into the security prompt)

The `code-security-reviewer` agent scans the codebase and produces findings with the severity calibration rubric and self-verification pass built into the prompt.

### Pass 2: Independent Verification (separate agent)

For Tier 2 and Tier 3 reviews, after the discovery pass produces findings, spawn the `security-verifier` agent to adversarially disprove them:

**Instruction to include in T2/T3 review workflow:**

```
After producing the SRR findings above, invoke the security-verifier agent
with ONLY the list of HIGH+ findings (no reasoning, no context from this review).
The verifier will independently search the codebase for compensating controls
and report DISPROVED / CONFIRMED / DOWNGRADE for each finding.
Update the SRR with the verification results before finalizing.
```

### When to use each approach

| Context | Verification approach |
|---------|----------------------|
| Tier 1 (pre-commit) | None - speed matters, findings are high-confidence patterns |
| Tier 2 (feature complete) | Self-verification pass (built into prompt) |
| Tier 3 (sprint end) | Self-verification + spawn `security-verifier` agent for HIGH+ findings |
| Pre-release or post-incident | Full independent verification - spawn verifier for ALL findings |

### Why two agents matter

The same agent that finds an issue is biased toward confirming it (confirmation bias). A separate agent with no access to the discovery reasoning and instructions to *disprove* each finding roughly halves false positives (per Anthropic's "Using LLMs to Secure Source Code" research, May 2026).

---

## Output Convention

| Review Type | Output Path | Naming Pattern |
|---|---|---|
| Security Tier 1 | Inline only | No file |
| Security Tier 2 | `docs/security/` | `SRR-{###}-{YYYY-MM-DD}-T2.md` |
| Security Tier 3 | `docs/security/` | `SRR-{###}-{YYYY-MM-DD}-T3.md` |
| AI Surface Review | `docs/security/` | `AISR-{###}-{YYYY-MM-DD}.md` |
| Maintainability | `docs/reviews/` | `MRR-{###}-{YYYY-MM-DD}.md` |
| UX Review | `docs/ux-reviews/` | `UXR-{###}-{YYYY-MM-DD}.md` |
| Dep snapshot | `docs/security/` | `dep-snapshot-{YYYY-MM-DD}.md` |

---

## Report Numbering

- SRR numbers are sequential across all tiers: SRR-001, SRR-002, SRR-003, ...
- MRR numbers are sequential: MRR-001, MRR-002, MRR-003, ...
- UXR numbers are sequential: UXR-001, UXR-002, UXR-003, ...
- Always check existing files in `docs/security/`, `docs/reviews/`, and `docs/ux-reviews/` to determine the next number before creating a new report
- The tier suffix (T2 or T3) is appended after the date, not the number

---

## Folder Structure

```
.kiro/
- hooks/
  - security-tier1-precommit.json
  - security-tier2-feature.json
  - security-tier3-sprint.json
- prompts/
  - review-code-security.md
  - review-code-maintainability.md
- steering/
  - review-policy.md

docs/
- security/
  - SECURITY_LOG.md
  - dep-snapshot-{YYYY-MM-DD}.md
  - SRR-{###}-{YYYY-MM-DD}-T2.md
  - SRR-{###}-{YYYY-MM-DD}-T3.md
- reviews/
  - REVIEW_LOG.md
  - MRR-{###}-{YYYY-MM-DD}.md
- ux-reviews/
  - UXR-{###}-{YYYY-MM-DD}.md
```
