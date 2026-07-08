---
description: "Scan for embedded literals that belong in config or a constants module: URLs, magic numbers, thresholds, error message strings, and environment-dependent values."
---


# Hardcoded Value Scan

Run this prompt to detect embedded literals, magic values, and environment assumptions
in a codebase. Produces a structured findings report with severity, verdict, and
remediation - plus a scan manifest proving the scan actually ran.

> **Part of kiro-rails.** This is a manual review prompt. For automated coverage,
> pair it with the `pre-release-hardcode-check` hook (see "Hook Pairing" below),
> which runs C1 + C5 on changed files without being asked.

## When to Run

- Before any release or version tag
- After a feature branch lands that touches 10+ files
- When onboarding a new or inherited project
- Quarterly as a hygiene check
- Reactively, after a bug is traced to a hardcoded value that should have been config

## Scan Categories

### C1 - Hardcoded Identifiers (CRITICAL if in prod code)

UUIDs, database IDs, org/tenant/profile identifiers that should be derived at runtime.

**Pattern:** `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`

**Exclude (acceptable):**
- ID generation calls (not hardcoding) - see language appendix
- Type declarations for ID columns - see language appendix
- Dev fixtures and test factories
- Migration revision IDs

**Finding = violation if:** An ID literal appears in business logic, service code, or
endpoint code where it should be looked up from config or the database.

---

### C2 - Hardcoded URLs and Domains (HIGH)

Localhost URLs, specific domains, and port numbers embedded where they should be
config-driven.

**Patterns:**
- `localhost:\d+` or `127.0.0.1:\d+`
- Environment-specific domain patterns - **adapt to your naming scheme**, e.g.
  `https?://[a-z-]+\.(dev|staging|prod)\.example\.(com|io)`
- Specific port numbers in logic (not config defaults)

**Exclude (acceptable):**
- Settings/config files declaring **defaults** (e.g., `database_url: str = "postgresql://..."`)
- CLI tool defaults with an override path (env var or flag)
- Test fixtures and assertions
- Documentation and comments

**Finding = violation if:** A URL or port is used directly in service/route code
instead of reading from config. Or: a test assumes a specific URL that should be
derived from the test environment.

---

### C3 - Magic Numbers (MEDIUM)

Numeric values with business meaning that lack a named constant.

**Patterns:**
- Timeout values: `timeout=30`, `max_age=600`
- Limits: `[:100]`, `limit=50`, `page_size=20`
- Retry counts: `range(3)`, `max_retries=5`
- Thresholds: `if count > 10`, `rate_limit_per_min=60`

**Exclude (acceptable):**
- Named constant definitions: `MAX_RETRIES = 3` (the definition is the fix)
- Standard protocol values: HTTP status codes (`404`, `200`)
- Array indices and loop ranges for iteration
- Mathematical constants, bit operations

**Finding = violation if:** A number appears in business logic without a named
constant, and changing it would require searching for the raw number across the
codebase.

---

### C4 - String Literals as Enum Values (MEDIUM)

Status values, role names, and type discriminators used as raw strings instead of
enums or constants.

**Patterns:**
- `== "active"`, `== "pending"`, `== "admin"`
- `status = "open"`, `role = "member"`
- Provenance/discriminator assignments: `source = "self_signup"`

**Exclude (acceptable):**
- Constant definitions: `STATUS_ACTIVE = "active"`
- ORM column defaults: `server_default="active"`
- Test assertions (comparing against known values)
- Seed data and migration data

**Finding = violation if:** The same string literal appears in 3+ places, or a typo
in the string would cause a silent bug that no type checker catches.

---

### C5 - Hardcoded Credentials / Secrets (CRITICAL)

API keys, passwords, tokens, connection strings with real credentials.

**Patterns:**
- `password = "..."`, `secret = "..."`, `token = "..."`
- `api_key`, `client_secret` with inline values
- Base64-encoded strings that look like keys
- High-entropy string literals over 20 characters assigned to auth-adjacent names

**Exclude (acceptable):**
- Placeholder/example values: `"changeme"`, `"your-api-key-here"`
- Dev-mode test secrets that are self-describing (e.g., contain `dev`, `test`,
  `not-for-production` in the value itself)
- `.env.example` files

**Finding = violation if:** A real credential is in source code. This is always
CRITICAL regardless of context. If in doubt about whether a value is real,
report it as CRITICAL and let a human downgrade it.

---

### C6 - Environment Assumptions (LOW-MEDIUM)

Code that assumes a specific environment (dev/staging/prod) without reading config.

**Patterns:**
- `if hostname == "localhost"`, `IS_LOCALHOST`, `IS_LOCAL_DEV`
- `if env == "production"` hardcoded in business logic (vs. reading from settings)
- Feature flags checked by string comparison instead of the flag service

**Exclude (acceptable):**
- The config layer itself reading `APP_ENV` (or equivalent) to set defaults
- Dev-mode guards that are explicitly documented

