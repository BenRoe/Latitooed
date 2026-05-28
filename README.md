<div align="center">
  <img src="docs/app-icon-rounded.png" width="96" alt="Latitooed icon">
  <h1>Latitooed</h1>
  <p>Ink your coordinates into every shot.</p>
</div>

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
git clone https://github.com/BenRoe/image-exif-gps.git
cd image-exif-gps
open Latitooed.xcodeproj
```

Select the `Latitooed` scheme and press **Run**.

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
