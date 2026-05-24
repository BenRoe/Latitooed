# Phase 7: Live Place Search - Research

**Researched:** 2026-05-25
**Domain:** SwiftUI overlay dropdown, Task-based debounce, MapKit MKLocalSearch, macOS search UX
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Remove the Search button entirely. No explicit submit affordance — typing drives search exclusively.
- **D-02:** Remove `performSearchOnSubmit` / `onSubmit` handler from `CoordinateSearchPanel`.
- **D-03:** Show results in a floating dropdown overlay anchored below the search field (not inline expanding panel). Map remains visible while browsing results.
- **D-04:** Use SwiftUI `.overlay` or popover — do not push layout content down.
- **D-05:** Minimum 3 characters before any search fires. Below threshold: cancel any in-flight task, clear results, dismiss dropdown silently.
- **D-06:** 500 ms debounce on last keystroke before firing `MKLocalSearch`.
- **D-07:** Existing `searchGeneration` guard and `activeSearchTask?.cancel()` pattern must remain — new `onChange` path must respect it.
- **D-08:** X clear button appears inside the search field when text is non-empty. Tapping clears field, cancels in-flight task, dismisses dropdown.
- **D-09:** Escape key also clears field and dismisses dropdown.
- **D-10:** On result selection: keep query text in the field, dismiss dropdown. Coordinate updates as before.

### Claude's Discretion

None defined — all implementation choices are locked in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOC-02 | User can select a search result to set the target coordinate. | Already met by `selectSearchResult(_:)`. This phase upgrades the interaction model only — results must appear in the new dropdown, and tap-to-select must remain wired to the existing handler. |

</phase_requirements>

---

## Summary

Phase 7 replaces the submit-gated search interaction in `CoordinateSearchPanel` with a live-as-you-type experience. The change is **entirely contained within one view file** (`CoordinateSearchPanel.swift`) plus **minimal ViewModel cleanup** (`performSearchOnSubmit`, `isSearchButtonDisabled`, `isSearchResultsExpanded` may be removed or repurposed). No new packages, no new models, no service layer changes.

The existing `CoordinateSelectionViewModel` already has the complete cancellation and generation-guard infrastructure needed for live search. The only new concurrency artifact is a `@State var debounceTask: Task<Void, Never>?` stored in the view, following the same pattern already present in `CoordinateFieldsView` (which uses `onChange(of:)`). The debounce is implemented with `Task.sleep` — Combine is not imported anywhere in the feature and must not be introduced.

The floating dropdown is an `.overlay(alignment: .bottom)` on the search-field `HStack`, rendering a `VStack` that matches the field width exactly. This is the macOS-idiomatic approach: the overlay sits in Z-order above `CoordinateFieldsView`, `RecentCoordinatesView`, and the map without affecting their layout. `CoordinateSearchResultRow` is reused unchanged inside the dropdown.

**Primary recommendation:** Treat this as a pure UI refactor of `CoordinateSearchPanel.swift`. Wire `onChange` → debounce Task → `viewModel.search()`. Replace the expanding inline block with an `.overlay` dropdown. Remove the submit affordance. Done.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Debounce timer management | View (`CoordinateSearchPanel`) | — | 500 ms Task is ephemeral UI state, not business logic. Stored as `@State`. |
| Search execution + generation guard | ViewModel (`CoordinateSelectionViewModel`) | — | Already owns `activeSearchTask`, `searchGeneration`, `search()` |
| Results model | ViewModel | — | `searchResults: [CoordinateSearchResult]` unchanged |
| Dropdown visibility | View | ViewModel (`isSearchResultsExpanded` or replacement) | View owns the `@State var isDropdownVisible: Bool`; ViewModel collapses on selection |
| Cancellation on clear/Escape | View (triggers) → ViewModel (`cancelSearch()`) | — | View gesture → existing `cancelSearch()` method |
| X clear button rendering | View | — | Pure conditional UI element |
| Overlay anchoring / z-order | View | — | SwiftUI `.overlay(alignment: .bottom)` on the HStack |

