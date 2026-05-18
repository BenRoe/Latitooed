---
phase: 03-core-metadata-writing
plan: 03-01
subsystem: metadata-writing
tags: [swift, exiftool, metadata, testing]
requires:
  - phase: 02-coordinate-selection
    provides: CoordinateSelection value used by metadata writer inputs
provides:
  - fakeable async MetadataWriter protocol
  - structured MetadataWriteResult values
  - pure ExifTool GPS argument builder for JPEG and HEIC
affects: [core-metadata-writing, batch-writing, ui-batch-flow]
tech-stack:
  added: []
  patterns: [value-typed metadata writer boundary, pure argument builder tests]
key-files:
  created:
    - GPSMetadataEditor/Features/MetadataWriting/MetadataWriter.swift
    - GPSMetadataEditor/Features/MetadataWriting/MetadataWriteResult.swift
    - GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift
    - GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift
  modified:
    - GPSMetadataEditor.xcodeproj/project.pbxproj
key-decisions:
  - "ExifTool arguments are built as an ordered [String] without shell quoting."
  - "Phase 3 accepts JPEG and HEIC only for write arguments; videos are rejected before launch."
patterns-established:
  - "Metadata writing lives under GPSMetadataEditor/Features/MetadataWriting."
  - "Per-file writer results carry UI status, message, diagnostics, and optional GPS status."
requirements-completed: [BATCH-05, META-01, META-02, META-06, META-07]
duration: 24 min
completed: 2026-05-18
---

# Phase 03 Plan 01: Metadata Writer Contract and GPS Arguments Summary

**Fakeable metadata writer boundary with deterministic ExifTool GPS arguments for destructive JPEG/HEIC writes**

## Performance

- **Duration:** 24 min
- **Started:** 2026-05-18T13:52:00Z
- **Completed:** 2026-05-18T14:16:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `MetadataWriter` as a non-throwing async service protocol.
- Added `MetadataWriteResult` with success, warning, failure, user message, diagnostics, and optional `GPSStatus.updated`.
- Added `ExifToolArgumentBuilder` with exact `-overwrite_original`, `-gpsposition=lat, lon`, and final path argument behavior.
- Added Swift Testing coverage for JPEG, HEIC, signed coordinates, path safety, and video rejection.

## Task Commits

1. **Task 1: Add metadata writer protocol and result values** - `489df0a` (feat)
2. **Task 2: Add ExifTool GPS argument builder** - `489df0a` (feat)

## Files Created/Modified

- `GPSMetadataEditor/Features/MetadataWriting/MetadataWriter.swift` - Async fakeable writer contract.
- `GPSMetadataEditor/Features/MetadataWriting/MetadataWriteResult.swift` - Structured per-file write results.
- `GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift` - Pure JPEG/HEIC argument builder.
- `GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift` - Argument order and path-safety tests.
- `GPSMetadataEditor.xcodeproj/project.pbxproj` - Target membership for new source and test files.

## Decisions Made

- Used `SelectedMediaFile` URL as `fileID`, matching the existing row identity model.
- Kept MOV/MP4 out of the argument builder so video handling remains an explicit warning path in later writer/UI code.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `xcodebuild` is unavailable in the VM, so the requested Xcode test command remains host-side verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The writer contract and argument builder are ready for the bundled ExifTool resolver and concrete writer.

## Self-Check: PASSED WITH HOST VERIFICATION PENDING

- Static acceptance checks passed with `rg`.
- `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` could not run because `xcodebuild` is not installed in the VM.

---
*Phase: 03-core-metadata-writing*
*Completed: 2026-05-18*
