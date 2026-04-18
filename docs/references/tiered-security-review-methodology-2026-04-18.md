# Tiered Security Review Methodology for Kiro-Assisted Development

## TL;DR

A single monolithic security prompt run at every commit is wasteful and slow. A single prompt run only at sprint end misses critical issues early. This document proposes a three-tier security review model - one prompt, three hook configs, three scopes - that matches review depth to development context, keeps feedback loops tight, and produces professional-grade audit output without prompt sprawl.

---

## Background

This methodology was designed for a Claude Opus-assisted full-stack development workflow, where large volumes of code are generated across multiple sessions. The codebase includes Lambda functions, API routes, IAM definitions, external integrations, and frontend components. The review system uses Kiro hooks to trigger AI-powered code audits automatically at defined checkpoints.

The original security prompt (SRR format) covered OWASP categories S1-S12, code quality Q1-Q3, and dependency scanning D1-D3. A gap analysis against professional security audit standards (NCC Group, Trail of Bits, OWASP ASVS) identified nine additional coverage areas:

1. Business logic vulnerabilities
2. BOLA/IDOR per-resource authorization
3. Cryptographic implementation quality
4. Rate limiting and abuse prevention
5. Secure headers and CORS
6. Supply chain and lock file integrity
7. Logging security dimension
8. File upload security
9. Information disclosure via errors

Threat modeling is explicitly excluded - it is handled by a dedicated AWS Threat Modeling MCP server (awslabs/threat-modeling-mcp-server), which is purpose-built for that job and runs as a separate workflow.

Adding all nine areas to a single prompt run on every commit creates two problems:

- **Context overload** - a model asked to check 25+ security categories on every staged file will either truncate findings or produce shallow results
- **Trigger mismatch** - checking for CORS misconfiguration or rate limiting gaps on a two-line utility function change is noise, not signal

The tiered model solves both problems.

---

## Core Principle

> Match review depth to development context. Run the smallest scope that catches the highest-risk issues at each checkpoint.

Security issues have different discovery windows:

- Secrets and unsafe code patterns should be caught **before they are committed** - the blast radius of a committed secret is immediate and potentially irreversible
- Authorization gaps, business logic flaws, and cryptographic weaknesses should be caught **when a feature is complete** - they require full context of the feature to evaluate correctly
- Supply chain risk, logging gaps, header configuration, and systemic patterns should be caught **at sprint or phase boundaries** - they require full codebase visibility to assess properly

Running everything at every checkpoint conflates these windows and degrades the quality of each check.

---

## The Three-Tier Model

### Tier 1 - Pre-Commit (Every Commit)

**Trigger:** `preToolUse` on `git commit`

**Scope:** Staged files only

**Goal:** Block commits that introduce immediately exploitable or irreversible issues

**Categories covered:**
- Hardcoded secrets, API keys, tokens, private keys
- `.env` files staged outside of `.env.example`
- Unsafe code execution: `eval()`, `exec()`, `innerHTML`, `dangerouslySetInnerHTML`, `subprocess` with `shell=True`
- Raw SQL string interpolation
- Auth/authorization checks bypassed or weakened
- Stack traces or internal error details returned in API responses
- Missing input validation on new routes
- PII logged in plain text

**Why this scope:** These are the categories where the cost of a miss is highest and the fix window is shortest. A committed secret may be rotated within minutes by an attacker scanning public repos. A bypassed auth check in a committed route is live the moment it deploys. Everything in Tier 1 is either immediately exploitable or creates a permanent artifact (git history) that is expensive to remediate.

**Output:** Inline block/warn response in the Kiro agent - no SRR file generated. CRITICAL and HIGH findings block the commit. MEDIUM findings warn but allow.

---

### Tier 2 - Feature Complete

**Trigger:** `postToolUse` on feature-complete signal or manual invocation

**Scope:** Files changed since the last SRR, plus any new integrations, routes, or IAM definitions

**Goal:** Catch security issues that require full feature context to evaluate

**Categories covered (in addition to Tier 1):**
- S1-S3: Authentication, data isolation, input validation
- S5-S9: API security, database security, frontend security, infrastructure config, data privacy
- S10-S12: IAM least privilege, Lambda env vars, cloud misconfiguration
- New S13: Business logic vulnerabilities - price/quantity manipulation, workflow bypass, privilege escalation through data fields, mass assignment, race conditions
- New S14: BOLA/IDOR - per-resource ownership verification at service layer for every endpoint accepting a resource ID
- Expanded S4: Cryptographic implementation quality - weak algorithms, insecure randomness, JWT vulnerabilities, timing attacks, IV/nonce reuse
- New S17: File upload security - MIME validation, size limits, path traversal, malicious content, S3 public access

**Why this scope:** Business logic flaws, BOLA/IDOR, and cryptographic weaknesses cannot be evaluated on a diff of two files. They require understanding the full feature - its inputs, its trust boundaries, its data model, and its relationship to adjacent services. Running these checks at feature completion gives the model the context it needs to produce accurate findings rather than false positives or missed issues.

**Output:** Full SRR report in `docs/security/SRR-{###}-{YYYY-MM-DD}.md` with tier noted. SECURITY_LOG.md updated. CRITICAL/HIGH findings create immediate fix tasks.

