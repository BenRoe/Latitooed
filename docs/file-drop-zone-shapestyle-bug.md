# FileDropZone ShapeStyle Compile Bug

## Summary

`FileDropZone.swift` failed to compile because a SwiftUI ternary expression mixed two different concrete shape-style types inside `strokeBorder`.

## Build Error

The failing build reported:

```text
FileDropZone.swift:90:61: error: member 'quaternary' in 'TintShapeStyle' produces result of type 'some ShapeStyle', but context expects 'TintShapeStyle'
viewModel.isDropTargeted ? .tint : .quaternary
```

It also reported:

```text
error: instance member 'quaternary' cannot be used on type 'TintShapeStyle'
```

## Cause

Swift inferred the ternary expression from the first branch, `.tint`, as `TintShapeStyle`. The second branch, `.quaternary`, resolves to a different opaque `ShapeStyle`, so both branches could not satisfy the same concrete type expected by `strokeBorder`.

This is a SwiftUI type-system issue, not a runtime bug.

## Fix

Type-erase both branches with `AnyShapeStyle`:

```swift
RoundedRectangle(cornerSize: cornerSize)
    .strokeBorder(
        viewModel.isDropTargeted ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
        style: StrokeStyle(
            lineWidth: viewModel.isDropTargeted ? 2 : 1,
            dash: viewModel.isDropTargeted ? [] : [8, 6]
        )
    )
```

## Verification

Re-run:

```bash
xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test
```

The original `ShapeStyle` compile error should no longer appear.

## Prevention

When a SwiftUI conditional chooses between different style values, make the common type explicit. For shape styles, use `AnyShapeStyle` when the two branches are not the same concrete style type.
