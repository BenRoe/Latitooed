# Phase 2: Coordinate Selection - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-17T20:32:27+02:00
**Phase:** 2-Coordinate Selection
**Areas discussed:** Search Result Flow, Map Click and Target Marker, Manual Coordinate Entry, Map Style Controls and Panel Layout

---

## Search Result Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Inline list | Compact results below the search field; selection stays in the same panel. | Yes |
| Map overlay | Results appear over the map; keeps geography central but can feel cramped. | |
| Popover | Transient results from the search field; lighter but easier to lose. | |

**User's choice:** Inline list below the search field.
**Notes:** Search selection sets coordinate only, search runs on explicit action, and no-result/error states stay quiet and inline.

---

## Map Click and Target Marker

| Option | Description | Selected |
|--------|-------------|----------|
| Click map | Click anywhere to set target coordinate. | Yes |
| Select map feature | Select known place/POI only. | |
| Both | Support map click and feature selection. | |
| Pin plus coordinate card | Visible marker plus compact lat/lon card. | |
| Pin only | Clean map marker without extra card. | Yes |
| Crosshair target | Center-map style targeting. | |

**User's choice:** Click anywhere sets coordinate; marker is pin only.
**Notes:** Map clicks collapse search results but keep query text. Default map region is Berlin with no fake pin.

---

## Manual Coordinate Entry

| Option | Description | Selected |
|--------|-------------|----------|
| Live valid edits | Valid number updates pin/map immediately. | Yes |
| Apply button | User edits fields, then applies coordinate. | |
| On submit | Return commits values. | |
| Inline validation | Keep field editable; show error; target updates only when valid. | Yes |
| Clamp to range | Force latitude/longitude into valid bounds. | |
| Reject keystroke | Prevent invalid input while typing. | |

**User's choice:** Live valid edits with inline validation.
**Notes:** Coordinates display at 6 decimal places. Manual entry collapses old search results.

---

## Map Style Controls and Panel Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Segmented control | Standard/satellite/hybrid visible above map. | |
| Toolbar menu | Cleaner but less obvious. | |
| Map overlay icons | Small icon controls on map. | Yes |
| Fields below map | Stable and easy to scan. | |
| Fields above map | Keeps search and coordinate input together. | Yes |
| Dense pro layout | Minimal labels and more map space. | Yes |
| Small status row | Shows target coordinate ready state near controls. | Yes |

**User's choice:** Use macOS Maps-style small icon overlays; coordinate fields above map; dense pro layout; small status row for selected coordinate.
**Notes:** User provided screenshot reference for macOS Maps overlay control style.

---

## the agent's Discretion

- Exact SwiftUI file split, MapKit camera defaults, icon names, and spacing can be chosen by planner/implementer within the locked behavior.

## Deferred Ideas

- User-editable default map location setting.
