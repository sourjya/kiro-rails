# Release Process (kiro-rails maintainers)

How to cut a kiro-rails release. Pairs with the `versioning.md` checklist; this adds
the repo-specific publish + verification steps.

## Steps

1. **Work on a branch**, never on `main` (per `git-workflow.md` / `focus-and-branch-discipline.md`).
2. **Bump the version** in both installers - `install.sh` (`CURRENT_VERSION`) and `install.ps1` (`$CurrentVersion`). They must match. (The bump is what makes existing installs pick up changes on re-run.)
3. **Update the changelog** - add a dated `vX.Y.Z` section to `docs/changelogs/CHANGELOG.md`.
4. **Regenerate the Claude layer** - `bash scripts/export-to-claude.sh && git add .claude .mcp.json`, then confirm `bash scripts/check-claude-fresh.sh` prints `OK`.
5. **Pre-push smoke test** - validate the *un-pushed* working tree before it goes out:

   ```bash
   bash scripts/smoke-test-install.sh --local
   ```

   This serves the working tree over a local http server and installs from it, running
   both `install.sh` and `install.ps1` natively (the latter when `pwsh` is present).
   Catches path/version/missing-file regressions before they reach `main`. Must print
   `SMOKE TEST PASSED`.
6. **Merge** the branch to `main` with `--no-ff`, then delete the branch.
7. **Push** `main` to both remotes: `git push origin main && git push codecommit main`.
8. **Tag** (annotated) and push: `git tag -a vX.Y.Z -m "..." && git push origin vX.Y.Z && git push codecommit vX.Y.Z`. The repo tags every minor and patch.
9. **GitHub release**: `gh release create vX.Y.Z --title "..." --notes-file <notes> --latest`.
10. **Post-push smoke test** - confirm the published release actually installs:

   ```bash
   bash scripts/smoke-test-install.sh           # tests ref 'main'
   bash scripts/smoke-test-install.sh vX.Y.Z    # or pin to the tag
   ```

   This installs into throwaway dirs and asserts: `install.sh` exits 0 with zero
   download warnings, the version file matches, and nothing is left behind; and that
   `install.ps1` either runs clean (if `pwsh` is installed) or that all of its managed
   URLs resolve (HTTP 200) - which catches the "manifest entry with no published file"
   404 class of bug. Exit 0 = `SMOKE TEST PASSED`.

## Notes

- `install.ps1` native execution needs PowerShell (`pwsh`). On Ubuntu/WSL install it via
  Microsoft's apt repo (`powershell` package) or `snap install powershell --classic` -
  there is no `pwsh` apt package. Without it, the smoke test still validates the ps1
  manifest via URL checks.
- `scripts/smoke-test-install.sh` is a maintainer tool (it targets this repo's raw URLs)
  and is deliberately not shipped as a managed file.