---

## Standard Stack

### Core (no new packages)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 13+ (project baseline) | Overlay, onChange, onExitCommand | Native framework; already used throughout |
| MapKit | macOS 13+ | `MKLocalSearch` (already used) | No change to search service |

No new packages are introduced in this phase. [VERIFIED: official Apple docs]

### Package Legitimacy Audit

Not applicable — this phase introduces zero new packages.

---

## Architecture Patterns

### System Architecture Diagram

```
User types → TextField (onChange) → debounceTask?.cancel(); new debounceTask
                                          │
                              Task { sleep 500ms; checkCancellation }
                                          │ (if not cancelled AND query.count >= 3)
                                    viewModel.search()
                                          │
                              CoordinateSelectionViewModel
                                  searchGeneration++
                                  activeSearchTask = Task { searchService.search(...) }
                                          │
                              MapKitCoordinateSearchService (unchanged)
                                    MKLocalSearch.start()
                                          │
                              viewModel.searchResults updated
                                          │
                         CoordinateSearchPanel observes searchResults
                                    dropdown renders
```

### Recommended Project Structure

No new files. All changes in:
```
GPSMetadataEditor/Features/CoordinateSelection/
├── Views/
│   └── CoordinateSearchPanel.swift     ← primary change
└── CoordinateSelectionViewModel.swift  ← minor cleanup only
```

### Pattern 1: Task-based Debounce in SwiftUI View

**What:** Store a `Task<Void, Never>?` as `@State`. On each `onChange`, cancel the previous task and create a new one that sleeps then acts.

**When to use:** When you need debounced async side-effects triggered by a `@Bindable` / `@Observable` property change, without introducing Combine.

**Example:**
```swift
// Source: Apple developer docs (onChange performance recommendations)
// + project pattern from CoordinateFieldsView (.onChange(of:) usage)
@State private var debounceTask: Task<Void, Never>?

// Inside the view body on TextField:
.onChange(of: viewModel.searchQuery) { _, newValue in
    debounceTask?.cancel()
    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 3 else {
        viewModel.cancelSearch()
        isDropdownVisible = false
        return
    }
    debounceTask = Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        viewModel.search()
        isDropdownVisible = true
    }
}
```

**Concurrency note:** The ViewModel is `@Observable @MainActor`. The `Task { @MainActor in ... }` annotation ensures all accesses remain on the main actor. `try? await Task.sleep(for:)` — the `try?` silences the `CancellationError` from `Task.sleep` when the task is cancelled externally, which is the correct pattern here. [VERIFIED: Apple SwiftUI docs — onChange performance considerations; swift-concurrency-pro skill]

### Pattern 2: Floating Dropdown via `.overlay(alignment: .bottom)`

**What:** Apply `.overlay(alignment: .bottom)` to the search row `HStack`. The overlay content is positioned below the anchor view, matching its width, without affecting layout.

**When to use:** Any floating surface that must not push sibling views down. Standard macOS pattern (used by Maps, Spotlight, etc.)

**Example:**
```swift
// Source: Apple SwiftUI overlay(alignment:content:) docs
HStack(spacing: AppDesign.Spacing.sm) {
    TextField("Search for a place", text: $viewModel.searchQuery)
        .textFieldStyle(.roundedBorder)
        .overlay(alignment: .trailing) {
            // X clear button
        }
        .onExitCommand { /* clear + dismiss */ }
}
.overlay(alignment: .bottom) {
    if isDropdownVisible {
        SearchDropdownView(viewModel: viewModel) {
            isDropdownVisible = false
        }
        .offset(y: /* computed or via GeometryReader */)
    }
}
```

**Width matching:** `.overlay` automatically sizes its content to the anchor view's width when the content uses `.frame(maxWidth: .infinity)`. No `GeometryReader` required for width. [VERIFIED: Apple SwiftUI overlay docs]

