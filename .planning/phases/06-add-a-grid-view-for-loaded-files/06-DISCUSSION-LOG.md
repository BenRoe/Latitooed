# Phase 6: Loaded Files Grid View - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-24T10:29:48Z
**Phase:** 06-Loaded Files Grid View
**Areas discussed:** View Switch Behavior, Grid Cell Design, Selection Model, Scale and Empty States

---

## View Switch Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Segmented control | A compact Table/Grid segmented control beside the Selected Files header. | yes |
| Toolbar-style icon buttons | Uses table/grid icons in the header. | |
| Menu setting | Keeps the surface quieter, but hides a core view-mode feature. | |

**User's choice:** Segmented control
**Notes:** The control should be local to the selected-files surface.

| Option | Description | Selected |
|--------|-------------|----------|
| Table by default | Preserves the existing dense review workflow. | |
| Grid by default | Makes the new visual workflow prominent. | yes |
| Remember last mode | Polished, but adds persistence or session state. | |

**User's choice:** Grid by default
**Notes:** Grid mode should be the default once files are loaded.

| Option | Description | Selected |
|--------|-------------|----------|
| Session-only | Keep the mode while the app window/session is alive. | yes |
| Persist across launches | Adds app preference persistence. | |
| Do not remember | Always reset on reload. | |

**User's choice:** Session-only
**Notes:** Do not add cross-launch preferences in this phase.

| Option | Description | Selected |
|--------|-------------|----------|
| Selected Files header | Put it beside the file count in the left review header. | yes |
| Footer | Keeps it near Apply Location. | |
| Window toolbar | Native-feeling, but broader than the feature scope. | |

**User's choice:** Selected Files header
**Notes:** The segmented control belongs beside the count in the selected-files header.

---

## Grid Cell Design

| Option | Description | Selected |
|--------|-------------|----------|
| Thumbnail-first cards | Large thumbnail or file-type fallback, with filename and compact status below. | yes |
| Status-first tiles | File type/result badges are most prominent, thumbnails secondary. | |
| Minimal filename cards | Filename plus status only. | |

**User's choice:** Thumbnail-first cards
**Notes:** The grid should deliver a genuinely visual browsing mode.

| Option | Description | Selected |
|--------|-------------|----------|
| Filename + type + GPS + result | Mirrors the table's core columns in compact card form. | yes |
| Filename + result only | Cleaner cards, but weaker for pre-write review. | |
| Filename + type only | Good for visual browsing, but hides write/GPS state too much. | |

**User's choice:** Filename + type + GPS + result
**Notes:** Grid mode should remain functionally equivalent to the table's core review information.

| Option | Description | Selected |
|--------|-------------|----------|
| File-type fallback icon | Use native symbol-style fallback by media kind, plus the type badge/status text. | yes |
| Blank placeholder | Quiet, but looks broken when many videos are loaded. | |
| Filename-only fallback | Simple, but visually weak and harder to scan. | |

**User's choice:** File-type fallback icon
**Notes:** Non-image files and thumbnail failures should be intentional visual states.

| Option | Description | Selected |
|--------|-------------|----------|
| Medium cards | Enough room for thumbnail/fallback plus 2-3 compact status lines. | yes |
| Compact cards | More files visible, but filenames/statuses get cramped quickly. | |
| Large cards | Better thumbnails, but poor for bulk review. | |

**User's choice:** Medium cards
**Notes:** Balance visual browsing with bulk review density.

---

## Selection Model

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror table multi-selection | Grid uses the same selectedFileIDs set, supports multi-select, and feeds the same detail panel. | yes |
| Single-selection grid only | Simpler visual behavior, but grid and table would not be equivalent. | |
| No grid selection | Clicking a card only previews details; batch still applies to all loaded files. | |

**User's choice:** Mirror table multi-selection
**Notes:** Grid and table should behave like one loaded-file browser.

| Option | Description | Selected |
|--------|-------------|----------|
| Replace selection with that card | Finder-like default. | yes |
| Toggle that card | Useful for touch-like selection, but less native for macOS desktop. | |
| Open/expand details only | Keeps selection separate, but makes the grid harder to use for review. | |

**User's choice:** Replace selection with that card
**Notes:** Plain click should select one card.

| Option | Description | Selected |
|--------|-------------|----------|
| Command-click toggles, Shift-click range selects | Best match for macOS multi-selection and table behavior. | yes |
| Command-click only | Easier to implement, but weaker for large batches. | |
| No modifier selection | Simplest, but inconsistent with the table. | |

**User's choice:** Command-click toggles, Shift-click range selects
**Notes:** Support native-feeling multi-selection when cleanly possible.

| Option | Description | Selected |
|--------|-------------|----------|
| First selected in file order | Matches the current view model's derived detail behavior. | |
| Selection summary | Shows N files selected instead of one file's details. | yes |
| Last clicked item | Requires tracking focus separately from selection. | |

**User's choice:** Selection summary
**Notes:** This is a deliberate change from current derived detail behavior for multi-selection.

---

## Scale and Empty States

| Option | Description | Selected |
|--------|-------------|----------|
| Scrollable adaptive grid | Use a vertically scrolling adaptive grid with stable medium card width. | yes |
| Paged grid | Keeps layout bounded, but adds navigation and state. | |
| Fixed columns | Predictable, but wastes space or cramps cards as the window changes. | |

**User's choice:** Scrollable adaptive grid
**Notes:** Fits SwiftUI `LazyVGrid` and the left review pane.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep existing drop zone only | The grid/table switch appears after files are loaded; empty state stays focused on adding files. | yes |
| Show grid empty state | Makes the new mode visible, but duplicates the existing drop-zone purpose. | |
| Show disabled segmented control | Signals the feature, but adds inactive UI before it helps. | |

**User's choice:** Keep existing drop zone only
**Notes:** Do not make the first-launch intake state busier.

| Option | Description | Selected |
|--------|-------------|----------|
| Compact status badges with color + icon | Keeps cards scannable and accessible if labels are still present. | yes |
| Colored card border only | Clean, but weaker for accessibility and status precision. | |
| Full message text on each card | Explicit, but too noisy for bulk review. | |

**User's choice:** Compact status badges with color + icon
**Notes:** Avoid relying on color alone.

| Option | Description | Selected |
|--------|-------------|----------|
| Best-effort thumbnails with fallback | Show previews where easy, but the grid must remain useful with fallback icons. | yes |
| Fallback icons only | Faster and simpler, but less of a visual grid. | |
| Robust thumbnail pipeline | Better polish, but risks turning this into a media preview/performance phase. | |

**User's choice:** Best-effort thumbnails with fallback
**Notes:** The phase should not become a robust thumbnail infrastructure project.

## the agent's Discretion

- Exact type names, segmented-control implementation details, thumbnail loading mechanism, adaptive card width, and selection helper structure.

## Deferred Ideas

- None.
