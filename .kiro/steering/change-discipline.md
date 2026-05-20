---
inclusion: always
---

# Change Discipline

Rules governing what you can change, how changes must be scoped, dependency management, and commit hygiene.

## Permission Boundaries - MANDATORY

**Explicit rules for what may be changed, what requires approval, and what must never be touched.**

### ✅ Always Allowed
- Read any file in the repository
- Run linting, type checking, and tests
- Edit source files within the scope of the current task
- Update documentation and changelog

### ⚠️ Ask First
- Adding or removing dependencies
- Database schema changes or new migrations
- Deleting files or directories
- Changing CI/CD configuration
- Modifying shared infrastructure code used by multiple services

### 🚫 Never
- Commit secrets, `.env` files, or credentials
- Force push to `main` or protected branches
- Modify generated files (`dist/`, `build/`, lock files unless updating deps)
- Modify already-applied database migrations
- Remove or weaken existing tests (unless explicitly asked)
- Change code outside the scope of the current task

## Consistency - Match Existing Patterns - MANDATORY

**When touching existing code, matching the existing style is more important than "ideal" style.**

### Rules

1. **New code must look like it was written by the same author** - match naming conventions, formatting, patterns, and idioms already present in the file/module.
2. **Follow existing patterns from similar components** - before creating a new service, route, or component, find an existing one that does something similar and follow its structure.
3. **Don't refactor while implementing** - if you notice code that could be improved but it's outside the current task, note it for later. Don't mix refactoring with feature work.
4. **When in doubt, be consistent** - if the codebase uses one pattern and the style guide says another, follow the codebase. Consistency within a project trumps external standards.

## Change Scope Discipline - MANDATORY

**Change only what was asked for. No drive-by refactors, no unsolicited improvements.**

### Rules

1. **Minimal changes** - modify as few lines as possible while correctly solving the problem. Every changed line must be justified by the task.
2. **No extra improvements** - do not refactor, optimize, or "clean up" code that is not part of the current task, even if it looks wrong.
3. **No unsolicited dependency updates** - don't upgrade packages, change configs, or modify tooling unless the task requires it.
4. **Scope creep is a bug** - if implementation reveals a needed change outside the current scope, document it as a separate task. Don't silently expand the change.
5. **Review your diff before committing** - every line in the diff should relate to the task. If something doesn't, revert it.

## Fix Depth Rule — MANDATORY

**If a fix introduces a new failure, STOP. Do not chain fixes blindly.**

### Rules

1. **Two-fix limit** — if your second fix attempt for the same issue introduces yet another failure, STOP immediately.
2. **Map all paths** — before attempting fix #3, read the FULL integration context: all related code paths, all consumers, all edge cases. Draw the complete picture.
3. **Root cause, not symptoms** — each failed fix is evidence you're treating a symptom. Step back and identify the actual root cause.
4. **Document what you tried** — before the third attempt, write down: what fix #1 did, why it failed, what fix #2 did, why it failed. The pattern reveals the real problem.
5. **Ask for help** — if you cannot identify the root cause after mapping all paths, say so. Don't keep guessing.

## Copy-Paste Verification — MANDATORY

**After copying code from another context, verify EVERY field makes sense in the new context.**

### Rules

1. **Review all values** — default values, field names, identifiers, paths, URLs, error messages. Each must be correct for the NEW context, not the source.
2. **Check return types** — if you copied a function that returns `isConnected: true`, ask: is that the correct default HERE?
3. **Check message objects** — if constructing a new object based on a similar one, verify ALL required fields are included. Don't drop fields.
4. **Check config references** — if the copied code references a config file, manifest, or package.json entry, verify that entry exists for the new context.

## Package Manifest Verification — MANDATORY

**After creating any file that should be published or deployed, verify it's included in the manifest.**

### Rules

1. **npm `files` array** — after creating new directories or entry points, verify they're listed in `package.json` `files`. Run `npm pack --dry-run` to confirm.
2. **pyproject.toml `include`** — after creating new Python modules, verify they're included in the package build.
3. **bin entries** — after creating CLI entry points, verify the `bin` field in package.json points to the correct file.
4. **After adding any import** — verify the dependency is declared in the manifest (package.json or pyproject.toml). Don't use undeclared packages.

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

## Commit Discipline

- Commit at meaningful milestones
- Descriptive commit messages stating what and why
- Update changelog for behavior/structure changes
- Verify tests pass before committing

## Changelog Rolling Policy

- `docs/changelogs/CHANGELOG.md` should stay under **500 lines**
- When it exceeds 500 lines, roll over: rename to `docs/changelogs/CHANGELOG.YYYY-MM-DD.md` and start fresh
- Do NOT copy, summarize, or selectively preserve entries - just roll it over clean
- Write **consolidated** changelog entries grouped by feature

## Repository Hygiene

- Do not clutter the repository root with ad hoc notes, temporary design files, scratchpads, or undocumented artifacts.
- All project documentation lives in `docs/` (except `README.md` at root).

## Security & Credentials

- No credentials in source control
- Use .env.example for configuration templates
- Run secret-exposure review before commits
- Credentials, API keys, and test accounts must be externalized into secure configuration - never inline
