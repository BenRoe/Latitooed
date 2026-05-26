---
phase: 08-multi-result-search-completer
reviewed: 2026-05-26T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift
  - GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift
  - GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift
findings:
  critical: 4
  warning: 7
  info: 4
  total: 15
status: issues_found
---

# Phase 08: Code Review Report

**Reviewed:** 2026-05-26
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The submitted implementation introduces an `MKLocalSearchCompleter`-backed search service and a two-step resolve via `MKLocalSearch` in the ViewModel. The core idea is sound, but the implementation contains several correctness defects in the concurrency layer that will manifest as runtime crashes, dropped searches, and wrong-coordinate selections in production:

- The `CheckedContinuation` in `SearchCompleterDelegate` is leaked (never resumed) when a search is superseded, and is at risk of being resumed twice by repeated `completerDidUpdateResults` callbacks. Either failure mode is a documented `CheckedContinuation` runtime trap.
- Every `MapKit`-backed `CoordinateSearchResult` is constructed with `coordinate: .berlin` — i.e. the wrong coordinate. If the two-step resolve does not run (fallback path, future refactor, dropped completion entry), the user ends up at Berlin regardless of what they tapped.
- Result/`lastCompletions` alignment depends on `MKLocalSearchCompleter` calling `completerDidUpdateResults` exactly once before continuation resume — a property MapKit does **not** guarantee.
- Type-narrowing the injected `any CoordinateSearchServicing` to the concrete `MapKitCoordinateSearchService` to read `lastCompletions` defeats the dependency-injection seam the protocol exists to provide.

Additionally, multiple `print` statements remain in the production code path, and tests do not cover the new two-step resolve flow at all (only the fallback). The stale-response race test relies on `Task.yield()` rather than a deterministic delay, which makes it flaky.

## Critical Issues

### CR-01: Every MapKit search result has `coordinate: .berlin` (silent data corruption)

**File:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:48-54`

**Issue:** `completerDidUpdateResults` constructs `CoordinateSearchResult` with `coordinate: .berlin` for every completion. `MKLocalSearchCompletion` does not expose a coordinate (only `title`/`subtitle`), so the design *requires* a follow-up `MKLocalSearch` to resolve the real coordinate. However, the `CoordinateSearchResult.coordinate` field is non-optional and is consumed in at least one fallback path:

- `CoordinateSelectionViewModel.selectSearchResult` (line 105): when `completionMap[result.id]` returns nil, the code calls `setCoordinate(result.coordinate, ...)` — placing the user's pin in Berlin regardless of which result they tapped.

The `completionMap` can plausibly be empty in production whenever the cast on line 191 of the ViewModel fails (any non-`MapKitCoordinateSearchService` implementation, or a future decorator/wrapper), or when a new `search()` has cleared the map (line 161) between when results were shown and when the user tapped one. The fallback that exists "so all existing tests stay green" is silently wrong for the real service.

This is the central correctness bug of the phase: the model field is lying about its data.

**Fix:** Either (a) make `CoordinateSearchResult.coordinate` optional so the model honestly reflects "unresolved", and have the View/ViewModel handle nil explicitly, or (b) eliminate the fallback path entirely and require completion-map resolution for results produced by `MapKitCoordinateSearchService`. Recommended:

```swift
nonisolated struct CoordinateSearchResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String?
    let coordinate: CoordinateSelection?  // nil = unresolved, must resolve via MKLocalSearch
    // ...
}
```

And in the delegate:

```swift
let results = slice.map { completion in
    CoordinateSearchResult(
        title: completion.title,
        subtitle: completion.subtitle.isEmpty ? nil : completion.subtitle,
        coordinate: nil  // resolved later via two-step MKLocalSearch
    )
}
```

Then have `selectSearchResult` treat a missing completion entry as an explicit programmer error rather than silently substituting Berlin.

---

### CR-02: `CheckedContinuation` is leaked (never resumed) when `search` is called twice

**File:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:25-41`

