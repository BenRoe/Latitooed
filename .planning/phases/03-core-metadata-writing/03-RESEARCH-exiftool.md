## RESEARCH COMPLETE

**Phase:** 3 - Core Metadata Writing  
**Slice:** Bundled ExifTool write path for JPEG/HEIC GPS metadata  
**Researched:** 2026-05-18  
**Confidence:** HIGH for ExifTool GPS arguments and overwrite behavior; MEDIUM for final app-bundle placement because signing/package verification is Phase 5.

## Summary Recommendation

Use the bundled ExifTool command-line application as the only Phase 3 metadata writer, resolved from `Bundle.main` as an executable resource and launched with `Process.executableURL` plus `Process.arguments`. Do not discover `/usr/local/bin/exiftool`, `/opt/homebrew/bin/exiftool`, or `PATH`. This preserves META-05/META-06 and proves the no-Homebrew runtime path early. [VERIFIED: Context7 `/websites/developer_apple`; CITED: https://developer.apple.com/documentation/foundation/bundle/url(forauxiliaryexecutable:); VERIFIED: local `03-CONTEXT.md`]

For JPEG and HEIC still images, prefer ExifTool's writable `Composite:GPSPosition` path when the bundled version is at least ExifTool 12.36: pass `-GPSPosition=<signed latitude>, <signed longitude>` so ExifTool writes `GPSLatitude`, `GPSLatitudeRef`, `GPSLongitude`, and `GPSLongitudeRef` together. ExifTool's FAQ documents `GPSPosition` as writable from 12.36 and says it writes all four EXIF GPS coordinate/reference tags. [VERIFIED: Context7 `/exiftool/exiftool`; CITED: https://exiftool.org/faq.html; CITED: https://exiftool.org/TagNames/Composite.html]

Because Phase 3 decision D-01 locks destructive in-place overwrite with no `_original` backups, include `-overwrite_original` in write arguments after the blocking app confirmation. ExifTool's normal write mode preserves originals with `_original` appended; `-overwrite_original` replaces the original file instead. This matches D-01 only if the confirmation copy is explicit and no write starts before confirmation. [VERIFIED: Context7 `/exiftool/exiftool`; CITED: https://exiftool.org/exiftool_pod.html; CITED: https://exiftool.org/faq.html; VERIFIED: local `03-CONTEXT.md`]

## External Source Notes

### Bundled ExifTool Strategy

- ExifTool is a platform-independent Perl library plus command-line application for reading, writing, and editing metadata in many file types, including EXIF and GPS metadata. [CITED: https://exiftool.org/]
- Official ExifTool docs say the full distribution includes the `exiftool` application and `Image::ExifTool` package, and can run directly after extraction with `DIR/exiftool FILE` without installing globally. [CITED: https://exiftool.org/]
- Official ExifTool docs also offer a macOS package, but that package installs into `/usr/local/bin`; Phase 3 should not use that installer path because the project requires a bundled helper and no Homebrew/system install dependency. [CITED: https://exiftool.org/; VERIFIED: local `.planning/REQUIREMENTS.md` META-05]
- For app code, Apple's `Bundle` API provides `url(forAuxiliaryExecutable:)` for executables in the app bundle and `url(forResource:withExtension:subdirectory:)` for bundle resources. Prefer `url(forAuxiliaryExecutable:)` if Phase 3 places ExifTool as a helper executable in the bundle's auxiliary executable location; otherwise use `url(forResource:...)` only if the Xcode resource phase places it under `Resources`. [VERIFIED: Context7 `/websites/developer_apple`; CITED: https://developer.apple.com/documentation/foundation/bundle/url(forauxiliaryexecutable:)]
- Apple's `Process` examples set `process.executableURL`, `process.arguments`, `standardOutput`, `standardError`, call `run()`, and inspect `terminationStatus`; this supports the project requirement to avoid shell command strings. [VERIFIED: Context7 `/websites/developer_apple`; CITED: https://developer.apple.com/forums/thread/690310]

### GPS Write Arguments for JPEG and HEIC

- ExifTool writable file-type docs list JPEG and HEIC as read/write formats, so both are valid Phase 3 targets for ExifTool writes. [CITED: https://exiftool.org/exiftool_pod.html]
- ExifTool 11.33 added HEIC/HEIF write support; this is far older than the `GPSPosition` minimum, so a bundled ExifTool new enough for `GPSPosition` also covers HEIC write availability. [VERIFIED: Context7 `/exiftool/exiftool`; CITED: https://github.com/exiftool/exiftool/blob/master/html/ancient_history.html]
- ExifTool FAQ documents explicit EXIF GPS writes as `-exif:gpslatitude=<value> -exif:gpslatituderef=<N/S>` and equivalent longitude tags. [CITED: https://exiftool.org/faq.html]
- ExifTool GPS tag docs define `GPSLatitudeRef` values as `N` or `S`, and `GPSLongitudeRef` values as `E` or `W`; they also accept signed numbers when writing refs. [CITED: https://exiftool.org/TagNames/GPS.html]
- ExifTool FAQ documents `-gpsposition="-42.5, -33.25"` as a signed decimal coordinate form and says writable `Composite:GPSPosition` updates `GPSLatitude`, `GPSLatitudeRef`, `GPSLongitude`, and `GPSLongitudeRef`. [CITED: https://exiftool.org/faq.html; CITED: https://exiftool.org/TagNames/Composite.html]
- Recommended Phase 3 argument builder for a single eligible still image:

```text
[
  "-overwrite_original",
  "-GPSPosition=<latitude>, <longitude>",
  "<file path>"
]
```

The app must pass this as an argument array, with the full file path as its own argument, never as a shell-escaped command string. This preserves spaces, Unicode, and external-drive paths already covered by FILE-05. [VERIFIED: local `.planning/REQUIREMENTS.md`; VERIFIED: Context7 `/websites/developer_apple`]

- If the planner wants a fallback argument path for a lower bundled ExifTool version, use explicit EXIF tags:

```text
[
  "-overwrite_original",
  "-EXIF:GPSLatitude=<abs latitude>",
  "-EXIF:GPSLatitudeRef=<N or S>",
  "-EXIF:GPSLongitude=<abs longitude>",
  "-EXIF:GPSLongitudeRef=<E or W>",
  "<file path>"
]
```

This fallback is less compact but directly matches ExifTool GPS tag docs. Prefer avoiding fallback complexity by vendoring a current ExifTool version and asserting it is >= 12.36 in a unit/smoke test. [CITED: https://exiftool.org/faq.html; CITED: https://exiftool.org/TagNames/GPS.html]

### Original Preservation and Overwrite Policy

- ExifTool's default write behavior preserves the original file by appending `_original`; this is the standard safety default. [CITED: https://exiftool.org/exiftool_pod.html]
- `-overwrite_original` modifies in place without creating that backup; official docs caution to use it only when backups exist. [VERIFIED: Context7 `/exiftool/exiftool`; CITED: https://exiftool.org/exiftool_pod.html]
- Phase 3 explicitly chooses in-place overwrite and no `_original` backup, so the planner should make `-overwrite_original` unconditional only after the blocking confirmation returns Overwrite. If the user aborts, do not build or launch any ExifTool process. [VERIFIED: local `03-CONTEXT.md` D-01 through D-04]

### Warning/Error Interpretation

- Treat `Process.run()` throwing as a launch-level failure: missing helper, non-executable helper, denied execution, or invalid executable URL. Map this to a structured failure with a user-facing helper error and diagnostic detail. [VERIFIED: Context7 `/websites/developer_apple`; CITED: https://developer.apple.com/forums/thread/690310]
- Treat nonzero `terminationStatus` as a file write failure unless stdout/stderr clearly indicate "0 image files updated" with warnings only; preserve stdout, stderr, and status in diagnostic detail for Phase 4 review/export later. [ASSUMED]
- Treat `terminationStatus == 0` plus warning text on stdout/stderr as a success-with-warning candidate, not as an automatic failure. ExifTool can surface warnings separately from fatal errors in its API, but CLI warning routing can vary by operation, so Phase 3 should capture both pipes and keep diagnostics. [CITED: https://www.exiftool.org/ExifTool.html; ASSUMED]
- Do not parse localized or prose ExifTool output as the only source of truth. Use exit status for coarse success/failure, retain stdout/stderr for diagnostics, and keep user-facing messages app-owned and stable. [ASSUMED]

## Planning Implications

- Add a metadata-writing service boundary, for example `MetadataWriter` plus `ExifToolMetadataWriter`, with a small `ExifToolGPSArgumentBuilder` that can be unit-tested without launching ExifTool. This directly supports D-08 and META-06. [VERIFIED: local `03-CONTEXT.md`]
- Resolve the helper through a dedicated dependency, for example `ExifToolExecutableResolver`, so tests can inject missing/non-executable URLs and the app never falls back to `PATH`. [VERIFIED: local `03-CONTEXT.md`; VERIFIED: Context7 `/websites/developer_apple`]
- Keep each write invocation single-file and sequential in Phase 3. Mixed selections should write JPEG/HEIC and return warning results for MOV/MP4 stating video writing is deferred to Phase 4. [VERIFIED: local `03-CONTEXT.md` D-09 through D-11]
- Reacquire security-scoped access around the actual ExifTool invocation, matching the existing intake service's `startAccessingSecurityScopedResource()` pattern. [VERIFIED: local `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift`]
- Update `SelectedMediaFile` snapshots by replacement after each file result: success should set `gpsStatus` to `.updated`, `latestResult` to `.success`, and a compact latest message; unsupported/deferred files should use `.warning`; write/launch failures should use `.failure`. [VERIFIED: local `SelectedMediaFile.swift`, `GPSStatus.swift`, `FileResultStatus.swift`]
- Tests should cover argument construction for northern/eastern, southern/western, zero, path with spaces, and Unicode path cases. Tests should assert each argument is a separate array element and no shell command string is produced. [VERIFIED: local `GPSMetadataEditorTests/FileIntakeServiceTests.swift`; VERIFIED: local `.planning/REQUIREMENTS.md` FILE-05/META-06]
- Add a launch abstraction or process runner protocol so unit tests can simulate stdout, stderr, thrown launch errors, and exit status without requiring host ExifTool. Real bundled-helper execution can remain a host-side/manual smoke check until packaging phases. [ASSUMED]

## Risks/Non-Goals

- **Bundling risk:** The official macOS package installs to `/usr/local/bin`, which is not suitable for the app's no-system-dependency requirement. The planner must specify how the full ExifTool distribution or extracted executable/helper payload is added to the Xcode target without relying on the system install. [CITED: https://exiftool.org/; VERIFIED: local `.planning/REQUIREMENTS.md` META-05]
- **Perl/runtime risk:** Official ExifTool docs say macOS/Unix users already have Perl installed, but app distribution should verify this on the target macOS versions during Phase 5. Phase 3 should avoid claiming release packaging is solved by source-level bundling alone. [CITED: https://exiftool.org/; ASSUMED]
- **HEIC mutation risk:** ExifTool has a documented historical HEIC/HDR gain-map issue around adding XMP; Phase 3 writes EXIF GPS only, but host-side smoke tests should include at least one real HEIC sample and verify Apple Preview/Photos can still open it. [CITED: https://exiftool.org/]
- **Destructive write risk:** `-overwrite_original` intentionally removes ExifTool's `_original` safety copy. This is locked by D-01, but the UI confirmation and result reporting must make the consequence clear. [CITED: https://exiftool.org/exiftool_pod.html; VERIFIED: local `03-CONTEXT.md`]
- **No video implementation:** MOV/MP4 ExifTool GPS writes are out of scope for this slice and Phase 3. Mixed selections should produce warning results only for video files. [VERIFIED: local `03-CONTEXT.md`]
- **No native Image I/O fallback:** Native still-image writing remains a future option and should not be introduced in Phase 3. [VERIFIED: local `.planning/REQUIREMENTS.md` META-08 as v2]
- **No progress/cancellation/history:** The ExifTool runner should be shaped so Phase 4 can add cancellation, but Phase 3 should not add a progress UI, cancellation control, result drawer, or persistent history. [VERIFIED: local `03-CONTEXT.md` D-14]

## Sources

- Context7 `/exiftool/exiftool` docs queries: GPS write tags, `GPSPosition`, explicit EXIF GPS refs, HEIC write support, `-overwrite_original`.
- Context7 `/websites/developer_apple` docs queries: `Bundle` resource/executable lookup and `Process` executable URL/arguments/output patterns.
- ExifTool official home: https://exiftool.org/
- ExifTool FAQ: https://exiftool.org/faq.html
- ExifTool application docs: https://exiftool.org/exiftool_pod.html
- ExifTool GPS tags: https://exiftool.org/TagNames/GPS.html
- ExifTool Composite tags: https://exiftool.org/TagNames/Composite.html
- Apple `Bundle.url(forAuxiliaryExecutable:)`: https://developer.apple.com/documentation/foundation/bundle/url(forauxiliaryexecutable:)
- Apple Developer Forums process example: https://developer.apple.com/forums/thread/690310
- Local context: `.planning/phases/03-core-metadata-writing/03-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `AGENTS.md`
