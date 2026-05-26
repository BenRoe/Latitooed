# Phase 8: Multi-Result Search Completer — Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Source:** Conversation (Phase 7 post-mortem + user requirement)

<domain>
## Phase Boundary

Phase 7 implemented a live search dropdown using `MKLocalSearch`. The implementation works (tests pass, overlay renders, results display) but `MKLocalSearch` returns only 1 result for partial queries like "leip" because it is a full-text place lookup API, not an autocomplete API.

This phase replaces the search backend with `MKLocalSearchCompleter`, Apple's autocomplete API, which returns 5–10 suggestions for partial queries — matching Apple Maps UX. The UI (dropdown, scroll, styling) from Phase 7 is UNCHANGED. Only the search service implementation changes.

**In scope:**
- Replace `MKLocalSearch` request in `MapKitCoordinateSearchService` with `MKLocalSearchCompleter`
- Wrap delegate-based `MKLocalSearchCompleter` in async/await via `withCheckedThrowingContinuation`
- Two-step flow: completer returns completions → on user selection, resolve completion to coordinates via `MKLocalSearch(request: .init(completion:))` (one call, not N parallel calls)
- Keep `CoordinateSearchServicing` protocol unchanged
- Keep `CoordinateSearchResult` model unchanged
- All existing tests pass unchanged

**Out of scope:**
- Any UI changes to `CoordinateSearchPanel` or `SearchDropdownView`
- Changes to `CoordinateSelectionViewModel` beyond what is needed to support lazy coordinate resolution on selection
- Adding new requirements or features beyond multi-result suggestions

</domain>

<decisions>
## Implementation Decisions

### API Choice
- Use `MKLocalSearchCompleter` for suggestions (returns completions with title + subtitle, NO coordinates)
- Use `MKLocalSearch(request: MKLocalSearch.Request(completion:))` to resolve coordinates ONLY when user selects a result
- Do NOT do N parallel resolution calls (expensive, slow)

### Protocol Contract
- `CoordinateSearchServicing.search(for:near:)` returns `[CoordinateSearchResult]` — LOCKED, unchanged
- `CoordinateSearchResult` has non-optional `coordinate: CoordinateSelection` — LOCKED, unchanged
- `FakeCoordinateSearchService` and `DelayedCoordinateSearchService` in tests — unchanged

### Async Wrapper Strategy
- `MKLocalSearchCompleter` is delegate-based (not async)
- Wrap in `final class` delegate with `withCheckedThrowingContinuation`
- Take FIRST `completerDidUpdateResults` callback (one-shot pattern) — fire continuation immediately, nil out stored continuation, ignore subsequent callbacks
- Handle `completer(_:didFailWithError:)` to resume with throwing

### Coordinate Resolution on Selection
- `CoordinateSelectionViewModel.selectSearchResult(_:)` currently calls `setCoordinate(result.coordinate, ...)` synchronously
- After this phase: if `result.coordinate` is a placeholder (e.g. stored completion), resolve asynchronously first, then `setCoordinate`
- OR: store `MKLocalSearchCompletion` separately in the viewmodel (keyed by result ID) and resolve on demand
- Preferred: store completions map in `CoordinateSelectionViewModel` alongside `searchResults`, resolve on `selectSearchResult`

### Claude's Discretion
- Exact approach for storing completions alongside results (dictionary, tuple, etc.)
- Whether to add a loading state during coordinate resolution
- Error handling if coordinate resolution fails (show alert, ignore, retry)
- Whether to debounce or throttle `completerDidUpdateResults` callbacks
- Region hint: whether to pass the map center as `completer.region` or leave unset

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Implementation (Phase 7)
- `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift` — current `MapKitCoordinateSearchService` to replace
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` — `search()`, `selectSearchResult()`, `searchResults` property
- `GPSMetadataEditor/Features/CoordinateSelection/Views/CoordinateSearchPanel.swift` — `SearchDropdownView` (no changes needed here)
- `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift` — all tests must pass unchanged
- `GPSMetadataEditorTests/CoordinateSearchServiceTests.swift` — `FakeCoordinateSearchService` tests must pass unchanged

### Models
- `GPSMetadataEditor/Features/CoordinateSelection/Models/CoordinateSearchResult.swift` — `Identifiable, Equatable, Sendable`; `coordinate: CoordinateSelection` non-optional; DO NOT change

### Roadmap
- `.planning/ROADMAP.md` — Phase 8 goal and success criteria

</canonical_refs>

<specifics>
## Specific Ideas

- `MKLocalSearchCompleter.queryFragment` is the trigger — set it to start async suggestion fetch
- `MKLocalSearchCompletion` has `.title` (String) and `.subtitle` (String) — map to `CoordinateSearchResult.title` and `.subtitle`
- `MKLocalSearch.Request(completion:)` initializer takes `MKLocalSearchCompletion` directly
- The completer instance must be kept alive during the async wait — store as a property on the delegate class, not a local variable
- Swift concurrency + delegate pattern: delegate class needs `@unchecked Sendable` or `@MainActor` isolation
- Existing debug print `[MapKit] '...' → N items` should be updated to reflect completer result count

</specifics>

<deferred>
## Deferred Ideas

- Showing category icons per result type (like Apple Maps) — out of scope
- Showing recently viewed results at top of list — out of scope (already covered by RecentCoordinatesView)
- Offline/cached search — out of scope

</deferred>
