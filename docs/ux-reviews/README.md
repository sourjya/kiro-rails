# UX Reviews

UX review reports produced by the `ux-reviewer` agent or the `review-ux-live.md` prompt.

## Placement Rules

- **Format:** `UXR-{###}-{YYYY-MM-DD}.md`
- **Numbering:** Sequential (UXR-001, UXR-002, ...)
- **Content:** Scored findings against `.kiro/steering/ux-console-idiom.md` rubric
- **Structure:** Summary → Systemic → Per-page → Plan → Corrections → Notes

## When UXR Reports Are Created

- Feature-complete on a `ui/` or `feat/` branch with frontend changes
- Pre-release (per `versioning.md` release checklist)
- Manual trigger when UX regression is suspected

## Gate

- **PASS:** Zero Sev-1 findings AND no page below 70/100
- **FAIL:** Any Sev-1 OR any page below 70/100

A FAIL blocks release (same weight as a Tier 2 security finding).

## Cross-references

- `.kiro/steering/review-policy.md` — trigger rules
- `.kiro/steering/ux-console-idiom.md` — the rubric
- `.kiro/prompts/review-ux-live.md` — the browser-walk protocol
- `.kiro/agents/ux-reviewer.json` — the restricted-tool agent
