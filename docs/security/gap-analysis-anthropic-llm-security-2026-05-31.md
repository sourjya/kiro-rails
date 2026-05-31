# Gap Analysis: Anthropic's "Using LLMs to Secure Source Code" vs. Kiro-Rails Security Review System

**Source:** https://claude.com/blog/using-llms-to-secure-source-code (May 27, 2026)
**Date:** 2026-05-31
**Compared against:** `.kiro/prompts/review-code-security.md`, `.kiro/agents/code-security-reviewer.json`, `.kiro/steering/review-policy.md`

---

## Executive Summary

Anthropic's guide describes a 6-step loop: **Threat Model → Sandbox → Discovery → Verification → Triage → Patching**. Kiro-rails' 3-tier security review system (T1 pre-commit, T2 feature-complete, T3 sprint-end) covers Discovery and Triage well, and has structural advantages Anthropic doesn't address (tiered depth, pre-commit gating, integrated maintainability reviews). However, kiro-rails has significant gaps in **Independent Verification**, **Threat Modeling as input document**, and **Iterative patching with variant analysis**.

---

## What Kiro-Rails Does Well / Better

### 1. Tiered Execution Model (BETTER)

Anthropic describes a single scan loop. Kiro-rails has **three tiers** calibrated to context:
- **T1 (pre-commit):** Staged files only, fast, blocks on CRITICAL/HIGH
- **T2 (feature-complete):** Changed files + new integrations, full OWASP
- **T3 (sprint-end):** Full codebase + supply chain + headers

This is more practical — you catch issues at the cheapest point to fix them. Anthropic's "scan periodically" advice doesn't address this granularity.

### 2. Pre-Commit Gating (BETTER)

Kiro-rails blocks commits with CRITICAL findings (secrets, eval, raw SQL, auth bypass). Anthropic's loop is entirely **post-hoc** — they find, verify, triage, then patch. We prevent the worst issues from ever entering the repo.

### 3. Prescriptive Category Taxonomy (BETTER for recurring reviews)

Our prompt has **17+ named categories** (S1-S17, D1-D5, Q1-Q3) with specific check items. Anthropic explicitly warns against "long checklists" saying they "reduce creativity." However:
- Their advice applies to **one-off pentesting** where novel findings matter
- For **recurring automated reviews**, consistency and coverage matter more
- Our checklists ensure we never skip a category between runs

### 4. Confidence Levels + Evidence Requirements (BETTER)

Our prompt requires: CONFIRMED, LIKELY, or NEEDS VALIDATION per finding, plus exact file/line/code evidence. This is more rigorous than what Anthropic describes for the discovery phase.

### 5. Integrated Workflow (BETTER)

Our system produces SRR reports → updates SECURITY_LOG.md → creates fix tasks → updates roadmap. Anthropic focuses on the technical loop but doesn't address how findings flow into a team's work management.

### 6. AI-Generation Artifact Detection (UNIQUE)

T3 includes explicit checks for AI-generated code drift (naming inconsistencies, over-verbose boilerplate, structural incoherence across sessions). Anthropic doesn't address this — they assume human-written code.

### 7. Regression Test Mandate (BETTER)

T2+ rules require noting "whether a regression test exists" for each HIGH+ finding. Anthropic mentions TDD in patching but we track it as part of triage.

### 8. Restricted-Tool Agent (GOOD)

The `code-security-reviewer` agent has `allowedTools` limited to read/grep/glob/knowledge — no write access. This prevents the reviewer from accidentally modifying code during analysis. Anthropic doesn't address tool restriction for the discovery agent.

---

## What They Do That We're Missing

### 1. Independent Verification Agent (HIGH GAP)

**Their approach:** Discovery and verification are **separate agents**. The verifier runs in a fresh context with NO access to the discovery agent's reasoning. It assumes each finding is a false positive and tries to disprove it.

> "Adding an adversarial verifier roughly halved the rate of non-exploitable findings."

**Our gap:** We use a single agent for both discovery and assessment. The same agent that finds the issue also assigns confidence. This creates confirmation bias — the agent is unlikely to disprove its own finding.

**Impact:** Higher false positive rate, especially for MEDIUM/LOW findings where exploitability is ambiguous.

**Recommendation:** Add a verification step to T2/T3 reviews. After the security reviewer produces findings, spawn a second agent (or second pass) with ONLY the finding description + codebase access. Prompt it to disprove each HIGH+ finding. Take majority vote.

### 2. Threat Model as Input Document (HIGH GAP)

