---
phase: 01-app-shell-and-file-intake
plan: 01-02
subsystem: file-intake
tags: [swift, swift-testing, macos, file-access, uttype]
requires:
  - phase: 01-app-shell-and-file-intake
    provides: macOS SwiftUI app and Swift Testing target from plan 01-01
provides:
  - URL-preserving selected media file snapshots
  - supported media file kind, GPS status, result status, warning, and intake result value types
  - file intake classifier with resource-value validation, UTType classification, extension fallback, and duplicate rejection
  - Swift Testing coverage for model defaults, supported extensions, URL preservation, warnings, duplicates, and filesystem rejection cases
affects: [01-app-shell-and-file-intake, picker-wiring, drag-drop, batch-results]
tech-stack:
  added: [UniformTypeIdentifiers]
  patterns: [Swift value snapshots, URL identity, resource-value validation, balanced security-scoped access, Swift Testing service coverage]
key-files:
  created:
    - GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift
    - GPSMetadataEditor/Features/FileIntake/Models/MediaFileKind.swift
    - GPSMetadataEditor/Features/FileIntake/Models/GPSStatus.swift
    - GPSMetadataEditor/Features/FileIntake/Models/FileResultStatus.swift
    - GPSMetadataEditor/Features/FileIntake/Models/IntakeWarning.swift
    - GPSMetadataEditor/Features/FileIntake/Models/FileIntakeResult.swift
    - GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift
    - GPSMetadataEditorTests/FileIntakeServiceTests.swift
  modified:
    - GPSMetadataEditor.xcodeproj/project.pbxproj
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
key-decisions:
  - "Used `URL` as the stable selected-file identity so duplicate checks and snapshots preserve file URL fidelity."
  - "Classified files with resource `contentType`/UTType first, then lowercased extension fallback, without deep content sniffing."
  - "Kept intake classification synchronous and value-based because Phase 1 only performs lightweight resource-value reads."
patterns-established:
  - "File intake services return `FileIntakeResult` with accepted snapshots and warning records instead of mutating UI state directly."
  - "Security-scoped resource access is started and stopped in the same classification scope."
requirements-completed: [FILE-03, FILE-04, FILE-05]
duration: 6min
completed: 2026-05-15
---

# Phase 1 Plan 01-02: File Intake Domain and Classification Summary

**URL-preserving file intake snapshots with resource-value validation and warning generation for rejected media files**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-15T21:51:53Z
- **Completed:** 2026-05-15T21:57:22Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added file-intake value types for selected media snapshots, media kind, GPS status, file result status, warnings, and intake results.
- Implemented `FileIntakeService` to reject duplicate, unsupported, directory, missing, inaccessible, read-only, and locked inputs before table insertion.
- Added Swift Testing coverage for supported mixed-case extensions, default snapshot states, warning reasons, URL preservation with spaces/Unicode, duplicate handling, and deterministic filesystem warnings.

## Task Commits

1. **Task 1: Define selected-file and warning value types** - `93994fd` (feat)
2. **Task 2: Implement URL intake classification** - `85b8338` (feat)

## Files Created/Modified

- `GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift` - Immutable selected-file snapshot using URL identity and honest default GPS/result states.
- `GPSMetadataEditor/Features/FileIntake/Models/MediaFileKind.swift` - JPEG, HEIC, MOV, and MP4 classification via UTType or case-insensitive extension.
- `GPSMetadataEditor/Features/FileIntake/Models/GPSStatus.swift` - Phase 1 GPS status values with `notChecked` default.
- `GPSMetadataEditor/Features/FileIntake/Models/FileResultStatus.swift` - Pending, success, warning, and failure result values.
- `GPSMetadataEditor/Features/FileIntake/Models/IntakeWarning.swift` - Warning reasons and user-facing messages for rejected intake inputs.
- `GPSMetadataEditor/Features/FileIntake/Models/FileIntakeResult.swift` - Accepted snapshot plus warning result container.
- `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift` - URL intake classification and validation service.
- `GPSMetadataEditorTests/FileIntakeServiceTests.swift` - Swift Testing coverage for the model and classifier contract.
- `GPSMetadataEditor.xcodeproj/project.pbxproj` - Added new source and test files to the app/test targets.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` - Advanced plan progress and marked plan requirements complete.

## Decisions Made

- Used `URL` directly for `SelectedMediaFile.id` and duplicate tracking instead of path strings.
- Checked resource values before extension fallback so directories, missing files, locked files, and read-only files are rejected before accepted rows are created.
- Kept the classifier synchronous and free of unstructured tasks because the work is limited to deterministic local resource metadata reads.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `xcodebuild` is not installed in this execution environment, so RED/GREEN and final automated test commands could not run here. The command attempted was `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test`, and it exited with `zsh:1: command not found: xcodebuild`.
- `plutil` is also unavailable in this environment, so project-file linting could not be run.

## Verification

- **TDD RED attempts:** The intended tests were written before implementation, but the RED command could not compile because `xcodebuild` is unavailable.
- **Required automated command:** Not run to completion because `xcodebuild` is unavailable.
- **Source checks passed:** New model/service symbols are referenced from the app target project file.
- **Source checks passed:** No `DispatchQueue`, `Task.detached`, unstructured `Task {}`, `@unchecked Sendable`, `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, `foregroundColor`, `cornerRadius`, `onTapGesture`, or C-style `String(format:)` patterns were introduced.
- **Whitespace check passed:** `git diff --check` reported no whitespace errors.

## Known Stubs

None.

## Threat Flags

None. The file-access trust boundary and required mitigations were already listed in the plan threat model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The intake domain layer is ready for the next Phase 1 plan to wire picker and drag/drop events into `FileIntakeService` and render accepted files plus latest warnings in the existing shell.

## Self-Check: PASSED

- Created files exist in the working tree.
- Task commits `93994fd` and `85b8338` exist in git history.
- No tracked file deletions were introduced by either task commit.

---
*Phase: 01-app-shell-and-file-intake*
*Completed: 2026-05-15*
