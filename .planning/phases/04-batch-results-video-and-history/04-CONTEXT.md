# Phase 4: Batch Results, Video, and History - Context

**Gathered:** 2026-05-18T22:26:45+02:00
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 makes the existing sequential batch write workflow more transparent, adds best-effort MOV/MP4 metadata writing, and persists recent coordinates plus compact batch summaries. The phase should improve daily-use visibility through footer progress, existing result surfaces, recent coordinate reuse, and batch history, while staying within the established native macOS utility layout.

Important scope change: active batch cancellation is intentionally removed from Phase 4 and should not be deferred as future work. Downstream planning must not implement a Cancel button or cancellation state even though earlier requirements listed BATCH-02.

</domain>

<decisions>
## Implementation Decisions

### Batch Progress Without Cancellation
- **D-01:** Do not add active cancellation in Phase 4.
- **D-02:** Do not defer cancellation as future work; treat cancellation as intentionally dropped from the product scope for now.
- **D-03:** Do not add a Cancel button, cancellation command, or cancelled file state.
- **D-04:** Rows should update only after each file completes, preserving the current selected-files table as the result surface.
- **D-05:** While the sequential batch is running, the footer should show the currently writing filename and count.
- **D-06:** Footer progress copy should be filename-first, for example: `Writing IMG_2042.HEIC (3 of 12)`.

### Result Review Depth
- **D-07:** Keep the existing selected-files table as the primary result surface after a batch.
- **D-08:** Selecting a row should show that file's result message in the existing bottom-left detail panel.
- **D-09:** Warning and failure rows may expose collapsed technical diagnostics when diagnostic detail exists.
- **D-10:** Success rows should stay quiet and should not expose technical diagnostics.
- **D-11:** Completed batch summaries should remain counts-only, for example: `9 updated, 2 warnings, 1 failed.`

### Video Best-Effort Behavior
- **D-12:** Do not hard-code the exact MOV/MP4 ExifTool tag set in this context. Phase 4 research must choose the minimal tag set for best-effort QuickTime-compatible location writes.
- **D-13:** If ExifTool exits cleanly for a MOV or MP4 write, show success with the same user-facing success message style as images, such as `GPS metadata updated.`
- **D-14:** Do not add extra compatibility caveats to successful video rows.
- **D-15:** MOV/MP4 rows should show warnings or failures only when the helper reports warnings or failures.
- **D-16:** MOV and MP4 should share the same user-facing behavior and copy by default.
- **D-17:** Research and planning may split MOV and MP4 arguments or result handling if ExifTool behavior differs by container.

### Recent Coordinates and Batch History
- **D-18:** Recent coordinates should appear in the coordinate panel near the existing search/manual controls.
- **D-19:** Recent coordinate labels should use the selected place name when available, otherwise formatted coordinates.
- **D-20:** Custom naming and pinned favorites are out of scope for Phase 4.
- **D-21:** Recent batch runs should appear in a dedicated compact history section below the selected-file detail/result area.
- **D-22:** Each batch history entry should show timestamp, coordinate label, total file count, and success/warning/failure counts.
- **D-23:** Selecting a batch history entry should support reusing that run's coordinate in the coordinate panel.
- **D-24:** Selecting a batch history entry must not restore previous files or previous per-file results into the active table.
- **D-25:** SwiftData should persist recent coordinate records and compact batch summaries only: coordinate label/value, timestamp, total file count, and success/warning/failure counts.
- **D-26:** SwiftData must not persist media contents, per-file result history, file bookmark data, or enough information to reconnect prior files in Phase 4.
- **D-27:** Correctness-sensitive SwiftData writes must be explicitly saved rather than relying on autosave timing.

### the agent's Discretion
- Planner may choose the exact SwiftData model type names, fetch/query boundaries, retention count for recent coordinates/history, and view decomposition, as long as the decisions above and existing SwiftUI architecture are preserved.
- Planner may choose the exact collapsed diagnostic disclosure UI in the detail panel.
- Researcher and planner must decide the exact MOV/MP4 ExifTool arguments from current ExifTool documentation and behavior, not from this context alone.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope
- `.planning/PROJECT.md` - Defines the native macOS app, bundled ExifTool direction, best-effort video constraint, and persistence/privacy boundaries.
- `.planning/REQUIREMENTS.md` - Defines Phase 4 requirements BATCH-02, BATCH-03, BATCH-04, META-03, META-04, PERSIST-01, PERSIST-02, PERSIST-03, and PERSIST-04. Note that BATCH-02 is superseded by D-01 through D-03 in this context.
- `.planning/ROADMAP.md` - Defines Phase 4 goal, success criteria, and implementation notes. Note that the cancellation success criterion is superseded by D-01 through D-03 in this context.
- `.planning/STATE.md` - Captures carried-forward decisions, completed Phase 3 status, and current phase focus.

