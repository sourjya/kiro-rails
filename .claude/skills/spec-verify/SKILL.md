---
name: spec-verify
description: Verify a completed implementation against its spec. Checks all acceptance criteria, runs tests, validates coverage. Use after spec-implement is done.
---

# Spec Verify Workflow

Verify that a completed implementation satisfies its spec.

## Steps

1. **Read the spec** - load requirements.md and design.md
2. **Run verification checks** against each requirement
3. **Generate a verification report**
4. **Flag any gaps** for remediation

## Verification Checklist

For each requirement in `requirements.md`:

### Functional Verification
- [ ] Every acceptance criterion has a passing test
- [ ] Edge cases identified in design.md are handled
- [ ] Error paths are tested (not just happy path)

### Non-Functional Verification
- [ ] Performance requirements met (if specified)
- [ ] Security requirements met (no secrets, proper auth, input validation)
- [ ] Accessibility requirements met (if frontend)

### Code Quality
- [ ] Tests pass (`npm test` / `pytest` / equivalent)
- [ ] Type checking passes (if applicable)
- [ ] No lint errors
- [ ] No hardcoded values that should be configurable

### Documentation
- [ ] Code comments explain WHY, not WHAT
- [ ] API changes documented
- [ ] ADR written if architectural decisions were made
- [ ] Changelog entry added

## Verification Report

After checking, append a verification section to the spec folder:

```markdown
<!-- Append to tasks.md -->

## Verification Results

**Date:** YYYY-MM-DD
**Status:** ✅ PASSED | ⚠️ PARTIAL | ❌ FAILED

### Requirements Coverage
| Requirement | Status | Notes |
|-------------|--------|-------|
| REQ-1 | ✅ | All criteria met |
| REQ-2 | ⚠️ | Missing edge case test |

### Gaps Found
- Gap 1: ...
- Gap 2: ...

### Recommendation
Ready for archive / Needs remediation on: ...
```

## Rules

1. **Be strict** - a requirement is only "met" if ALL its acceptance criteria pass
2. **Check tests exist** - don't just trust that code works; verify tests cover it
3. **Flag scope creep** - if implementation added things not in the spec, note it
4. **Recommend next step** - either `spec-archive` (if passed) or remediation tasks
