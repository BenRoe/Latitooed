---
phase: 08-multi-result-search-completer
fixed_at: 2026-05-26T00:00:00Z
review_path: .planning/phases/08-multi-result-search-completer/08-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 11
skipped: 0
status: all_fixed
---

# Phase 08: Code Review Fix Report

**Fixed at:** 2026-05-26
**Source review:** `.planning/phases/08-multi-result-search-completer/08-REVIEW.md`
**Iteration:** 1
**Scope:** critical + warning (Info findings IN-01..IN-04 deferred to the developer per fix_scope)

**Summary:**

- Findings in scope: 11 (4 critical + 7 warning)
- Fixed: 11
- Skipped: 0

**Verification status:** Tier 1 (re-read + visual inspection) only. The Linux dev VM has no Swift toolchain (`swift`/`swiftc` not present) and `xcodebuild` is macOS-only, so Tier 2 syntax/compile checks could not be run. **The macOS host must run the `GPSMetadataEditorTests` bundle to confirm the suite stays green before merging.** Several fixes change semantics (protocol shape, optional coordinate, new error case) and are flagged below as `requires human verification`.

## Fixed Issues

### CR-02: `CheckedContinuation` is leaked (never resumed) when `search` is called twice

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift`
**Commit:** `ad24e22`
**Applied fix:** The prior continuation is now resumed with `CancellationError()` before reassignment in `SearchCompleterDelegate.search(for:)`. This kills the `SWIFT TASK CONTINUATION MISUSE: leaked its continuation!` runtime trap. Status: **fixed** (narrow, mechanical fix).

---

### CR-01: Every MapKit search result has `coordinate: .berlin` (silent data corruption)

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/Models/CoordinateSearchResult.swift`, `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift`, `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift`, `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift`
**Commit:** `0996423` (bundled — see note below)
**Applied fix:** `CoordinateSearchResult.coordinate` is now `Optional<CoordinateSelection>` (nil for unresolved MapKit completions). The MapKit delegate produces results with `coordinate: nil`, so a missing resolver no longer silently substitutes `.berlin`. `selectSearchResult` drops the selection when neither a resolver nor a pre-resolved coordinate is available. Status: **fixed: requires human verification** (semantic change to the model — confirm all UI surfaces that consume `searchResults` still compile and behave correctly).

---

### CR-03: `completerDidUpdateResults` is called repeatedly; resuming the continuation twice traps

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift`
**Commit:** `0996423` (bundled)
**Applied fix:** `completerDidUpdateResults` now snapshots `completer.results` once, builds both the `results` array and the matching `resolvers` dictionary atomically in the same scope, resumes the continuation, and ignores all later callbacks (`guard let cont = continuation else { return }` at the top). The index-misalignment race and the double-resume race are both eliminated. Status: **fixed: requires human verification** (concurrency semantics).

---

### CR-04: Type-narrowing `any CoordinateSearchServicing` to read `lastCompletions` breaks DI

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift`, `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift`, `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift`
**Commit:** `0996423` (bundled)
**Applied fix:** Introduced a `CoordinateSearchResults` bundle struct and an opaque `CoordinateResolver` enum (cases `.immediate(CoordinateSelection)` and `.mapKitCompletion(MKLocalSearchCompletionBox)`). The protocol now returns `CoordinateSearchResults` from `search` and adds a `resolve(_:)` method, so the view-model never reaches into the concrete service. The `as? MapKitCoordinateSearchService` cast and the mutable `lastCompletions` side-channel are gone. Fakes can now exercise the resolve flow uniformly. Status: **fixed: requires human verification** (protocol-level redesign).

---

### WR-01: Debug `print` statements left in production code

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift`, `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift`
**Commit:** `0996423` (bundled — the view-model rewrite that addresses CR-04 also removed all `print` calls in the same edit)
**Applied fix:** All eight `[Completer]`/`[Search]` `print(...)` calls removed. No `os.Logger` substitution was added — the surrounding code now relies on tests for behavioral verification rather than runtime tracing. If logging is wanted, follow up with a `Logger` instance gated to `.debug`. Status: **fixed**.

---

### WR-02: Deinit on `@MainActor` class accesses isolated state without isolation guarantee

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift`
**Commit:** `0996423` (bundled — addressed inside the view-model rewrite)
**Applied fix:** Added a doc comment to `deinit` explaining the invariant: `Task` is `Sendable` so `cancel()` is safe from any context, and `ObservationIgnored` properties are not Observation-tracked so no isolation hop is required. The structural pattern recommended in the review is now in place. If a future Swift 6 strict-concurrency build complains, the comment also flags the location for the developer to convert to an explicit `tearDown()` from `.onDisappear`. Status: **fixed**.

---

