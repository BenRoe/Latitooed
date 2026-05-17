# Phase 2: Coordinate Selection - Pattern Map

**Generated:** 2026-05-17
**Status:** Ready for planning

## Files Likely To Be Created Or Modified

| Planned File | Role | Closest Existing Analog | Notes |
|--------------|------|-------------------------|-------|
| `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` | Main UI state and commands | `GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift` | Use `@Observable @MainActor`, service injection, derived detail/status state, no `ObservableObject`. |
| `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionView.swift` | Right-panel root view | `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` | Extract subviews, reuse `AppDesign`, avoid view-body business logic. |
| `GPSMetadataEditor/Features/CoordinateSelection/Models/*.swift` | Coordinate/search/map-style value types | `GPSMetadataEditor/Features/FileIntake/Models/*.swift` | Use small `Sendable`, `Equatable`, `Identifiable` value types. |
| `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift` | MapKit search boundary | `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift` | Keep MapKit interaction out of views; make fakeable for tests. |
| `GPSMetadataEditor/Features/CoordinateSelection/Views/*.swift` | Search/results/fields/map overlay subviews | `GPSMetadataEditor/Features/FileIntake/Views/*.swift` | One focused view per file where practical. |
| `GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift` | Integration point | Existing root split view | Replace `ReservedLocationPanel()` with coordinate selection view. |
| `GPSMetadataEditor.xcodeproj/project.pbxproj` | Target membership | Existing explicit project file references | Add every new app/test Swift file to correct groups and source build phases. |
| `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift` | State and validation tests | `GPSMetadataEditorTests/FileIntakeViewModelTests.swift` | Test validation, state transitions, search collapse, cancellation-safe behavior where fakeable. |

## Existing Patterns To Reuse

### Main-Actor View Model

`FileIntakeViewModel` pattern:

- `@Observable`
- `@MainActor`
- `final class`
- service stored with `@ObservationIgnored`
- commands mutate plain value state
- tests call view-model methods directly

Phase 2 should mirror this with `CoordinateSelectionViewModel`.

### Feature Folder Layout

Current structure:

- `Features/FileIntake/FileIntakeView.swift`
- `Features/FileIntake/FileIntakeViewModel.swift`
- `Features/FileIntake/Models/`
- `Features/FileIntake/Services/`
- `Features/FileIntake/Views/`

Phase 2 should create:

- `Features/CoordinateSelection/CoordinateSelectionView.swift`
- `Features/CoordinateSelection/CoordinateSelectionViewModel.swift`
- `Features/CoordinateSelection/Models/`
- `Features/CoordinateSelection/Services/`
- `Features/CoordinateSelection/Views/`

### Design Constants

Use `AppDesign.Spacing`, `AppDesign.Radius`, and `AppDesign.Layout`. Add new constants only when the coordinate panel needs stable dimensions for map overlay controls or field groups.

### Testing

Use Swift Testing in `GPSMetadataEditorTests`. Prefer unit tests for coordinate validation and view-model state. UI rendering and MapKit tile behavior need host/Xcode manual verification.

## Landmines

- `MapKit` SwiftUI APIs must be verified on macOS host/Xcode before implementation is marked fully verified.
- Manual numeric fields must allow invalid intermediate values while keeping parsing/validation outside SwiftUI view bodies.
- Search cancellation must not show a user-facing error.
- Any new Swift file must be added to `GPSMetadataEditor.xcodeproj/project.pbxproj`.
