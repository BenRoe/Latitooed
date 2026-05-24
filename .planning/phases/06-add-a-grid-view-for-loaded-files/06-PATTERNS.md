# Phase 6: Loaded Files Grid View - Pattern Map

**Generated:** 2026-05-24
**Status:** Ready for planning
**UI-SPEC:** Skipped by explicit user request for this run

## Files Likely To Be Created Or Modified

| Planned File | Role | Closest Existing Analog | Notes |
|--------------|------|-------------------------|-------|
| `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` | Session-only view mode, shared selection helpers, selected-file review state | Existing file | Keep `@Observable @MainActor`; do not introduce persistence. |
| `GPSMetadataEditor/Features/FileIntake/Views/FileDetailPanel.swift` | Single-file detail and multi-selection summary | Existing file | Preserve warning/failure diagnostics for single selection. |
| `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` | Header segmented control and table/grid switch | Existing file | Keep `HSplitView`, drop zone, detail panel, batch history, and footer actions. |
| `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesGrid.swift` | New grid review surface and card subviews | `SelectedFilesTable.swift`, `FileDetailPanel.swift`, `WarningSummaryView.swift` | Use native SwiftUI grid APIs and existing value/status models. |
| `GPSMetadataEditor.xcodeproj/project.pbxproj` | Explicit Xcode file membership | Existing project file | Add `SelectedFilesGrid.swift` to FileIntake Views group and app target sources. |
| `GPSMetadataEditorTests/FileIntakeViewModelTests.swift` | State and selection tests | Existing file | Extend current Swift Testing suite with `@MainActor`, `#expect`, and `#require`. |
| `GPSMetadataEditorTests/FileIntakeSmokeTests.swift` | Lightweight construction/source-level smoke | Existing file | Add minimal view construction checks if useful; avoid UI tests unless unit tests cannot cover behavior. |

## Existing Patterns To Reuse

### Main-Actor Observable State

`FileIntakeViewModel` is `@Observable @MainActor` and already owns file intake state, selection, latest warnings, metadata batch progress, and notices. Phase 6 state should stay there: a small loaded-files view mode and selection-review derivation are UI state, not persistence state.

### Set-Backed Selection

`SelectedFilesTable` binds `Table(files, selection: $selection)` to `Set<SelectedMediaFile.ID>`. The grid should reuse the same `selectedFileIDs` set so table and grid selection stay in sync.

### Plain-Click Normalization Outside Table Cells

`SelectedFilesTable` uses an AppKit-side local event monitor to collapse plain-click selection after native table handling. Phase 6 must leave this behavior alone. Grid-specific click handling belongs inside the new grid/card implementation, not inside table cells.

### Immutable File Snapshots

`SelectedMediaFile` is a `Hashable`, `Sendable` value containing URL, display name, containing folder, media kind, GPS status, latest result, latest message, and diagnostic detail. Cards should render these snapshots directly.

### Compact Result Surfaces

`FileDetailPanel` already shows selected-file detail and warning/failure diagnostics. Phase 6 should extend this panel to support no selection, one file, and multiple files rather than adding a new result drawer.

### Explicit Xcode Project Membership

The project uses explicit PBX groups and source build-file entries. New Swift app files must be added to `GPSMetadataEditor.xcodeproj/project.pbxproj`.

## Landmines

- Do not add SwiftData or cross-launch persistence for Table/Grid mode.
- Do not introduce `@Query`, `@Model`, `ModelContext`, or SwiftData schema changes; `swiftdata-pro` applies here as a guardrail against unnecessary persistence.
- Do not create a grid-only selected-file source of truth.
- Do not remove, replace, or weaken `SelectedFilesTable`.
- Do not add per-cell gestures to the existing table.
- Do not make thumbnails a blocking media-preview pipeline; fallback icons must be enough.
- Do not add third-party UI, image-loading, or selection libraries.
- Do not persist thumbnails, file URLs, bookmarks, display-name lists, media contents, or per-file result history.
- Do not use fixed font sizes, `foregroundColor`, `.cornerRadius`, `AnyView`, or UIKit colors in new SwiftUI code.

## Pattern Mapping Complete

Plans should reference this file, `06-CONTEXT.md`, `06-RESEARCH.md`, `docs/swiftui-table-selection-behavior.md`, and the Swift specialist skills before implementation. The closest implementation analogs are `FileIntakeViewModel`, `SelectedFilesTable`, `FileDetailPanel`, and the existing Swift Testing view-model tests.
