# Kiro-Rails Security Enhancement Spec

## Source: Claude-BugHunter Adaptation

**Date:** 2026-06-01
**Source:** [elementalsouls/Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter) (MIT, v2.0)
**Author:** Sachin Sharma - Bug Hunting & GenAI Security Research

---

## What Claude-BugHunter Is

A 51-skill bundle for Claude Code's skills system, designed for bug hunting and external red-team work. Key architecture:

- **6-phase engagement flow:** Scope → Recon → Hunt → Validate → Capture → Report
- **28 hunt-* skills:** Per-vulnerability-class detection patterns curated from 681 disclosed HackerOne reports across 24 vulnerability classes
- **7-Question Gate (triage-validation):** A non-optional validation step before any finding is reported - prevents false positives and wasted effort
- **Auto-loading by keyword:** Skills trigger when the user describes what they're testing; no explicit invocation needed
- **Enterprise platform attack chains:** M365/Entra, Okta, vCenter, VPN appliances, SharePoint
- **Engagement folder scaffolding:** Structured workspace per target with scope.md, findings/, evidence/

---

## What Translates to Kiro-Rails (Defensive Adaptation)

Claude-BugHunter is offensive (external attack surface). Kiro-rails is defensive (dev-workflow guardrails). The concepts that translate:

### 1. Per-Vulnerability-Class Review Checklists (from hunt-* skills)

**BugHunter concept:** Each `hunt-*` skill contains detection patterns, payloads, bypass tables, and chain templates for one vulnerability class.

**Kiro-rails adaptation:** Defensive code review checklists per vulnerability class. Instead of "how to find SQLi on a target," it's "how to verify your code doesn't have SQLi patterns." These would be skills that auto-activate when editing relevant files.

**Proposed skill: `security-hunt/`**

| Vulnerability class | Activates on | Checks |
|---|---|---|
| SQLi | `**/models/**`, `**/services/**`, raw SQL | Parameterized queries, no string interpolation, ORM usage |
| XSS | `**/*.tsx`, `**/*.jsx`, template files | Output encoding, dangerouslySetInnerHTML, template escaping |
| SSRF | `**/services/**`, HTTP client code | URL allowlists, no user-controlled URLs to fetch |
| IDOR | `**/api/**`, `**/routes/**` | Ownership checks on every object access, tenant scoping |
| Auth bypass | `**/auth/**`, middleware | Session validation, token verification, role checks |
| File upload | Upload handlers | Content-type validation, size limits, path traversal prevention |
| SSTI | Template rendering code | No user input in template strings |
| Race conditions | Transaction code, async handlers | Proper locking, idempotency keys, TOCTOU prevention |

**Status:** Proposed for future implementation. The spec documents the pattern; actual SKILL.md files are a separate task.

### 2. Validation Gate (from triage-validation / 7-Question Gate)

**BugHunter concept:** Before reporting any finding, run it through 7 questions. One NO = KILL.

**Kiro-rails adaptation:** A validation gate for security review findings. Before a finding makes it into an SRR report, verify:

1. Is the vulnerable code path reachable in production (not dead code, not behind a feature flag)?
2. Can an attacker actually supply the malicious input (what's the entry point)?
3. Is there a compensating control upstream that blocks exploitation?
4. Does the finding require preconditions the attacker cannot obtain?
5. Is this already documented as an accepted risk (check ADRs, THREAT_MODEL.md)?
6. Can concrete impact be demonstrated, not just "technically possible"?
7. Is this a real vulnerability, not a code smell or style issue?

**Status:** This discipline is already partially implemented in our `security-verifier` agent (adversarial verification pass). The 7-Question Gate formalizes it as a checklist. Could become a `security-triage/` skill.

### 3. AI/Agentic Surface Review (new prompt)

**BugHunter concept:** The `hunt-llm-ai` skill covers prompt injection, ASCII smuggling, and ASI01-10 from the attacker's perspective.

**Kiro-rails adaptation:** The `review-ai-agent-surface.md` prompt - a comprehensive defensive audit for AI-powered features, aligned to OWASP Top 10 for Agentic Apps, LLM Apps, and MCP Top 10. This is the defender's counterpart to BugHunter's `hunt-llm-ai`.

**Status:** Implemented. Added as `.kiro/prompts/review-ai-agent-surface.md`.

### 4. Engagement Scaffolding (from hunt.sh)

**BugHunter concept:** `hunt <target>` creates a structured folder with scope.md, findings/, evidence/, CLAUDE.md.

**Kiro-rails adaptation:** We already have this via the docs/security/ structure and SRR report numbering. No additional scaffolding needed - our existing convention (SECURITY_LOG.md, SRR-###, AISR-###) serves the same purpose.

---

## What Does NOT Translate (Out of Scope)

| BugHunter feature | Why it doesn't fit |
|---|---|
| Offensive recon (subfinder, dnsx, httpx) | Kiro-rails is a dev-workflow template, not a pentest framework |
| Enterprise platform attack chains (M365, Okta, VPN) | External attack surface; we're defending code, not attacking infrastructure |
| Bug bounty reporting templates (H1, Bugcrowd) | We report to ourselves via SRR/AISR, not to bounty platforms |
| Red-team mindset / "DO NOT STOP" directive | Inappropriate for defensive code review context |
| Slash commands (/hunt, /recon, /triage) | Kiro uses prompts and skills, not slash commands |
| Engagement memory (JSONL persistence) | Our chokepoint-log.md and SECURITY_LOG.md serve this purpose |
| Burp MCP integration | External tooling; out of scope for a template repo |

---

## Integration with Existing Security System

### How the new prompt fits the tiered model

```
Tier 1 (pre-commit)     → review-code-security.md (conventional surface)
Tier 2 (feature)        → review-code-security.md + review-ai-agent-surface.md (if AI feature)
Tier 3 (sprint)         → review-code-security.md + review-ai-agent-surface.md (all AI surfaces)
```

The AI agent surface review runs **alongside** the conventional security review, not instead of it. It owns the AI-specific attack surface; the security prompt owns the conventional surface.

### Report naming

| Review type | Output path | Naming |
|---|---|---|
| AI Surface Review | `docs/security/` | `AISR-{###}-{YYYY-MM-DD}.md` |

AISR numbers are sequential, independent of SRR numbers.

### Trigger conditions

The AISR prompt fires when a feature:
- Calls an LLM
- Exposes a chat or natural-language interface
- Runs an autonomous or semi-autonomous agent
- Registers or invokes tools/functions
- Consumes an MCP server
- Retrieves content into a model context (RAG)
- Executes model-generated code, queries, or workflows

---

## Future Work (Not This PR)

1. **`security-hunt/` skill** - per-vulnerability-class defensive review checklists that auto-activate on file patterns
2. **`security-triage/` skill** - formalized 7-Question Gate for security findings validation
3. **Threat model integration** - the AISR prompt already reads `docs/security/THREAT_MODEL.md`; ensure the threat modeling MCP server output feeds into it
4. **hunt-llm-ai patterns** - extract the defensive subset of BugHunter's LLM/AI hunting patterns into our security-hunt skill

---

## References

- [Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter) - MIT, Sachin Sharma
- [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications/) (ASI01-ASI10, Dec 2025)
- [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/) (2025)
- [OWASP MCP Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/MCP_Security_Cheat_Sheet.html)
- [Anthropic - "Using LLMs to Secure Source Code"](https://claude.com/blog/using-llms-to-secure-source-code) (May 2026)
