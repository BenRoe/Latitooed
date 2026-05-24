# Phase 6: Loaded Files Grid View - Research

## RESEARCH COMPLETE

Phase 6 should add a second loaded-files review surface, not a new file-intake model. The lowest-risk shape is a session-only view-mode value on `FileIntakeViewModel`, a segmented `Picker` in the existing Selected Files header, and a new SwiftUI grid view that renders `selectedFiles` while binding to the existing `selectedFileIDs` set. This preserves the completed table workflow and lets the grid reuse current status models, result messages, detail panel, footer actions, batch history, and metadata-writing state. [VERIFIED: `.planning/phases/06-add-a-grid-view-for-loaded-files/06-CONTEXT.md`] [VERIFIED: `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift`] [VERIFIED: `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift`]

## Source Findings

- `FileIntakeView` already has the right integration point: the Selected Files header contains the title, count, and current table immediately below. Add the segmented Table/Grid control beside the count only when files exist, then switch the loaded-files content area between `SelectedFilesTable` and the new grid. [VERIFIED: `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift`]
- `FileIntakeViewModel` already owns `selectedFiles` and `selectedFileIDs`, and exposes `selectFile(id:)` plus `selectFiles(ids:)`. The grid should call those APIs or bind through the same set rather than keeping separate grid selection state. [VERIFIED: `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift`]
- `selectedFileDetail` currently returns the first selected file in table order. Phase 6 decision D-14 requires a multi-selection summary instead, so planning should replace the single optional detail shape with a review state enum or add a separate `selectedFileReview` value that can represent no selection, one file, and multiple files. [VERIFIED: `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift`] [VERIFIED: `.planning/phases/06-add-a-grid-view-for-loaded-files/06-CONTEXT.md`]
- `SelectedFilesTable` uses SwiftUI `Table(files, selection: $selection)` plus an AppKit-side `TableSelectionNormalizer` to make plain clicks collapse selection while leaving Command/Shift clicks to native table behavior. Grid work must not add per-cell gestures to this table or disturb that normalizer. [VERIFIED: `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesTable.swift`] [VERIFIED: `docs/swiftui-table-selection-behavior.md`]
- `SelectedMediaFile`, `MediaFileKind`, `GPSStatus`, and `FileResultStatus` are small `Sendable` value types with display names. They are sufficient for filename, kind, GPS, result, fallback icon, and badge content. [VERIFIED: `GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift`] [VERIFIED: `GPSMetadataEditor/Features/FileIntake/Models/MediaFileKind.swift`] [VERIFIED: `GPSMetadataEditor/Features/FileIntake/Models/GPSStatus.swift`] [VERIFIED: `GPSMetadataEditor/Features/FileIntake/Models/FileResultStatus.swift`]
- Tests already use Swift Testing with `@MainActor` view-model suites, `#expect`, and `#require`. Phase 6 should extend `FileIntakeViewModelTests` for view-mode defaults, selection behavior, and multi-selection summary rather than adding UI tests first. [VERIFIED: `GPSMetadataEditorTests/FileIntakeViewModelTests.swift`] [VERIFIED: `GPSMetadataEditorTests/FileIntakeSmokeTests.swift`]

## Framework Notes

