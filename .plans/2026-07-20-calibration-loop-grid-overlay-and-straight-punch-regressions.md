# AeroBeat Input Camera Tracking - Calibration Loop, Grid Overlay, and Straight-Punch Regressions

**Date:** 2026-07-20  
**Status:** In Progress  
**Last Updated:** 2026-07-20 20:24 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Audit and fix the newly reported replay/calibration regressions so Flow/Boxing proving behavior matches the current architecture direction again.

---

## Overview

The latest AeroBeat handoff explicitly called out a follow-up regression seam in `aerobeat-input-camera-tracking` that had not yet been worked: calibration loops `10s -> 5s -> 10s -> 5s` indefinitely, the Flow/Boxing overlay grid appears undersized/centered and then disappears after calibration starts, and straight punches in replay are no longer firing their pose threshold. That work was not actually completed after the handoff; the most recent repo activity only archived completed calibration/grid plans and cleaned a separate `FlowGridOverlay` warning seam.

This plan keeps the regression lane honest and narrow. We start by auditing the exact code/config/runtime truth behind the three reported symptoms, then materialize the smallest truthful repair path, then run QA and audit before claiming the seam is fixed.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Latest canonical AeroBeat handoff naming this regression seam | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-07-20T19-48-00-04-00-aerobeat.md` |
| `REF-02` | Recently completed shared calibration plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-20-shared-calibration-countdown-and-capture.md` |
| `REF-03` | Recently completed Flow overlay / Boxing grid-avoidance plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md` |
| `REF-04` | Cleanup plan proving the later warning-only work did not address the new regressions | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-grid-overlay-warning-and-plan-cleanup.md` |

---

## Tasks

### Task 1: Audit calibration loop, overlay-grid, and straight-punch regressions

