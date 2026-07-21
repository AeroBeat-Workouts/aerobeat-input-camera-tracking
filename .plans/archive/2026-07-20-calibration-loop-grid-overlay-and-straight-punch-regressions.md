# AeroBeat Input Camera Tracking - Calibration Loop, Grid Overlay, and Straight-Punch Regressions

**Date:** 2026-07-20
**Status:** Complete
**Last Updated:** 2026-07-20 21:34 EDT
**Blocked Reason:** None
**Agent:** `pico`

---

## Goal

Audit and fix the newly reported replay/calibration regressions so Flow/Boxing proving behavior matches the current architecture direction again.

---

## Overview

The latest AeroBeat handoff explicitly called out a follow-up regression seam in `aerobeat-input-camera-tracking` that had not yet been worked: calibration loops `10s -> 5s -> 10s -> 5s` indefinitely, the Flow/Boxing overlay grid appears undersized/centered and then disappears after calibration starts, and straight punches in replay are no longer firing their pose threshold. That work was not actually completed after the handoff; the most recent repo activity only archived completed calibration/grid plans and cleaned a separate `FlowGridOverlay` warning seam.

This plan keeps the regression lane honest and narrow. We start by auditing the exact code/config/runtime truth behind the three reported symptoms, then materialize the smallest truthful repair path, then run QA and audit before claiming the seam is fixed.

**2026-07-20 product clarification from Derrick:** for the `/.testbed/` project, replay calibration is a required testing capability. We should not treat prerecorded replay as categorically ineligible for calibration. The earlier proving-harness slice that disabled calibration on default replay fixtures was a truthful short-term stopgap for the misleading current behavior, but it is **not** the desired final product behavior for this testbed. The next seam is to allow calibration on arbitrary replay videos while staying honest about whether the footage actually yields a usable baseline.

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
- **Post-implementation truth update (superseded by Derrick clarification):** shared calibration is now intentionally unavailable on the default prerecorded proving clips. That stopgap was useful for preventing misleading testbed behavior, but Derrick has now clarified that the `/.testbed/` harness must support calibration on arbitrary replay videos for testing. Treat this completed slice as an interim truth-maintenance fix, not the final desired behavior.

---

### Task 3: QA replay calibration truth seam

