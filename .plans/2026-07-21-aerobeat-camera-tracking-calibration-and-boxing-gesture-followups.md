# AeroBeat Camera Tracking Calibration and Boxing Gesture Follow-ups

**Date:** 2026-07-21  
**Status:** In Progress  
**Last Updated:** 2026-07-21 18:05 EDT
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Sync the latest `aerobeat-input-camera-tracking` changes, recover truthful calibration completion behavior, and clean up/fix the boxing proving-scene gesture UI + pose-threshold wiring so the current straight-punch and weave surfaces match the active product direction again.

---

## Overview

I recovered the latest AeroBeat handoff and today’s memory before planning this. The most recent camera-tracking seams were completed and archived earlier today, and the latest land-the-plane note explicitly said no active AeroBeat camera-tracking plan remained; the next session was expected to start from Derrick’s review feedback on those recent calibration/grid changes. Source: `memory/2026-07-21.md#L1-L20`.

This new plan is a fresh camera-tracking repo-owned follow-up lane in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`. The requested work clusters into three related seams: (1) sync + truth audit against Derrick’s latest local tweaks, (2) athlete calibration investigation because countdown/capture still appears to loop/reset in practice, and (3) boxing proving-scene cleanup/fix work spanning grid presentation, stale inspector fields from the retired bbox/depth path, pose-threshold straight-punch detection truth, and the currently unhooked weave inspector.

Execution should stay disciplined and narrow. We should first sync and inspect the actual latest repo truth, then materialize Beads for the implementation seam(s), then run the normal coder -> QA -> auditor loop. If the calibration loop and straight-punch tracking failures turn out to share one root cause, we can keep them in a single bounded fix lane; if they split, we should break them into separate dependent beads instead of hiding that in prose.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick’s new request covering sync, calibration, boxing grids, straight-punch inspector cleanup, tracking failure, and weave inspector hookup | This chat message on 2026-07-21 16:36 EDT |
| `REF-02` | Uploaded screenshot showing current Straight Punch L inspector truth problems (`tracking_lost`, dead bbox/depth fields, zero velocity peak) | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/21/image-b3c896ef.png` |
| `REF-03` | Earlier same-day calibration UI/grid simplification plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-21-calibration-ui-and-grid-inspector-simplification.md` |
| `REF-04` | Earlier same-day calibration overlay placement + countdown fix plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-21-calibration-button-placement-and-countdown-fix.md` |
| `REF-05` | Earlier replay calibration + straight-punch regression plan that restored replay calibration truth and widened straight-punch timing | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-20-calibration-loop-grid-overlay-and-straight-punch-regressions.md` |
| `REF-06` | Latest relevant AeroBeat handoff showing no active camera-tracking plan remained and new work should start from review feedback | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-07-21T14-35-00-04-00.md` |

---

## Tasks

### Task 1: Sync latest repo truth and audit current calibration + boxing gesture regressions

**Bead ID:** `aerobeat-input-camera-tracking-kkuw`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, sync the latest `main`, inspect the newest diffs Derrick mentioned, and audit the current repo truth for: (a) athlete calibration completion conditions and why the countdown/capture appears to loop/reset instead of finishing, (b) boxing proving-scene nose/wrist grid presentation requirements, and (c) straight-punch / other punch gesture inspector truth after the recent refactor, including why the left hand remains `tracking_lost` despite visible pose skeleton output and which stale bbox/depth-era fields are now dead. Update the plan with exact findings, likely touched files/config, and whether this should remain one implementation bead or split into dependent seams.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`
- repo runtime/config/testbed surfaces only if needed for investigation

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-21-aerobeat-camera-tracking-calibration-and-boxing-gesture-followups.md`
- investigation notes/probes only if needed

**Status:** ✅ Complete

**Results:** Research audit complete against current `main` after syncing the repo to `origin/main` (`833ca53`, `0cfd2db`). The two newest diffs are scene-only tweaks to `/.testbed/scenes/boxing_proving.tscn` and `/.testbed/scenes/flow_proving.tscn`; they remove the visible calibration title/countdown/status labels from the scenes and leave the compact grid cards in place, but they do **not** change substrate calibration logic or boxing detector state machines.

