# Phase 6: Loaded Files Grid View - Context

**Gathered:** 2026-05-24T10:29:48Z
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 6 adds a native macOS SwiftUI grid view for files already loaded into the app. The grid is an alternate visual review surface for the same selected-file data used by the existing table. It must preserve the existing table/list workflow, batch actions, warnings, and result review behavior while making loaded media easier to browse visually.

</domain>

<decisions>
## Implementation Decisions

### View Switch Behavior
- **D-01:** Add a segmented Table/Grid control for switching the loaded-files review surface.
- **D-02:** Grid mode should be the default when files are loaded.
- **D-03:** Remember the selected mode for the current app/window session only. Do not add cross-launch preference persistence in this phase.
- **D-04:** Place the segmented control in the Selected Files header beside the file count so it clearly controls only the loaded-files surface.
- **D-05:** Keep the existing drop-zone-only empty state until files are loaded; do not show an empty grid or disabled segmented control before it is useful.

### Grid Cell Design
- **D-06:** Grid cells should be thumbnail-first cards.
- **D-07:** Each card must show filename, file type, GPS status, and latest result so grid mode remains functionally equivalent to the table's core review columns.
- **D-08:** Non-image files and thumbnail failures should use a first-class file-type fallback icon rather than blank or filename-only placeholders.
- **D-09:** Use medium-density cards: enough room for a thumbnail or fallback plus compact metadata/status lines, without becoming a large preview gallery.
- **D-10:** Warning, failure, success, and pending states should appear as compact status badges using color plus icon and text, not color alone.

### Selection Model
- **D-11:** Grid mode must mirror table multi-selection through the shared `selectedFileIDs` set.
- **D-12:** Plain-clicking a grid card should replace selection with that card.
- **D-13:** Command-click should toggle grid-card selection, and Shift-click should range-select when it can be implemented cleanly.
- **D-14:** When multiple files are selected, the detail panel should show a selection summary rather than the first selected file's detail.
- **D-15:** The grid must not break the existing SwiftUI `Table` multi-selection behavior or reintroduce per-cell gesture conflicts in `SelectedFilesTable`.

### Scale and Edge States
- **D-16:** Use a vertically scrolling adaptive grid with a stable medium card width.
- **D-17:** Thumbnail generation is best-effort in this phase. The grid must remain useful with fallback icons, and planning should avoid turning this into a robust media-preview pipeline phase.
- **D-18:** The grid should remain usable for small and large batches without disrupting file selection, warning visibility, the selected-file detail/result area, batch history, or Apply Location.

### the agent's Discretion
- Planner may choose exact type names, segmented-control implementation details, thumbnail loading mechanism, adaptive card width, and the precise selection helper structure, as long as the decisions above and existing SwiftUI architecture are preserved.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and Phase Scope
- `.planning/ROADMAP.md` - Phase 6 goal, requirements, success criteria, and dependency on Phase 5.
- `.planning/PROJECT.md` - Product goal, active requirements, and native macOS SwiftUI constraints.
- `.planning/REQUIREMENTS.md` - Existing file-intake, batch-result, metadata, and packaging requirements that grid mode must not regress.
- `.planning/STATE.md` - Current project state and carried-forward decisions.

### Prior Decisions
- `.planning/phases/04-batch-results-video-and-history/04-CONTEXT.md` - Locks the current selected-files table as the existing result surface, selected-row detail behavior, batch history placement, and compact result messaging.
- `docs/swiftui-table-selection-behavior.md` - Documents the native SwiftUI table multi-selection behavior and the requirement to avoid cell-level gesture hacks that interfere with selection.

### Current File Intake Code
- `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` - Integrates the selected-files surface, detail panel, batch history, coordinate panel, and footer actions.
- `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesTable.swift` - Existing table review surface and table-selection normalizer.
- `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` - Owns `selectedFiles`, `selectedFileIDs`, selected-file detail derivation, batch progress, result replacement, and notices.
- `GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift` - Immutable file snapshot fields available to grid cards.
- `GPSMetadataEditor/Features/FileIntake/Views/FileDetailPanel.swift` - Existing selected-file detail and diagnostics surface that needs multi-selection summary behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FileIntakeViewModel.selectedFiles` - Existing source of truth for loaded files; grid should render this array rather than maintaining separate file state.
- `FileIntakeViewModel.selectedFileIDs` - Existing set-backed selection model; grid should share this binding with the table.
- `SelectedMediaFile` - Provides URL, display name, containing folder, media kind, GPS status, latest result, latest message, and diagnostics fields for grid-card content.
- `FileResultStatus`, `GPSStatus`, and `MediaFileKind` - Existing status/type models for card badges and fallback icon selection.
- `FileDetailPanel` - Existing detail/diagnostics surface; needs to support a multi-selection summary when more than one grid/table item is selected.

### Established Patterns
- Shared UI state lives in `@Observable @MainActor` view models owned by SwiftUI `@State`.
- The table uses `Binding<Set<SelectedMediaFile.ID>>` for native macOS multi-selection.
- Phase 4 kept result diagnostics in the existing selected-file detail panel rather than adding a separate results drawer.
- Batch history is already placed below the selected-file detail/result area in the left column; grid work should not displace it without a planning reason.
- SwiftUI grid documentation supports `LazyVGrid` with `GridItem(.adaptive(...))` for vertically scrolling adaptive grids; this matches the selected scale decision.

### Integration Points
- `FileIntakeView` Selected Files header - Add the segmented Table/Grid control beside the count.
- `FileIntakeView` selected-files content area - Switch between `SelectedFilesTable` and the new grid view after files are loaded.
- `FileIntakeViewModel` - Add session-only selected view-mode state and any derived multi-selection summary needed by `FileDetailPanel`.
- `SelectedFilesTable` - Preserve current table behavior; do not move selection hacks into table cells.
- New grid view file under `GPSMetadataEditor/Features/FileIntake/Views/` - Likely home for the card grid and card subviews, following current feature-view organization.

</code_context>

<specifics>
## Specific Ideas

- The Table/Grid control should read as a local control for the selected-files surface, not a global navigation control.
- Grid cards should be visually useful even for MOV/MP4 files and thumbnail failures by showing file-type fallback icons as intentional states.
- Multi-selection summary copy can be concise, for example: `4 files selected`, with aggregate counts by type/result if planning finds that useful without expanding scope.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope.

</deferred>

---

*Phase: 6-Loaded Files Grid View*
*Context gathered: 2026-05-24T10:29:48Z*
