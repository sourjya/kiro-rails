---
name: spec-archive
description: Archive a completed and verified spec. Moves it from active specs to the docs archive, updates the spec registry. Use after spec-verify passes.
---

# Spec Archive Workflow

Archive a completed spec after it passes verification.

## Steps

1. **Verify completion** - all tasks checked, verification passed
2. **Move to archive** - relocate from `.kiro/specs/<name>/` to `docs/architecture/specs/<name>/`
3. **Update registry** - add entry to the spec index
4. **Clean up** - remove the active spec folder

## Process

### 1. Pre-Archive Check

Confirm in `tasks.md`:
- All `- [ ]` are now `- [x]`
- Verification Results section exists with status ✅ PASSED

If not, inform the user and suggest running `spec-verify` first.

### 2. Archive Location

Move the entire spec folder:
```
.kiro/specs/<feature-name>/  →  docs/architecture/specs/<feature-name>/
```

Create `docs/architecture/specs/` if it doesn't exist.

### 3. Add Archive Metadata

Prepend to the archived `proposal.md`:

```markdown
---
archived: YYYY-MM-DD
status: completed
implemented-in: <branch or commit reference>
---
```

### 4. Update Spec Index

Append to `docs/architecture/specs/INDEX.md` (create if missing):

```markdown
| <Feature Name> | YYYY-MM-DD | Completed | Brief description |
```

### 5. Clean Up

- Remove `.kiro/specs/<feature-name>/` (it now lives in docs)
- Inform the user the spec is archived

## Rules

1. **Never archive a failing spec** - verification must pass first
2. **Preserve history** - the archive is the source of truth for "what was built and why"
3. **Link to implementation** - include branch/commit/PR reference in metadata
4. **Keep the index current** - every archived spec must appear in INDEX.md
