Act as a senior frontend performance engineer specializing in React, browser rendering pipelines, and Core Web Vitals optimization.

Your task is to perform a comprehensive frontend performance audit of this codebase. Identify rendering bottlenecks, memory leaks, unnecessary re-renders, bundle bloat, and Core Web Vitals issues. Produce a prioritized fix plan with concrete code-level recommendations.

---

## Phase 1: Static Analysis (no browser needed)

Scan the codebase for known performance anti-patterns:

**React Rendering:**
1. Components missing `React.memo()` that receive stable props but re-render due to parent changes. Focus on list item components rendered inside `.map()` loops.
2. Inline object/array literals in JSX props (`style={{...}}`, `options={[...]}`) that create new references every render.
3. Callbacks defined inline in JSX without `useCallback` - especially in `.map()` loops where each iteration creates a new function.
4. `useEffect` dependencies that change on every render (objects, arrays, functions not wrapped in `useMemo`/`useCallback`).
5. Expensive computations inside render bodies that should be wrapped in `useMemo`.
6. Components that subscribe to broad context values but only use a small slice - causing re-renders on unrelated context changes.
7. Missing `useTransition` for non-urgent state updates - search/filter inputs that trigger expensive re-renders should use `startTransition` to keep the input responsive.
8. Missing `useDeferredValue` for derived expensive renders - values driving expensive child renders (search queries, filter criteria) that block input responsiveness.
9. React Compiler awareness - if on React 19+ with compiler enabled, flag redundant manual `useMemo`/`useCallback`. If NOT on React 19+, flag missing memoization.

**DOM, CSS & Rendering:**
10. Animations using `height`, `width`, `top`, `left`, `margin`, or `padding` instead of `transform`/`opacity` (triggers layout on every frame instead of compositor).
11. `box-shadow`, `border-radius`, or `filter` transitions that trigger paint on every frame.
12. Large DOM trees - components rendering 100+ elements when most are off-screen (candidates for virtualization or `content-visibility: auto`).
13. Missing CSS `contain: content` on independent UI islands (cards, tiles, widgets, drawers) - without containment, a change inside one card triggers layout recalculation across the entire document.
14. Missing `content-visibility: auto` with `contain-intrinsic-size` on long scrollable lists and below-fold sections - achieves virtualization-like performance without JavaScript.
15. CSS selectors with high specificity or deep nesting that force expensive style recalculation.
16. `will-change` applied broadly or permanently instead of only on elements that actually animate.

**Resource Loading & LCP:**
17. LCP image missing `fetchpriority="high"` attribute. LCP image with `loading="lazy"` (contradicts priority).
18. Missing `<link rel="preconnect">` to critical origins (CDN, font provider, API) in document head.
19. Missing `<link rel="preload">` for critical resources the browser can't discover from HTML parsing (CSS background images, fonts).
20. Large dependencies imported eagerly that should be lazy-loaded or code-split.
21. Barrel file re-exports (`index.ts`) that pull in entire feature modules when only one component is needed.
22. Duplicate utility code across features that should be in `shared/`.

**Image & Font Optimization:**
23. Images served only as JPEG/PNG without modern format alternatives (AVIF/WebP via `<picture>` element or framework image component).
24. Images missing `srcset` and `sizes` for responsive delivery. Images missing explicit `width`/`height` attributes (causes CLS).
25. Font files loading full Unicode ranges when only Latin subset is needed. More than 2 font families or 4 font files total.
26. `@font-face` using `font-display: swap` without metric override descriptors (`size-adjust`, `ascent-override`, `descent-override`) on fallback fonts - causes CLS on font swap.
27. Non-critical fonts using `font-display: swap` when `font-display: optional` (with preload) would eliminate both FOIT and CLS.

**Third-Party Scripts:**
28. Third-party scripts (analytics, chat widgets, A/B testing) loaded synchronously or without `async`/`defer`. Scripts that should use `strategy="lazyOnload"` (Next.js) or be offloaded to Web Workers (Partytown).
29. Analytics/tracking calls inside click handlers that block visual updates - should be deferred with `requestIdleCallback` or `scheduler.postTask({ priority: 'background' })`.

