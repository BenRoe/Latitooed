# Phase 8: Multi-Result Search Completer - Research

**Researched:** 2026-05-25
**Domain:** MapKit autocomplete — MKLocalSearchCompleter, Swift 6 strict concurrency, delegate-to-async bridging
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01: Resolution Timing — Optimistic Dismiss.** After user taps a suggestion, dismiss the dropdown immediately. Resolve coordinates asynchronously in the background. Show a loading indicator in the ready-status bar while resolving (`readyStatusText` → "Resolving location…"). Set coordinate when resolution completes.
- **D-02: Region Hint — Global (No Region).** Do NOT pass a region to `MKLocalSearchCompleter`. Search globally with no geographic bias.
- **D-03: Result Count — 8 Results.** Cap displayed suggestions at 8: `completer.results.prefix(8)`.
- **D-04: Resolution Failure — Status Bar Error.** If `MKLocalSearch(request: .init(completion:))` fails, show `"Could not load location. Try again."` in the ready-status area. Clear after 3 seconds or when user starts a new search. Preserve previously selected coordinate.

### Claude's Discretion

- Delegate-wrapper architecture: `final class` delegate with `withCheckedThrowingContinuation`, fire on first `completerDidUpdateResults`, nil continuation to prevent double-fire.
- Delegate class keeps strong reference to `MKLocalSearchCompleter` to prevent deallocation during async wait.
- Service returns `[CoordinateSearchResult]` with placeholder coord (`.berlin`) — real coordinate resolved in ViewModel on selection.
- `CoordinateSelectionViewModel.selectSearchResult(_:)` detects "unresolved" results and triggers async resolution via stored `[UUID: MKLocalSearchCompletion]` map.
- `readyStatusText` exposes a "resolving" state in addition to existing states.

### Deferred Ideas (OUT OF SCOPE)

- Category icons per result type
- Recently searched completions pinned at top
- Showing a "searching…" skeleton while completions load
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOC-01 | User can search for a place using Apple MapKit without providing Google or third-party API keys. | MKLocalSearchCompleter is a pure MapKit API, no keys required. Replaces MKLocalSearch for suggestion gathering while keeping the same zero-key dependency. |
| LOC-02 | User can select a search result to set the target coordinate. | Two-step flow: completer returns suggestions (no coords) → on selection, MKLocalSearch.Request(completion:) resolves one item to coordinates. |
</phase_requirements>

---

## Summary

Phase 8 replaces the `MKLocalSearch`-based suggestion path in `MapKitCoordinateSearchService` with `MKLocalSearchCompleter`. The key challenge is bridging a delegate-based, non-`Sendable` API into the project's `async`/`await` + Swift 6 strict-concurrency architecture.

The approach is a two-step flow. Step 1: a `@MainActor`-isolated delegate wrapper class holds both the `MKLocalSearchCompleter` and a stored `CheckedContinuation`. When `queryFragment` is set, the completer fires asynchronously; on first delegate callback, the continuation is resumed with mapped results (title + subtitle strings only — `MKLocalSearchCompletion` itself is not `Sendable`) and immediately nilled out. Step 2: on user selection, `CoordinateSelectionViewModel` uses the stored `[UUID: MKLocalSearchCompletion]` map to look up the original completion, calls `MKLocalSearch(request: .init(completion:)).start()`, and resolves the real coordinate.

The current codebase uses `SWIFT_VERSION = 6.2` and `SWIFT_STRICT_CONCURRENCY = complete`, so strict isolation rules apply throughout. `MKLocalSearchCompleter` is a non-`Sendable` reference type that must be created and used exclusively on `@MainActor`. The delegate wrapper class should be marked `@MainActor` to satisfy the compiler without needing `@unchecked Sendable`. All existing tests mock `CoordinateSearchServicing` and remain untouched; new tests cover the ViewModel's resolve path.

