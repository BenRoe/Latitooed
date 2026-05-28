<div align="center">
  <img src="docs/app-icon-rounded.png" width="96" alt="Latitooed icon">
  <h1>Latitooed</h1>
  <p>Ink your coordinates into every shot.</p>
  <a href="https://github.com/BenRoe/Latitooed/releases/latest">⬇️ Download latest release</a>
</div>

---

> **Note:** Latitooed is not code-signed or notarized. On first launch macOS will block it. Right-click the app → **Open** to proceed, or run:
> ```bash
> xattr -cr /Applications/Latitooed.app
> ```

---

## What it does

Select multiple image or video files, pick a location via map search or manual coordinates, and write that GPS data to all files at once.

**Supported formats:** JPEG, HEIC, PNG, TIFF, RAW variants, MOV, MP4 (best effort)

---

## Privacy first

Everything runs locally on your Mac. No files are uploaded, no analytics collected, no network requests made (except Apple Maps for map tiles and location search). GPS data is written directly to your files using a bundled copy of ExifTool — no external services involved.

---

## Libraries & tools

| Component        | Library                                    |
| ---------------- | ------------------------------------------ |
| UI               | SwiftUI                                    |
| Maps & search    | MapKit                                     |
| Persistence      | SwiftData                                  |
| Metadata writing | [ExifTool](https://exiftool.org) (bundled) |

---

## Build from source

**Requirements:** macOS 15+, Xcode 26+

```bash
git clone https://github.com/BenRoe/Latitooed.git
cd image-exif-gps
open Latitooed.xcodeproj
```

Select the `Latitooed` scheme and press **Run**.

To build a distributable DMG:

```bash
./scripts/build-dmg.sh
# outputs: dist/Latitooed-<version>.dmg
```

> **First launch:** macOS will show a Gatekeeper warning since the app is unsigned. Right-click → Open to proceed, or run `xattr -cr /Applications/Latitooed.app`.

---

## Contributing

### AI agent skills

This project uses [twostraws](https://github.com/twostraws) Swift agent skills for SwiftUI, SwiftData, Swift Testing, and Swift Concurrency. Install them with:

```bash
npx skills add twostraws/swiftui-agent-skill
npx skills add twostraws/swiftdata-agent-skill
npx skills add twostraws/swift-testing-agent-skill
npx skills add twostraws/swift-concurrency-agent-skill
```

### Code intelligence

[GitNexus](https://github.com/abhigyanpatwari/GitNexus) — call graph indexer that maps symbols and execution flows, used here for impact analysis before edits.

### Workflow

Built with [GSD Redux](https://github.com/open-gsd/get-shit-done-redux) — community fork of the Get Shit Done planning and execution workflow for Claude Code.

---

## Note

This app was built with the assistance of AI (Claude Code and Codex).
