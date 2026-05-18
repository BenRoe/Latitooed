# Coordinate Display Locale Stability

## Symptom

Coordinate display tests failed under a non-US locale because decimal formatting could use locale-specific separators.

## Cause

Coordinate strings are app data and test expectations, not user-facing prose. They should be stable regardless of the Mac's current locale.

## Fix

Format coordinate values with an explicit POSIX locale:

```swift
.locale(Locale(identifier: "en_US_POSIX"))
```

## Verification

Run tests in a locale such as German/Berlin and confirm coordinate display remains like:

```text
52.520008, 13.404954
```