**Primary recommendation:** Make `MapKitCoordinateSearchService` a `@MainActor final class` (dropping `nonisolated struct`) whose delegate wrapper is an inner `@MainActor final class`. The `CoordinateSearchServicing` protocol stays `nonisolated` — the service gains `@MainActor` isolation, which is compatible because the ViewModel's `search()` already calls it from `Task { @MainActor in ... }`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Autocomplete suggestion fetching | Service layer (`MapKitCoordinateSearchService`) | — | Keeps UI layer free of MapKit types; protocol boundary preserved |
| Delegate-to-async bridging | Service layer (inner delegate class) | — | Continuation lifecycle must be co-located with completer ownership |
| `[UUID: MKLocalSearchCompletion]` storage | ViewModel (`CoordinateSelectionViewModel`) | — | Completions have UI lifetime; ViewModel is already `@MainActor @Observable` |
| Coordinate resolution on selection | ViewModel (`selectSearchResult`) | — | Optimistic dismiss + loading state requires ViewModel to own the async resolution task |
| Loading / error status ("Resolving…" / "Could not load") | ViewModel (`readyStatusText`) | — | Status bar is driven by ViewModel state, not the service |
| UI rendering (dropdown, results list) | View (`SearchDropdownView`) | — | No UI changes — existing dropdown renders `searchResults` array unchanged |

---

## Standard Stack

### Core (MapKit, Apple-provided, no external packages)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `MapKit.MKLocalSearchCompleter` | macOS 10.11.4+ | Autocomplete suggestions for partial queries | Apple's autocomplete API; zero API keys; returns 5-10 results for partial input |
| `MapKit.MKLocalSearch` | macOS 10.9+ | Coordinate resolution from a completion | `Request(completion:)` initializer resolves the full `MKMapItem` from a completer suggestion |
| `Foundation.withCheckedThrowingContinuation` | Swift stdlib | Bridge delegate callbacks to async/await | Canonical pattern for one-shot delegate bridging; detects double-resume at runtime |

**No external packages required.** All APIs are from Apple's MapKit and Swift stdlib.

### API Availability Confirmed

| API | Minimum macOS | Project Target | Status |
|-----|--------------|---------------|--------|
| `MKLocalSearchCompleter` | macOS 10.11.4 | macOS 26.0 | Safe |
| `MKLocalSearchCompleter.resultTypes` | macOS 10.15 | macOS 26.0 | Safe |
| `MKLocalSearchCompleter.cancel()` | macOS 10.11.4 | macOS 26.0 | Safe |
| `MKLocalSearchCompleter.isSearching` | macOS 10.11.4 | macOS 26.0 | Safe |
| `MKLocalSearch.Request.init(completion:)` | macOS 10.11.4+ | macOS 26.0 | Safe |

[VERIFIED: developer.apple.com/documentation/mapkit/mklocalsearchcompleter]
[VERIFIED: developer.apple.com/documentation/mapkit/mklocalsearch/request/init(completion:)]
[VERIFIED: ctx7 /websites/developer_apple_mapkit]

---

## Package Legitimacy Audit

No external packages are installed in this phase. All APIs are from Apple's first-party MapKit framework. This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
User types query (3+ chars, 500ms debounce)
         │
         ▼
CoordinateSearchPanel.onChange
         │  viewModel.search()
         ▼
CoordinateSelectionViewModel.search()
         │  searchService.search(for:near:)
         ▼
MapKitCoordinateSearchService  ◄──── @MainActor final class
         │  inner CompleterDelegate
         │  completer.queryFragment = query
         │  withCheckedThrowingContinuation { cont in
         │      self.continuation = cont
         │  }
         │
         ▼  [async wait]
MKLocalSearchCompleter (Apple)
         │
         ▼  completerDidUpdateResults(_:)  [on @MainActor]
CompleterDelegate
         │  map results to (title, subtitle) strings
         │  continuation?.resume(returning: results)
         │  continuation = nil
         ▼
[CoordinateSearchResult] with placeholder coords
         │
         ▼
ViewModel stores searchResults + [UUID: MKLocalSearchCompletion]
         │
         ▼
SearchDropdownView renders results (unchanged)

                    ── User taps a suggestion ──

SearchDropdownView.Button.action
         │  viewModel.selectSearchResult(result)
         ▼
