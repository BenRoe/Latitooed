# Host Xcodebuild Verification Boundary

## Finding

The VM environment used by Codex does not have `xcodebuild` available:

```text
zsh:1: command not found: xcodebuild
```

## Impact

Codex can run local text checks such as `git diff --check`, but real Swift compile and test verification must run on the macOS host with Xcode installed.

## Host Command

Run from the host checkout:

```bash
cd /Users/ben/Git/image-exif-gps
xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'
```

## Reporting Rule

Do not mark a Swift/Xcode phase fully verified from VM-only checks. Report host-side `xcodebuild` as pending unless the user provides the host result.

