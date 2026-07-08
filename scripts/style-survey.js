/**
 * style-survey.js — Computed-style census for UX rubric evidence.
 *
 * Run this script in a browser context (DevTools console, Playwright MCP
 * `javascript` tool, or any browser automation) to produce quantitative
 * evidence for the D (Density & Type) and K (Consistency & Tokens) rubric
 * families in .kiro/steering/ux-console-idiom.md.
 *
 * Output: a JSON object with font-size histogram, weight census, border-radius
 * set, button dimensions, heading hierarchy, tab/nav active states, and
 * table header/first-cell alignment data.
 *
 * Usage:
 *   - Paste into DevTools console on any page
 *   - Or invoke via browser MCP: mcp.browser.evaluate(script)
 *   - Or run via Playwright: page.evaluate(script)
 *
 * No dependencies. No side effects. Read-only DOM inspection.
 */
(() => {
  'use strict';

  /**
   * Collect computed styles from all visible elements on the page.
   * Skips hidden elements (display:none, visibility:hidden, zero-area).
   *
   * @returns {object} Structured survey results for rubric validation
   */
  function runStyleSurvey() {
    const results = {
      timestamp: new Date().toISOString(),
      url: window.location.href,
      viewport: { width: window.innerWidth, height: window.innerHeight },
      fontSizes: {},
      fontWeights: {},
      borderRadii: new Set(),
      headings: [],
      buttons: [],
      tabsAndNavItems: [],
      tableHeaders: [],
      formControls: [],
      colorValues: new Set(),
      spacingValues: new Set(),
    };

    const allElements = document.querySelectorAll('body *');

    for (const el of allElements) {
      // Skip invisible elements
      if (el.offsetWidth === 0 && el.offsetHeight === 0) continue;
      const cs = window.getComputedStyle(el);
      if (cs.display === 'none' || cs.visibility === 'hidden') continue;

      // ── Font sizes (D-1) ──────────────────────────────────────────
      const fontSize = cs.fontSize;
      results.fontSizes[fontSize] = (results.fontSizes[fontSize] || 0) + 1;

      // ── Font weights (D-2) ────────────────────────────────────────
      const fontWeight = cs.fontWeight;
      results.fontWeights[fontWeight] = (results.fontWeights[fontWeight] || 0) + 1;

      // ── Border radii (K-1) ────────────────────────────────────────
      const radius = cs.borderRadius;
      if (radius && radius !== '0px') {
        results.borderRadii.add(radius);
      }

      // ── Background/text colors (K-2 sampling) ─────────────────────
      const bgColor = cs.backgroundColor;
      const textColor = cs.color;
      if (bgColor && bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
        results.colorValues.add(bgColor);
      }
      if (textColor) {
        results.colorValues.add(textColor);
      }

      // ── Spacing values (K-3 sampling, padding only) ───────────────
      const pt = cs.paddingTop;
      const pb = cs.paddingBottom;
      const pl = cs.paddingLeft;
      const pr = cs.paddingRight;
      [pt, pb, pl, pr].forEach(v => {
        if (v && v !== '0px') results.spacingValues.add(v);
      });
    }

    // ── Headings hierarchy (D-3) ──────────────────────────────────────
    const headingTags = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];
    for (const tag of headingTags) {
      const els = document.querySelectorAll(tag);
      if (els.length > 0) {
        const cs = window.getComputedStyle(els[0]);
        results.headings.push({
          tag,
          count: els.length,
          fontSize: cs.fontSize,
          fontWeight: cs.fontWeight,
          lineHeight: cs.lineHeight,
        });
      }
    }

    // ── Buttons (dimensions + font) ───────────────────────────────────
    const buttons = document.querySelectorAll(
      'button, [role="button"], input[type="submit"], input[type="button"], a.btn, a.button'
    );
    const buttonSample = Array.from(buttons).slice(0, 20);
    for (const btn of buttonSample) {
      const cs = window.getComputedStyle(btn);
      const rect = btn.getBoundingClientRect();
      results.buttons.push({
        text: (btn.textContent || '').trim().slice(0, 30),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
        fontSize: cs.fontSize,
        fontWeight: cs.fontWeight,
        padding: `${cs.paddingTop} ${cs.paddingRight} ${cs.paddingBottom} ${cs.paddingLeft}`,
        borderRadius: cs.borderRadius,
      });
    }

    // ── Tabs and nav items — active state (K-5) ───────────────────────
    const navSelectors = [
      '[role="tab"]',
      '[aria-selected]',
      'nav a',
      '.nav-item',
      '.tab',
      '[class*="active"]',
      '[data-active]',
      '[aria-current]',
    ];
    const navItems = document.querySelectorAll(navSelectors.join(','));
    const navSample = Array.from(navItems).slice(0, 15);
    for (const item of navSample) {
      const cs = window.getComputedStyle(item);
      results.tabsAndNavItems.push({
        tag: item.tagName.toLowerCase(),
        text: (item.textContent || '').trim().slice(0, 30),
        isActive: item.getAttribute('aria-selected') === 'true' ||
                  item.getAttribute('aria-current') != null ||
                  item.classList.contains('active') ||
                  item.hasAttribute('data-active'),
        backgroundColor: cs.backgroundColor,
        color: cs.color,
        fontWeight: cs.fontWeight,
        borderBottom: cs.borderBottom,
        opacity: cs.opacity,
      });
    }

    // ── Table headers and first cells (T-1 alignment) ─────────────────
    const tables = document.querySelectorAll('table, [role="grid"], [role="table"]');
    const tableSample = Array.from(tables).slice(0, 5);
    for (const table of tableSample) {
      const headers = table.querySelectorAll('th, [role="columnheader"]');
      const firstRow = table.querySelector('tr:nth-child(2), [role="row"]:nth-child(2)');
      const firstCells = firstRow ? firstRow.querySelectorAll('td, [role="gridcell"], [role="cell"]') : [];

      if (headers.length > 0) {
        results.tableHeaders.push({
          headerCount: headers.length,
          cellCount: firstCells.length,
          headerWidths: Array.from(headers).slice(0, 8).map(h => Math.round(h.getBoundingClientRect().width)),
          cellWidths: Array.from(firstCells).slice(0, 8).map(c => Math.round(c.getBoundingClientRect().width)),
        });
      }
    }

    // ── Form controls without labels (A-5) ────────────────────────────
    const inputs = document.querySelectorAll('input, select, textarea');
    for (const input of inputs) {
      const id = input.id;
      const ariaLabel = input.getAttribute('aria-label');
      const ariaLabelledBy = input.getAttribute('aria-labelledby');
      const hasLabel = (id && document.querySelector(`label[for="${id}"]`)) ||
                       ariaLabel || ariaLabelledBy ||
                       input.closest('label');
      if (!hasLabel) {
        results.formControls.push({
          tag: input.tagName.toLowerCase(),
          type: input.type || 'text',
          name: input.name || '(unnamed)',
          placeholder: input.placeholder || '',
          hasLabel: false,
        });
      }
    }

    // ── Serialize sets to arrays ──────────────────────────────────────
    results.borderRadii = Array.from(results.borderRadii).sort();
    results.colorValues = Array.from(results.colorValues).sort();
    results.spacingValues = Array.from(results.spacingValues).sort();

    // ── Summary for quick rubric check ────────────────────────────────
    results.summary = {
      distinctFontSizes: Object.keys(results.fontSizes).length,
      distinctFontWeights: Object.keys(results.fontWeights).length,
      fontWeightList: Object.keys(results.fontWeights).sort(),
      distinctBorderRadii: results.borderRadii.length,
      borderRadiiList: results.borderRadii,
      distinctColors: results.colorValues.length,
      buttonCount: results.buttons.length,
      headingCount: results.headings.length,
      unlabelledFormControls: results.formControls.length,
      tableCount: results.tableHeaders.length,
      // D-1 check: most common body font size
      dominantFontSize: Object.entries(results.fontSizes)
        .sort((a, b) => b[1] - a[1])[0]?.[0] || 'unknown',
      // D-2 check: number of font weights
      fontWeightViolation: Object.keys(results.fontWeights).length > 2,
      // K-1 check: number of border-radius values
      borderRadiusViolation: results.borderRadii.length > 2,
    };

    return results;
  }

  // Execute and return
  const survey = runStyleSurvey();

  // If in DevTools console, pretty-print; otherwise return raw
  if (typeof console !== 'undefined' && typeof copy === 'function') {
    copy(JSON.stringify(survey, null, 2));
    console.log('Style survey copied to clipboard. Summary:');
    console.table(survey.summary);
    return survey.summary;
  }

  return JSON.stringify(survey, null, 2);
})();