**Bead ID:** `aerobeat-input-camera-tracking-fsal`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, QA the replay calibration truth seam against bead `aerobeat-input-camera-tracking-fsal`. Claim it on start with `bd update aerobeat-input-camera-tracking-fsal --status in_progress --json`. Verify that default prerecorded proving replays now truthfully disable shared calibration, that calibration requests are not routed on those replay fixtures, that replay-derived `auto_bootstrap` baselines no longer render misleading shared grid overlay/truth output, and that live-source shared-calibration coverage still behaves correctly. Re-run the strongest relevant repo-local validation and inspect the proving-harness behavior at the highest-fidelity repo-local level available. Do not self-implement missing work; report exact evidence, any gaps, and whether this slice is ready for audit. Do not close the bead. Update this plan with the QA results before finishing.

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-calibration-loop-grid-overlay-and-straight-punch-regressions.md`

**Status:** ✅ Complete

**Results:**
- **QA verdict:** the replay-calibration truth slice behaves correctly in repo-local proving-harness coverage and is **ready for audit** as scoped. I did **not** touch the separate straight-punch replay-timing seam.
- **Strongest relevant repo-local validation re-run:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration -gexit` ✅ passed (**3/3 tests, 58 asserts, 8.319s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid_truth -gexit` ✅ passed (**2/2 tests, 40 asserts, 13.847s**).
- **What those QA passes proved at the highest-fidelity repo-local level available:**
  - **Default prerecorded proving replays truthfully disable shared calibration** in both Boxing and Flow proving scenes. The disabled primary button label is `Replay Calibration Unavailable`, the secondary cancel button stays hidden, and the explanatory copy says calibration is disabled for prerecorded proving replay / this prerecorded replay / default action clip.
  - **Calibration requests are not routed on replay fixtures.** The replay-scene regression test emits the disabled button press and confirms `FakeAthleteRecalibrateProvider.request_count == 0`, so the proving harness no longer forwards recalibration starts for the default replay fixtures.
  - **Replay-derived `auto_bootstrap` baselines no longer render misleading shared grid truth.** With `capture_source = "auto_bootstrap"`, the shared Flow grid overlay is hidden and the grid-truth panel body switches to explanatory hidden-for-replay / auto-bootstrap copy instead of rendering a false shared-calibration overlay.
  - **Live-source shared calibration still behaves correctly.** The live-harness coverage still exercises start/cancel plus success/failure truth: start button routes one request, active countdown/capture copy appears, cancellation routes once and switches to retry copy, failure surfaces centered-camera guidance, and success restores `Recalibrate Athlete` plus `Captured baseline: 5/5 frames` / `Calibration complete` truth.
- **Source-level QA spot check:** `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` now contains dedicated live (`LiveCalibrationHarness`) versus prerecorded replay coverage, and `/.testbed/scripts/proving_harness.gd` contains the corresponding gating/helpers (`_shared_calibration_supported_for_active_source()`, replay `auto_bootstrap` overlay suppression) that explain the passing behavior.
- **Gap / caveat:** I did not perform a manual physical-camera or interactive GUI proving run. The highest-fidelity repo-local evidence available in this lane was the headless proving-scene GUT coverage that instantiates the real Boxing/Flow proving scenes and exercises the harness UI/state wiring in-process.
- **Background noise explicitly out of scope:** a broader run of the full `test_boxing_proving_harness_profiles_and_debug.gd` file still hit pre-existing unrelated depth-debug failures (`test_boxing_depth_debug_thumbnail_truthfully_reports_unavailable_depth_texture`, `test_boxing_depth_debug_overlay_consumes_runtime_region_metadata_without_config_reconstruction`, `test_boxing_depth_debug_swap_uses_real_runtime_texture_when_available`, `test_boxing_depth_debug_swap_resets_when_yaml_disables_thumbnail_click_swap`). I stopped that noisy pass after confirming those failures are outside this replay-calibration slice.

---

### Task 4: Fix straight-punch replay timing truth

**Bead ID:** `aerobeat-input-camera-tracking-59bh`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, implement the separate straight-punch replay timing fix against bead `aerobeat-input-camera-tracking-59bh`. Claim it on start with `bd update aerobeat-input-camera-tracking-59bh --status in_progress --json`. Fix the boxing replay/debug truth seam where straight-punch `triggered` state can vanish between published updates. Keep the slice narrow and truthful: adjust timing/profile/publication behavior so the default boxing replay path can surface straight-punch trigger truth reliably at the published replay/debug cadence, and add a dedicated replay-facing regression test. Do not widen back into the replay-calibration seam except for tightly related harness/test plumbing if truly necessary. Update this plan with exact files changed and the route you chose, run the strongest repo-local validation, commit, and push to `main` before handoff unless blocked. Do not close the bead. Leave it ready for QA with exact evidence, commit hash, and any remaining timing/profile caveats.

**Folders Created/Deleted/Modified:**
- `assets/`
- `/.testbed/tests/unit/`
- runtime/testbed surfaces only as needed

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `/.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `/.testbed/tests/unit/test_pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-calibration-loop-grid-overlay-and-straight-punch-regressions.md`

**Status:** ✅ Complete

**Results:**
- **Chosen route:** kept the boxing replay/debug publish cap at **10 fps** and fixed the truth seam in the boxing gesture profile itself. Straight-punch replay now restores a `triggered` grace window and pose-only rearm window that outlive the published replay/debug cadence instead of collapsing within ~10 ms.
- **Exact config change:** `assets/boxing.gesture_detection.yaml`
  - `straight_punch.threshold.timing.triggered_grace_ms`: **10 -> 240**
  - `straight_punch.threshold.rearm.pose_only_rearm_ms`: **10 -> 250**
  - I intentionally left `assets/boxing.camera_tracking.yaml` unchanged at `tracking.state_update_max_fps: 10`; the narrow truthful fix is to make boxing trigger truth survive the existing published cadence rather than broadening replay/state publication behavior.
- **Regression coverage added:**
  - `/.testbed/tests/unit/test_camera_tracking_config_profiles.gd` now locks the canonical boxing profile values at `triggered_grace_ms = 240` and `pose_only_rearm_ms = 250` so the shortened 10 ms overrides cannot silently come back.
  - `/.testbed/tests/unit/test_pose_detector_substrate.gd` now adds `test_boxing_profile_bundle_keeps_straight_punch_trigger_truth_visible_at_published_replay_cadence()`, a dedicated replay-facing cadence regression. It uses the boxing profile's real `state_update_max_fps = 10` publish cap, applies the boxing timing values, and proves that a straight-punch trigger is still visible **100 ms later** with `grace_ms_remaining = 140` instead of vanishing between published updates.
- **Strongest repo-local validation run:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gexit` ✅ passed.
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` ✅ passed (**74/74 tests, 843 asserts, 1.679s**).
  - Focused spot check before the full pass: `-gunit_test_name=straight_punch_trigger_truth_visible_at_published_replay_cadence` ✅ passed (**1/1 tests, 20 asserts**).
- **Remaining timing/profile caveat for QA:** the new cadence regression uses pose-only straight-punch plumbing for determinism while pulling the boxing profile's real publish cadence and timing values. QA should still verify the default boxing proving replay surfaces the improved trigger truth at product level, but the repo-local detector/config seam is now explicitly covered.

---

### Task 5: Enable calibration on arbitrary replay videos in testbed

**Bead ID:** `aerobeat-input-camera-tracking-j0to`
**SubAgent:** `primary` (for `coder`)
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, implement replay-calibration support for arbitrary replay videos in the `/.testbed/` harness against bead `aerobeat-input-camera-tracking-j0to`. Claim it on start with `bd update aerobeat-input-camera-tracking-j0to --status in_progress --json`. Derrick has clarified that replay calibration is a required testbed capability, so do not keep the current blanket replay-calibration disable path as the final product behavior. Re-enable calibration for replay sources in a truthful way: the harness should allow calibration attempts on replay video, use the visible pose data from the video feed just like live input, and stay honest when a random clip never yields a usable baseline. Remove only the unnecessary replay safeguards; do not reintroduce misleading auto-bootstrap grid truth as if it were a real calibration capture. Keep this slice narrow and focused on replay calibration support rather than reopening the separate straight-punch seam. Update this plan with exact files changed and the route chosen, run the strongest repo-local validation, commit, and push to `main` before handoff unless blocked. Do not close the bead; leave it ready for QA with exact evidence and any remaining replay-calibration caveats.

**Folders Created/Deleted/Modified:**
- `/.testbed/`
- runtime/testbed surfaces only as needed
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- likely `/.testbed/scripts/proving_harness.gd`
- likely `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- maybe proving-scene fixture/config surfaces if required
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-calibration-loop-grid-overlay-and-straight-punch-regressions.md`

**Status:** ✅ Complete  

**Results:**
- **Chosen route:** removed the proving-harness replay-only calibration block and restored replay calibration as a first-class `/.testbed/` capability, while keeping the existing auto-bootstrap grid-truth guardrail intact. The harness now lets replay sources attempt the same shared calibration flow as live input, but its copy stays explicit that calibration still depends on the visible replay frames actually containing a centered T-pose segment.
- **Exact harness changes:**
  - `/.testbed/scripts/proving_harness.gd`
    - removed the source gate from `_start_athlete_calibration_request()`, `provider_has_start_calibration()`, and `provider_has_cancel_calibration()` so replay sources can request/cancel shared calibration the same way live sources do.
    - replaced the replay-disable button/copy path in `_refresh_calibration_flow_ui()` with truthful replay-capable copy. Replay scenes now show `Start Calibration` instead of `Replay Calibration Unavailable`, keep the normal countdown/capture state machine, and explain that replay calibration uses the visible pose in the video feed and may honestly fail when a random action clip never presents a usable centered T-pose baseline.
    - preserved the existing `_active_source_uses_replay_bootstrap_baseline()` guard so replay `auto_bootstrap` baselines still do **not** reappear as fake shared calibration truth in the grid overlay/truth panel.
  - `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
    - replaced the prior prerecorded-replay disable regression with `test_proving_scenes_allow_shared_calibration_attempts_for_prerecorded_replays()`.
    - new coverage proves both Boxing and Flow proving scenes enable the replay calibration button, route one calibration request on press, surface replay-specific honesty copy, and report `capture_pending` truth as “waiting for a centered T-pose in the replay feed” rather than pretending calibration is categorically unavailable.
- **Strongest repo-local validation run:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration -gexit` ✅ passed (**3/3 tests, 72 asserts, 6.209s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid_truth -gexit` ✅ passed (**2/2 tests, 40 asserts, 9.831s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=calibration_session -gexit` ✅ passed (**2/2 tests, 20 asserts, 0.42s**).
- **Remaining replay-calibration caveat for QA:** this change intentionally does **not** fabricate success for arbitrary replay footage. A replay clip still needs to visibly satisfy the same centered T-pose readiness checks as live input before the substrate will capture a truthful `calibration_session` baseline. When a clip never shows that pose, the harness now treats failure as expected truth instead of disabling the feature up front.

---

### Task 6: QA replay calibration support for arbitrary replay videos

**Bead ID:** `aerobeat-input-camera-tracking-p9aw`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, QA replay calibration support for arbitrary replay videos against bead `aerobeat-input-camera-tracking-p9aw`. Claim it on start with `bd update aerobeat-input-camera-tracking-p9aw --status in_progress --json`. Verify that prerecorded replay sources in the `/.testbed/` harness now allow calibration attempts, route calibration requests, use truthful replay-specific countdown/capture/failure copy, and still do not mislabel replay `auto_bootstrap` baselines as real shared calibration captures. Re-run the strongest relevant repo-local validation and inspect the proving-harness behavior at the highest-fidelity repo-local level available. Do not self-implement missing work; report exact evidence, any gaps, and whether this slice is ready for audit. Do not close the bead. Update this plan with the QA results before finishing.

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ✅ Complete

**Results:**
- **QA verdict:** the replay-calibration support slice behaves correctly in repo-local proving-harness coverage and is **ready for audit** as scoped. I did **not** change or retest the separate straight-punch timing slice beyond keeping it out of scope.
- **Strongest relevant repo-local validation re-run:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration -gexit` ✅ passed (**3/3 tests, 72 asserts, 5.326s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid_truth -gexit` ✅ passed (**2/2 tests, 40 asserts, 10.596s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=calibration_session -gexit` ✅ passed (**2/2 tests, 20 asserts, 0.405s**).
- **What the proving-harness QA passes proved at the highest-fidelity repo-local level available:**
  - **Prerecorded replay proving scenes now allow calibration attempts.** The real Boxing and Flow proving scenes both present an enabled `Start Calibration` button instead of the earlier replay-only disable path, and pressing it increments `FakeAthleteRecalibrateProvider.request_count` to **1** in each scene.
  - **Calibration requests are routed for replay sources.** After the press, the harness enters the active session state with the start button disabled, the cancel button visible, and countdown text `Countdown: 5s`, proving the replay calibration request is actually forwarded into the shared calibration flow.
  - **Replay-specific honesty copy is present during idle/countdown/capture-pending states.** Source-level expectations in `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` and matching harness strings in `/.testbed/scripts/proving_harness.gd` confirm that replay scenes say calibration uses the visible pose in the video feed, that random clips may never yield a usable baseline, and that `capture_pending` truth becomes `Waiting for a centered T-pose in the replay feed` / `calibration will fail honestly` rather than implying universal success.
  - **Replay `auto_bootstrap` baselines still do not masquerade as real shared calibration captures.** With `capture_source = "auto_bootstrap"`, the shared Flow grid overlay remains hidden and the grid-truth panel body explicitly says the overlay is hidden for this prerecorded replay / auto-bootstrap baseline instead of rendering false shared-calibration truth.
- **Exact source spot-check evidence:**
  - `/.testbed/scripts/proving_harness.gd` now keeps replay calibration enabled by routing through `provider_has_start_calibration()` / `provider_has_cancel_calibration()` with no replay-source block, appends replay-specific instruction copy in `_build_calibration_instruction_lines()`, and uses truthful replay-specific `capture_pending` / idle status strings in `_calibration_status_text()`.
  - `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd:test_proving_scenes_allow_shared_calibration_attempts_for_prerecorded_replays()` covers enabled replay calibration requests plus replay-specific idle/countdown/capture-pending copy, and `test_proving_scenes_hide_replay_auto_bootstrap_grid_truth()` keeps the grid-truth guardrail locked.
- **Gap / caveat:** I did not perform a manual interactive GUI or physical-camera run. The highest-fidelity repo-local evidence available in this QA lane was the headless GUT proving-scene coverage that instantiates the real Boxing/Flow proving scenes and exercises the actual harness UI/state wiring in-process.
- **Commit under test:** `6bf087d` — `Re-enable replay calibration attempts in proving harness`.

---

### Task 8: Audit replay calibration support for arbitrary replay videos

**Bead ID:** `aerobeat-input-camera-tracking-siwb`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, audit replay calibration support for arbitrary replay videos against bead `aerobeat-input-camera-tracking-siwb`. Claim it on start with `bd update aerobeat-input-camera-tracking-siwb --status in_progress --json`. Independently verify that prerecorded replay sources in the `/.testbed/` harness now allow calibration attempts, route calibration requests, use truthful replay-specific countdown/capture/failure copy, and still do not mislabel replay `auto_bootstrap` baselines as real shared calibration captures. Re-run or spot-check the strongest relevant repo-local validation and inspect the proving-harness behavior at the highest-fidelity repo-local level available. If the work passes, close the bead with an explicit reason; if not, leave it open and report the exact gap. Update this plan with the audit results before finishing.

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-calibration-loop-grid-overlay-and-straight-punch-regressions.md`

**Status:** ✅ Complete

**Results:**
- **Audit verdict:** the replay-calibration support slice **passes audit** as scoped. Prerecorded replay sources in the `/.testbed/` harness now allow calibration attempts, route calibration requests, use truthful replay-specific calibration copy, and still keep replay `auto_bootstrap` baselines from masquerading as real shared calibration captures.
- **Independent validation re-run (strongest relevant repo-local checks):**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=shared_calibration -gexit` ✅ passed (**3/3 tests, 72 asserts, 5.296s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid_truth -gexit` ✅ passed (**2/2 tests, 40 asserts, 11.093s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=calibration_session -gexit` ✅ passed (**2/2 tests, 20 asserts, 0.422s**).
- **What I independently verified at the highest-fidelity repo-local level available:**
  - **Replay calibration attempts are allowed and routed.** In `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd:test_proving_scenes_allow_shared_calibration_attempts_for_prerecorded_replays()`, both real proving scenes instantiate with an enabled `Start Calibration` button, and pressing it increments `FakeAthleteRecalibrateProvider.request_count` to `1`, confirming the harness now forwards replay calibration requests instead of blocking them.
  - **Replay-specific countdown/capture/failure truth is present.** The same proving-scene test and `/.testbed/scripts/proving_harness.gd` now agree on honest replay copy: idle instructions say replay calibration uses the visible pose in the video feed and random clips may never yield a usable baseline; `capture_pending` status says `Waiting for a centered T-pose in the replay feed`; failure truth is intentionally framed as an honest result when the clip never presents a usable pose.
  - **Request-routing implementation matches the passing behavior.** `/.testbed/scripts/proving_harness.gd:_start_athlete_calibration_request()` now routes straight through provider/tracking-singleton `start_athlete_calibration()` / `request_athlete_recalibration()` without a replay-source gate, so the harness behavior is not just a test-double illusion.
  - **Replay `auto_bootstrap` baselines still stay hidden from shared grid truth.** `/.testbed/scripts/proving_harness.gd:_refresh_flow_grid_overlay()` clears/hides the overlay when `_active_source_uses_replay_bootstrap_baseline()` is true, and `_build_grid_truth_text()` explicitly says the shared grid truth is hidden because the current baseline came from replay auto-bootstrap rather than an explicit centered T-pose calibration capture. The proving-scene regression `test_proving_scenes_hide_replay_auto_bootstrap_grid_truth()` passed for both Boxing and Flow.
- **Commit audited:** `6bf087d` — `Re-enable replay calibration attempts in proving harness`.
- **Caveat kept honest:** I did not run a manual interactive GUI or physical-camera session in this audit lane. The highest-fidelity repo-local evidence available here was the real proving-scene GUT coverage plus source-level spot checks of the active harness implementation.

---

### Task 7: QA straight-punch replay timing truth

**Bead ID:** `aerobeat-input-camera-tracking-crkc`
**SubAgent:** `primary` (for `qa`)
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, QA the straight-punch replay timing truth slice against bead `aerobeat-input-camera-tracking-crkc`. Claim it on start with `bd update aerobeat-input-camera-tracking-crkc --status in_progress --json`. Verify that the default boxing replay/debug path now truthfully surfaces straight-punch `triggered` state at the product-facing proving/debug layer, that the widened grace/rearm timings match the repo-local config truth, and that the new replay-facing regression coverage really proves the intended cadence behavior without widening scope dishonestly. Re-run the strongest relevant repo-local validation and inspect the highest-fidelity proving/debug evidence available. Do not self-implement missing work; report exact evidence, any gaps, and whether this slice is ready for audit. Do not close the bead. Update this plan with the QA results before finishing.

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed

**Status:** ✅ Complete

**Results:**
- **QA verdict:** the straight-punch replay timing truth slice is **ready for audit** as scoped. The boxing profile truth, detector cadence regression, and product-facing proving/debug surfaces all line up with the intended narrow fix. I did **not** find evidence of dishonest scope widening back into replay publication or calibration behavior.
- **Repo-local config truth re-verified:**
  - `assets/boxing.camera_tracking.yaml` still caps `tracking.state_update_max_fps` at **10 fps**.
  - `assets/boxing.gesture_detection.yaml` now sets boxing straight-punch `threshold.timing.triggered_grace_ms` to **240** and `threshold.rearm.pose_only_rearm_ms` to **250**.
  - `/.testbed/tests/unit/test_camera_tracking_config_profiles.gd` passed and explicitly locks those boxing profile values (`state_update_max_fps = 10`, `triggered_grace_ms = 240`, `pose_only_rearm_ms = 250`).
- **Strongest relevant detector/config validation re-run:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gexit` ✅ passed (**4/4 tests, 91 asserts, 0.456s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=straight_punch_trigger_truth_visible_at_published_replay_cadence -gexit` ✅ passed (**1/1 tests, 20 asserts, 0.409s**).
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` ✅ passed (**74/74 tests, 843 asserts, 1.72s**).
- **What the new cadence regression truthfully proves:**
  - `test_boxing_profile_bundle_keeps_straight_punch_trigger_truth_visible_at_published_replay_cadence()` uses the real boxing profile bundle, preserves the boxing replay/debug publish cap at **10 fps**, disables hands only for deterministic pose-only replay sampling, and proves a triggered straight punch is still surfaced one published snapshot (**100 ms**) later.
  - Exact checked values in the passing test: left straight-punch state remains `triggered`, `grace_ms_remaining == 140`, `triggered_grace_ms == 240`, and `pose_only_rearm_ms == 250` at the published snapshot. That is the honest proof that the new timing survives the existing product publish cadence instead of requiring a wider state-update-rate change.
- **Highest-fidelity proving/debug evidence re-run:** the product-facing proving/debug layer is covered by targeted `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` passes that exercise the real Boxing proving harness UI/debug builders.
  - `test_boxing_proving_hand_debug_line_surfaces_bbox_state_metrics` ✅ passed (**1/1, 14 asserts**) and verifies the compact hand-debug line includes `state=triggered`, `wrist_xyz_vel=0.420`, `bbox_growth=0.015`, and `grace=160ms`.
  - `test_boxing_punch_hover_card_uses_bbox_state_machine_debug_fields` ✅ passed (**1/1, 10 asserts**) and verifies hover-card rows surface the straight-punch state machine fields rather than a fake simplified view.
  - `test_boxing_punch_inspector_body_calls_out_live_bbox_inputs` ✅ passed (**1/1, 13 asserts**) and verifies the shared inspector body says `Current state - triggered`, `Recent punch velocity peak >= 0.180 - 0.310`, `Recent bbox area growth peak >= 0.010 - 0.012`, `Grace timer - 160/240ms remaining (active)`, and `Stored trigger bbox area - 0.071`.
  - `test_boxing_pose_only_punch_hover_card_and_inspector_report_skipped_hand_inputs_truthfully` ✅ passed (**1/1, 12 asserts**) and verifies the pose-only replay/debug path explicitly says `pose-only fallback` / `bbox skipped` instead of pretending hand-box metrics exist.
  - `test_boxing_pose_only_punch_event_still_activates_left_tile_badge` ✅ passed (**1/1, 2 asserts**) against the default replay fixture scene (`boxing_guard->straight_right_repeat_04_take_01.mp4`) and confirms a pose-only straight-punch trigger still lights the left punch tile badge at the proving layer.
  - `test_boxing_punch_inspector_freezes_paused_values_for_gesture_popups` ✅ passed (**1/1, 6 asserts**) and verifies paused inspector popups keep the `ready -> triggered` truth snapshot instead of being overwritten by later state drift.
  - `test_boxing_punch_hover_card_merges_latest_state_change_signal_snapshot` ✅ passed (**1/1, 3 asserts**) and verifies the hover card merges the latest state-change payload into a visible row: `state=triggered wrist=0.280 xy=0.082<=0.090 (true) bbox=0.064 growth=0.011 fresh=true source=fresh_inference grace=240ms valid=true`.
- **Scope-honesty check:** the new regression coverage stays narrow. The cadence proof uses the real boxing profile values and published replay cadence, but simplifies the trigger path to pose-only for determinism; that is acceptable because the product-facing proving layer separately covers both pose-only replay truth and bbox/hand-driven inspector surfaces. I did **not** see evidence that the test cheats by changing `state_update_max_fps` or by broadening into unrelated subsystems.
- **Relevant gap / background noise:** a broader `-gunit_test_name=punch` proving-harness sweep hit one unrelated pre-existing failure, `test_punch_family_inspectors_keep_only_compact_depth_backend_and_thresholds`, around compact depth-threshold copy (`Depth backend - missing` vs expected configured strings). That failure is outside this straight-punch replay timing slice; the straight-punch-specific proving/debug tests listed above all passed.
- **Manual/runtime caveat:** I did not run an interactive GUI replay session with live visuals. The highest-fidelity repo-local evidence available in this lane was the real proving-harness GUT coverage plus the full detector/config suite.

---

### Task 9: Audit straight-punch replay timing truth

**Bead ID:** `aerobeat-input-camera-tracking-4hbx`
**SubAgent:** `primary` (for `auditor`)
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, audit the straight-punch replay timing truth slice against bead `aerobeat-input-camera-tracking-4hbx`. Claim it on start with `bd update aerobeat-input-camera-tracking-4hbx --status in_progress --json`. Independently verify that the default boxing replay/debug path now truthfully surfaces straight-punch `triggered` state at the product-facing proving/debug layer, that the widened grace/rearm timings match the repo-local config truth, and that the replay-facing regression coverage proves the intended cadence behavior without dishonest scope widening. Re-run or spot-check the strongest relevant repo-local validation and inspect the highest-fidelity proving/debug evidence available. If the work passes, close the bead with an explicit reason; if not, leave it open and report the exact gap. Update this plan with the audit results before finishing.

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- verification/audit notes only if needed

**Status:** ✅ Complete

**Results:**
- **Audit verdict:** the straight-punch replay timing truth slice **passes audit** as scoped. The default boxing replay/debug path now truthfully surfaces straight-punch `triggered` state at the product-facing proving/debug layer, the widened timing values match repo-local config truth, and the replay-facing cadence regression proves the intended behavior without dishonest scope widening.
- **Repo-local config truth re-verified:**
  - `assets/boxing.gesture_detection.yaml` now sets boxing straight-punch `threshold.timing.triggered_grace_ms` to **240** and `threshold.rearm.pose_only_rearm_ms` to **250**.
  - `/.testbed/tests/unit/test_camera_tracking_config_profiles.gd` passed again and locks those exact boxing profile values in the selected profile bundle.
- **Replay-cadence proof re-verified:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=straight_punch_trigger_truth_visible_at_published_replay_cadence -gexit` ✅ passed (**1/1 tests, 20 asserts**).
  - That regression uses the real boxing profile’s `state_update_max_fps = 10` publish cap, derives the published snapshot interval as **100 ms**, and proves a left straight punch is still surfaced as `state = triggered` one published update later with `grace_ms_remaining = 140`, `triggered_grace_ms = 240`, and `pose_only_rearm_ms = 250`.
- **Highest-fidelity proving/debug evidence re-verified:**
  - `test_boxing_proving_hand_debug_line_surfaces_bbox_state_metrics` ✅ (**1/1, 14 asserts**) still prints `state=triggered`, `wrist_xyz_vel=0.420`, `bbox_growth=0.015`, and `grace=160ms` in the compact hand-debug line.
  - `test_boxing_punch_hover_card_uses_bbox_state_machine_debug_fields` ✅ (**1/1, 10 asserts**) still surfaces the straight-punch state machine rows instead of a flattened/fake summary.
  - `test_boxing_punch_inspector_body_calls_out_live_bbox_inputs` ✅ (**1/1, 13 asserts**) still shows the product-facing inspector truth for live-style boxing debug, including `Current state - triggered`, the bbox-growth thresholds, and `Grace timer - 160/240ms remaining (active)`.
  - `test_boxing_pose_only_punch_hover_card_and_inspector_report_skipped_hand_inputs_truthfully` ✅ (**1/1, 12 asserts**) confirms the pose-only replay/debug path says `pose-only fallback` / `bbox skipped` instead of inventing hand-box inputs.
  - `test_boxing_pose_only_punch_event_still_activates_left_tile_badge` ✅ (**1/1, 2 asserts**) passed against the proving scene backed by the default replay fixture `boxing_guard->straight_right_repeat_04_take_01.mp4`, confirming a replay straight-punch trigger still lights the punch tile badge at the product-facing proving layer.
  - `test_boxing_punch_inspector_freezes_paused_values_for_gesture_popups` ✅ (**1/1, 6 asserts**) keeps the paused `ready -> triggered` snapshot stable for auditability.
  - `test_boxing_punch_hover_card_merges_latest_state_change_signal_snapshot` ✅ (**1/1, 3 asserts**) still merges the latest transition payload into the visible hover-card row, including `state=triggered ... grace=240ms valid=true`.
- **Scope-honesty audit:** `git show --stat 689608d` confirms the implementation slice stayed narrow: the fix changed `assets/boxing.gesture_detection.yaml`, added/updated config truth assertions, and added the cadence regression in `test_pose_detector_substrate.gd`. It did **not** widen into tracker publish-rate changes, proving-harness calibration policy, or unrelated detector behavior.
- **Audit caveat:** I did not run an interactive GUI replay session. The highest-fidelity repo-local evidence available in this lane was the real proving-scene GUT coverage plus the detector/config tests above, and that evidence is consistent.
- **Bead closure:** closed `aerobeat-input-camera-tracking-4hbx` because the boxing profile truth, replay-cadence regression, and product-facing proving/debug surfaces all now agree on truthful straight-punch `triggered` visibility at the published replay cadence.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Closed the full regression lane. The `/.testbed/` harness once again allows shared calibration attempts on prerecorded replay sources, does so honestly using the visible replay pose feed, and still keeps replay `auto_bootstrap` baselines from masquerading as real shared calibration captures. In parallel, the boxing profile now keeps straight-punch `triggered` truth visible across the published 10 fps replay/debug cadence, with proving/debug surfaces and detector/config tests all agreeing on the same state-machine truth.

**Reference Check:** `REF-01` correctly named the regression lane. `REF-02` explains why shared calibration now requires centered T-pose capture and why baseline reset clears gameplay truth. `REF-03` explains why the shared overlay consumes the single runtime baseline/grid payload and why replay auto-bootstrap truth must stay separate from real calibration truth. `REF-04` confirms the later cleanup work did not address either seam. Derrick's replay-calibration clarification is now implemented in Task 5 rather than just noted as future work.

**Commits:**
- `d6bb10d` - Truthfully disable replay calibration in proving harness
- `689608d` - Restore straight-punch replay trigger truth
- `6bf087d` - Re-enable replay calibration attempts in proving harness

**Lessons Learned:** Current repo tests validate the shared calibration contract and boxing profile shape, but replay-facing truth can still drift when the harness UI policy diverges from the substrate's actual readiness contract. Replay-first proving flows need explicit tests for both directions: (1) never pretend auto-bootstrap is a real shared calibration capture, and (2) never disable a legitimate calibration path just because arbitrary footage might fail to satisfy the pose prerequisites.

---

*Completed on 2026-07-20*