**Memory:**
30. `useEffect` without cleanup functions - especially for `addEventListener`, `setInterval`, `setTimeout`, WebSocket connections, `IntersectionObserver`, and `ResizeObserver`.
31. Event bus subscriptions without corresponding unsubscribe in cleanup.
32. Cache entries (React Query, SWR, or custom) that grow unbounded - missing `gcTime`, `staleTime`, or max entry configuration.
33. Closures in long-lived callbacks (WebSocket handlers, timers) that capture stale component state.

**CLS-Specific:**
34. Ad slots, embeds, and iframes without explicit `width`/`height` or CSS `aspect-ratio` set before content loads.
35. Dynamic content injected above the fold (cookie banners, notification bars, promotional banners) that pushes existing content down instead of using `position: fixed/sticky` or reserved space.

**INP-Specific:**
36. Long event handlers (>50ms) that should yield to the main thread using `scheduler.yield()` (with `setTimeout(0)` fallback).
37. Non-urgent work (analytics, logging) in event handlers that runs before state updates - should be deferred after paint.

**Hydration (SSR/SSG):**
38. Hydration mismatches - `Date.now()`, `Math.random()`, `typeof window`, `navigator`, or locale-dependent formatting in components rendered on both server and client.
39. Overly broad `"use client"` boundaries - directive on parent containers instead of leaf interactive components, forcing hydration of static content.
40. Top-level `await` in page components blocking the entire page render instead of isolating slow fetches behind `<Suspense>` boundaries.
41. Missing `<Suspense>` boundaries for independently-loadable sections - prevents streaming partial content.
42. Large serialized payloads crossing server/client boundary - full database rows passed as props when only a few fields are needed.

**Network & Caching:**
43. Static assets (JS, CSS, images with content hashes) missing `Cache-Control: public, max-age=31536000, immutable`. HTML documents missing `Cache-Control: public, max-age=0, must-revalidate`.
44. Web Workers not used for CPU-intensive operations (sorting large datasets, JSON parsing large payloads, complex calculations) that block the main thread for >50ms.

---

## Phase 2: DevTools Investigation (requires browser)

Use Chrome DevTools MCP tools to measure actual performance:

**Core Web Vitals:**
```
# Lighthouse audit - baseline scores
lighthouse_audit(device: "mobile")

# Page load trace - identify LCP element, render-blocking resources
navigate_page(url: "http://localhost:5173")
performance_start_trace(reload: true)
# After auto-stop, analyze:
performance_analyze_insight(insightSetId: "...", insightName: "LCPBreakdown")
performance_analyze_insight(insightSetId: "...", insightName: "DocumentLatency")
```

**Interaction Performance (INP):**
```
# Record an interaction - measure responsiveness
performance_start_trace(reload: false, autoStop: false)
# Perform the interaction (click, type, etc.)
click(uid: "target-element-uid")
performance_stop_trace()
# Look for: long tasks > 50ms, layout thrashing, forced reflows
```

**Simulated Slow Device:**
```
# Throttle to simulate real-world conditions
emulate(cpuThrottlingRate: 6, networkConditions: "Fast 3G")
# Re-run Lighthouse and interaction tests under throttling
lighthouse_audit(device: "mobile")
```

**Memory Leaks:**
```
# Heap snapshot comparison
take_memory_snapshot(filePath: "before.heapsnapshot")
# Navigate around, open/close panels, then return
take_memory_snapshot(filePath: "after.heapsnapshot")
# Compare: look for detached DOM trees, growing arrays
```

**Paint Performance:**
```
# Take screenshot, then scroll/interact and take another
take_screenshot(filePath: "paint-check.png")
# Check: does scrolling cause repaints outside the scroll area?
# Check: does hovering an item repaint the entire list or just the item?
# Verify animations run on compositor thread (no layout/paint in Performance panel)
```

---

## Gap-Finding Behavior

Do not report a finding as isolated without first checking whether it is systemic.

