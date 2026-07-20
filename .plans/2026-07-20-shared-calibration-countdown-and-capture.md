# AeroBeat Input Camera Tracking — Shared Calibration Countdown + Capture

**Date:** 2026-07-20  
**Status:** In Progress  
**Last Updated:** 2026-07-20 07:31 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Replace the current one-press athlete recalibration button with a shared Boxing + Flow calibration flow that matches the BeatSaver-conversion architecture pivot: a visible countdown/T-pose capture UX in the proving scenes plus one shared calibration capture contract that both gameplay input styles use.

---

## Overview

The recovered AeroBeat handoff pointed us back at `aerobeat-input-camera-tracking` as the next repo-owned lane after the docs/content contract cleanup. Derrick clarified that the immediate next seam is **not** more docs work; it is making the Boxing and Flow Godot proving/testbed projects reflect the current architecture choices. Right now the repo still exposes athlete recalibration as an instant button press, but the current product need is a more athlete-facing flow: prompt the athlete to stand centered in camera in a T-pose, show an on-screen countdown, then capture the shared calibration data used by both Boxing and Flow.

This slice has two coupled parts. First, we need a **shared runtime contract** for calibration sessions so Boxing and Flow do not diverge in what “calibration” means or how the captured pose data is staged and committed. Second, we need **scene/UI integration** in the proving projects so the athlete gets clear affordances during testing: start calibration, see a 5-second countdown, see T-pose + center-in-camera instructions, then receive truthful success/failure state after capture. The likely first implementation should stay conservative: one shared countdown/capture path, one shared captured baseline payload, then scene-specific display/use of that truth afterward.

This work is explicitly connected to the broader BeatSaver-conversion architecture pivot. Recent repo cleanup already aligned Flow toward direct calibrated 4x3 grid truth and Boxing toward simplified nose + wrists pose-threshold truth. The new calibration seam should therefore capture the shared athlete anchor data needed by those two directions rather than slipping back into older one-off or gameplay-specific calibration paths.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Latest AeroBeat handoff naming this repo and next slice | `/home/derrick/.openclaw/workspace/projects/openclaw-pico/handoffs/handoff-2026-07-20T00-39-00-04-00.md` |
| `REF-02` | Most recent repo-owned cleanup plan that aligned Flow/Boxing truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md` |
| `REF-03` | Shared proving harness current recalibrate button behavior | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-04` | Shared pose substrate baseline + recalibration logic | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-05` | Boxing proving scene/harness surfaces consuming calibration truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn` |
| `REF-06` | Flow proving scene/harness surfaces consuming calibration truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn` |
| `REF-07` | Current proving-scene tests around recalibration routing | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` |
| `REF-08` | Current substrate tests around recalibration + baseline reset | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd` |

---

## Tasks

### Task 1: Audit the shared calibration seam and lock the shared capture contract

**Bead ID:** `aerobeat-input-camera-tracking-decv`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, claim bead `aerobeat-input-camera-tracking-decv` with `bd update aerobeat-input-camera-tracking-decv --status in_progress --json` when you start. Serve as the research role. Audit the current athlete recalibration seam across the shared proving harness, Boxing/Flow proving scenes, and the pose detector substrate. Return an exact implementation hit list for a shared calibration session contract that both Boxing and Flow should use: start/request state, 5-second countdown behavior, athlete-facing instructions (center in camera + T-pose), capture/commit timing, shared captured baseline fields, failure/abort conditions, and which scene/runtime files should own each responsibility. Call out what should stay shared vs scene-specific so the coder can implement without guessing. Update the plan with exact findings.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md`

**Status:** ✅ Complete