**Their approach:** Create a `THREAT_MODEL.md` that explicitly documents trust boundaries, what's trusted, what's out of scope. Feed it to both discovery and triage agents.

> "The most common cause of false positives is that the model lacks a good understanding of your trust boundaries."
> "Teams with well-documented threat models had findings that were exploitable 90% of the time."

**Our gap:** We have implicit trust assumptions scattered across the prompt (e.g., "Prioritize real exploitability") but no formal threat model document per project. The reviewer agent infers trust boundaries from code, which causes false positives.

**Impact:** The reviewer doesn't know what the project trusts (e.g., "authenticated clients are trusted for data integrity") and may flag non-issues.

**Recommendation:** Add a `docs/security/THREAT_MODEL.md` template to kiro-rails. Include: system context, assets, entry points, trust boundaries, what we trust, what's out of scope. Reference it in the review prompt's preamble. Add a `threat-model` skill that bootstraps it from code + docs.

### 3. Variant Analysis After Patching (MEDIUM GAP)

**Their approach:** After fixing a vulnerability, explicitly search for: (1) same pattern at other call sites, (2) same vulnerability class elsewhere in the codebase.

> "A codebase with one SQL injection vulnerability tends to have more SQL injection vulnerabilities."

**Our gap:** We fix the specific finding but don't systematically search for variants. The bug workflow in `git-workflow.md` requires regression tests but not variant searches.

**Recommendation:** Add to the bug fix template: "Variant search: [list of other locations checked]". Add a prompt instruction to T2/T3: "After identifying a finding, search for the same pattern across the full codebase and report all instances as a single grouped finding."

### 4. Adversarial Patch Verification (MEDIUM GAP)

**Their approach:** After patching, have a fresh discovery agent probe the patch as an attacker. Validation ladder: Build passes → PoC stops working → test suite passes → re-attack succeeds.

**Our gap:** We verify patches pass tests but don't re-attack. A patch might fix the symptom but leave the root cause exploitable via a different path.

**Recommendation:** Add to T2 review trigger: "After security patches are applied, re-scan the patched files with the original finding as context. Confirm the fix is comprehensive."

### 5. Severity Calibration Rubric (MEDIUM GAP)

**Their approach:** Explicit rubric with structured questions:
- Reachability (can attacker reach this code?)
- Attacker control (does untrusted input reach the sink?)
- Preconditions (non-default settings, feature flags, time windows?)
- Authentication required?
- Read vs. write impact?
- Blast radius (one user, all users, platform?)

> "Zero preconditions + unauthenticated = CRITICAL. Three+ preconditions = LOW."

**Our gap:** We have severity levels (CRITICAL/HIGH/MEDIUM/LOW) but the calibration is implicit. The agent decides severity based on judgment, not a structured rubric.

**Recommendation:** Add the rubric to the T2/T3 prompt. Force the agent to answer each question before assigning severity. This produces more consistent, defensible severity ratings.

### 6. Deduplication by Root Cause (LOW GAP)

**Their approach:** Explicit dedup rules:
- Same file + same category + lines within 10 = duplicate
- Same root cause worded differently = duplicate
- Missing global protection reported per endpoint = one finding

**Our gap:** No explicit dedup rules. A missing rate-limiting middleware could be reported as N separate findings (one per endpoint).

**Recommendation:** Add dedup guidance to T2/T3: "Group findings by root cause. If a single fix (e.g., adding global middleware) would resolve multiple findings, report it once with all affected locations listed."

### 7. Historical Bug Patterns as Discovery Input (LOW GAP)

**Their approach:** Feed past CVEs and security-fix commits as "bug-shape" hints to guide discovery.

> "One team reviewed hundreds of past CVE and security-fix commits, distilled them into 'bug-shape' hints... They found three exploitable issues in an hour."

**Our gap:** Our T2/T3 workflow reads SECURITY_LOG.md for context on what's been reviewed before, but doesn't use past findings as pattern templates for new discovery.

**Recommendation:** Add to T3 prompt: "Read past SRR findings in docs/security/ and use recurring patterns as search templates for the current scan."

### 8. Sandbox / PoC Execution (LOW GAP for template)

**Their approach:** Build a sandbox where the agent can compile, run tests, and execute proof-of-concept exploits.

**Our gap:** Our review is purely static analysis. The agent reads code but never executes it.

**Why LOW for a template:** Kiro-rails is a project template, not a specific application. Sandbox setup is project-specific and can't be templated generically. However, we could provide guidance.