**Bead ID:** `aerobeat-input-camera-tracking-2ne7`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, audit bead `aerobeat-input-camera-tracking-2ne7`. Claim it on start with `bd update aerobeat-input-camera-tracking-2ne7 --status in_progress --json`. Investigate the three reported regressions from the latest AeroBeat handoff: (1) calibration loops `10s -> 5s -> 10s -> 5s` and never completes, (2) Flow/Boxing overlay grid appears too small/centered and then disappears after calibration trigger, and (3) straight punches in replay are not firing their pose threshold. Determine whether these share a root cause or are separate seams, identify the narrowest truthful next fix slice, and update this plan with exact findings, touched files, and recommended coder scope. Do not implement fixes yet unless the audit proves a tiny contained code correction is inseparable from reproducing the bug.  

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- repo runtime/testbed surfaces only as needed for investigation

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-calibration-loop-grid-overlay-and-straight-punch-regressions.md`
- investigation notes/probes only if needed

**Status:** ✅ Complete  

**Results:**
- **Root-cause split:** the three symptoms do **not** collapse into one code bug. Symptoms **(1) calibration never completes** and **(2) overlay grid starts undersized/centered then disappears on calibration trigger** share the same proving-scene replay/calibration seam. Symptom **(3) straight punches in replay not firing their pose threshold** is a separate boxing threshold/timing seam.
- **Why calibration + overlay are coupled:**
  - Both proving scenes default to action replays, not calibration footage:
    - `/.testbed/scenes/boxing_proving.tscn` -> `boxing_guard->straight_right_repeat_04_take_01.mp4`
    - `/.testbed/scenes/flow_proving.tscn` -> `flow_swing_lr12->lr6_repeat_04_take_01.mp4`
  - Shared calibration now requires a centered T-pose before capture can begin (`src/detectors/pose_detector_substrate.gd`: `CALIBRATION_CENTER_TOLERANCE`, `CALIBRATION_T_POSE_*`, `_evaluate_calibration_readiness()`). Those default replay clips are normal action clips, so the runtime can truthfully stay in `capture_pending` and then fail/never meaningfully complete for a tester expecting a one-button recalibration flow.
  - Pressing calibration immediately clears the existing baseline via `request_athlete_recalibration()` in `src/detectors/pose_detector_substrate.gd`, and the proving harness clears the overlay whenever `grid.is_calibrated == false` (`/.testbed/scripts/proving_harness.gd:_refresh_flow_grid_overlay()`, `/.testbed/scripts/flow_grid_overlay.gd:update_grid_debug()/clear_grid_debug()`). That explains the **disappears after trigger** half directly.
  - The **undersized/centered before trigger** half is consistent with the still-enabled shared auto-bootstrap path in `_update_baseline()`: outside an explicit calibration session it commits after 5 valid frames using whatever pose the action replay currently has, with `capture_source = "auto_bootstrap"`. For boxing/flow action clips, that means the initial baseline/grid can be built from guard/swing frames rather than a centered T-pose, producing a visibly too-small centered grid while still passing current code truth.
- **Why straight-punch replay is separate:**
  - Boxing profile state publication is capped at **10 fps** in `assets/boxing.camera_tracking.yaml` (`tracking.state_update_max_fps: 10`), so debug/inspector truth is sampled about every **100 ms**.
  - Boxing straight-punch threshold timing is currently tuned to **10 ms grace** + **10 ms pose-only rearm** in `assets/boxing.gesture_detection.yaml`.
  - That combination is far shorter than the published replay/debug cadence, so replay inspector state can miss the `triggered` window entirely even if underlying motion briefly qualifies. Current config-shape coverage even locks these values in (`/.testbed/tests/unit/test_camera_tracking_config_profiles.gd` asserts `pose_only_rearm_ms == 10`), but there is no repo-local test proving that the default boxing replay fixture still surfaces a visible straight-punch trigger at profile timing.
  - This seam is therefore **not** the same as calibration/grid disappearance. It is a boxing threshold/timing/profile-validation seam.
- **Narrowest truthful next fix slice:**
  1. **First fix slice (recommended): make replay calibration truthful in the proving scenes** rather than pretending the default action fixtures are calibratable. Narrow options, in likely-preferred order:
     - disable or relabel the shared Start Calibration affordance when the active source is an action replay with no calibratable segment;
     - or swap default proving replay assets to clips that actually include centered T-pose calibration setup;
     - only if UX requires it, preserve the previous committed grid overlay until replacement calibration succeeds instead of clearing immediately on request.
  2. **Second fix slice:** widen boxing straight-punch timing to match replay/state publication cadence, or raise boxing replay/debug publication cadence so `triggered` truth cannot vanish between 100 ms state updates.
- **Most likely file/config touch points for coder:**
  - Replay-calibration seam:
    - `/.testbed/scenes/boxing_proving.tscn`
    - `/.testbed/scenes/flow_proving.tscn`
    - `/.testbed/scripts/proving_harness.gd`
    - `src/detectors/pose_detector_substrate.gd`
    - optionally new replay calibration fixtures under `/.testbed/assets/fixtures/...` if the chosen fix is asset-based.
  - Straight-punch replay seam:
    - `assets/boxing.gesture_detection.yaml`
    - `assets/boxing.camera_tracking.yaml`
    - `/.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
    - `/.testbed/tests/unit/test_pose_detector_substrate.gd`
    - potentially `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` for inspector-facing truth.
