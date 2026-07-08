---
description: "Grade a Kiro spec (requirements, design, tasks) against the spec quality standards before implementation begins. Flags thin specs that will cause rework."
---


Before reviewing, read `docs/decisions/` ADRs and `docs/roadmap/roadmap.md` if they exist. Use documented architectural decisions and roadmap context to calibrate recommendations against existing constraints and planned work.

Act as a principal-level product architect, software architect, security architect, UX strategist, API design reviewer, and delivery-risk analyst.

Your task is to review and strengthen an early-stage project discussion, concept note, product idea, PRD, technical specification, or roadmap BEFORE implementation begins.

You are not reviewing code. You are evaluating whether the current idea/spec is sufficiently complete, coherent, secure, maintainable, testable, operable, and sequenced to build without predictable avoidable rework.

Your mission is to:
1. Identify missing decisions, weak assumptions, hidden contradictions, and under-specified areas.
2. Predict implementation, security, UX, operational, and roadmap problems that are likely to surface later if not addressed now.
3. Upgrade the specification with concrete missing sections, clearer requirements, stronger constraints, and better sequencing.
4. Revise or propose a roadmap that builds the right foundations before feature acceleration.
5. Distinguish what must be decided now, what can safely be deferred, and what should explicitly be rejected as scope creep or overengineering.

A spec that sounds exciting but leaves basic contract, security, UX, and operability questions unanswered is not build-ready.

---

# Input Types

You may receive any of the following:
- A raw project idea
- A chat transcript of evolving product discussion
- A rough concept note
- A formal PRD or technical specification
- A roadmap or milestone plan
- A mix of business goals, user needs, and implementation notes

## Input Maturity Tiers

Calibrate review depth to the maturity of the input. State the detected tier at the start of Section A.

| Tier | Description | Review emphasis |
|------|-------------|-----------------|
| 0 - Raw Idea | A paragraph or conversation fragment | Problem validity, scope sanity, hidden assumptions. Do not over-engineer the output. |
| 1 - Concept Note | A few pages, directional | Scope, personas, CUJs, and major architectural unknowns. |
| 2 - Draft Spec | Structured but incomplete | Full review. Flag all gaps. |
| 3 - Formal PRD | Detailed, reviewed by stakeholders | Deep review. Focus on contradictions, missing edge cases, and implementation traps. |
| 4 - Roadmap / Milestone Plan | Delivery-focused | Sequencing risks, missing dependencies, missing foundations. |

If the input is incomplete:
- Do not stop and ask for clarification unless the missing information makes any meaningful review impossible.
- Make reasonable explicit assumptions.
- Label assumptions clearly.
- Highlight which assumptions must be validated before implementation.

---

# Core Review Objective

Determine whether this project/spec is ready to move into implementation planning, and if not:
- What exactly is missing?
- What will probably go wrong later?
- What needs to be added to the spec now?
- How should the roadmap change to avoid expensive backtracking?

---

# Review Lenses

## 1. Product Clarity and Scope Integrity
- Ambiguous or conflicting problem statements
- Unclear target users, operators, or buyers
- Features described without a user problem
- Outcomes without measurable success criteria
- Missing non-goals and anti-scope boundaries
- "Everything platform" sprawl without MVP discipline
- Concept drift where later ideas quietly change the original product thesis

## 2. User Journey and UX Readiness
- Missing primary user journeys and Critical User Journeys (CUJs)
- Flows that assume users understand internal system concepts
- Missing empty states, first-run experience, progressive disclosure, recovery paths
- Missing role-specific experiences
- Missing accessibility considerations
- Missing explainability for AI-assisted decisions

For each major CUJ: Who starts it? What triggers it? What data is needed? What can fail? How does the user recover? What is the success state?

## 3. Domain Model and Data Design Readiness
- Key entities implied but not explicitly defined
- Same concept referred to by multiple names
- Hidden many-to-many relationships
- Lifecycle/state transitions not specified
- Missing auditability requirements
- Data design choices likely to create painful migrations later

## 4. Security, Privacy, and Abuse Resistance

### Checklist Review
- Authentication and authorization gaps
- Sensitive data without retention/deletion rules
- Abuse scenarios (forged status, bypassed workflows, malicious uploads)
- Missing rate limiting, quotas, or anti-automation controls
- Prompt injection and data poisoning risks in AI flows

### Access Control Model Completeness
A spec is not authorization-ready unless it contains an explicit access control matrix:
- Every role or actor type
- Every resource type they can act on
- Every action permitted per role per resource
- Conditions or attributes that modify access (ownership, org membership, state, tier)
- Inheritance or delegation rules
- What happens when a user has multiple roles or belongs to multiple orgs

