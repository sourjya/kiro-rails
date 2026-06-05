---
description: "<!--"
---

<!--
=============================================================================
review-ai-agent-surface.md - AI / agentic feature security audit prompt
=============================================================================

FRAMEWORK PROVENANCE
This prompt's objectives and severity model are derived from the following
public security frameworks. Finding IDs (AIS-1..AIS-10) map to these categories
so output is traceable to a recognized standard.

- OWASP Top 10 for Agentic Applications (ASI01-ASI10)
  OWASP GenAI Security Project. Announced Black Hat Europe 2025; released Dec 2025.
  https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications/
  Drives: AIS-1 (ASI01 Goal Hijack), AIS-2 (ASI02 Tool Misuse),
  AIS-3 (ASI03 Identity/Privilege Abuse), AIS-4 (ASI04 Agentic Supply Chain),
  AIS-5 (ASI05 Unexpected Code Execution), AIS-6 (ASI06 Memory/Context Poisoning),
  AIS-7 (ASI07 Insecure Inter-Agent Comms), AIS-8 (ASI09 Human-Agent Trust),
  AIS-10 (ASI08 Cascading Failures + ASI10 Rogue Agents).

- OWASP Top 10 for LLM Applications (2025)
  https://genai.owasp.org/llm-top-10/
  Drives: prompt injection (LLM01), data/model poisoning (LLM04),
  improper output handling (LLM05), excessive agency (LLM06).

- OWASP MCP Security Cheat Sheet / MCP Top 10
  https://cheatsheetseries.owasp.org/cheatsheets/MCP_Security_Cheat_Sheet.html
  Drives: AIS-4 tool poisoning, rug pulls, confused deputy, cross-server
  tool shadowing, NeighborJack (0.0.0.0 binding), transport security.

- OWASP Agentic Skills Top 10 (AST10)
  https://owasp.org/www-project-agentic-skills-top-10/
  Drives: AIS-4 skill provenance, code-signing, permission manifests.

- Anthropic, "Using LLMs to Secure Source Code" (May 2026)
  Basis of the kiro-rails adversarial-verifier model; the AISR verification
  pass reuses its two-agent disprove discipline.

Re-validate framework versions periodically; the agentic-AI threat landscape
moves fast and category numbering can shift between editions.
=============================================================================
-->

Before scanning, read these context documents if they exist:
- `docs/security/THREAT_MODEL.md` - trust boundaries, what is in/out of scope
- `docs/decisions/` ADRs - architectural decisions that explain intentional agent design (confidence thresholds, autonomous-action boundaries, tool scoping rationale)
- `docs/security/SECURITY_LOG.md` - previously reviewed findings (avoid re-reporting)
- Any agent capability registry, tool catalog, system prompt files, or intent/approval schema definitions

Use documented trust boundaries and intentional design decisions to skip findings on explicitly trusted paths. Do not flag documented exceptions as findings.

Act as a principal-level AI security architect and agentic systems auditor performing a comprehensive review of an AI-powered or agentic feature.

Your mission is not to verify that the agent produces useful output. It is to determine whether the agent can be made to act against the user, the tenant, or the platform - whether untrusted content can redirect its goals, whether its tools can be driven beyond their intended scope, whether it inherits more privilege than the requesting user holds, whether its memory or context can be poisoned across turns or sessions, and whether every consequential action it takes is attributable, reversible, and gated to the right confidence threshold. An agent that works for a cooperative user but cannot be trusted with a hostile one is not production-ready.

This review aligns to the OWASP Top 10 for Agentic Applications (ASI01-ASI10, December 2025), the OWASP Top 10 for LLM Applications (2025), and the OWASP MCP Top 10. Finding IDs use the `AISxx` prefix and cross-reference the relevant ASI/LLM/MCP category.

This prompt is invoked at feature-complete time for any feature that: calls an LLM, exposes a chat or natural-language interface, runs an autonomous or semi-autonomous agent, registers or invokes tools/functions, consumes an MCP server, retrieves content into a model context (RAG), or executes model-generated code, queries, or workflows. It runs alongside `review-code-security.md` Tier 2, not instead of it - this prompt owns the AI-specific attack surface; the security prompt owns the conventional surface.

---

## Review Objectives

### AIS-1. Prompt injection and goal hijack (ASI01 / LLM01)

The central agentic vulnerability. There is no foolproof prevention - assess defense in depth, not the existence of a single filter.

