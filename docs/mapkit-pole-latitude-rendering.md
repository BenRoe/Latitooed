# MapKit Pole Latitude Rendering

## Symptom

Coordinates near the poles, especially `90`, produced MapKit/Metal console noise and the marker could disappear. The marker rendered reliably at latitude `85` and lower.

## Cause

MapKit's SwiftUI rendering path does not reliably display markers at or near the mathematical latitude edges. Centering the camera near the pole can also place the visual annotation outside the visible renderable area.

## Fix

Preserve the real selected coordinate in the model and fields, but clamp the map camera and visual annotation to `±85` for rendering.

## Verification

Enter latitude `89` and longitude `13`. The model should still report `89, 13`, while the visible annotation renders at the supported map latitude. Entering `85, 13` should render directly at `85`.

