# Phase 2: Coordinate Selection - Research

**Researched:** 2026-05-17T20:45:00+02:00
**Status:** Ready for UI design contract, then planning

## Research Question

What does the planner need to know to implement Phase 2: Coordinate Selection well?

Phase 2 must replace the reserved right-side placeholder with a native MapKit coordinate picker. It must cover LOC-01 through LOC-06: explicit MapKit place search, result selection, map-click coordinate selection, map style switching, manual latitude/longitude entry, and visible selected coordinate readiness.

## Sources Checked

- Apple Developer Documentation: MapKit for SwiftUI — https://developer.apple.com/documentation/mapkit/mapkit_for_swiftui
- Apple Developer Documentation: `MapReader` — https://developer.apple.com/documentation/mapkit/mapreader
- Apple Developer Documentation: `MapProxy.convert(_:from:)` — https://developer.apple.com/documentation/mapkit/mapproxy/4282659-convert
- Apple Developer Documentation: `MKLocalSearch` — https://developer.apple.com/documentation/mapkit/mklocalsearch
- Apple Developer Documentation: `MKLocalSearchCompleter` — https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter
- Apple Developer Documentation: `MKLocalSearchCompletion` — https://developer.apple.com/documentation/mapkit/mklocalsearchcompletion
- Apple sample doc: Interacting with nearby points of interest — https://developer.apple.com/documentation/MapKit/interacting-with-nearby-points-of-interest
- Project context: `.planning/phases/02-coordinate-selection/02-CONTEXT.md`
- Prior UI contract: `.planning/phases/01-app-shell-and-file-intake/01-UI-SPEC.md`
- Existing code: `GPSMetadataEditor/Features/FileIntake/*`, `GPSMetadataEditor/Support/AppDesign.swift`

## Key Findings

### MapKit Search

- `MKLocalSearch` is the right fit for explicit user-triggered searches. It accepts a request and returns `MKMapItem` results.
- Apple docs and sample code show `MKLocalSearch.start()` can be called with `async`/`await`, which matches the project's Swift concurrency rules.
- `MKLocalSearchCompleter` is useful for autocomplete while typing, but the user explicitly chose explicit search only. Do not build a live completion UI in Phase 2.
- Planner should include cancellation of any active search task/search object when a new explicit search starts or when the view model resets state.
- Search should be scoped by the visible map region when practical so a query like "museum" biases toward the current map area.

### Map Click Coordinate Selection

- SwiftUI `MapReader` exposes a `MapProxy` that can convert a click point in a coordinate space into `CLLocationCoordinate2D`.
- This supports the selected behavior: clicking anywhere on the map sets the target coordinate.
- Use a `Marker` for the selected target. The context explicitly rejects an additional map coordinate card.
- Map click should collapse search results while preserving the query text.

### Map Camera and Default Region

- The no-selection initial camera should center on Berlin with no fake pin.
- Selecting a search result or valid manual coordinate should update the selected coordinate and move the map camera to that coordinate.
- Keep camera state in a `@MainActor @Observable` view model rather than embedding camera mutation logic in SwiftUI body code.

### Map Style Controls

- MapKit for SwiftUI supports map styles, including standard and imagery/satellite-style presentation.
- Phase 2 must offer standard, satellite/imagery, and hybrid-style modes.
- The user wants macOS Maps-style small icon overlays on the map, not a segmented control. Planner should treat these as labeled buttons with icon-only visual style, preserving accessibility labels.

### Manual Coordinate Entry

- Project guidance says manual latitude/longitude entry should use formatted numeric bindings instead of string parsing in view bodies.
- The user chose live valid edits: valid numbers update the selected coordinate and map immediately.
- Invalid values must remain editable, show inline validation, and not update the target until valid.
- Coordinates display at 6 decimal places.
- Because a directly formatted `Double` binding can make invalid intermediate text awkward, the planner should split logic carefully:
  - preserve the user-facing requirement for editable invalid values;
  - keep parsing/validation out of view bodies;
  - use a small coordinate-entry model/value type or view-model methods to validate range and publish field state.

### Existing Code Patterns

- The current root view is `FileIntakeView`, with an `HSplitView`, file intake on the left, and `ReservedLocationPanel()` on the right.
- Phase 2 should replace `ReservedLocationPanel()` with a coordinate selection view, likely under `GPSMetadataEditor/Features/CoordinateSelection/`.
- Existing app state uses `@Observable @MainActor` view models owned by `@State`; follow this for `CoordinateSelectionViewModel`.
- Existing design constants live in `AppDesign`. Reuse spacing/radius/layout constants where appropriate and add narrowly scoped constants only if the coordinate panel needs them.
- Existing tests use Swift Testing under `GPSMetadataEditorTests`. Add focused unit tests for coordinate validation and view-model state transitions.
- The `.xcodeproj` currently has explicit file references and build-phase entries. Any new Swift source/test files must be added to the project file unless the implementer changes project structure deliberately.

## Recommended Planning Shape

Use a small number of vertical MVP plans:

1. Coordinate domain and validation state
   - Add `CoordinateSelectionViewModel`.
   - Add selected-coordinate value type and map style enum if needed.
   - Add unit tests for valid/invalid coordinate entry, 6-decimal display, Berlin default, source switching, and search-result collapse behavior.

2. Map/search service behavior
   - Add a MapKit search service/protocol that runs explicit `MKLocalSearch` requests.
   - Keep search state cancellable and testable.
   - Return lightweight search results with display title/subtitle and coordinate only.

3. SwiftUI right-panel integration
   - Replace `ReservedLocationPanel` in `FileIntakeView`.
   - Add search field, inline result list/status, coordinate fields, ready status row, map with marker, map click handling, and map-style overlay buttons.
   - Maintain dense pro layout and avoid large instructional copy.

This can be one wave if implemented by one executor sequentially, or two waves if the model/service plan precedes the UI integration plan.

## Risks and Mitigations

- **MapKit API availability drift:** Verify exact SwiftUI Map APIs in Xcode on host before marking implementation complete. The VM can edit files but cannot fully verify MapKit UI.
- **Manual numeric input edge cases:** Formatted numeric fields can fight invalid intermediate text. Keep validation logic in the view model and test invalid ranges explicitly.
- **Search cancellation:** Avoid detached/unstructured tasks. Keep one active search task or search object and cancel before starting a replacement.
- **Project file churn:** Adding many new files requires careful `.xcodeproj` updates. Plans should list exact new files and verify target membership.
- **Accessibility for icon overlays:** Icon-only visual buttons still need text labels, tooltips/help, and accessible names.

## Validation Guidance

Automated checks:

- Unit tests for coordinate validation:
  - latitude accepts `-90...90`
  - longitude accepts `-180...180`
  - invalid values do not replace selected coordinate
  - 6-decimal display formatting
- Unit tests for view-model behavior:
  - initial map region is Berlin and selected coordinate is nil
  - selecting a search result sets coordinate and collapses results
  - clicking map sets coordinate and collapses results while preserving query
  - manual valid edit sets coordinate and collapses results
  - explicit search updates inline result/status state

Manual/host checks:

- Build and test with Xcode or host-side `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test`.
- Launch app on macOS host and verify MapKit renders nonblank, map clicks set a pin, search returns results, and style overlay controls switch presentation.

## Open Items for Planning

- Phase 2 needs a UI design contract (`02-UI-SPEC.md`) before plan creation because the phase is UI-heavy and the project config enables the UI safety gate.
- Planner should not add the deferred user-editable default map location setting. Berlin is the fixed Phase 2 default.

## RESEARCH COMPLETE