**Issue:** On line 26-27, an in-flight search is cancelled by calling `completer.cancel()` and setting `continuation = nil`. The previous continuation is *dropped on the floor* — never resumed. `CheckedContinuation` requires exactly one resume call; failing to resume triggers a Swift runtime warning ("SWIFT TASK CONTINUATION MISUSE: leaked its continuation!") and the awaiting Task hangs forever.

Even worse: `completer.cancel()` does not appear to invoke `completer(_:didFailWithError:)` with a `CancellationError` synchronously — and even if it did, `continuation` has already been niled out, so the delegate callback would silently no-op.

This bug is reachable in normal use: any user who types a second query before the first one resolves triggers the leak.

**Fix:** Resume the previous continuation with `CancellationError` before niling it:

```swift
func search(for query: String) async throws -> [CoordinateSearchResult] {
    if completer.isSearching { completer.cancel() }
    if let pending = continuation {
        pending.resume(throwing: CancellationError())
    }
    continuation = nil
    // ...
}
```

The same fix should be applied to the cancellation handler on line 34-40 — it resumes-then-nils, which is correct, but the `Task { @MainActor ... }` hop means the cancellation is delivered asynchronously and may race a `completerDidUpdateResults` callback that already resumed and nil'd, producing a double-resume (see CR-03).

---

### CR-03: `completerDidUpdateResults` is called repeatedly; resuming the continuation twice traps

**File:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:45-57`

**Issue:** `MKLocalSearchCompleter` invokes `completerDidUpdateResults` whenever `queryFragment` produces a new result set — which can happen multiple times for a single search (debounced refinement). The current code resumes `continuation` on the first call and nils it. Subsequent callbacks find `continuation == nil` (no-op for resume), but they DO mutate `lastCompletions` (line 46-47).

Two failure modes flow from this:

1. **Index misalignment** (the bug the inline comment on line 193 claims to solve, but does not): the `results` array passed to the awaiting ViewModel comes from the *first* delegate callback. `lastCompletions`, read later by the ViewModel via `concreteService.lastCompletions`, may have been overwritten by a *subsequent* delegate callback with a different ordering. The `zip(results, completions)` in the ViewModel will then bind result-id → wrong-completion. User taps "Berlin, Germany" and resolves to "Berlin, NH".

2. **Double-resume race**: if the cancellation handler's `Task { @MainActor in ... continuation?.resume(throwing: CancellationError()) ... }` is scheduled between two delegate callbacks, you can end up with a window where the first callback already resumed and nil'd, the cancellation Task runs (no-op on nil), then a second callback arrives — but a fresh `search` call has reassigned `continuation` to a NEW continuation, and the stale second callback resumes the *new* continuation with stale results. The new caller gets the old query's results.

**Fix:** Snapshot completions *with* their results at resume time, atomically:

```swift
func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    guard let cont = continuation else { return }  // ignore later updates
    let slice = Array(completer.results.prefix(8))
    lastCompletions = slice
    let results = slice.map { /* ... */ }
    continuation = nil
    cont.resume(returning: results)
}
```

Better still: change the protocol to return both results and completions as a tuple/struct so the ViewModel does not have to reach into `lastCompletions` on the concrete type at all (see CR-04).

---

### CR-04: Type-narrowing `any CoordinateSearchServicing` to read `lastCompletions` breaks DI

**File:** `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift:191-196`

**Issue:** The ViewModel injects `searchService: any CoordinateSearchServicing` but then does `if let concreteService = searchService as? MapKitCoordinateSearchService` to fish out `lastCompletions`. This:

- Defeats the purpose of the protocol — `FakeCoordinateSearchService` cannot exercise the completion-map path, so the new behavior is completely untested.
- Silently degrades any future replacement of the concrete service (decorators, alternate implementations, even a mock subclass). The cast fails, `completionMap` stays empty, and every selection falls back to the broken `.berlin` path (CR-01).
- Couples the ViewModel to a class identity it shouldn't know about.
- Reads `lastCompletions` *after* `await`, so the value is racy if `MKLocalSearchCompleter` issues additional callbacks between resume and the read (CR-03).

**Fix:** Return completions alongside results through the protocol, so the ViewModel never has to type-check:

```swift
struct CoordinateSearchResults: Sendable {
    let results: [CoordinateSearchResult]
    // opaque token the ViewModel hands back during select; service knows how to resolve
    let resolvers: [UUID: CoordinateResolver]
}