### Prior Phase Decisions
- `.planning/phases/01-app-shell-and-file-intake/01-CONTEXT.md` - Establishes selected-file table, detail panel, footer/status area, supported file kinds, and layout constraints.
- `.planning/phases/02-coordinate-selection/02-CONTEXT.md` - Establishes coordinate panel behavior, selected coordinate display, and manual/search/map coordinate selection decisions.
- `.planning/phases/03-core-metadata-writing/03-CONTEXT.md` - Establishes bundled ExifTool, destructive overwrite confirmation, sequential write path, structured per-file results, and Phase 4 deferred boundaries.

### Source Files to Inspect
- `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` - Current root view, footer apply command, overwrite confirmation, and split layout.
- `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` - Current sequential batch loop, row replacement, summary counts, and `isMetadataBatchRunning` state.
- `GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift` - Immutable selected-file snapshot and current row result fields.
- `GPSMetadataEditor/Features/MetadataWriting/MetadataWriter.swift` - Current metadata writer protocol boundary.
- `GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift` - Current JPEG/HEIC writer and video-deferred warning behavior.
- `GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift` - Current still-image argument builder and video unsupported branch.
- `GPSMetadataEditor/Features/MetadataWriting/ProcessRunner.swift` - Current process runner and cancellation handler; planning should account for the decision to not expose user cancellation in Phase 4.
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` - Source of selected coordinate and search result context for recent-coordinate persistence.
- `GPSMetadataEditor/Features/CoordinateSelection/Models/CoordinateSelection.swift` - Coordinate value, validation, sendability, and display formatting.

### Local Follow-Up Docs
- `docs/swift-default-mainactor-nonisolated-values.md` - Documents Swift actor-isolation lessons from Phase 3 that may affect Sendable value models and services.
- `docs/swiftui-table-selection-behavior.md` - Documents table-selection behavior relevant to row result/detail interactions.
- `docs/host-xcodebuild-verification-boundary.md` - Documents host-vs-VM verification limits for Xcode builds and app smoke checks.

No external specs or ADRs were referenced during discussion.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FileIntakeViewModel.applyMetadata(coordinate:writer:)` already runs selected files sequentially, replaces rows with `MetadataWriteResult`, sets `isMetadataBatchRunning`, and produces a counts summary.
- `FileIntakeViewModel.MetadataBatchSummary` already has success/warning/failure counts and a counts-only message.
- `SelectedMediaFile` already carries `latestResult` and `latestMessage` for row/detail result display.
- `MetadataWriteResult` already carries `diagnosticDetail`, which can feed collapsed warning/failure diagnostics.
- `FoundationProcessRunner` already terminates the child process on task cancellation, but Phase 4 should not expose user cancellation controls.
- `ExifToolMetadataWriter` already routes MOV/MP4 to a Phase 4 warning, giving a narrow replacement point for video write attempts.
- `CoordinateSelectionViewModel` and `CoordinateSelection` already hold the selected coordinate and validated display values needed for recent coordinate persistence.

### Established Patterns
- Feature code is grouped under `GPSMetadataEditor/Features/<FeatureName>/`.
- Shared UI state uses `@Observable @MainActor` view models owned by `@State`.
- SwiftUI views are extracted into focused `View` structs rather than large computed properties.
- User-facing warnings and status messages stay quiet and inline unless destructive overwrite confirmation is required.
- Tests use Swift Testing with focused service/view-model coverage.

### Integration Points
- Progress copy belongs in the existing footer rather than a new progress panel.
- Result diagnostics belong in the existing selected-file detail panel rather than a new results drawer.
- Batch history should fit below the selected-file detail/result area in the left column.
- Recent coordinates should connect to the coordinate panel so selecting a recent coordinate updates the same selected-coordinate state used by Apply Location.
- SwiftData should be introduced at the app/persistence boundary without crossing actor boundaries with model instances; services should use value snapshots or persistent identifiers where needed.

</code_context>

<specifics>
## Specific Ideas

- In-progress footer copy should use the filename-first pattern: `Writing IMG_2042.HEIC (3 of 12)`.
- Completed footer copy should stay counts-only: `9 updated, 2 warnings, 1 failed.`
- Video success copy can match image success copy: `GPS metadata updated.`
- A history row can read like: `Today 14:32 - Berlin - 12 files - 9 updated, 2 warnings, 1 failed.`

</specifics>

<deferred>
## Deferred Ideas

- None. Cancellation was explicitly dropped from scope and should not be treated as a deferred future feature.

</deferred>

---

*Phase: 4-Batch Results, Video, and History*
*Context gathered: 2026-05-18T22:26:45+02:00*
