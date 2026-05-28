# Agent guide for Swift and SwiftUI

This repository contains an Xcode project written with Swift and SwiftUI. Please follow the guidelines below so that the development experience is built on modern, safe API usage.

## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, and related frameworks. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.

## Core instructions

- Target iOS 26.0 or later. (Yes, it definitely exists.)
- Swift 6.2 or later, using modern Swift concurrency. Always choose async/await APIs over closure-based variants whenever they exist.
- SwiftUI backed up by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.

## Swift instructions

- `@Observable` classes must be marked `@MainActor` unless the project has Main Actor default actor isolation. Flag any `@Observable` class missing this annotation.
- All shared data should use `@Observable` classes with `@State` (for ownership) and `@Bindable` / `@Environment` (for passing).
- Strongly prefer not to use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` unless they are unavoidable, or if they exist in legacy/integration contexts when changing architecture would be complicated.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, for example `URL.documentsDirectory` to find the app’s documents directory, and `appending(path:)` to append strings to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`; always use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Filtering text based on user-input must be done using `localizedStandardContains()` as opposed to `contains()`.
- Avoid force unwraps and force `try` unless it is unrecoverable.
- Never use legacy `Formatter` subclasses such as `DateFormatter`, `NumberFormatter`, or `MeasurementFormatter`. Always use the modern `FormatStyle` API instead. For example, to format a date, use `myDate.formatted(date: .abbreviated, time: .shortened)`. To parse a date from a string, use `Date(inputString, strategy: .iso8601)`. For numbers, use `myNumber.formatted(.number)` or custom format styles.

## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` classes instead.
- Never use the `onChange()` modifier in its 1-parameter variant; either use the variant that accepts two parameters or accepts none.
- Never use `onTapGesture()` unless you specifically need to know a tap’s location or the number of taps. All other usages should use `Button`.
- Never use `Task.sleep(nanoseconds:)`; always use `Task.sleep(for:)` instead.
- Never use `UIScreen.main.bounds` to read the size of the available space.
- Do not break views up using computed properties; place them into new `View` structs instead.
- Do not force specific font sizes; prefer using Dynamic Type instead.
- Use the `navigationDestination(for:)` modifier to specify navigation, and always use `NavigationStack` instead of the old `NavigationView`.
- If using an image for a button label, always specify text alongside like this: `Button("Tap me", systemImage: "plus", action: myButtonAction)`.
- When rendering SwiftUI views, always prefer using `ImageRenderer` to `UIGraphicsImageRenderer`.
- Don’t apply the `fontWeight()` modifier unless there is good reason. If you want to make some text bold, always use `bold()` instead of `fontWeight(.bold)`.
- Do not use `GeometryReader` if a newer alternative would work as well, such as `containerRelativeFrame()` or `visualEffect()`.
- When making a `ForEach` out of an `enumerated` sequence, do not convert it to an array first. So, prefer `ForEach(x.enumerated(), id: \.element.id)` instead of `ForEach(Array(x.enumerated()), id: \.element.id)`.
- When hiding scroll view indicators, use the `.scrollIndicators(.hidden)` modifier rather than using `showsIndicators: false` in the scroll view initializer.
- Use the newest ScrollView APIs for item scrolling and positioning (e.g. `ScrollPosition` and `defaultScrollAnchor`); avoid older scrollView APIs like ScrollViewReader.
- Place view logic into view models or similar, so it can be tested.
- Avoid `AnyView` unless it is absolutely required.
- Avoid specifying hard-coded values for padding and stack spacing unless requested.
- Avoid using UIKit colors in SwiftUI code.

## SwiftData instructions

If SwiftData is configured to use CloudKit:

- Never use `@Attribute(.unique)`.
- Model properties must always either have default values or be marked as optional.
- All relationships must be marked optional.

## Project structure