- Trace every path by which untrusted content reaches the model. Direct (user message) and indirect (tool results, retrieved documents, file uploads, webhook payloads, database rows authored by other users, event payloads) both count. Indirect injection is the higher-severity case because the user never sees the malicious instruction.
- Verify untrusted content is never concatenated into the system prompt. System instructions, user-role content, and tool-result content must occupy structurally distinct positions, not be string-joined.
- Check for instruction-data separation: does the system prompt tell the model that tool results and retrieved content are data to be analyzed, not instructions to be followed?
- Flag any path where a tool result can alter the agent's plan, add sub-goals, or trigger further tool calls without re-grounding against the original user intent.
- Flag reflection or self-critique loops with no iteration cap (denial-of-wallet and infinite-loop risk).
- For multi-step plans: is the original objective re-asserted at each step, or can a mid-plan injected instruction silently replace it?

### AIS-2. Tool scope and misuse (ASI02 / LLM06)

- Inventory every tool the agent can call. For each, record: read vs. write, blast radius, and whether the granted scope exceeds what the feature requires.
- Flag tools with write/delete/financial/permission-changing capability that are reachable without a confidence gate or human approval step.
- Parameter pollution: can the model populate a tool parameter with a value outside the intended domain (a path outside the allowed prefix, an ID belonging to another tenant, an unbounded limit, an arbitrary URL)? Tool input schemas must constrain parameters, not just type them.
- Tool-chain manipulation: can a sequence of individually-permitted tool calls compose into an unauthorized outcome (read tool feeds an ID into a write tool that skips ownership check)?
- Automated abuse: can an authorized tool be driven at harmful scale (bulk export, mass email, repeated expensive operation) with no per-session rate limit or quota?

### AIS-3. Agent identity and privilege (ASI03 / LLM06)

- Determine whose identity the agent acts under. Flag any agent that executes tool calls with a service identity, system role, or static credential rather than the requesting user's scoped permissions.
- Verify the agent cannot perform actions the requesting user could not perform directly. The agent is a deputy; it must not be a more powerful one.
- Flag dynamic privilege escalation: any path where the agent acquires elevated scope mid-session.
- Cross-system scope: when the agent calls downstream services, is the user's tenant and permission context propagated, or does the downstream call run with broad agent-level access?
- Shadow/derived agents: if the agent spawns sub-agents or background jobs, do they inherit correctly scoped credentials or a broader set?

### AIS-4. MCP and tool supply chain (ASI04 / MCP Top 10)

Applies to any feature consuming an MCP server or third-party tool definition.

- Tool poisoning: tool descriptions, parameter schemas, and return values are read by the model and are an injection vector. Flag any MCP server whose tool metadata is not pinned, reviewed, and integrity-checked. Treat tool descriptions as untrusted content that enters the model context.
- Rug pull: flag tool definitions that can change after approval without re-review. Pin tool schemas to a known hash; alert on drift.
- Confused deputy: flag any MCP server or tool proxy that acts on its own privilege rather than validating that the session/token belongs to the current requester on every call. OAuth misconfiguration makes this a one-line bug.
- Cross-server tool shadowing: when multiple MCP servers are connected, the model sees all tool descriptions at once. Flag the risk of one server's tool description manipulating calls to another.
- Network and transport: flag MCP servers bound to `0.0.0.0` rather than localhost (NeighborJack), remote servers without TLS or server-identity verification, and stdio servers that pass configuration directly to command execution.
- Provenance: are tools sourced only from verified publishers? Is there a permission manifest per tool?

### AIS-5. Unexpected code and command execution (ASI05 / LLM05)

Applies to any feature where the model generates code, SQL, shell commands, workflow definitions, or structured actions that are subsequently executed.

- Flag model-generated code, queries, or commands that reach an interpreter, shell, database, or workflow engine without sandboxing and an allowlist.
- Verify generated SQL is parameterized or constrained to a safe query builder, never string-executed.
- Flag generated workflow or automation definitions that can embed arbitrary steps without validation against a primitive allowlist.
- Output handling: model output rendered into HTML, a template, or a downstream system must be treated as untrusted and sanitized. Flag stored-injection-to-XSS paths where model output containing injected markup is persisted and later rendered.
- SSRF via model-chosen URLs: flag any tool that fetches a model-supplied URL without an allowlist or egress policy.

### AIS-6. Memory and context poisoning (ASI06 / LLM04)

