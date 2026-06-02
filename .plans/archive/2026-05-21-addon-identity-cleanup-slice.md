# AeroBeat Input Camera Tracking — Addon Identity Cleanup Slice

**Date:** 2026-05-21  
**Status:** Stale  
**Agent:** Cookie 🍪

---

## Goal

Clean up the active addon/preload/config identity debt that still names this repo as `aerobeat-input-mediapipe-python`, while keeping the migration truthful and avoiding premature contract breakage.

---

## Overview

The first migration seam (`ce8a720`) intentionally preserved some naming debt so we could land a safe `CameraTracking` bridge without inventing final packaging truth too early. QA and audit both confirmed that the remaining debt is real but non-blocking for that first slice: active preload paths, `.testbed` addon manifest identity, and some config/session-facing strings still point at `aerobeat-input-mediapipe-python` / `mediapipe_python`.

This cleanup slice should stay narrower than a full contract migration. The target is active repo-owned identity surfaces that are safe to rename now: addon key/mount identity within this repo’s `.testbed`, preloads that still point at `res://addons/aerobeat-input-mediapipe-python/...`, plugin/package wording, and any repo-local config constants that should reflect `camera_tracking` ownership truth. It should not blindly rename historical plan files, archive references, or every internal provider/runtime identifier if those are still part of intentional compatibility. In particular, if `provider_id = mediapipe_python` or specific shared-session keys are still required for consumer compatibility today, that needs to be called out explicitly rather than “fixed” by guesswork.

The governing principle: rename what is now clearly owned by `aerobeat-input-camera-tracking`, preserve intentional compatibility seams, and document any remaining not-yet-safe identity debt.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current first migration plan and its stated deferred identity debt | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-05-21-input-camera-tracking-contract-migration.md` |
| `REF-02` | Current repo entrypoint / compatibility adapter truth | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/input_provider.gd` |
| `REF-03` | Current proving harness preload surface | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-04` | Current `.testbed` addon manifest identity | `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/addons.jsonc` |
| `REF-05` | Stable upstream camera-tracking contract shell commit | `25f52da` in `/workspace/projects/aerobeat/aerobeat-tool-camera-tracking` |
| `REF-06` | Current QA/audit truth for the first migration seam | `ce8a720` plus beads `aerobeat-input-camera-tracking-3gz` and `aerobeat-input-camera-tracking-d41` |

---

## Tasks

### Task 1: Implement the active addon/preload/config identity cleanup slice

**Bead ID:** `aerobeat-input-camera-tracking-e31`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the bead on start and implement a safe identity-cleanup slice for active repo-owned addon/preload/config surfaces. Rename active `.testbed` addon identity, preload paths, and plugin/package/config wording away from `aerobeat-input-mediapipe-python` where that wording is now clearly stale. Do not mass-rewrite archived/historical plans. Do not rename compatibility identifiers that are still required for current consumer/runtime truth unless you can prove the safe replacement and validate it. Preserve Boxing + Flow proving behavior, use `.testbed` as the proving project, never edit `/addons/` mirrors, run relevant validation, and document any intentionally deferred compatibility names left behind.

**Folders Created/Deleted/Modified:**
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- active source/testbed/config files that still use stale addon/preload identity

**Status:** ✅ Complete

**Results:** Implemented the active identity-cleanup slice and pushed commit `5504058` (`Rename active addon identity to camera tracking`). Renamed the active `.testbed` self-mount key from `aerobeat-input-mediapipe-python` to `aerobeat-input-camera-tracking`, updated active repo-owned preload/load paths across `.testbed` scenes, harness/test scripts, active unit tests, `src/providers/camera_tracking_provider.gd` self-loads, and updated the repo-local runtime-prep warning in `python_mediapipe/prepare_runtime.py` to point at the new addon mount. Also cleaned the non-compat owner prefix in `src/input_provider.gd` to `aerobeat-input-camera-tracking:input_provider`. Validation: `cd .testbed && godotenv addons install`, then clean validation in a fresh temp copy of `.testbed` with fresh addon install: `godot --headless --path . --check-only --script scripts/proving_harness.gd`, `godot --headless --path . --check-only --script scripts/test_scene.gd`, Gut `test_camera_tracking_provider.gd` (`3/3` passed), and Gut `test_pose_detector_substrate.gd` (`12/12` passed). Important validation caveat preserved honestly: the live `.testbed` currently has a stale installed mirror at `.testbed/addons/aerobeat-input-mediapipe-python`, which causes duplicate global-class parse errors if both old and new mounts are present; this was not edited directly because `/addons/` mirrors are off-limits. Intentionally deferred compatibility names left behind: `mediapipe_python` identifiers that still express backend/runtime truth (`PROVIDER_ID`, `SHARED_SESSION_KEY`, provider/backend metadata/config strings).

---

### Task 2: QA the active addon/preload/config identity cleanup slice

**Bead ID:** `aerobeat-input-camera-tracking-s5t`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the bead after coder completion and independently verify the identity-cleanup slice. Confirm active `.testbed` addon identity and preload paths are updated truthfully, proving/tests still load, no `/addons/` mirrors were edited, and any remaining compatibility names are explicitly justified instead of accidental leftovers. Re-run meaningful repo-local validation and record exact evidence.

**Folders Created/Deleted/Modified:**
- verification only

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 3: Audit the active addon/preload/config identity cleanup slice

**Bead ID:** `aerobeat-input-camera-tracking-cag`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim the bead after QA completion and independently truth-check the identity-cleanup slice. Confirm the work cleaned up real active naming debt, did not silently break compatibility, and left any remaining intentional `mediapipe_python` names documented honestly.

**Folders Created/Deleted/Modified:**
- verification only

**Files Created/Deleted/Modified:**
- audit notes only if needed

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial / repair largely proven, final audit writeback still uncertain

**What We Built:** Landed the active source/testbed identity rename in commit `5504058`, then followed it with repair commit `ad15683` after QA correctly found stale generated-addon and `.godot` cache collisions in the live proving path. The repair adds `scripts/refresh_testbed_workbench.py` plus repo docs/CI/runtime guidance so the supported validation path now refreshes generated addon mounts and cache state truthfully instead of relying on hand-edited mirrors.

**Reference Check:** The slice stayed scoped to active repo-owned identity surfaces and preserved intentional compatibility IDs like `PROVIDER_ID`, `SHARED_SESSION_KEY`, and backend metadata `mediapipe_python` strings where those still describe runtime truth.

**Commits:**
- `5504058` - Rename active addon identity to camera tracking
- `ad15683` - Refresh testbed workbench after addon rename

**Lessons Learned:** The risky part is not renaming strings — it is distinguishing stale identity surfaces from still-required compatibility IDs, and then proving the generated workbench/cache state can be refreshed reproducibly. The last subagent outputs indicate QA passed the repaired path and the first audit block was a bead-state race, but the final audit closure still needs a clean explicit pass/closed confirmation next session.

---

*Last updated on 2026-05-21*