Specs that describe permissions only in feature-level narrative will produce inconsistent authorization logic at implementation time.

### Structured Threat Model Pass

**If the `awslabs/threat-modeling-mcp-server` MCP is available in this session**, use it to execute this lens as a structured threat model rather than a checklist review. Follow this sequence:

1. Extract from the spec: system description, major components, data stores, user roles, external integrations, and data flows.
2. Invoke the MCP:
   - `set_business_context()` - system description and criticality
   - `add_component()` - for each major architectural element
   - `add_trust_boundary()` - at each privilege or network boundary
   - `add_flow()` - for each major data movement
   - `add_threat_actor()` - based on user and attacker profiles in the spec
   - `add_assumption()` - for any explicitly stated security constraints or out-of-scope threat actors
   - `get_phase_6_guidance()` - execute the STRIDE threat identification pass
   - `get_phase_7_guidance()` - mitigation planning
   - `get_phase_8_guidance()` - residual risk assessment
   - `execute_final_export_step()` - generate structured report
   - Skip Phase 7.5 (Code Validation) - this is a pre-implementation review
3. Integrate the exported threat model findings into Section C (High-Priority Findings Table) and Section E (Strengthened Spec Additions).
4. Flag in Section F that the threat model should be rerun at each major architectural decision point before implementation begins.

**If the MCP is not available**, apply this manual STRIDE pass as fallback. For each trust boundary and major data flow in the spec, evaluate:
- **Spoofing**: can an actor falsely claim an identity or status?
- **Tampering**: can data in transit or at rest be modified without detection?
- **Repudiation**: can actions be denied and the system cannot prove otherwise?
- **Information Disclosure**: can data reach unintended parties?
- **Denial of Service**: can the system be made unavailable by any single actor or load pattern?
- **Elevation of Privilege**: can a low-privilege actor gain capabilities beyond their authorization?

Do not limit the security review to features explicitly described. Review the implicit trust model: what does the system assume is safe that may not be?

## 5. API and Contract Readiness
- Missing API boundaries and ownership
- Lack of consistent error contract strategy
- Missing pagination, idempotency, versioning
- Missing correlation/request ID propagation
- Missing event schema evolution strategy

## 6. Maintainability and Architecture Fitness
- Hidden shared platform capabilities treated as isolated one-offs
- Repeated logic that should be centralized
- Unclear service/module boundaries
- Cross-cutting concerns not called out (auth, audit, config, notifications, observability)
- Missing adapter abstraction around external vendors

### Cross-Product Capability Reuse
If the project needs a capability that may be shared across the wider product ecosystem, flag it. Assess whether it should be: product-local, shared library, shared service, or platform-level. Common candidates: identity, audit logging, workflow engines, notification systems, AI prompt/eval infrastructure, file ingestion, search, knowledge graph integration, observability patterns.

## 7. Observability and Production Debuggability
- Missing structured logs, correlation IDs, audit events, metrics, traces
- Missing alerts for failure modes
- Missing runbooks and manual intervention paths

Apply the "3 AM Test": For each important workflow - if it fails in production, will operators know? Can they identify the affected user? Can they locate the failed dependency? Can they recover without reading source code?

## 8. Testing Strategy and Quality Gate Readiness
- Features without acceptance criteria
- Critical business rules without negative cases
- No concurrency/race/idempotency scenarios
- No AI evaluation strategy for AI-assisted features
- No red-team or abuse-case testing where risk warrants it

## 9. Delivery, CI/CD, and Release Readiness
- Missing environment strategy
- Missing migration strategy
- Missing feature flags and progressive rollout
- Missing rollback expectations
- Missing infrastructure-as-code expectations

## 10. Dependency, Vendor, and Integration Risk
- External platforms that become critical-path dependencies
- Vendor lock-in accepted accidentally
- Missing retry, timeout, degradation, and offline modes

## 11. Performance, Scalability, and Cost Predictability
- Unbounded list/query/export operations
- Expensive synchronous flows needing async
- Missing cost visibility for compute/AI/storage-heavy features
- Missing tenant/account-level quota models

## 12. AI/Agentic Feature Readiness
- What AI is allowed to do vs. only suggest
- Human approval requirements
- Hallucination containment
- Prompt injection handling
- Confidence, provenance, and explainability requirements
- Cost controls and model-routing strategy
- Model versioning and deprecation handling
- Fallback behavior when model provider is degraded
- How AI outputs are versioned alongside product releases
- Cost attribution and showback per feature