---

### Tier 3 - Sprint or Phase End

**Trigger:** Manual invocation or sprint-end milestone

**Scope:** Full codebase

**Goal:** Catch systemic patterns, supply chain risk, and configuration issues that only become visible at full codebase scale

**Categories covered (full scope - all tiers plus):**
- Q1-Q3: Dead code, query performance, error handling consistency
- Expanded D1-D3: Known CVEs, outdated packages, secrets in git history, dependency confusion, typosquatting, transitive dependency risk, lock file integrity, build-time script execution
- New S15: Secure headers and CORS - CSP, X-Frame-Options, HSTS, CORS wildcard origins, cookie security flags
- New S16: Logging security - security-relevant events not logged, log injection, sensitive data in logs, audit trail completeness
- Expanded S5/Q3: Information disclosure - verbose error modes, GraphQL introspection, user enumeration via error messages
- Expanded S14 (rate limiting systemic review): Unbounded pagination, ReDoS patterns, missing account lockout
- AI-generation artifact review across all sessions in the sprint
- Test coverage delta across all new modules

**Why this scope:** Supply chain attacks, CORS misconfigurations, and logging gaps are systemic - they manifest as patterns across the codebase, not as issues in a single file. A dependency confusion attack is invisible until you look at all package names together. A logging gap is only meaningful when you can see which security events are and are not being captured across all services. These checks need full codebase visibility and are worth the longer runtime at sprint boundaries.

**Output:** Full SRR report with tier noted. Roadmap updated with MEDIUM/LOW findings. Dependency manifest snapshot recorded for next sprint comparison.

---

## Prompt Architecture

One prompt file. Three hook configs. The hook config passes a tier instruction to the prompt at invocation time.

```
.kiro/
- hooks/
  - security-tier1-precommit.json
  - security-tier2-feature.json
  - security-tier3-sprint.json
- prompts/
  - review-code-security.md       (single prompt, tier-aware)
  - review-code-maintainability.md
- steering/
  - review-policy.md

docs/
- security/
  - SECURITY_LOG.md
  - SRR-001-YYYY-MM-DD.md
- reviews/
  - REVIEW_LOG.md
  - MRR-001-YYYY-MM-DD.md
```

The security prompt contains all categories organized into tiers. Each hook invokes the same prompt but passes a tier parameter that instructs the model to run only the categories for that tier. This avoids maintaining three separate prompt files that would drift out of sync over time.

---

## Maintainability Prompt Changes

The maintainability prompt requires only minor additions - no structural change:

- **Objective 15 strengthened** - add explicit patterns for missing rate limiting, unbounded pagination, and ReDoS-prone regex as standardizable control flow concerns
- **Objective 18 strengthened** - add security-relevant logging gaps (missing auth failure logs, missing admin action logs, PII in log output) as observability inconsistencies to flag

These are not new objectives - they are natural extensions of existing ones. The maintainability prompt remains a single full-codebase scan triggered at feature completion and sprint end, unchanged in structure.

---

## Justification Summary

| Design Decision | Justification |
|---|---|
| One prompt, three hooks | Avoids prompt drift across multiple files; single source of truth for all security categories |
| Tier 1 blocks commits | Secrets and unsafe execution have the shortest fix window and highest blast radius - they must be caught before git history is written |
| Tier 2 at feature complete | Business logic and BOLA/IDOR require full feature context - evaluating them on a two-file diff produces false positives and missed issues |
| Tier 3 at sprint end | Supply chain, headers, and logging gaps are systemic patterns - they require full codebase visibility to assess accurately |
| Threat modeling excluded | Handled by awslabs/threat-modeling-mcp-server - purpose-built tool, no value in duplicating in a code review prompt |
| Maintainability prompt unchanged structurally | The nine new security additions are security findings, not maintainability findings - only two categories (rate limiting patterns, logging consistency) have a maintainability dimension, and both fit naturally into existing objectives |

---

## Coverage Map - Before and After

| Category | Before | After | Tier |
|---|---|---|---|
| Secrets and hardcoded credentials | Tier 2 | Tier 1 | Pre-commit |
| Unsafe code execution | Tier 2 | Tier 1 | Pre-commit |
| Auth bypass | Tier 2 | Tier 1 | Pre-commit |
| Input validation (new routes) | Tier 2 | Tier 1 | Pre-commit |
| OWASP S1-S12 | Tier 2 | Tier 2 | Feature complete |
| Business logic vulnerabilities | Not covered | Tier 2 | Feature complete |
| BOLA/IDOR | Partial | Tier 2 | Feature complete |
| Cryptographic quality | Partial | Tier 2 | Feature complete |
| File upload security | Not covered | Tier 2 | Feature complete |
| CVE scanning | Tier 3 | Tier 3 | Sprint end |
| Supply chain integrity | Partial | Tier 3 | Sprint end |
| Secure headers and CORS | Not covered | Tier 3 | Sprint end |
| Logging security | Not covered | Tier 3 | Sprint end |
| Information disclosure | Partial | Tier 3 | Sprint end |
| Rate limiting (systemic) | Not covered | Tier 3 | Sprint end |
| Threat modeling | Not covered | External MCP | Separate tool |
