---
inclusion: always
---

# Execution Discipline Standards

Supplementary engineering rules derived from cross-project execution standards.
These rules fill gaps not already covered by `engineering-standards.md` or `code-commenting-standards.md`.

## Dependency Minimalism

- Every new dependency must have a functional justification tied to a concrete requirement, test need, or architectural concern.
- Do not add libraries speculatively. If the standard library or an existing dependency can do the job, use it.
- Keep dependency manifests (`pyproject.toml`, `package.json`) lean and auditable.
- **Python dependencies are managed exclusively via uv and pyproject.toml.** Never use `requirements.txt`, `pip install`, `pip freeze`, or `poetry`. Add deps with `uv add <package>`. The lockfile is `uv.lock`.
- **Justify every new dependency** - the commit message or task notes must explain why this dependency is needed and why existing deps or stdlib can't do the job.
- **Check for overlap** - before adding a new package, verify no existing dependency already provides the same functionality.
- **Prefer small, focused packages** over large frameworks when only one feature is needed.
- **Pin versions explicitly** - never use floating version ranges in production dependencies. Lock files must be committed.
- **Audit before adding** - check the package's maintenance status, download count, last update date, and known vulnerabilities before adding it to the project.

## Design Principles

- Favor composition over inheritance. Use inheritance only when it is semantically justified and materially improves the design.
- Public interfaces, domain models, service boundaries, and infrastructure adapters must be explicit and easy to reason about.
- No god classes, hidden coupling, or ambiguous ownership boundaries.
- Write code as if a different engineer will inherit the project under delivery pressure.

## Repository Hygiene

- Do not clutter the repository root with ad hoc notes, temporary design files, scratchpads, or undocumented artifacts.
- All project documentation lives in `docs/` (except `README.md` at root).

## Documentation Organization

All documentation must be placed in the appropriate `docs/` subdirectory based on its purpose:

### docs/decisions/ (Architecture Decision Records)
- **Format**: `ADR-###-descriptive-name.md` (e.g., `ADR-001-tech-stack.md`)
- **Content**: Context, decision, alternatives considered, consequences
- **Immutability**: ADRs are historical artifacts; status can change to "superseded" but content stays

### docs/architecture/
- **Purpose**: Technical documentation of HOW the system works today
- **Content**: System structure, data flows, component interactions, implementation patterns

### docs/roadmap/
- **Purpose**: Project planning and milestone tracking
- **Content**: Roadmaps, milestone plans, implementation schedules

### docs/changelogs/
- **Purpose**: Historical record of changes to the system
- **Content**: `CHANGELOG.md` (current), archived changelogs (`CHANGELOG.YYYY-MM-DD.md`)

### docs/bugs/
- **Purpose**: Bug investigation and resolution documentation
- **Format**: `BUG-###-short-description.md`

### docs/ideas/
- **Purpose**: Feature exploration and research before promotion to specs
- **Content**: Freeform markdown exploring a feature concept
- **Archive**: Promoted ideas move to `docs/ideas/_archive/`

### docs/technical-debt/
- **Purpose**: Known technical debt items and remediation plans

### docs/testing/
- **Purpose**: Testing strategy, test plans, coverage reports

### docs/runbooks/
- **Purpose**: Operational guides and setup instructions

### docs/references/
- **Purpose**: External documentation, research materials, API guides

### docs/engineering/
- **Purpose**: Engineering process documentation, execution standards

### Placement Rules

**DO NOT**: Create documentation files in `docs/` root, mix document types, or create new subdirectories without documenting their purpose.

**DO**: Place ADRs in `docs/decisions/` with proper numbering, update this list if adding a new documentation category.

## API Versioning

- APIs must be versioned from the start of the project.
- Versioning strategy must be explicit, documented, and applied consistently.

## Development Roadmap and Planning

- Before substantive implementation begins, establish a structured plan:
  - **Kiro Specs** (preferred): `requirements.md`, `design.md`, and `tasks.md` under `.kiro/specs/{feature-name}/`
  - **Manual Roadmap** (for broader planning): `docs/roadmap/roadmap.md` with milestones and TODO items
- Link specs to the roadmap at the appropriate timeline point.
- Execute work incrementally, one task at a time.
- If implementation realities require a plan change: update the spec/roadmap, document the reason, record in changelog.

### Spec Quality Standards - NON-NEGOTIABLE

