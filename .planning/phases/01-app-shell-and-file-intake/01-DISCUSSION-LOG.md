# Phase 1: App Shell and File Intake - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-15T23:25:26+02:00
**Phase:** 1-App Shell and File Intake
**Areas discussed:** Main Window Shape, Accepted File Set, File Row Information, Warning Behavior

---

## Main Window Shape

| Decision Point | Options Considered | Selected |
|----------------|--------------------|----------|
| First launch feel | Table-first utility; Drop-zone-first; Split utility layout; You decide | Drop-zone-first |
| Drop zone after files exist | Compact persistent drop strip; Table takes over; Empty-state only; You decide | Compact persistent drop strip |
| Anticipating future map area | Reserve no map space yet; Leave a right-side placeholder; Small status/footer only; You decide | Hybrid: right-side placeholder plus footer/status area |
| Right-side placeholder content | Selected coordinate pending; File summary panel; Minimal blank reserve; You decide | Minimal blank reserve |

**User's choice:** Drop-zone-first shell with persistent compact drop strip, split layout reserved for Phase 2, quiet right-side placeholder, and small footer/status area.
**Notes:** The placeholder should not imply Phase 2 functionality exists yet.

---

## Accepted File Set

| Decision Point | Options Considered | Selected |
|----------------|--------------------|----------|
| Unsupported files | Accept target formats only; Accept common media broadly; Accept any file as a row; You decide | Accept target formats only |
| Type classification | Extension-based for Phase 1; Type identifier aware; Content sniffing; You decide | Type identifier aware |
| Duplicate files | Prevent duplicates by URL; Allow duplicates; Replace existing row; You decide | Prevent duplicates by URL |
| Dropped directories | Reject directories; Shallow scan; Recursive scan; You decide | Recursive scan requested, deferred; Phase 1 rejects directories |

**User's choice:** Accept only JPEG, HEIC, MOV, and MP4 into the selected-file table; use platform file type information where available; prevent duplicate URL rows.
**Notes:** Recursive folder scanning was treated as scope creep for Phase 1 and captured as a deferred idea.

---

## File Row Information

| Decision Point | Options Considered | Selected |
|----------------|--------------------|----------|
| Row emphasis | Operational basics; Trust details; Compact batch list; You decide | Compact batch list |
| Detail access | Expandable row; Inspector/details panel; Popover or sheet; No details in Phase 1 | Extra bottom area in the left column |
| GPS status display | Placeholder text; Unknown status badge; Fake/sample states for UI only; You decide | Small GPS status icon states |
| Phase 1 default GPS state | Unknown/not checked; No GPS data placeholder; Mixed mock states in debug only; You decide | Unknown/not checked |
| Path detail | Full path always; Containing folder plus filename; Collapsed full path with copy action; You decide | Containing folder plus filename |

**User's choice:** Compact rows with display name, type badge, GPS status icon, and latest result; selected-file details appear in a bottom-left area.
**Notes:** GPS icons should eventually represent no GPS data, has GPS data, and updated GPS data, but Phase 1 defaults to unknown/not checked.

---

## Warning Behavior

| Decision Point | Options Considered | Selected |
|----------------|--------------------|----------|
| Unsupported-file warning placement | Transient notice plus warning summary; Modal alert; Inline rejection list; You decide | Transient notice plus warning summary |
| Bulk rejected files | Summarize by reason; List every rejected item immediately; Show first few plus count; You decide | List every rejected item immediately |
| Inaccessible/read-only/locked/missing target files | Stay in table with warning state; Reject before table; Ask per batch/intake event; You decide | Reject before table |
| Warning persistence | Until next intake event; For the session; Until user clears; You decide | Until next intake event |

**User's choice:** Use immediate transient feedback plus bottom-left warning details; list all rejected items; keep selected-file table limited to eligible files.
**Notes:** Rejection details describe the most recent intake event only.

---

## the agent's Discretion

- No major decisions were delegated entirely to the agent.

## Deferred Ideas

- Recursive folder scanning for dropped folders, including traversal policy and nested-file warning behavior.
