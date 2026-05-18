# Phase 2 Verification

## Verdict

Accepted with verification waived by user.

## Date

2026-05-18

## Scope

Phase 2 implemented the coordinate selection right panel:

- MapKit place search through an explicit Search action.
- Search result selection into a lightweight coordinate result.
- Manual latitude and longitude entry.
- Map click coordinate targeting.
- Standard, satellite/imagery, and hybrid map style controls.
- Selected-coordinate ready status outside the map.
- Map rendering hardening for high-latitude coordinates using a visual `±85` clamp while preserving the actual selected coordinate.

## Verification Status

Host-side verification was intentionally skipped by user request.

Not run:

```bash
xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'
```

Not fully repeated:

- Full MapKit UI smoke check.
- End-to-end Xcode run after the final Phase 2 map rendering commits.

## Known Residual Risk

- Swift/Xcode compile or test regressions may remain until the host command is run.
- MapKit can emit framework/debugger console warnings such as `default.csv`, `CAMetalLayer`, task-name-port, and `ViewBridge` messages. Current project decision is to treat those as non-blocking unless visible UI behavior fails.
- The visual map annotation clamps high-latitude rendering to `±85`; the stored selected coordinate remains the user's actual value.

## Manual Verification When Revisited

On the macOS host:

```bash
cd /Users/ben/Git/image-exif-gps
xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'
```

Then launch the app and check:

1. The coordinate map renders in the right panel.
2. Latitude `85`, longitude `13` shows the marker directly.
3. Latitude `89`, longitude `13` preserves the selected coordinate and renders the marker at the supported map clamp.
4. Clicking the map updates fields and marker.
5. Search result selection updates fields and marker.
6. Standard, satellite/imagery, and hybrid controls change the map style.