**Requirements.md** must include:
- Numbered user stories with acceptance criteria (testable, not vague)
- Non-functional requirements (performance, cost, reliability, accessibility)
- Explicit "out of scope" section to prevent scope creep

**Design.md** must include:
- Architecture diagram showing service interactions
- Data model with actual SQL or Pydantic schemas (not hand-wavy descriptions)
- API contracts with request/response examples
- Frontend component tree with data flow
- For pipelines/background processes: observability design (what gets logged, what metrics are emitted, how to trace a request end-to-end)

**Tasks.md** must include:
- Phases with clear boundaries and checkpoint gates
- Every task has a concrete deliverable (file path, test name, endpoint)
- TDD structure: RED → GREEN → REFACTOR per step
- Security checkpoint at final phase
- No vague tasks like "implement the feature" - break down to individual functions/components

**If a spec feels thin, it IS thin. Expand it before writing code.**

## Observability-First Design - MANDATORY

**ZERO BLACKBOXES.** Every pipeline, background process, and async workflow must be observable from day one.

### Rules for all background/async/pipeline code:

1. **Structured logging** - every operation logs: what started, what inputs it received, what it produced, how long it took, whether it succeeded or failed. JSON structured logging, not print statements.
2. **Correlation IDs** - every pipeline run or background task gets a unique ID that flows through all log entries and database records.
3. **State transitions** - every job/task has explicit states (PENDING → RUNNING → SUCCESS/FAILED/RETRYING) stored in the database.
4. **Metrics** - track: items processed, items failed, processing time, queue depth, retry count.
5. **Error context** - when something fails, log the full context: what was being processed, what step failed, what the input was.
6. **Resumability** - if a pipeline crashes mid-run, it must be resumable from where it stopped via database checkpointing.
7. **Discuss architecture first** - before implementing any pipeline or background process, discuss the architecture: data flow, failure modes, retry strategy, observability hooks.

### ADR Roadmap Linking - MANDATORY

Every ADR must be linked in `docs/roadmap/roadmap.md` at the sprint/milestone row where the decision was made.

## Pre-Commit Enforcement

- No secrets in committed files
- Formatting and lint checks pass
- Changelog has been updated when source changes warrant it
- Use Kiro hooks or git hooks to automate these checks

## Git Branching - MANDATORY

**All work must happen on a feature branch, never directly on `main`.**
**One branch per spec/feature. Merge to main before starting the next one. No exceptions.**

See `.kiro/steering/git-workflow.md` for complete branching rules.

### ADR Roadmap Linking - MANDATORY

Every ADR must be linked in `docs/roadmap/roadmap.md` at the sprint/milestone row where the decision was made.

**Rules:**
- Link ADRs in chronological order within each row
- Only link ADRs that actually exist on disk
- Format: `[ADR-###](../decisions/ADR-###-descriptive-name.md)` (relative path from `docs/roadmap/`)

## Bug Reporting and Resolution Workflow - MANDATORY

When a bug is identified, follow this workflow in full:

### Step 1: Assign a bug number
Check `docs/bugs/` for the highest existing `BUG-###` number and increment by 1.

### Step 2: Create the bug document
Create `docs/bugs/BUG-###-short-description.md` with: ID, Severity, Status, Description, Reproduction steps, Root cause, Fix description, Files changed, Regression tests added.

### Step 3: Fix the bug
Minimal and targeted fix - do not refactor unrelated code.

### Step 4: Add regression tests - NON-NEGOTIABLE
Every bug fix requires both negative AND positive regression tests:
- **Negative test**: reproduces the bug, must FAIL on unfixed code (RED phase)
- **Positive test**: confirms the fix, passes after fix (GREEN phase)
- Named after the bug: `test_bug###_<description>` (Python) or `it('BUG-###: <description>')` (TypeScript)
- Never mark a bug `FIXED` without regression tests committed in the same change

### Step 5: Link to the roadmap
Add a reference in the roadmap or spec tasks for traceability.

### Step 6: Update the changelog
Add entry to `docs/changelogs/CHANGELOG.md` under today's date.

### Step 7: Update the bug document status
Set `Status` to `FIXED`, fill in `Fixed` date and remaining fields.

## Credential Handling

- Credentials, API keys, and test accounts must be externalized into secure configuration - never inline.
- Prior to every commit, perform an explicit secret-exposure review.