**Results:**
- Audit complete across the current recalibration seam. Files inspected: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` (scene-backed boxing wrapper inspected because `boxing_proving.tscn` mounts it), `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`, and `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_provider.gd` plus `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_aero_camera_tracking.gd` to confirm there is currently no calibration-session coverage in those provider/singleton wrappers.
- Current seam truth:
  - Shared proving harness owns a single top-right `AthleteRecalibrateButton` whose press path immediately calls `request_athlete_recalibration()` on the provider/singleton, then only reports `Athlete baseline recalibration requested` or `... unavailable`; there is no countdown, no instructions, no cancel/retry state, and no scene-specific UI contract beyond that button (`REF-03`).
  - Runtime provider/singleton layers are pure pass-through wrappers today: `AeroCameraTracking.request_athlete_recalibration()` forwards to `CameraTrackingProvider.request_athlete_recalibration()`, which forwards to `PoseDetectorSubstrate.request_athlete_recalibration()` (`REF-04`).
  - The substrate recalibration call is an immediate reset only: clear baseline accumulator, clear transient gesture state, zero height/squat-derived measurements, empty events, and rebuild public gesture debug/state. There is no pending/requested/in-progress capture state and no gating on athlete pose quality (`REF-04`).
  - Baseline commit currently happens implicitly after the next 5 valid tracking/reacquiring frames with positive shoulder width, torso height, wrist span, and a visible nose. The accumulator averages these fields into one shared baseline payload: `sample_frames`, `shoulder_width`, `torso_height`, `athlete_height`, `shoulder_center_x`, `shoulder_center_y`, `hip_center_y`, `nose_x`, `nose_y`, `wrist_span`, `left_knee_y`, `right_knee_y`, `left_ankle_y`, `right_ankle_y` (`REF-04`, `REF-08`).
  - Current proving/unit tests only verify the old seam: baseline auto-build after 5 frames, reset clearing baseline/squat truth, and both proving scenes surfacing a recalibrate button that calls the provider exactly once. There is no countdown/session/instruction/failure-path coverage yet (`REF-07`, `REF-08`).
- Exact implementation hit list for the shared calibration session contract:
  - **Start/request state:** replace the runtime boolean-style `request_athlete_recalibration()` seam with a shared calibration-session API rooted in `pose_detector_substrate.gd` and surfaced unchanged through `camera_tracking_provider.gd` and `AeroCameraTracking.gd`. The shared runtime contract should expose a session dictionary/state machine with at least `idle`, `countdown`, `capture_pending`, `capturing`, `succeeded`, `failed`, and `aborted`/`cancelled`, plus `seconds_remaining`, `countdown_started_at_ms`, `capture_started_at_ms`, `failure_reason`, and a snapshot of the most recent pose-readiness evaluation.
  - **5-second countdown behavior:** the countdown should be driven from shared runtime time/tick state rather than scene timers so Boxing and Flow see identical truth from the same provider state. Button press should transition `idle -> countdown` immediately, clear the prior baseline at session start, and hold gesture truth in the existing uncalibrated state until commit succeeds. The shared proving harness should only render the runtime-reported countdown and disable/relabel the entry button while a session is active.
  - **Athlete-facing instructions:** shared runtime should publish stable instruction keys/text state for `stand_centered` and `hold_t_pose` based on pose-readiness checks, while the shared proving harness owns the visible copy/layout. Scene-specific surfaces may style or place the copy differently, but the wording contract and readiness booleans should stay shared so Boxing and Flow do not drift. The current scenes have no dedicated instruction nodes, so Task 3 should add them at the proving-layer/UI surface rather than burying text in gameplay-specific scripts.
  - **Capture/commit timing:** at countdown completion, runtime should validate the current frame before counting capture samples. Only then transition into `capturing` and accumulate the baseline sample window. Commit should happen once the required capture sample count is reached from valid frames during the active capture window; do not silently keep using pre-countdown samples. If readiness drops mid-capture, runtime should either pause accumulation or fail the session explicitly rather than averaging mixed-quality frames.
  - **Shared captured baseline fields:** keep the existing shared baseline payload as the single source of truth for both modes because both Boxing and Flow already consume it indirectly (`shoulder_width`, `torso_height`, `athlete_height`, `shoulder_center_x`, `shoulder_center_y`, `hip_center_y`, `nose_x`, `nose_y`, `wrist_span`, `left_knee_y`, `right_knee_y`, `left_ankle_y`, `right_ankle_y`, `sample_frames`, `is_calibrated`). Add session metadata alongside it rather than forking per-mode baselines; likely candidates are `captured_at_ms`, `capture_source`, and session/result fields, but the geometric baseline should remain shared.
  - **Failure / abort / retry conditions:** shared runtime should own failure truth for at least: tracking lost/not tracking, required landmarks missing (nose/shoulders/wrists/hips), athlete not centered enough, arms not in T-pose tolerance, countdown interrupted by explicit cancel/restart, and capture window expiring without enough valid frames. Shared proving harness should expose retry/cancel affordances mapped back to the runtime API. Scene-specific scripts should not invent their own failure heuristics.
  - **Responsibility split:** `pose_detector_substrate.gd` owns the session state machine, readiness heuristics, countdown/capture timing, baseline reset/commit, and public detector-state payload; `camera_tracking_provider.gd` and `AeroCameraTracking.gd` stay thin forwarders only; `.testbed/scripts/proving_harness.gd` owns shared athlete UX wiring (button state, countdown label, instruction label, success/failure status reflection, fixture event logging, shared tests); `.testbed/scenes/boxing_proving.tscn` and `.testbed/scenes/flow_proving.tscn` own only scene placement/styling of the shared calibration widgets; `.testbed/scripts/boxing_proving_harness.gd` should continue consuming shared state for boxing-specific summaries/debug but should not fork the session logic.
- Recommended test additions for later tasks:
  - substrate tests for session state transitions, countdown expiry, T-pose/centering readiness gates, valid capture commit, mid-session failure, cancel/retry, and preservation of the shared baseline payload shape;
  - proving harness tests that both scenes surface the shared countdown/instruction state and map button actions to the new runtime API rather than the old instant reset;
  - provider/singleton wrapper tests only if the API shape changes beyond a simple forwarder.
- Ambiguity to resolve during implementation: the repo currently uses the same 5-frame sample threshold for baseline commit and the requested UX also asks for a 5-second countdown. The audit recommends keeping those as separate concepts: 5 seconds for athlete-facing countdown, then a distinct capture sample window (which may remain 5 valid frames unless the coder finds a stronger repo-local reason to change it).

---

### Task 2: Implement the shared calibration session capture contract

**Bead ID:** `aerobeat-input-camera-tracking-t8rm`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-08`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait for Task 1, then claim bead `aerobeat-input-camera-tracking-t8rm` with `bd update aerobeat-input-camera-tracking-t8rm --status in_progress --json`. Serve as the coder. Implement the shared runtime-side calibration session contract used by both Boxing and Flow. Replace the current instant-reset-only recalibration path with a truthful session flow that supports a 5-second capture countdown, shared athlete instructions, and a single shared capture/commit of the baseline data needed by both gameplay styles. Keep the contract centralized rather than duplicating logic per scene. Add or update repo-local tests around baseline reset/capture/session state as needed, run relevant validation, update the plan with exact edits and evidence, commit/push to `main`, and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_provider.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_aero_camera_tracking.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md`

**Status:** ✅ Complete

**Results:**
- Implemented the shared runtime-side calibration session contract centrally in `REF-04` (`pose_detector_substrate.gd`) instead of duplicating per-scene logic. The old instant reset path now starts a truthful session state machine with `countdown -> capture_pending -> capturing -> succeeded/failed/cancelled`, shared readiness/instruction truth, and explicit capture-window timing.
- Added shared calibration-session payload exposure to detector state and metrics so downstream consumers can read countdown seconds, readiness booleans, instruction copy, failure reason, capture progress, and final result from one place. The baseline payload stayed canonical; only tightly scoped metadata fields were added alongside it (`captured_at_ms`, `capture_source`).
- Preserved the existing shared baseline geometry capture path while separating the new athlete-facing 5-second countdown from the distinct post-countdown capture sample window, matching the conservative ambiguity resolution recorded in Task 1 (`REF-04`, `REF-08`).
- Kept wrappers thin by adding pass-through helpers in `camera_tracking_provider.gd` and `AeroCameraTracking.gd` for start/cancel/get calibration session state without moving ownership out of the substrate (`REF-04`).
- Added repo-local tests covering countdown/session transitions, centering + T-pose readiness gates, successful capture commit, capture-window failure, cancel behavior preventing silent auto-recalibration, and wrapper exposure in provider/singleton layers (`REF-08`).
- Validation run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_camera_tracking_provider.gd,res://tests/unit/test_aero_camera_tracking.gd -gunit_test_name=calibration -gexit` ✅ passed (8/8).
- Broader spot-check: the same three files run without the calibration filter exposed two pre-existing provider depth-runtime fixture failures (`test_camera_tracking_provider_live_frame_merges_preview_descriptor_for_real_depth_runtime` and `...replay_polling_merges_preview_descriptor_for_real_depth_runtime` expecting `depth_runtime_status=ready` but seeing `failed/artifact_missing`). Those failures are outside this calibration slice and were not introduced by the new calibration-session assertions.

