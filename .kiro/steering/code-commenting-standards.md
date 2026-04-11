---
inclusion: always
---

# Code Commenting Standards

Every piece of code must be commented so that a follow-on developer can understand all pieces without needing to ask the original author.

## Enforcement

1. **Automated hook** — `.kiro/hooks/comment-standards-check.kiro.hook` intercepts git commits and verifies staged source files meet this standard.
2. **Linting rules** — Enable docstring rules in your linter config.

## Guiding Principle

Comments answer "why" and "how it fits", not "what it does".

## Module-Level Docstrings / File-Level JSDoc

Every file must start with a docstring/JSDoc block that includes:
1. A one-line summary of the module's purpose
2. How this module fits into the larger architecture
3. Key design decisions or tradeoffs (link to ADRs where applicable)
4. For complex modules: a brief description of the internal flow

## Class and Function Docstrings

- Every public class and function must have a docstring/JSDoc
- Include Args/Returns/Raises sections for non-trivial functions
- For Pydantic models: document each field

## Inline Comments

Use for:
- Non-obvious design decisions
- Cross-module relationships
- Security rationale
- Performance tradeoffs
- Backward compatibility notes

Do NOT use for:
- Restating what the code does
- Obvious variable assignments
- Standard library usage

## Section Separators

For files with multiple logical sections, use comment block separators.

## Cross-Reference Comments

When code depends on or mirrors code in another module, add a cross-reference:
- "See also: ADR-005 for rationale"
- "The frontend mirrors these checks in auth.service.ts"

## Enum and Constant Comments

Document why each value exists, not just what it is.