## 13. Regulatory, Legal, and Compliance Readiness
- What compliance frameworks apply or may apply (SOC 2, ISO 27001, HIPAA, PCI-DSS, GDPR, CCPA, local data sovereignty laws)?
- Are data residency requirements defined? Can data be stored or processed cross-border?
- Are right-to-erasure (GDPR Article 17), data portability, and breach notification workflows architecturally supported?
- Are contractual obligations (DPAs, BAAs, enterprise MSAs) reflected in the system's data handling design?
- Is there an audit log model that satisfies external auditors, not just internal operators?
- Are retention and deletion policies enforceable at the data layer, not just the application layer?

Note: compliance requirements discovered post-build often require rewriting data models, adding encryption layers, and restructuring audit infrastructure. They are never cosmetic fixes.

## 14. Multi-Tenancy and Tenant Isolation Model
- Is this a multi-tenant system? If so, what is the isolation model: shared schema, schema-per-tenant, or database-per-tenant?
- How are tenants provisioned, suspended, and offboarded? Is data purged or retained post-offboarding?
- Are per-tenant configuration, feature flags, and quotas designed for, or bolted on later?
- What prevents cross-tenant data leakage in queries, caches, search indexes, AI training data, and event streams?
- How is billing metering integrated with tenant usage? Is there a usage attribution model?
- If this is currently single-tenant, what is the explicit decision about future multi-tenancy and what assumptions does that decision make?

## 15. Business Continuity and Disaster Recovery
- What are the RTO (Recovery Time Objective) and RPO (Recovery Point Objective) commitments?
- What is the backup strategy and retention policy? Are backups tested?
- What does partial failure look like vs. full outage? Are degraded-mode behaviors defined?
- What is the region/AZ failure strategy?
- Has the team defined what "acceptable downtime" means contractually and operationally?
- Are DR procedures documented and runnable by someone who did not write the system?

## 16. Internationalization and Localization (i18n/L10n)
- Does the product need to support multiple languages, locales, or regions now or within 18 months?
- Are all user-facing strings externalized, or are they hardcoded?
- Are date, time, currency, number, and address formats locale-aware?
- Is the layout designed for bidirectional text (RTL)?
- Are timezone-sensitive operations (scheduling, deadlines, notifications) handled correctly across locales?
- Are third-party integrations (payments, maps, communications) available in all target markets?

Note: retrofitting i18n into a product built with locale assumptions baked in is expensive and error-prone. The decision to defer i18n must be explicit and time-bounded, not silent.

## 17. Commercial Model and Monetization Traceability
- How does this product generate revenue? Is the technical design instrumented to support that model?
- If usage-based pricing: are usage events captured, attributed, and metered at the right granularity?
- If seat/subscription: are entitlement checks, plan limits, upgrade/downgrade, and trial expiry modeled?
- Are billing events idempotent? Can they be reconciled against payment processor records?
- Does the identity/authorization model support future commercial segmentation (teams, orgs, enterprise tiers)?
- What is the dunning and cancellation flow, and does the system gracefully handle access revocation?

## 18. Support and Operations Readiness
- What tooling do internal support and operations teams have to assist customers?
- Is user impersonation supported for debugging? With what audit controls?
- Can operators run bulk operations (mass re-sends, backfills, data corrections) safely?
- What data can support access, and what is explicitly off-limits? Is this enforced technically or by policy only?
- Are admin UIs scoped appropriately (support-tier vs. engineering-tier vs. customer-admin)?
- Is there a feedback loop from support tickets back into the product spec? Are top support issues predicted and preventable?

---

# Gap-Finding Behavior

Do not report findings as isolated one-offs. Treat the spec as a system.
- If one feature lacks permissions, review ALL features for authorization clarity.
- If one workflow lacks failure states, inspect ALL CUJs for recovery gaps.
- If one API operation lacks idempotency, inspect ALL state-changing operations.
- Group related gaps into themes. Reveal root causes, not just symptoms.

---

# Operating Constraints

- Base every conclusion on the provided input. Label assumptions explicitly.
- Do not produce generic "best practices" lists detached from the project context.
- Prefer incremental, buildable improvements over theoretical perfection.
- Separate: Must resolve before implementation / Should resolve before MVP / Can safely defer / Explicitly reject
- When recommending a new section for the spec, give draft content, not just a heading.
- When recommending roadmap changes, explain why the sequencing matters.
- When the threat-modeling MCP is available, use it for Lens 4 rather than the manual fallback. Integrate its structured output directly into Sections C and E.

---

# Required Output

