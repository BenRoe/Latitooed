# MapKit And macOS Console Warnings

## Symptom

Running the app in Xcode can print:

```text
Failed to locate resource named "default.csv"
CAMetalLayer ignoring invalid setDrawableSize width=0.000000 height=0.000000
Unable to obtain a task name port right for pid ...: (os/kern) failure (0x5)
ViewBridge to RemoteViewService Terminated ... benign unless unexpected
```

## Findings

- `default.csv` appears in public reports around Core Location / MapKit provider internals. The app does not reference this file.
- `CAMetalLayer` zero-size warnings are associated with Metal-backed views being laid out at zero size. The app hardens this by giving the map explicit minimum width and height.
- `Unable to obtain a task name port right` appears in Xcode/macOS debugger and process-right contexts.
- `ViewBridge ... Code=18` appears in unrelated SwiftUI/macOS apps and includes Apple's own `benign unless unexpected` hint.

## Fix Or Decision

Treat these as framework/debugger warnings unless there is a visible app failure. Keep the map layout hardened with nonzero minimum dimensions and verify behavior rather than trying to suppress system logs in app code.

## Verification

The app passes if the map is visible, the annotation appears for supported coordinates, and Xcode tests pass. Remaining one-off framework warnings do not fail the phase by themselves.

