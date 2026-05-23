---
inclusion: fileMatch
fileMatchPattern: ["**/*.tsx", "**/*.jsx"]
---

# Frontend Patterns

Rules for React/JSX development. Loaded only when working on frontend component files.

## React Hooks — NON-NEGOTIABLE

1. **ALL hooks at the top of the component** — before any early returns, conditional logic, or variable declarations that depend on props. React requires the same hooks to run in the same order every render.
2. **Never place hooks after early returns** — this causes "Rendered more hooks than during the previous render" crashes.
3. **Verify required providers exist** — before using `useQuery`, `useParams`, `useNavigate`, or any context hook, confirm the component is rendered inside the required provider (`QueryClientProvider`, `Router`, etc.).
4. **Use `mutateAsync` + `await` for dependent operations** — never fire-and-forget with `mutate()` when a subsequent operation depends on the result. `mutate` is fire-and-forget; `mutateAsync` returns a promise.

## Event Propagation — MANDATORY

1. **Document event capture/propagation** — when adding event handlers, note what events are captured, what propagation is stopped, and what other handlers exist on parent/child elements.
2. **React synthetic `stopPropagation()` does NOT stop native DOM events** — if you need to stop a native event (e.g., window-level Escape listener), use `e.nativeEvent.stopImmediatePropagation()` or manage an event stack.
3. **Never spread DnD `{...listeners}` on containers with click handlers** — DnD listeners capture all pointer events. Apply them to a dedicated drag handle element instead.
4. **Escape key layering** — when multiple components listen for Escape (modals, drawers, dropdowns), implement a stack-based system. The topmost layer consumes the event; lower layers ignore it.
5. **Outside-click handlers + portals** — if a component renders via a portal (e.g., dropdown menu on `document.body`), the outside-click handler must check if the click target is inside the portal, not just inside the trigger's DOM tree.

## CSS Layout — MANDATORY

1. **Flex containers: always set `min-h-0` and `overflow-hidden`** on intermediate containers. Without `min-h-0`, flex children cannot shrink below their content size.
2. **Header/body alignment** — use the SAME layout strategy (grid or flex with identical gaps/gutters) for both header and body rows. Never mix CSS grid for headers with flex for rows.
3. **Popover/dropdown positioning** — verify the positioning direction matches the trigger's screen location. `right: 0` extends leftward (correct for right-side triggers). `left: 0` extends rightward (correct for left-side triggers).
4. **Absolute positioning inside overflow containers** — elements with `position: absolute` are clipped by ancestor `overflow: hidden`. Use a portal or move the positioned element outside the overflow container.

## Cache & Data Fetching — MANDATORY

1. **When setting `staleTime`** — document what invalidation scenarios exist. After any mutation that changes server state, verify the cache is invalidated or the query is refetched.
2. **After mutations, always invalidate** — call `queryClient.invalidateQueries()` for affected keys. Don't rely on staleTime expiry for data freshness after writes.
3. **Error + retry on 401** — if a query gets a 401, don't let `staleTime` prevent retry. Set `retry: false` for auth-dependent queries or clear the query cache on auth state change.
4. **Optimistic updates need rollback** — if using optimistic updates, always implement the `onError` rollback. Don't leave stale optimistic state on failure.

## Component Completeness — MANDATORY

Before marking any UI component or feature task as done, verify:
1. **Error state** — what does the user see when the API call fails?
2. **Loading state** — what does the user see while data is loading?
3. **Empty state** — what does the user see when there's no data?
4. **Persistence** — does any state need to survive page reload? If yes, where is it persisted?
5. **Destructive actions** — do delete/remove actions have confirmation dialogs with undo?
6. **Themed components only** — no native `<select>`, `window.alert()`, `window.confirm()`, or `title` attributes. Use the design system.

## UX Non-Negotiables — MANDATORY

These rules apply to ALL frontend layout and interaction decisions. Violations are bugs.

1. **Interaction locality** — controls must be near the object they affect. Never place a section menu at the far-right edge when the section title is on the left. Actions go before or beside their target.
2. **Primary content gets primary space** — descriptions, comments, and form fields are content, not metadata. They get dominant width and vertical breathing room. Never squeeze content below metadata.
3. **No decorative borders unless they encode state** — thick colored borders with no functional meaning are visual noise. Use subtle background, shadow, or tokenized selection treatment.
4. **Minimum readable text size** — body text minimum 14px. Content text (descriptions, comments) preferred 15-16px. Comments are content, not admin data.
5. **First-glance test** — within 3 seconds, user must know: what am I viewing, what is most important, what can I do next.
6. **Density matches task type** — data grids: compact is acceptable. Reading, comments, task detail, forms: spacious is required.
7. **Copy the reason, not just the surface** — when borrowing a pattern from another product, preserve WHY it works (interaction model, hierarchy, locality). Don't copy the visual and break the interaction.
8. **No `justify-between` for section actions** — section-level controls use leading or adjacent placement. Never push primary section controls to the far-right trailing slot unless they affect the entire page.
