---
phase: 07-live-place-search
plan: 01
subsystem: CoordinateSelection
tags: [live-search, debounce, dropdown, mapkit, swiftui]
dependency_graph:
  requires: []
  provides:
    - live-as-you-type MapKit search in CoordinateSearchPanel
    - clearSearch() convenience method on CoordinateSelectionViewModel
  affects:
    - GPSMetadataEditor/Features/CoordinateSelection/Views/CoordinateSearchPanel.swift
    - GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift
    - GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift
tech_stack:
  added: []
  patterns:
    - Task-based debounce via @State debounceTask: Task<Void, Never>?
    - Floating dropdown via .overlay(alignment: .bottom) on search row HStack
    - X clear button as .overlay(alignment: .trailing) on TextField
    - onExitCommand for macOS Escape key handling
key_files:
  created: []
  modified:
    - GPSMetadataEditor/Features/CoordinateSelection/Views/CoordinateSearchPanel.swift
    - GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift
    - GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift
decisions:
  - Kept isSearchResultsExpanded in ViewModel to avoid breaking existing tests; view adds its own @State isDropdownVisible and syncs the two via onChange
  - Used static offset(y: 36) for dropdown placement below HStack (standard roundedBorder TextField height on macOS); GeometryReader not required
  - clearSearch() resets display state only (searchResults + searchStatus); cancelSearch() remains the task-cancellation path
metrics:
  duration_seconds: 210
  completed: "2026-05-25T01:16:47Z"
  tasks_completed: 2
  files_modified: 3
---

# Phase 07 Plan 01: Live Place Search — Clean ViewModel & Rewrite CoordinateSearchPanel Summary

**One-liner:** Replaced submit-gated MapKit search with onChange debounce (3 chars / 500 ms) and floating dropdown overlay; removed Search button and onSubmit handler; added clearSearch() to ViewModel.

---

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Clean ViewModel — remove submit artifacts, add clearSearch() | b172e17 | CoordinateSelectionViewModel.swift, CoordinateSelectionViewModelTests.swift |
| 2 | Rewrite CoordinateSearchPanel — live search, floating dropdown, X clear, Escape | f6ae9dd | CoordinateSearchPanel.swift |

---

## What Was Built

**Task 1 — ViewModel cleanup (TDD red + green):**
- Removed `performSearchOnSubmit()` — only caller was `CoordinateSearchPanel.onSubmit`
- Removed `isSearchButtonDisabled` computed property — only reader was the removed Search button
- Added `clearSearch()` immediately after `cancelSearch()`: sets `searchResults = []` and `searchStatus = .idle` without touching `activeSearchTask` or `searchGeneration`
- Added `clearSearchResetsResultsAndStatus` test: populates results + searching status, calls `clearSearch()`, asserts empty results and idle status

**Task 2 — CoordinateSearchPanel rewrite:**
- Added `@State private var debounceTask: Task<Void, Never>?` and `@State private var isDropdownVisible = false`
- `TextField` gains a trailing overlay X clear button (`xmark.circle.fill`, `.secondary`, `accessibilityLabel("Clear search field")`)
- `TextField` gains `.onExitCommand` handler: clears query, cancels debounce task, calls `cancelSearch()`, hides dropdown
- Search row `HStack` gains `.onChange(of: viewModel.searchQuery)`: cancels previous debounce, enforces 3-char minimum, starts 500 ms `Task { @MainActor in }` debounce that calls `viewModel.search()`
- `HStack` gains `.onChange(of: viewModel.isSearchResultsExpanded)`: syncs `isDropdownVisible = false` when ViewModel collapses (map tap, manual field entry, recent coordinate selection)
- `.overlay(alignment: .bottom)` on the `HStack` renders `dropdownContent` with `offset(y: 36)` when `isDropdownVisible`
- `dropdownContent`: "Results" caption, spinner (`ProgressView().controlSize(.small).accessibilityLabel("Searching")`), status text, `ScrollView { VStack { ForEach } }.frame(maxHeight: 240)`, `.regularMaterial` + `AppDesign.Radius.mediumSize` + shadow
- Removed inline `if viewModel.isSearchResultsExpanded` expanding block entirely
- `CoordinateSearchResultRow` private struct kept verbatim

---

## Decisions Made

1. **Keep `isSearchResultsExpanded` in ViewModel** — five existing tests assert on it directly; removing it would require rewriting those tests. The view adds its own `@State isDropdownVisible` and syncs via `onChange`. Both flags coexist without conflict.

2. **Static `offset(y: 36)` for dropdown placement** — the plan recommended starting with this value for standard `roundedBorder` TextField height on macOS. `GeometryReader` adds complexity without benefit for this use case.

3. **`clearSearch()` is state-only** — `cancelSearch()` owns task cancellation; `clearSearch()` owns display state reset. Keeps single-responsibility principle and matches the plan's explicit separation.

---

## Deviations from Plan

None — plan executed exactly as written. The GitNexus index was stale during execution (showed `performSearchOnSubmit` still called by `CoordinateSearchPanel.swift`) but this reflected pre-edit state; the symbol was correctly removed in Task 2.

---

## Known Stubs

None — all data paths are wired. The dropdown renders live `viewModel.searchResults` from MapKit; no hardcoded or placeholder values.

---

## Threat Flags

No new threat surface introduced. Changes are pure UI refactor within existing `CoordinateSearchPanel`. No new network endpoints, auth paths, file access, or schema changes.

The three mitigations in the plan's threat register are all present:
- **T-07-01 (DoS):** 3-char minimum + 500 ms debounce + `cancelSearch()` on clear/Escape implemented in `onChange` handler
- **T-07-02 (Info Disclosure):** `searchQuery` remains ephemeral, never persisted
- **T-07-03 (Tampering):** `searchGeneration` guard in `search()` unchanged; `Task.isCancelled` check after sleep present

---

## Verification Notes

`xcodebuild` is not available in the Linux execution environment (project filesystem is mounted from macOS host via Parallels). All verification was performed via source assertions (grep). Build and test suite must be confirmed on the macOS host:

```bash
xcodebuild test -scheme GPSMetadataEditor -destination 'platform=macOS' -only-testing:GPSMetadataEditorTests/CoordinateSelectionViewModelTests
xcodebuild build -scheme GPSMetadataEditor -destination 'platform=macOS'
```

Human verification: Launch app, type "Ber" → dropdown appears with results after ~500 ms, no Search button visible. Press Escape → dropdown dismisses, field clears. Type "Berlin" → select a result → dropdown dismisses, query text remains "Berlin", coordinate updates.

---

## Self-Check

**Files exist:**
- `GPSMetadataEditor/Features/CoordinateSelection/Views/CoordinateSearchPanel.swift` — FOUND (rewritten)
- `GPSMetadataEditor/Features/CoordinateSelection/CoordinateSelectionViewModel.swift` — FOUND (cleaned)
- `GPSMetadataEditorTests/CoordinateSelectionViewModelTests.swift` — FOUND (new test added)

**Commits exist:**
- `b172e17` — refactor(07-01): clean ViewModel and add clearSearch()
- `f6ae9dd` — feat(07-01): rewrite CoordinateSearchPanel with live search and floating dropdown

## Self-Check: PASSED
