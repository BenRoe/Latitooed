# MapKit Map Click Coordinate Selection

## Symptom

Left-clicking the map did not reliably set the target marker location.

## Cause

The original tap handling did not reliably capture the clicked location in the SwiftUI `MapReader` coordinate space.

## Fix

Use `SpatialTapGesture` and convert the local tap point through `MapProxy`:

```swift
SpatialTapGesture()
    .onEnded { value in
        setCoordinate(at: value.location, using: proxy)
    }
```

## Verification

Click a location on the map. The latitude/longitude fields should update and the target annotation should move to the clicked area.