- Use a consistent project structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Write unit tests for core application logic.
- Only write UI tests if unit tests are not possible.
- Add code comments and documentation comments as needed.
- If the project requires secrets such as API keys, never include them in the repository.
- If the project uses Localizable.xcstrings, prefer to add user-facing strings using symbol keys (e.g. helloWorld) in the string catalog with `extractionState` set to "manual", accessing them via generated symbols such as `Text(.helloWorld)`. Offer to translate new keys into all languages supported by the project.

## PR instructions

- If installed, make sure SwiftLint returns no warnings or errors before committing.

## Code Search

- Use the `ast-grep` skill for structural code searches, especially when looking for declarations, modifiers, protocol conformances, call patterns, or other syntax-aware matches. Use `rg` for simple text searches.

## Debug Communication

- While fixing bugs, keep step-by-step progress updates very short. Prefer terse status notes over explanations unless a decision or blocker needs context.

## Xcode MCP

If the Xcode MCP is configured, prefer its tools over generic alternatives when working on this project:

- `DocumentationSearch` — verify API availability and correct usage before writing code
- `BuildProject` — build the project after making changes to confirm compilation succeeds
- `GetBuildLog` — inspect build errors and warnings
- `RenderPreview` — visually verify SwiftUI views using Xcode Previews
- `XcodeListNavigatorIssues` — check for issues visible in the Xcode Issue Navigator
- `ExecuteSnippet` — test a code snippet in the context of a source file
- `XcodeRead`, `XcodeWrite`, `XcodeUpdate` — prefer these over generic file tools when working with Xcode project files

<!-- GSD:project-start source:PROJECT.md -->
## Project

**GPS Metadata Editor**

GPS Metadata Editor is a native macOS SwiftUI app for bulk-editing GPS metadata on local image files, with best-effort support for common video files. It lets a user select multiple files, choose a target coordinate through Apple MapKit search, map interaction, or manual latitude/longitude entry, and apply that location to all selected files in one batch. The app is for Mac users who want a self-contained visual tool and should not require Homebrew, terminal commands, Google API keys, or a separately installed ExifTool.

**Core Value:** Users can reliably apply a chosen GPS coordinate to many local media files without installing command-line dependencies.

### Constraints

