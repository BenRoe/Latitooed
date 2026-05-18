# SwiftUI Map Style Foreground Style Bug

## Symptom

`MapStyleOverlay.swift` failed to compile with:

```text
Member 'primary' in 'TintShapeStyle' produces result of type 'HierarchicalShapeStyle', but context expects 'TintShapeStyle'
```

## Cause

The ternary expression mixed `.tint` and `.primary`. Swift inferred the first branch as `TintShapeStyle`, but `.primary` resolves to a different concrete style type.

## Fix

Use a common concrete type for both branches:

```swift
.foregroundStyle(isSelected ? Color.accentColor : Color.primary)
```

## Verification

Run the Xcode test command and confirm `MapStyleOverlay.swift` no longer appears in the Swift compile failures.

