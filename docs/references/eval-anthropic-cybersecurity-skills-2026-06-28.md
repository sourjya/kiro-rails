# Evaluation: Anthropic-Cybersecurity-Skills

**Date:** 2026-06-28
**Source:** https://github.com/mukul975/Anthropic-Cybersecurity-Skills
**Author:** Mahipal Jangra (mukul975)
**License:** Apache-2.0
**Evaluated for:** kiro-rails security review prompt improvements

---

## Summary

817 structured cybersecurity skills across 29 domains, following the [agentskills.io](https://agentskills.io/) open standard. Each skill is a folder with `SKILL.md` (YAML frontmatter + structured Markdown body), mapped to 6 compliance frameworks: MITRE ATT&CK v19.1, NIST CSF 2.0, MITRE ATLAS v5.4, MITRE D3FEND v1.3, NIST AI RMF 1.0, and MITRE F3 (Fight Fraud Framework v1.1).

The repo is an **operational knowledge base for security practitioners**, not a development-process framework. It teaches agents how to perform specific security tasks (forensics, threat hunting, pentesting) rather than how to write secure code.

---

## Architecture & Design Patterns Worth Noting

### 1. Progressive Disclosure (Token-Efficient Skill Loading)

Skills cost ~30 tokens to scan (frontmatter only) and 500–2,000 tokens to fully load. Agents scan all 817 skills in one pass, then load only the 2-3 relevant ones.

**Our equivalent:** Our skills are always fully loaded. If we expand beyond 5-10 skills, this pattern becomes important.

### 2. Multi-Framework Compliance Tagging

Every skill carries YAML frontmatter mapping it to multiple compliance frameworks:
```yaml
nist_csf: [RS.AN-01, RS.AN-03, DE.AE-02]
mitre_attack: [T1005, T1074, T1119]
atlas_techniques: [AML.T0047]
d3fend_techniques: [D3-MA, D3-PSMD]
nist_ai_rmf: [MEASURE-2.6]
```

**Our gap:** Our SRR reports reference OWASP categories but don't tag findings to NIST CSF, ATT&CK, or D3FEND. For regulated environments, this mapping would increase report value.

### 3. Structured Skill Anatomy

```
skills/<name>/
├── SKILL.md              ← YAML frontmatter + Markdown body
├── references/
│   ├── standards.md      ← Framework mappings, CVE refs
│   └── workflows.md      ← Deep technical procedure
├── scripts/
│   └── process.py        ← Working helper scripts
└── assets/
    └── template.md       ← Checklists, report templates
```

Body sections: `## When to Use` → `## Prerequisites` → `## Workflow` → `## Verification`

### 4. Agent Discovery via Description Keywords

Descriptions are written for agent semantic matching:
> "Analyze volatile memory dumps using Volatility 3 to extract running processes, network connections, loaded modules, and evidence of malicious activity."

Keyword-rich descriptions enable agents to find the right skill from natural language queries without needing exact name matches.

---

## Domain Coverage (29 domains, 817 skills)

| Domain | Skills | Relevance to kiro-rails |
|--------|--------|------------------------|
| Cloud Security | 66 | **High** — hardening, CSPM, cloud forensics |
| Web Application Security | 42 | **High** — OWASP Top 10, SQLi, XSS, SSRF |
| DevSecOps | 18 | **High** — CI/CD security, Trivy, code signing |
| API Security | 28 | **High** — GraphQL, REST, OWASP API Top 10 |
| Supply Chain Security | 8 | **High** — SBOMs, dependency confusion, SLSA |
| AI Security | 14 | **High** — LLM red-teaming, prompt injection, MCP security |
| Container Security | 33 | **Medium** — K8s RBAC, image scanning, Falco |
| Cryptography | 16 | **Medium** — TLS, post-quantum, key management |
| Identity & Access Management | 37 | **Medium** — Entra ID, PAM, zero trust |
| Compliance & Governance | 9 | **Medium** — NIST 800-30, CMMC, HIPAA |
| Threat Hunting | 58 | Low — operational SOC work |
| Threat Intelligence | 52 | Low — STIX/TAXII, MISP, feed integration |
| Digital Forensics | 41 | Low — disk imaging, memory forensics |
| Malware Analysis | 39 | Low — reverse engineering, sandboxing |
| Red Teaming | 33 | Low — ADCS, BloodHound, C2 frameworks |
| Incident Response | 26 | Low-Medium — breach containment patterns |
| Penetration Testing | 21 | Low — operational pentesting |
| Others (12 domains) | ~150 | Low — OT/ICS, mobile, hardware, deception |

---

## Comparison: Their Security Coverage vs Ours

| Area | Anthropic-Cybersecurity-Skills | kiro-rails | Assessment |
|------|-------------------------------|------------|------------|
| AI/Agentic Security | 14 skills (LLM red-team, prompt injection) | `review-ai-agent-surface.md` (25KB, ASI01-10, MCP Top 10) | **We're significantly deeper** |
| Code Security Review | Not a focus (practitioner ops) | `review-code-security.md` (19KB, OWASP S1-S13) + 2 agents | **We're much deeper** |
| Supply Chain | 8 skills (SBOMs, dep confusion) | `review-dependency-risk.md` + T3 hook (D1-D5) | **Comparable** |
| CI/CD Security | Within DevSecOps (18 skills) | `review-cicd-pipeline.md` (14KB) | **Comparable** |
| IaC Security | Within Cloud Security (66 skills) | `review-iac-consistency.md` (15KB) | **Comparable** |
| Compliance Mapping | 6 frameworks per skill (strength) | No framework tagging on findings | **They're better here** |
| Process Integration | None (reference-only) | 3-tier review, hooks, adversarial verifier | **We're much better** |
| Incident Response | 26 structured skills | No IR skill/prompt | **They cover, we don't** |
| Threat Modeling | No explicit coverage | Recommended in review-policy.md but no skill | **Neither does well** |

---

## Actionable Improvements for kiro-rails

### Priority 1: Borrow for Security Review Prompts

These improvements enhance our existing `review-code-security.md` and `review-ai-agent-surface.md` with patterns from their operational knowledge:

1. **Add NIST CSF + ATT&CK mapping to SRR output format**
   - Each finding gets a `Frameworks:` row: `NIST CSF DE.CM-01 | ATT&CK T1190 | D3FEND D3-WAF`
   - Effort: Small (add template row)
   - Value: Compliance reporting for regulated teams

2. **Add supply chain verification checklist to T3 review**
   - Inspired by their 8 supply chain skills: SBOM generation, dependency confusion checks, SLSA verification, Sigstore verification
   - Concrete checks: verify lockfile integrity, check for typosquatting, audit transitive deps
   - Effort: Medium (expand review-dependency-risk.md)

3. **Add cloud-specific security checks to IaC review**
   - Their 66 cloud security skills cover patterns we don't check: S3 public access, IAM privilege escalation paths, VPC flow log gaps, KMS key rotation
   - Add a "Cloud Hardening Checklist" section to review-iac-consistency.md
   - Effort: Medium

4. **Enhance API security checks**
   - Their 28 API security skills cover GraphQL-specific attacks (introspection, batching, depth attacks), rate limit bypass, and WAF evasion
   - Add GraphQL-specific checks to review-api-contracts.md
   - Effort: Small

### Priority 2: New Skills

5. **`incident-response` skill**
   - Activates on: "breach", "compromise", "incident", "forensics", "containment"
   - Provides: containment checklist, evidence preservation steps, communication templates, recovery verification
   - Effort: Medium

6. **`threat-modeling` skill**
   - Activates on: "external API", "auth", "file upload", "payment", "new endpoint"
   - Provides: STRIDE checklist, trust boundary identification, data flow audit prompts
   - Effort: Medium

### Priority 3: Structural Improvements

7. **Add `references/` sub-files to security prompts**
   - Their pattern of `references/standards.md` alongside each skill allows progressive loading
   - We could add companion reference files to our prompts for framework-specific checklists
   - Effort: High (requires curating reference material)

8. **Add `## Activation Triggers` section to review prompts**
   - Their "When to Use" pattern is self-documenting
   - Our hooks already handle triggering, but documenting conditions in-prompt aids manual use
   - Effort: Small

---

## What We Should NOT Adopt

1. **Offensive/red-team skills** — Wrong audience (we serve developers, not pentesters)
2. **Tool-specific operational runbooks** — Volatility3, BloodHound, Sliver C2 are analyst tools
3. **Their skill format verbatim** — Their format optimizes for operational execution; ours optimizes for development decisions
4. **Quantity over depth** — 817 skills is a knowledge base. We're a process template. 5-10 well-integrated skills > 100 reference skills

---

## Conclusion

The repos serve fundamentally different purposes:
- **Theirs:** "Give an AI agent practitioner-level security *knowledge*" (operational reference library)
- **Ours:** "Give an AI agent engineering *discipline*" (process enforcement with hooks, agents, reviews)

The overlap is in security, where we can borrow their **compliance framework tagging**, **supply chain verification depth**, **cloud hardening patterns**, and **API-specific attack knowledge** to strengthen our existing review prompts. Their incident-response and threat-modeling patterns fill genuine gaps in our skill library.

The key insight: they provide breadth across 29 operational domains; we provide depth of integration with automated enforcement. These are complementary, not competitive.
