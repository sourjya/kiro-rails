---
inclusion: fileMatch
fileMatchPattern: ["**/api/**", "**/routes/**", "**/services/**/*.ts", "**/services/**/*.py", "**/schemas/**", "**/hooks/use*.ts"]
---

# API Contract Discipline

Rules for API boundary code. Loaded when working on routes, services, schemas, or data-fetching hooks.

## Contract-First Development - MANDATORY

**Define the response shape BEFORE implementing either side.**

### Rules

1. **Schema first, code second** - before implementing any API endpoint, define the response type (Pydantic model, TypeScript interface, or Zod schema). Both frontend and backend implement against this contract.
2. **Never assume response shape** - don't write `resp.data.message` without verifying the backend actually returns `{data: {message: ...}}`. Check the schema or test the endpoint.
3. **Envelope consistency** - decide once per project: do list endpoints return raw arrays or `{items: [...], total: N}`? Document it. Never mix approaches.
4. **Type the full response** - including HTTP status, headers, and error shapes. Don't just type the happy path.
5. **Axios/fetch unwrapping** - document whether your API client unwraps responses. If using Axios, `resp.data` is the body. If your client auto-unwraps, the hook gets the body directly. Never guess.

## Response Shape Verification - MANDATORY

When connecting frontend to backend:

1. **Log the actual response** - before writing rendering code, `console.log` or inspect the actual API response shape. Don't assume from the backend code.
2. **Handle nested envelopes** - if the API returns `{data: {project: {...}}}`, don't type the result as `Project`. Type it as `{data: {project: Project}}` and extract.
3. **Array vs object** - verify: does the endpoint return `[...]` or `{items: [...]}` or `{results: [...]}`? This is the #1 source of frontend crashes.
4. **Null vs undefined vs missing** - document which fields can be null, which are optional (may be missing from response), and which are always present.

## Error Response Contract - MANDATORY

1. **Structured error responses** - all API errors return a consistent shape: `{error: string, detail?: string, code?: string}`. Never return raw exception messages.
2. **Never expose internals** - no stack traces, file paths, SQL queries, or internal service names in error responses. Use generic messages with correlation IDs for debugging.
3. **HTTP status codes are semantic** - 400 for validation, 401 for auth, 403 for authorization, 404 for not found, 409 for conflict, 422 for unprocessable, 500 for server errors. Never return 200 with an error body.

## Rate Limiting - GUIDANCE

1. **Per-endpoint, not global** - rate limits should be scoped to specific endpoints, not applied as global middleware that blocks everything.
2. **Generous in dev** - start with 100+/min in development. Tighten for production based on actual usage patterns.
3. **Return 429 with Retry-After** - include the `Retry-After` header so clients know when to retry.