- If one component is missing memoization, audit all sibling components in the same feature for the same pattern.
- If one image is missing responsive attributes, audit all images across the codebase.
- If one third-party script is loaded synchronously, audit all external script tags.
- If one event handler has a long task, audit all interaction handlers for the same pattern.
- If one font is missing metric overrides, audit all `@font-face` declarations.
- If one component has a broad `"use client"` boundary, audit all client component boundaries.

Treat the codebase as a pattern landscape, not a collection of isolated issues.

---

## Operating Constraints

- Base every finding on direct evidence from the codebase or DevTools measurement.
- Do not flag speculative micro-optimizations without evidence of impact.
- Do not flag premature memoization on components that render fewer than 5 times per interaction.
- Do not flag bundle size concerns for chunks that are already lazy-loaded.
- Prioritize by user-perceived impact: LCP and INP fixes before bundle size, above-fold before below-fold.
- Distinguish between "fix now" (visible jank, failed CWV) and "fix when touching the file" (accumulated anti-patterns).

---

## Evidence Requirements

For each finding:

- Cite exact file, component name, or line pattern.
- State whether the issue is local, repeated, or systemic.
- Describe the concrete impact: estimated time saved, bytes reduced, or CWV metric improved.
- Provide the specific fix (code change, not "optimize this").

---

## Required Output

### A. Executive Summary

- Core Web Vitals status: LCP, INP, CLS scores and primary bottlenecks
- Top 3 highest-impact fixes with estimated improvement
- Whether the app would pass CWV thresholds on mobile under throttling
- Bundle size assessment and largest optimization opportunities

### B. Findings Table

| Field | Content |
|---|---|
| Title | Short descriptive label |
| Severity | Critical / High / Medium / Low |
| Category | Rendering / Bundle / Memory / CLS / INP / LCP / Network |
| Scope | Local / Repeated / Systemic |
| Evidence | File, component, DevTools measurement, or code snippet |
| Impact | Estimated improvement (ms saved, KB reduced, CWV delta) |
| Fix | Concrete code change |
| Effort | Low / Medium / High |

### C. Core Web Vitals Scorecard

For each measured page/route:

| Route | LCP | INP | CLS | FCP | TTI | Bundle Size | Status |
|---|---|---|---|---|---|---|---|
| / | | | | | | | Pass/Fail |

### D. Optimization Roadmap

- **Phase 1: Critical CWV fixes** - issues causing failed thresholds or visible jank
- **Phase 2: High-impact optimizations** - measurable improvement under throttling
- **Phase 3: Accumulated anti-patterns** - fix when touching the file

### E. Do Not Miss Checklist

Confirm you explicitly reviewed each of the following:

- [ ] LCP element identified and optimized (fetchpriority, preload, format)
- [ ] INP measured for primary interactions (click, type, scroll)
- [ ] CLS sources identified (images, fonts, dynamic content, ads)
- [ ] React memoization patterns across all list/repeated components
- [ ] useTransition/useDeferredValue for search/filter interactions
- [ ] Context subscription breadth across all context consumers
- [ ] useEffect cleanup functions on all subscriptions and timers
- [ ] Bundle analysis: largest chunks, lazy loading opportunities, barrel files
- [ ] Image optimization: format, responsive, dimensions, priority
- [ ] Font loading: subsetting, metric overrides, display strategy
- [ ] Third-party script loading strategy and main-thread impact
- [ ] CSS containment on independent UI components
- [ ] content-visibility on long scrollable lists
- [ ] Cache-Control headers on static assets
- [ ] Hydration mismatches and "use client" boundary placement (if SSR)
- [ ] Memory leak patterns: heap growth after repeated navigation
- [ ] Animation performance: compositor-only properties, will-change usage

## What NOT to Flag

- Speculative micro-optimizations without evidence ("this loop could be faster")
- Premature memoization on components that render fewer than 5 times per interaction
- Bundle size concerns for chunks that are already lazy-loaded
- Performance issues in admin-only or low-traffic pages unless specifically requested
- React Compiler redundancy warnings if the project is not on React 19+
