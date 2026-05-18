# SwiftUI Frame Argument Order

## Symptom

Xcode failed to compile `CoordinateSelectionView.swift` with:

```text
Argument 'maxWidth' must precede argument 'minHeight'
```

## Cause

Swift function arguments must follow the declaration order. For SwiftUI `frame`, `maxWidth` appears before `minHeight`.

## Fix

Use:

```swift
.frame(maxWidth: .infinity, minHeight: AppDesign.Layout.mapMinimumHeight, maxHeight: .infinity)
```

## Verification

Build in Xcode and confirm the argument-order compile error is gone.

