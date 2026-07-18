# Kiro-Rails Improvement Recommendations

**Research date:** July 2026
**Target release window:** v0.21 - v0.23
**Baseline:** kiro-rails v0.20.0 (22 steering files, 30 hooks, 17 review prompts, 4 agents, 7 skills, 15 scripts, 5 export targets)
**Sources:** 2026 empirical literature on agent rule files and skill libraries, current OSS guardrail ecosystem, CVE record for agent configuration attacks, and a direct audit of the kiro-rails repo.

---

## Executive Summary

Kiro-rails' triangulation model (steering, hooks, prompts) is directionally validated by 2026 research: guardrails measurably help, deterministic enforcement beats reminders, and the zero-token primary path is the right economic bet. Three structural gaps remain, and each now has published evidence or live exploits behind it.

1. **The steering layer is unaudited prose.** Large-scale controlled experiments show that positive directives ("follow code style") can silently degrade agent performance while negative constraints ("do not refactor unrelated code") drive nearly all the benefit. Roughly half of kiro-rails' resident steering mass is positive-directive process narration.
2. **The feedback loop only adds; nothing retires.** The system converges toward the "library drift" failure mode documented in self-evolving skill libraries: unbounded accumulation without outcome-driven lifecycle management degrades retrieval and stalls performance.
3. **Kiro-rails guards the codebase but not itself.** Steering files, hooks, and agent config are now a documented exploit class (CVE-2025-59536, CVE-2026-21852, GitInject-style judgment manipulation). A template whose entire mechanism is "inject persistent instructions and auto-executing hooks" must treat that mechanism as an attack surface.

The recommended v0.21 theme: **the guardrail system that guards itself.** Self-integrity plus polarity-audited steering plus a pre-action intercept layer is a coherent, defensible release story backed by three months of CVEs and two peer-adjacent studies, not vibes.

---

## Priority Roadmap

| # | Recommendation | Release | Effort | Evidence strength |
|---|---|---|---|---|
| R1 | Guard the guardrails (steering-diff sentinel, signed install) | v0.21 | Medium | High (live CVEs) |
| R2 | Tamper resistance (hook checksums, protected paths) | v0.21 | Small | High (exploit class) |
| R3 | Polarity audit + steering rewrite | v0.21 | Small | Medium (single-model study, directional) |
| R4 | PreToolUse intercept layer (4th enforcement layer) | v0.21 | Medium | High (mature ecosystem pattern) |
| R5 | Rule ledger + lifecycle management | v0.21 (skeleton) | Medium | Medium-high |
| R6 | Steering diet + budget tooling | v0.21 | Small | Medium (two converging studies) |
| R7 | Frontmatter lint (hygiene) | v0.21 | Trivial | Direct repo finding |
| R8 | CI parity verifier | v0.22 | Small | Logical gap |
| R9 | rails-bench eval harness | v0.22 | Large | High value, real cost |
| R10 | MCP as export target #6 | v0.22 | Medium | Strategic |
| R11 | Semgrep second-stage detection | v0.23 | Medium | Optional upgrade |
| R12 | EARS notation in spec workflow | v0.23 | Small | Ecosystem convergence |
| R13 | Session-scoped (trajectory) detection | v0.23 | Medium | Emerging category |
| R14 | Dual bash/PowerShell script layer | Backlog | Medium | Funnel widening |

**Explicit non-goal:** runtime gateway-style guardrails (Bifrost / Agent Control category). Different product, different buyer. Kiro-rails stays local, deterministic, and template-shaped.

---

## R1. Guard the Guardrails

**Problem.** Kiro-rails is structurally a config-injection mechanism: it distributes persistent instructions and auto-executing hooks. That mechanism is the 2026 exploit class of record.