**Recommendation:** Add a section to the THREAT_MODEL.md template: "Sandbox setup instructions" with guidance on how to build a faithful test environment for security verification.

---

## What They Recommend Against That We Do (Correctly)

### 1. "Don't use long checklists — they reduce creativity"

We use detailed checklists (S1-S17). This is **correct for our use case**. Anthropic's advice applies to one-off pentesting. For recurring automated reviews, consistency > creativity.

### 2. "Discovery should optimize for recall, not precision"

Our T1 correctly optimizes for **precision** — we can't block commits on false positives. Our T3 could benefit from higher recall. This is already well-calibrated in our tiered approach.

---

## Actionable Upgrades (Priority Order)

| # | Upgrade | Effort | Impact | Files to Change |
|---|---|---|---|---|
| 1 | Add `THREAT_MODEL.md` template | 1h | HIGH | New: `docs/security/THREAT_MODEL.md` template |
| 2 | Add independent verification step to T2/T3 | 2h | HIGH | `review-code-security.md`, new hook or agent |
| 3 | Add severity calibration rubric | 30min | MEDIUM | `review-code-security.md` (T2/T3 sections) |
| 4 | Add variant analysis to bug fix workflow | 30min | MEDIUM | `git-workflow.md`, bug doc template |
| 5 | Add deduplication rules | 15min | MEDIUM | `review-code-security.md` (T2/T3 rules) |
| 6 | Add adversarial re-scan after patches | 1h | MEDIUM | New hook or T2 trigger rule |
| 7 | Feed historical findings into discovery | 30min | LOW | `review-code-security.md` (T3 workflow) |
| 8 | Add sandbox guidance to template | 30min | LOW | THREAT_MODEL.md template |

---

## Implementation Sketches

### Upgrade 1: THREAT_MODEL.md Template

Add to `docs/security/THREAT_MODEL.md`:

```markdown
# Threat Model

## System Context
<!-- What does this system do? Who uses it? -->

## Assets
<!-- What data/resources are we protecting? -->

## Entry Points
<!-- How can external actors interact with the system? -->

## Trust Boundaries
<!-- Where does trust change? -->

## What We Trust
<!-- Explicit: "We trust authenticated clients for X" -->
<!-- This prevents false positives on trusted paths -->

## What's Out of Scope
<!-- Attacks we explicitly don't care about and why -->

## Historical Bug Patterns
<!-- Recurring vulnerability classes from past SRRs -->
```

Add to `review-code-security.md` preamble:
```
Before scanning, read `docs/security/THREAT_MODEL.md` if it exists. Use it to:
- Skip findings on trusted paths documented as out-of-scope
- Calibrate severity based on documented trust boundaries
- Focus discovery on documented entry points and assets
```

### Upgrade 2: Independent Verification Step

Add after T2/T3 discovery in `review-code-security.md`:

```markdown
### Verification Pass (T2/T3 only)

After producing findings, perform an independent verification pass:

1. For each HIGH+ finding, assume it is a FALSE POSITIVE
2. Search for compensating controls: upstream validation, auth gates,
   type constraints, unreachable code paths, WAF rules
3. Check if the finding's prerequisites are actually satisfiable
4. Downgrade or remove findings where exploitation is blocked
5. Mark verified findings as CONFIRMED, unverified as NEEDS VALIDATION

The verification pass must NOT reference your original reasoning.
Re-read the code fresh for each finding.
```

For stronger separation, add a second agent:

```json
{
  "name": "security-verifier",
  "description": "Adversarial verification agent. Tries to disprove security findings.",
  "prompt": "You are an adversarial security verifier. For each finding provided, assume it is a false positive. Search the codebase for compensating controls, unreachable paths, or mitigating factors that would make the finding non-exploitable. Report only findings you CANNOT disprove.",
  "tools": ["read", "grep", "glob"],
  "allowedTools": ["read", "grep", "glob"]
}
```

### Upgrade 3: Severity Calibration Rubric

Add to T2/T3 rules in `review-code-security.md`:

```markdown
### Severity Calibration (answer before assigning severity)

For each finding, answer these questions:
1. **Reachability:** Can an attacker reach this code from a real entry point?
2. **Attacker control:** Does untrusted input reach the sink intact?
3. **Preconditions:** What must be true for the bug to trigger?
4. **Authentication:** Unauthenticated, authenticated user, or admin only?
5. **Impact type:** Read-only, write, or full compromise?
6. **Blast radius:** One user, all users, one tenant, or platform-wide?

Scoring:
- 0 preconditions + unauthenticated + write/compromise = CRITICAL
- 1-2 preconditions OR authenticated = HIGH
- 3+ preconditions OR admin-only OR read-only = MEDIUM
- Local-only OR requires physical access = LOW
```

