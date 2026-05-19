---
phase: 04-batch-results-video-and-history
plan: 04-02
subsystem: metadata-writing
tags: [exiftool, mov, mp4, quicktime, gps]
requires:
  - phase: 03-core-metadata-writing
    provides: bundled ExifTool resolver, argument-array writer, and structured metadata results
provides:
  - QuickTime Keys GPS arguments for MOV and MP4
  - MOV/MP4 routing through the bundled ExifTool process path
  - still-image-style success and failure result mapping for video writes
affects: [phase-04, metadata-writing, file-intake]
tech-stack:
  added: []
  patterns:
    - separate ExifTool arguments for every flag and file path
    - one shared metadata write path for supported media kinds
key-files:
  created:
    - .planning/phases/04-batch-results-video-and-history/04-02-SUMMARY.md
  modified:
    - GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift
    - GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift
    - GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift
    - GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift
key-decisions:
  - "MOV and MP4 use `-Keys:GPSCoordinates=<lat>, <lon>` as the minimal researched QuickTime-compatible tag target."
  - "Clean video helper exits use the same `GPS metadata updated.` success copy as still images."
  - "No system ExifTool fallback, shell command, or video compatibility caveat copy was added."
patterns-established:
  - "ExifToolArgumentBuilder owns per-kind tag selection while preserving argument-array safety."
  - "ExifToolMetadataWriter routes every supported kind through one process runner path."
requirements-completed:
  - META-03
  - META-04
duration: 4 min
completed: 2026-05-19
---

# Phase 04 Plan 02: Best-Effort Video GPS Writes Summary

**MOV and MP4 GPS writes through bundled ExifTool using QuickTime Keys coordinates**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-19T10:08:00Z
- **Completed:** 2026-05-19T10:11:54Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Replaced the MOV/MP4 unsupported argument branch with `-Keys:GPSCoordinates=<latitude>, <longitude>`.
- Updated tests to prove MOV and MP4 share the same QuickTime Keys strategy and preserve unsafe-looking paths as a single final argument.
- Removed the Phase 3 video-deferred writer branch so MOV and MP4 invoke the injected process runner.
- Added video success, nonzero-exit failure, and thrown-runner failure tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add QuickTime Keys GPS arguments for MOV and MP4** - `576d98b` (feat)
2. **Task 2: Route MOV and MP4 through the writer process path** - `a26a01f` (feat)

**Plan metadata:** this docs commit.

## Files Created/Modified

- `GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift` - Added MOV/MP4 QuickTime Keys GPS arguments.
- `GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift` - Routed all supported media kinds through the shared process path.
- `GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift` - Replaced video unsupported tests with Keys GPS argument tests.
- `GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift` - Replaced deferred-warning tests with video write result mapping tests.

## Decisions Made

- Used `Keys:GPSCoordinates` instead of unqualified GPS coordinates to match Phase 4 research and Apple-style QuickTime location metadata.
- Kept clean video exits visually identical to image successes; warnings/failures are helper-derived only.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep.

## Issues Encountered

- `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` could not run in this VM because `xcodebuild` is unavailable.
- Host smoke testing with sample MOV/MP4 files remains pending.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 04-03 can add recent-coordinate persistence and reuse. Video results now flow through the same structured result path and diagnostic detail surface completed in 04-01.

---
*Phase: 04-batch-results-video-and-history*
*Completed: 2026-05-19*
