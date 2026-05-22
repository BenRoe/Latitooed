---
phase: 05-packaging-and-release-verification
verified: 2026-05-22T19:06:16Z
status: human_needed
score: 2/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 2/5
  gaps_closed: []
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Run host xcodebuild tests"
    expected: "On macOS host, `xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'` exits 0, including helper failure tests."
    why_human: "The VM has no `xcodebuild`; host Xcode execution is required."
  - test: "Build signed Release app on host"
    expected: "The Release build creates a signed `GPSMetadataEditor.app` at the documented `APP_PATH`."
    why_human: "Signed app build and codesign verification require the macOS host signing environment."
  - test: "Run static packaged-app verifier on host"
    expected: "`scripts/verify-packaged-app.sh \"$APP_PATH\"` finds `Contents/Resources/ExifTool/exiftool`, confirms it is executable, prints bundled helper version, and passes codesign verification."
    why_human: "No built signed `.app` artifact exists in the VM checkout."
  - test: "Launch signed app with stripped PATH"
    expected: "`PATH=/usr/bin:/bin:/usr/sbin:/sbin \"$APP_PATH/Contents/MacOS/GPSMetadataEditor\"` launches the signed app without external ExifTool lookup."
    why_human: "App launch and helper execution must be observed on the host."
  - test: "Complete JPEG/HEIC UI smoke"
    expected: "Using copied `sample.jpg` and `sample.heic`, the app applies Berlin coordinate `52.520008, 13.404954` and both rows report success."
    why_human: "SwiftUI interaction and real signed-app metadata writes are host-only UAT."
  - test: "Record pre-write GPS baseline"
    expected: "Before launching the app, the bundled-helper inspection of copied `sample.jpg` and `sample.heic` shows no GPS tags or values that do not already match Berlin."
    why_human: "Requires the host-built signed app and copied smoke files."
  - test: "Inspect written metadata with bundled helper"
    expected: "`\"$APP_PATH/Contents/Resources/ExifTool/exiftool\" -gpslatitude -gpslongitude -gpsposition \"$SMOKE_DIR/sample.jpg\" \"$SMOKE_DIR/sample.heic\"` reports Berlin GPS values for both copied files."
    why_human: "Requires files written by the host UI smoke."
---

# Phase 5: Packaging and Release Verification Report

**Phase Goal:** Prove the signed packaged app works without external command-line dependencies.
**Verified:** 2026-05-22T19:06:16Z
**Status:** human_needed
**Re-verification:** Yes - after review fixes commit `2d93048`

## MVP Mode Note

ROADMAP marks this phase as `mode: mvp`, but `gsd-sdk query user-story.validate --story "Prove the signed packaged app works without external command-line dependencies." --pick valid` returned `false`. Because this phase is a technical release-verification slice and the user explicitly requested goal-backward verification, this report verifies the roadmap success criteria directly. It does not treat the invalid MVP user-story format as evidence that the packaging goal passed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The built app bundle includes the ExifTool helper in bundle resources. | ? HUMAN NEEDED | Source evidence exists: `GPSMetadataEditor.xcodeproj/project.pbxproj` has `ExifTool in Resources`, and `GPSMetadataEditor/Resources/ExifTool/exiftool` exists and is executable. The actual built signed app resource path is still pending in `05-HUMAN-UAT.md`. |
| 2 | The signed app can resolve and execute the bundled helper from `Bundle.main`. | ? HUMAN NEEDED | Source resolver uses `bundle.url(forResource: "exiftool", withExtension: nil, subdirectory: "ExifTool")`, and tests assert bundle-local paths. `scripts/verify-packaged-app.sh` now verifies the app signature before executing the helper version check. Signed app execution is not yet proven; `05-HUMAN-UAT.md` leaves PKG-02 pending. |
| 3 | The app reports clear errors when the helper is missing, non-executable, or fails to launch. | VERIFIED | `ExifToolMetadataWriter.swift` maps missing/non-executable helper errors to user-facing messages, and `ExifToolMetadataWriterTests.swift` covers missing helper, non-executable helper, and runner launch failure mapping. Host test execution remains a human check. |
| 4 | A release verification flow writes GPS metadata to sample JPEG and HEIC files on a machine without Homebrew or system ExifTool. | ? HUMAN NEEDED | `docs/release-verification.md` documents copied fixtures, pre-write GPS baseline capture, stripped `PATH`, Berlin coordinate write, and bundled-helper metadata inspection. The actual host UI smoke is pending in `05-HUMAN-UAT.md`; it is not marked passed. |
| 5 | Packaging notes document remaining notarization or distribution constraints. | VERIFIED | `docs/release-verification.md` states Phase 5 verifies a signed app only and defers notarization, stapling, DMG/ZIP, updater, installer, public hosting, and Mac App Store readiness. |

