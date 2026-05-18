# Phase 4: Batch Results, Video, and History - Pattern Map

**Generated:** 2026-05-18
**Status:** Ready for planning

## Files Likely To Be Created Or Modified

| Planned File | Role | Closest Existing Analog | Notes |
|--------------|------|-------------------------|-------|
| `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` | Batch progress and row result state | Existing file | Extend the current sequential loop; do not add cancellation UI/state. |
| `GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift` | Immutable row snapshot | Existing file | Add optional diagnostic detail if detail panel needs selected-row diagnostics. |
| `GPSMetadataEditor/Features/FileIntake/Views/FileDetailPanel.swift` | Selected-row message/diagnostics | Existing file | Use compact disclosure only for warning/failure diagnostics. |
| `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` | Root layout/footer/history placement | Existing file | Preserve `HSplitView`; add history below detail and pass progress into footer. |
| `GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift` | ExifTool tag argument selection | Existing file | Replace MOV/MP4 unsupported branch with `-Keys:GPSCoordinates=<lat>, <lon>`. |
| `GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift` | Writer behavior mapping | Existing file | Route MOV/MP4 through same process path and success/warning/failure mapping. |
| `GPSMetadataEditor/Features/BatchHistory/Models/RecentCoordinate.swift` | SwiftData recent coordinate record | New model | Store label, latitude, longitude, last-used timestamp only. |
| `GPSMetadataEditor/Features/BatchHistory/Models/BatchRunSummary.swift` | SwiftData compact batch summary | New model | Store timestamp, coordinate label/value, total, success, warning, failure counts only. |
| `GPSMetadataEditor/Features/BatchHistory/Services/BatchHistoryStore.swift` | Explicit SwiftData save/prune boundary | New service | Keep `ModelContext` on the main actor and save after correctness-sensitive writes. |
| `GPSMetadataEditor/Features/BatchHistory/Views/RecentCoordinatesView.swift` | Coordinate reuse UI | `CoordinateSearchPanel.swift` / `CoordinateFieldsView.swift` | Compact native SwiftUI rows near search/manual controls. |
| `GPSMetadataEditor/Features/BatchHistory/Views/BatchHistorySection.swift` | Batch history UI | `FileDetailPanel.swift` / `WarningSummaryView.swift` | Counts-only history below detail panel; no file restore affordance. |
| `GPSMetadataEditor/GPSMetadataEditorApp.swift` | App persistence container | Existing file | Add SwiftData model container for Phase 4 models. |
| `GPSMetadataEditor.xcodeproj/project.pbxproj` | File membership | Existing explicit project file | Add new source/test files to correct groups and targets. |
| `GPSMetadataEditorTests/*Tests.swift` | Swift Testing coverage | Existing test files | Prefer unit tests with fake writers/process runners and in-memory SwiftData containers. |

## Existing Patterns To Reuse

### Main-Actor Observable State

`FileIntakeViewModel` and `CoordinateSelectionViewModel` are `@Observable @MainActor` classes owned by SwiftUI `@State`. Phase 4 should keep UI state on those models and use `@Bindable` or explicit closures in child views.

### Sequential Batch Loop

`FileIntakeViewModel.applyMetadata(coordinate:writer:)` already snapshots `selectedFiles`, awaits one writer call per file, and replaces the row after the result returns. Add progress state before each awaited write and clear it in `defer`; do not add per-file tasks.

### Value Row Replacement

`SelectedMediaFile` is an immutable `Sendable` value. Preserve the replacement pattern when carrying `latestDiagnosticDetail` or equivalent row detail.

### Existing Result Surface

`SelectedFilesTable` is the primary result surface and `FileDetailPanel` is the selected-row review surface. Phase 4 should not create a drawer, report modal, or restore surface.

### Fakeable Service Boundaries

`MetadataWriter`, `ProcessRunning`, and `CoordinateSearchServicing` are testable seams. Keep video and batch-history tests behind fakes or in-memory containers rather than real helper writes in unit tests.

### Project File Membership

The project uses explicit PBX groups, not file-system-synchronized groups. Any new app or test file must be added to `GPSMetadataEditor.xcodeproj/project.pbxproj`.

## Landmines

- `BATCH-02` is superseded by `04-CONTEXT.md`; do not plan a Cancel button, `cancelBatch()`, cancelled row state, or future cancellation copy.
- Do not persist URLs, bookmarks, display-name arrays, diagnostic logs, media contents, thumbnails, or per-file result records in SwiftData.
- Do not pass SwiftData `@Model` instances or `ModelContext` across actor boundaries; pass values or persistent identifiers.
- Do not rely on SwiftData autosave for recent-coordinate or batch-summary writes; call `try modelContext.save()`.
- Do not write video metadata with an unqualified `GPSCoordinates` tag; Phase 4 research chose `Keys:GPSCoordinates`.
- Do not show raw ExifTool diagnostics on success rows.
- Do not replace the selected-files table or bottom-left detail panel with a new result UI.
- Do not call ExifTool through shell strings or PATH lookup.

## Pattern Mapping Complete

Plans should reference this file, `04-CONTEXT.md`, `04-RESEARCH.md`, and `04-UI-SPEC.md` before implementation. The closest implementation analogs are the current file-intake view-model loop, the coordinate-selection view-model injection pattern, the existing metadata writer seam, and Swift Testing tests with fakes.
