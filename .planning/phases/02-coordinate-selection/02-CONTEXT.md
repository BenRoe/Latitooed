# Phase 2: Coordinate Selection - Context

**Gathered:** 2026-05-17T20:32:27+02:00
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 replaces the quiet right-side location placeholder with a working MapKit coordinate picker. Users can search for a place, select a search result, click the map to choose an exact coordinate, switch map presentation, manually enter latitude and longitude, and see the selected coordinate before later batch-writing phases use it. This phase does not write metadata, persist recent coordinates, or add app preferences beyond what is needed for coordinate selection.

</domain>

<decisions>
## Implementation Decisions

### Search Result Flow
- **D-01:** Search results appear as a compact inline list below the search field in the right-side coordinate panel.
- **D-02:** Selecting a search result sets latitude and longitude and moves the map target; Phase 2 does not need to store or display extra place metadata.
- **D-03:** Search runs only after an explicit user action, such as pressing Return or clicking a Search button.
- **D-04:** Empty, no-result, and search-error states appear as quiet inline status text in the results area.

### Map Click and Target Marker
- **D-05:** Clicking anywhere on the map sets the target coordinate.
- **D-06:** The selected map target is shown with a pin only. Do not add an extra coordinate card on the map.
- **D-07:** Clicking the map collapses search results while preserving the current query text.
- **D-08:** When no coordinate has been selected, the map defaults to Berlin and shows no fake target pin.

### Manual Coordinate Entry
- **D-09:** Valid manual latitude and longitude edits update the target pin and map immediately.
- **D-10:** Invalid latitude or longitude values remain editable, show inline validation, and do not update the selected target until valid.
- **D-11:** Coordinates are displayed at 6 decimal places.
- **D-12:** Manual coordinate entry becomes the active source and hides old search results.

### Map Style Controls and Panel Layout
- **D-13:** Map style controls should use small icon overlays on the map in the style of macOS Maps, not a segmented control.
- **D-14:** Coordinate fields live above the map near search.
- **D-15:** Use a dense pro layout with minimal labels and as much map space as practical.
- **D-16:** Show selected-coordinate readiness with a small status row near the controls, e.g. the target latitude and longitude.

### the agent's Discretion
- Planner may choose the exact SwiftUI view decomposition, MapKit camera defaults, icon choices, and control spacing as long as they preserve the dense pro layout and the decisions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope
- `.planning/PROJECT.md` — Defines the product, native macOS direction, self-contained workflow, and v1 constraints.
- `.planning/REQUIREMENTS.md` — Defines Phase 2 requirements LOC-01 through LOC-06 and their traceability.
- `.planning/ROADMAP.md` — Defines Phase 2 goal, success criteria, and implementation notes.
- `.planning/STATE.md` — Captures current project focus and carried-forward decisions.

### Prior Phase Decisions
- `.planning/phases/01-app-shell-and-file-intake/01-CONTEXT.md` — Locks the split layout and reserves the right side for the Phase 2 coordinate/map area.
- `.planning/phases/01-app-shell-and-file-intake/01-UI-SPEC.md` — Locks the native SwiftUI utility layout, drop-zone-first file intake, and quiet right-side placeholder that Phase 2 replaces.

No external specs or ADRs were referenced during discussion.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` — Current root view uses `HSplitView`, keeps file intake in the left column, and renders `ReservedLocationPanel()` in the right column. Phase 2 should replace that placeholder with the coordinate selection surface.
- `GPSMetadataEditor/Features/FileIntake/Views/ReservedLocationPanel.swift` — Existing placeholder confirms the right panel is reserved for location selection.
- `GPSMetadataEditor/Support/AppDesign.swift` — Existing spacing, radius, and layout constants should be reused where they fit the new panel.
- `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` — Shows the established `@Observable @MainActor` view-model pattern for shared UI state.

### Established Patterns
- The app already uses feature folders under `GPSMetadataEditor/Features/`.
- SwiftUI views are extracted into focused `View` structs instead of computed view properties.
- Shared mutable UI state is owned by `@State` view models and passed into child views through bindings or bindable models.
- User-facing warnings/status stay quiet and inline unless a stronger interruption is required.

### Integration Points
- Phase 2 should add a coordinate-selection feature area and connect it to the existing right side of `FileIntakeView`.
- The bottom footer may remain general app status; coordinate readiness should be visible near the coordinate controls in the right panel.
- Later metadata-writing phases need a selected-coordinate value they can consume, but Phase 2 does not need to implement batch write integration.

</code_context>

<specifics>
## Specific Ideas

- The right panel should feel closer to a pro utility than a guided wizard.
- Map controls should resemble the small overlay icon controls in the macOS Maps app.
- Berlin is the default starting map region before the user selects a coordinate.

</specifics>

<deferred>
## Deferred Ideas

- User-editable default map location setting. This is a preference capability and belongs outside Phase 2.

</deferred>

---

*Phase: 2-Coordinate Selection*
*Context gathered: 2026-05-17T20:32:27+02:00*