**Score:** 2/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.jpg` | JPEG smoke fixture | VERIFIED | `file` reports JPEG image data. |
| `GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.heic` | HEIC smoke fixture | VERIFIED | `file` reports ISO Media, HEIF Image HEVC profile. |
| `scripts/verify-packaged-app.sh` | Static package verifier | VERIFIED | `bash -n` exits 0; script checks app bundle, bundled helper path, executable bit, runs `codesign --verify` and `codesign -dv`, then executes the helper version check after signature verification. |
| `docs/release-verification.md` | Host release checklist | VERIFIED | Contains VM checks, host `xcodebuild test`, Release build, static package checks, pre-write GPS baseline capture, stripped-PATH smoke, and distribution caveats. |
| `GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift` | Helper failure/no-fallback tests | VERIFIED | Substantive Swift Testing coverage for missing helper, non-executable helper, bundle-only resolver path, and runner failure mapping. |
| `GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift` | Argument path safety tests | VERIFIED | Tests preserve final file path as one argument and reject executable/shell/PATH tokens. |
| `.planning/phases/05-packaging-and-release-verification/05-HUMAN-UAT.md` | Host evidence capture | VERIFIED | Lists PKG-01 through PKG-04 plus pre-write baseline and metadata inspection checks with `result: [pending]`; no `result: [passed]` claims. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `GPSMetadataEditor.xcodeproj/project.pbxproj` | `scripts/verify-packaged-app.sh` | ExifTool resource membership materializes at `Contents/Resources/ExifTool/exiftool` | VERIFIED | Project has `ExifTool in Resources`; script checks the same bundle path. Actual built bundle remains host UAT. |
| `BundledExifToolResolver.swift` | `ExifToolMetadataWriterTests.swift` | Typed helper errors mapped to user-facing messages | VERIFIED | Tests assert `Bundled ExifTool helper is missing.` and `Bundled ExifTool helper is not executable.` |
| `ExifToolMetadataWriter.swift` | `FileIntakeView.confirmOverwrite` | Packaged happy path uses normal app writer | VERIFIED | `FileIntakeView.confirmOverwrite` calls `ExifToolMetadataWriter()`, which defaults to `BundledExifToolResolver.mainBundle()`. |
| `docs/release-verification.md` | `05-HUMAN-UAT.md` | Same host smoke steps | VERIFIED | Both artifacts include stripped PATH launch, pre-write baseline, fixture write smoke, bundled-helper inspection, and pending evidence rows. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `FileIntakeView.swift` | Selected files and coordinate passed to `applyMetadataIfConfirmed` | User-selected files and `coordinateViewModel.selectedCoordinate` | Yes in app flow; host UI smoke pending | HUMAN NEEDED |
| `ExifToolMetadataWriter.swift` | `executableURL`, `arguments`, `ProcessResult` | `BundledExifToolResolver.mainBundle()`, `ExifToolArgumentBuilder`, `FoundationProcessRunner` | Source is real bundle/process flow; signed bundle execution pending | HUMAN NEEDED |
| `docs/release-verification.md` | Smoke fixture copies and `APP_PATH` | Host commands copy committed fixtures and build Release app | Pending host execution | HUMAN NEEDED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Fixture formats are valid | `file GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.jpg GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.heic` | JPEG and HEIF/HEIC ISO Media reported | PASS |
| Package verifier shell parses | `bash -n scripts/verify-packaged-app.sh` | Exit 0 | PASS |
| Bundled repo helper executes | `GPSMetadataEditor/Resources/ExifTool/exiftool -ver` | `13.58` | PASS |
| Review fix doc/script hardening exists | `rg -n "pre-write GPS baseline|codesign --verify|Bundled ExifTool version" docs/release-verification.md scripts/verify-packaged-app.sh` | Baseline text found in docs; `codesign --verify` appears before `Bundled ExifTool version` in the verifier script. | PASS |
| Host test suite | `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` | `command not found: xcodebuild` in VM | HUMAN NEEDED |
| Signed app package verifier | `scripts/verify-packaged-app.sh "$APP_PATH"` | Not run; no host-built signed `.app` artifact in VM | HUMAN NEEDED |
| Signed app UI smoke | Follow `docs/release-verification.md` | Not run; `05-HUMAN-UAT.md` results pending | HUMAN NEEDED |

### Probe Execution

No probe scripts were declared and `find scripts -path '*/tests/probe-*.sh' -type f` found none. Step 7c: SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PKG-01 | 05-01, 05-03 | Packaged app includes ExifTool helper in bundle resources. | HUMAN NEEDED | Project resource membership and script checks exist; actual signed app resource evidence is pending. |
| PKG-02 | 05-02, 05-03 | Signed app can locate and execute bundled helper from app bundle. | HUMAN NEEDED | Resolver/test/script evidence exists; host signed app execution pending. |
| PKG-03 | 05-02, 05-03 | Clear user-facing error if helper is missing, non-executable, or fails to launch. | VERIFIED | Source and tests cover missing, non-executable, and throwing runner failure messages. |
| PKG-04 | 05-01, 05-03 | App completes JPEG/HEIC write flow without Homebrew/system ExifTool. | HUMAN NEEDED | Release checklist and fixtures exist; actual negative-PATH host UI smoke pending. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No unresolved `TBD`, `FIXME`, or `XXX` markers found in phase-modified files. | - | - |

### Human Verification Required

#### 1. Host Xcode Tests

**Test:** On the macOS host:

```bash
cd /Users/ben/Git/image-exif-gps
xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'
```

**Expected:** The test suite exits 0, including helper failure tests for PKG-03.
**Why human:** The VM does not have Xcode; `xcodebuild` is unavailable here.

#### 2. Signed Release App Build And Static Verification

**Test:** Follow `docs/release-verification.md` through the Release build and run:

```bash
scripts/verify-packaged-app.sh "$APP_PATH"
```

**Expected:** The script confirms `Contents/Resources/ExifTool/exiftool`, executable bit, bundled helper version, and codesign verification for the signed `GPSMetadataEditor.app`.
**Why human:** Requires host-built signed app artifact and host signing environment.

#### 3. Signed App No-External-Helper Launch

**Test:** Launch the built app on the host with:

```bash
PATH=/usr/bin:/bin:/usr/sbin:/sbin "$APP_PATH/Contents/MacOS/GPSMetadataEditor"
```

**Expected:** The app launches and remains usable without Homebrew/system ExifTool on `PATH`.
**Why human:** Actual signed app launch cannot be proven from static VM checks.

#### 4. JPEG/HEIC Baseline, Write Smoke, And Metadata Inspection

**Test:** Copy `sample.jpg` and `sample.heic` to a temp directory, inspect the copied files before launch to establish that they do not already contain Berlin GPS values, select both in the app, apply Berlin coordinate `52.520008, 13.404954`, then inspect again:

```bash
"$APP_PATH/Contents/Resources/ExifTool/exiftool" \
  -gpslatitude -gpslongitude -gpsposition \
  "$SMOKE_DIR/sample.jpg" "$SMOKE_DIR/sample.heic"
```

**Expected:** The pre-write baseline does not already match Berlin, both app rows report success, and both copied files show Berlin GPS values or equivalent north/east formatting.
**Why human:** This is the core UI smoke and real metadata write proof for PKG-04.

### Gaps Summary

No code gaps were found in the repository artifacts. Review fixes from commit `2d93048` are verified: the release checklist now records a pre-write GPS baseline, and the package verifier checks the app signature before executing the bundled helper. The phase is still not fully passable because the central release claim requires host evidence that is explicitly pending: signed app build, codesign/resource verification, signed app launch with stripped `PATH`, pre-write baseline evidence, and JPEG/HEIC write smoke. Per the user instruction, these host checks are not marked as passed.

---

_Verified: 2026-05-22T19:06:16Z_
_Verifier: the agent (gsd-verifier)_
