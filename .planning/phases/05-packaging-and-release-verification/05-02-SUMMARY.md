---
phase: 05-packaging-and-release-verification
plan: 05-02
subsystem: testing
tags: [swift-testing, exiftool, packaging, no-fallback]

requires:
  - phase: 03-core-metadata-writing
    provides: bundled ExifTool resolver, metadata writer, process runner, and argument builder
provides:
  - Bundle-local resolver assertions that reject Homebrew, system, and env helper paths
  - Still-image process-runner failure coverage for structured metadata write failures
  - Argument-builder assertions that reject executable, shell, env, and PATH tokens
affects: [packaging, release-verification, metadata-writing]

tech-stack:
  added: []
  patterns: [Swift Testing service-level coverage with injected process runner fakes]

key-files:
  created: []
  modified:
    - GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift
    - GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift

key-decisions:
  - "Kept Phase 5 no-fallback proof in focused tests instead of changing production metadata-writing architecture."
  - "Kept process-launch failure coverage behind the injected ProcessRunning fake rather than launching a missing executable."

patterns-established:
  - "Resolver tests assert bundle-local helper paths and reject Homebrew/system/env fallback paths."
  - "Argument-builder tests assert metadata arguments remain data-only and never include executable or shell lookup tokens."

requirements-completed: [PKG-02, PKG-03]

duration: 28min
completed: 2026-05-22T15:46:00Z
---

# Phase 05: No-Fallback and Helper Failure Tests Summary

**Bundle-only ExifTool resolution and argument construction now have explicit Swift Testing coverage against Homebrew, system, shell, env, and PATH fallback paths.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-05-22T15:18:00Z
- **Completed:** 2026-05-22T15:46:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Added resolver assertions that the helper path ends in `/ExifTool/exiftool` and does not point at Homebrew, `/usr/local/bin`, `/usr/bin`, or `/usr/bin/env`.
- Changed process-runner throw coverage to use a JPEG still-image path while preserving the user-facing failure message and diagnostic detail checks.
- Added argument-builder assertions that JPEG, HEIC, MOV, and MP4 metadata arguments do not include executable names, Homebrew paths, shell paths, env lookup, or `PATH`.

## Task Commits

1. **Task 1: Add explicit no-PATH resolver and writer assertions** - `a4359c9` (test)
2. **Task 2: Confirm process launch failure maps to clear metadata failure** - `a4359c9` (test)
3. **Task 3: Keep GPS write arguments independent of shell and PATH** - `d87bf79` (test)

## Files Created/Modified

- `GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift` - Strengthens bundle-only resolver checks and still-image runner failure coverage.
- `GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift` - Adds reusable assertions that argument arrays do not contain executable, shell, env, Homebrew, or PATH lookup tokens.

## Decisions Made

- No production metadata-writing code changed because the existing resolver, writer, process runner, and argument builder already followed the bundle-only architecture.
- The runner-throw test was narrowed to a JPEG still-image file to match Phase 5 helper-failure criteria without adding brittle real-process launch behavior to unit tests.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; changes stay limited to the test files listed in the plan.

## Issues Encountered

- `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` could not run in this VM because `xcodebuild` is not installed. Host-side Xcode test execution remains required.

## Verification

- `rg -n "/opt/homebrew|/usr/local|/usr/bin/env|ProcessInfo\\.processInfo\\.environment|PATH" GPSMetadataEditor/Features/MetadataWriting/BundledExifToolResolver.swift GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift` returned no matches.
- `rg -n "stillImageRunnerThrowMapsToStructuredFailure|GPS metadata could not be written|Fake runner failed|/ExifTool/exiftool|/opt/homebrew|/usr/local/bin|/usr/bin/env" GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift` confirmed the required writer assertions.
- `rg -n "argumentsContainForbiddenExecutableTokens|/opt/homebrew/bin/exiftool|/usr/local/bin/exiftool|/bin/sh|zsh|/usr/bin/env|PATH" GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift` confirmed the required argument-builder assertions.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05-02 source changes are ready for host test verification. Phase 5 cannot continue past Wave 1 until Plan 05-01 receives a valid HEIC fixture and produces its release-smoke fixture/script/doc outputs.

## Self-Check: PASSED

Source acceptance criteria passed in the VM. Host `xcodebuild test` remains a manual verification step because this VM does not provide Xcode.

---
*Phase: 05-packaging-and-release-verification*
*Completed: 2026-05-22*