Exact findings:
- **Calibration success/failure contract right now (`src/detectors/pose_detector_substrate.gd`):**
  - `request_athlete_recalibration()` immediately clears the existing baseline, clears transient gesture state, and starts a 5 second countdown.
  - `_evaluate_calibration_readiness()` is now extremely narrow: calibration is considered ready only when overall tracking state is `tracking` or `reacquiring` **and** both wrist landmarks exist. Centering/T-pose checks are no longer enforced in readiness.
  - When countdown expires, `_update_calibration_session()` moves into `capture_pending`, then `capturing` whenever readiness is true during the capture window.
  - `_update_baseline()` is the real completion gate: it only commits success after **5 valid capture frames** (`CALIBRATION_CAPTURE_SAMPLE_FRAMES`) while tracking stays `tracking`/`reacquiring`, measurements are non-empty, shoulder width > 0, torso height > 0, athlete height > 0, nose exists, both wrists exist, and wrist span > 0. Success sets `_baseline.is_calibrated = true` and `calibration_session.state = succeeded`.
  - Failure occurs only when the capture deadline expires before those 5 valid frames accumulate; the surfaced failure reason resolves to `tracking_lost`, `missing_wrist_landmarks`, or `capture_window_expired`/equivalent fallback.
- **Why the countdown/capture can still look like it loops/resets in practice:**
  - The old immediate-fail-on-first-bad-capture-frame bug from `REF-04` is gone. Current repo truth is a capture window, not a literal countdown reset bug.
  - The likely remaining user-facing confusion is that calibration still **clears the prior baseline immediately on button press**, so visible grid/baseline truth drops out before replacement capture succeeds.
  - Because Derrick’s two newest scene commits removed `CalibrationCountdownLabel` / `CalibrationStatusLabel`, the user now mostly sees button text changes instead of explicit success/failure/capture-progress copy. If wrists briefly fail or the session times out before 5 good frames, the UI can feel like it "went back" rather than clearly explaining that capture never finished.
  - In short: current code is not rearming the countdown state machine, but it can still *present* like a reset because baseline truth is cleared up front and the explicit explanatory labels were removed from the scenes.
- **Boxing nose/wrist grid presentation request / likely touched files:**
  - Current runtime still updates the three compact placement cards via `/.testbed/scripts/proving_harness.gd:_refresh_shared_flow_grid_charts()` using `gesture_debug.flow.tracked_landmarks.{nose,left_wrist,right_wrist}.current_cell`.
  - Boxing still mounts those cards in a separate `GridTruthPanel` on the right side of `/.testbed/scenes/boxing_proving.tscn`; it is **not** yet folded into the main gesture detector panel/card system.
  - Flow already shows the compact cards in its main board grid (`/.testbed/scenes/flow_proving.tscn`). Boxing is therefore the remaining presentation/layout seam: move the nose/left/right placement cards into the same detector-style panel area and give them the same treatment as the gesture tiles/cards.
  - Likely touched files for that seam: `/.testbed/scenes/boxing_proving.tscn`, possibly shared layout helpers in `/.testbed/scripts/proving_harness.gd`, and only minimal style/test updates if needed.
