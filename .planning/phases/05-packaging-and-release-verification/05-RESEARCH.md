# Phase 5: Packaging and Release Verification - Research

**Generated:** 2026-05-22T14:50:00+02:00
**Status:** Complete

## Research Question

What needs to change to plan Phase 5 well, using current code and GitNexus evidence?

## Summary

Phase 5 should be planned as a release-verification slice, not as a new metadata-writing feature. The code already has the important runtime seams: `BundledExifToolResolver` resolves `ExifTool/exiftool` from a bundle, `ExifToolMetadataWriter` injects the resolver/argument builder/process runner, and tests already cover missing, non-executable, nonzero-exit, and runner-throw behavior. The remaining work is to prove that this survives packaging/signing and cannot pass by using Homebrew or a system ExifTool.

## GitNexus Findings

GitNexus was refreshed for current commit `98b76ae`; the first `npx gitnexus analyze` run printed `free(): double free detected in tcache 2` after incremental update work, but `npx gitnexus status` then reported the repository up to date.

Relevant GitNexus queries:

- `bundled ExifTool resolver packaged app resources metadata writer process runner`
- `Xcode project resources ExifTool signed app packaging verification tests`
- `metadata write batch apply GPS JPEG HEIC helper failure`
- `requirements PKG-01 PKG-02 PKG-03 PKG-04 packaging release verification`

Key graph evidence:

- `BundledExifToolResolver` is directly exercised by `ExifToolMetadataWriterTests` for missing helper, non-executable helper, bundle-only resolution, JPEG/HEIC success, video success, nonzero exit, and runner-throw behavior.
- `ExifToolMetadataWriter` has one app-side caller through `FileIntakeView.confirmOverwrite` and direct test coverage in `ExifToolMetadataWriterTests`.
- `ExifToolArgumentBuilder` is used by `ExifToolMetadataWriter` and covered by `ExifToolArgumentBuilderTests`, including path safety and video coordinates.
- GitNexus impact for `BundledExifToolResolver` is medium and mostly test-bound: direct tests plus `ExifToolMetadataWriter.init`.
- GitNexus impact for `ExifToolMetadataWriter` is medium and affects `FileIntakeView.confirmOverwrite` plus metadata writer tests.
- Project resource membership already contains `ExifTool in Resources` in `GPSMetadataEditor.xcodeproj/project.pbxproj`.

Planning implication: keep code changes surgical. Most Phase 5 work should add release fixtures, static/package checks, host verification docs, and targeted tests rather than rewriting metadata flow.

## Apple Release Guidance

Current Apple guidance relevant to the phase:

- Apple notarization docs state that macOS software distributed with Developer ID should be notarized before distribution, and that the modern notary path uses `notarytool` rather than the old `altool` path.
- Apple packaging guidance says direct distribution uses signed code, a distribution container, then notarization of that container.
- Apple Developer ID help identifies Developer ID Application certificates as the certificate type for signing Mac apps distributed outside the Mac App Store.

Planning implication: Phase 5 can verify a signed `.app` as locked in `05-CONTEXT.md`, while documenting notarization, stapling, and DMG/ZIP as follow-up release constraints. Do not imply public distribution is complete without notarization/container work.

## Existing Code State

### Already Present

- `GPSMetadataEditor/Resources/ExifTool/exiftool` and bundled `lib/` runtime.
- Xcode resource build phase includes the `ExifTool` folder.
- Release build has `ENABLE_HARDENED_RUNTIME = YES`.
- Debug build has `ENABLE_HARDENED_RUNTIME = NO` for hosted tests, documented in `docs/xcode-hosted-test-bundle-signing.md`.
- `BundledExifToolResolver.executableURL()` checks for missing and non-executable helper.
- `ExifToolMetadataWriter` catches `BundledExifToolResolver.ResolverError` and maps helper failures to clear messages.
- `ProcessRunner` uses `Process.executableURL` and `arguments`, not a shell.
- Existing tests avoid launching real ExifTool by using fake process runners.

### Missing / Needs Planning

- No committed JPEG/HEIC release-smoke fixtures currently exist.
- No packaged-app release verification document currently gives exact host commands.
- No static check script/documented command currently verifies built app resource path, executable bit, code signature, and absence of `/opt/homebrew/bin/exiftool` usage.
- Existing tests cover resolver and runner errors, but Phase 5 should decide whether to add one targeted assertion for process-launch failure preserving user-facing helper failure behavior.
- No Phase 5 UAT artifact exists to capture host results for signed `.app` smoke.

## Recommended Plan Split

### 05-01: Package Evidence and Fixtures

Create or add small JPEG/HEIC fixtures, add a package verification helper script or documented static-check command, and prove the built app bundle contains executable `Contents/Resources/ExifTool/exiftool`. This covers PKG-01 and prepares the repeatable smoke for PKG-04.

### 05-02: No-Fallback and Helper Failure Tests

Tighten source/test evidence around no PATH/Homebrew fallback and helper failure mapping. This covers PKG-02 and PKG-03 without forcing awkward manual packaged-app failure variants.

### 05-03: Host Release Verification Checklist

Write the host-side checklist, packaging notes, and Phase 5 UAT template. The checklist must include exact host `xcodebuild`, codesign/resource checks, stripped-PATH app launch, temp fixture copy, UI smoke, metadata inspection, and the distribution caveats. This covers PKG-04 and the roadmap packaging-notes criterion.

## Risks

- HEIC fixture creation may require macOS host tooling or a user-provided sample. If execution cannot create a valid HEIC fixture in the VM, the plan should stop and ask for a small fixture rather than weakening the requirement.
- The VM cannot prove Xcode archive, codesign, launch, or app-bundle execution. Host verification remains mandatory.
- A signed `.app` is not the same as a notarized public release. Documentation must be precise about that boundary.

## Sources

- `.planning/phases/05-packaging-and-release-verification/05-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `GPSMetadataEditor.xcodeproj/project.pbxproj`
- `GPSMetadataEditor/Features/MetadataWriting/BundledExifToolResolver.swift`
- `GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift`
- `GPSMetadataEditor/Features/MetadataWriting/ProcessRunner.swift`
- `GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift`
- `docs/host-xcodebuild-verification-boundary.md`
- `docs/xcode-hosted-test-bundle-signing.md`
- Apple: `https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution`
- Apple: `https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution`
- Apple: `https://developer.apple.com/help/account/certificates/create-developer-id-certificates/`

## Validation Architecture

Phase 5 validation requires three layers:

1. **Source/static verification:** project resource membership, resolver source has no PATH/Homebrew fallback, package-check script verifies resource path/executable bit/codesign on built `.app`.
2. **Unit/integration tests:** helper failure mapping remains covered without mutating packaged app bundles manually.
3. **Host manual smoke:** signed packaged app launches with external ExifTool unavailable or PATH stripped, writes copied JPEG/HEIC fixtures, and post-write metadata is inspected from the built bundle/helper path.
