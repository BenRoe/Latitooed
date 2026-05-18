# Phase 03: Core Metadata Writing - Research

**Researched:** 2026-05-18  
**Domain:** macOS SwiftUI metadata writing with bundled ExifTool  
**Confidence:** HIGH for service boundary, ExifTool still-image tags, security-scoped access, and VM/host verification limits; MEDIUM for exact helper bundling layout because Phase 5 owns final packaging.

## Redo Research Synthesis

This canonical research file is the planning input for Phase 3 and is now explicitly backed by the redo subagent slices:

- `.planning/phases/03-core-metadata-writing/03-RESEARCH-exiftool.md` — bundled ExifTool, GPS tag strategy, overwrite behavior, source notes.
- `.planning/phases/03-core-metadata-writing/03-RESEARCH-process-concurrency.md` — Swift 6.2 process execution, cancellation, security-scoped access lifetime, fakeable runner tests.
- `.planning/phases/03-core-metadata-writing/03-RESEARCH-ui-data.md` — SwiftUI data flow, minimal apply command, result state mapping, SwiftData deferral.

Cross-slice planning conclusions:

1. Use only bundled ExifTool resolved from `Bundle.main`; no Homebrew, PATH, `/usr/bin/env`, or system fallback.
2. Invoke ExifTool with `Process.executableURL` and `[String]` arguments; never build shell command strings.
3. Write JPEG/HEIC through a unit-testable argument builder, preferably `-overwrite_original` plus `-gpsposition=<latitude>, <longitude>` with host sample verification.
4. Run one deterministic sequential batch and keep security-scoped access active during the actual helper write.
5. Return structured per-file results and map them into existing `SelectedMediaFile.latestResult`, `latestMessage`, and `GPSStatus.updated` state.
6. Treat MOV/MP4 as warnings deferred to Phase 4.
7. Defer SwiftData persistence, progress UI, cancellation UI, result drawer, and detailed history to Phase 4.
8. Preserve the user's `skip UI-SPEC` decision for planning; still respect the locked Phase 3 UI constraints from `03-CONTEXT.md`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Write Safety and Confirmation
- **D-01:** Phase 3 overwrites metadata in place by default; it does not create ExifTool `_original` backups.
- **D-02:** Starting a batch must show a blocking confirmation dialog before any write begins.
- **D-03:** The confirmation copy must clearly warn that GPS metadata will be overwritten and there is no way back to the original metadata through the app. The actions should be equivalent to **Overwrite** and **Abort**.
- **D-04:** If the user aborts, no files should be written.

### Bundled ExifTool
- **D-05:** Phase 3 must bundle ExifTool now and use that bundled helper rather than Homebrew, a system install, or a developer fallback.
- **D-06:** The writer should resolve the helper from `Bundle.main` and fail with a structured user-facing error if the helper is missing or not executable.
- **D-07:** ExifTool invocation must use an executable `URL` and an argument array. Do not build shell command strings.
- **D-08:** Argument construction should be isolated enough for unit tests to verify GPS write arguments without launching ExifTool.

### File Scope
- **D-09:** Phase 3 writes JPEG and HEIC files only.
- **D-10:** Mixed selections are allowed. JPEG/HEIC files should be written, while MOV/MP4 files receive a warning result such as video metadata writing being deferred to Phase 4.
- **D-11:** Unsupported or unwritable files should already be filtered by file intake, but the writer still returns structured failures if a selected file cannot be written at batch time.

### Batch UI and Result Boundary
- **D-12:** Add a minimal **Apply Location** command, disabled until at least one file and one coordinate are selected.
- **D-13:** After confirmation and completion, update each selected file's latest result/status message and show a compact footer summary.
- **D-14:** Do not add a result drawer, progress UI, cancellation control, persistent history, or detailed result review in Phase 3; those belong to Phase 4.

### the agent's Discretion
- Planner may choose the exact `MetadataWriter` protocol shape, result type names, helper resource location, batch coordinator/view-model structure, and UI placement for the apply command, as long as the decisions above and existing SwiftUI architecture are preserved.