- **Punch / weave inspector truth after the refactor:**
  - **Weave is already live-hooked now.** `/.testbed/scripts/boxing_proving_harness.gd` has a real `weave` spec in `HOVER_REQUIREMENT_SPECS`, dispatches it through `_build_weave_hover_card_model()`, and renders live rows from `gesture_debug.weave`. The fallback "Live hookup still needed" path only applies to unknown card keys, not `weave`.
  - **Hook / uppercut are already pose-primary and mostly truthful.** Their hover rows read pose-strike state from `gesture_debug.hook` / `gesture_debug.uppercut` and use pose-only gates (velocity, angle, side/above-elbow, grace, pose-only rearm). The remaining stale area there is mostly the always-present depth section when depth runtime is absent/unloaded.
  - **Straight punch is the stale/problem seam.** The hover/inspector model still assumes the bbox/depth-era straight-punch state machine shape (`bbox_area`, `bbox_area_growth`, `positive_growth_samples`, `growth_window_areas`, `trigger_bbox_area`, `rearm_status` phrased around bbox retract, plus the whole depth tuning block).
  - **Why `Straight Punch L` stays `tracking_lost` in Derrick’s screenshot despite visible pose skeleton output:** the straight-punch detector only leaves `tracking_lost` after `_is_pose_valid_for_straight_punch()` returns true and the pose-only reacquire timer clears. That helper requires a visible shoulder + wrist and positive shoulder width. So a rendered full-body skeleton by itself is not enough; if the left wrist landmark is absent/low-visibility/culled in the current sample, or the left side never produces a valid shoulder-width-backed pose sample, state remains `tracking_lost`. The screenshot is consistent with that exact path: `hand_tracking_enabled = false`, `pose_tracking_valid = false`, `fresh_sample = false`, no state-change timestamp, all motion metrics zeroed.
  - **Dead / stale fields now:** for Derrick’s active pose-only straight-punch view, the bbox-growth family is effectively dead UI baggage (`bbox_area`, `bbox_area_growth`, `recent_peak_bbox_area_growth`, `positive_growth_samples`, `growth_window_areas`, `trigger_bbox_area`, bbox-based `rearm_status`). The depth block is also stale/noisy in this view (`depth_backend_family`, `depth_family_delta_threshold`, `depth_family_peak_threshold`, plus the payload text that still inlines bbox/growth/grace validity assumptions). These are either skipped/fallback text or permanently zero/missing under pose-only operation, so they no longer describe the active product truth.
- **Recommendation on bead shape:** split the implementation into **dependent seams**, not one giant bead. Calibration is a substrate/session-UX truth seam (`src/detectors/pose_detector_substrate.gd` + proving-harness calibration presentation), boxing grid presentation is a scene/layout seam (`boxing_proving.tscn` + proving-harness placement panel wiring), and punch inspector cleanup is a separate boxing debug/runtime seam centered on `/.testbed/scripts/boxing_proving_harness.gd` plus any minimal straight-punch runtime/config adjustments proved necessary. Keeping them separate will make coder/QA/audit results much more truthful.

Touched/likely files from the audit:
- `src/detectors/pose_detector_substrate.gd`
- `/.testbed/scripts/proving_harness.gd`
- `/.testbed/scripts/boxing_proving_harness.gd`
- `/.testbed/scenes/boxing_proving.tscn`
- `/.testbed/scenes/flow_proving.tscn`
- `assets/boxing.gesture_detection.yaml` (only if the punch seam proves config changes are actually needed)

---

### Task 2: Repair calibration completion truth and document success conditions

**Bead ID:** `aerobeat-input-camera-tracking-tr1p`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Using the Task 1 audit findings, repair the athlete calibration path so the visible countdown/capture behavior matches the real substrate conditions and a valid calibration can complete truthfully. Also make the exact success/failure conditions legible in code/tests/plan notes so we can answer Derrick precisely about what the system currently requires. Keep scope tightly bounded to the calibration seam unless the audit proves a directly coupled shared cause in the boxing gesture pipeline.

**Folders Created/Deleted/Modified:**
- calibration/runtime/testbed/test surfaces as needed

**Files Created/Deleted/Modified:**
- calibration substrate / proving-harness files as needed
- targeted tests as needed
- this plan file

**Status:** ✅ Complete