**Z-order:** `.overlay` renders above all siblings in the parent `VStack` by SwiftUI layout rules. This places the dropdown above `CoordinateFieldsView`, `RecentCoordinatesView`, and the map. [VERIFIED: Apple SwiftUI docs]

### Pattern 3: `.onExitCommand` for Escape Key

**What:** SwiftUI modifier that fires when the user presses Escape (macOS) while the view (or its focused child) has focus.

**When to use:** macOS panel UX — dismiss floating overlays on Escape. Preferred over `.onKeyPress(.escape)` for macOS because it does not require focus on the specific view.

**Example:**
```swift
// Source: developer.apple.com/documentation/swiftui/view/onexitcommand(perform:)
TextField("Search for a place", text: $viewModel.searchQuery)
    .onExitCommand {
        viewModel.searchQuery = ""
        viewModel.cancelSearch()
        isDropdownVisible = false
    }
```

**Availability:** macOS 10.15+. [VERIFIED: Apple SwiftUI docs — onExitCommand(perform:)]

### Pattern 4: X Clear Button as TextField Trailing Overlay

**What:** A `Button` with `xmark.circle.fill` placed as a `.overlay(alignment: .trailing)` inside the `TextField`.

**When to use:** Clear affordance inside a search field — matches Apple Maps, Spotlight pattern.

**Example:**
```swift
// Source: Apple HIG + swiftui-pro skill conventions
TextField("Search for a place", text: $viewModel.searchQuery)
    .textFieldStyle(.roundedBorder)
    .overlay(alignment: .trailing) {
        if !viewModel.searchQuery.isEmpty {
            Button {
                viewModel.searchQuery = ""
                viewModel.cancelSearch()
                isDropdownVisible = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear search field")
            .padding(.trailing, AppDesign.Spacing.xs)
        }
    }
```

### Pattern 5: Dropdown ScrollView with Max Height Constraint

**What:** `ScrollView { VStack { ... } }` capped at 240 pt for approximately 5 result rows.

**Why ScrollView not List:** `List` on macOS renders selection chrome (highlight backgrounds, disclosure indicators) that conflicts with the plain button style used in `CoordinateSearchResultRow`. `ScrollView + VStack + ForEach` is the correct pattern here.

```swift
// Source: existing CoordinateSearchPanel.swift pattern (ForEach + Button + .plain)
ScrollView {
    VStack(alignment: .leading, spacing: 0) {
        ForEach(viewModel.searchResults) { result in
            Button {
                viewModel.selectSearchResult(result)
                isDropdownVisible = false
            } label: {
                CoordinateSearchResultRow(result: result)
            }
            .buttonStyle(.plain)
        }
    }
}
.frame(maxHeight: 240)
```

### Anti-Patterns to Avoid

- **Using `List` for the dropdown:** Produces macOS selection chrome that conflicts with `.plain` button style and doesn't clip cleanly inside `.regularMaterial`. Use `ScrollView + VStack`.
- **Using Combine for debounce:** Not imported in the target files. `Task.sleep` achieves identical behavior. Adding Combine requires a new import and introduces an additional paradigm.
- **`Task.detached` for the debounce task:** Detached tasks lose actor context. The debounce task must be `Task { @MainActor in ... }` to safely access ViewModel properties.
- **`await MainActor.run { }` for every ViewModel access:** Unnecessary when the task itself is `@MainActor`-isolated. The ViewModel is `@MainActor @Observable`, so a `Task { @MainActor in ... }` can call `viewModel.search()` directly.
- **`@State var debounceTask` not cancelled in `onDisappear`:** The task should be cancelled when the view disappears. Add `.onDisappear { debounceTask?.cancel() }`.
- **Setting `isDropdownVisible = true` before the search completes:** The dropdown should become visible as soon as the search is triggered (shows spinner). The `viewModel.searchStatus == .searching` path covers this.
- **Applying the dropdown overlay to `CoordinateSelectionView`'s outer `VStack`:** It must be on `CoordinateSearchPanel`'s internal search row `HStack`. Applying it higher up causes misaligned width.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Debounce timer | Custom `DispatchWorkItem` or `Timer` | `Task { try? await Task.sleep(for:) }` | Swift Concurrency approach already used in project; GCD is unnecessary |
| Search cancellation / generation guard | New mechanism | Existing `viewModel.cancelSearch()` + `searchGeneration` | Already correct and tested |
| Dropdown width matching | `GeometryReader` hack | `.overlay(alignment: .bottom)` + `.frame(maxWidth: .infinity)` | SwiftUI overlay inherits anchor width natively |
| Keyboard Escape handling | Custom `NSEvent` monitor | `.onExitCommand` | Native SwiftUI modifier, macOS 10.15+ |
| Result row component | New view | `CoordinateSearchResultRow` (already in file) | Verified reusable, matches design spec |