### WR-03: Resolve task does not race-check against newer searches

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift`
**Commit:** `0996423` (bundled)
**Applied fix:** `search()` now cancels `activeResolveTask` (and clears `activeErrorClearTask`) at the top, alongside the existing `activeSearchTask` cancel. `clearSearch()` does the same. A late resolve from a prior search can no longer overwrite a selection from the new one. Status: **fixed: requires human verification** (cross-method concurrency invariant).

---

### WR-04: `activeErrorClearTask` not cancelled by `clearSearch()` or new selection

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift`
**Commit:** `0996423` (bundled)
**Applied fix:** `activeErrorClearTask?.cancel()` is now called in every place that intentionally replaces or clears `readyStatusOverride`: at the top of `selectSearchResult` (before setting "Resolving location…"), in the resolve success branch (before setting nil), in `search()`, and in `clearSearch()`. A stale 3-second clear timer can no longer wipe a fresh override. Status: **fixed: requires human verification** (timing-sensitive).

---

### WR-05: Stale-response race test uses `Task.yield()` instead of a deterministic delay

**Files modified:** `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift`
**Commit:** `0996423` (bundled — fake service conforms to the new protocol shape and is rewritten in the same pass)
**Applied fix:** `DelayedCoordinateSearchService` now uses `try await Task.sleep(for: .milliseconds(20))` for the Berlin branch instead of `await Task.yield()`. The 20ms suspension guarantees the Paris call below is dispatched while Berlin is still blocked, removing the flaky CI ordering. Status: **fixed**.

---

### WR-06: `lastCompletions` has no documented happens-before relationship with `search` return

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift`
**Commit:** `0996423` (bundled)
**Applied fix:** The `lastCompletions` property is gone entirely. Completions now ship as part of `CoordinateSearchResults.resolvers`, returned by the same continuation resume as `results`. There is no longer a mutable side-channel for the view-model to read, so the happens-before question is moot. Status: **fixed**.

---

### WR-07: Cancellation handler's `Task { @MainActor [weak self] in ... }` cancels a *future* search

**Files modified:** `GPSMetadataEditor/Features/CoordinateSelection/Services/CoordinateSearchService.swift`
**Commit:** `71f4f50`
**Applied fix:** Added `currentSearchID: UInt64` to `SearchCompleterDelegate`, incremented per `search(for:)` call and snapshotted at dispatch into a local `searchID` constant. The cancellation handler now checks `self.currentSearchID == searchID` on the MainActor before tearing down the continuation/completer, so a late cancel that lands after a new search has started no-ops. Status: **fixed: requires human verification** (race window).

---

## Skipped Issues

None — all in-scope findings were fixed.

## Bundling Notes

Eight findings (CR-01, CR-03, CR-04, WR-01, WR-03, WR-04, WR-05, WR-06) were committed together as `0996423`. They are inseparable in practice:

- CR-01 (optional coordinate) forces a change in `CoordinateSearchResult`.
- CR-04 (resolver in protocol) changes the protocol return type — which both consuming files (`MapKitCoordinateSearchService`, `FakeCoordinateSearchService`) must update in lockstep.
- CR-03 (atomic snapshot) is the new contract for the delegate that produces the bundle CR-04 introduces.
- WR-06 (`lastCompletions` side-channel) is removed by CR-04, not patched.
- WR-01 (`print` removal), WR-03 (cancel resolve in search/clear), WR-04 (cancel error timer on success/clear), and WR-05 (deterministic delay) all touch the same `search()` / `selectSearchResult` / `clearSearch` / fake-service blocks that the CR-04 refactor rewrites. Splitting them would have created intermediate states that don't compile.

Per the fix strategy's multi-file/multi-finding pattern, the commit message lists every finding ID it addresses and the reasoning for bundling.

## Verification Notes for the Developer

The Linux dev VM had no Swift toolchain available, so the standard Tier 2 syntax check could not run. The macOS host should:

1. Build the GPSMetadataEditor target (`xcodebuild build -scheme GPSMetadataEditor`) to confirm the protocol-level refactor compiles.
2. Run the `GPSMetadataEditorTests` and `CoordinateSearchServiceTests` test bundles to verify the suite stays green. The renamed test `selectingSearchResultWithPreResolvedCoordinateSetsTargetSynchronously` and the new test `selectingSearchResultWithoutResolverAndWithoutCoordinateIsDropped` are net-new coverage for the CR-01 path.
3. Smoke-test the actual MapKit-backed search in the running app: type a multi-character query, verify completions appear, tap one, verify "Resolving location…" briefly appears and then the pin moves to the tapped place (not Berlin).
4. Re-run the stale-response test (`staleSearchResponseDoesNotOverwriteNewerState`) several times to confirm the new deterministic delay has eliminated the flake.

Info findings IN-01..IN-04 were out of scope (fix_scope = critical_warning). IN-01 (test coverage of resolve flow) is now partly addressed by the new test cases, but additional resolve-failure and resolve-cancellation tests would be valuable.

---

_Fixed: 2026-05-26_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
