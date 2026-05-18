## RESEARCH COMPLETE

**Phase:** 3 - Core Metadata Writing
**Slice:** UI data flow and optional SwiftData boundary
**Researched:** 2026-05-18
**Confidence:** HIGH for SwiftUI data flow and Phase 3 non-goals; MEDIUM for SwiftData actor-boundary details because Apple forum material supplemented local SwiftData Pro guidance.

### Summary recommendation

Phase 3 should keep UI state in the existing SwiftUI/Observation style: `@Observable @MainActor` view models owned by `@State`, with `@Bindable` only where a child view needs bindings into mutable model properties. [CITED: AGENTS.md] [CITED: .agents/skills/swiftui-pro/references/data.md] [VERIFIED: Context7 / Apple SwiftUI docs: https://developer.apple.com/documentation/swiftui/bindable]

The minimal planning move is to lift `CoordinateSelectionViewModel` ownership from `CoordinateSelectionView` into `FileIntakeView`, or introduce one small `@MainActor @Observable` batch coordinator owned by the root view that can see both `FileIntakeViewModel.selectedFiles` and `CoordinateSelectionViewModel.selectedCoordinate`. [VERIFIED: codebase - `FileIntakeView.swift`, `CoordinateSelectionView.swift`] Do not build a result drawer, progress model, cancellation model, or persistent history in Phase 3; the phase context explicitly defers those to Phase 4. [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`]

SwiftData should be deferred for this phase. Phase 3 requirements cover applying one coordinate to eligible selected files, destructive confirmation, sequential writes, bundled ExifTool invocation, and structured per-file results; persistence requirements `PERSIST-01` through `PERSIST-04` are mapped to Phase 4. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/ROADMAP.md`] If the implementation nevertheless records anything persistent early, it must save correctness-sensitive writes explicitly and avoid moving `ModelContext` or `@Model` instances across actor boundaries. [VERIFIED: Context7 / Apple SwiftData docs: https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches] [CITED: .agents/skills/swiftdata-pro/references/core-rules.md] [CITED: Apple Developer Forums search result: https://developer.apple.com/forums/thread/805409]

### SwiftUI/SwiftData planning implications

- Use a root-owned `@State private var coordinateViewModel = CoordinateSelectionViewModel()` and pass it into `CoordinateSelectionView`, or use an equally small `BatchWriteViewModel` that receives immutable snapshots from both existing view models. The current `CoordinateSelectionView` privately owns its view model, so Phase 3 cannot enable/disable **Apply Location** from the selected coordinate without lifting that state. [VERIFIED: codebase - `CoordinateSelectionView.swift`] [VERIFIED: codebase - `CoordinateSelectionViewModel.swift`]

- Keep `FileIntakeViewModel` as the owner of selected file snapshots and result updates. `SelectedMediaFile` already has `latestResult` and `latestMessage`, `FileResultStatus` already has `pending`, `success`, `warning`, and `failure`, and `GPSStatus` already has `updated`; those are sufficient for Phase 3 table/detail/footer updates. [VERIFIED: codebase - `SelectedMediaFile.swift`, `FileResultStatus.swift`, `GPSStatus.swift`, `SelectedFilesTable.swift`, `FileDetailPanel.swift`]

- Add mutation through replacement, not in-place model objects. `SelectedMediaFile` is an immutable value snapshot, so a planner should add a targeted method such as `applyWriteResults(_:)` that maps existing rows by URL/ID and replaces only affected snapshots with new `gpsStatus`, `latestResult`, and `latestMessage` values. [VERIFIED: codebase - `SelectedMediaFile.swift`] [ASSUMED: recommended method name]

- Keep the Phase 3 result model small: a per-file result should carry URL or selected-file ID, `FileResultStatus`, user-facing message, optional diagnostic detail, and optional new `GPSStatus`. That satisfies `META-07` and maps directly to existing UI fields without a new review surface. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: codebase - existing result/status fields]

- Treat MOV and MP4 as warning rows in Phase 3. Mixed selections are allowed, but only JPEG and HEIC are written; video warnings should update `latestResult = .warning` and a concise `latestMessage` such as video metadata writing being deferred. [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`]

- Attach the destructive `confirmationDialog` to the **Apply Location** button or its immediate container, not at an unrelated root. Apple’s SwiftUI docs show `confirmationDialog` driven by `@State`, with a destructive action and explanatory message. [VERIFIED: Context7 / Apple SwiftUI docs: https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)-2s7pz] The local SwiftUI skill also says dialogs should attach to the triggering UI. [CITED: .agents/skills/swiftui-pro/references/navigation.md]

- The **Apply Location** command should be disabled unless `selectedFiles.isEmpty == false` and `selectedCoordinate != nil`. It should remain a compact utility command and should not introduce wizard navigation. [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`]

- Button labels must include text with any system image for accessibility, e.g. `Button("Apply Location", systemImage: "location.fill", action: ...)`; avoid icon-only buttons and avoid `onTapGesture()` for the command. [CITED: AGENTS.md] [CITED: .agents/skills/swiftui-pro/references/accessibility.md]

- Skip the UI-SPEC gate as requested by the user. The planner still needs to preserve the existing UI contract: compact apply command, blocking destructive confirmation, per-row latest result/message updates, and compact footer summary only. [VERIFIED: user request] [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`]

- Do not introduce SwiftData in Phase 3 unless the planner intentionally pulls in a Phase 4 persistence requirement. If used early, `@Query` belongs only inside SwiftUI views, service code should use `ModelContext.fetch(...)`, correctness-sensitive changes should call `try modelContext.save()`, and persisted result/history records should contain metadata only, never media contents. [CITED: .agents/skills/swiftdata-pro/references/core-rules.md] [VERIFIED: Context7 / Apple SwiftData docs: https://developer.apple.com/documentation/swiftdata/deleting-persistent-data-from-your-app] [VERIFIED: `.planning/REQUIREMENTS.md`]

### Testing and verification strategy

- Add `@MainActor` Swift Testing coverage for the UI state bridge: no files disables apply, no coordinate disables apply, both files and coordinate enable apply, aborting confirmation performs no write, and successful completion updates row snapshots plus footer summary. Existing tests use Swift Testing with `@MainActor` view-model tests. [VERIFIED: codebase - `GPSMetadataEditorTests/FileIntakeViewModelTests.swift`, `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift`]

- Add a fake metadata writer or fake batch coordinator for UI tests so view-model tests verify result mapping without launching ExifTool. Argument construction and real helper execution belong to the metadata-writing slice; this UI/data slice should depend on structured writer results. [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`]

- Add table/detail state tests for each Phase 3 status path: JPEG/HEIC success sets `.success` and `GPSStatus.updated`; MOV/MP4 sets `.warning`; missing/non-executable helper or write failure sets `.failure` with a user-facing message. [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`] [VERIFIED: codebase - status fields]

- Keep tests below the UI-SPEC level: no result drawer, no cancellation UI, no progress UI, no persistent history assertions. Those belong to Phase 4. [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`]

- Suggested host-side verification command after implementation: `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test`. The project has a `GPSMetadataEditorTests` target, but this command still needs host-side Xcode verification because prior Phase 2 host verification was waived. [VERIFIED: codebase - `GPSMetadataEditor.xcodeproj/project.pbxproj`] [VERIFIED: `.planning/STATE.md`]

### Risks/non-goals

- Risk: keeping `CoordinateSelectionViewModel` private inside `CoordinateSelectionView` will force brittle cross-view access or duplicate selected-coordinate state. Lift the owner instead. [VERIFIED: codebase]

- Risk: adding SwiftData now creates actor-boundary and save-order complexity while delivering no Phase 3 requirement. Defer it until Phase 4 persistence unless the planner explicitly scopes a small, isolated persistence preparatory task. [VERIFIED: `.planning/REQUIREMENTS.md`] [CITED: .agents/skills/swiftdata-pro/references/core-rules.md]

- Risk: trying to model progress/cancellation in Phase 3 will conflict with D-14. The only Phase 3 "progress" should be coarse running/complete state needed to disable duplicate writes and summarize completion. [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`]

- Non-goal: detailed result review, exportable reports, batch history, recent coordinates, MOV/MP4 writes, cancellable progress UI, and backup preference UI. [VERIFIED: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`] [VERIFIED: `.planning/ROADMAP.md`]

- Non-goal: third-party UI, persistence, or process-management frameworks. Project instructions forbid third-party frameworks without approval. [CITED: AGENTS.md]

### Source notes

- Context7 resolved `/websites/developer_apple_swiftui` and `/websites/developer_apple_swiftdata`; docs queried for `@Bindable`, `confirmationDialog`, and `ModelContext.save()` behavior. [VERIFIED: Context7]
- `bx web "site:developer.apple.com SwiftData ModelContext actor boundary ModelActor"` found Apple Developer documentation/forum results for `ModelActor`, model actor isolation, and passing Sendable values such as persistent identifiers across actors. [CITED: Apple Developer search results]
- Local source inspection confirmed current ownership and result fields in `FileIntakeView`, `FileIntakeViewModel`, `CoordinateSelectionView`, `CoordinateSelectionViewModel`, `SelectedMediaFile`, `FileResultStatus`, and `GPSStatus`. [VERIFIED: codebase]
- `.planning/config.json` has `workflow.nyquist_validation` set to `false`; this slice still recommends targeted tests because the project already has Swift Testing coverage. [VERIFIED: `.planning/config.json`]