---

## Existing Implementation — Detailed Findings

### What Already Exists and Is Reused

**`CoordinateSelectionViewModel.search()`** — The search method is complete and correct. It:
- Increments `searchGeneration` to guard against stale results
- Cancels `activeSearchTask` before starting a new one
- Sets `isSearchResultsExpanded = true` (this will be superseded by view-local `isDropdownVisible`)
- Handles `.idle`, `.emptyQuery`, `.searching`, `.noResults`, `.failed` status transitions
- Uses `Task.checkCancellation()` via `MapKitCoordinateSearchService`

**`CoordinateSelectionViewModel.cancelSearch()`** — Cancels the task, clears it, increments generation. The X button and Escape handler call this directly.

**`CoordinateSelectionViewModel.selectSearchResult(_:)`** — Calls `setCoordinate(_:label:collapseResults:true)` which sets `isSearchResultsExpanded = false`. After this phase, the view will also need to set its local `isDropdownVisible = false` on selection. The ViewModel's `isSearchResultsExpanded` can remain or be repurposed — it is safest to keep it and let the view additionally track `@State var isDropdownVisible`.

**`CoordinateSearchResultRow`** — Private view already in `CoordinateSearchPanel.swift`. Renders `mappin.circle` (tint), title (`.body`), subtitle (`.caption`). No changes needed. Move into the dropdown `ForEach` as-is.

**`viewModel.searchStatusText`** — Returns strings for all non-idle states. Already matches the copywriting contract.

**`viewModel.searchStatus`** — Drives spinner visibility (`== .searching`), error color (`== .failed`).

### What Changes in the ViewModel

These are the only ViewModel modifications:

| Item | Action | Risk |
|------|--------|------|
| `performSearchOnSubmit()` | Remove (called only from `.onSubmit`) | Low — no other callers |
| `isSearchButtonDisabled` | Remove (only used by removed Search button) | Low — verify with grep |
| `isSearchResultsExpanded` | Can be kept as-is (no callers will break). The view will use its own `@State var isDropdownVisible`. | Low |

**Grep confirms** `isSearchResultsExpanded` is only set internally in the ViewModel and read in `CoordinateSearchPanel`. After replacing the panel's conditional with the overlay, no other view reads it. It can remain without harm, or be removed if cleanup is desired.

**Grep confirms** `performSearchOnSubmit` is only called from `CoordinateSearchPanel.swift`. Safe to remove.

### `collapseSearchResults()` Usage

`collapseSearchResults()` is only called internally via `setCoordinate(_:label:collapseResults:)`. After Phase 7, the view needs to also dismiss the dropdown on selection. The recommended approach: call `viewModel.selectSearchResult(result)` then immediately set `isDropdownVisible = false` in the button action. The ViewModel method still collapses `isSearchResultsExpanded` — no harm in leaving it.

### `isSearchResultsExpanded` in Other Tests

