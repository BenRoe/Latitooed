---
phase: 03-core-metadata-writing
plan: 03-03
subsystem: metadata-writing-ui
tags: [swiftui, observable, batch-writing, testing]
requires:
  - phase: 03-01
    provides: MetadataWriter protocol and result values
  - phase: 03-02
    provides: ExifToolMetadataWriter concrete implementation
provides:
  - root-owned coordinate state bridge
  - Apply Location command with destructive confirmation
  - sequential batch result updates
  - compact batch summary counts
affects: [core-metadata-writing, batch-results, video-history]
tech-stack:
  added: []
  patterns: [root-owned shared view models, non-throwing sequential batch orchestration]
key-files:
  created:
    - GPSMetadataEditorTests/MetadataBatchViewModelTests.swift
  modified:
    - GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift
    - GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift
    - GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionView.swift
    - GPSMetadataEditor.xcodeproj/project.pbxproj
key-decisions:
  - "FileIntakeView owns CoordinateSelectionViewModel so the Apply Location command can read selected files and selected coordinate."
  - "The batch method is non-throwing and continues after per-file failures."
patterns-established:
  - "Batch UI state stays in FileIntakeViewModel and updates immutable SelectedMediaFile snapshots by replacement."
  - "Destructive write confirmation is attached directly to the Apply Location command surface."
requirements-completed: [BATCH-01, BATCH-05, BATCH-06, META-01, META-02, META-05, META-06, META-07]
duration: 31 min
completed: 2026-05-18
---

# Phase 03 Plan 03: Apply Location Batch Flow Summary

**Confirmed Apply Location command that sequentially writes selected coordinates and updates per-file results**

## Performance

- **Duration:** 31 min
- **Started:** 2026-05-18T14:54:00Z
- **Completed:** 2026-05-18T15:25:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Changed `CoordinateSelectionView` to accept an injected `CoordinateSelectionViewModel`.
- Lifted coordinate state into `FileIntakeView` next to the file-intake view model.
- Added a disabled-until-ready `Apply Location` footer command with overwrite/no-restore confirmation copy.
- Added sequential batch orchestration in `FileIntakeViewModel` with per-file result replacement and compact counts.
- Added Swift Testing coverage for command readiness, abort/confirm paths, ordering, result mapping, and summary counts.

## Task Commits

1. **Task 1: Bridge coordinate state into the file intake root** - `b7f25e1` (feat)
2. **Task 2: Add sequential batch orchestration and result updates** - `b7f25e1` (feat)
3. **Task 3: Add Apply Location command and destructive confirmation** - `b7f25e1` (feat)

## Files Created/Modified

- `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` - Apply command, confirmation dialog, coordinate state bridge.
- `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` - Batch readiness, sequential apply method, result replacement, summary counts.
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionView.swift` - Injected coordinate view model.
- `GPSMetadataEditorTests/MetadataBatchViewModelTests.swift` - Batch and confirmation-path tests.
- `GPSMetadataEditor.xcodeproj/project.pbxproj` - Test target membership.

## Decisions Made

- Kept `Task {}` only at the SwiftUI button boundary to enter async work; per-file execution remains a plain awaited `for` loop.
- Used existing footer/status surfaces rather than adding Phase 4 result review or progress surfaces.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `xcodebuild` is unavailable in the VM, so compile/test verification remains host-side.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 3 source implementation is complete. Phase 4 can build on current per-file result state for richer batch results, video metadata behavior, cancellation/progress UI, and history.

## Self-Check: PASSED WITH HOST VERIFICATION PENDING

- Static acceptance checks passed with `rg`.
- `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` could not run because `xcodebuild` is not installed in the VM.

---
*Phase: 03-core-metadata-writing*
*Completed: 2026-05-18*
