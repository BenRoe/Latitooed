# Phase 7: Live Place Search - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 7-live-place-search
**Areas discussed:** Search button fate, Results overlay style, Debounce & min chars, Clear/cancel UX

---

## Search Button Fate

| Option | Description | Selected |
|--------|-------------|----------|
| Remove entirely | Pure live search — typing drives everything. Matches Apple Maps. Simpler UI. | ✓ |
| Keep as explicit trigger | Button stays as fallback. Adds complexity but keeps keyboard shortcut muscle memory. | |
| Hide, keep Enter key | Remove button visually but still fire on Return key as fallback. | |

**User's choice:** Remove it entirely
**Notes:** None

---

## Results Overlay Style

| Option | Description | Selected |
|--------|-------------|----------|
| Floating dropdown overlay | Results float above map, disappear on selection/click-away. Apple Maps style. | ✓ |
| Keep inline expanding panel | Results push content down inside search panel. Simpler but hides map. | |
| Split: search row + results list below | Dedicated scrollable section below search. Fixed vertical space. | |

**User's choice:** Floating dropdown overlay

**Anchor position:**

| Option | Description | Selected |
|--------|-------------|----------|
| Below the search field | Standard dropdown. Anchors to bottom edge of TextField. | ✓ |
| Over map, full width | Results span full width of map area below search bar. | |

**User's choice:** Below the search field
**Notes:** None

---

## Debounce & Min Chars

| Option | Description | Selected |
|--------|-------------|----------|
| 2 characters | Matches Apple Maps. Avoids single-letter noise. | |
| 3 characters | Fewer API calls, more intentional. | ✓ |
| 1 character | Maximum responsiveness, noisy results. | |

**Min chars choice:** 3 characters

| Option | Description | Selected |
|--------|-------------|----------|
| 300ms | Standard UI debounce. Responsive. | |
| 500ms | Slower, more conservative on API calls. | ✓ |
| 150ms | Very fast, more MKLocalSearch requests. | |

**Debounce choice:** 500ms
**Notes:** Conservative settings intentional to reduce MapKit call rate.

---

## Clear / Cancel UX

| Option | Description | Selected |
|--------|-------------|----------|
| X button + Escape key | Clear button when field has text. Escape also clears. Apple Maps pattern. | ✓ |
| Escape key only | No visible clear button. | |
| Backspace to empty | No explicit affordance. Results dismiss when below min chars. | |

**Clear choice:** X button in field + Escape key

| Option | Description | Selected |
|--------|-------------|----------|
| Keep query text, dismiss dropdown | Field shows place name after selection. Matches Maps. | ✓ |
| Clear field, dismiss dropdown | Field empties after selection. Clean slate. | |
| Keep query, keep dropdown open | Results stay for comparison. | |

**On-selection choice:** Keep query text, dismiss dropdown
**Notes:** None

---

## Claude's Discretion

None — all areas had explicit user decisions.

## Deferred Ideas

None — discussion stayed within phase scope.
