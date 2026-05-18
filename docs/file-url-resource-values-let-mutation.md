# URL Resource Values Mutation In Tests

## Symptom

`FileIntakeServiceTests.swift` failed to compile with:

```text
Cannot use mutating member on immutable value: 'url' is a 'let' constant
```

## Cause

`URL.setResourceValues(_:)` is mutating. The test used `let url`, so Swift rejected the mutation.

## Fix

Declare the URL as mutable where the test changes resource values:

```swift
var url = ...
try url.setResourceValues(values)
```

## Verification

Run the Xcode test command and confirm `FileIntakeServiceTests.swift` compiles.

