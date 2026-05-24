# Implementation Plan: [Feature Name]

## Overview

[Brief description of the feature and its purpose]

**Architecture References:**
- [List relevant ADRs]

**Key Principles:**
- [List key architectural principles for this feature]

**Development Approach - TDD MANDATORY:**
- **RED -> GREEN -> REFACTOR**: Write failing tests FIRST, then minimal implementation, then refactor
- NEVER write implementation code before its test
- Each phase below follows strict TDD ordering: tests before implementation
- See testing-standards.md for complete TDD guidelines

**Testing Strategy:**
- Unit tests for specific examples and edge cases (write FIRST)
- Integration tests for cross-module interactions
- E2E tests for critical user workflows
- All tests use stable selectors/identifiers exclusively

## Tasks

### Phase 1: [Phase Name]

#### Step 1: [Component Name] - TDD Cycle

**RED Phase: Write Tests First**
- [ ] 1.1 Write unit tests for [component/utility]
  - Test [specific behavior 1]
  - Test [specific behavior 2]
  - Test [edge case 1]
  - Test [error handling]
  - File: `tests/unit/test_[component].py`
  - _Requirements: [requirement IDs]_

**GREEN Phase: Implement to Pass Tests**
- [ ] 1.2 Implement [component/utility]
  - Create [file path]
  - Implement [method 1] to satisfy tests
  - Implement [method 2] to satisfy tests
  - Add comprehensive documentation (module, class, function level)
  - Add inline comments for non-obvious decisions
  - _Requirements: [requirement IDs]_

**REFACTOR Phase: Clean Up**
- [ ] 1.3 Refactor [component] (if needed)
  - Extract common patterns
  - Improve naming
  - Optimize performance
  - Ensure all tests still pass

#### Checkpoint: Phase 1 Complete

- [ ] All tests passing
- [ ] No linting errors
- [ ] Security checkpoint passed (no hardcoded secrets, auth intact, inputs validated)
- [ ] Changelog updated
- [ ] Changes committed

---

### Phase 2: [Next Phase Name]

[Repeat TDD cycle structure for next phase]

---

### [UI Phase Template — use for any phase that modifies frontend]

#### UX Intent (required before coding any UI)

```
Screen:
Primary user:
Primary task:
Most frequent action:
Least acceptable friction:
Reference pattern (product + screen):
Interaction placement rule:
Density rule:
Visual hierarchy (rank top 3 elements):
Do not change:
```

#### Step N: [Component Name] - TDD Cycle

[Follow standard RED/GREEN/REFACTOR structure above]

---

## TDD Reminders

**Before writing ANY implementation code, ask yourself:**
1. Have I written a test for this functionality?
2. Have I seen that test FAIL for the right reason?
3. Am I writing the MINIMAL code to make the test pass?

**If the answer to any of these is NO, STOP and write the test first.**

---

### Final Phase: Completeness Verification

**This phase is NON-NEGOTIABLE. Do not skip it.**

- [ ] **Error states** — every API call has a visible error state (not just console.log)
- [ ] **Loading states** — every async operation shows a loading indicator
- [ ] **Empty states** — every list/collection has an empty state message
- [ ] **Persistence** — any state that should survive page reload is persisted (localStorage, database, URL params). Intentionally ephemeral state is documented.
- [ ] **Destructive actions** — delete/remove operations have confirmation dialogs with clear action labels
- [ ] **Themed components** — no native `<select>`, `window.alert()`, `window.confirm()`, or `title` attributes
- [ ] **API contract verified** — frontend types match actual backend response shape (log and verify)
- [ ] **Cache invalidation** — after mutations, affected queries are invalidated or refetched
- [ ] **Prop parity** — if reusing/extracting a shared component, every prop the original passes is matched (no empty defaults)
- [ ] **Visual verification** — rendered output verified (or explicitly listed what user must check if verification unavailable)
- [ ] **All tests passing** — `npm test` / `pytest` green
- [ ] **No type errors** — `tsc --noEmit` / `ruff check` clean
- [ ] **Changelog updated** — entry added for user-visible changes

---

## Task Status Legend

- `[ ]` = Not started
- `[-]` = In progress
- `[x]` = Completed