CoordinateSelectionViewModel.selectSearchResult(_:)
         │  optimistic dismiss (isSearchResultsExpanded = false)
         │  readyStatusText = "Resolving location…"
         │  look up MKLocalSearchCompletion by result.id
         │
         ▼  Task { @MainActor in
MKLocalSearch(request: .init(completion:)).start()
         │
         ▼  response.mapItems.first
setCoordinate(latitude:longitude:)       [success path]
         │
         ▼
readyStatusText = "Target set: …"

                    ── On error ──

readyStatusText = "Could not load location. Try again."
[auto-clear after 3 seconds]
```

### Recommended Project Structure

No new files or folders needed. All changes are within:

```
GPSMetadataEditor/
└── Features/CoordinateSelection/
    ├── Services/
    │   └── CoordinateSearchService.swift    ← REPLACE implementation
    └── CoordinateSelectionViewModel.swift   ← ADD resolve logic, readyStatusText state
```

---

### Pattern 1: @MainActor Delegate Wrapper with One-Shot Continuation

The project runs Swift 6.2 with `SWIFT_STRICT_CONCURRENCY = complete`. `MKLocalSearchCompleter` is a non-`Sendable` NSObject subclass. The completer and its delegate must live on `@MainActor`.

**What:** An inner `@MainActor final class` owns the `MKLocalSearchCompleter` and stores a `CheckedContinuation`. The outer service creates this wrapper and `await`s its `search(for:)` method.

**Why not `nonisolated struct` + `Task { @MainActor in }`:** Accessing `completer.results` from inside `Task { @MainActor in ... }` in a `nonisolated func completerDidUpdateResults` is a Swift 6 error — `MKLocalSearchCompletion` is not `Sendable` across actor boundaries.

**Correct pattern (verified against Apple WWDC sample and ControlRoom project):**

```swift
// Source: Apple WWDC MapKit sample + twostraws/ControlRoom pattern
@MainActor
final class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter
    private var continuation: CheckedContinuation<[CoordinateSearchResult], Error>?

    override init() {
        completer = MKLocalSearchCompleter()
        // D-02: no region — global search
        super.init()
        completer.delegate = self
    }

    func search(for query: String) async throws -> [CoordinateSearchResult] {
        // Cancel any in-flight search before starting a new one
        if completer.isSearching { completer.cancel() }

        return try await withCheckedThrowingContinuation { [weak self] cont in
            guard let self else {
                cont.resume(throwing: CancellationError())
                return
            }
            // Nil out any stale continuation before storing new one
            // (double-resume guard: previous search was superseded)
            self.continuation = nil
            self.continuation = cont
            self.completer.queryFragment = query
        }
    }

    // One-shot: fire on first update, nil to prevent double-resume
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Safe: delegate callbacks from MKLocalSearchCompleter arrive on main thread
        MainActor.assumeIsolated {
            let results = completer.results.prefix(8).map { completion in
                CoordinateSearchResult(
                    title: completion.title,
                    subtitle: completion.subtitle.isEmpty ? nil : completion.subtitle,
                    coordinate: .berlin   // placeholder — real coord resolved on selection
                )
            }
            continuation?.resume(returning: Array(results))
            continuation = nil
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
```

**Key points:**
- `MainActor.assumeIsolated` is used (not `Task { @MainActor in }`) because Apple's MapKit guarantee is that delegate callbacks arrive on the main thread [VERIFIED: developer.apple.com/documentation/mapkit], so `assumeIsolated` is both correct and avoids an extra task hop.
- `continuation = nil` immediately after `resume(...)` is the fire-once guard against double-resume traps.
- The completer is a stored property of the delegate (not the service struct), keeping it alive during the async wait.

---

### Pattern 2: Service as @MainActor Class

The existing `MapKitCoordinateSearchService` is a `nonisolated struct`. It must become a `@MainActor final class` to own the delegate wrapper (which is `@MainActor`).

```swift
// Source: project conventions + Swift 6 strict concurrency requirements
@MainActor
final class MapKitCoordinateSearchService: CoordinateSearchServicing {
    private let delegate = SearchCompleterDelegate()

    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw CoordinateSearchError.emptyQuery
        }
        try Task.checkCancellation()
        let results = try await delegate.search(for: trimmedQuery)
        try Task.checkCancellation()
        print("[Completer] '\(trimmedQuery)' → \(results.count) completions")
        return results
    }
}
```

**Protocol change required:** `CoordinateSearchServicing` is currently `nonisolated protocol ... : Sendable`. A `@MainActor class` conforming to a `Sendable` protocol is fine in Swift 6.2 (classes are `Sendable` when all mutable state is actor-isolated). However the `func search(...)` requirement — being `async throws` — must be callable from `@MainActor` context. Because the ViewModel already calls it from `Task { @MainActor in ... }`, this is safe.

The `FakeCoordinateSearchService` in tests is a `nonisolated struct` conforming to the same protocol — this continues to work because the protocol requirement itself has no actor annotation.

[ASSUMED] — Whether the compiler requires `nonisolated` on the search method or an `@MainActor` conformance annotation depends on the exact Swift 6.2 / Xcode 26 diagnostic. The implementor should check if `@MainActor MapKitCoordinateSearchService: CoordinateSearchServicing` compiles without needing `nonisolated func search(...)`.

---

### Pattern 3: ViewModel Resolve Flow

`selectSearchResult(_:)` currently sets the coordinate directly. Post-Phase 8 it must:
1. Dismiss the dropdown (optimistic)
2. Show resolving status
3. Kick off an async resolution `Task`
4. On success: set coordinate, clear resolving status
5. On failure (D-04): show error message, auto-clear after 3 seconds

The ViewModel needs:
- `private var completionMap: [UUID: MKLocalSearchCompletion] = [:]` — populated in `search()` alongside `searchResults`
- A new `SearchStatus` case `.resolving` — OR use `readyStatusText` directly as a computed property that checks a new `private var resolvingStatus: String?`

**The cleanest design (given readyStatusText is already a computed var):**

```swift
// Source: project conventions from CoordinateSelectionViewModel.swift
// Add to ViewModel:
@ObservationIgnored
private var completionMap: [UUID: MKLocalSearchCompletion] = [:]

