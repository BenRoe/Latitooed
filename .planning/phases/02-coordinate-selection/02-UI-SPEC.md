---
phase: 2
slug: coordinate-selection
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-17
reviewed_at: 2026-05-17T20:46:13+02:00
---

# Phase 2 - UI Design Contract

> Visual and interaction contract for the native macOS SwiftUI coordinate selection workflow. Generated for Phase 2 and verified against the Phase 2 context, research, and existing Phase 1 app shell.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual native SwiftUI design system |
| Preset | Not applicable |
| Component library | Native SwiftUI controls only |
| Icon library | SF Symbols |
| Font | System font through SwiftUI text styles |

Implementation must stay native SwiftUI plus MapKit. Do not introduce third-party UI frameworks, UIKit/AppKit color bridging in SwiftUI views, custom web-style component registries, or fixed font sizes. The right-side coordinate panel should feel like a dense Mac utility surface rather than a guided wizard.

SwiftUI implementation must preserve accessible labels for visual icon-only controls. `Button("Label", systemImage: ..., action: ...)` may use `.labelStyle(.iconOnly)` for the map overlay, but the label must remain available to VoiceOver and Voice Control.

---

## Layout Contract

| Region | Contract |
|--------|----------|
| Main window | Preserve the existing `HSplitView`: file intake remains on the left, coordinate selection replaces `ReservedLocationPanel` on the right. |
| Right panel | Dense vertical utility panel with a compact control strip above a large map. Avoid large instructional copy. |
| Search row | Topmost control row. Includes search text field and explicit Search action. Search runs on Return or Search, not while typing. |
| Search results | Compact inline list below the search row. It appears only when expanded and contains concise result title/subtitle rows. Empty, no-result, and error states use quiet inline status in the same area. |
| Coordinate fields | Latitude and longitude fields live above the map near search. They are compact, horizontally paired where width allows, and remain visible while the map scroll/interaction area changes. |
| Ready status row | Small row near the fields showing the selected coordinate, e.g. `Target set: 52.520008, 13.404954`. If no target exists, show a low-emphasis neutral state. |
| Map | Primary surface in the right panel. It fills the remaining right-side space and starts centered on Berlin with no target pin. |
| Target marker | Use a single pin marker only. Do not show a coordinate card, callout, or large annotation over the map in Phase 2. |
| Map controls | Standard/satellite/hybrid style controls use small icon overlays on the map, matching the feel of macOS Maps controls. Do not use a segmented control. |
| Footer | Existing app footer may remain general readiness/status. Do not rely on footer as the only selected-coordinate confirmation. |

---

## Visual Hierarchy

| Priority | Element | Rule |
|----------|---------|------|
| 1 | Map | Dominant right-panel surface. It must remain visually and spatially primary after controls are added. |
| 2 | Search and coordinate strip | Compact working controls, not a large form. Use clear labels or placeholders without verbose helper text. |
| 3 | Target pin | The only map target annotation. It should be easy to see without competing with MapKit controls. |
| 4 | Inline search results/status | Secondary. Results should scan quickly and collapse when map/manual entry becomes the active source. |
| 5 | Ready status row | Low-height confirmation that selected coordinate is ready for later batch application. |

The panel must not become card-heavy. Use native surfaces and overlays; avoid nested cards and large bordered explanatory blocks.

---

## Spacing Scale

Use the existing `AppDesign.Spacing` scale:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, compact field-status gaps |
| sm | 8px | Search row gaps, overlay button internal gaps, result row spacing |
| md | 16px | Right-panel control groups, result-list padding, map-to-controls spacing |
| lg | 24px | Right-panel outer padding where map is not full-bleed inside the split area |
| xl | 32px | Reserved only for larger empty regions; avoid in dense Phase 2 controls |
| 2xl | 48px | Not used in Phase 2 right panel |
| 3xl | 64px | Not used in Phase 2 right panel |

Exceptions: MapKit map content and platform map controls may use system metrics. Overlay controls must still provide at least a 44px interactive target even when the visible icon surface is compact.

---

## Typography

Use the same Phase 1 hierarchy and SwiftUI text styles. Do not add new fixed font sizes.

| Role | Size | Weight | Line Height | SwiftUI Style |
|------|------|--------|-------------|---------------|
| Label | 12px | Regular 400 | 1.4 | `.caption` or equivalent platform label style |
| Body | 14px | Regular 400 | 1.5 | `.body` |
| Heading | 17px | Bold 700 | 1.25 | `.headline` with `bold()` only when needed |
| Display | 24px | Bold 700 | 1.2 | Not used in the Phase 2 right panel |

Result rows, validation text, map-control labels, and ready status should use label/body styles. Avoid `.caption2`, negative letter spacing, and `fontWeight(.bold)`.

---

## Color

Use adaptive native colors. Hex values are light-mode references only, not fixed implementation colors.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `appBackground` reference `#F5F5F5` | Window background and broad split layout surfaces |
| Secondary (30%) | `contentSurface` reference `#FFFFFF` | Search/results strip and any non-map right-panel surface |
| Accent (10%) | System accent color, blue reference `#0A84FF` | Search action focus, selected result, selected target pin, keyboard focus ring |
| Warning | `warning` reference `#B26A00` | Invalid coordinate validation and search failure status |
| Destructive | `destructive` reference `#D70015` | Not used in Phase 2 |