- **Validation/evidence captured during audit:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=calibration_session -gexit` ✅ passed (2/2). Confirms current runtime contract intentionally allows `capture_pending` then failure when readiness never becomes true.
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration -gexit` ✅ passed (2/2). Confirms current proving-scene tests only check shared calibration UI/state wiring, not whether the default replay clips are actually calibratable.
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gunit_test_name=boxing -gexit` ✅ passed (1/1, 64 asserts). Confirms repo truth still explicitly loads boxing straight-punch `pose_only_rearm_ms: 10` under the boxing profile.
- **Coder handoff recommendation:** do **not** try to solve all three complaints in one commit. Land the replay-calibration/truthfulness slice first because it explains the calibration loop + overlay disappearance together and is mostly a UX/runtime contract issue. Then take straight-punch replay as a separate boxing timing pass with a dedicated replay-facing regression test.

---

### Task 2: Fix replay calibration truth seam

**Bead ID:** `aerobeat-input-camera-tracking-eh63`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, implement the first recommended fix slice against bead `aerobeat-input-camera-tracking-eh63`. Claim it on start with `bd update aerobeat-input-camera-tracking-eh63 --status in_progress --json`. Fix the replay-calibration truth seam that explains both the calibration loop / non-completion complaint and the undersized/disappearing overlay-grid complaint. Keep the slice narrow and truthful: either disable/relabel calibration for action-replay sources that are not actually calibratable, or switch the proving scenes to assets/flows that are truly calibratable, and only preserve the previous grid during recalibration if that is necessary to keep the UX truthful. Do not broaden into the separate straight-punch timing seam yet. Update this plan with exact files changed and what route you chose, run the strongest repo-local validation, commit, and push to `main` before handoff unless blocked. Do not close the bead; leave it ready for QA with exact evidence and any remaining replay/UX caveats.  

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- fixture/config/runtime surfaces only as needed for the truthful fix route

**Files Created/Deleted/Modified:**
- `/.testbed/scripts/proving_harness.gd`
- `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-calibration-loop-grid-overlay-and-straight-punch-regressions.md`

**Status:** ✅ Complete  

**Results:**
- **Chosen route:** kept the slice narrow and truthful by fixing the proving-harness contract instead of broadening runtime calibration logic or changing boxing timing. Default prerecorded proving replays now surface shared calibration as unavailable, with explicit copy explaining that the action replay does not provide a truthful centered T-pose capture segment and that testers should use a live camera or a replay fixture with explicit calibration setup.
- **Replay-grid truth fix:** when the active source is a prerecorded replay and the current baseline came from replay `auto_bootstrap`, the proving harness now hides the shared grid overlay/truth panel instead of rendering that replay-derived baseline as if it were a real shared calibration capture. This directly addresses the undersized/centered pre-calibration grid complaint without lying about grid truth.
- **Exact code changes:**
  - `/.testbed/scripts/proving_harness.gd`
    - added `_shared_calibration_supported_for_active_source()` and `_active_source_uses_replay_bootstrap_baseline()` helpers.
    - gated `provider_has_start_calibration()`, `provider_has_cancel_calibration()`, and `_start_athlete_calibration_request()` so prerecorded proving replays cannot start the shared calibration flow.
    - rewrote the calibration button/countdown/instruction/status copy for prerecorded replays so the UI explains why calibration is unavailable.
    - suppressed `flow_grid_overlay` and replaced the grid-truth panel body when the active replay is only carrying an `auto_bootstrap` baseline.
  - `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
    - preserved live-source shared-calibration coverage via a dedicated `LiveCalibrationHarness` test helper.
    - added proving-scene regression coverage that default prerecorded replays disable shared calibration truthfully and do not route calibration requests.
    - added regression coverage that replay `auto_bootstrap` baselines hide the grid overlay/truth surfaces, while normal shared grid truth rendering still works.
- **Validation/evidence:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration -gexit` ✅ passed (3/3).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid_truth -gexit` ✅ passed (2/2).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=calibration_session -gexit` ✅ passed (2/2).
  - Broader context check: the full `test_boxing_proving_harness_profiles_and_debug.gd` file still reports unrelated pre-existing depth-debug failures outside this slice; this change did not widen into that seam.
- **Remaining replay/UX caveat for QA:** shared calibration is now intentionally unavailable on the default prerecorded proving clips. QA should verify that this is the truthful desired product behavior for those fixtures, and treat any future desire for replay-side calibration as a separate asset/capability seam rather than a bug in this slice.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Completed the audit plus the first implementation slice. Default prerecorded proving replays now truthfully disable shared calibration, and replay `auto_bootstrap` baselines no longer masquerade as valid shared grid truth. The separate straight-punch replay timing seam remains intentionally untouched for the next pass.

**Reference Check:** `REF-01` correctly named the regression lane. `REF-02` explains why calibration now requires a centered T-pose and why baseline reset clears gameplay truth. `REF-03` explains why the shared overlay consumes the single runtime baseline/grid payload. `REF-04` confirms the later cleanup work did not address either seam.

**Commits:**
- `d6bb10d` - Truthfully disable replay calibration in proving harness

**Lessons Learned:** Current repo tests validate the shared calibration contract and boxing profile shape, but they do not prove that the default proving replay fixtures are calibratable or that boxing straight-punch `triggered` state survives the profile's published replay/debug cadence. For replay-first proving flows, the UI must explicitly distinguish live/shared-calibration truth from replay auto-bootstrap convenience state.

---

*Completed on 2026-07-20*