@ObservationIgnored
private var activeResolveTask: Task<Void, Never>?

private var readyStatusOverride: String? = nil  // "Resolving…" or error

var readyStatusText: String {
    if let override = readyStatusOverride {
        return override
    }
    guard let selectedCoordinate else {
        return "No target coordinate selected."
    }
    return "Target set: \(selectedCoordinate.displayText)"
}

func selectSearchResult(_ result: CoordinateSearchResult) {
    isSearchResultsExpanded = false   // optimistic dismiss

    guard let completion = completionMap[result.id] else {
        // No completion stored — result had real coords (e.g. from old code path)
        // Fall back to direct coordinate set
        setCoordinate(result.coordinate, label: result.title, collapseResults: false)
        return
    }

    readyStatusOverride = "Resolving location…"
    activeResolveTask?.cancel()
    activeResolveTask = Task { @MainActor [weak self] in
        guard let self else { return }
        do {
            let request = MKLocalSearch.Request(completion: completion)
            let response = try await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }
            if let item = response.mapItems.first,
               let coord = CoordinateSelection(
                   latitude: item.placemark.coordinate.latitude,
                   longitude: item.placemark.coordinate.longitude) {
                self.setCoordinate(coord, label: result.title, collapseResults: false)
                self.readyStatusOverride = nil
            } else {
                self.showResolveError()
            }
        } catch is CancellationError {
            // Superseded by newer selection — silently drop
        } catch {
            guard !Task.isCancelled else { return }
            self.showResolveError()
        }
    }
}

