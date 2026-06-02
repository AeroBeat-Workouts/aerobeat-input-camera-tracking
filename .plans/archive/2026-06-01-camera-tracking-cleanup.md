# AeroBeat Camera Tracking Cleanup

**Date:** 2026-06-01
**Status:** Stale
**Last Updated:** 2026-06-02 07:29 EDT
**Blocked Reason:** Superseded as an active execution plan and intentionally left top-level as earlier cleanup framing, not the authoritative continuation target. The completed continuation is recorded in archived plans `/.plans/archive/2026-06-01-cross-repo-demediapipe-coordination.md` and `/.plans/archive/2026-06-02-input-camera-tracking-repo-root-demediapipe-audit.md`.
**Agent:** `main`

---

## Goal

Clean up the remaining naming and compatibility debt in `aerobeat-input-camera-tracking` now that the layering alignment work is complete.

---

## Overview

The final audit passed, but Derrick has now set a stricter target: `aerobeat-input-camera-tracking` should have no compatibility surface or knowledge of MediaPipe at all. That includes sharable `src/`, repo docs, provider IDs/session keys, config names/shims, plugin metadata, and proving/testbed naming where this repo itself is expressing the concept. The input repo should only know that it communicates with `aerobeat-tool-camera-tracking`.

The key constraint is that this is still cleanup work, not a return to runtime-boundary migration. The sharable `src/` path is already aligned structurally. So this plan focuses on removing the remaining MediaPipe-branded naming/config surfaces and replacing them with tool-contract-neutral equivalents without regressing the contract-only runtime path.

Important rule for this cleanup: `.testbed/addons.jsonc` should continue mounting `aerobeat-vendor-mediapipe-python`, because the hidden proving/workbench environment still needs to satisfy `aerobeat-tool-camera-tracking`'s backend/runtime dependency for local proving/tests. That mount is allowed in `.testbed/` and should not be treated as input-repo `src/` MediaPipe knowledge.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Input repo cleanup target | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` |
| `REF-02` | Final passing audit | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-final-audit-report.md` |
| `REF-03` | Boundary memo describing intended ownership split | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-boundary-memo.md` |
| `REF-04` | Completed alignment plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-06-01-input-camera-tracking-alignment.md` |

---

## Tasks

### Task 1: Define the cleanup scope and neutral replacement rules

**Bead ID:** `aerobeat-input-camera-tracking-ykt`
**SubAgent:** `primary` (for `research` workflow role)
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Review the final audit findings and identify every remaining MediaPipe-branded or MediaPipe-knowledge-bearing surface in `aerobeat-input-camera-tracking`, including provider IDs/session keys, config resources, README/plugin wording, and `.testbed/` names/messages/scripts. The goal is not compatibility preservation; the goal is that this repo should not know or say MediaPipe at all, only that it communicates with `aerobeat-tool-camera-tracking`. Important exception: do not treat `.testbed/addons.jsonc` mounting `aerobeat-vendor-mediapipe-python` as cleanup debt, because the hidden proving/workbench still needs that vendor mount to satisfy the sibling tool repo's backend/runtime dependency for local proving/tests. Produce a cleanup memo with neutral replacements, rename order, and any cross-repo compatibility risks that must be handled explicitly. Claim the bead on start and do not modify application code.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-06-01-camera-tracking-cleanup.md`
- `.plans/2026-06-01-camera-tracking-cleanup-memo.md`

**Status:** ✅ Complete

**Results:** Research completed the de-MediaPipe cleanup memo at `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-06-01-camera-tracking-cleanup-memo.md` and closed bead `aerobeat-input-camera-tracking-ykt`. The memo identifies remaining MediaPipe-branded surfaces in sharable `src`, docs, and `.testbed/`, explicitly excludes `.testbed/addons.jsonc` vendor mounting as allowed proving-only dependency wiring, and recommends splitting cleanup into two slices: repo-local naming cleanup first, then coordinated cleanup of provider/session/backend identifiers and proving-harness runtime seams.

---

### Task 2: Remove MediaPipe-branded naming/config from sharable src

**Bead ID:** `aerobeat-input-camera-tracking-7nr`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Implement the approved cleanup in the sharable `src/` path of `aerobeat-input-camera-tracking` so the repo no longer contains MediaPipe-branded or MediaPipe-knowledge-bearing config surfaces, IDs, session keys, class names, or comments. Replace them with tool-contract-neutral equivalents. Claim the bead on start, run validation, commit, and push before handoff.

**Folders Created/Deleted/Modified:**
- `src/`

**Files Created/Deleted/Modified:**
- likely `src/config/mediapipe_config.gd`
- likely `src/config/camera_tracking_config.gd`
- likely `src/input_provider.gd`
- likely `src/providers/camera_tracking_provider.gd`
- other affected sharable files discovered during implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Remove MediaPipe-branded docs and proving/testbed naming

**Bead ID:** `Pending`
**SubAgent:** `primary` (for `coder` workflow role)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Update README, plugin metadata, and `.testbed/` proving-only names/messages/scripts so this repo no longer says or encodes MediaPipe knowledge. The repo should present itself only as a consumer of `aerobeat-tool-camera-tracking`. Claim the bead on start, run validation, commit, and push before handoff.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- repo root

**Files Created/Deleted/Modified:**
- `README.md`
- `plugin.cfg`
- `.testbed/...` files as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: QA the cleanup slice

**Bead ID:** `Pending`
**SubAgent:** `primary` (for `qa` workflow role)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Verify that the cleanup slice improves naming/config clarity without breaking required compatibility or the contract-only runtime path. Run focused tests, inspect any renamed compatibility seams, and document verdict plus evidence. Claim the bead on start and do not modify application code.

**Folders Created/Deleted/Modified:**
- validation artifacts as needed

**Files Created/Deleted/Modified:**
- validation notes as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Independently audit post-cleanup truthfulness

**Bead ID:** `Pending`
**SubAgent:** `primary` (for `auditor` workflow role)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Independently verify that the cleanup removed the intended naming/config debt, preserved any required compatibility seams, and did not reintroduce layering violations. Produce a brief audit with exact evidence. Claim the bead on start and close the bead only when the review is complete.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- final cleanup audit path to be assigned

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Created the cleanup plan; execution has not started yet.

**Reference Check:** Pending execution.

**Commits:**
- None yet.

**Lessons Learned:** Cleanup work should be explicit about compatibility seams so we don’t confuse naming debt with architecture debt.

---

*Completed on Pending*