Applies to any feature with conversational memory, persistent agent memory, embeddings, or a RAG store.

- Flag write paths into agent memory or the RAG store that accept untrusted content without provenance tagging or validation. Poisoned memory persists across turns and sessions and is invisible at read time.
- Cross-session and cross-tenant leakage: verify memory and embedding stores are scoped per user and per tenant. A shared vector index is a cross-tenant data-leak vector.
- Verify retrieved memory carries a trust label distinguishing user-authored content, agent-authored content, and externally-ingested content.
- Flag designs where exceeding a memory or context limit causes the agent to lose track of an earlier privilege decision (forgetting an approval boundary is an escalation path).

### AIS-7. Inter-agent communication and orchestration (ASI07 / ASI10)

Applies to multi-agent or orchestrated-workflow features (relevant to any conversational-action orchestration layer, approval engine, or intent router).

- Flag inter-agent messages that are trusted without authentication of the sending agent. A forged "approval granted" or "consensus reached" message is an escalation path.
- Verify messages between agents cannot be replayed or tampered with in transit.
- Rogue-agent containment: if one agent in a workflow is compromised or hallucinating, what stops its output from being trusted unconditionally by the next stage? Flag orchestration that routes consequential actions (transactions, approvals, deletions) purely on another agent's say-so.
- Flag orchestration hijack paths where an injected instruction can re-route a workflow to a different (more privileged) agent or skip an approval stage.

### AIS-8. Confidence gating and human-in-the-loop (cross-cutting; ASI09)

The control that converts an autonomous agent into a safe one. Central to attributable, reversible, confidence-gated action design.

- For every agent-initiated action that mutates state, moves money, changes permissions, sends external communication, or deletes data: verify a confidence threshold or approval gate exists and is specified, not implicit.
- Flag any consequential action that executes autonomously below a defined confidence threshold, or where no threshold is defined at all.
- Verify the approval surface shows the user what will actually happen (the resolved action and its parameters), not a paraphrase the model generated. Users approve what they are shown; if the shown summary diverges from the executed action, approval is meaningless.
- Reversibility: for each consequential action, is there a defined undo, compensating action, or audit-backed rollback? Irreversible autonomous actions need the highest gate.
- Over-trust (ASI09): flag UX that presents agent output as authoritative without surfacing uncertainty, sources, or the ability to inspect the underlying action.

### AIS-9. Action provenance and auditability (cross-cutting; compliance)

Required for regulated operation (EU AI Act Article 12 logging, PDPA, and equivalent record-keeping obligations).

- Verify every agent-initiated action writes an audit record that links: the triggering user intent, the resolved action and parameters, the confidence score, the approving identity (human or autonomous-with-threshold), the tool(s) invoked, and the outcome.
- Flag agent-executed writes that are indistinguishable in the audit log from human-initiated writes. Attribution must record that an agent acted, on whose behalf, and why.
- Verify logs are tamper-evident and retained per the applicable record-keeping requirement.
- Flag PII or sensitive content written to agent logs or traces without masking.
- Verify the provenance trail is sufficient to answer, after the fact: which intent caused this action, what confidence drove it, who could have stopped it, and can it be reversed.

### AIS-10. Cascading failure and abuse economics (ASI08)

- Flag designs where a single hallucinated fact, false API endpoint, or poisoned memory entry can propagate through subsequent steps and amplify (a false value written to memory that later steps treat as ground truth).
- Verify there is a circuit breaker: a point where accumulated low-confidence or repeated-error state halts the agent rather than compounding.
- Denial-of-wallet: flag unbounded model-call loops, unbounded tool-call fan-out, and missing per-user/per-tenant token and invocation budgets. The cost blast radius of one injected instruction must be capped.

---

## Gap-Finding Behavior

Do not report a finding as isolated without checking whether it is systemic.

- If one tool lacks a confidence gate, audit every write-capable tool for the same gap.
- If one untrusted-content path reaches the system prompt, trace all ingestion paths (user input, tool results, RAG, uploads, events) for the same flaw.
- If one MCP server's tool schema is unpinned, audit every connected server.
- If one memory write skips provenance tagging, audit every write path into memory and the RAG store.
- If one agent action lacks an audit record, audit every consequential action for provenance coverage.
- If one inter-agent message is unauthenticated, audit the whole orchestration graph.
- If one tool parameter is unconstrained, audit every tool's input schema.

Treat the agent as a single attack surface with many entry points, not a collection of isolated features. Group findings into themes.