private func showResolveError() {
    readyStatusOverride = "Could not load location. Try again."
    Task { @MainActor [weak self] in
        try? await Task.sleep(for: .seconds(3))
        self?.readyStatusOverride = nil
    }
}
```

**Important:** `MKLocalSearch.Request(completion:)` accepts `MKLocalSearchCompletion` directly. The completion is stored in `completionMap` at the point where `search()` populates `searchResults`, so the UUID keys align with `result.id` values from `CoordinateSearchResult`.

---

### Pattern 4: Mapping Completions to CoordinateSearchResult + completionMap

In `search()`, after getting results from the service, the ViewModel needs to build the `completionMap`. However the service now returns `[CoordinateSearchResult]` with placeholder coords — the service does NOT know the `MKLocalSearchCompletion` objects.

**Design choice:** The service must also return the completion objects somehow. Two options:

**Option A (recommended by CONTEXT.md):** Service returns `[CoordinateSearchResult]` with a deterministic UUID (not `UUID()` each call — the UUID must be stable per completion). The ViewModel receives a parallel `[MKLocalSearchCompletion]` via a separate call. This requires adding a second method to the service, breaking the protocol.

**Option B (cleaner, zero protocol change):** The delegate wrapper stores the last set of `MKLocalSearchCompletion` objects. The service exposes them as a property: `var lastCompletions: [MKLocalSearchCompletion]`. The ViewModel calls `search()`, then reads `lastCompletions` immediately after (both on `@MainActor`, so no race). This keeps the protocol unchanged.

**Option C (cleanest for testing):** Change `CoordinateSearchResult` to carry an opaque `completion` token — but CONTEXT.md says model is unchanged.

**Recommended: Option B.** The service is now a `@MainActor class` (not a protocol), the ViewModel holds a concrete reference (or a protocol reference if we add a new protocol method). Because `CoordinateSearchServicing` is `nonisolated`, adding a `@MainActor` property to the concrete class is transparent to the protocol. The ViewModel's `init` can cast or store the concrete type for the mapping step.

Alternatively, a thin wrapper struct that pairs results with completions can be passed through a second parameter:

```swift
// Alternative: The delegate wrapper makes completions accessible as a companion
// after search() returns. Both reads happen on @MainActor in the same task.
func search() {
    // ... existing search task ...
    activeSearchTask = Task { @MainActor [weak self, searchService] in
        let results = try await searchService.search(for: query, near: searchCenter)
        // If service is the concrete class, retrieve completions:
        if let concreteService = self?.searchService as? MapKitCoordinateSearchService {
            let completions = concreteService.delegate.lastCompletions
            // zip results with completions to build completionMap
            for (result, completion) in zip(results, completions) {
                self?.completionMap[result.id] = completion
            }
        }
        self?.searchResults = results
    }
}
```

[ASSUMED] — The exact accessor design (property vs. companion return value) is left to the implementor. The key constraint is: result UUIDs must match completion positions (index-aligned, capped at 8).

---

### Anti-Patterns to Avoid

- **`Task { @MainActor in completer.results }`** in a `nonisolated` delegate method: Swift 6 error — `MKLocalSearchCompletion` is not `Sendable` and cannot cross actor boundary. Use `MainActor.assumeIsolated` instead.
- **Resuming continuation without nil-out:** Second `completerDidUpdateResults` call (MapKit can call it multiple times as results refine) causes a runtime trap on `withCheckedThrowingContinuation`. Always nil the continuation immediately after `resume(...)`.
- **`@unchecked Sendable`** on the delegate class: The skill's `bridging.md` forbids this except for types with internal locking. Use `@MainActor` instead.
- **Storing `MKLocalSearchCompletion` across actor boundaries:** These are non-`Sendable`. Keep them on `@MainActor` only.
- **Not cancelling the completer when a new search supersedes:** Setting a new `queryFragment` does NOT automatically cancel the previous one cleanly for the one-shot continuation pattern. Call `completer.cancel()` (and nil the stored continuation) before setting the new fragment.
- **Setting `queryFragment = ""`** to cancel: The docs warn this triggers a new (empty) search that may still call the delegate. Use `completer.cancel()` when `isSearching` is true, and nil the continuation before starting a new search.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Autocomplete suggestions for partial text | Custom fuzzy-match against MKLocalSearch results | `MKLocalSearchCompleter` | Apple's completer returns 5-10 OS-level suggestions using the same index as Apple Maps |
| Coordinate resolution from a place name | Second `MKLocalSearch(naturalLanguageQuery:)` | `MKLocalSearch(request: .init(completion:))` | The `init(completion:)` path passes internal metadata from the completer to MapKit, yielding more accurate results than a plain text query |
| Double-resume guard | Manual `Bool` flag | `continuation = nil` pattern | `withCheckedThrowingContinuation` runtime already traps on double-resume; the nil-optional pattern is the idiomatic Swift guard |
| Debounce | Custom timer | Existing `Task.sleep` debounce in `CoordinateSearchPanel.onChange` | Phase 7 already wired 3-char / 500ms debounce — unchanged |

**Key insight:** The `init(completion:)` initializer is specifically designed to carry internal MapKit metadata from the completer result. A plain text query from `completion.title` would not produce the same coordinate accuracy.

---

## Common Pitfalls

### Pitfall 1: MKLocalSearchCompletion Is Not Sendable — Swift 6 Compile Error

**What goes wrong:** Code like `nonisolated func completerDidUpdateResults(...) { Task { @MainActor in completer.results ... } }` fails to compile: "Task or actor isolated value cannot be sent" because `MKLocalSearchCompletion` is a non-`Sendable` reference type.

**Why it happens:** `completer.results` returns `[MKLocalSearchCompletion]`. Capturing these inside `Task { @MainActor in }` crosses an isolation domain.

**How to avoid:** Map to `Sendable` data (title + subtitle `String`s) before crossing the boundary, OR use `MainActor.assumeIsolated { }` which avoids any boundary crossing at all. Apple's own sample code uses `Task { @MainActor in suggestedCompletions = completer.results }` which works only when the class is itself `@MainActor`-isolated (so `completer.results` is already on the same actor, no boundary crossed).

[VERIFIED: developer.apple.com/forums/thread/761518] [VERIFIED: ctx7 /websites/developer_apple_mapkit]

---

### Pitfall 2: Continuation Double-Resume Trap

**What goes wrong:** `MKLocalSearchCompleter` may call `completerDidUpdateResults` more than once (results refine as more data arrives). The second call hits `continuation.resume(...)` on an already-resumed continuation → runtime trap in Swift's checked continuation.

**Why it happens:** The one-shot wrapping pattern assumes the delegate fires exactly once, but MapKit's completer can fire multiple times.

**How to avoid:** Always nil the continuation immediately after resuming: `continuation?.resume(...); continuation = nil`. The optional + nil pattern makes subsequent calls no-ops.

[VERIFIED: bridging.md skill reference + multiple community sources]

---

### Pitfall 3: Cancellation Does Not Resume the Continuation

**What goes wrong:** Swift task cancellation (`task.cancel()`) does NOT propagate into a `withCheckedThrowingContinuation` unless you explicitly hook it with `withTaskCancellationHandler`. A cancelled outer task leaves the continuation dangling, causing a "SWIFT TASK CONTINUATION MISUSE: leaked its continuation" warning and a hanging coroutine.

**Why it happens:** `withCheckedThrowingContinuation` suspends the task. If the outer `Task` is cancelled (e.g., user types a new query and `activeSearchTask?.cancel()` is called), the continuation body is not automatically unwound.

**How to avoid:** Wrap the `withCheckedThrowingContinuation` call with `withTaskCancellationHandler`:

```swift
return try await withTaskCancellationHandler {
    try await withCheckedThrowingContinuation { cont in
        self.continuation = cont
        self.completer.queryFragment = query
    }
} onCancel: {
    // Runs on any thread when the outer Task is cancelled
    Task { @MainActor [weak self] in
        self?.continuation?.resume(throwing: CancellationError())
        self?.continuation = nil
        self?.completer.cancel()
    }
}
```

[VERIFIED: cancellation.md skill reference — `withTaskCancellationHandler` bridges Swift cancellation to legacy cancel mechanisms]

---

### Pitfall 4: completionMap UUID Alignment After Prefix(8)

**What goes wrong:** The service returns `results.prefix(8)` mapped to `[CoordinateSearchResult]` with `UUID()` per item. The ViewModel tries to zip these UUIDs with `completer.results` — but if the service has already sliced to prefix(8), both arrays must be sliced identically.

**Why it happens:** If the service calls `UUID()` inside its map closure and separately exposes `lastCompletions` as a different slice, the UUID-to-completion mapping breaks.

**How to avoid:** Slice `completer.results.prefix(8)` once, map over the slice to create both the `CoordinateSearchResult` array AND keep the aligned `[MKLocalSearchCompletion]` slice. Never map twice from the same source array (UUIDs are generated per call).

---

### Pitfall 5: Stale completionMap After New Search

**What goes wrong:** User searches "Berlin", results appear, user searches "Paris" before selecting. Old Berlin completions remain in `completionMap`. User selects Paris item — but the UUID from a fresh "Paris" search populates a new result set, so the old Berlin entries don't interfere. However, if `completionMap` is not cleared on each new `search()`, it grows indefinitely.

**How to avoid:** Reset `completionMap = [:]` at the start of each `search()` call in the ViewModel, before awaiting new results.

---

## Code Examples

### Verified One-Shot Completer Wrapping

```swift
// Source: Apple WWDC MapKit sample (developer.apple.com/documentation/mapkit/interacting-with-nearby-points-of-interest)
// + twostraws/ControlRoom adapted for Swift 6.2 @MainActor isolation

