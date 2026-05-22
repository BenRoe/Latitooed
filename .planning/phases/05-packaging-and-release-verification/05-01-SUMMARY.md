---
phase: 05-packaging-and-release-verification
plan: 05-01
subsystem: packaging
tags: [release-verification, exiftool, codesign, fixtures]

requires:
  - phase: 03-core-metadata-writing
    provides: bundled ExifTool resource and bundle-only metadata writer
provides:
  - JPEG and HEIC release-smoke fixtures
  - Static packaged-app verification script for bundled helper and codesign evidence
  - Initial release verification documentation with VM and host boundaries
affects: [packaging, release-verification, human-uat]

tech-stack:
  added: []
  patterns: [host-side signed app verification script, copied-fixture smoke inputs]

key-files:
  created:
    - GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.jpg
    - GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.heic
    - scripts/verify-packaged-app.sh
    - docs/release-verification.md
  modified: []

key-decisions:
  - "Use committed nonsensitive JPEG and HEIC fixtures as immutable release-smoke inputs."
  - "Verify the helper by explicit app-bundle path instead of relying on shell PATH or Homebrew."
  - "Keep Phase 5 scoped to signed .app verification; notarization and DMG/ZIP remain deferred."

patterns-established:
  - "Package verification scripts accept a built .app path and resolve helper resources inside Contents/Resources."
  - "Release smoke writes should copy committed fixtures before mutation."

requirements-completed: [PKG-01, PKG-04]

duration: 32min
completed: 2026-05-22T19:13:00Z
---

# Phase 05: Package Evidence and Fixtures Summary

**Release-smoke fixtures, a bundled-helper package verifier, and initial release verification docs now prepare signed `.app` verification without external ExifTool fallback.**

## Performance

- **Duration:** 32 min
- **Started:** 2026-05-22T18:41:00Z
- **Completed:** 2026-05-22T19:13:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added valid `sample.jpg` and `sample.heic` release-smoke fixtures under `GPSMetadataEditorTests/Fixtures/ReleaseSmoke/`.
- Added `scripts/verify-packaged-app.sh`, which checks a built `GPSMetadataEditor.app` for the bundled helper path, executable bit, helper version, and codesign evidence.
- Added `docs/release-verification.md` with the Phase 5 signed `.app` scope, VM checks, host test command, build artifact path setup, and static package checks.

## Task Commits

1. **Task 1: Add small JPEG and HEIC release-smoke fixtures** - `9c6530e` (test)
2. **Task 2: Add static packaged-app verification script** - `53af8cd` (build)
3. **Task 3: Seed release verification docs with package evidence commands** - `aa6c734` (docs)

## Files Created/Modified

- `GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.jpg` - Valid JPEG source fixture for copied release smoke.
- `GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.heic` - Valid HEIC/HEIF source fixture for copied release smoke.
- `scripts/verify-packaged-app.sh` - Static packaged-app resource, helper execution, and codesign verification helper.
- `docs/release-verification.md` - Initial release verification checklist and boundary notes.

## Decisions Made

- The HEIC and JPEG samples were accepted from the host after `file` identified them as valid image formats.
- The package verifier invokes `"$HELPER_PATH" -ver`, never a bare `exiftool` command or Homebrew/system path.
- Documentation preserves the signed `.app` Phase 5 boundary and explicitly defers notarization, stapling, DMG/ZIP packaging, updater, installer, public hosting, and Mac App Store readiness.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; work stayed within fixture, script, and documentation outputs.

## Issues Encountered

- The VM could not generate HEIC itself. The user provided a valid host-side `sample.heic`, and `file` confirmed it as `ISO Media, HEIF Image HEVC Main or Main Still Picture Profile`.

## Verification

- `bash -n scripts/verify-packaged-app.sh` passed.
- `file GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.jpg GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.heic` identified JPEG image data and HEIF/HEIC ISO media.
- `rg -n "Contents/Resources/ExifTool/exiftool|codesign --verify|notarization|verify-packaged-app|GPSMetadataEditor.app|Phase 5" scripts docs/release-verification.md` confirmed required script and doc content.
- `rg -n "/opt/homebrew/bin/exiftool|/usr/local/bin/exiftool|bare exiftool -ver|exiftool -ver" scripts/verify-packaged-app.sh` returned no matches.

## User Setup Required

Host-side package verification is still required after building `GPSMetadataEditor.app` on macOS:

```bash
scripts/verify-packaged-app.sh "$APP_PATH"
```

## Next Phase Readiness

Plan 05-03 can now build on the fixtures, package verifier, and initial release verification doc to add the full host checklist and human UAT evidence artifact.

## Self-Check: PASSED

All 05-01 VM acceptance checks passed. Signed app execution remains a host-side Phase 5 verification item.

---
*Phase: 05-packaging-and-release-verification*
*Completed: 2026-05-22*