protocol CoordinateSearchServicing: Sendable {
    func search(for query: String, near center: CoordinateSelection) async throws -> CoordinateSearchResults
    func resolve(_ token: CoordinateResolver) async throws -> CoordinateSelection
}
```

Then the fake can populate `resolvers` deterministically and the test suite actually covers the resolve flow.

---

## Warnings

### WR-01: Debug `print` statements left in production code

**File:**
- `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:82`
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift:183, 185, 199, 203, 205, 213`

**Issue:** Seven `print(...)` statements remain in the production code path (`[Completer]` and `[Search]` traces). These leak to stdout on every search in shipping builds, are not gated by `#if DEBUG`, and were almost certainly added for debugging the concurrency code. They will clutter Console.app for end users and confuse future maintainers about whether they are intentional logging.

**Fix:** Remove all `print` calls, or replace with `Logger` (`os.Logger`) gated to `.debug` level:

```swift
import os
private let log = Logger(subsystem: "com.example.app", category: "CoordinateSearch")
// ...
log.debug("'\(trimmedQuery)' → \(results.count) completions")
```

---

### WR-02: Deinit on `@MainActor` class accesses isolated state without isolation guarantee

**File:** `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift:51-55`

**Issue:** `deinit` is not `@MainActor`-isolated even on a `@MainActor` class. Reading `activeSearchTask`, `activeResolveTask`, `activeErrorClearTask` from `deinit` is currently allowed by Swift only because these are `Task` types (Sendable) and the compiler has special-case relaxations. Under Swift 6 strict concurrency this will warn or error depending on the property type. The `cancel()` calls are fine on Sendable `Task`, but reading the optionals from a non-isolated context is fragile and depends on deinit-on-last-release semantics.

**Fix:** This is mostly safe today but document the invariant or use the explicit Swift 6 pattern:

```swift
deinit {
    // Tasks are Sendable; cancel is safe from any context.
    // ObservationIgnored properties are not Observation-tracked, so no isolation hop needed.
    activeSearchTask?.cancel()
    activeResolveTask?.cancel()
    activeErrorClearTask?.cancel()
}
```

Verify under `-strict-concurrency=complete` and add `// swift(6) deinit-from-isolated-context` comment if needed, or move cleanup into an explicit `func tearDown()` call from the View's `.onDisappear`.

---

### WR-03: Resolve task does not race-check against newer searches

**File:** `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift:102-138`

**Issue:** `selectSearchResult` starts an `activeResolveTask` and cancels any previous one. But it does not bump a generation counter, and it does not check whether a *new search* (not a new selection) has invalidated the completion before resolve completes. Sequence:

1. User searches "Berlin" → results shown, completionMap populated.
2. User taps "Berlin, Germany" → resolve task starts (MKLocalSearch in flight).
3. User edits searchQuery to "Paris" and calls `search()` → line 161 clears `completionMap`, but `activeResolveTask` is NOT cancelled.
4. Resolve completes with Berlin's coordinate.
5. `self.setCoordinate(coord, label: "Berlin, Germany", ...)` — overwrites whatever the user is currently doing in the Paris search.

**Fix:** Cancel `activeResolveTask` in `search()` and `clearSearch()`:

```swift
func search() {
    activeResolveTask?.cancel()
    activeResolveTask = nil
    readyStatusOverride = nil  // already done
    completionMap = [:]
    // ...
}
```

Also consider bumping a resolve generation to defend against the cancel-but-task-already-past-checkCancellation race.

---

### WR-04: `activeErrorClearTask` not cancelled by `clearSearch()` or new selection

**File:** `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift:231-245`

**Issue:** `clearSearch()` sets `readyStatusOverride = nil` but does NOT cancel `activeErrorClearTask`. If a resolve error fired the 3-second clear timer, and the user then performs a successful selection that sets a new `readyStatusOverride`, the stale clear task can still fire and wipe out the new override 3 seconds later.

