---
phase: 03-core-metadata-writing
plan: 03-02
subsystem: metadata-writing
tags: [swift, exiftool, process, concurrency, testing]
requires:
  - phase: 03-01
    provides: MetadataWriter protocol, MetadataWriteResult, ExifToolArgumentBuilder
provides:
  - bundle-only ExifTool resolver
  - async Process runner seam
  - concrete ExifToolMetadataWriter
  - bundled ExifTool 13.58 helper resource
affects: [core-metadata-writing, batch-writing, packaging]
tech-stack:
  added: [ExifTool 13.58 bundled helper]
  patterns: [bundle-only helper resolution, fake process runner tests]
key-files:
  created:
    - GPSMetadataEditor/Features/MetadataWriting/BundledExifToolResolver.swift
    - GPSMetadataEditor/Features/MetadataWriting/ProcessRunner.swift
    - GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift
    - GPSMetadataEditor/Resources/ExifTool/exiftool
    - GPSMetadataEditor/Resources/ExifTool/lib/
    - GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift
    - GPSMetadataEditorTests/ProcessRunnerTests.swift
  modified:
    - GPSMetadataEditor.xcodeproj/project.pbxproj
key-decisions:
  - "The resolver only checks Bundle.main resources and never falls back to Homebrew, PATH, or system locations."
  - "Normal unit tests use fake ProcessRunning seams and do not launch real ExifTool."
patterns-established:
  - "Subprocess code is isolated behind ProcessRunning."
  - "ExifToolMetadataWriter maps helper/process outcomes into MetadataWriteResult instead of throwing through UI code."
requirements-completed: [BATCH-05, BATCH-06, META-01, META-02, META-05, META-06, META-07]
duration: 38 min
completed: 2026-05-18
---

# Phase 03 Plan 02: Bundled ExifTool Writer Summary

**Bundle-only ExifTool writer with async process execution, still-image result mapping, and video warning behavior**

## Performance

- **Duration:** 38 min
- **Started:** 2026-05-18T14:16:00Z
- **Completed:** 2026-05-18T14:54:00Z
- **Tasks:** 3
- **Files modified:** 260

## Accomplishments

- Added a `BundledExifToolResolver` that resolves `ExifTool/exiftool` from `Bundle.main` and checks executable permission.
- Added `FoundationProcessRunner` using `Process.executableURL`, `Process.arguments`, stdout/stderr pipes, termination handler, and cancellation termination.
- Added `ExifToolMetadataWriter` for JPEG/HEIC success/failure mapping and MOV/MP4 deferred warnings.
- Bundled the official ExifTool 13.58 script and runtime library, trimmed to runtime files needed by the helper.

## Task Commits

1. **Task 1: Add bundled ExifTool resolver and resource membership** - `b91bd64` (feat)
2. **Task 2: Add async Process runner** - `b91bd64` (feat)
3. **Task 3: Add concrete ExifTool metadata writer** - `b91bd64` (feat)

## Files Created/Modified

- `GPSMetadataEditor/Features/MetadataWriting/BundledExifToolResolver.swift` - Bundle-only helper lookup and executable check.
- `GPSMetadataEditor/Features/MetadataWriting/ProcessRunner.swift` - Async process execution seam and Foundation implementation.
- `GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift` - Concrete metadata writer and result mapper.
- `GPSMetadataEditor/Resources/ExifTool/` - Bundled ExifTool 13.58 runtime.
- `GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift` - Fake-runner writer mapping tests.
- `GPSMetadataEditorTests/ProcessRunnerTests.swift` - Process launch failure test.
- `GPSMetadataEditor.xcodeproj/project.pbxproj` - Source/test/resource target membership.

## Decisions Made

- Trimmed the upstream ExifTool distribution to the executable, README, and `lib/` runtime tree after confirming `exiftool -ver` still reports `13.58`.
- Kept concrete writer tests fake-runner based; real JPEG/HEIC sample writes remain host-side smoke verification.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `xcodebuild` is unavailable in the VM, so compile/test verification remains host-side.
- The official ExifTool tarball initially unpacked docs and upstream tests; those task-added files were removed before amending the production commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The metadata writer can now be injected into the file-intake batch flow for destructive confirmation and selected-file result updates.

## Self-Check: PASSED WITH HOST VERIFICATION PENDING

- Static acceptance checks passed with `rg`.
- Bundled helper smoke check passed: `GPSMetadataEditor/Resources/ExifTool/exiftool -ver` returned `13.58`.
- `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` could not run because `xcodebuild` is not installed in the VM.

---
*Phase: 03-core-metadata-writing*
*Completed: 2026-05-18*
