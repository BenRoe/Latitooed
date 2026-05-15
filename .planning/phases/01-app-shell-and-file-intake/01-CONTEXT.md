# Phase 1: App Shell and File Intake - Context

**Gathered:** 2026-05-15T23:25:26+02:00
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 delivers the native macOS SwiftUI app shell and file-intake workflow. Users can launch the utility, add multiple supported local media files through picker and drag/drop, review the selected-file set, and see clear warnings for files that cannot be accepted. Coordinate selection, metadata reading/writing, batch execution, persistence, and packaging are later phases.

</domain>

<decisions>
## Implementation Decisions

### Main Window Shape
- **D-01:** Use a drop-zone-first launch experience so adding files is obvious before any files are selected.
- **D-02:** After files are added, keep a compact persistent drop strip above the selected-file table so users can add more files at any time.
- **D-03:** Build the main window as a split layout now, reserving the right side for the future coordinate/map area from Phase 2.
- **D-04:** The right-side Phase 1 placeholder should stay visually quiet and minimal; it must not imply that coordinate selection exists yet.
- **D-05:** Include a small footer/status area for future batch/location state, but keep Phase 1 focused on file intake.

### Accepted File Set
- **D-06:** Only JPEG, HEIC, MOV, and MP4 files enter the selected-file table in Phase 1.
- **D-07:** Unsupported files should be rejected from the selected-file set and reported through warnings.
- **D-08:** Classify file type using platform file type information where available, falling back to case-insensitive file extensions.
- **D-09:** Do not perform deep content sniffing in Phase 1 unless planning finds it necessary for a simple warning.
- **D-10:** Prevent duplicate rows by URL. Re-selecting or re-dropping the same file must not create another row.
- **D-11:** Reject directories in Phase 1 with a clear warning.

### File Row Information
- **D-12:** Use compact selected-file rows: display name, type badge, GPS status icon, and latest result.
- **D-13:** Put selected-file details in an extra bottom area of the left column. Selecting a row can populate that area with path/access/warning details.
- **D-14:** Do not use the right-side placeholder for selected-file details; it is reserved for the future coordinate/map area.
- **D-15:** Scaffold the GPS status icon model with eventual states for no GPS data, has GPS data, and updated GPS data.
- **D-16:** In production Phase 1, newly added files default to an honest unknown/not-checked GPS state until real metadata reading exists.
- **D-17:** In the bottom detail area, show containing folder plus filename rather than always showing the full path.

### Warning Behavior
- **D-18:** Unsupported-file warnings should use a transient notice plus a warning summary/details area in the bottom-left portion of the interface.
- **D-19:** For bulk drops, list every rejected item immediately in the warning details rather than only summarizing by reason.
- **D-20:** Inaccessible, read-only, locked, or missing target-format files should be rejected before entering the selected-file table.
- **D-21:** Warning details describe the most recent picker/drop action and persist until the next intake event.

### the agent's Discretion
- No decisions were delegated entirely to the agent. Planner may choose native SwiftUI control details that preserve the locked layout and behavior above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope
- `.planning/PROJECT.md` — Defines the product, native macOS direction, self-contained workflow, and v1 constraints.
- `.planning/REQUIREMENTS.md` — Defines Phase 1 requirements FILE-01 through FILE-05 and their traceability.
- `.planning/ROADMAP.md` — Defines Phase 1 goal, success criteria, and implementation notes.
- `.planning/STATE.md` — Captures current project focus and carried-forward decisions.

No external specs or ADRs were referenced during discussion.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No app source files exist yet. Phase 1 is expected to establish the initial SwiftUI app structure.

### Established Patterns
- No code patterns exist yet. Follow repository instructions: macOS SwiftUI, modern Swift concurrency, value-type selected-file snapshots, and file access handling outside SwiftUI view bodies.

### Integration Points
- The new app shell should create the foundation for Phase 2 coordinate/map UI on the reserved right side.
- The selected-file model should leave room for later metadata reading/writing and batch result updates.

</code_context>

<specifics>
## Specific Ideas

- The first screen should feel approachable through a large drop zone.
- Once files exist, the left column should contain a compact drop strip, compact file rows, and a bottom details/warnings area.
- GPS status should eventually be icon-driven, with states for no GPS data, existing GPS data, and updated GPS data.

</specifics>

<deferred>
## Deferred Ideas

- Recursive folder scanning for dropped folders, including traversal policy and nested-file warning behavior, should be considered as a future capability outside Phase 1.

</deferred>

---

*Phase: 1-App Shell and File Intake*
*Context gathered: 2026-05-15T23:25:26+02:00*
