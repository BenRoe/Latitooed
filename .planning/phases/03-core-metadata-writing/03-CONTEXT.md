# Phase 3: Core Metadata Writing - Context

**Gathered:** 2026-05-18T13:35:14+02:00
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 adds the first real metadata write path. A user can select local media files, choose a target coordinate from the existing coordinate selection panel, and apply that coordinate to eligible JPEG and HEIC files through a bundled ExifTool helper. The phase must keep writes sequential and deterministic, call ExifTool through an executable URL plus argument array, and return structured per-file results. MOV/MP4 video writes, cancellable progress UI, persistent batch history, and detailed result review remain Phase 4 work.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope
- `.planning/PROJECT.md` — Defines the self-contained native macOS app, bundled ExifTool direction, destructive-write caution, and v1 constraints.
- `.planning/REQUIREMENTS.md` — Defines Phase 3 requirements BATCH-01, BATCH-05, BATCH-06, META-01, META-02, META-05, META-06, and META-07.
- `.planning/ROADMAP.md` — Defines Phase 3 goal, success criteria, and implementation notes.
- `.planning/STATE.md` — Captures carried-forward project decisions and current phase status.

### Prior Phase Decisions
- `.planning/phases/01-app-shell-and-file-intake/01-CONTEXT.md` — Establishes selected-file intake behavior, supported file kinds, warnings, and layout constraints.
- `.planning/phases/02-coordinate-selection/02-CONTEXT.md` — Establishes coordinate selection behavior, selected target display, Berlin default, map selection, and manual coordinate input.

### Source Files to Inspect
- `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` — Current root view owns file intake state and renders `CoordinateSelectionView()` on the right side.
- `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` — Owns selected files, latest notices, selected-file detail, and established `@Observable @MainActor` state pattern.
- `GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift` — Immutable selected-file snapshot with URL, media kind, GPS status, latest result, and latest message fields.
- `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift` — Existing security-scoped resource access and file validation behavior to preserve during write-time access.
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` — Owns selected coordinate and field state; Phase 3 must expose or lift this value for batch writing.
- `GPSMetadataEditor/Features/CoordinateSelection/Models/CoordinateSelection.swift` — Validated coordinate value and six-decimal display format.

No external specs or ADRs were referenced during discussion.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SelectedMediaFile` already carries `kind`, `latestResult`, and `latestMessage`, which gives Phase 3 a narrow place to surface per-file write outcomes.
- `FileResultStatus` already has `pending`, `success`, `warning`, and `failure`, matching the structured result states Phase 3 needs.
- `GPSStatus` already has `updated`, which can represent a successful metadata write after Phase 3 completes.
- `FileIntakeService` already validates reachability, readability, writability, locked state, and media kind. Write-time code should still reacquire security-scoped access while invoking ExifTool.
- `CoordinateSelection` is already `Sendable`, validates latitude/longitude ranges, and has stable display formatting.

### Established Patterns
- Feature code is grouped under `GPSMetadataEditor/Features/<FeatureName>/`.
- Shared mutable UI state uses `@Observable @MainActor` classes owned with `@State`.
- SwiftUI views are extracted into focused `View` structs rather than computed view properties.
- User-facing warnings/status are quiet and inline unless destructive action requires confirmation.
- Tests use Swift Testing and `@testable import GPSMetadataEditor`.

### Integration Points
- `FileIntakeView` currently creates `FileIntakeViewModel` and embeds `CoordinateSelectionView()`, while `CoordinateSelectionView` privately owns `CoordinateSelectionViewModel`. Phase 3 needs to bridge these state owners so the batch command can see both selected files and selected coordinate.
- `FileIntakeViewModel.selectedFiles` is currently append-only immutable snapshots; applying write results will likely require replacing matching `SelectedMediaFile` values with updated snapshots.
- The Phase 3 writer should live behind a new metadata-writing service boundary, likely in a new feature folder or service folder, so future native Image I/O/AVFoundation backends can be added without rewriting UI flow.
- Batch writes should process files sequentially and keep security-scoped resource access active for the actual helper invocation.

</code_context>

<specifics>
## Specific Ideas

- Confirmation copy should be direct and cautionary, for example: "You will overwrite the GPS metadata in these files. The original metadata cannot be restored through this app."
- The visible command should be a compact utility-style **Apply Location** button, not a wizard flow.
- Phase 3 should prove the real no-Homebrew path by using the bundled helper during normal app execution.

</specifics>

<deferred>
## Deferred Ideas

- Optional backup preservation or overwrite preference can be revisited later if users want recoverability instead of destructive default writes.
- MOV and MP4 best-effort metadata writing belongs to Phase 4.
- Batch progress, cancellation, detailed result review, and persistent history belong to Phase 4.
- Native Image I/O or AVFoundation metadata backends remain future options behind the writer service boundary.

</deferred>

---

*Phase: 3-Core Metadata Writing*
*Context gathered: 2026-05-18T13:35:14+02:00*
