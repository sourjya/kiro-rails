---
inclusion: auto
description: Version numbering, git tagging, and release process
---

# Versioning and Release Process

## Version Scheme

Semantic Versioning: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.0.0, 2.0.0): Breaking changes to public APIs, data formats, or user-facing contracts. Users must update their setup.
- **MINOR** (0.1.0, 0.2.0): New features, new capabilities. Backward compatible.
- **PATCH** (0.1.1, 0.1.2): Bug fixes, documentation updates, performance improvements. No new features.

## Pre-1.0 Rules (Beta)

While in beta (0.x.y):
- Minor version bumps for feature additions
- Patch bumps for bug fixes
- Breaking changes are allowed without major bump (beta expectation)
- Each minor version gets a git tag

## When to Tag

| Trigger | Version bump | Example |
|---|---|---|
| Bug fix that affects users | PATCH | `0.1.0` -> `0.1.1` |
| Security fix | PATCH (immediate) | `0.1.1` -> `0.1.2` |
| New feature | MINOR | `0.1.2` -> `0.2.0` |
| Breaking change (pre-1.0) | MINOR | `0.2.0` -> `0.3.0` |
| Stable release | MAJOR | `0.x.y` -> `1.0.0` |

## When NOT to Tag

- Documentation-only changes (no tag, no version bump)
- Internal refactors with no user-visible change
- Test additions
- CI/build changes

<!-- CUSTOMIZE: List all files that must be updated on version bump -->
## Files to Update on Version Bump

**The git tag is the authoritative version.** `docs/changelogs/CHANGELOG.md` is the
authoritative human-readable record. Every other version reference is a copy that
must be kept in sync with them.

Every file that hard-codes the version string must be listed here and bumped on
every release. kiro-rails has no build manifest, but its two installers each carry a
version constant that gates the "already installed / upgrade" decision, so they ARE
version files and must stay in sync with the tag:

```
install.sh    -> CURRENT_VERSION="0.18.0"
install.ps1   -> $CurrentVersion = "0.18.0"
```

(These drifted to 0.15.0 while tags reached 0.17.3 precisely because this list did
not name them - KRL-13. A version reference not on this list is one that silently
never gets bumped.) If you fork kiro-rails into a project WITH a build manifest, add
`pyproject.toml` / `package.json` here too; if you strip the installers, remove this
block rather than pointing the checklist at a file that does not exist.

Verify tags and changelog agree before releasing:

```bash
git tag -l "v*" | sort -V | tail -1                        # latest tag
grep -m1 -oE '^## [0-9-]+ - v[0-9.]+' docs/changelogs/CHANGELOG.md   # latest documented
```

## Release Checklist

1. All tests pass
2. Lint clean
3. Update version in all version files listed above (skip if the project has none)
4. Update `docs/changelogs/CHANGELOG.md` - move Unreleased items under the new version header with date
5. **Regenerate the Claude bonus layer** - the committed `.claude/` tree is a generated artifact and MUST be refreshed before tagging: `bash scripts/export-to-claude.sh && git add .claude`. Verify it is in sync with `bash scripts/check-claude-fresh.sh` (must print `OK`).
6. Commit: `chore: release vX.X.X`
7. Tag: `git tag -a vX.X.X -m "vX.X.X - brief description"`
8. Push: `git push origin main --tags`

## Tag Format

```
v0.1.0    (not 0.1.0 - always prefix with v)
v0.2.0
v1.0.0
```

## Git Tag Commands

```bash
# Create annotated tag (always use annotated, not lightweight)
git tag -a v0.1.0 -m "v0.1.0 - description"

# Push tag
git push origin v0.1.0

# List tags
git tag -l "v*"

# Delete a tag (if you made a mistake)
git tag -d v0.1.0
git push origin --delete v0.1.0
```