- CVE-2025-59536 (CVSS 8.7): a malicious repository injects hook configurations into `.claude/settings.json` that execute arbitrary shell commands at agent initialization, before any trust dialog.
- CVE-2026-21852: agent config poisoning that routes API traffic (including auth tokens) to an attacker, and npm postinstall poisoning of persistent memory files - backdoors that survive session boundaries, unlike ordinary prompt injection.
- GitInject (arXiv:2606.09935): judgment manipulation with no shell access. A PR adds a backdoored module plus a CLAUDE.md "Scope Restrictions" section instructing the reviewer not to flag the vulnerable pattern, claiming a separate security team reviews those modules. This weaponizes a steering file to suppress exactly the kind of review kiro-rails Tier 2 performs. The adversarial verifier agent, which actively hunts reasons to dismiss findings, is arguably extra susceptible.

**Recommendations.**

1. **`steering-diff-sentinel` hook.** Any commit or PR touching `.kiro/steering/`, `.kiro/hooks/`, `CLAUDE.md`, `AGENTS.md`, `.mcp.json`, or `.claude/settings.json` triggers a mandatory human-ack gate plus a deterministic injection-pattern scan: scope-suppression language ("do not flag", "reviewed elsewhere", "skip this check"), base64/encoded blocks, URL exfiltration patterns, and instructions addressed to the agent rather than to humans. Zero tokens; regex and grep, consistent with existing hook economics.
2. **Treat rule files as untrusted input in security reviews.** Extend the Tier 1 commit scan and the Tier 2/3 prompts with a "review the reviewers" section: diff-scan all steering and agent-config files as hostile content, not trusted configuration. No SDD competitor (Spec Kit, OpenSpec, BMAD) does this today; first mover on "the template that audits itself" is a real market position.
3. **Fix the install path.** `curl | bash` with no checksum, distributing a security template, is an irony the README cannot survive contact with a security-minded evaluator. Ship a signed manifest (minisign or cosign), pin the installer to a checksum, and have `install.sh` verify managed-file hashes on upgrade.

**Deliverables:** one hook, one prompt section, one manifest + installer change.

---

## R2. Tamper Resistance

**Problem.** Hooks live in-repo and are writable by the agent they constrain. An agent in a fix spiral can edit the fix-spiral detector. Current-generation governance tooling treats self-protection (the agent cannot disable its own governance) and append-only audit trails the agent cannot modify as baseline features.

**Recommendations.**

1. **Protected-path meta-hook.** Block agent writes to `.kiro/hooks/` and managed steering files unless an explicit human-set environment flag (e.g. `KIRO_RAILS_ADMIN=1`) is present in the session. Deterministic, one script.
2. **Managed-file checksums at session start.** The managed/unmanaged split already exists (`user-project-overrides.md` semantics). Extend it: a session-start hook verifies installed steering and hooks against the signed manifest from R1 and reports drift loudly. Reuses R1's manifest; the two recommendations ship together.
3. **Ledger placement.** The rule ledger (R5) lives outside the repo working tree (e.g. `~/.kiro-rails/ledger/` or a git-ignored append-only file with hash chaining) so it inherits tamper resistance for free.

---

## R3. Polarity Audit and Steering Rewrite

**Evidence.** "Guardrails Beat Guidance" (arXiv:2604.11088; 679 rule files, 25,532 rules, 5,000+ Claude Code runs on SWE-bench Verified):

