# Phase 3: Core Metadata Writing - Pattern Map

**Generated:** 2026-05-18
**Status:** Ready for planning

## Files Likely To Be Created Or Modified

| Planned File | Role | Closest Existing Analog | Notes |
|--------------|------|-------------------------|-------|
| `GPSMetadataEditor/Features/MetadataWriting/MetadataWriter.swift` | Writer protocol | `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift` | Keep the service fakeable and async; use value inputs/results. |
| `GPSMetadataEditor/Features/MetadataWriting/MetadataWriteResult.swift` | Result values | `GPSMetadataEditor/Features/FileIntake/Models/FileIntakeResult.swift` | Return status, message, diagnostics, and target URL/ID. |
| `GPSMetadataEditor/Features/MetadataWriting/ExifToolArgumentBuilder.swift` | Pure argument builder | `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift` | Keep logic testable without launching ExifTool. |
| `GPSMetadataEditor/Features/MetadataWriting/BundledExifToolResolver.swift` | Helper lookup | `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift` | Resolve only from `Bundle.main`; no PATH or system fallback. |
| `GPSMetadataEditor/Features/MetadataWriting/ProcessRunner.swift` | Async subprocess boundary | `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift` | Bridge callback termination into async result; capture stdout/stderr/status. |
| `GPSMetadataEditor/Features/MetadataWriting/ExifToolMetadataWriter.swift` | Concrete writer | `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift` | Reacquire security-scoped access around the helper invocation. |
| `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` | Batch state owner | Existing file | Add batch result application and compact summary state. |
| `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` | Apply command integration | Existing file | Own/pass coordinate view model, attach confirmation to Apply Location. |
| `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionView.swift` | Coordinate state injection | Existing file | Accept an injected `CoordinateSelectionViewModel` instead of private ownership only. |
| `GPSMetadataEditor.xcodeproj/project.pbxproj` | Target membership/resources | Existing explicit project file | Add new source/test files and bundled ExifTool helper resource. |
| `GPSMetadataEditorTests/*Metadata*Tests.swift` | Unit tests | Existing Swift Testing files | Test argument builder, fake process runner, writer mapping, and batch UI state. |

## Existing Patterns To Reuse

### Main-Actor UI State

`FileIntakeViewModel` and `CoordinateSelectionViewModel` are both `@Observable @MainActor` classes owned by SwiftUI `@State`. Phase 3 UI/batch state should preserve that pattern and keep subprocess objects out of observable models.

### Value Snapshots

`SelectedMediaFile`, `CoordinateSelection`, `FileResultStatus`, and `GPSStatus` are small value types/enums. Phase 3 should update rows by replacing `SelectedMediaFile` snapshots rather than introducing mutable model objects.

### Fakeable Services

`CoordinateSearchServicing` shows the right service seam for tests. Phase 3 should mirror this with `MetadataWriter` and `ProcessRunning` so normal unit tests do not depend on a real ExifTool binary.

### Security-Scoped Access

`FileIntakeService.classify(url:)` uses balanced `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`. The metadata writer should repeat that pattern around the actual ExifTool write, not just around preflight checks.

### Swift Testing

Existing tests use `Testing`, `@MainActor` suites where needed, and direct view-model/service calls. Phase 3 should add unit tests for core logic and keep real JPEG/HEIC helper writes as host-side smoke verification.

## Landmines

- Do not call `/usr/bin/env`, `/bin/sh`, `zsh`, `exiftool` by name, or PATH lookup. Use a bundle-resolved executable URL.
- Do not build a shell command string; every ExifTool flag and file path must be a separate `[String]` argument.
- Do not create ExifTool `_original` backups in Phase 3; locked decision D-01 requires destructive overwrite after confirmation.
- Do not write MOV/MP4 metadata in Phase 3; mixed video files should receive warning results.
- Do not introduce SwiftData, progress UI, cancellation UI, result drawer, or persistent history in this phase.
- Any new Swift file and test file must be added to `GPSMetadataEditor.xcodeproj/project.pbxproj`.

## Pattern Mapping Complete

Plans should reference this file, `03-RESEARCH.md`, and `03-CONTEXT.md` before implementation. The closest implementation analogs are the existing file-intake service/view-model split and the coordinate-search fakeable async service boundary.