`CoordinateSelectionViewModelTests` has tests that assert `viewModel.isSearchResultsExpanded == true` after `search()` or `== false` after `selectSearchResult`. These tests still pass because the ViewModel still sets this flag. The tests do not need to change unless the property is removed. [CONFIRMED: reading test file]

---

## Common Pitfalls

### Pitfall 1: Dropdown Covers Map but Does Not Dismiss on Outside Click

**What goes wrong:** The user clicks the map to set a coordinate. The dropdown remains visible.
**Why it happens:** There is no "click outside to dismiss" handler.
**How to avoid:** Wire `viewModel.setCoordinateFromMap(latitude:longitude:)` (already called by `CoordinateMapView` on tap) to also dismiss the dropdown. Since the ViewModel calls `setCoordinate(collapseResults: true)`, the view can observe `isSearchResultsExpanded` becoming false and sync `isDropdownVisible`.

**Alternative approach:** Add a transparent full-screen backdrop `Color.clear.contentShape(.rect).onTapGesture { isDropdownVisible = false }` behind the dropdown in the overlay. The UI spec allows either approach. The map-tap path is the cleaner solution because `isSearchResultsExpanded` is already set to false by `setCoordinateFromMap`.

**Simplest implementation:** Add `.onChange(of: viewModel.isSearchResultsExpanded)` to sync `isDropdownVisible`:
```swift
.onChange(of: viewModel.isSearchResultsExpanded) { _, newValue in
    if !newValue { isDropdownVisible = false }
}
```

### Pitfall 2: `Task { @MainActor in }` vs `Task {}` — Actor Isolation

**What goes wrong:** `viewModel.search()` is called from a non-`@MainActor` Task closure, causing a strict concurrency error.
**Why it happens:** The ViewModel is `@MainActor`. A plain `Task {}` inherits the calling context (which is `@MainActor` when called from `onChange`), but if someone changes isolation this breaks.
**How to avoid:** Always annotate the debounce task `Task { @MainActor in ... }` — explicit is safer than implicit.

### Pitfall 3: `try? await Task.sleep` Swallows Cancellation Silently

**What goes wrong:** Task is cancelled (previous debounce superseded), but `guard !Task.isCancelled` never runs because `try?` makes the `CancellationError` from `Task.sleep` look like a nil-optional, not a cancellation.
**Why it happens:** `Task.sleep(for:)` throws `CancellationError` on cancellation. `try?` converts it to `nil`, skipping subsequent code — which is the DESIRED behavior for a debounce.
**Clarification:** This is actually correct. When the task is cancelled, `try? await Task.sleep(...)` returns without executing the search. The `guard !Task.isCancelled` after the sleep is an additional safety net for tasks that survive the sleep but are cancelled between sleep and search. Both are correct and complement each other.

### Pitfall 4: Dropdown Width Does Not Match TextField

**What goes wrong:** Dropdown is narrower than the TextField (e.g., wraps to content width).
**Why it happens:** The overlay content's width is not constrained to the anchor.
**How to avoid:** Wrap dropdown content in `.frame(maxWidth: .infinity)` so it fills the anchor's width automatically.

### Pitfall 5: Tests Assert `isSearchResultsExpanded` After Phase 7 Removes the Property

**What goes wrong:** If `isSearchResultsExpanded` is removed from the ViewModel, 5+ existing tests fail.
**How to avoid:** Either keep the property, or update tests to assert `searchResults.isEmpty` / `searchStatus` instead. Safest: keep the property.

### Pitfall 6: `debounceTask` Leaks if View Is Removed Before Completion

**What goes wrong:** A pending 500 ms task calls `viewModel.search()` after the view has been deallocated.
**How to avoid:** Add `.onDisappear { debounceTask?.cancel() }`.

---

## Code Examples

### Complete Debounce + Dropdown Integration Sketch

