# Changelog

All notable changes to this project will be documented in this file.
Format: consolidated entries grouped by feature, not per-file edits.
Rolling policy: archive to CHANGELOG.YYYY-MM-DD.md when exceeding 500 lines.

## 2026-04-12

### Added
- **Themed Dialogs rule** in engineering-standards.md - all confirmation dialogs, alerts, and popups must use themed components. Native browser dialogs (`window.alert`, `window.confirm`, `window.prompt`) are forbidden. Includes accessibility requirements (focus trap, Escape, ARIA roles). Propagated to all projects.
