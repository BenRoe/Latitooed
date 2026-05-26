---
phase: 08-multi-result-search-completer
verified: 2026-05-26T22:00:00Z
status: human_needed
score: 7/7 must-haves verified (code-level)
overrides_applied: 0
deviations:
  - must_have: "Protocol stays unchanged (per ROADMAP.md notes line 194)"
    reason: "Code review (08-REVIEW.md) finding CR-04 identified that type-narrowing `any CoordinateSearchServicing` to `MapKitCoordinateSearchService` to read `lastCompletions` defeats the DI seam, breaks the FakeCoordinateSearchService test path, and exposes a happens-before race on a mutable side-channel. The fix (commit 0996423) reshaped the protocol to return `CoordinateSearchResults` (results + resolvers dictionary) and added `resolve(_:)`. This is documented in 08-REVIEW-FIX.md and was explicitly flagged by the user as an intentional improvement that should be documented but not fail verification."
    decision: "ACCEPTED — improvement preserves goal intent. The two-step completer/resolve flow described in the goal is implemented; only the protocol-level seam changed."
human_verification:
  - test: "Live MapKit completer returns multiple suggestions for partial queries"
    expected: "Typing 'leip', 'ber', 'pari' (3+ chars) in the search field shows 5+ results in the dropdown within ~500ms of stopping typing"
    why_human: "MKLocalSearchCompleter behavior requires a live network/MapKit context; result counts cannot be asserted in unit tests without mocking out the system framework"
  - test: "Selecting a suggestion resolves to the correct coordinate"
    expected: "Tap any non-Berlin result (e.g. 'Paris, France'). Status bar shows 'Resolving location…' briefly, then map pin moves to Paris and status reads 'Target set: 48.xxx, 2.xxx'. Crucially: pin is NOT Berlin (the prior placeholder), so the two-step resolve via MKLocalSearch is actually firing."
    why_human: "Requires running app with live MapKit; verifies the CR-01 fix (optional coordinate, real resolve)"
  - test: "Resolve failure shows error and auto-clears"
    expected: "Force a resolve failure (e.g. airplane mode, or tap an unresolvable result). Status bar shows 'Could not load location. Try again.' and clears to coordinate-state text after exactly ~3 seconds. The previously selected coordinate remains unchanged."
    why_human: "Timer-driven UX cannot be reliably asserted without injecting a controllable Clock; live behavior of the 3-second auto-clear requires manual observation"
  - test: "Cancellation race: typing fast does not crash or hang"
    expected: "Type 'b', 'be', 'ber', 'berl', 'berli', 'berlin' rapidly (faster than 500ms debounce). No crash, no SWIFT TASK CONTINUATION MISUSE runtime trap, only the final query's results appear. The currentSearchID identity stamp (CR-04 / WR-07 fix) is exercised here."
    why_human: "Continuation lifecycle race conditions only manifest at runtime; static analysis can verify the guard structure but not its real-world effectiveness"
  - test: "Stale resolve from prior search does not overwrite new selection"
    expected: "Search 'Berlin', wait for results, tap 'Berlin, Germany' (resolve starts). Before resolve completes (~few hundred ms), change query to 'Paris' and tap a Paris result. Final coordinate must be the Paris one — Berlin's stale resolve must not overwrite Paris (WR-03 fix)."
    why_human: "Two-step async race timing depends on real MapKit latency and is not deterministically reproducible in unit tests"
---

# Phase 8: Multi-Result Search Completer — Verification Report

**Phase Goal:** Replace `MKLocalSearch` with `MKLocalSearchCompleter` so partial queries (3+ chars) return multiple autocomplete suggestions instead of a single result. On selection, resolve the chosen completion to coordinates via `MKLocalSearch(request: .init(completion:))`.

**Verified:** 2026-05-26
**Status:** human_needed (code-level verification passed; live MapKit behavior requires human UAT)
**Re-verification:** No — initial verification after Plan 01 + code review fix iteration

## Goal Achievement