---

### Task 3: Wire the countdown/T-pose athlete UX into Boxing and Flow proving scenes

**Bead ID:** `aerobeat-input-camera-tracking-uk6m`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait for Task 2, then claim bead `aerobeat-input-camera-tracking-uk6m` with `bd update aerobeat-input-camera-tracking-uk6m --status in_progress --json`. Serve as the coder. Update the shared proving harness plus the Boxing/Flow proving scene surfaces so recalibration becomes an athlete-facing calibration flow: visible button/entrypoint, 5-second on-screen countdown, instructions to stand centered in camera in a T-pose, truthful in-progress/success/failure messaging, and scene UI that reflects the shared calibration state without duplicating the underlying capture logic. Add or update proving-scene tests, run relevant validation, update the plan with exact edits/evidence, commit/push to `main`, and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn`
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- additional proving-scene test files to be determined during execution
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: QA the shared calibration countdown and proving-scene integration

**Bead ID:** `aerobeat-input-camera-tracking-naxc`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait for Task 3, then claim bead `aerobeat-input-camera-tracking-naxc` with `bd update aerobeat-input-camera-tracking-naxc --status in_progress --json`. Serve as QA. Verify the new calibration flow end to end at the highest-fidelity repo-local level available: starting calibration from the proving scenes, the 5-second countdown, T-pose/centering guidance visibility, shared runtime calibration state transitions, successful capture path, reset/retry behavior, and preservation of the current Boxing + Flow contract truth after calibration. Use repo-local tests and direct source/scene truth checks. Update the plan with exact QA evidence and close the bead with a concrete reason when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Audit the calibration lane against the architecture pivot

**Bead ID:** `aerobeat-input-camera-tracking-sbjz`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, wait for Task 4, then claim bead `aerobeat-input-camera-tracking-sbjz` with `bd update aerobeat-input-camera-tracking-sbjz --status in_progress --json`. Serve as auditor. Independently truth-check the calibration work against the current AeroBeat architecture pivot: shared calibration contract across Boxing + Flow, athlete-facing proving UX, no regression back to divergent gameplay-specific calibration semantics, and repo-visible truth that the countdown/T-pose capture flow is now the intended proving-scene path. Use diffs, validation output, and current repo state. Update the plan with the audit outcome and close the bead only if the work actually passes.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Created on 2026-07-20*
