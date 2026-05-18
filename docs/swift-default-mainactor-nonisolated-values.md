# Swift Default MainActor and Pure Values

## Finding

With default MainActor isolation enabled, plain Swift declarations can become main-actor isolated unless marked otherwise. This affected pure value types and service boundaries used from tests and async writer code.

## Symptoms

Host `xcodebuild test` reported errors such as:

```text
Main actor-isolated property 'url' cannot be accessed from outside of the actor
Main actor-isolated static method 'failure(for:message:diagnosticDetail:)' cannot be called from outside of the actor
Main actor-isolated instance method 'executableURL()' cannot be called from outside of the actor
```

## Fix

Mark pure models, result values, protocols, and non-UI services as `nonisolated` when they are meant to cross actor boundaries:

```swift
nonisolated struct SelectedMediaFile: Identifiable, Hashable, Sendable { ... }
nonisolated protocol MetadataWriter: Sendable { ... }
nonisolated struct ExifToolArgumentBuilder: Sendable { ... }
```

For defaults that touch main-actor APIs, avoid using them in nonisolated initializer defaults. Use an explicit factory instead:

```swift
static func mainBundle() -> BundledExifToolResolver {
    BundledExifToolResolver(bundle: Bundle.main)
}
```

## Rule

For this project, UI views and `@Observable @MainActor` view models stay main-actor isolated. Pure app data and metadata/file/search services should be `nonisolated` when used from tests, async services, or protocol boundaries.