### Observable Truths (from PLAN frontmatter `must_haves.truths`)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Typing 3+ chars in the search field returns 5 or more suggestions in the dropdown | VERIFIED (code) | `CoordinateSearchPanel.swift:41` `guard trimmed.count >= 3` gate; `CoordinateSearchService.swift:108` `prefix(maxCompletionsShown)` where `maxCompletionsShown = 8`; live count requires human UAT (deferred to human_verification) |
| 2 | Each suggestion shows a title and optional subtitle | VERIFIED | `CoordinateSearchResult.swift:5-6` defines `title: String` + `subtitle: String?`; `CoordinateSearchService.swift:112-113` maps `completion.title` and `completion.subtitle.isEmpty ? nil : completion.subtitle`; `CoordinateSearchPanel.swift:138-146` renders title + conditional subtitle |
| 3 | Selecting a suggestion dismisses the dropdown immediately, shows 'Resolving location…' in the status bar, then sets the coordinate on success | VERIFIED | `CoordinateSelectionViewModel.swift:106` `isSearchResultsExpanded = false` (optimistic dismiss); line 137 sets `readyStatusOverride = "Resolving location…"`; lines 141-146 await `searchService.resolve(resolver)` then `setCoordinate(coord, label: result.title, …)` and clear override |
| 4 | If resolution fails, status bar shows 'Could not load location. Try again.' and clears after 3 seconds | VERIFIED | `CoordinateSelectionViewModel.swift:253-261` `showResolveError()` sets the exact string at line 255 and uses `Task.sleep(for: .seconds(3))` then nils override |
| 5 | All existing CoordinateSelectionViewModelTests and CoordinateSearchServiceTests pass unchanged | VERIFIED (trust host) | User reports xcodebuild test green at 21:26:52; existing tests still present in test files; `CoordinateSearchServiceTests.swift` was updated (commit 8118114) to consume the new `CoordinateSearchResults` bundle return type — this is a signature adaptation, not a semantic test change; existing behavioral assertions intact |
| 6 | No region hint is passed to MKLocalSearchCompleter (global search) | VERIFIED | `CoordinateSearchService.swift:65-66` explicit comment "No region biasing: surface global results"; no `.region =` assignment anywhere on the completer; no `MKCoordinateRegion` constructed |
| 7 | Results are capped at 8 suggestions | VERIFIED | `CoordinateSearchService.swift:50` `static let maxCompletionsShown = 8`; line 108 `Array(completer.results.prefix(Self.maxCompletionsShown))` |