### Upgrade 4: Variant Analysis

Add to `git-workflow.md` Bug Resolution Workflow step 3:

```markdown
3a. **Variant search - NON-NEGOTIABLE** - after identifying the root cause:
   - Search for the same pattern at all other call sites
   - Search for the same vulnerability class elsewhere in the codebase
   - Document: "Variant search: checked [locations]. Found [N] additional instances."
   - Fix ALL variants in the same branch, not just the reported instance
```

### Upgrade 5: Deduplication Rules

Add to T2/T3 rules in `review-code-security.md`:

```markdown
### Deduplication Rules

- Same file + same category + lines within 10 = ONE finding
- Same root cause at multiple call sites = ONE finding listing all locations
- Missing global protection (auth, rate-limit, CORS) = ONE finding, not per-endpoint
- Report the root cause, not each symptom
```

---

## Key Quotes from Anthropic That Validate Our Approach

> "Discovery is now straightforward to parallelize, and the bottleneck has shifted to verification, triage, and patching."

Our tiered system addresses this — T1 catches easy stuff automatically, T2/T3 focus on harder verification and triage.

> "If we send product engineers a pile of findings where a majority are non-exploitable, they will lose trust in the reports."

Our confidence levels (CONFIRMED/LIKELY/NEEDS VALIDATION) and "do NOT report false positives" instruction address this directly.

> "The model performed best on systems with well-documented threat models, system design docs, requirements, and constraints."

We have extensive steering files, specs, and ADRs. This is a strength — but we need to formalize it into a THREAT_MODEL.md.

---

---

## Cross-Prompt Impact Analysis

The Anthropic findings don't just affect `review-code-security.md`. Four principles apply across **all 13 review prompts**:

### Principle 1: Independent Verification (affects 6 prompts)

The "same agent finds AND verifies" problem exists in every review prompt. The agent that identifies a finding is biased toward confirming it.

| Prompt | Current behavior | Gap |
|--------|-----------------|-----|
| `review-code-security.md` | Single agent finds + assigns confidence | No adversarial disproof |
| `review-code-maintainability.md` | Single agent finds duplication + rates severity | No check if "duplication" is actually intentional variation |
| `review-api-contracts.md` | Single agent flags inconsistencies | No check if inconsistency is documented intentional design |
| `review-dependency-risk.md` | Single agent flags risk | No check if risk is already mitigated by other controls |
| `review-iac-consistency.md` | Single agent flags misconfig | No check if config is intentional for that environment |
| `review-observability.md` | Single agent flags gaps | No check if gap is acceptable per documented SLO |

**Upgrade:** Add a "Verification Pass" section to each prompt:
```markdown
### Verification Pass
After producing findings, re-examine each HIGH+ finding adversarially:
1. Search for documented exceptions or intentional design decisions
2. Check if compensating controls exist elsewhere
3. Downgrade findings where the "gap" is actually documented intent
```

### Principle 2: Threat Model / Context Document (affects ALL prompts)

Every prompt would benefit from reading a project-level context document before scanning. The security prompt needs trust boundaries; the maintainability prompt needs architectural intent; the API prompt needs contract decisions.

| Prompt | What context document it needs |
|--------|-------------------------------|
| `review-code-security.md` | `THREAT_MODEL.md` — trust boundaries, what's out of scope |
| `review-code-maintainability.md` | `docs/decisions/` ADRs — intentional duplication, chosen patterns |
| `review-api-contracts.md` | API design decisions doc — intentional exceptions to envelope |
| `review-dependency-risk.md` | Dependency policy doc — accepted risks, vendor lock-in decisions |
| `review-iac-consistency.md` | Infrastructure decisions — intentional per-env differences |
| `review-observability.md` | SLO definitions — what level of observability is "enough" |
| `review-test-quality.md` | Test strategy doc — intentional coverage gaps, risk-based testing |
| `review-cicd-pipeline.md` | Deployment policy — intentional gating decisions |
| `review-frontend-performance.md` | Performance budget doc — acceptable thresholds |
| `review-css-architecture.md` | Design system decisions — intentional overrides |
| `review-spec-readiness.md` | Already reads specs — no gap |
| `review-ux-audit.md` | UX principles doc — intentional pattern choices |
| `review-ux-preflight.md` | Already takes input context — no gap |

