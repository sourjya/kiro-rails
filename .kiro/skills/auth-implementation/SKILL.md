---
name: auth-implementation
description: Authentication, SSO, OAuth, OIDC, login, redirect, token implementation patterns. Use when implementing auth flows, login pages, token refresh, SSO integration, or redirect handling.
---

# Auth Implementation Checklist

When implementing any authentication flow, ALL of the following paths must be handled. Do not implement only the happy path.

## Mandatory Paths

### 1. Happy Path
- User has valid session → proceed normally
- User authenticates successfully → redirect to intended destination

### 2. Expired Token
- Access token expired → attempt silent refresh with refresh token
- Refresh token expired → redirect to login (not infinite loop)
- Never fire API requests before confirming token is available

### 3. Missing Session
- No token in storage → show login UI or redirect to identity provider
- Don't auto-redirect without checking if a session exists first

### 4. Redirect Loop Prevention
- **Max 2 redirects** then show an error page with clear message
- Store redirect count in sessionStorage, reset on successful auth
- Never redirect from login page back to login page

### 5. Provider-Specific Quirks
- **Cognito**: does NOT support `prompt=none` for silent auth
- **Keycloak**: supports `prompt=none` but returns `login_required` error if no session
- **Auth0**: supports silent auth via `/authorize` with `prompt=none`
- Always check provider documentation for supported parameters

### 6. Graceful Degradation
- If identity provider is unreachable → show error, don't crash the app
- If OIDC discovery endpoint fails → fall back to manual config or show maintenance page
- Never make the entire app dependent on auth provider availability for rendering

## Implementation Rules

1. **`redirect_uri` must be dynamic** — use `window.location.origin` + callback path. Never hardcode `localhost`.
2. **State parameter** — always include a random `state` param to prevent CSRF. Verify it on callback.
3. **Token storage** — access tokens in memory (short-lived), refresh tokens in httpOnly cookies or secure storage. Never localStorage for refresh tokens.
4. **Logout must clear ALL state** — tokens, cached user info, query cache, any auth-dependent state.
5. **401 handling** — on 401 response, attempt ONE silent refresh. If that fails, redirect to login. Don't retry indefinitely.
6. **Multi-tab sync** — if user logs out in one tab, other tabs should detect it (via storage event or BroadcastChannel).

## Testing Requirements

- Test with expired tokens (mock token expiry)
- Test with identity provider down (mock network failure)
- Test redirect loop scenario (verify max 2 redirects)
- Test multi-tab logout propagation
- Test with clock skew (token appears expired due to time difference)
