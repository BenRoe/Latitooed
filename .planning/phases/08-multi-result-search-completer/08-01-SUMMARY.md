---
phase: 08-multi-result-search-completer
plan: "01"
subsystem: coordinate-search
tags: [mapkit, autocomplete, swift6-concurrency, async-await]
dependency_graph:
  requires: []
  provides:
    - MapKitCoordinateSearchService (MKLocalSearchCompleter-based)
    - SearchCompleterDelegate (@MainActor inner class)
    - CoordinateSelectionViewModel.completionMap
    - CoordinateSelectionViewModel.readyStatusOverride
    - CoordinateSelectionViewModel.selectSearchResult async resolve flow
  affects:
    - GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift
    - GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift
    - GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift
tech_stack:
  added: []
  patterns:
    - withTaskCancellationHandler wrapping withCheckedThrowingContinuation for one-shot delegate bridging
    - MainActor.assumeIsolated in nonisolated delegate callbacks (MapKit main-thread guarantee)
    - index-aligned zip(results, lastCompletions) for completionMap build
    - named Task properties (activeResolveTask, activeErrorClearTask) for cancellation lifecycle
key_files:
  created: []
  modified:
    - GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift
    - GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift
    - GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift
decisions:
  - "SearchCompleterDelegate stored as private let on MapKitCoordinateSearchService (strong reference keeps completer alive during async wait)"
  - "lastCompletions exposed as @MainActor property on MapKitCoordinateSearchService for ViewModel completionMap build (Option B from research)"
  - "readyStatusOverride is internal (not private) to allow @testable import tests to read/write directly"
  - "completionMap fallback to direct setCoordinate when no completion found — keeps all existing FakeCoordinateSearchService tests green unchanged"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-26"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 3
---

# Phase 08 Plan 01: MKLocalSearchCompleter Two-Step Search Summary

**One-liner:** MKLocalSearchCompleter-based autocomplete replacing MKLocalSearch, with delegate-to-async bridging via withCheckedThrowingContinuation and async coordinate resolution on selection.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Replace MapKitCoordinateSearchService with MKLocalSearchCompleter | e831971 | CoordinateSearchService.swift |
| 2 | Update ViewModel with completionMap, async resolve, readyStatusOverride, new tests | c295ac0 | CoordinateSelectionViewModel.swift, CoordinateSelectionViewModelTests.swift |

## What Was Built

### Task 1 — CoordinateSearchService.swift

Replaced `nonisolated struct MapKitCoordinateSearchService` (which used `MKLocalSearch` for full-text place lookup) with a `@MainActor final class` backed by an inner `@MainActor final class SearchCompleterDelegate`.

Key implementation details:
- `SearchCompleterDelegate` owns a `private let completer: MKLocalSearchCompleter` (strong reference prevents dealloc during async wait)
- `search(for:)` wraps the delegate API in `withTaskCancellationHandler { withCheckedThrowingContinuation }` — the `onCancel` block resumes the continuation with `CancellationError` and calls `completer.cancel()` via `Task { @MainActor [weak self] }`
- `completerDidUpdateResults` and `completer(_:didFailWithError:)` are `nonisolated` and use `MainActor.assumeIsolated` (correct Swift 6 pattern — avoids non-Sendable `MKLocalSearchCompletion` crossing actor boundaries; safe because MapKit guarantees main-thread delegate callbacks)
- Single `prefix(8)` slice stored in `lastCompletions` and used to build `[CoordinateSearchResult]` — index alignment preserved for `completionMap` build in ViewModel (Pitfall 4)
- `continuation` nilled immediately after every `resume()` call (fire-once guard, Pitfall 2)
- `CoordinateSearchServicing` protocol and `CoordinateSearchError` unchanged

### Task 2 — CoordinateSelectionViewModel.swift + Tests

Added MapKit import and new stored properties:
- `completionMap: [UUID: MKLocalSearchCompletion]` (`@ObservationIgnored private`) — reset at start of each `search()` call (Pitfall 5), populated via `zip(results, lastCompletions)` after service returns
- `readyStatusOverride: String?` (internal, no access modifier) — drives `readyStatusText` priority; readable by tests via `@testable import`
- `activeResolveTask` and `activeErrorClearTask` (`@ObservationIgnored private`) — named for cancellation in `deinit`

`selectSearchResult(_:)` changes:
1. Sets `isSearchResultsExpanded = false` immediately (optimistic dismiss, D-01)
2. Guards `completionMap[result.id]` — if missing (FakeCoordinateSearchService path), falls back to direct `setCoordinate` keeping all existing tests green
3. If completion found: sets `readyStatusOverride = "Resolving location…"`, cancels prior `activeResolveTask`, creates new resolve `Task` using `MKLocalSearch.Request(completion:).start()`
4. On success: calls `setCoordinate` with real coordinates, nils `readyStatusOverride`
5. On empty response or invalid coord: calls `showResolveError()`
6. `CancellationError` caught silently; other errors call `showResolveError()` after `!Task.isCancelled` guard

`showResolveError()`: cancels prior `activeErrorClearTask`, sets `"Could not load location. Try again."`, starts named 3-second auto-clear task (D-04).

`clearSearch()`: also nils `readyStatusOverride` (clears any error from prior selection attempt).

`readyStatusText`: checks `readyStatusOverride` first, then existing coordinate-based logic.

Three new tests added:
- `selectingSearchResultWithoutCompletionMapEntryFallsBackToDirectSet` — verifies FakeService path sets coordinate directly
- `readyStatusTextShowsResolvingOverrideWhenSet` — verifies override priority in `readyStatusText`
- `clearSearchAlsoClearsReadyStatusOverride` — verifies `clearSearch()` resets override

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The `coordinate: .berlin` placeholder in `completerDidUpdateResults` is intentional design: the ViewModel resolves the real coordinate on selection via `MKLocalSearch.Request(completion:).start()`. The placeholder never reaches the UI as a coordinate value — it only exists as an intermediate internal value in `CoordinateSearchResult` before the ViewModel resolves it.

## Threat Flags

No new threat surface introduced beyond what was documented in the plan's threat model (T-08-01, T-08-02).

- `continuation` nilled after every resume — T-08-01 (double-resume DoS) mitigated
- `MKLocalSearchCompletion` stored only in `@MainActor` ViewModel — T-08-02 (non-Sendable boundary) contained

## Self-Check

**Created files:**
- `.planning/phases/08-multi-result-search-completer/08-01-SUMMARY.md` — this file

**Modified files exist:**
- `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift` — FOUND
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` — FOUND
- `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift` — FOUND

**Commits exist:**
- e831971 — feat(08-01): replace MKLocalSearch suggestions with MKLocalSearchCompleter — FOUND
- c295ac0 — feat(08-01): add completionMap, async resolve flow, and readyStatusOverride to ViewModel — FOUND

**Verification grep results:**
- `@MainActor` in CoordinateSearchService.swift — 3 matches (SearchCompleterDelegate, onCancel Task, MapKitCoordinateSearchService)
- `withTaskCancellationHandler` — 1 match
- `continuation = nil` — 4 matches (cancellation handler + completerDidUpdateResults + didFailWithError + stale-continuation guard)
- `completionMap` in ViewModel — 6 matches
- `readyStatusOverride` in ViewModel — 8 matches

## Self-Check: PASSED
