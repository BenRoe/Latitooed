---
quick_id: 260524-w2v
slug: scan-loaded-media-for-existing-latitude-
status: executing
created: 2026-05-24
---

Scan accepted media files for existing latitude/longitude metadata after intake and update the existing GPS status badge to `Has GPS` or `No GPS`.

Success criteria:
- Accepted files no longer stay at `Not checked` after the app scans metadata.
- The scan looks for coordinate metadata only; it does not attempt reverse geocoding or place names.
- Existing write-result states remain separate from GPS presence.
