---
phase: 04-batch-results-video-and-history
plan: 04-04
subsystem: persistence
tags: [swiftdata, batch-history, swiftui]
requires:
  - phase: 04-batch-results-video-and-history
    provides: recent-coordinate store from plan 04-03 and diagnostics/progress from plan 04-01
provides:
  - compact SwiftData batch summary model
  - post-write batch history recording
  - left-column Recent Batches section with coordinate reuse
affects: [phase-04, file-intake, batch-history, coordinate-selection]
tech-stack:
  added: []
  patterns:
    - counts-only durable batch summaries
    - post-write persistence that does not rerun metadata writes
key-files:
  created:
    - GPSMetadataEditor/Features/BatchHistory/Models/BatchRunSummary.swift
    - GPSMetadataEditor/Features/BatchHistory/Views/BatchHistorySection.swift
    - .planning/phases/04-batch-results-video-and-history/04-04-SUMMARY.md
  modified:
    - GPSMetadataEditor/GPSMetadataEditorApp.swift
    - GPSMetadataEditor/Features/BatchHistory/Services/BatchHistoryStore.swift
    - GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionView.swift
    - GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift
    - GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift
    - GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift
    - GPSMetadataEditorTests/BatchHistoryStoreTests.swift
    - GPSMetadataEditorTests/MetadataBatchViewModelTests.swift
    - GPSMetadataEditor.xcodeproj/project.pbxproj
key-decisions:
  - "Batch history persists timestamp, coordinate label/value, total file count, and success/warning/failure counts only."
  - "History coordinate reuse updates the active coordinate state without restoring previous files or per-file results."
  - "Persistence failures after a batch are non-blocking warnings and do not rerun metadata writes."
patterns-established:
  - "Batch summary persistence prunes to 10 entries after insert."
  - "History rows use `Use Coordinate` rather than restore/reopen actions."
requirements-completed:
  - PERSIST-02
  - PERSIST-03
  - PERSIST-04
  - BATCH-04
duration: 5 min
completed: 2026-05-19
---

# Phase 04 Plan 04: Compact Batch History Summary

**Counts-only batch history with coordinate reuse and no previous-file restore surface**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-19T10:19:00Z
- **Completed:** 2026-05-19T10:23:50Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added `BatchRunSummary` as a compact SwiftData model with timestamp, coordinate label/value, total count, and result counts only.
- Extended `BatchHistoryStore` to record batch summaries, update recent coordinates, prune summaries to 10, and explicitly save mutations.
- Wired `FileIntakeView` to record history after metadata writes complete and to report persistence failures as non-blocking warnings.
- Added `BatchHistorySection` below the file detail panel with counts-only rows and `Use Coordinate` reuse.
- Added tests for compact summary fields, batch recording, pruning, and coordinate reuse without changing selected files.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add compact batch-summary SwiftData model** - `141b504` (feat)
2. **Task 2: Record recent coordinate and batch summary after completion** - `18beaa4` (feat)
3. **Task 3: Render compact recent batch history below details** - `385054d` (feat)

**Plan metadata:** this docs commit.

## Files Created/Modified

- `GPSMetadataEditor/Features/BatchHistory/Models/BatchRunSummary.swift` - Compact counts-only batch summary model.
- `GPSMetadataEditor/Features/BatchHistory/Services/BatchHistoryStore.swift` - Batch summary recording, snapshots, and pruning.
- `GPSMetadataEditor/Features/BatchHistory/Views/BatchHistorySection.swift` - Left-column history section and coordinate reuse action.
- `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` - Post-batch persistence hook and history section placement.
- `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` - Non-blocking history persistence failure notice.
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` - Batch summary coordinate reuse path.
- `GPSMetadataEditor/GPSMetadataEditorApp.swift` - App model container includes both history models.
- `GPSMetadataEditorTests/BatchHistoryStoreTests.swift` - In-memory SwiftData coverage.
- `GPSMetadataEditorTests/MetadataBatchViewModelTests.swift` - Coordinate reuse without selected-file restore coverage.
- `GPSMetadataEditor.xcodeproj/project.pbxproj` - Project membership for new files.

## Decisions Made

- Kept history rows informational and counts-only; there are no filenames, file paths, diagnostics, thumbnails, restore, or reopen affordances.
- Reused the active coordinate state for history coordinate reuse, matching recent-coordinate behavior from 04-03.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep.

## Issues Encountered

- `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` could not run in this VM because `xcodebuild` is unavailable.
- Focused host UI smoke for Recent Batches remains pending.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 4 source work is complete. Host-side Xcode tests and focused UI smoke checks should verify the SwiftData model container, recent-coordinate rendering, batch-history rendering, MOV/MP4 write behavior, and no restore/cancellation affordances.

---
*Phase: 04-batch-results-video-and-history*
*Completed: 2026-05-19*