Accent reserved for: selected search result, target pin, Search button/focus, active style control, and keyboard focus ring. Do not use accent for all text, all map overlays, all result rows, or decorative panel borders.

---

## Component Contract

| Component | Contract |
|-----------|----------|
| Coordinate selection view | New right-panel view replacing `ReservedLocationPanel`. It owns search, coordinate fields, ready status, and map. |
| Search field | Text input with explicit Search action. Pressing Return and clicking Search both trigger search. No autocomplete/live search in Phase 2. |
| Search action | Labeled command, likely `Button("Search", systemImage: "magnifyingglass", action: ...)`. Disable or no-op on empty/whitespace query. |
| Search results list | Inline compact list below search. Rows show result title and optional subtitle/address. Selecting a row sets coordinate and moves map; do not require persisting full map item metadata. |
| Inline status | Empty query, no results, and search errors use small inline copy in results area. Canceled searches do not show an error. |
| Latitude field | Compact numeric field above map. Invalid values stay editable and show inline validation. Valid values update target immediately. |
| Longitude field | Same behavior as latitude. Valid range is `-180...180`. |
| Ready status | Small text row near controls. When target exists, show coordinates at 6 decimals. |
| Map | SwiftUI MapKit map centered on Berlin by default. It accepts map clicks and displays one pin for selected target. |
| Map click target | Clicking anywhere on the map sets target coordinate, collapses search results, and preserves search query text. |
| Map style overlay | Small overlay control group with icon buttons for standard, satellite/imagery, and hybrid-style presentation. Controls should resemble compact macOS Maps overlays. |

---

## Interaction Contract

| Interaction | Contract |
|-------------|----------|
| Explicit search | Search runs only when user presses Return or activates Search. The app may show progress inline while search is active. |
| Search result selection | Sets selected coordinate, moves map camera to that coordinate, and shows ready status. No extra place metadata is required in Phase 2. |
| No result/error | Show quiet inline status in the result area. Do not use blocking alerts for normal no-result or transient search failure states. |
| Map click | Converts clicked map point to coordinate, sets target, shows pin, collapses results, and leaves query text unchanged. |
| Manual latitude/longitude | Valid edits update target and map immediately. Invalid edits do not replace current target and show inline validation. |
| Search collapse | Map click and manual entry both collapse old search results. |
| Map styles | User can switch among standard, satellite/imagery, and hybrid-style presentations from overlay icon buttons. |
| Keyboard | Search field, Search action, result rows, coordinate fields, and style controls must be keyboard reachable. |

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Search field placeholder | Search for a place |
| Search action | Search |
| Results heading | Results |
| Empty query status | Enter a place name to search. |
| Searching status | Searching... |
| No results status | No places found. Try a different search. |
| Search error status | Places could not be loaded. Try again. |
| Latitude label | Latitude |
| Longitude label | Longitude |
| Invalid latitude | Latitude must be between -90 and 90. |
| Invalid longitude | Longitude must be between -180 and 180. |
| No target status | No target coordinate selected. |
| Target status | Target set: {latitude}, {longitude} |
| Standard map control | Standard |
| Satellite map control | Satellite |
| Hybrid map control | Hybrid |

Avoid generic dialog labels such as Submit, OK, or Save. No destructive confirmation exists in Phase 2.

---

## Accessibility Contract

| Area | Requirement |
|------|-------------|
| Text | Use Dynamic Type-compatible SwiftUI text styles. Do not force fixed font sizes. |
| Icon overlays | Every visually icon-only map overlay button must keep an accessible text label and should expose help/tooltip text where appropriate. |
| Coordinate fields | Labels must be programmatically associated or adjacent enough for VoiceOver clarity. Validation messages must be readable and not color-only. |
| Search results | Result rows must be selectable by keyboard and announce title/subtitle. |
| Map target | Pin state must be reflected outside the map through the ready status row so map visuals are not the only confirmation. |
| Color | Warnings and selected states must include copy, icon, stroke, or shape changes so color is not the only signal. |
| Motion | Camera movement and result collapse should be subtle and respect Reduce Motion. |

---

## Concurrency and State Contract

| Area | Contract |
|------|----------|
| View model | Coordinate selection state belongs in `@Observable @MainActor` state owned by the root or right-panel view with `@State`. |
| Search task | Explicit searches must be cancellable. Starting a new search cancels the previous one. |
| Cancellation | `CancellationError` is normal and must not become a user-facing search error. |
| Actor reentrancy | After any `await`, verify the completed search still matches the current query/request before publishing results. |
| View bodies | Do not place search orchestration, parsing, validation, or map-camera business logic directly in SwiftUI view bodies. |

---

## SwiftData Contract

Phase 2 must not introduce SwiftData models or persistence for coordinate defaults, favorites, or recent coordinates. The user-editable default map location and recent-coordinate history are deferred capabilities. If planning needs a future-facing value type, keep it as a plain Swift value, not a persisted `@Model`.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| Third-party registries | none | not applicable |

No third-party component registries or frameworks are allowed for Phase 2.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-17
