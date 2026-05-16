# Phase 01-05 Verification Instructions

Use this checklist after executing `01-05-PLAN.md`.

## Purpose

Plan `01-05` closes the Phase 1 verification blocker by converting the Phase 1 roadmap goal into a valid MVP user story.

The expected user story is:

```text
As a Mac user, I want to select and review supported local media files, so that I can prepare them for GPS metadata editing.
```

## Steps

1. Execute only the Phase 1 gap-closure plan:

   ```bash
   $gsd-execute-phase 1 --gaps-only
   ```

2. Confirm the user story validates:

   ```bash
   gsd-sdk query user-story.validate --story "As a Mac user, I want to select and review supported local media files, so that I can prepare them for GPS metadata editing." --pick valid
   ```

   Expected output:

   ```text
   true
   ```

3. Confirm `.planning/ROADMAP.md` has the same user story in both places:

   - Phase 1 row in the `## Overview` table.
   - Phase 1 detailed section line starting with `**Goal:**`.

4. Confirm Phase 1 still has MVP mode enabled:

   ```bash
   rg -n "\\*\\*Mode:\\*\\* mvp" .planning/ROADMAP.md
   ```

5. Confirm the plan produced its summary:

   ```bash
   test -f .planning/phases/01-app-shell-and-file-intake/01-05-SUMMARY.md
   ```

6. Re-run Phase 1 execution or verification so the verifier can move past the original user-story guard:

   ```bash
   $gsd-execute-phase 1 --gaps-only
   ```

   If `01-05-SUMMARY.md` already exists, GSD should skip the completed gap plan and continue to phase-level verification.

## Pass Criteria

Phase `01-05` is verified when:

- `01-05-SUMMARY.md` exists.
- The user-story validator returns `true`.
- The Phase 1 overview goal and detailed `**Goal:**` line match the expected story exactly.
- `01-VERIFICATION.md` no longer reports the MVP user-story format gap.

## Notes

- This gap does not require Swift source changes.
- This does not replace the later Xcode build/test check for the Phase 1 app code. Run that on a macOS machine with Xcode tools installed when available.