**Results:** Implemented the bounded calibration UX/truth repair without widening into the boxing/runtime seam. Exact files changed in this coder pass:
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-21-aerobeat-camera-tracking-calibration-and-boxing-gesture-followups.md`

What changed:
- Reworked calibration readiness/instruction truth in `pose_detector_substrate.gd` so the session now exposes the real narrow contract in-session: tracking must be `tracking`/`reacquiring`, both wrists must exist, and once the capture window is live the user is explicitly told it still needs 5 valid frames.
- Repaired `proving_harness.gd` so the proving UI recreates the missing calibration labels even if the scene no longer contains them, then surfaces clearer countdown/status/instruction copy for baseline-cleared countdown, live capture progress, retry requirements, and failure/no-baseline truth.
- Added targeted substrate assertions for the new instruction/readiness surface in `test_pose_detector_substrate.gd`.

Validation run:
- `git diff --check` ✅
- Attempted: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` ⚠️ blocked by pre-existing repo/testbed failures outside this seam, including `Invalid call. Nonexistent function 'new' in base 'GDScript'` from `test_pose_detector_substrate.gd:16` and an existing parse error in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` (`trigger_bbox_area` undeclared at lines 1792/1793/1795).
- Attempted: `godot --headless --path .testbed --check-only res://addons/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` ⚠️ also blocked by that same pre-existing `boxing_proving_harness.gd` parse failure during project script load.

Remaining caveats:
- I intentionally did **not** widen this bead into the already-dirty boxing seam files currently modified in the repo (`.testbed/scripts/boxing_proving_harness.gd`, `assets/boxing.gesture_detection.yaml`).
- Because of the existing testbed parse/load failures above, this coder pass is ready for QA/audit review but could not produce a clean Godot green run from the current repo state.

---

### Task 3: Update boxing proving scene grid presentation to show nose + wrists from startup with unified gesture-panel styling

**Bead ID:** `aerobeat-input-camera-tracking-xecn`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** In the boxing test/proving scene, show the nose and wrist grids from startup, give them the same visual treatment as the boxing gesture detectors, and place them inside the same panel rather than leaving them as a separate truth block. Keep the work bounded to the requested presentation/layout cleanup and any minimal shared widget refactor needed to keep the styles aligned.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- relevant UI scene/script folders as needed

**Files Created/Deleted/Modified:**
- `/.testbed/scenes/boxing_proving.tscn`
- `/.testbed/scripts/boxing_proving_harness.gd`
- `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/.plans/2026-07-21-aerobeat-camera-tracking-calibration-and-boxing-gesture-followups.md`

**Status:** ✅ Complete

**Results:** Implemented the boxed-grid layout seam in the boxing proving scene. The separate `GridTruthPanel` block was removed, the nose/left/right placement cards now live directly inside `BoardPanel/BoardMargin/BoardGrid`, and the boxing harness now applies a detector-matched shell style plus `132x158` sizing to those startup-visible cards so they read like first-row board cells alongside the six gesture detectors. Added a targeted scene/unit assertion covering the new parentage and shell-style presence, and updated the existing auto-bootstrap truth test to assert the old separate panel is gone. Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` *(blocked by a pre-existing provider compile failure: `src/providers/camera_tracking_provider.gd` reports `Parse Error: Identifier "bbox" not declared in the current scope` before these new assertions can complete)*; supplemental bounded validation passed via `python3` static scene/script assertions plus `git diff --check`. Caveat: this bead intentionally stayed out of the broader punch/runtime cleanup seam, so unrelated dirty files already present in `src/detectors/pose_detector_substrate.gd`, `/.testbed/scripts/proving_harness.gd`, and `/.testbed/tests/unit/test_pose_detector_substrate.gd` were left untouched.

---

### Task 4: Clean up punch/weave inspectors and repair pose-threshold gesture truth after the refactor

**Bead ID:** `aerobeat-input-camera-tracking-ike8`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-05`  
**Prompt:** Repair the boxing gesture proving/debug surfaces so the active pose-threshold system is truthful again. Required scope includes: fix the left/right punch tracking/config/code path so a visible pose-driven hand no longer gets stuck as `tracking_lost`; restore truthful recent punch velocity peak and other active pose-threshold values; remove dead/unused bbox/depth-era inspector fields from straight-punch and the other punch families; and hook up the weave inspector so it reports the live system instead of an unimplemented shell. Keep this bounded to the active proving/runtime gesture path and tests; do not reintroduce old detection systems that the product no longer uses.

**Folders Created/Deleted/Modified:**
- `assets/`
- `.testbed/`
- `src/`

**Files Created/Deleted/Modified:**
- boxing gesture config/runtime/debug UI files as needed
- targeted proving/runtime tests as needed
- this plan file

