---
status: partial
phase: 08-multi-result-search-completer
source: [08-VERIFICATION.md]
started: 2026-05-26T00:00:00Z
updated: 2026-05-26T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Live MapKit completer returns multiple suggestions for partial queries
expected: Typing 'leip', 'ber', 'pari' (3+ chars) in the search field shows 5+ results in the dropdown within ~500ms of stopping typing.
result: [pending]

### 2. Selecting a suggestion resolves to the correct coordinate
expected: Tap any non-Berlin result (e.g. 'Paris, France'). Status bar shows 'Resolving location…' briefly, then map pin moves to Paris and status reads 'Target set: 48.xxx, 2.xxx'. Crucially, pin is NOT Berlin (the prior placeholder) — confirms two-step resolve via MKLocalSearch fires.
result: [pending]

### 3. Resolve failure shows error and auto-clears
expected: Force a resolve failure (e.g. airplane mode, or tap an unresolvable result). Status bar shows 'Could not load location. Try again.' and clears to coordinate-state text after exactly ~3 seconds. Previously selected coordinate remains unchanged.
result: [pending]

### 4. Cancellation race: typing fast does not crash or hang
expected: Type 'b', 'be', 'ber', 'berl', 'berli', 'berlin' rapidly (faster than 500ms debounce). No crash, no SWIFT TASK CONTINUATION MISUSE runtime trap, only final query's results appear. Exercises currentSearchID identity stamp (CR-04 / WR-07 fix).
result: [pending]

### 5. Stale resolve from prior search does not overwrite new selection
expected: Search 'Berlin', wait for results, tap 'Berlin, Germany' (resolve starts). Before resolve completes (~few hundred ms), change query to 'Paris' and tap a Paris result. Final coordinate must be Paris — Berlin's stale resolve must not overwrite (WR-03 fix).
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