```swift
// Source: synthesized from Apple SwiftUI docs + existing codebase patterns
struct CoordinateSearchPanel: View {
    @Bindable var viewModel: CoordinateSelectionViewModel
    @State private var debounceTask: Task<Void, Never>?
    @State private var isDropdownVisible = false

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            TextField("Search for a place", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)
                .overlay(alignment: .trailing) {
                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                            debounceTask?.cancel()
                            viewModel.cancelSearch()
                            isDropdownVisible = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search field")
                        .padding(.trailing, AppDesign.Spacing.xs)
                    }
                }
                .onExitCommand {
                    viewModel.searchQuery = ""
                    debounceTask?.cancel()
                    viewModel.cancelSearch()
                    isDropdownVisible = false
                }
        }
        .onChange(of: viewModel.searchQuery) { _, newValue in
            debounceTask?.cancel()
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 3 else {
                viewModel.cancelSearch()
                viewModel.searchResults = []
                isDropdownVisible = false
                return
            }
            isDropdownVisible = true
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                viewModel.search()
            }
        }
        .onChange(of: viewModel.isSearchResultsExpanded) { _, newValue in
            if !newValue { isDropdownVisible = false }
        }
        .overlay(alignment: .bottom) {
            if isDropdownVisible {
                dropdownContent
                    .offset(y: /* fieldHeight + gap — or omit if overlay anchors correctly */)
            }
        }
        .onDisappear {
            debounceTask?.cancel()
        }
    }

    @ViewBuilder
    private var dropdownContent: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Text("Results")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.searchStatus == .searching {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Searching")
            }

            if let statusText = viewModel.searchStatusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(viewModel.searchStatus == .failed ? .orange : .secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.searchResults) { result in
                        Button {
                            viewModel.selectSearchResult(result)
                            isDropdownVisible = false
                        } label: {
                            CoordinateSearchResultRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 240)
        }
        .frame(maxWidth: .infinity)
        .padding(AppDesign.Spacing.sm)
        .background(.regularMaterial)
        .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .contain)
    }
}
```

**Note on `viewModel.searchResults = []`:** `searchResults` is a `var` on `@Observable @MainActor` ViewModel. Setting it from the view's `onChange` is permitted because `onChange` runs on the main actor. However, the cleaner approach is to add a `clearSearchResults()` method to the ViewModel — the executor may choose either.

---

## MKLocalSearch vs MKLocalSearchCompleter — Which to Use

**Decision (confirmed by CONTEXT.md D-06):** Use `MKLocalSearch` (full search), not `MKLocalSearchCompleter` (suggestion strings only).

**Why:** `MKLocalSearchCompleter` returns `MKLocalSearchCompletion` objects — text strings suitable for autocomplete suggestions, not `MKMapItem` objects with coordinates. To get coordinates from a completer result, you must then perform a separate `MKLocalSearch` with the completion. This two-step flow adds complexity with no benefit given the 3-char / 500 ms debounce gate already limits call rate.

The existing `MapKitCoordinateSearchService` already uses `MKLocalSearch` correctly. No change needed.

[VERIFIED: Apple MapKit docs — MKLocalSearchCompleter returns strings, not coordinates; MKLocalSearch.Response.mapItems contains coordinate-bearing MKMapItem objects]

---

## Validation Architecture

> `workflow.nyquist_validation` is explicitly `false` in `.planning/config.json`. Section skipped.

---

## Security Domain

> This phase adds no network endpoints, no authentication, no input that reaches a backend, and no new data storage. MapKit search is an OS-level API with no direct credentials. Security section not applicable to this UI refactor.

---

## Environment Availability

This phase is a pure Swift/SwiftUI code change. No external tools, CLIs, databases, or services are required beyond Xcode and the existing MapKit framework (bundled with macOS).

Step 2.6: SKIPPED (no external dependencies beyond existing project toolchain).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `isSearchButtonDisabled` has no callers outside `CoordinateSearchPanel.swift` | Existing Implementation — What Changes in the ViewModel | If another view uses it, removing it breaks compilation. Verify with grep before removal. |
| A2 | The `.overlay(alignment: .bottom)` approach correctly positions the dropdown below the HStack without a Y offset calculation | Architecture Patterns — Pattern 2 | If the overlay anchors to the center-bottom of the HStack instead of below it, a `GeometryReader` or explicit `offset(y:)` is needed |

