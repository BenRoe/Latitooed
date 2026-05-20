# Phase 5: Packaging and Release Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20T10:40:00+02:00
**Phase:** 5-Packaging and Release Verification
**Areas discussed:** Release artifact shape, No-fallback proof, Sample verification files, Verification interface, Helper failure behavior, Packaging notes

---

## Release Artifact Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Signed `.app` only | Keep Phase 5 focused on proving the packaged app bundle and bundled ExifTool execution; document notarization/DMG as remaining constraints. | ✓ |
| Signed `.app` plus ZIP | Closer to a downloadable artifact, still simpler than DMG/PKG; adds archive verification and optional stapling notes. | |
| Signed + notarized DMG/ZIP | Closest to real distribution, but requires Apple Developer credentials/notary setup and may block the phase on host/account state. | |

**User's choice:** Signed `.app` only.
**Notes:** The phase should not block on notarization or public distribution packaging.

---

## No-Fallback Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Negative PATH test | Run packaged app in a host environment where Homebrew/system ExifTool is unavailable or PATH stripped, then write JPEG/HEIC. | ✓ |
| Rename Homebrew ExifTool temporarily | Stronger but invasive on host. | |
| Static-only proof | Inspect code/project for `Bundle.main` resource and no `/opt/homebrew/bin/exiftool`; faster but weaker. | |

**User's choice:** Negative PATH/no external helper test.
**Notes:** The user clarified that this is a developer-machine verification guard, not a customer requirement. Customers should only need the bundled `.app`.

---

## Sample Verification Files

| Option | Description | Selected |
|--------|-------------|----------|
| Bundled test fixtures copied to temp dir | Add small JPEG and HEIC fixtures in repo/test resources, copy before smoke so originals stay clean. | ✓ |
| User-provided local samples | Avoids repo fixture files, but verification is less repeatable. | |
| Generate samples during test | Possible for JPEG, weaker/riskier for HEIC metadata realism. | |

**User's choice:** Bundled test fixtures copied to a temporary directory.
**Notes:** Smoke mutates copied files only.

---

## Verification Interface

| Option | Description | Selected |
|--------|-------------|----------|
| Manual checklist + exact commands | Document archive/export, launch signed `.app`, select copied fixtures, apply Berlin coordinate, inspect metadata with bundled helper. | ✓ |
| Scripted helper smoke | Add script for archive/resource/codesign checks, but UI write remains manual. | |
| Full scripted end-to-end | Automate build, launch, and metadata write; high effort and brittle for SwiftUI UI. | |

**User's choice:** Manual host checklist with exact commands.
**Notes:** Keep this robust and explicit rather than over-automated.

---

## Helper Failure Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Unit/integration tests plus packaged happy path | Keep missing/non-executable/fail-launch in tests; packaged app smoke proves real happy path. | ✓ |
| Manual packaged failure variants too | Duplicate app bundle, remove/chmod helper, launch each. Stronger but awkward. | |
| Only existing tests | Fastest, but may under-cover PKG-03 if gaps exist. | |

**User's choice:** Unit/integration tests for failure paths plus one packaged happy path.
**Notes:** Existing resolver tests can be reused or strengthened; manual packaged failure variants are not required.

---

## Packaging Notes

| Option | Description | Selected |
|--------|-------------|----------|
| Signed app verified; notarization/DMG deferred | Honest Phase 5 closeout with exact remaining steps. | ✓ |
| Treat notarization as required | Stronger release bar, may block on Apple credentials. | |
| Minimal note only | Mention outside-App-Store assumption without detailed next steps. | |

**User's choice:** Clear signed-app verification with notarization/DMG deferred.
**Notes:** The docs should be explicit about remaining distribution constraints.

---

## the agent's Discretion

- Exact fixture paths.
- Exact packaging verification document filename.
- Exact command syntax and whether to add small static-check scripts.
- Whether existing helper failure tests need targeted additions.

## Deferred Ideas

- Notarized ZIP or DMG distribution.
- Stapled notarization ticket.
- Installer package, updater, public release automation, or download page.
- Full scripted SwiftUI end-to-end packaged-app automation.
