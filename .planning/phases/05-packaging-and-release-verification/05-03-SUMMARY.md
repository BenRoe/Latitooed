---
phase: 05-packaging-and-release-verification
plan: 05-03
subsystem: packaging
tags: [release-verification, human-uat, codesign, no-fallback]

requires:
  - phase: 05-packaging-and-release-verification
    provides: release fixtures, package verifier, and no-fallback test coverage
provides:
  - Host-side signed app build and static verification checklist
  - Negative-PATH JPEG/HEIC manual smoke checklist
  - Phase 5 human UAT evidence artifact with pending result fields
affects: [packaging, release-verification, milestone-closeout]

tech-stack:
  added: []
  patterns: [manual host UAT capture, signed app checklist, bundled-helper metadata inspection]

key-files:
  created:
    - .planning/phases/05-packaging-and-release-verification/05-HUMAN-UAT.md
  modified:
    - docs/release-verification.md

key-decisions:
  - "Use direct app executable launch with stripped PATH for the no-external-helper smoke."
  - "Keep human UAT pending until the user provides host-side signed app results."
  - "Document Developer ID, notarization, and hardened runtime as remaining outside-App-Store distribution constraints."

patterns-established:
  - "Host release checklists include copyable commands and keep VM/static checks separate from host-only app execution."
  - "Human UAT artifacts use expected/result rows and do not mark host checks passed before evidence exists."

requirements-completed: [PKG-01, PKG-02, PKG-03, PKG-04]

duration: 24min
completed: 2026-05-22T19:38:00Z
---

# Phase 05: Host Release Checklist and UAT Summary

**The release checklist now covers signed app build, codesign/resource checks, stripped-PATH launch, copied JPEG/HEIC smoke, bundled-helper metadata inspection, and pending host UAT evidence.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-05-22T19:14:00Z
- **Completed:** 2026-05-22T19:38:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Expanded `docs/release-verification.md` with exact host commands for `xcodebuild test`, Release build output, `APP_PATH`, and `scripts/verify-packaged-app.sh "$APP_PATH"`.
- Added a `Manual Smoke: No External ExifTool` section that copies fixtures to a temp directory, launches the app with `PATH=/usr/bin:/bin:/usr/sbin:/sbin`, applies Berlin coordinates, and inspects copied files with the bundled helper path.
- Added `05-HUMAN-UAT.md` with pending expected/result rows for PKG-01 through PKG-04, metadata inspection, and packaging notes.

## Task Commits

1. **Task 1: Write exact host signed-app build and static verification checklist** - `5c14899` (docs)
2. **Task 2: Add negative-PATH UI smoke and metadata inspection steps** - `5c14899` (docs)
3. **Task 3: Create Phase 5 human UAT evidence artifact** - `0be3081` (docs)

## Files Created/Modified

- `docs/release-verification.md` - Complete host checklist and signed `.app` distribution boundary notes.
- `.planning/phases/05-packaging-and-release-verification/05-HUMAN-UAT.md` - Host evidence capture artifact with pending results.

## Decisions Made

- The no-fallback smoke launches `"$APP_PATH/Contents/MacOS/GPSMetadataEditor"` directly with a stripped `PATH`, avoiding uncertainty about whether Launch Services preserves environment variables.
- Metadata inspection uses `"$APP_PATH/Contents/Resources/ExifTool/exiftool"` so verification cannot silently depend on Homebrew ExifTool.
- The UAT artifact remains `status: partial` because signed app execution and UI smoke require host evidence.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; host execution remains explicitly pending.

## Issues Encountered

None.

## Verification

- `rg -n "xcodebuild test|verify-packaged-app|codesign|notarization|DMG|ZIP|/Users/ben/Git/image-exif-gps" docs/release-verification.md` confirmed host build, codesign, and distribution-boundary commands.
- `rg -n "PATH=/usr/bin:/bin:/usr/sbin:/sbin|52.520008|13.404954|Contents/Resources/ExifTool/exiftool|sample.heic|sample.jpg" docs/release-verification.md` confirmed no-fallback smoke steps.
- `rg -n "renam|delet|/opt/homebrew/bin/exiftool|/usr/local/bin/exiftool" docs/release-verification.md` returned no matches.
- `rg -n "PKG-01|PKG-02|PKG-03|PKG-04|result: \\[pending\\]|docs/release-verification.md" .planning/phases/05-packaging-and-release-verification/05-HUMAN-UAT.md` confirmed pending UAT coverage.
- `rg -n "result: \\[passed\\]" .planning/phases/05-packaging-and-release-verification/05-HUMAN-UAT.md` returned no matches.

## User Setup Required

Run the host checklist in `docs/release-verification.md`, then paste the results into `05-HUMAN-UAT.md`.

## Next Phase Readiness

All Phase 5 plans are source-complete. Phase-level verification should report `human_needed` until the macOS host checklist and UAT rows are completed.

## Self-Check: PASSED

Documentation and UAT acceptance checks passed in the VM. Host signed app execution remains pending by design.

---
*Phase: 05-packaging-and-release-verification*
*Completed: 2026-05-22*