**Upgrade:** Add to each prompt's preamble:
```markdown
Before scanning, read relevant decision documents in `docs/decisions/` and
`docs/security/THREAT_MODEL.md` (if they exist). Use documented decisions
to distinguish intentional choices from accidental gaps. Do not flag
documented exceptions as findings.
```

### Principle 3: Deduplication by Root Cause (affects 4 prompts)

Several prompts can produce N findings for what is actually one root cause.

| Prompt | Dedup problem |
|--------|---------------|
| `review-code-security.md` | Missing global middleware → N findings per endpoint |
| `review-code-maintainability.md` | One missing abstraction → N "duplication" findings |
| `review-api-contracts.md` | One missing middleware → N "inconsistent header" findings |
| `review-observability.md` | One missing correlation ID setup → N "missing context" findings |

**Upgrade:** Add dedup rules to these four prompts:
```markdown
### Deduplication
- If a single fix (middleware, shared abstraction, config change) would
  resolve multiple findings, report it ONCE with all affected locations listed
- Group findings by root cause, not by symptom location
```

### Principle 4: Severity Calibration Rubric (affects 5 prompts)

Several prompts assign severity without structured criteria, leading to inconsistent ratings.

| Prompt | Current severity approach | Gap |
|--------|-------------------------|-----|
| `review-code-security.md` | Implicit judgment | No structured rubric |
| `review-code-maintainability.md` | "Phase 1/2/3" priority | No cost-of-inaction rubric |
| `review-dependency-risk.md` | "blast radius" mentioned | No structured scoring |
| `review-iac-consistency.md` | Implicit | No environment-aware rubric |
| `review-cicd-pipeline.md` | Implicit | No exploitability rubric |

**Upgrade:** Add calibration rubrics specific to each domain. Security gets the reachability/preconditions rubric. Maintainability gets a cost-of-change rubric. Dependencies get a blast-radius rubric.

---

## Prompts That Are Already Strong (No Changes Needed)

| Prompt | Why it's fine |
|--------|--------------|
| `review-spec-readiness.md` | Already operates pre-implementation; verification isn't applicable |
| `review-ux-preflight.md` | Already takes explicit input context; produces PROCEED/REVISE/BLOCK |
| `review-ux-audit.md` | Already persona-driven with explicit scope input |
| `review-css-architecture.md` | Findings are objective (hardcoded values, dead CSS) — low false-positive risk |
| `review-frontend-performance.md` | Findings are measurable (bundle size, render count) — low ambiguity |

---

## Summary: What to Upgrade and How

### Immediate (do now, ~2h total)

1. **Create `docs/security/THREAT_MODEL.md` template** — add to kiro-rails as a managed file
2. **Add verification pass to `review-code-security.md`** — adversarial disproof step for T2/T3
3. **Add severity calibration rubric to `review-code-security.md`** — structured questions before severity assignment
4. **Add dedup rules to `review-code-security.md`** — group by root cause

### Short-term (next session, ~2h total)

5. **Add "read context docs" preamble to all 13 prompts** — 1-2 lines each telling the agent to check ADRs/THREAT_MODEL before flagging
6. **Add verification pass to `review-code-maintainability.md`** — check if "duplication" is intentional
7. **Add verification pass to `review-api-contracts.md`** — check if inconsistency is documented
8. **Add dedup rules to `review-observability.md` and `review-api-contracts.md`**

### Medium-term (next sprint)

9. **Create `security-verifier` agent** — separate agent that adversarially disproves findings
10. **Add variant analysis to `git-workflow.md` bug fix template** — search for same pattern elsewhere
11. **Add adversarial re-scan hook** — after security patches, re-scan patched files
12. **Add `threat-model` skill** — bootstraps THREAT_MODEL.md from code + docs + git history

---

## Conclusion

Kiro-rails' security review system is structurally sound and in some ways more practical than Anthropic's reference architecture (tiered depth, pre-commit gating, workflow integration). The **two highest-value upgrades** are:

1. **THREAT_MODEL.md template** — reduces false positives by giving the reviewer explicit trust boundaries
2. **Independent verification step** — halves false positives per Anthropic's data by adding adversarial disproof

These principles extend beyond security to **all review prompts** — the same "read context before flagging" and "verify before reporting" patterns would improve every prompt in the system.

Total effort for all upgrades: ~6h across two sessions. The cross-prompt "read context docs" change is the highest-leverage single edit — one line added to each prompt's preamble that reduces false positives across the board.