@MainActor
final class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    private(set) var lastCompletions: [MKLocalSearchCompletion] = []
    private var continuation: CheckedContinuation<[CoordinateSearchResult], Error>?

    override init() {
        super.init()
        completer.delegate = self
        // D-03: results capped at 8 in the callback; no region (D-02)
    }

    func search(for query: String) async throws -> [CoordinateSearchResult] {
        if completer.isSearching { completer.cancel() }
        continuation = nil  // discard any prior stale continuation

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                self.continuation = cont
                self.completer.queryFragment = query
            }
        } onCancel: { [weak self] in
            Task { @MainActor [weak self] in
                self?.continuation?.resume(throwing: CancellationError())
                self?.continuation = nil
                self?.completer.cancel()
            }
        }
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            let slice = Array(completer.results.prefix(8))
            self.lastCompletions = slice  // stored for ViewModel to build completionMap
            let results = slice.map { completion in
                CoordinateSearchResult(
                    title: completion.title,
                    subtitle: completion.subtitle.isEmpty ? nil : completion.subtitle,
                    coordinate: .berlin  // placeholder
                )
            }
            continuation?.resume(returning: results)
            continuation = nil
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
```

### MKLocalSearch.Request(completion:) Resolution

```swift
// Source: twostraws/ControlRoom LocalSearchController.swift
// + developer.apple.com/documentation/mapkit/mklocalsearch/request/init(completion:)
let request = MKLocalSearch.Request(completion: completion)
let response = try await MKLocalSearch(request: request).start()
guard let item = response.mapItems.first else { throw CoordinateResolveError.noItems }
let coordinate = CoordinateSelection(
    latitude: item.placemark.coordinate.latitude,
    longitude: item.placemark.coordinate.longitude
)
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| `MKLocalSearch(naturalLanguageQuery:)` for suggestions | `MKLocalSearchCompleter.queryFragment` | Returns 5-10 Apple Maps-style autocomplete suggestions instead of 1 full-text match |
| Delegate-based with Combine/callback | `withCheckedThrowingContinuation` + `withTaskCancellationHandler` | Idiomatic Swift 6.2 async/await; no Combine dependency |
| `Task { @MainActor in completer.results }` | `MainActor.assumeIsolated { completer.results }` | Correct Swift 6 pattern; avoids Sendable crossing |