Concretely:
1. Resolve fails → `readyStatusOverride = "Could not load location..."`, sleep(3s) task scheduled.
2. User calls `selectSearchResult` again at t=2s → resolve starts, `readyStatusOverride = "Resolving location…"`.
3. At t=3s, stale clear task fires, sets `readyStatusOverride = nil` — wiping "Resolving location…".

The `activeErrorClearTask?.cancel()` exists on line 238 but is only called inside `showResolveError()`, not on the success path.

**Fix:** Cancel `activeErrorClearTask` whenever `readyStatusOverride` is intentionally cleared or replaced — in `clearSearch()`, in `search()`, and in the resolve success branch on line 126:

```swift
self.setCoordinate(coord, label: result.title, collapseResults: false)
self.activeErrorClearTask?.cancel()
self.activeErrorClearTask = nil
self.readyStatusOverride = nil
```

---

### WR-05: Stale-response race test uses `Task.yield()` instead of a deterministic delay

**File:** `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift:257-273, 351-361`

**Issue:** `DelayedCoordinateSearchService` issues `await Task.yield()` only when `query == "Berlin"`. The test then triggers `search()` for Berlin, immediately followed by `search()` for Paris, then waits 50ms. The assertion is that Paris wins. This relies on `Task.yield()` actually yielding scheduling such that the Berlin Task suspends — but `Task.yield()` is a hint, not a guarantee, and on a single-core test runner under contention the ordering can flip. This test will be flaky in CI.

Additionally, the test does not verify that `searchStatus`, `completionMap`, or `searchGeneration` were correctly handled — it only checks `searchResults.map(\.title)`.

**Fix:** Use a `CheckedContinuation`-based barrier so the test deterministically blocks Berlin until Paris is dispatched:

```swift
final class GatedSearchService: CoordinateSearchServicing {
    let resultsByQuery: [String: [CoordinateSearchResult]]
    let berlinGate: AsyncStream<Void>.Continuation
    let berlinReady: AsyncStream<Void>
    // ... await berlinReady before returning Berlin results, signal from test
}
```

Or simpler: `try await Task.sleep(for: .milliseconds(20))` for Berlin so the ordering is unambiguous.

---

### WR-06: `MapKitCoordinateSearchService.lastCompletions` has no documented happens-before relationship with `search(for:near:)` return

**File:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:65-85, 69-71`

**Issue:** The ViewModel reads `concreteService.lastCompletions` after `await searchService.search(for:...)` returns, assuming it was populated by the same delegate callback that resumed the continuation. This is *currently* true (lines 47, 55 in delegate are sequential) but it is an undocumented invariant on a mutable property exposed publicly. Any future change that, e.g., resumes the continuation before assigning `lastCompletions`, or makes `lastCompletions` non-synchronous, silently breaks the ViewModel.

The property is also writable internally and could be mutated by additional delegate callbacks before the ViewModel reads it (CR-03).

**Fix:** Make completions part of the return value (see CR-04). Until then, mark the property's contract explicitly with a doc comment and a stored-snapshot copy:

```swift
/// Completions that were returned by the most recent successful `search`.
/// Index-aligned with the `[CoordinateSearchResult]` returned by that same call.
/// **Must be read synchronously after** `search` returns, before invoking `search` again.
var lastCompletions: [MKLocalSearchCompletion] { ... }
```

---

### WR-07: Cancellation handler's `Task { @MainActor [weak self] in ... }` cancels a *future* search

**File:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:34-40`

**Issue:** The `onCancel` handler schedules a `Task` to hop to MainActor and call `self?.completer.cancel()`. By the time that task runs, the awaiting call site may have already returned (cancellation delivered after resume) AND a new `search` may have started. Calling `completer.cancel()` on a freshly-started new search aborts it before its delegate ever fires, while leaving the new continuation suspended forever (combined with CR-02, this means the new caller hangs).

