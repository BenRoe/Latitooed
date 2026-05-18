# SwiftUI Table Selection Behavior

## Finding

SwiftUI `Table` multi-selection on macOS is enabled by binding selection to `Set<Row.ID>`. Binding to `Row.ID?` creates single-selection behavior.

## Symptoms

- Command-click could not select multiple rows when selection used `SelectedMediaFile.ID?`.
- Adding per-cell `TapGesture` to force Finder-style collapse interfered with native `Table` selection.
- Updating SwiftUI `@State` during mouse-down could make Command-click unreliable.

## Fix

Use a set-backed table selection:

```swift
@Binding var selection: Set<SelectedMediaFile.ID>

Table(files, selection: $selection) {
    ...
}
```

Keep detail-panel behavior separate from table selection by deriving the first selected row in table order.

If Finder-style plain-click collapse is required, do not attach tap gestures to table cells. Use AppKit-side event observation after native `Table` selection has handled the click, and leave Command/Shift clicks untouched.

## Rule

Prefer native SwiftUI `Table` selection first. Add selection workarounds only outside cell content, because cell gestures compete with built-in row selection.