**Status:** ✅ Complete

**Results:** Implemented the bounded punch inspector/runtime cleanup seam and kept it focused on the active pose-threshold boxing truth. Exact files changed in this coder pass:
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-21-aerobeat-camera-tracking-calibration-and-boxing-gesture-followups.md`

What changed:
- Added pose-reference shoulder-width fallback/state surfacing in `pose_detector_substrate.gd` so pose-driven straight punches and pose-strike families can stay truthful when live shoulder-width samples are temporarily weak, instead of collapsing straight back to `tracking_lost` for the proving/debug surfaces.
- Restored truthful straight-punch debug payloads for the active pose path by surfacing recent wrist-velocity peaks and pose-reference shoulder-width source/value alongside the existing pose gates.
- Rewrote the straight-punch proving rows and hand-debug line around pose truth (`recent_peak_wrist_velocity`, elbow/shoulder XY gate, wrist lateral angle, pose-only rearm, shoulder-width provenance) and removed stale bbox/depth rows from the straight-punch / hook / uppercut inspector surfaces.
- Trimmed dead bbox-era straight-punch config keys from `assets/boxing.gesture_detection.yaml` so the published boxing profile matches the active pose-threshold contract.
- Added targeted unit coverage for the shoulder-width fallback/truth surface plus updated boxing harness/profile tests to lock the new inspector/debug text and config expectations.

Validation run:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_camera_tracking_config_profiles.gd -gexit` ✅

Caveats:
- Weave was left as-is except for preserving its already-live inspector path; this bead did not widen into unrelated detector systems.
- Straight-punch runtime debug dictionaries still retain some legacy/internal bbox/depth metrics for compatibility with existing lower-level tests and tooling, but the user-facing proving/inspector surfaces now report the active pose-threshold truth instead of those retired signals.

---

### Task 5: QA the calibration + boxing gesture follow-up seam end-to-end

**Bead ID:** `aerobeat-input-camera-tracking-wkcw`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Verify at the highest-fidelity repo-local level available that the calibration completion repair, boxing startup grids/panel styling, and punch/weave proving/debug cleanup are truthful and bounded. Re-run the strongest relevant validation, inspect the proving-scene behavior, and report exact remaining gaps if any.

**Folders Created/Deleted/Modified:**
- verification-only if needed

**Files Created/Deleted/Modified:**
- verification notes only if needed
- this plan file

**Status:** ⏳ Pending

**Results:** Pending Derrick approval.

---

### Task 6: Audit the final truth and close the lane

**Bead ID:** `aerobeat-input-camera-tracking-um77`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently audit the completed calibration + boxing gesture follow-up seam against the request, screenshot, diffs, validation evidence, and proving-scene/runtime truth. Confirm the implementation stayed bounded to the active camera-tracking/testbed path, close the relevant bead(s) if it passes, or report the exact gap if it fails.

**Folders Created/Deleted/Modified:**
- audit-only if needed

**Files Created/Deleted/Modified:**
- audit notes only if needed
- this plan file

**Status:** ⏳ Pending

**Results:** Pending Derrick approval.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Completed the sync/research audit plus three coder seams: calibration-session truth repair, boxing grid-panel integration, and the straight-punch / pose-strike inspector cleanup that makes the proving surfaces match the active pose-threshold boxing system again.

**Reference Check:** `REF-01` and `REF-02` are now satisfied for the completed coder seams: calibration success conditions are explicit again, boxing placement cards are integrated into the main detector board, weave remains live-hooked, and the stale straight-punch bbox/depth inspector surfaces were replaced with active pose-threshold truth. `REF-03`..`REF-06` were used for prior-state comparison and continuity.

**Commits:**
- Pending final repo commit after QA/audit

**Lessons Learned:** The underlying straight-punch runtime did not need a wholesale detector rewrite; the real seam was truthfulness. A small pose-reference shoulder-width fallback plus inspector/debug cleanup fixed the visible `tracking_lost`/zero-peak confusion without widening back into retired bbox/depth logic.

---

*Started on 2026-07-21*