**Score:** 7/7 truths verified at the code level. Truths 1, 3 (timing), 4 (timing) require human UAT for live MapKit behavior — surfaced in `human_verification`.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift` | MapKitCoordinateSearchService as @MainActor final class with inner SearchCompleterDelegate | VERIFIED | 161 lines; SearchCompleterDelegate at line 48 (private `@MainActor final class`); MapKitCoordinateSearchService at line 128 (`@MainActor final class`); both substantive, wired |
| `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` | resolverMap, readyStatusOverride, async resolve flow in selectSearchResult | VERIFIED | `resolverMap` at line 45 (renamed from `completionMap` in plan — intentional CR-04 fix, see deviations); `readyStatusOverride` at line 27 (internal); `selectSearchResult` async resolve at lines 105-155 |
| `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift` | New tests for resolve success, resolve failure, readyStatusText resolving state | PARTIAL — see anti-pattern IN-01 carry-over | Two new tests added: `selectingSearchResultWithPreResolvedCoordinateSetsTargetSynchronously` (line 301), `selectingSearchResultWithoutResolverAndWithoutCoordinateIsDropped` (line 316), `readyStatusTextShowsResolvingOverrideWhenSet` (line 329), `clearSearchAlsoClearsReadyStatusOverride` (line 337); however, NO test covers actual async resolve success/failure path against `MKLocalSearchCompletion` resolvers — REVIEW IN-01 carry-over |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `CoordinateSearchService.MapKitCoordinateSearchService.search` | `CoordinateSearchResults.results` | `MKLocalSearchCompleter.results` via delegate | Yes (live MapKit) | FLOWING (assumed via Apple framework; human UAT confirms) |
| `CoordinateSearchService.MapKitCoordinateSearchService.resolve` | `CoordinateSelection` | `MKLocalSearch.Request(completion:).start()` then `item.placemark.coordinate` | Yes (live MapKit) | FLOWING (verified via code path; throws `.unresolvable` if empty/invalid) |
| `CoordinateSelectionViewModel.searchResults` | `[CoordinateSearchResult]` | `bundle.results` from `searchService.search` | Yes | FLOWING — line 213 |
| `CoordinateSelectionViewModel.resolverMap` | `[UUID: CoordinateResolver]` | `bundle.resolvers` from `searchService.search` | Yes | FLOWING — line 212 |
| `CoordinateSelectionViewModel.selectedCoordinate` | `CoordinateSelection` | `searchService.resolve(resolver)` result on tap | Yes | FLOWING — line 143 |
| `CoordinateSearchPanel.SearchDropdownView.searchResults` | rendered list | `viewModel.searchResults` | Yes | FLOWING — line 106 |

### Key Link Verification

| From | To | Via | Expected Pattern (Plan) | Actual Pattern (Post-fix) | Status |
|------|-----|-----|-------------------------|---------------------------|--------|
| `CoordinateSelectionViewModel.search()` | service completions data | `as? MapKitCoordinateSearchService` (per plan) | Replaced by protocol-level `CoordinateSearchResults` bundle: `bundle.resolvers` at line 212 | WIRED (via intentional deviation — see CR-04 fix) |
| `CoordinateSelectionViewModel.selectSearchResult` | completion lookup | `completionMap[result.id]` (per plan) | `resolverMap[result.id]` at line 113 (renamed, same semantics — UUID lookup) | WIRED |
| `selectSearchResult` resolve path | `MKLocalSearch.Request(completion:)` | (per plan) direct call in ViewModel | Now encapsulated in `MapKitCoordinateSearchService.resolve` at line 149 — `MKLocalSearch.Request(completion: box.completion)` + `MKLocalSearch(request:).start()` at line 150 | WIRED (intentionally moved into service per CR-04) |
| `CoordinateSearchPanel` tap | `viewModel.selectSearchResult(result)` | SwiftUI button | `Button { viewModel.selectSearchResult(result); onDismiss() }` at line 108 | WIRED |
| `CoordinateSearchPanel` query input | `viewModel.search()` | onChange + 500ms debounce | Line 38-56 — onChange triggers debounceTask which calls `viewModel.search()` | WIRED |
| `SearchDropdownView` render | `viewModel.searchResults` | ForEach binding | Line 106 `ForEach(viewModel.searchResults) { result in ... }` | WIRED |

All key links verified — including the renamed `resolverMap` / `CoordinateSearchResults` plumbing that emerged from the code-review fix.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 8 files compile and tests pass | `xcodebuild test -scheme GPSMetadataEditor -destination 'platform=macOS'` (cannot run on Linux VM) | Reported green by user/host at 21:26:52 | TRUST — host result accepted per task instructions |
| Service exposes new protocol shape | `grep "func search.*CoordinateSearchResults\|func resolve" Services/CoordinateSearchService.swift` | 4 matches (protocol decl + 2 impls; service line 132 + 144) | PASS |
| ViewModel uses resolver pattern (no concrete-type cast) | `grep "as? MapKitCoordinateSearchService\|as!" CoordinateSelectionViewModel.swift` | 0 matches | PASS — CR-04 fix is live |
| No leaked debt markers in phase 8 files | `grep -E "TBD\|FIXME\|XXX" Services/CoordinateSearchService.swift CoordinateSelectionViewModel.swift Models/CoordinateSearchResult.swift Tests/CoordinateSelectionViewModelTests.swift Tests/CoordinateSearchServiceTests.swift` | 0 matches | PASS |
| No `print` debug calls in phase 8 production files | `grep "print(" Services/CoordinateSearchService.swift CoordinateSelectionViewModel.swift` | 0 matches | PASS — WR-01 fix is live |
| Continuation fire-once guard | `grep -c "continuation = nil" Services/CoordinateSearchService.swift` | 4 matches (search cleanup, onCancel, didUpdateResults, didFailWithError) | PASS — CR-02/CR-03 fixes are live |

### Probe Execution

No probes are defined for this phase — Swift/macOS project, no `scripts/*/tests/probe-*.sh` infrastructure present. Spot-checks above + host xcodebuild result substitute.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| LOC-01 | 08-01 | User can search for a place using Apple MapKit without providing Google or third-party API keys | SATISFIED | `MKLocalSearchCompleter` + `MKLocalSearch` are Apple MapKit framework calls; no API keys, no third-party SDKs imported. `CoordinateSearchService.swift` imports only `Foundation` and `MapKit` |
| LOC-02 | 08-01 | User can select a search result to set the target coordinate | SATISFIED | `CoordinateSelectionViewModel.selectSearchResult` (lines 105-155) handles selection; resolves via `searchService.resolve(resolver)` and calls `setCoordinate(coord, label: result.title, …)` on success; tap wired in `CoordinateSearchPanel.swift:108` |

Both requirement IDs from PLAN frontmatter are accounted for and satisfied at the code level. REQUIREMENTS.md traceability table still maps LOC-01/LOC-02 to "Phase 2" (line 96-97) because Phase 8 is an enhancement, not a re-allocation — the original Phase 2 coverage stands and Phase 8 strengthens the user-visible behavior. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `Views/CoordinateSearchPanel.swift` | 85 | `let _ = print("[DropdownView] render results=…")` left in source | Info (NOT phase 8 scope) | This file is NOT in Phase 8's `files_modified` list; the print is in uncommitted working-tree changes that introduce `SearchDropdownView`. Last committed change to this file was Phase 7 (commit `f6ae9dd`). Out of scope for this verification; flag to developer for separate cleanup. |
| `CoordinateSelectionViewModelTests.swift` | n/a | No test covers the async MKLocalSearch resolve path (only `.immediate` resolver case is exercised) | Info (REVIEW IN-01 carry-over, deferred from fix scope) | The fake service's `.mapKitCompletion` branch throws `.unresolvable`, so neither success nor failure of the real two-step resolve is unit-tested. Human UAT covers this; future test plan should add a fake resolver that returns a known coordinate. |

No blocker-class anti-patterns. No `TBD` / `FIXME` / `XXX` markers in any phase 8 file.

### Deviations from Plan (Acknowledged)

The PLAN frontmatter `must_haves.key_links` and the ROADMAP note "protocol stays unchanged" describe an implementation that injected `MapKitCoordinateSearchService` and read `lastCompletions` via `as? MapKitCoordinateSearchService` cast plus a `completionMap[result.id]` lookup. The code review (08-REVIEW.md CR-04) identified this as a DI break and stale-mutable-state race. The fix (commit `0996423`, summarised in 08-REVIEW-FIX.md) reshaped the protocol to return `CoordinateSearchResults` (results + resolvers) and added `resolve(_:)` to the protocol, so the ViewModel no longer type-checks. Per the verifier instructions, this deviation is **intentional and accepted** — the goal-level behavior (two-step completer/resolve, partial queries → multiple suggestions, on-select resolve to real coords) is fully preserved.

Concrete remapping:

- Plan said: `(searchService as? MapKitCoordinateSearchService)?.lastCompletions` → Actual: `bundle.resolvers` returned alongside `bundle.results` from `searchService.search` (line 207-213).
- Plan said: `completionMap: [UUID: MKLocalSearchCompletion]` → Actual: `resolverMap: [UUID: CoordinateResolver]` (line 45). Semantically equivalent, type-narrower for non-Sendable wrapping.
- Plan said: `MKLocalSearch.Request(completion:)` directly in ViewModel → Actual: encapsulated in `MapKitCoordinateSearchService.resolve` (line 149-150). Same MapKit call, moved into the service to keep DI clean.

### Human Verification Required

See `human_verification` block in the YAML frontmatter for the five UAT items the developer must run on macOS before closing the phase:

1. Live MapKit completer returns multiple suggestions for partial queries (verifies Truth 1 at runtime).
2. Selecting a suggestion resolves to the correct (non-Berlin) coordinate (verifies the CR-01 fix and two-step resolve end-to-end).
3. Resolve failure shows error and auto-clears after ~3 seconds (verifies Truth 4 timing).
4. Cancellation race: typing fast does not crash or hang (verifies CR-02 / CR-03 / WR-07 fixes).
5. Stale resolve from prior search does not overwrite new selection (verifies WR-03 fix).

### Gaps Summary

No blocker gaps. All seven plan-level truths are evidenced in the codebase at the static / code-structure level. The phase goal — replace `MKLocalSearch` with `MKLocalSearchCompleter` for partial-query autocomplete + two-step resolve on selection — is structurally achieved.

The reasons this verification returns `human_needed` rather than `passed`:

1. Linux dev VM cannot run `xcodebuild`, so the test-suite green light comes from host-reported execution rather than verifier-run execution. The host result is trusted per task instructions.
2. The behaviors that depend on live `MKLocalSearchCompleter` interaction with Apple's framework (5+ result count, real coordinate after resolve, "Resolving location…" visibility duration, 3-second error auto-clear timing, concurrent-typing safety) cannot be asserted from static code inspection.

Two pieces of follow-up work (non-blocking) the developer may want to schedule:

- Remove the stray `let _ = print("[DropdownView] render …")` from `CoordinateSearchPanel.swift:85` (uncommitted working-tree change, Phase 7 territory).
- Add a `Fake` `CoordinateResolver` test path so unit tests exercise the resolve success/failure branches without depending on live `MKLocalSearch` (closes REVIEW IN-01).

---

_Verified: 2026-05-26_
_Verifier: Claude (gsd-verifier)_
