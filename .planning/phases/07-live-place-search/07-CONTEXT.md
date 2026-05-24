# Phase 7: Live Place Search - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the existing submit-gated MapKit search (Enter key / Search button) with live-as-you-type search. Results appear in a floating dropdown anchored below the search field. No new search capabilities are added — this phase upgrades the interaction model of the existing `CoordinateSearchPanel` + `CoordinateSelectionViewModel`.

</domain>

<decisions>
## Implementation Decisions

### Search Trigger
- **D-01:** Remove the Search button entirely. No explicit submit affordance — typing drives search exclusively.
- **D-02:** Remove `performSearchOnSubmit` / `onSubmit` handler from `CoordinateSearchPanel`.

### Results Presentation
- **D-03:** Show results in a floating dropdown overlay anchored below the search field (not inline expanding panel). Map remains visible while browsing results.
- **D-04:** Use SwiftUI `.overlay` or popover — do not push layout content down.

### Debounce Behavior
- **D-05:** Minimum 3 characters before any search fires. Below threshold: cancel any in-flight task, clear results, dismiss dropdown silently.
- **D-06:** 500 ms debounce on last keystroke before firing `MKLocalSearch`.
- **D-07:** Existing `searchGeneration` guard and `activeSearchTask?.cancel()` pattern must remain — new `onChange` path must respect it.

### Clear / Cancel UX
- **D-08:** X clear button appears inside the search field when text is non-empty. Tapping clears field, cancels in-flight task, dismisses dropdown.
- **D-09:** Escape key also clears field and dismisses dropdown.
- **D-10:** On result selection: keep query text in the field (user can see what they selected), dismiss dropdown. Coordinate updates as before.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Search Implementation
- `GPSMetadataEditor/Features/CoordinateSelection/Views/CoordinateSearchPanel.swift` — current UI to be replaced
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` — search state machine, `searchGeneration`, `activeSearchTask`
- `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift` — `MapKitCoordinateSearchService`, already has `Task.checkCancellation()`
- `GPSMetadataEditor/Features/CoordinateSelection/Models/CoordinateSearchResult.swift` — result model, unchanged

### Tests to Preserve / Extend
- `GPSMetadataEditorTests/CoordinateSearchServiceTests.swift` — service tests, must remain green
- `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift` — ViewModel tests; debounce behavior may need new cases

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `searchGeneration` + `activeSearchTask` in `CoordinateSelectionViewModel`: already handles task cancellation on superseded searches — wire `onChange` into this same path.
- `CoordinateSearchResult` model: no changes needed.
- `CoordinateSearchResultRow` private view in `CoordinateSearchPanel`: reuse as-is inside the new dropdown.

### Established Patterns
- `@Bindable var viewModel` pattern in views — keep.
- `AppDesign.Spacing` / `AppDesign.Radius` — use for dropdown styling to stay consistent.
- `.regularMaterial` background used in existing results panel — carry into dropdown.

### Integration Points
- `CoordinateSearchPanel` is used inside `CoordinateSelectionView` — the overlay/dropdown must not break that layout.
- `viewModel.selectSearchResult(_:)` is the existing selection handler — call it unchanged on tap.
- `viewModel.collapseSearchResults()` exists and sets `isSearchResultsExpanded = false` — reuse or replace with new dismiss signal.

</code_context>

<specifics>
## Specific Ideas

- Apple Maps desktop is the reference UX: live results, floating list, X clear button, no submit button.
- Debounce: 3 chars / 500 ms — more conservative than Apple Maps defaults, intentional to reduce MapKit call rate.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 7-Live Place Search*
*Context gathered: 2026-05-25*
