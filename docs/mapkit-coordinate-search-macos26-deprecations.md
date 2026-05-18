# MapKit Coordinate Search macOS 26 Deprecations

## Symptom

Xcode warned in `CoordinateSearchService.swift`:

```text
'placemark' was deprecated in macOS 26.0: Use location, address and addressRepresentations instead
```

## Cause

`MKMapItem.placemark` is deprecated for the project target. The new MapKit API exposes coordinates through `location` and display address data through `addressRepresentations`.

## Fix

Use:

```swift
let mapCoordinate = item.location.coordinate
let subtitle = item.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true)
```

## Verification

Build in Xcode and confirm the `placemark` deprecation warnings are gone.