### Deferred Ideas (OUT OF SCOPE)
- Optional backup preservation or overwrite preference can be revisited later if users want recoverability instead of destructive default writes.
- MOV and MP4 best-effort metadata writing belongs to Phase 4.
- Batch progress, cancellation, detailed result review, and persistent history belong to Phase 4.
- Native Image I/O or AVFoundation metadata backends remain future options behind the writer service boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BATCH-01 | Apply one selected coordinate to all eligible selected files in a single batch. | Use a main-actor batch coordinator/view-model that iterates current `SelectedMediaFile` snapshots sequentially and calls `MetadataWriter.writeGPS(...)` for JPEG/HEIC only. [VERIFIED: codebase grep] |
| BATCH-05 | Backups by default or explicit overwrite choice. | Locked decision D-01 chooses destructive overwrite, so planner must add confirmation before writing and pass ExifTool `-overwrite_original`. [VERIFIED: CONTEXT.md] [CITED: https://exiftool.org/exiftool_pod.html] |
| BATCH-06 | Sequential batch writes. | Planner should use one awaited loop, not per-file detached/unstructured tasks; this preserves deterministic ordering and security-scope lifetime. [VERIFIED: .agents/skills/swift-concurrency-pro/SKILL.md] |
| META-01 | Write GPS latitude/longitude to JPEG. | ExifTool lists JPEG as writable and GPS metadata as writable/creatable; `Composite:GPSPosition` writes latitude, longitude, and refs together. [CITED: https://exiftool.org/exiftool_pod.html] [CITED: https://exiftool.org/faq.html] |
| META-02 | Write GPS latitude/longitude to HEIC. | ExifTool lists HEIC as writable; use the same EXIF GPS still-image argument strategy and verify on host sample files. [CITED: https://exiftool.org/exiftool_pod.html] |
| META-05 | Use bundled ExifTool helper. | Resolve from `Bundle.main`, check file reachability/executable permission, and never call PATH/Homebrew. ExifTool official distribution can run from an extracted directory without installing. [VERIFIED: CONTEXT.md] [CITED: https://exiftool.org/] |
| META-06 | Invoke through executable URL and argument array. | Apple `Process.arguments` are passed as argv strings without shell expansion; use `executableURL`/`arguments`, not `/bin/sh -c`. [CITED: https://developer.apple.com/documentation/foundation/process/1408983-arguments] |
| META-07 | Return structured per-file result details. | Existing `FileResultStatus` has pending/success/warning/failure and `SelectedMediaFile` has `latestResult`/`latestMessage`; add diagnostic detail in writer results without overloading UI strings. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 3 should introduce a narrow metadata-writing feature slice: a `MetadataWriter` protocol, an `ExifToolMetadataWriter`, a small `Process` runner abstraction, a pure ExifTool argument builder, and a main-actor batch/apply coordinator wired into the existing file-intake and coordinate-selection state. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep]

The primary recommendation is: use bundled ExifTool with arguments like `-overwrite_original`, `-gpsposition=<lat>, <lon>`, and one file path per invocation, executed sequentially under active security-scoped access; map stdout/stderr/exit status into structured per-file results. [CITED: https://exiftool.org/faq.html] [CITED: https://exiftool.org/exiftool_pod.html] [CITED: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource%28%29]

Do not add persistent batch history, cancellation controls, progress UI, video writes, native Image I/O fallback, or a Homebrew/dev fallback in this phase. [VERIFIED: CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Target macOS/iOS-family Apple code with Swift 6.2 or later, strict modern concurrency, SwiftUI, and `@Observable` shared state. [VERIFIED: AGENTS.md]
- Do not introduce third-party Swift frameworks without asking first; avoid UIKit unless requested. [VERIFIED: AGENTS.md]
- `@Observable` classes must be `@MainActor` unless default actor isolation covers them. [VERIFIED: AGENTS.md]
- Prefer async/await over closure APIs; never use `DispatchQueue.main.async()` for new app flow. [VERIFIED: AGENTS.md]
- SwiftUI commands should use `Button("Label", systemImage: ..., action: ...)`, not unlabeled image buttons or tap gestures. [VERIFIED: AGENTS.md]
- Break types into separate Swift files and keep feature folders consistent. [VERIFIED: AGENTS.md]
- Write unit tests for core logic; use UI tests only when unit tests cannot cover behavior. [VERIFIED: AGENTS.md]
- If SwiftLint is installed, planner should include a SwiftLint check before commit. [VERIFIED: AGENTS.md]
- Host-side closeout must include exact `xcodebuild`, Xcode launch, and focused UI smoke steps. [VERIFIED: AGENTS.md]
- Do not make direct code edits outside GSD workflow; this research artifact is planning output only. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Batch command enablement and confirmation | SwiftUI/MainActor UI | Metadata service | The UI owns selected-file/selected-coordinate readiness and the destructive confirmation gate before calling services. [VERIFIED: CONTEXT.md] |
| Sequential write orchestration | MainActor view model/coordinator | Metadata service | Current mutable UI state is `@Observable @MainActor`; the coordinator should await one file at a time and apply result snapshots back to `selectedFiles`. [VERIFIED: codebase grep] |
| ExifTool invocation | Service boundary | Process runner | `ExifToolMetadataWriter` owns helper resolution, argument creation, process execution, and result normalization. [VERIFIED: CONTEXT.md] |
| File permission lifetime | Service boundary | File intake validation | Intake prefilters files, but write-time code must reacquire security-scoped access around the actual helper invocation. [CITED: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource%28%29] |
| Persistent batch history | Out of scope | SwiftData later | Phase 4 owns persistence; Phase 3 should keep result state in the current selected-file snapshots only. [VERIFIED: CONTEXT.md] |

## Standard Stack

No new Swift package dependency should be planned. [VERIFIED: AGENTS.md]

| Component | Version/Source | Purpose | Why Standard |
|-----------|----------------|---------|--------------|
| Swift / SwiftUI | Swift 6.2 project setting | Main app and UI state | Existing project target uses Swift 6.2 and SwiftUI patterns. [VERIFIED: codebase grep] |
| Swift Testing | Existing test target | Unit tests for argument builder, fake process runner, and batch state updates | Existing tests import `Testing` and use `@Test`. [VERIFIED: codebase grep] |
| Foundation `Process` | Apple Foundation | Execute bundled ExifTool via executable URL plus arguments | Apple `Process` exposes `executableURL`, `arguments`, stdout/stderr pipes, termination status, and termination. [CITED: https://developer.apple.com/documentation/foundation/process/executableurl] [CITED: https://developer.apple.com/documentation/foundation/process/1408983-arguments] |
| ExifTool | Bundle resource, current official release 13.58 as of 2026-05-05 | Write JPEG/HEIC GPS metadata | Official ExifTool supports JPEG/HEIC writes and GPS metadata writes. [CITED: https://exiftool.org/] [CITED: https://exiftool.org/exiftool_pod.html] |

### Package Legitimacy Audit

No npm/PyPI/crates/SwiftPM package is recommended for Phase 3; the planner should not install third-party Swift frameworks. [VERIFIED: AGENTS.md]

ExifTool is an external bundled helper, not a language registry package. Treat acquiring/bundling its executable as a source/provenance task: use the official ExifTool distribution, record the version, preserve license files if present, and add host verification that the app does not fall back to `/usr/bin`, `/usr/local/bin`, or `/opt/homebrew/bin`. [CITED: https://exiftool.org/] [ASSUMED]

## Key Implementation Decisions

### Service Boundary

Use this planning shape:

```swift
protocol MetadataWriter: Sendable {
    func writeGPS(_ coordinate: CoordinateSelection, to file: SelectedMediaFile) async -> MetadataWriteResult
}
```

Keep protocol input/output value-typed and `Sendable`; do not pass `ModelContext`, SwiftUI bindings, or mutable view models into the writer. [VERIFIED: .agents/skills/swift-concurrency-pro/SKILL.md] [VERIFIED: .agents/skills/swiftdata-pro/SKILL.md]

Place implementation under a new feature folder such as `GPSMetadataEditor/Features/MetadataWriting/` with separate files for protocol, result values, argument builder, process runner, bundled-helper resolver, and ExifTool writer. [VERIFIED: AGENTS.md] [ASSUMED]

### ExifTool Argument Strategy

Recommended still-image command arguments:

```text
-overwrite_original
-gpsposition=<latitude>, <longitude>
<file path>
```

`Composite:GPSPosition` writes `GPSLatitude`, `GPSLatitudeRef`, `GPSLongitude`, and `GPSLongitudeRef` together in ExifTool 12.36+. [CITED: https://exiftool.org/faq.html] Use decimal latitude/longitude from `CoordinateSelection` and avoid manual N/S/E/W ref construction unless host tests reveal HEIC compatibility issues. [ASSUMED]

Because D-01 requires destructive overwrite with no `_original` backup, include `-overwrite_original`; official ExifTool docs say the default write behavior preserves originals with `_original`, while `-overwrite_original` overwrites by renaming the temp file. [VERIFIED: CONTEXT.md] [CITED: https://exiftool.org/exiftool_pod.html]

Do not use `-overwrite_original_in_place` for Phase 3 unless planning discovers a specific metadata/file-attribute need; it is slower and not required by the locked decisions. [CITED: https://exiftool.org/exiftool_pod.html] [ASSUMED]

### Process Runner

Use a testable runner abstraction:

```swift
struct ProcessResult: Sendable {
    let terminationStatus: Int32
    let standardOutput: String
    let standardError: String
}

protocol ProcessRunning: Sendable {
    func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult
}
```

Implementation should configure `Process.executableURL`, `Process.arguments`, `standardOutput = Pipe()`, and `standardError = Pipe()`, then `try process.run()` and read pipe data after termination. [CITED: https://developer.apple.com/documentation/foundation/process/executableurl] [CITED: https://developer.apple.com/documentation/foundation/process/standardoutput]

Apple documents that `Process.arguments` strings do not undergo shell expansion, which is exactly why spaces, Unicode paths, and shell metacharacters must remain separate array entries instead of being quoted into a command string. [CITED: https://developer.apple.com/documentation/foundation/process/1408983-arguments]

Phase 3 does not expose cancellation UI, but the runner should be shaped for Phase 4 by terminating an active process if its surrounding task is cancelled. [VERIFIED: CONTEXT.md] [VERIFIED: .agents/skills/swift-concurrency-pro/SKILL.md] Use structured cancellation hooks rather than spawning untracked `Task {}` loops. [VERIFIED: .agents/skills/swift-concurrency-pro/SKILL.md]

### File Access

Call `url.startAccessingSecurityScopedResource()` immediately before ExifTool execution and balance it with `stopAccessingSecurityScopedResource()` in `defer` after the process completes. [CITED: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource%28%29]

The security scope must remain active while the child process performs the write; do not start/stop access only during preflight argument construction. [CITED: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource%28%29] [ASSUMED]

If security-scope access fails or the file is no longer reachable/writable, return a structured `.failure` result instead of throwing through the UI. [VERIFIED: CONTEXT.md]

### UI State Bridge

`FileIntakeView` currently owns `FileIntakeViewModel`, while `CoordinateSelectionView` privately owns `CoordinateSelectionViewModel`; Phase 3 must lift or inject coordinate state so the apply command can read both selected files and selected coordinate. [VERIFIED: codebase grep]

Preferred plan: create the coordinate view model in `FileIntakeView` alongside the file-intake view model and pass it into `CoordinateSelectionView(viewModel:)`; then the footer/apply command can check file count plus `selectedCoordinate`. [VERIFIED: codebase grep] [ASSUMED]

Use `confirmationDialog` or `alert` for the blocking overwrite confirmation; keep visible copy direct and avoid adding a wizard/result drawer. [VERIFIED: CONTEXT.md] [VERIFIED: .agents/skills/swiftui-pro/SKILL.md]

### SwiftData

Phase 3 should avoid SwiftData model/schema changes. [VERIFIED: CONTEXT.md] Persistent recent coordinates and batch history are Phase 4 requirements. [VERIFIED: REQUIREMENTS.md]

If the planner decides to persist anything despite the boundary, it must keep `ModelContext` on its actor, use `@Query` only in SwiftUI views, pass value snapshots or persistent identifiers across async service boundaries, and explicitly save correctness-sensitive writes. [CITED: https://developer.apple.com/documentation/swiftdata/modelcontext] [VERIFIED: .agents/skills/swiftdata-pro/SKILL.md]

## File / Module Planning Implications

Likely implementation files:

```text
GPSMetadataEditor/Features/MetadataWriting/
├── MetadataWriter.swift
├── MetadataWriteResult.swift
├── ExifToolMetadataWriter.swift
├── ExifToolArgumentBuilder.swift
├── BundledExifToolResolver.swift
└── ProcessRunner.swift

GPSMetadataEditorTests/
├── ExifToolArgumentBuilderTests.swift
├── ExifToolMetadataWriterTests.swift
├── ProcessRunnerTests.swift
└── MetadataBatchViewModelTests.swift
```

Existing files likely touched by implementation:

- `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` for lifted coordinate state, apply button, confirmation, and footer summary. [VERIFIED: codebase grep]
- `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` for batch result application methods that replace immutable `SelectedMediaFile` snapshots. [VERIFIED: codebase grep]
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionView.swift` to accept an injected `CoordinateSelectionViewModel`. [VERIFIED: codebase grep]
- `GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift` may need a copy/update helper or initializer extension for result updates. [VERIFIED: codebase grep]
- `GPSMetadataEditor.xcodeproj/project.pbxproj` for adding the ExifTool bundle resource and new source/test files. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GPS EXIF coordinate/ref encoding | Custom rational EXIF writer | ExifTool `Composite:GPSPosition` | ExifTool writes latitude, longitude, and ref tags together. [CITED: https://exiftool.org/faq.html] |
| Shell parsing/quoting | Command string with `/bin/sh -c` | `Process.executableURL` + `[String]` arguments | Apple says `arguments` are passed without shell expansion, avoiding quoting bugs. [CITED: https://developer.apple.com/documentation/foundation/process/1408983-arguments] |
| Parallel batch engine | Per-file unstructured `Task {}` loop | One sequential async loop | Phase requires deterministic ordering; local concurrency skill flags unstructured loops as cancellation-risky. [VERIFIED: CONTEXT.md] [VERIFIED: .agents/skills/swift-concurrency-pro/SKILL.md] |
| Persistent history | Ad hoc files or premature SwiftData schema | In-memory per-file result updates only | Phase 4 owns persistence/history. [VERIFIED: CONTEXT.md] |

## Common Pitfalls

### Accidentally Using System ExifTool
**What goes wrong:** Code works on the developer machine because `/usr/local/bin/exiftool` or `/opt/homebrew/bin/exiftool` exists, but fails for users. [VERIFIED: REQUIREMENTS.md]  
**Avoid:** Resolver must use `Bundle.main.url(...)`; tests should assert no PATH lookup fallback. [VERIFIED: CONTEXT.md]  
**Warning sign:** Any code calls `Process.executableURL = URL(fileURLWithPath: "exiftool")` or runs `/usr/bin/env`. [ASSUMED]

### Losing Security-Scoped Access During Write
**What goes wrong:** Intake validation succeeds, but the actual helper cannot write once access is released. [CITED: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource%28%29]  
**Avoid:** Start access in the writer around the actual `Process` run and stop in `defer`. [CITED: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource%28%29]  
**Warning sign:** Security scope is only used in `FileIntakeService.classify(...)`. [VERIFIED: codebase grep]

### Unit Tests Launching Real ExifTool
**What goes wrong:** Tests become host-dependent and fail in the Codex VM, CI, or machines without the bundled helper. [VERIFIED: environment audit]  
**Avoid:** Test argument builder and writer mapping with fake `ProcessRunning`; reserve real sample writes for host-side manual/integration checks. [ASSUMED]

### Treating Video as Failure Instead of Deferred Warning
**What goes wrong:** Mixed selections look broken even though D-10 says MOV/MP4 should produce warnings. [VERIFIED: CONTEXT.md]  
**Avoid:** Batch coordinator should skip `.mov`/`.mp4` and set `.warning` with "video writing is deferred to Phase 4" style copy. [VERIFIED: CONTEXT.md]

### Assuming ExifTool Defaults Match Locked Destructive Behavior
**What goes wrong:** ExifTool creates `_original` backups, contradicting D-01. [VERIFIED: CONTEXT.md] [CITED: https://exiftool.org/exiftool_pod.html]  
**Avoid:** Include `-overwrite_original` only after the confirmation dialog returns overwrite. [VERIFIED: CONTEXT.md] [CITED: https://exiftool.org/exiftool_pod.html]

## Code Examples

### Unit-Testable Argument Builder

```swift
// Source: ExifTool FAQ documents writable Composite:GPSPosition and decimal coordinate input.
struct ExifToolArgumentBuilder: Sendable {
    func gpsWriteArguments(coordinate: CoordinateSelection, fileURL: URL) -> [String] {
        [
            "-overwrite_original",
            "-gpsposition=\(coordinate.latitude), \(coordinate.longitude)",
            fileURL.path(percentEncoded: false),
        ]
    }
}
```

[CITED: https://exiftool.org/faq.html] [ASSUMED: exact Swift API call should be verified against project deployment SDK during implementation]

### Sequential Batch Loop Shape

```swift
for file in selectedFiles {
    let result: MetadataWriteResult

    switch file.kind {
    case .jpeg, .heic:
        result = await metadataWriter.writeGPS(coordinate, to: file)
    case .mov, .mp4:
        result = .warning(file: file, message: "Video metadata writing is planned for Phase 4.")
    }

    apply(result, to: file.id)
}
```

[VERIFIED: CONTEXT.md] [VERIFIED: .agents/skills/swift-concurrency-pro/SKILL.md]

## Testing and Verification Strategy

### Automated Tests

Use Swift Testing tests that do not require a real ExifTool binary. [VERIFIED: codebase grep]

| Behavior | Test Type | Notes |
|----------|-----------|-------|
| GPS argument construction | Unit | Assert `-overwrite_original`, one `-gpsposition=...` argument, and file path as a separate argument. [CITED: https://exiftool.org/faq.html] |
| No shell command strings | Unit/code inspection | `ProcessRunning` API should accept URL + `[String]`; no `/bin/sh`, `zsh`, or `-c`. [CITED: https://developer.apple.com/documentation/foundation/process/1408983-arguments] |
| Helper missing/non-executable | Unit | Fake resolver returns missing/non-executable and writer maps to structured failure. [VERIFIED: CONTEXT.md] |
| stdout/stderr/status mapping | Unit | Fake process returns exit 0, nonzero, stderr warnings; writer maps to success/warning/failure. [VERIFIED: CONTEXT.md] |
| Mixed JPEG/HEIC/MOV/MP4 batch | Unit | JPEG/HEIC invoke writer sequentially; videos get warning; order matches input order. [VERIFIED: CONTEXT.md] |
| Abort confirmation | View-model unit | If user aborts, process runner receives zero calls. [VERIFIED: CONTEXT.md] |
| Security-scope lifetime | Unit seam | Wrap access in an injectable access manager if direct URL security-scope calls are hard to observe. [ASSUMED] |

### Host-Side Verification Required

The Codex VM currently has no `swift`, `xcodebuild`, or `exiftool` on PATH; it cannot prove build/test success or real metadata writes. [VERIFIED: environment audit]

Planner should include exact host checks:

```bash
xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'
```

Then run the app from Xcode on the host, select copied JPEG and HEIC samples, choose a coordinate, confirm **Overwrite**, and verify:

```bash
/path/to/bundled/exiftool -GPSLatitude -GPSLongitude -GPSLatitudeRef -GPSLongitudeRef /path/to/sample.jpg
/path/to/bundled/exiftool -GPSLatitude -GPSLongitude -GPSLatitudeRef -GPSLongitudeRef /path/to/sample.heic
```

Also verify that `/usr/local/bin/exiftool`, `/opt/homebrew/bin/exiftool`, or PATH removal does not affect app execution. [VERIFIED: REQUIREMENTS.md] [ASSUMED]

## Environment Availability

| Dependency | Required By | Available in Codex VM | Version | Fallback |
|------------|-------------|-----------------------|---------|----------|
| `npx ctx7@latest` | Documentation lookup | Yes | npx 11.12.1 | bx/web search |
| `bx` | Brave/source lookup | Yes | 1.5.0 | web search |
| `swift` | Build/tests | No | — | Host-side Xcode required |
| `xcodebuild` | Build/tests | No | — | Host-side Xcode required |
| `exiftool` | Real metadata write verification | No | — | Bundled helper after implementation; host verification |

**Missing dependencies with no fallback in VM:** `swift`, `xcodebuild`, real ExifTool execution. [VERIFIED: environment audit]

**Missing dependencies with fallback:** none for final verification; unit-test planning can still be researched from source. [VERIFIED: environment audit]

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | Local macOS utility has no auth boundary in Phase 3. [VERIFIED: REQUIREMENTS.md] |
| V3 Session Management | No | No sessions. [VERIFIED: REQUIREMENTS.md] |
| V4 Access Control | Yes | Use user-selected file URLs and security-scoped access during writes. [CITED: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource%28%29] |
| V5 Input Validation | Yes | Validate file kind from existing intake and coordinate ranges from `CoordinateSelection`. [VERIFIED: codebase grep] |
| V6 Cryptography | No | No crypto in Phase 3. [VERIFIED: REQUIREMENTS.md] |

Known threat patterns:

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Command injection via filename | Tampering/Elevation | Use executable URL plus argument array; never shell strings. [CITED: https://developer.apple.com/documentation/foundation/process/1408983-arguments] |
| Unauthorized file write | Tampering | Only operate on selected URLs and hold security-scoped access while writing. [CITED: https://developer.apple.com/documentation/foundation/nsurl/startaccessingsecurityscopedresource%28%29] |
| Supply-chain/helper substitution | Tampering | Resolve helper from app bundle, verify executable, and record ExifTool source/version. [VERIFIED: CONTEXT.md] [CITED: https://exiftool.org/] |
| Irreversible metadata loss | Repudiation/Information integrity | Blocking confirmation with explicit overwrite/no-app-restore copy. [VERIFIED: CONTEXT.md] |

## Risks and Non-Goals

Risks:

- HEIC write behavior must be verified on host sample files because ExifTool support is documented, but app bundle execution and Apple Photos/Finder interpretation still need real macOS validation. [CITED: https://exiftool.org/exiftool_pod.html] [ASSUMED]
- Bundling a Perl-based ExifTool distribution inside an app may need project-file/resource and executable-bit handling that final packaging will harden in Phase 5. [CITED: https://exiftool.org/] [ASSUMED]
- Phase 2 host-side verification was waived, so state-bridging around `CoordinateSelectionViewModel` may surface compile/UI issues only on host Xcode. [VERIFIED: STATE.md]

Explicit non-goals:

- No MOV/MP4 writes. [VERIFIED: CONTEXT.md]
- No cancellation control or progress UI. [VERIFIED: CONTEXT.md]
- No persistent batch history or SwiftData schema changes. [VERIFIED: CONTEXT.md]
- No Homebrew/system ExifTool fallback. [VERIFIED: CONTEXT.md]
- No native Image I/O or AVFoundation metadata writer. [VERIFIED: CONTEXT.md]

## Sources

### Primary (HIGH confidence)

- Context7 `/exiftool/exiftool` — ExifTool GPS write examples, `Composite:GPSPosition`, GPS ref tags.  
- Context7 `/websites/developer_apple` — security-scoped URL start/stop documentation.  
- Context7 `/websites/developer_apple_swiftdata` — `ModelContext`, main-actor environment context, autosave.  
- `AGENTS.md` — project Swift/SwiftUI/SwiftData/GSD constraints.  
- `.planning/phases/03-core-metadata-writing/03-CONTEXT.md` — locked Phase 3 decisions.  
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — requirements, roadmap mapping, current state.  
- Codebase grep/source reads — current models, view models, tests, project settings.

### Secondary (MEDIUM confidence)

- Brave `bx` official ExifTool search against `exiftool.org` — ExifTool 13.58 download/version, package/install notes, writable formats, overwrite behavior.  
- Web search official Apple docs — `Process.arguments`, `executableURL`, `standardOutput`, `terminationStatus`.  
- Apple Developer Forums by Apple DTS — process pipe/termination examples; useful implementation caution, not a normative API contract.

### Tertiary (LOW confidence)

- Assumed implementation file layout and exact helper resource location; planner should adapt after inspecting Xcode resource conventions.  
- Assumed use of decimal `-gpsposition=<lat>, <lon>` for both JPEG and HEIC until host sample verification confirms output compatibility.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ExifTool helper should be bundled from official distribution with preserved provenance/license files, but exact app-bundle location is planner discretion. | Package Legitimacy Audit / File Planning | Packaging task may need rework in Phase 5. |
| A2 | Decimal `-gpsposition=<lat>, <lon>` is sufficient for both JPEG and HEIC. | ExifTool Argument Strategy | HEIC host verification may require explicit `-exif:gpslatitude`, refs, or format tweaks. |
| A3 | `-overwrite_original_in_place` is unnecessary for Phase 3. | ExifTool Argument Strategy | File metadata preservation requirements could change command choice. |
| A4 | Security-scoped access started in the parent process covers the child helper write for user-selected files. | File Access | Host sandbox testing could reveal a need for entitlement or file coordination adjustments. |
| A5 | Exact Swift API `fileURL.path(percentEncoded: false)` is available in the target SDK. | Code Examples | Implementation may need `fileURL.path` or another Foundation spelling. |

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all major APIs verified from project files or official docs.
- Architecture: HIGH — service boundary and state seams are explicit in phase context and code.
- ExifTool tags: HIGH for `GPSPosition` and overwrite behavior; MEDIUM for HEIC end-to-end app behavior until host sample verification.
- Verification: HIGH — VM lacks Swift/Xcode/ExifTool, so host-side checks are mandatory.

**Research date:** 2026-05-18  
**Valid until:** 2026-06-17 for architecture; recheck ExifTool release/version before final bundling.