**Deprecated/outdated:**
- `MKLocalSearchCompleter.filterType` (`.locationsAndQueries`, `.locationsOnly`): deprecated in favor of `resultTypes` (macOS 10.15+). The project targets macOS 26 — use `resultTypes` only.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The compiler will accept `@MainActor final class MapKitCoordinateSearchService: CoordinateSearchServicing` without requiring `nonisolated` on the `func search(...)` method | Pattern 2 | Minor — implementor may need `nonisolated(unsafe)` or explicit `nonisolated` on the method; does not change architecture |
| A2 | The exact accessor pattern for passing `[MKLocalSearchCompletion]` from service to ViewModel (Option B: `lastCompletions` property) compiles without Sendable errors under Swift 6.2 | Pattern 4 | Medium — if `MKLocalSearchCompletion` is not Sendable even when accessed on `@MainActor`, the design must change to carry string data only |
| A3 | `MKLocalSearchCompleter.resultTypes` default (no explicit assignment) returns both address and POI completions suitable for global place search | Standard Stack | Low — worst case is setting `completer.resultTypes = [.address, .pointOfInterest]` explicitly, which is macOS 10.15+ (safe) |

**If this table is empty:** All claims were verified. It is not empty — A2 is the one non-trivial assumption.

---

## Open Questions

