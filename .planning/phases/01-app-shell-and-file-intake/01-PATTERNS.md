# Phase 1 - Pattern Map

**Phase:** 01 - App Shell and File Intake
**Generated:** 2026-05-15
**Codebase state:** No app source files or Xcode project exist yet.

## File Classification

| Planned File | Role | Data Flow | Closest Existing Analog | Required Pattern Source |
|--------------|------|-----------|--------------------------|-------------------------|
| `GPSMetadataEditor.xcodeproj/project.pbxproj` | Xcode project configuration | Build/test target membership | No analog found | AGENTS.md project structure and Swift 6.2/macOS guidance |
| `GPSMetadataEditor/GPSMetadataEditorApp.swift` | App entry | Creates main scene and root view | No analog found | `.planning/phases/01-app-shell-and-file-intake/01-RESEARCH.md` SwiftUI App Shell Direction |
| `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` | Primary feature view | View model state -> file intake UI | No analog found | `01-UI-SPEC.md` Layout, Component, Interaction, Accessibility contracts |
| `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` | Main-actor UI state | Picker/drop URLs -> intake service -> selected files/warnings | No analog found | `01-RESEARCH.md` Warning and Result State, Concurrency and File Access |
| `GPSMetadataEditor/Features/FileIntake/Models/*.swift` | Value types | Snapshot, kind, GPS status, result, warnings | No analog found | `01-CONTEXT.md` D-06 through D-21 |
| `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift` | Domain service | URLs -> accepted snapshots + rejected warnings | No analog found | `01-RESEARCH.md` File Type Classification |
| `GPSMetadataEditorTests/FileIntakeServiceTests.swift` | Unit tests | Fixture URLs/resource metadata -> intake result assertions | No analog found | `01-RESEARCH.md` Testing coverage list |
| `GPSMetadataEditorTests/FileIntakeViewModelTests.swift` | Unit tests | Service results -> view model selected files/warnings | No analog found | `01-CONTEXT.md` warning and duplicate decisions |

## No Analog Found

The repository currently contains planning artifacts only. Executors should not infer patterns from unrelated files. The source of truth for Phase 1 implementation is:

- `AGENTS.md` for Swift, SwiftUI, testing, and project-structure constraints.
- `.planning/phases/01-app-shell-and-file-intake/01-CONTEXT.md` for locked product decisions D-01 through D-21.
- `.planning/phases/01-app-shell-and-file-intake/01-RESEARCH.md` for SwiftUI API direction, file classification rules, concurrency boundaries, and tests.
- `.planning/phases/01-app-shell-and-file-intake/01-UI-SPEC.md` for visual, copywriting, and interaction contracts.

## Shared Patterns

| Pattern | Required Usage |
|---------|----------------|
| Main actor UI state | `@Observable @MainActor` view model owned by SwiftUI `@State`; no `ObservableObject`, `@Published`, `@StateObject`, or `@EnvironmentObject`. |
| File URL fidelity | Store and compare `URL` values directly; never parse file paths as command strings. |
| Security-scoped access | Use balanced `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` around attribute reads where needed. |
| Type classification | Prefer platform file type/UTType resource values, then fall back to case-insensitive extensions. |
| SwiftUI controls | Use labeled `Button`, `Label`, `Table` or native list/table controls, `ContentUnavailableView` where suitable, `foregroundStyle()`, and `clipShape(.rect(cornerRadius:))`. |
| Testing | Use Swift Testing for core logic and state transitions; keep UI tests out unless unit tests cannot prove behavior. |

## Pattern Mapping Complete

No existing implementation analogs are available. Plans must reference this file and the upstream contracts instead of claiming local code patterns exist.
