# Phase 5: Packaging and Release Verification - Context

**Gathered:** 2026-05-20T10:40:00+02:00
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 5 proves that the signed packaged macOS app is self-contained for the v1 release path. The phase must verify that ExifTool is included in the app bundle resources, resolved from `Bundle.main`, executable from the signed app, and able to write sample JPEG and HEIC files without relying on Homebrew or any system ExifTool install. This phase should produce a verified signed `.app` artifact and clear packaging notes, while leaving notarization, DMG/ZIP creation, and public distribution hardening as documented follow-up constraints.

</domain>

<decisions>
## Implementation Decisions

### Release Artifact Shape
- **D-01:** Phase 5 should produce and verify a signed `.app` bundle only.
- **D-02:** Do not require a notarized DMG, notarized ZIP, installer package, or public download container for Phase 5 completion.
- **D-03:** Notarization, stapling, DMG/ZIP packaging, update delivery, and public distribution polish should be documented as remaining release constraints.

### No-Fallback Proof
- **D-04:** Verification must include a negative external-helper proof on the macOS host: run the packaged app in an environment where Homebrew/system ExifTool is unavailable or `PATH` is stripped, then complete the JPEG/HEIC write smoke.
- **D-05:** Do not temporarily rename or mutate a host Homebrew/system ExifTool install as part of the standard verification path.
- **D-06:** Static inspection alone is not enough for Phase 5; the signed packaged app must execute the bundled helper in a real smoke.
- **D-07:** This no-fallback proof is a developer/release verification step only. Customers should not need Homebrew ExifTool or any separately installed helper.
- **D-08:** Build and packaging should use the bundled repo resources already under `GPSMetadataEditor/Resources/ExifTool/`; avoid adding a Phase 5 build dependency on Homebrew ExifTool.

### Sample Verification Files
- **D-09:** Add or identify small repository JPEG and HEIC sample fixtures for packaged-app verification.
- **D-10:** Verification must copy fixtures to a temporary working directory before running the smoke so tracked fixture files remain unchanged.
- **D-11:** The packaged-app smoke should write GPS metadata to the copied JPEG and HEIC files, not only inspect bundle contents.

### Host Verification Flow
- **D-12:** Phase 5 should document a manual host-side verification checklist with exact commands.
- **D-13:** The checklist should cover archive/export or equivalent signed-app build, codesign/resource checks, launch of the signed `.app`, fixture copy, UI selection of copied fixtures, applying a known coordinate, and metadata inspection.
- **D-14:** Prefer a robust manual smoke over brittle full UI automation for this phase.
- **D-15:** Full scripted end-to-end UI automation is out of scope for Phase 5.

### Helper Failure Behavior
- **D-16:** Missing-helper, non-executable-helper, and launch-failure behavior should be covered with unit or integration tests.
- **D-17:** Manual packaged-app verification only needs the happy path for helper execution and JPEG/HEIC writes.
- **D-18:** Do not require manual destructive variants that duplicate the app bundle and remove or chmod the helper during standard Phase 5 closeout.

### Packaging Notes
- **D-19:** Packaging notes should clearly state: signed app verified; notarization, stapling, DMG/ZIP distribution, and wider release packaging remain deferred.
- **D-20:** Notes should reference current Apple guidance for outside-App-Store macOS distribution: Developer ID signing, notarization, and hardened runtime considerations.
- **D-21:** Notes should preserve the initial outside-App-Store distribution assumption and avoid implying Mac App Store readiness.

### the agent's Discretion
- Planner may choose the exact fixture file locations, verification document filename, command syntax, and whether to add a small script for static archive/resource checks, as long as the required manual host smoke remains explicit.
- Planner may choose how to inspect post-write metadata, but inspection should use the bundled helper path or another explicit non-fallback command path so the result cannot silently depend on Homebrew ExifTool.
- Planner may decide whether existing resolver tests are sufficient or need targeted additions for launch-failure coverage.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope
- `.planning/PROJECT.md` - Defines the self-contained native macOS app, bundled ExifTool direction, outside-App-Store v1 assumption, and packaging verification need.
- `.planning/REQUIREMENTS.md` - Defines Phase 5 requirements PKG-01, PKG-02, PKG-03, and PKG-04.
- `.planning/ROADMAP.md` - Defines Phase 5 goal, success criteria, and the warning to avoid `/opt/homebrew/bin/exiftool` fallback.
- `.planning/STATE.md` - Captures carried-forward decisions and Phase 5 as the next action.

