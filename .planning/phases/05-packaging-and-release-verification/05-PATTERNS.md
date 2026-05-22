# Phase 5: Packaging and Release Verification - Patterns

**Generated:** 2026-05-22T14:50:00+02:00

## Files Likely Created or Modified

| File | Role | Closest Existing Analog |
|------|------|-------------------------|
| `GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.jpg` | committed JPEG smoke fixture | path-safety fake file paths in `ExifToolArgumentBuilderTests.swift` |
| `GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.heic` | committed HEIC smoke fixture | path-safety fake file paths in `ExifToolArgumentBuilderTests.swift` |
| `scripts/verify-packaged-app.sh` | static package verification helper | existing host commands in `docs/host-xcodebuild-verification-boundary.md` |
| `docs/release-verification.md` | manual signed-app verification checklist | `docs/phase-01-05-verification.md`, `docs/host-xcodebuild-verification-boundary.md` |
| `.planning/phases/05-packaging-and-release-verification/05-HUMAN-UAT.md` | host UAT capture artifact | `.planning/phases/04-batch-results-video-and-history/04-HUMAN-UAT.md` |
| `GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift` | targeted helper failure/no-fallback assertions | existing resolver/writer tests in same file |

## Existing Patterns to Follow

### Planning and Verification Docs

- Keep host commands explicit and copyable.
- Separate VM/static checks from host/Xcode checks.
- Do not mark host-only behavior verified from VM output.
- Use short expected/result UAT rows for human smoke checks.

### Swift Tests

- Use Swift Testing with `@Test` and `#expect`.
- Use fake `ProcessRunning` implementations instead of launching real ExifTool in unit tests.
- Keep resolver tests isolated by creating temporary bundle directories.
- Preserve strict-concurrency-friendly value types and actors for fakes.

### Metadata Writer Boundary

- `ExifToolMetadataWriter` should keep injected resolver, argument builder, and process runner.
- `ProcessRunner` must use executable URL plus argument array.
- No shell command strings, no `/bin/sh`, no `zsh`, no `/usr/bin/env`, no PATH lookup.

### Xcode Project

- Resource membership already uses an `ExifTool` folder in the app resources build phase.
- Release has hardened runtime enabled.
- Debug hosted tests intentionally keep hardened runtime disabled.
- Project edits should stay narrowly focused if fixture resources need test target membership.

## GitNexus-Derived Integration Points

- `FileIntakeView.confirmOverwrite` is the app caller that constructs `ExifToolMetadataWriter`; packaged-app smoke should use this existing UI path.
- `BundledExifToolResolver` impact is mostly direct tests; if changing resolver behavior, update `ExifToolMetadataWriterTests`.
- `ExifToolMetadataWriter` impact includes `FileIntakeView.confirmOverwrite` and tests; avoid changing its public behavior beyond failure clarity.
- `ExifToolArgumentBuilder` already has argument-level safety coverage; reuse it instead of adding duplicate packaging-specific argument construction.

## Landmines

- `npx gitnexus analyze` printed a double-free crash after incremental analysis, but status reported the index current afterward. Re-run `npx gitnexus status` before relying on later graph output.
- No existing committed media fixtures are present. HEIC fixture availability may be the execution blocker.
- macOS signing, archive/export, launch, and UI smoke require the host, not this VM.
- Notarization and DMG/ZIP are intentionally deferred; do not accidentally expand Phase 5 into public release automation.