- Every individually beneficial rule in per-rule ablation was a negative constraint; every individually harmful one was a positive directive (Fisher's exact p = 0.029 on the partition).
- Measured casualties that kiro-rails steering almost certainly contains in some form: "read existing test files" (-14.3pp), "follow existing code style" (-14.3pp), "handle edge cases" (-11.4pp), "preserve backward compatibility" (-8.6pp).
- Rule gains are largely content-independent (random rules matched curated rules), pointing to a context-priming mechanism; ensembles are resilient up to 50 rules, so aggressive pruning is not urgent - rewriting polarity is the lever, not deleting rules.
- Long-term asymmetry: rules teaching *how* to code get absorbed into improving base models; rules encoding *what must not happen* cannot be, because they express organizational priorities the model has no way to know. Negative constraints are the durable asset.

**Caveats to publish honestly:** single agent (Claude Code), single model, single benchmark, n = 35-58 tasks; the authors frame polarity as a directional pattern motivating replication, not a law.

**Recommendations.**

1. **`polarity-audit` review prompt.** Classifies every steering rule as negative constraint / positive directive / state-dependent conditional, reports the ratio per file, and proposes rewrites for the highest-risk directives ("do X" becomes "do not ship without X" where the semantics survive inversion).
2. **Steering rewrite pass.** Prioritize the four heaviest resident files (see R6 audit data). Keep positive directives only where a hook enforces the behavior anyway (in which case compress the steering copy to one line, since the reflex, not the prose, is doing the work).
3. **Novelty claim.** No project in the SDD ecosystem audits rule polarity. This is a cheap, citable, differentiating artifact.

---

## R4. PreToolUse Intercept Layer

**Problem.** All three current layers fire after the agent acts: save, commit, checkpoint. The 2026 hook ecosystem moved to pre-action gating. Claude Code and the Agent SDK expose ~30 lifecycle hook events; a PreToolUse hook receives the pending tool call as JSON and can block it (exit code 2) with the stderr message fed back to the agent before anything executes.

**Reference design to adapt:** `Dicklesworthstone/destructive_command_guard` (dcg). Four-stage pipeline: JSON parse and payload validation, path normalization (`/usr/bin/git` becomes `git`), an O(n) substring quick-reject so 99%+ of benign commands skip regex entirely, then safe-patterns-first matching. Denials return structured JSON: ruleId, packId, severity, an allow-once code, and a remediation block with the safe alternative. Rule packs are keyword-gated (the Kubernetes pack only activates when `kubectl` appears in the command), which is a cleaner architecture than a flat hook list and scales to community contribution.

**Recommendations.**

1. Add an **intercept layer** between steering and detection: prevent, **intercept**, detect, audit. This reframing is also the cleanest headline for the release.
2. Implement keyword-gated packs for the obvious catastrophes first: `git reset --hard`, force-push to protected branches, `rm -rf` outside sanctioned paths, writes to `.env` and secret files, and (per R2) writes to protected kiro-rails paths.
3. Keep the zero-token guarantee: pure shell, structured deny JSON, allow-once escape hatch for legitimate exceptions.
4. Ship per-tool adapters through the existing export mechanism - the same pattern works across Claude Code, Codex CLI, Gemini CLI, Copilot, and Cursor hook systems.

---

## R5. Rule Ledger and Lifecycle Management

**Evidence.** Library Drift / Ratchet (arXiv:2605.19576, extended in 2605.22148): self-evolving skill libraries fail silently through unbounded accumulation without outcome-driven lifecycle management, causing retrieval degradation, false-positive injections, and performance stagnation. SkillsBench measured LLM-authored skills at +0.0pp versus +16.2pp for human-curated ones - the bottleneck is lifecycle, not authoring. The verified fix is minimal: outcome-driven retirement with a conservative evidence floor, a bounded active cap, and a meta-level authoring prior. Critically, harsh retirement was actively harmful (below the no-skill floor), so the evidence floor must be conservative.

**Problem in kiro-rails terms.** The closed loop runs prompts -> hooks -> more hooks. There is no retirement path. At 30 hooks and 17 prompts this is cheap to add; at 60 it will be a migration.

**Recommendations.**

1. **`docs/engineering/rule-ledger.json`** (physically located per R2.3): an append-only evidence log. Every hook fire, suppression, override, and false-positive dismissal writes a capsule: {rule, trigger context, outcome, timestamp}.
2. **Quarterly `curate-rails` prompt** reads the ledger and proposes retirement for hooks that never fired, or fired and were overridden more than N times, with a conservative evidence floor (do not retire on thin data).
3. **Bounded active cap per layer** (steering, hooks, prompts) so growth forces a trade rather than accumulating silently.
4. **Authoring prior:** new hooks promoted from prompt findings must state polarity (R3) and the ledger evidence that motivated them.

---

## R6. Steering Diet and Budget Tooling

**Measured baseline (repo audit, July 2026).** The feature sheet's claim of "22 always-on context documents" is wrong; the actual inclusion-mode distribution:

| Inclusion mode | Files | Words |
|---|---|---|
| `always` (explicit) | 15 | 11,614 |
| no frontmatter (defaults to always) | 1 (review-policy.md) | 1,400 |
| `auto` (undocumented value; behavior unverified) | 2 (naming-conventions, versioning) | 695 |
| `fileMatch` | 2 (frontend-patterns, api-contract-discipline) | 1,673 |
| `manual` | 2 (ux-console-idiom, ux-pattern-registry) | 2,268 |

Resident load: **13,014 words always-on** (roughly 17-18k tokens per interaction), which is 74% of total steering mass. Top-heavy: git-and-focus-discipline (2,404), review-policy (1,400), reusable-architecture (1,258), change-discipline (1,225) - four files carry 48% of the resident weight.

**Converging evidence.** The ETH context-file study (context files add 20%+ cost without reliably improving task success) plus the priming finding (presence beats phrasing; content matters less than the existence of structured on-topic instruction) jointly imply the resident layer can shrink substantially without losing effect. Additionally, post-v0.20, steering prose that narrates behavior a hook already enforces deterministically (branch auto-delete, checkpoint commits, fix-spiral logging) is paying rent twice.

**Recommendations.**

1. **Tier the resident layer.** Always-on keeps only the compressed negative constraints and identity-critical conventions. Process walkthroughs move to `manual` or skill-style on-demand loading; domain conventions move to `fileMatch`. Realistic target: 40-50% reduction of resident tokens (revised down from an earlier 60%+ estimate that wrongly assumed all 22 files were resident).
2. **`steering-budget` script.** Reports per-file word/token weight and inclusion mode; flags any file that is `always` AND over ~800 words AND majority positive-directive (merging this tool with R3's polarity audit). The v0.1 is a 10-line awk script already prototyped during this research.
3. **Fix the feature sheet.** "22 steering files, tiered by inclusion mode" is both accurate and a stronger pitch, since tiered inclusion is the sophisticated position post-ETH.

---

## R7. Frontmatter Lint (Hygiene)

Two defects found in the repo audit, both silent by nature:

1. `review-policy.md` has no frontmatter at all and silently inherits default inclusion - inconsistent with the other 21 files.
2. `inclusion: auto` (naming-conventions.md, versioning.md) is not a documented Kiro inclusion mode (documented: `always`, `fileMatch`, `manual`). Verify actual behavior; the likely outcomes are silent default-to-always or silent drop, and both are unacceptable in a project whose pitch is "rules the agent cannot ignore."

**Recommendation.** A `steering-frontmatter-lint` hook: every steering file must carry explicit, valid frontmatter with a recognized inclusion value; `fileMatch` entries must carry a pattern. Trivial to build, prevents the whole defect class permanently.

---

## R8. CI Parity Verifier

**Problem.** "No CI pipeline by design" leaves a bypass hole: `git commit --no-verify`, teammates who never ran the installer, or an agent that edited a hook (mitigated but not eliminated by R2). Local-only enforcement drifts.

**Recommendation.** The detection hooks are deterministic shell scripts, so they run identically anywhere. Ship a thin reusable GitHub Actions workflow (and a composite action) that re-executes `scripts/` detection on PRs. This is not a CI pipeline - it is a verifier - so it does not violate the bring-your-own-CI stance. It also dovetails with the existing LocalStack + act dual-mode local CI work, so the template pattern already exists in-house.

---

## R9. rails-bench Eval Harness

**Problem.** Kiro-rails has no evidence it works. Neither does any competitor - Spec Kit, OpenSpec, BMAD, or the plugin ecosystem. The first template that can prove its own value owns the credibility high ground, and the methodology is now public and affordable.

**Method (adapted from arXiv:2604.11088).**

1. Screen candidate tasks with three baseline repetitions each; discard always-pass and never-pass tasks (in their data, 47% and 27% respectively contributed no signal). Keep the discriminative middle (30-70% baseline pass rate).
2. Run paired within-subject comparisons: full steering set vs. no steering vs. per-file ablations, same tasks, McNemar's exact test.
3. Emit per-rule verdicts: shaping (removal hurts), distorting (removal helps), inert.

**Cost anchor:** the full 5,000-run academic study cost ~$2,000; a 40-task, 20-condition slice is hobby-budget territory. Output feeds R3 and R5 with data instead of intuition. Sequence after the ledger exists so verdicts persist.

---

## R10 - R14. Smaller Items

**R10. MCP as export target #6.** Five export scripts each chase a moving per-tool format. An MCP server exposing steering, review prompts, and the bug ledger as resources/tools serves any MCP client without translation - a more durable answer to the anti-fragmentation thesis than N adapters, and convergent with existing in-house MCP work. Add alongside the export scripts; retire nothing until usage data says so.

**R11. Semgrep second-stage detection.** Regex hooks have a false-positive ceiling (the hardcoded-value scanner's "skips tests/config" caveat). LlamaFirewall's CodeShield demonstrates Semgrep + regex detection across eight languages with community-authored rules. Keep the zero-token regex quick-reject as stage one; make Semgrep an optional, independently disablable stage two.

**R12. EARS notation in specs.** Each EARS pattern collapses to a single testable claim with unambiguous scope, trigger, and response - an agent can generate code and the verifying test without guessing. Constrain the requirements section produced by `spec-propose` to EARS patterns, making `spec-verify` mechanically checkable. Also adopt the ecosystem's `constitution` naming for the steering layer (the feature sheet already uses the word informally); free discoverability.

**R13. Session-scoped detection.** Current coverage is file-scoped and commit-scoped. The emerging category (agenttrace, AgentDoG) is trajectory-level: loop detection, tool-misuse patterns, instruction hijacking across turns. The fix-spiral detector is the in-house seed; generalize it into a SessionEnd postmortem hook that scans the session for spiral, thrash, and scope-creep signatures and writes ledger capsules.

**R14. Dual bash/PowerShell script layer.** Spec Kit ships one; kiro-rails is bash-only. Widens the funnel for Windows-native users; the maintainer's own WSL environment is one antivirus quirk away from motivating this personally. Backlog until demand appears.

---

## Release Narrative

- **v0.21 - "The guardrail system that guards itself."** R1 + R2 + R3 + R4 + R5 skeleton + R6 + R7. Small individually, coherent collectively, and backed by CVEs and studies rather than intuition. Pairs naturally with the planned Kiro-birthday timing.
- **v0.22 - "Prove it."** R8 + R9 + R10. The verifier closes the bypass hole; rails-bench makes kiro-rails the first template in its category with published effectiveness data; MCP begins the post-export-script era.
- **v0.23 - "Deepen the detection."** R11 + R12 + R13.

**Anti-recommendation, restated:** do not add more steering files before measuring the existing ones, and do not chase the runtime-gateway category. The moat is local, deterministic, self-auditing enforcement - dig it deeper, not wider.

---

## References

1. Zhang et al., "Guardrails Beat Guidance: A Large-Scale Study of Rules, Skills, and Persistent Configuration for Coding Agents," arXiv:2604.11088 (May 2026).
2. Zhang et al., "Library Drift: Diagnosing and Fixing a Silent Failure Mode in Self-Evolving LLM Skill Libraries," arXiv:2605.19576; extended as "Ratchet," arXiv:2605.22148 (May 2026).
3. "GitInject: Real-World Prompt Injection Attacks in AI-Powered CI/CD Pipelines," arXiv:2606.09935 (2026).
4. "Towards Secure Agent Skills: Architecture, Threat Taxonomy, and Security Analysis," arXiv:2604.02837 (2026) - CVE-2025-59536, CVE-2026-21852 analysis.
5. Dicklesworthstone, destructive_command_guard - PreToolUse pack architecture reference.
6. LlamaFirewall (arXiv:2505.03574) - CodeShield Semgrep/regex detection design.
7. GitHub Spec-Kit; OpenSpec; BMAD - SDD ecosystem baselines, constitution.md convention, EARS notation guidance.
8. Jiang & Nam, "Beyond the Prompt: An Empirical Study of Cursor Rules," arXiv:2512.18925 (already cited in kiro-rails).
9. ETH Zurich context-file effectiveness study, arXiv:2602.11988 (already cited in kiro-rails).
10. Kiro-rails v0.20.0 repo audit (steering frontmatter and word counts), performed July 18, 2026.