**Fix:** Make the cancellation handler check generation/identity before cancelling, or queue the cancel onto a serial main-actor executor that respects ordering. Simpler: don't `await`-hop in the cancellation handler — capture an unowned/weak reference and call `cancel()` synchronously from any actor context (MKLocalSearchCompleter.cancel is thread-safe per Apple docs, but verify before relying on this).

```swift
} onCancel: { [weak self] in
    // Capture a snapshot so we cancel only the search we started
    let snapshotID = self?.currentSearchID
    Task { @MainActor [weak self] in
        guard let self, self.currentSearchID == snapshotID else { return }
        self.continuation?.resume(throwing: CancellationError())
        self.continuation = nil
        self.completer.cancel()
    }
}
```

---

## Info

### IN-01: Test suite does not cover the new two-step resolve path

**File:** `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift` (entire file)

**Issue:** The new code in `selectSearchResult` (lines 102-138 of the ViewModel) — starting a resolve Task, setting "Resolving location…", awaiting `MKLocalSearch`, handling failure, scheduling the 3-second clear — is not exercised by any test. The only test for `selectSearchResult` (`selectingSearchResultWithoutCompletionMapEntryFallsBackToDirectSet`, line 301) explicitly exercises the *fallback* path and asserts the comment "completionMap is empty".

There is no test for:
- Successful resolve flow (would require injecting a fake resolver — see CR-04).
- Failed resolve → `"Could not load location. Try again."` → 3s clear.
- Resolve task superseded by new resolve (`activeResolveTask?.cancel()` path on line 113).
- Race between resolve and new `search()` (WR-03).

**Fix:** After implementing CR-04 (resolver in protocol), add tests for each of these flows.

---

### IN-02: Magic number `8` for completion prefix without justification

**File:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:46`

**Issue:** `completer.results.prefix(8)` caps results at 8. No constant, no comment explaining why 8 (vs 5, vs 10, vs all). Plan documents may justify this but the code doesn't.

**Fix:**

```swift
private static let maxCompletionsShown = 8  // UX cap from phase 08 plan
let slice = Array(completer.results.prefix(Self.maxCompletionsShown))
```

---

### IN-03: Inline comments reference "Pitfalls" and "D-XX" tags from the plan that future maintainers won't have context for

**File:**
- `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:22, 43-44`
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift:103, 161, 189, 197, 238`

**Issue:** Comments like `// D-02: no region — global search (A3: default resultTypes is fine)`, `// Pitfall 5: clear stale entries before new search`, `// Build completionMap from MapKitCoordinateSearchService.lastCompletions (Option B)` reference identifiers from the phase 08 plan. Once the plan is archived these references become noise. Worse, they describe the *plan* not the *code* — a reader can't understand them without `git log` archaeology.

**Fix:** Replace with substantive comments that explain the code on its own terms:

```swift
// No region biasing: surface global results so users in any locale can find places.
// Default resultTypes (.address | .pointOfInterest | .query) is appropriate.
```

```swift
// Clear before each new search: stale completions belong to a prior query and
// would let an obsolete tap resolve to the wrong place.
completionMap = [:]
```

---

### IN-04: `nonisolated protocol` and `nonisolated enum` use unusual syntax

**File:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift:4, 8`

**Issue:** `nonisolated protocol CoordinateSearchServicing: Sendable` and `nonisolated enum CoordinateSearchError` apply `nonisolated` to type declarations. This is valid Swift 6 syntax but redundant: a `Sendable` protocol's requirements are already non-isolated by default, and an `enum` with `Sendable` cases has no isolation. The `nonisolated` keyword on the type adds no semantics here and may confuse readers into thinking there's actor isolation to override.

**Fix:** Drop the `nonisolated` keyword unless there's a specific compiler diagnostic it suppresses:

```swift
protocol CoordinateSearchServicing: Sendable {
    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult]
}

enum CoordinateSearchError: Error, Equatable, Sendable {
    case emptyQuery
}
```

If the keyword was added to silence a Swift 6 diagnostic in callers, document why with an inline comment.

---

_Reviewed: 2026-05-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
