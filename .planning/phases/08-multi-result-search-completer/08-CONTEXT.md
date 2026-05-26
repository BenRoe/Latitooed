# Phase 8: Multi-Result Search Completer — Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 shipped a live search dropdown using `MKLocalSearch`. It works — overlay renders, tests pass, results display — but `MKLocalSearch` returns only 1 result for partial queries (e.g. "leip") because it is a full-text place lookup API, not an autocomplete API.

This phase replaces the search backend with `MKLocalSearchCompleter`, Apple's autocomplete API, which returns 5–10 suggestions for partial queries — matching Apple Maps UX. The dropdown UI from Phase 7 is UNCHANGED. Only the search service and selection flow change.

**In scope:**
- Replace `MKLocalSearch`-based suggestion gathering in `MapKitCoordinateSearchService` with `MKLocalSearchCompleter`
- Wrap delegate-based API in async/await via `withCheckedThrowingContinuation`
- Two-step flow: completer returns title/subtitle completions → on selection, resolve ONE completion to coordinates via `MKLocalSearch(request: .init(completion:))`
- Optimistic dismiss on selection + loading state in ready-status bar during resolution
- Status bar error if resolution fails
- Keep `CoordinateSearchServicing` protocol unchanged
- Keep `CoordinateSearchResult` model unchanged
- All existing tests pass unchanged

**Out of scope:**
- Any UI changes to `CoordinateSearchPanel` or `SearchDropdownView`
- Category icons per result type
- Offline/cached search
- Pre-resolving all suggestions in parallel

</domain>

<decisions>
## Implementation Decisions

### D-01: Resolution Timing — Optimistic Dismiss
After user taps a suggestion, dismiss the dropdown immediately. Resolve coordinates asynchronously in the background. Show a loading indicator in the ready-status bar while resolving (`readyStatusText` → "Resolving location…"). Set coordinate when resolution completes. This matches the Apple Maps feel — no blocking UI.

### D-02: Region Hint — Global (No Region)
Do NOT pass a region to `MKLocalSearchCompleter`. Search globally with no geographic bias. Users tag photos from anywhere in the world — "leip" should return Leipzig regardless of what's visible on the map.

### D-03: Result Count — 8 Results
Cap displayed suggestions at 8: `completer.results.prefix(8)`. Matches Apple Maps density and fits the 240px scroll area without crowding.

### D-04: Resolution Failure — Status Bar Error
If `MKLocalSearch(request: .init(completion:))` fails (network error, no results), show a brief error in the ready-status area: `"Could not load location. Try again."` Clear it after 3 seconds (or when user starts a new search). Coordinate remains unchanged — previously selected coordinate (if any) is preserved.

### Architectural Approach (Claude's Discretion — implement cleanly)
- `MKLocalSearchCompleter` is delegate-based — wrap in a `final class` delegate with `withCheckedThrowingContinuation`. Fire the continuation on first `completerDidUpdateResults` callback (one-shot), nil the stored continuation to ignore subsequent callbacks.
- The delegate class keeps a strong reference to the `MKLocalSearchCompleter` instance to prevent deallocation during async wait.
- The service itself (`MapKitCoordinateSearchService`) returns `[CoordinateSearchResult]` as before — completions map to title/subtitle, coordinate can be a placeholder (e.g., `.berlin`) or the first resolved item's coordinate. The REAL coordinate is resolved later in the ViewModel on selection.
- `CoordinateSelectionViewModel.selectSearchResult(_:)` needs to detect "unresolved" results and trigger async resolution. Store a `[UUID: MKLocalSearchCompletion]` map alongside `searchResults` to enable this.
- Resolution: `MKLocalSearch(request: MKLocalSearch.Request(completion: completion)).start()` → take `response.mapItems.first` → extract coordinate.
- `readyStatusText` in ViewModel should expose a "resolving" state in addition to the existing states.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Implementation to Change
- `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift` — `MapKitCoordinateSearchService` (replace `MKLocalSearch` suggestion path)
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` — `search()`, `selectSearchResult()`, `readyStatusText`, `searchResults`

### Models (DO NOT CHANGE)
- `GPSMetadataEditor/Features/CoordinateSelection/Models/CoordinateSearchResult.swift` — `coordinate: CoordinateSelection` non-optional; model unchanged

### UI (DO NOT CHANGE)
- `GPSMetadataEditor/Features/CoordinateSelection/Views/CoordinateSearchPanel.swift` — `SearchDropdownView` unchanged

### Tests (Must Remain Green)
- `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift`
- `GPSMetadataEditorTests/CoordinateSearchServiceTests.swift`

### Phase 7 Context (Prior Decisions)
- `.planning/phases/07-live-place-search/07-CONTEXT.md` — debounce, clear UX, dropdown behavior all stay

</canonical_refs>

<specifics>
## Specific Ideas

- `MKLocalSearchCompleter.queryFragment = query` triggers suggestion fetch
- `completer.resultTypes` on macOS 26 — check available values; may include `.address`, `.pointsOfInterest`
- `MKLocalSearchCompletion.title` → `CoordinateSearchResult.title`
- `MKLocalSearchCompletion.subtitle` → `CoordinateSearchResult.subtitle` (empty string → nil)
- Swift 6 strict concurrency: delegate class likely needs `@MainActor` or `@unchecked Sendable`
- `MKLocalSearch.Request(completion:)` initializer available on macOS 10.15+ — confirmed safe
- The `[Search] '...' → N items` debug print in the service should be updated to show completer result count

</specifics>

<deferred>
## Deferred Ideas

- Category icons per result type (Apple Maps shows airport icon, coffee cup, etc.) — future phase
- Recently searched completions pinned at top — already covered by `RecentCoordinatesView`
- Showing a "searching…" skeleton while completions load — complexity not worth it; completer is fast

</deferred>
