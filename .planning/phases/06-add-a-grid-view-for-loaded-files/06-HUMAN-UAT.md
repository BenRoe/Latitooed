---
phase: 06-add-a-grid-view-for-loaded-files
status: pending
created: 2026-05-24
---

# Phase 06 Human UAT

## VM Source Checks

expected: Source checks confirm the grid is wired, uses shared selection state, keeps table support, and avoids banned SwiftUI patterns.
result: [pending]

Host-only test command:

```bash
xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test
```

## Host App Smoke Checks

### 1. Load Mixed Media
expected: Launch the app on macOS and load JPEG, HEIC, MOV, and MP4 files through the picker or drag and drop.
result: [pending]

### 2. Grid Is Default
expected: After files load, the loaded-files surface defaults to Grid.
result: [pending]

### 3. Table/Grid Switch
expected: Switching Table/Grid preserves loaded files, selection, detail, warning summary, batch history, footer, and Apply Location state.
result: [pending]

### 4. Table Command-Click
expected: In Table mode, Command-click multi-select still works through the existing SwiftUI Table behavior.
result: [pending]

### 5. Grid Plain-Click
expected: In Grid mode, plain-clicking a card replaces selection with that file.
result: [pending]

### 6. Grid Command-Click
expected: In Grid mode, Command-click toggles a card in or out of the shared selection.
result: [pending]

### 7. Grid Shift-Click
expected: In Grid mode, Shift-click range-selects from the last grid anchor to the clicked card.
result: [pending]

### 8. Multi-Selection Summary
expected: Selecting multiple files shows a summary such as `2 files selected` with aggregate type/result counts, not first-file diagnostics.
result: [pending]

### 9. Single Warning/Failure Diagnostics
expected: Selecting one warning or failure row still shows `Diagnostics` with the existing detail text.
result: [pending]

### 10. Apply Location Availability
expected: Apply Location remains enabled when files are loaded and a coordinate is selected.
result: [pending]

### 11. Warning Visibility
expected: Unsupported, inaccessible, duplicate, locked, and other intake warnings remain visible.
result: [pending]

## Summary

total: 11
passed: 0
issues: 0
pending: 11
skipped: 0
blocked: 0