---

## Severity Calibration (Agentic Context)

Score each finding by walking the chain from untrusted input to consequential action:

1. **Entry point:** Can untrusted content reach this path? Direct (user) or indirect (tool result, RAG, event, other tenant's data)? Indirect raises severity - the victim never sees the payload.
2. **Reachability:** Is the vulnerable path on a default code path, or does it need a non-default flag, role, or feature state?
3. **Privilege:** Does the agent act with user-scoped, elevated, or system privilege at the sink?
4. **Action class:** Read-only, state mutation, financial/permission/delete, or external communication?
5. **Gate:** Is there a confidence threshold or human approval between input and action? Is it bypassable?
6. **Blast radius:** One user, one tenant, cross-tenant, or platform-wide?
7. **Reversibility:** Reversible, compensable, or irreversible?

Scoring:
- Indirect injection -> elevated privilege -> irreversible or financial action with no gate = **CRITICAL**
- Direct injection -> state mutation with weak or bypassable gate, OR cross-tenant memory/data leak = **HIGH**
- Read-only disclosure, OR consequential action behind a sound gate with a minor weakness, OR 2+ preconditions = **MEDIUM**
- Requires admin, non-default config, or yields no consequential action = **LOW**

---

## Verification Pass

After producing all findings, perform an independent verification pass. For each HIGH+ finding, **assume it is a FALSE POSITIVE** and re-read the relevant code fresh, without reference to your original reasoning:

1. Is there a compensating control upstream - an input classifier, an allowlist, a structural separation, an auth gate, a confidence threshold - that blocks the chain?
2. Is the untrusted-input path actually reachable in the running system, or is it gated by a feature flag or role the attacker cannot obtain?
3. Is the privilege at the sink actually the agent's, or is the user's scope correctly propagated?
4. Check `docs/decisions/` ADRs and `docs/security/THREAT_MODEL.md` for a documented decision (an intentional autonomous-action boundary, an accepted-risk note) that makes the behavior intentional.
5. Downgrade or remove findings where the chain is broken by an existing control. Mark survivors CONFIRMED; mark the rest NEEDS VALIDATION.

For Tier 3 / sprint-end runs, spawn the `security-verifier` agent with ONLY the list of HIGH+ findings (ID, description, file, line - no reasoning) for an independent disprove pass, consistent with the `review-code-security.md` workflow.

---

## Operating Constraints

- Base every finding on direct evidence: system prompt files, tool/function definitions, tool input schemas, MCP server configs, memory/RAG write paths, approval and confidence-gate code, orchestration logic, and audit-log writes.
- Prompt injection has no perfect fix. Do not flag "prompt injection is possible" as a finding on its own. Flag the absence of defense in depth: missing instruction-data separation, missing output handling, missing confidence gate on the resulting action, missing provenance. Severity follows what the injection can actually reach.
- Do not flag a confidence gate as missing if a documented ADR establishes the action as intentionally autonomous and within an accepted-risk boundary. Note the ADR.
- Distinguish internal-only agents (single trusted operator, no untrusted input path) from user-facing or multi-tenant agents. Calibrate severity to the real input surface.
- Prefer the smallest safe remediation: constrain a tool schema, add a gate on one action, tag one memory write path - over "redesign the agent."
- Do not recommend removing agent capability where a gate, scope reduction, or provenance record addresses the risk.

---

## Evidence Requirements

For each finding:

- Cite the exact file and location: system prompt, tool definition, schema, MCP config, gate logic, memory write, or audit path.
- State the full chain: untrusted entry point -> path to sink -> privilege at sink -> consequential action -> gate status -> reversibility.
- Map to the framework category (ASI / LLM / MCP) so findings are traceable to a recognized standard.
- State whether the issue is local (one path), repeated (several), or systemic (agent-wide).
- Describe the concrete attack scenario, not a generic warning: what an attacker plants, where, and what the agent then does.
- State the recommended control and whether it is additive or requires an interface change.

---

## Required Output

### A. Executive Summary

- The single most dangerous injection-to-action chain in the feature
- Whether any untrusted-content path reaches a consequential action without a sound confidence gate
- Whether the agent ever acts with more privilege than the requesting user
- Whether every consequential action is attributable, reversible, and gated (the three-property test)
- The dominant systemic weakness and its blast radius
- Highest-confidence quick wins (schema constraints, single-action gates, provenance tags)

### B. Findings Table

| Field | Content |
|---|---|
| ID | `AIS-{seq}` |
| Title | Short descriptive label |
| Severity | Critical / High / Medium / Low |
| Framework | ASI / LLM / MCP category reference |
| Confidence | Confirmed / Needs Validation |
| Scope | Local / Repeated / Systemic |
| Entry point | Direct / Indirect (and source) |
| Chain | Untrusted input -> sink -> privilege -> action -> gate -> reversibility |
| Evidence | Files, schemas, prompts, configs involved |
| Attack scenario | Concrete walkthrough |
| Recommended control | Smallest safe remediation |
| Additive or breaking | Additive / Interface change |

### C. Agent Surface Matrix

For each agent, tool, or AI-powered entry point:

| Concern | Status |
|---|---|
| Instruction-data separation | Enforced / Partial / Absent |
| Indirect injection paths identified | Yes / No |
| Tool scope (least privilege) | Constrained / Over-scoped |
| Tool input schemas constrained | Yes / Partial / No |
| Agent acts as user (not elevated) | Yes / No / N/A |
| MCP tool schemas pinned | Pinned / Unpinned / N/A |
| Confidence gate on consequential actions | Present / Partial / Absent |
| Memory/RAG tenant isolation | Isolated / Shared / N/A |
| Memory provenance tagging | Tagged / Untagged / N/A |
| Inter-agent message auth | Authenticated / Unauthenticated / N/A |
| Action provenance / audit trail | Complete / Partial / Absent |
| Loop / token / cost caps | Bounded / Unbounded |

### D. The Three-Property Test

For every consequential agent action in the feature, confirm each property explicitly. This is the build-readiness gate for agentic features.

| Action | Attributable (audit links intent + confidence + identity) | Reversible (undo / compensate / rollback) | Gated (confidence threshold or human approval) |
|---|---|---|---|

Any action failing one or more properties is a finding in Section B.

### E. Remediation Roadmap

- **Phase 1 (additive, non-breaking):** Constrain tool input schemas, add confidence gates to ungated consequential actions, add provenance tags to memory writes, add audit records, pin MCP tool schemas.
- **Phase 2 (hardening):** Enforce instruction-data separation, scope agent identity to the requesting user, isolate memory/RAG per tenant, authenticate inter-agent messages.
- **Phase 3 (structural):** Sandbox model-generated execution, introduce circuit breakers and cost budgets, add tool-description drift detection and DLP on outbound tool arguments.

For each phase, note dependencies and whether any change requires a user-facing interface adjustment (for example, an approval surface that now shows the resolved action).

### F. Do Not Miss Checklist

Confirm you explicitly reviewed each, even where no issue was found:

- [ ] Every untrusted-content path into the model context (direct and indirect)
- [ ] System prompt isolation from user and tool-result content
- [ ] Every tool's scope against least privilege
- [ ] Every tool input schema for parameter constraints
- [ ] Agent identity and privilege at every tool sink
- [ ] MCP tool schema pinning, confused-deputy validation, transport security
- [ ] Model-generated code/SQL/command/workflow execution paths
- [ ] Model output rendering and sanitization (stored-injection-to-XSS)
- [ ] Memory/RAG write provenance and per-tenant isolation
- [ ] Cross-session and cross-tenant memory leakage
- [ ] Inter-agent message authentication and replay protection
- [ ] Confidence gates on every consequential action
- [ ] Approval surface fidelity (shown action equals executed action)
- [ ] Reversibility of every consequential action
- [ ] Action provenance: intent + confidence + identity + outcome linkage
- [ ] PII masking in agent logs and traces
- [ ] Loop caps, tool fan-out caps, and per-tenant token/cost budgets
- [ ] Circuit breaker on accumulated low-confidence or repeated-error state

---

## Trigger Reference

| Invocation | Trigger | Scope |
|---|---|---|
| Manual / feature-complete | Any AI-powered or agentic feature reaches code-complete | Files in the agent feature: prompts, tools, schemas, MCP config, memory, gates, orchestration, audit |
| Sprint-end | Alongside `review-code-security.md` Tier 3 | All AI-powered surfaces; spawn `security-verifier` on HIGH+ findings |

Reports go in `docs/security/` as `AISR-{###}-{YYYY-MM-DD}.md` (AI Surface Review). Update `docs/security/SECURITY_LOG.md` and the roadmap security-reviews table on completion, consistent with the SRR workflow.