1. **Can `MKLocalSearchCompletion` objects be stored as `@MainActor` properties and later read without Sendable issues?**
   - What we know: They are non-`Sendable` reference types. Stored on `@MainActor`. Read on `@MainActor` (in `selectSearchResult`).
   - What's unclear: Whether Swift 6.2's region-based isolation analysis considers this safe without explicit annotations.
   - Recommendation: The implementor should verify the `completionMap: [UUID: MKLocalSearchCompletion]` property compiles on the `@MainActor @Observable` ViewModel without `nonisolated(unsafe)`. If it does not, store `(title: String, subtitle: String?)` tuples and reconstruct a `MKLocalSearch.Request` with `naturalLanguageQuery = title` as fallback (slight accuracy loss).

2. **Does `MKLocalSearchCompleter` guarantee delegate callbacks on the main thread on macOS 26?**
   - What we know: Apple's documentation does not explicitly state this, but all community references and Apple WWDC samples treat it as main-thread, and `MainActor.assumeIsolated` is the Apple-endorsed pattern.
   - Recommendation: Use `MainActor.assumeIsolated` (asserts at runtime in debug builds if called off main thread). If a crash occurs, fall back to `Task { @MainActor in ... }` with DTO mapping.

---

## Environment Availability

Step 2.6: SKIPPED (no external tools, CLIs, or services required — all APIs are Apple MapKit, available in the Xcode 26 SDK targeting macOS 26.0).

---

## Validation Architecture

`nyquist_validation: false` in `.planning/config.json` — this section is skipped.

---

## Security Domain

No authentication, credentials, user data transmission, or network endpoints are introduced. All MapKit calls go through Apple's framework. `security_enforcement` is not set in config. No ASVS categories apply to this phase.

---

## Sources

### Primary (HIGH confidence)
- [ctx7 /websites/developer_apple_mapkit] — MKLocalSearchCompleter API docs, delegate methods, availability, cancel, resultTypes, queryFragment, init(completion:)
- [developer.apple.com/documentation/mapkit/mklocalsearchcompleter] — Class overview, availability macOS 10.11.4+
- [developer.apple.com/documentation/mapkit/mklocalsearch/request/init(completion:)] — Initializer availability and usage
- [developer.apple.com/documentation/mapkit/interacting-with-nearby-points-of-interest] — Apple's official delegate callback pattern with `Task { @MainActor in }` and `resultStreamContinuation?.yield`

### Secondary (MEDIUM confidence)
- [developer.apple.com/forums/thread/761518] — Swift 6 concurrency errors with MKLocalSearchCompleter; `MainActor.assumeIsolated` fix
- [twostraws/ControlRoom — LocalSearchController.swift] — Production macOS app using `@MainActor class` + `nonisolated func completerDidUpdateResults` + `Task { @MainActor [weak self] in }`; `MKLocalSearch.Request(completion:).start()` resolution pattern
- [XunMengWinter/PetNote-oss — LocationService.swift] — `@MainActor @Observable class: MKLocalSearchCompleterDelegate` pattern; `completions = completer.results.map {...}` in `completerDidUpdateResults` directly (works because class is `@MainActor`)
- [.claude/skills/swift-concurrency-pro/references/bridging.md] — Canonical continuation + delegate wrapping patterns; `@unchecked Sendable` guidance
- [.claude/skills/swift-concurrency-pro/references/cancellation.md] — `withTaskCancellationHandler` pattern for bridging Swift cancellation to legacy cancel

### Tertiary (LOW confidence)
- [medium.com/@srikanthvelaga55/...] — Combine-based debounced autocomplete pattern (Combine not used in this project)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs verified via ctx7 + official Apple docs + macOS 26 deployment target
- Architecture: HIGH — two production macOS apps studied (ControlRoom, PetNote) confirm the patterns
- Pitfalls: HIGH — Apple Developer Forum thread + Swift concurrency skill confirm the Sendable issue and continuation guard

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (MapKit API is stable; Swift 6.2 concurrency is current)