- Apple SwiftUI docs exposed through Context7 show `LazyVGrid` used inside a vertical `ScrollView` and `GridItem` for column layout. That supports the phase decision to use a vertically scrolling adaptive grid. [CITED: Apple SwiftUI `LazyVGrid` docs via Context7, https://developer.apple.com/documentation/swiftui/lazyvgrid]
- Apple SwiftUI docs exposed through Context7 show `.pickerStyle(.segmented)` for segmented `Picker` presentation, with segmented style intended for small option counts. This fits the two-option Table/Grid control. [CITED: Apple SwiftUI `Picker` and `SegmentedPickerStyle` docs via Context7, https://developer.apple.com/documentation/swiftui/picker]
- Context7 did not return Apple Image I/O docs for thumbnail generation; the ImageIO lookup matched the Python ImageIO library. Planning should therefore avoid relying on unverified Image I/O specifics and keep thumbnails best-effort with a fallback-first contract. [VERIFIED: Context7 lookup result]
- Apple Swift Testing docs exposed through Context7 confirm `#expect` for expected values and `#require` when a failed condition should stop the test. This matches the existing test style and should be used for new Phase 6 view-model tests. [CITED: Apple Swift Testing docs via Context7, https://developer.apple.com/documentation/testing/expectations]

## Swift Specialist Guidance

- SwiftUI: keep the grid as real `View` structs under `GPSMetadataEditor/Features/FileIntake/Views/`; do not split view bodies into computed properties. Use `foregroundStyle()`, `clipShape(.rect(cornerSize:))`, `Button` for card activation, text labels with SF Symbols for status badges, Dynamic Type text styles, and accessibility labels that include status text rather than color-only meaning. [CITED: `.agents/skills/swiftui-pro/SKILL.md`]
- Swift concurrency: avoid unstructured thumbnail-loading task sprawl in the first plan. If thumbnail generation is added, isolate it behind a small async service with cancellation-aware calls and value outputs; do not introduce `@unchecked Sendable` or GCD. For Phase 6, it is acceptable to start with fallback icons and add best-effort thumbnails as a bounded follow-up task. [CITED: `.agents/skills/swift-concurrency-pro/SKILL.md`]
- Swift Testing: write focused Swift Testing coverage for state transitions and selection derivation. Prefer deterministic value tests over screenshot/UI tests for this phase; use `#require` for optional review state extraction and `#expect` for state assertions. [CITED: `.agents/skills/swift-testing-pro/SKILL.md`]

## Planning Implications

- Plan 1 should establish the view-mode and review-state model: `LoadedFilesViewMode` or equivalent, default grid mode once files are loaded, session-only state, selected-file review enum, and tests proving table/grid mode and multi-selection summary behavior.
- Plan 2 should add the grid UI: a new `SelectedFilesGrid` and card subviews, segmented control in the header, adaptive `LazyVGrid`, fallback icons for non-image/thumbnail failure states, compact type/GPS/result badges, and selection actions that update the shared `selectedFileIDs`.
- Plan 3 should harden interaction and verification: Command-click toggle, plain-click replace, Shift-click range-select if clean from the ordered `selectedFiles` array, accessibility labels/help for long filenames, source checks that `SelectedFilesTable` remains untouched except for shared model needs, and host-side UI smoke steps.
- Keep MVP mode vertical: each plan should leave the app runnable and preserve current file intake, detail, batch history, and Apply Location behavior. Do not create a standalone gallery, persistent preference, thumbnail cache, file URL store, or third-party UI dependency.

## Risks And Non-Goals

- Risk: gestures in grid cards can conflict with button semantics or keyboard accessibility. Prefer `Button` for plain card activation and limit modifier-specific event handling to the smallest selection helper needed for Command/Shift behavior.
- Risk: adding thumbnail generation can balloon into a media pipeline. Treat thumbnails as optional best-effort presentation; fallback icons must be first-class and sufficient for Phase 6 success.
- Risk: multi-selection summary can accidentally remove single-file diagnostics. The detail panel should explicitly handle no selection, one file, and multiple files while preserving warning/failure diagnostic disclosure for one selected file.
- Non-goal: no cross-launch persistence for table/grid mode.
- Non-goal: no SwiftData schema changes, thumbnail persistence, previous-file restoration, or batch-history redesign.
- Non-goal: no third-party grid, image-loading, or UI framework.

## Verification Strategy

- VM/source checks: run focused `rg` checks for `LazyVGrid`, `.pickerStyle(.segmented)`, the new view-mode type, new multi-selection review state, no new SwiftData model, no third-party framework import, and no table cell `onTapGesture`.
- Unit tests: extend `FileIntakeViewModelTests` for grid-default/session-only mode, selecting one file, selecting multiple files, clearing stale selection when files are removed, and summary counts by status/type if implemented.
- Host checks: run `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test`, then launch the app on macOS, load JPEG/HEIC/MOV/MP4 files, confirm grid is default after loading, switch Table/Grid, verify table multi-select still works, verify grid plain-click and Command-click selection, and verify Apply Location remains available when a coordinate is selected.