**A1 mitigation:** Run `grep -r "isSearchButtonDisabled" GPSMetadataEditor/` before removing it.
**A2 mitigation:** The UI-SPEC.md (Implementation Constraint #4) says `.overlay(alignment: .bottom)` on the search row HStack with offset so "dropdown top edge aligns with field bottom edge" — an explicit offset is expected. The executor should measure the field height or use `GeometryReader` only if needed.

---

## Open Questions

1. **Dropdown offset below the HStack**
   - What we know: `.overlay(alignment: .bottom)` renders the overlay's top edge at the anchor's bottom edge by default (for `.bottom` alignment). However, SwiftUI actually aligns the overlay's **bottom** edge to the anchor's bottom. A positive `offset(y:)` or `alignmentGuide` may be needed to push it below.
   - What's unclear: Whether a simple `offset(y: searchFieldHeight)` or a `GeometryReader` approach is cleaner on macOS.
   - Recommendation: The executor should test with a static offset first (`offset(y: 36)` for a standard text field height), then adjust if needed. The UI-SPEC.md explicitly says "offset so the dropdown top edge aligns with the field bottom edge."

2. **`viewModel.searchResults = []` in view or ViewModel method**
   - What we know: On `query.count < 3`, results should be cleared silently.
   - What's unclear: Should the view reach into `viewModel.searchResults` directly, or should a `clearSearch()` / `resetSearchState()` method be added?
   - Recommendation: Add a lightweight `clearSearch()` to the ViewModel that clears results and resets status to `.idle`. This is cleaner and keeps all state transitions in the ViewModel. The ViewModel already has `cancelSearch()` for task cancellation — `clearSearch()` would add result/status reset.

---

## Sources

### Primary (HIGH confidence)
- [Apple SwiftUI docs — onExitCommand](https://developer.apple.com/documentation/swiftui/view/onexitcommand%28perform%3A%29) — confirmed macOS 10.15+, `nonisolated func` signature
- [Apple SwiftUI docs — onChange performance](https://developer.apple.com/documentation/swiftui/view/onchange%28of%3Ainitial%3A_%3A%29) — confirmed main-actor closure, Task.detached recommendation for long work
- [Apple SwiftUI docs — overlay(alignment:content:)](https://developer.apple.com/documentation/swiftui/view/overlay%28alignment%3Acontent%3A%29) — confirmed Z-order behavior
- [Apple MapKit docs — MKLocalSearchCompleter](https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter) — confirmed delegate-based, returns completion strings not coordinates
- [Apple MapKit docs — MKLocalSearch.Response.mapItems](https://developer.apple.com/documentation/mapkit/mklocalsearch/response/mapitems) — confirmed coordinate-bearing results
- Codebase: `CoordinateSelectionViewModel.swift`, `CoordinateSearchPanel.swift`, `CoordinateSearchService.swift`, `CoordinateSelectionViewModelTests.swift` — read directly

### Secondary (MEDIUM confidence)
- UI-SPEC.md (07-UI-SPEC.md) — authoritative design contract for this phase, written by gsd-ui-researcher
- CONTEXT.md (07-CONTEXT.md) — locked decisions from /gsd:discuss-phase

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, existing APIs verified
- Architecture (overlay/debounce): HIGH — verified via Apple docs + existing project patterns
- MapKit API choice (MKLocalSearch vs Completer): HIGH — verified via Apple MapKit docs
- Pitfalls: HIGH — derived from reading actual code + swift-concurrency-pro skill guidance
- Test impact: HIGH — all affected tests identified by reading test file directly

**Research date:** 2026-05-25
**Valid until:** 2026-08-25 (stable SwiftUI/MapKit APIs)