**Finding = violation if:** Business logic changes behavior based on a hardcoded
environment check instead of a feature flag or config value.

---

## Suppression Convention

Teams should not re-litigate the same ACCEPTABLE findings every quarter. Two
mechanisms are honored by this scan:

**1. Inline suppression comment** (preferred for one-off cases):

```
# scan:allow C3 - protocol-mandated 30s timeout per RFC 6455
// scan:allow C2 - loopback address required by local discovery protocol
```

Format: `scan:allow <category> - <reason>`. A suppression without a reason is
itself a MEDIUM finding.

**2. Allowlist file** (preferred for whole-file or pattern-level exclusions):

A `.scan-allowlist.md` (or `.toml`/`.yaml`) at repo root listing file paths or
globs per category, each with a justification and an owner.

**Scan behavior:** Suppressed findings are NOT silently dropped. They are listed
in a dedicated "Suppressed" table in the output so reviewers can audit whether
old suppressions still hold.

---

## Execution Instructions

For each category, run the grep patterns against the source directory (`src/` or
equivalent). Exclude `__pycache__`, `node_modules`, `dist/`, `build/`, `.git/`,
`vendor/`, and lock files.

For each finding, record:
1. **File + line** - where the violation is
2. **Category** - C1-C6
3. **Severity** - CRITICAL / HIGH / MEDIUM / LOW
4. **Context** - what the value is and why it appears hardcoded
5. **Verdict** - VIOLATION (needs fix), ACCEPTABLE (with justification), or SUPPRESSED (with suppression reference)
6. **Remediation** - where the value should live instead

**Do not skip categories.** If a category yields zero findings, its table is still
printed, empty. "Looks clean" without the manifest below is not a completed scan.

---

## Output Format

```markdown
## Findings: <project name>

### Scan Manifest
- Date: <ISO date>
- Directories scanned: <list>
- Directories excluded: <list>
- Files scanned: <count>
- Patterns executed: <count per category, C1-C6>
- Suppressions honored: <count>

### CRITICAL (must fix before release)
| # | File:Line | Category | Value | Remediation |
|---|-----------|----------|-------|-------------|
| 1 | ... | C5 | API key inline | Move to .env / secrets manager |

### HIGH (fix in current sprint)
| # | File:Line | Category | Value | Remediation |
|---|-----------|----------|-------|-------------|

### MEDIUM (backlog)
| # | File:Line | Category | Value | Remediation |
|---|-----------|----------|-------|-------------|

### LOW (note and move on)
| # | File:Line | Category | Value | Remediation |
|---|-----------|----------|-------|-------------|

### ACCEPTABLE (documented, no action)
| # | File:Line | Category | Value | Justification |
|---|-----------|----------|-------|---------------|

### SUPPRESSED (audit these periodically)
| # | File:Line | Category | Suppression Reason | Still Valid? |
|---|-----------|----------|--------------------|--------------|
```

Empty tables MUST be printed. An absent table means the category was not scanned.

---

## Review Cadence Integration

This scan slots into a tiered review workflow:

- **Feature-complete review:** Run C1 + C5 on changed files only
- **Sprint-end review:** Full scan, all categories
- **Pre-release:** Full scan; CRITICAL findings block the release

If your project uses the kiro-rails review prompt set, reference this scan from
your review policy steering file at the tiers above.

## Hook Pairing

The manual scan catches everything; the hook catches the worst things
automatically. Recommended hook configuration:

- **Trigger:** pre-commit or pre-release
- **Scope:** changed files only
- **Categories:** C1 + C5 (identifiers and secrets)
- **Behavior:** CRITICAL finding blocks the commit/release; everything else warns

This keeps the fast path fast while guaranteeing the two categories that cause
incidents never ship unreviewed.

---

## Language Adaptation Appendix

The six categories are language-agnostic. Exclusion patterns are not. Apply the
relevant block for your stack; contribute blocks for missing languages.

### Python
- C1 exclusions: `uuid4()` / `uuid.uuid4` calls (generation), SQLAlchemy
  `UUID(as_uuid=True)` (type declaration), Alembic migration revision IDs
- C4 exclusions: `Enum` class member definitions, `Literal[...]` type annotations
- Common fixture locations: `conftest.py`, `factories.py`, dev-only modules

### TypeScript / JavaScript
- C1 exclusions: `crypto.randomUUID()`, `uuid` package calls, Prisma/Drizzle
  schema ID column definitions
- C4 exclusions: `enum` definitions, `as const` union objects, Zod
  `z.enum([...])` declarations
- Common fixture locations: `__mocks__/`, `*.fixture.ts`, `test/factories/`

### Go
- C1 exclusions: `uuid.New()` / `uuid.NewString()` calls, struct tag type hints
- C4 exclusions: typed string constant blocks (`type Status string` + `const`)
- Common fixture locations: `testdata/`, `*_test.go`

### Other languages
Follow the same principle: exclude ID *generation* and *type declaration*,
flag ID *literals in logic*. Exclude typed constant definitions, flag raw
string comparisons.