- **Platform**: macOS first - the app is a native Mac utility, not iOS or web.
- **UI stack**: SwiftUI and MapKit - native UI and native Apple maps are core product assumptions.
- **Metadata backend**: Bundled ExifTool for v1 - chosen for broad write support and no external install requirement.
- **Distribution**: Outside the Mac App Store initially - reduces risk around bundled helper execution and sandbox review.
- **File access**: User-selected local files only - use file picker, drag and drop, and security-scoped access where required.
- **Video support**: Best effort - MOV and MP4 metadata behavior varies by container and consuming app.
- **Dependency policy**: No third-party Swift frameworks without explicit approval - follows repository guidance and keeps the app lightweight.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommendation
## Core Stack
| Layer | Choice | Rationale | Confidence |
|-------|--------|-----------|------------|
| App platform | macOS SwiftUI | Matches the desktop file-batch workflow and repository guidance. | High |
| Language/runtime | Swift 6.2+, modern Swift concurrency | Keeps file access, process execution, and UI state under strict concurrency rules. | High |
| UI architecture | SwiftUI with `@Observable` `@MainActor` view models | Aligns with project instructions and SwiftUI Pro data-flow guidance. | High |
| Map | MapKit for SwiftUI | Apple docs expose `Map`, `MapStyle`, map controls, and selectable map features for native map UX. | High |
| Place search | MapKit local search APIs | Avoids Google API keys and keeps the app native. | High |
| Persistence | SwiftData | Store recent batches, saved coordinates, app preferences, and optional history. Do not store media file contents. | Medium |
| Metadata backend | Bundled ExifTool invoked through `Process` | Best broad-format metadata writer; supports EXIF GPS and QuickTime-style GPS targets. | High |
| Native metadata fallback | Image I/O and AVFoundation service implementation later | Good future option for App Store or sandbox hardening, but weaker for v1 broad support. | Medium |
## SwiftUI Direction
- Use `NavigationSplitView` or a dense single-window utility layout with distinct file list, map/coordinate picker, and batch result surfaces.
- Keep body code small by extracting real subviews into separate `View` structs and files.
- Put shared UI state in `@Observable @MainActor` models owned by `@State`.
- Use `@Bindable` for editable state passed into child views.
- Use `Button("Label", systemImage: ..., action: ...)` for commands rather than tap gestures.
- Use numeric `TextField` bindings with `format: .number` for manual latitude and longitude.
- Prefer `confirmationDialog` for destructive overwrite/batch actions and attach it to the triggering control.
## SwiftData Direction
- `RecentCoordinate`: name, latitude, longitude, optional map item metadata.
- `BatchRun`: timestamp, target coordinate, counts for success/warning/failure.
- `BatchFileResult`: display name, original URL bookmark data if needed, file type, result status, message.
- `AppSetting`: explicit overwrite/backups preference if it should persist beyond a session.
- Save explicitly when correctness matters; do not rely on autosave timing.
- Keep `ModelContext` and model instances on the correct actor. Pass persistent identifiers or value snapshots across actor boundaries.
- Use explicit delete rules for relationships such as `BatchRun -> BatchFileResult`.
- Use `@Query` only in SwiftUI views; use `ModelContext.fetch(...)` in services.
- Avoid CloudKit assumptions for v1.
## ExifTool Direction
- Use ExifTool GPS composite tags where possible, e.g. GPS position writes that populate latitude, longitude, and refs together.
- Preserve originals by default or expose an explicit overwrite setting.
- Capture stdout, stderr, and exit status per file.
- Implement process execution as an async API with explicit cancellation propagation to the child process.
- Avoid unstructured per-file `Task {}` calls; v1 should run one cancellable sequential batch.
- For MP4/MOV, target QuickTime-compatible location metadata such as `Keys:GPSCoordinates` where appropriate.
- Surface video support as best effort because container structure and consuming app behavior vary.
## What Not To Use
- Do not require Homebrew ExifTool for end users.
- Do not make a local web app; browser file APIs do not fit reliable arbitrary metadata writes.
- Do not start with a pure Image I/O/AVFoundation backend if broad format support is v1's main promise.
- Do not introduce third-party Swift UI or persistence frameworks without explicit approval.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

| Skill | Description | Path |
|-------|-------------|------|
| swift-concurrency-pro | Reviews Swift code for concurrency correctness, modern API usage, and common async/await pitfalls. Use when reading, writing, or reviewing Swift concurrency code. | `.agents/skills/swift-concurrency-pro/SKILL.md` |
| swift-testing-pro | Writes, reviews, and improves Swift Testing code using modern APIs and best practices. Use when reading, writing, or reviewing projects that use Swift Testing. | `.agents/skills/swift-testing-pro/SKILL.md` |
| swiftdata-pro | Writes, reviews, and improves SwiftData code using modern APIs and best practices. Use when reading, writing, or reviewing projects that use SwiftData. | `.agents/skills/swiftdata-pro/SKILL.md` |
| swiftui-pro | Comprehensively reviews SwiftUI code for best practices on modern APIs, maintainability, and performance. Use when reading, writing, or reviewing SwiftUI projects. | `.agents/skills/swiftui-pro/SKILL.md` |
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

## Phase Closeout Reporting

After each phase, include a short manual verification section in the final response. It should give the user exact host-side steps to verify the phase, including any `xcodebuild` command, Xcode launch checks, and focused UI smoke checks relevant to that phase.

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **image-exif-gps** (1528 symbols, 5263 relationships, 35 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/image-exif-gps/context` | Codebase overview, check index freshness |
| `gitnexus://repo/image-exif-gps/clusters` | All functional areas |
| `gitnexus://repo/image-exif-gps/processes` | All execution flows |
| `gitnexus://repo/image-exif-gps/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