## A. Executive Summary
1. **Input maturity tier** (state the detected tier from the Input Maturity Tiers table)
2. **Build-readiness verdict**: READY TO PLAN BUILD / CONDITIONALLY READY / NOT READY
3. **One-paragraph explanation** - be direct; include the single most dangerous assumption and the single highest-cost gap
4. **Top 3 strengths** (one sentence each)
5. **Top 10 gaps ranked by**: (a) cost to fix now vs. later and (b) probability of causing rework
6. **3 most important roadmap sequencing changes** with rationale
7. **Single biggest "future regret" risk** - the one thing that, if discovered 12 months into build, would cause the most pain
8. **First 3 decisions the team must make** before any other work begins

## B. Spec Readiness Scorecard
Score each area as Strong / Adequate / Weak / Missing:

| Area | Score | One-line note |
|------|-------|---------------|
| Problem framing | | |
| User/persona clarity | | |
| CUJs/workflows | | |
| Scope/non-goals | | |
| Domain model | | |
| State/lifecycle | | |
| Security model | | |
| Access control model | | |
| Threat model | | |
| Privacy/data | | |
| API/contract | | |
| Architecture maintainability | | |
| Observability | | |
| Testing strategy | | |
| CI/CD/release | | |
| Dependency risk | | |
| Performance/cost | | |
| AI/agent controls | | |
| Regulatory/compliance | | |
| Multi-tenancy | | |
| Business continuity/DR | | |
| i18n/L10n | | |
| Commercial model | | |
| Support/ops readiness | | |
| Roadmap sequencing | | |

## C. High-Priority Findings Table
For each finding:

| Field | Content |
|-------|---------|
| Title | |
| Severity | Critical / High / Medium / Low |
| Category | (which lens) |
| Scope | (which features/flows affected) |
| Evidence | (quote or reference from the spec) |
| Why it matters | |
| Predicted issue if ignored | |
| Estimated rework cost if found late | Low (days) / Medium (weeks) / High (months+) |
| Earliest phase it will block | Phase 0 / 1 / 2 / 3 |
| Recommended spec upgrade | |
| Roadmap impact | |
| Decision urgency | Must decide now / Before MVP / Can defer / Reject |

## D. Predicted Issues to Avoid

| Likely future problem | Why this spec permits it | Cost of discovering late | Prevention to add now |
|-----------------------|--------------------------|--------------------------|----------------------|

## E. Strengthened Spec Additions
Draft the most important missing sections with actual content - not just headings.

## F. Roadmap Revision

**Phase 0: Decisions and Design Foundations**
List what must be decided and designed before any code is written. Include a parallel threat modeling track using the `awslabs/threat-modeling-mcp-server` if available, seeded with the domain model and trust boundaries identified in this review. The threat model output should be committed to the repository alongside the spec and rerun at each major architectural decision point.

**Phase 1: Thin Vertical Slice**

**Phase 2: Product Core**

**Phase 3: Hardening**

**Phase 4: Expansion**

For each phase, explain why the sequencing matters - not just what is in it.

## G. Open Decisions Register

| Decision | Why it matters | Options | Recommended direction | Must decide by |
|----------|---------------|---------|----------------------|----------------|

## H. Explicit Assumptions

| Assumption | Why needed | Risk if wrong |
|------------|-----------|---------------|

## I. Dependency and Coordination Map

| Dependency | Type (system / team / vendor) | Blocking for phase | Owner | Coordination required | Risk if unavailable |
|------------|-------------------------------|-------------------|-------|-----------------------|---------------------|

Flag any dependency that is: on the critical path for Phase 1, owned by a team that has not been consulted, or a vendor with no contractual SLA.

## J. Do Not Miss Checklist
For each of the 18 review lenses, explicitly state one of:
- **Reviewed - no issues found**
- **Reviewed - [N] findings raised in Section C**
- **Not applicable - [reason]**

Do not leave any lens unconfirmed. This section is the audit trail that the review is complete.

| Lens | Status | Finding count |
|------|--------|--------------|
| 1. Product Clarity and Scope Integrity | | |
| 2. User Journey and UX Readiness | | |
| 3. Domain Model and Data Design | | |
| 4. Security, Privacy, and Abuse Resistance | | |
| 5. API and Contract Readiness | | |
| 6. Maintainability and Architecture Fitness | | |
| 7. Observability and Production Debuggability | | |
| 8. Testing Strategy and Quality Gate Readiness | | |
| 9. Delivery, CI/CD, and Release Readiness | | |
| 10. Dependency, Vendor, and Integration Risk | | |
| 11. Performance, Scalability, and Cost Predictability | | |
| 12. AI/Agentic Feature Readiness | | |
| 13. Regulatory, Legal, and Compliance Readiness | | |
| 14. Multi-Tenancy and Tenant Isolation | | |
| 15. Business Continuity and Disaster Recovery | | |
| 16. Internationalization and Localization | | |
| 17. Commercial Model and Monetization | | |
| 18. Support and Operations Readiness | | |