### Prior Phase Decisions
- `.planning/phases/03-core-metadata-writing/03-CONTEXT.md` - Locks bundled ExifTool, bundle-only helper resolution, argument-array invocation, structured helper errors, and JPEG/HEIC write scope.
- `.planning/phases/04-batch-results-video-and-history/04-CONTEXT.md` - Locks current batch-result behavior, video best-effort behavior, and relevant metadata writer files.
- `docs/host-xcodebuild-verification-boundary.md` - Documents host-vs-VM limits for Xcode build, signing, packaging, and app smoke checks.

### Source Files to Inspect
- `GPSMetadataEditor.xcodeproj/project.pbxproj` - Current Xcode project resource inclusion for the ExifTool folder.
- `GPSMetadataEditor/Resources/ExifTool/exiftool` - Bundled helper executable expected in app resources.
- `GPSMetadataEditor/Resources/ExifTool/README` - Local helper resource notes.
- `GPSMetadataEditor/Features/MetadataWriting/BundledExifToolResolver.swift` - Current `Bundle.main` resource lookup and executable-bit validation.
- `GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift` - Current writer behavior for helper failures, process execution, and success/failure mapping.
- `GPSMetadataEditor/Features/MetadataWriting/ProcessRunner.swift` - Current `Process` execution boundary for the helper.
- `GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift` - Current JPEG, HEIC, MOV, and MP4 argument construction.
- `GPSMetadataEditorTests/ExifToolMetadataWriterTests.swift` - Existing resolver and writer failure-path coverage.
- `GPSMetadataEditorTests/ExifToolArgumentBuilderTests.swift` - Existing argument coverage that may inform fixture expectations.

### External Release Guidance
- `https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution` - Apple notarization guidance; confirms notarization uses Developer ID-signed software and current `notarytool` workflow.
- `https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution` - Apple packaging guidance for signing, distribution containers, notarization, and bundle-contained resources.
- `https://developer.apple.com/macos/distribution/` - Apple overview of outside-App-Store Mac distribution with Developer ID and notarization.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BundledExifToolResolver` already resolves `ExifTool/exiftool` from a supplied bundle and validates executability.
- `ExifToolMetadataWriter` already maps missing and non-executable helper errors to user-facing failure messages.
- `FoundationProcessRunner` already launches an executable URL with an argument array and does not use shell command strings.
- `ExifToolMetadataWriterTests` already include missing-helper, non-executable-helper, bundle-only resolver, nonzero-exit, and runner-throw coverage.
- `GPSMetadataEditor.xcodeproj/project.pbxproj` already has an `ExifTool in Resources` entry for the app target.

### Established Patterns
- Packaging and signing verification must run on the macOS host/Xcode side; this Linux VM can inspect source and planning artifacts but cannot prove signed `.app` behavior.
- Metadata writing stays behind the existing `MetadataWriter` service boundary.
- Tests use Swift Testing with focused service-level coverage.
- User-facing helper failures should remain clear and quiet, consistent with existing result messaging.

### Integration Points
- Phase 5 likely connects at the Xcode project resource phase, build/archive/export commands, helper resolver tests, and a new packaging verification document.
- The manual smoke should use the existing app UI: select copied JPEG/HEIC fixtures, choose a known coordinate such as Berlin, apply location, then inspect the copied files.
- Any static helper verification should check the built app resource path, expected executable bit, and codesign state without replacing the real packaged-app smoke.

</code_context>

<specifics>
## Specific Ideas

- Use the Berlin coordinate from existing app fixtures/state as the known write target unless planning finds a better stable sample.
- Verification command examples should make the no-fallback boundary obvious, such as stripping `PATH` when launching the app or explicitly checking that no `/opt/homebrew/bin/exiftool` path is used.
- Keep fixture writes isolated by copying sample files to `/tmp` or another temporary host-side working directory before manual smoke.
- State customer expectation plainly: users receive the `.app` with ExifTool bundled and do not install Homebrew ExifTool.

</specifics>

<deferred>
## Deferred Ideas

- Notarized ZIP or DMG distribution.
- Stapling notarization tickets.
- Public release download page, updater, installer package, or release automation.
- Full scripted SwiftUI end-to-end packaged-app automation.

</deferred>

---

*Phase: 5-Packaging and Release Verification*
*Context gathered: 2026-05-20T10:40:00+02:00*
