# Steering File Research - 2026-04-11

Research into AI coding agent rule systems across Cursor, AGENTS.md, Claude Code, Windsurf,
and academic studies. Used to identify gaps in our steering files.

## Sources

1. **MSR 2026 Study** - "Beyond the Prompt: An Empirical Study of Cursor Rules" (arxiv.org/html/2512.18925v2)
   - Analyzed 401 open-source repos with cursor rules
   - Taxonomy: 5 themes (Convention, Guideline, Project, LLM Directive, Example), 20 codes
   - Key finding: 89% of repos include guidelines, 84% conventions, 85% project info

2. **ETH Zurich Study** - Context file effectiveness (arxiv.org/abs/2602.11988)
   - LLM-generated context files REDUCED task success by ~3%, increased cost 20%+
   - Human-curated files: marginal 4% improvement, still worth it
   - Architecture overviews are redundant - agents find them independently

3. **AGENTS.md Standard** - Linux Foundation / Agentic AI Foundation
   - Cross-tool standard (Codex, Copilot, Cursor, Windsurf, Claude Code)
   - Key pattern: three-tier permission system (Always / Ask First / Never)
   - "Don't Touch" zones for protected files/directories

4. **Kirill Markin's Global Cursor Rules** (kirill-markin.com/articles/cursor-ide-rules-for-ai/)
   - Error handling: never silently ignore, no automatic fallbacks, context in error messages
   - Change scope: "change as few lines as possible", no drive-by refactors
   - Consistency: match existing code style over "correct" style

5. **Augment Code Guide** (augmentcode.com/guides/how-to-build-agents-md)
   - Non-inferable details only - don't duplicate what agents can discover
   - Commands section most important (exact flags, full invocations)
   - 150-200 line threshold before splitting into modular files

6. **Cursor Community Patterns** (prompthub.us, cursor forum, cursorrules.org)
   - 68% include QA/error handling rules
   - 43% include performance guidelines
   - 38% include consistency/match-existing-patterns rules
   - 34% include accessibility/UI rules
   - 31% include dependency management rules

## Gaps Identified in Our Steering

| Gap | Priority | Where to Add |
|-----|----------|-------------|
| Error Handling Standards | High | engineering-standards.md |
| Performance Guidelines | High | engineering-standards.md |
| Permission Boundaries / Don't Touch Zones | High | engineering-standards.md |
| Consistency / Match Existing Patterns | Medium | engineering-standards.md |
| Change Scope Discipline | High | engineering-standards.md |
| Dependency Management (concrete rules) | Medium | execution-discipline.md |

## What We Already Cover Well

- Folder organization (layer-first backend, feature-sliced frontend)
- TDD mandate with RED/GREEN/REFACTOR
- Task-first discipline (no code without task list)
- Infrastructure abstraction (adapter pattern, factory instantiation)
- Centralized configuration and constants
- Security requirements
- Documentation and commenting standards
- Git workflow and branching
- Reusable component architecture
- Observability-first design

## What to Skip (Research Says Counterproductive)

- Architecture overviews in steering (agents find these independently)
- Restating README content (redundant, increases token cost)
- Auto-generated rules (LLM-generated context reduces success rate)
