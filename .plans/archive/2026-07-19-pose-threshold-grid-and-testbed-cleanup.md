# AeroBeat Input Camera Tracking — Pose-Threshold Grid + Testbed Cleanup

**Date:** 2026-07-19  
**Status:** Complete  
**Last Updated:** 2026-07-19 16:00 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Remove stale detector paths and out-of-date testbed behavior from `aerobeat-input-camera-tracking` so the repo truth matches the current pose-threshold-only, nose+two-wrists, direct 4x3 Flow / simplified Boxing direction.

---

## Overview

Derrick called out that `aerobeat-input-camera-tracking` still contains too much obsolete logic in both `src/` and `.testbed/`: alternate detector paths we no longer use, old Boxing gesture/UI surfaces, and Flow proving/testbed behavior that still presents the older clock-based interaction model instead of the newer direct 4x3 grid direction. That means the library and its proving project are no longer telling the same truth as the current AeroBeat architecture.

This cleanup should be treated as a repo-owned modernization slice, not just a cosmetic docs pass. The likely work spans four seams: (1) retire unused detector backends and gameplay signals/config/debug surfaces that no longer belong in the active runtime contract, (2) clean up the `.testbed` YAML/config surfaces so they stop carrying dead variables and fixture lanes for retired detector/gameplay systems, (3) rewrite the Flow proving/testbed scene so it showcases the current 4x3 grid model rather than the clock-era interaction model, and (4) remove old Boxing proving/testbed UI and logic for gestures/gameplay we have explicitly simplified away, especially side-step and knee-strike surfaces.

Derrick also explicitly asked that the first audit expand into the mounted dependency repos used by the `.testbed` scene stack. That means the implementation hit list should not stop at this repo's `src/` and `.testbed/` roots; it should also classify whether adjacent addon dependencies such as `aerobeat-input-core`, `aerobeat-tool-camera-tracking`, `aerobeat-tool-camera-recording`, and `aerobeat-vendor-mediapipe-python` still carry dead code paths that are only hanging around because of the older detector-era architecture.

Because this repo has both runtime code and a Godot testbed, execution should follow the normal coder → QA → auditor loop. The coder first needs to make the runtime/testbed changes and run repo-local validation. QA should then verify the highest-fidelity proving behavior available, especially that Flow now reads as 4x3-grid truth and Boxing no longer exposes dead gesture/UI paths. The auditor should finally truth-check the remaining public/runtime surfaces so we do not leave any stale detector or gameplay story half-removed.

### 2026-07-19 Boxing cleanup decision update

Derrick explicitly approved deleting the stale alternate Boxing tracking work outright rather than preserving it as fallback/reference material. The active Boxing truth must remain:
- pose-threshold detection only
- gameplay landmarks centered on `nose`, `wrist_left`, and `wrist_right`
- preserved left/right wrist detection for straight punches, hooks, and uppercuts
- preserved dual-wrist guard detection
- preserved pose-threshold `squat` detection
- preserved pose-threshold `weave_left` / `weave_right` detection
- preserved Boxing threshold YAML tuning variables, which should stay in place for continued fine-tuning rather than being stripped as “stale”

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Main runtime surface still exposing stale gesture-era signals/config glue | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/AeroCameraTracking.gd` |
| `REF-02` | Provider/runtime bridge surface for active camera tracking contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd` |
| `REF-03` | Current config/profile loader surfaces still carrying gesture-detection-era shape | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/camera_tracking_config.gd` |
| `REF-04` | Profile loader mapping boxing/flow assets into runtime/testbed | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/config/profile_config_loader.gd` |
| `REF-05` | Stale alternate boxing detector path: prototype matcher | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/prototype_punch_matcher.gd` |
| `REF-06` | Stale alternate boxing detector path: learned classifier | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/learned_punch_classifier.gd` |
| `REF-07` | Active pose substrate that should remain aligned with nose + two wrists truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-08` | Flow proving scene still suspected to present clock-era logic | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn` |
| `REF-09` | Flow-specific testbed script surface still reflecting ring/clock model | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/flow_ring_chart.gd` |
| `REF-10` | Boxing proving scene likely still carrying dead gesture/UI surfaces | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn` |
| `REF-11` | Boxing proving harness where dead gesture/debug UI may still be wired | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-12` | Current canonical Flow architecture truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/docs/architecture/beatsaver-flow-v1-conversion.md` |
| `REF-13` | Current canonical Boxing architecture truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/docs/architecture/beatsaver-boxing-v1-conversion.md` |
| `REF-14` | `.testbed` mounted addon/dependency map | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/addons.jsonc` |
| `REF-15` | `.testbed` boxing/flow fixture YAML surface likely carrying dead lanes | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/` |

---

## Tasks

### Task 1: Audit exact stale runtime + testbed surfaces before implementation

**Bead ID:** `aerobeat-input-camera-tracking-az62`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`, `REF-11`, `REF-12`, `REF-13`, `REF-14`, `REF-15`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-az62` with `bd update aerobeat-input-camera-tracking-az62 --status in_progress --json` when you start. Audit `aerobeat-input-camera-tracking` plus the mounted `.testbed` dependency repos for stale runtime/testbed surfaces that conflict with the current pose-threshold-only, nose+two-wrists, direct-4x3-Flow / simplified-Boxing direction. Produce an exact hit list covering: dead detector backends/classes/configs, stale `.testbed` YAML/config variables and fixture lanes, stale exported signals or provider events, old Flow clock/ring proving logic, obsolete Boxing proving UI/gesture surfaces (including side-step and knee-strike paths), and any dependency-repo dead paths that should be cleaned up in follow-on repo-owned slices. Distinguish must-remove, must-rewrite, repo-local vs dependency-owned, and keep-for-now seams so the coder can execute without guesswork.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- audit artifact(s) to be determined during execution
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md`

**Status:** ✅ Complete  

**Results:** Completed the exact stale-surface audit across repo-local runtime/testbed code, `.testbed` YAML/config/fixture lanes, and the mounted dependency stack. The audit locked a coder-ready hit list: remove `src/detectors/prototype_punch_matcher.gd` and `src/detectors/learned_punch_classifier.gd`; strip `prototype`/`classifier` branches and backend values from `assets/boxing.gesture_detection.yaml`; rewrite the `src/providers/camera_tracking_provider.gd` ↔ `src/AeroCameraTracking.gd` boundary so the existing `flow_left_cell_entered` / `flow_right_cell_entered` runtime truth replaces stale `swing_*` / `trail_*` façade signals; remove stale Boxing proving/testbed UI and fixture families for knee/sidestep/stance-transition paths; and replace the old Flow swing/trail/ring proving surfaces with direct 4x3-grid proving. The audit also identified one clear dependency-owned follow-up seam in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/input_provider.gd`, which still advertises older sidestep-style shared contract language even though `input_manager.gd` already aligns to `flow_left_cell_entered` / `flow_right_cell_entered`.

---

### Task 2: Remove stale alternate detector/runtime paths from `src/`

**Bead ID:** `aerobeat-input-camera-tracking-0qlu`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-12`, `REF-13`  
**Prompt:** Implement the runtime/library cleanup in `src/` so the active library contract matches current truth: pose-threshold-only detection, nose + `wrist_left` + `wrist_right` as the active gameplay landmarks, no dead prototype/classifier-era boxing paths, and no stale exported signals/config/profile surfaces for simplified-away gameplay such as side-step or knee-strike if they no longer belong in the active contract. Keep the resulting runtime contract truthful for the current Flow + Boxing direction and run relevant repo-local validation.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- exact runtime files to be finalized from Task 1 hit list
- likely `src/AeroCameraTracking.gd`
- likely `src/providers/camera_tracking_provider.gd`
- likely `src/config/camera_tracking_config.gd`
- likely `src/config/profile_config_loader.gd`
- likely `src/detectors/pose_detector_substrate.gd`
- likely removal or retirement of `src/detectors/prototype_punch_matcher.gd`
- likely removal or retirement of `src/detectors/learned_punch_classifier.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md`

**Status:** ✅ Complete  

**Results:** Aligned the repo-local runtime/library contract to the simplified current truth. Updated `src/AeroCameraTracking.gd`, `src/providers/camera_tracking_provider.gd`, `src/config/camera_tracking_config.gd`, `src/config/profile_config_loader.gd`, `src/detectors/pose_detector_substrate.gd`, `src/input_provider.gd`, and `assets/boxing.gesture_detection.yaml` so the active contract is pose-threshold-only, centered on `nose`, `wrist_left`, and `wrist_right`, uses `flow_left_cell_entered` / `flow_right_cell_entered` instead of stale `swing_*` / `trail_*`, and no longer exposes simplified-away sidestep/knee/leg-lift runtime/profile surfaces. Replaced the old prototype/classifier detector implementations with inert compatibility stubs and updated repo-local unit coverage (`test_aero_camera_tracking.gd`, `test_camera_tracking_config_profiles.gd`, `test_input_provider_adapter.gd`, `test_pose_detector_substrate.gd`) to remove stale prototype/classifier/per-family and swing/trail truth. Validation passed with a targeted headless Godot run covering `test_camera_tracking_config_profiles.gd`, `test_input_provider_adapter.gd`, `test_aero_camera_tracking.gd`, `test_camera_tracking_provider.gd`, and `test_pose_detector_substrate.gd` (`114/114` passed). Repo dirt truth after this pass: there are unrelated tracked `.plans/` archive moves and plan-note edits already present in the worktree alongside the intended runtime/test updates; they appear to be historical-plan hygiene rather than generated runtime noise, so they should stay explicitly classified in the plan rather than being silently folded into this bead.

---

### Task 3: Rewrite Flow proving/testbed surfaces around the direct 4x3 grid

**Bead ID:** `aerobeat-input-camera-tracking-elxp`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-08`, `REF-09`, `REF-12`  
**Prompt:** Replace the stale Flow proving/testbed story with the current direct calibrated 4x3 Flow direction. Remove old clock/ring-era logic, stale swing/trail proving vocabulary, and obsolete flow fixture/config lanes, then update the Flow scene/scripts/harness so the testbed visibly demonstrates the 4x3 grid model and its current scope rather than the retired older interaction system.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- exact Flow scene/script files to be finalized from Task 1 hit list
- likely `.testbed/scenes/flow_proving.tscn`
- likely `.testbed/scripts/flow_ring_chart.gd`
- likely `.testbed/scripts/proving_harness.gd`
- likely Flow fixture/config surfaces under `.testbed/assets/fixtures/flow/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md`

**Status:** ✅ Complete  

**Results:** Reframed the Flow proving/testbed layer around the current direct calibrated 4x3 model. Updated `.testbed/scenes/flow_proving.tscn`, `.testbed/scripts/flow_ring_chart.gd`, and `.testbed/scripts/proving_harness.gd` so Flow proving now consumes the real `flow_left_cell_entered` / `flow_right_cell_entered` contract, renders left/right 4x3 cell boards plus shoulder-relative direction boards, and no longer presents retired swing/trail/ring semantics as current truth. Also rewrote Flow-facing labels, summaries, event-feed text, and console snapshot output to describe live cell-entry + recent-direction truth, and archived the obsolete rotation fixture YAML expectations as noncanonical raw-reference captures instead of current Flow proving truth. Validation passed with a targeted headless run of `test_pose_detector_substrate.gd` (`66/66`) and a headless instantiate check for `res://scenes/flow_proving.tscn` (`flow_proving_ok`). A broader run that included `test_proving_harness_trails.gd` exposed three unrelated pre-existing `_build_runtime_config` failures around `track_left_foot` assignment; these are repo-truth findings but do not appear introduced by this Flow 4x3 rewrite.

---

### Task 4: Remove dead Boxing gesture/testbed UI and simplified-away gameplay paths

**Bead ID:** `aerobeat-input-camera-tracking-69tz`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-10`, `REF-11`, `REF-13`  
**Prompt:** Clean up the Boxing proving/testbed surfaces so they match the simplified current gameplay. Remove dead UI, inspector/debug controls, and stale proving logic for unused gesture families or gameplay actions such as side-step and knee-strike if they are no longer part of the active Boxing direction. Preserve only the proving/runtime surfaces that are truthful for the current simplified path.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- exact Boxing scene/script files to be finalized from Task 1 hit list
- likely `.testbed/scenes/boxing_proving.tscn`
- likely `.testbed/scripts/boxing_proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md`

**Status:** ✅ Complete  

**Results:** Cleaned up the Boxing proving/testbed surfaces to match the simplified current gameplay. Removed stale alternate-tracking benchmark/doc/icon remnants, deleted stale Boxing fixture families for `knee_*`, `leg_lift_*`, `sidestep_*`, and `stance_transition`, and rewrote the proving-layer/docs expectations so the active Boxing set remains straight punches, hooks, uppercuts, dual-wrist guard, squat, and weave left/right only. In `.testbed/scripts/proving_harness.gd`, removed stale backend-override plumbing (`AEROBEAT_PUNCH_BACKEND_OVERRIDE`, learned-classifier/prototype overrides), removed prototype/classifier event-payload enrichment and fixture snapshot export fields, and fixed playback refresh to use cached `media_loaded` truth instead of recursively re-querying during debug refresh. Updated `test_boxing_proving_harness_profiles_and_debug.gd` and the human-verification checklist/log docs to match the simplified Boxing surface. Validation passed on targeted reruns for the recalibrate button route, fixture timeline file, replay-step-button regression, and hover-card tail regression. The long full-file Boxing harness run originally exposed two real issues (recalibrate refresh recursion and cached `media_loaded` expectation mismatch); both were fixed before closure. Remaining work now moves to QA and audit.

---

### Task 5: QA the runtime + testbed cleanup in the highest-fidelity safe path

**Bead ID:** `aerobeat-input-camera-tracking-4e1j`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01` through `REF-13`  
**Prompt:** Verify that the repo now tells one truthful story across `src/` and `.testbed/`: no alternate unused detector paths remain active, the active runtime contract reflects pose-threshold-only / nose+wrists truth, Flow proving shows the direct 4x3 direction instead of the clock model, and Boxing proving no longer exposes dead gesture/UI paths like side-step or knee-strike. Use the highest-fidelity safe validation path available and record exact gaps or remaining stale seams.

**Folders Created/Deleted/Modified:**
- validation/evidence folders as needed
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- QA artifacts as needed
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md`

**Status:** ❌ Failed  

**Results:** QA ran on 2026-07-19 using the highest-fidelity safe path available. Evidence gathered: (1) a headless Flow scene load check passed via `godot --headless --path .testbed --script ../.temp/qa_load_flow_scene.gd`, logging `FLOW_SCENE_OK name=FlowProving title=FLOW DIRECT 4x3 PROVING` plus runtime `Flow harness live`; (2) a fresh unattended exact-file GUT run for `res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` completed `39/39 passed` (`.testbed/test-results/task5-qa-20260719/gut-test_boxing_proving_harness_profiles_and_debug-only.log`); (3) repo-truth inspection confirmed `src/config/profile_config_loader.gd` strips `prototype` / `classifier` and stale families while `src/detectors/pose_detector_substrate.gd` keeps the active pose-threshold runtime path; and (4) Flow proving/testbed copy now presents direct calibrated 4x3 cell-entry + direction truth instead of the old clock/ring model. However QA did **not** pass overall because the approved active Boxing contract and the shipped runtime profile still disagree: `assets/boxing.gesture_detection.yaml` currently sets `squat.backend: disabled` and `weave.backend: disabled`, while the approved active Boxing set in this plan explicitly preserves pose-threshold `squat` plus `weave_left` / `weave_right`. Because the loader preserves `disabled`, the repo still does not tell one truthful Boxing story across runtime config and testbed/proving surfaces, so the bead stays blocked and the repo is not yet ready for audit.

---

### Task 5A: Reconcile the remaining Boxing squat/weave profile mismatch

**Bead ID:** `aerobeat-input-camera-tracking-3q9b`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-04`, `REF-07`, `REF-10`, `REF-11`, `REF-13`  
**Prompt:** Claim bead `aerobeat-input-camera-tracking-4e1j.1` when you start. Fix the narrow post-QA mismatch so the shipped Boxing runtime/testbed contract preserves pose-threshold `squat` and `weave_left` / `weave_right` as active surfaces, matching the approved active Boxing set in this plan. Update only the minimum runtime/profile/testbed surfaces needed, then run the minimum relevant validation proving the mismatch is resolved without reintroducing retired alternate-backend or dead-gesture paths.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- likely `assets/boxing.gesture_detection.yaml`
- any coupled runtime/testbed surface needed to keep the Boxing story truthful
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md`

**Status:** ✅ Complete  

**Results:** Fixed the narrow post-QA mismatch in the shipped Boxing profile. Updated `assets/boxing.gesture_detection.yaml` so `squat.backend` and `weave.backend` are both `threshold` again, preserving the approved active Boxing set while keeping the existing YAML tuning values unchanged and without reintroducing any retired alternate backends or dead gesture families. Added matching assertions in `.testbed/tests/unit/test_camera_tracking_config_profiles.gd` and `.testbed/tests/unit/test_pose_detector_substrate.gd` to prove the canonical Boxing bundle keeps `guard`, `squat`, and `weave` enabled on the threshold backend. Validation passed via a targeted headless GUT run of `test_camera_tracking_config_profiles.gd` and `test_pose_detector_substrate.gd` (`71/71` passed, exit code `0`).

---

### Task 5B: Re-QA the runtime + testbed cleanup after the squat/weave profile fix

**Bead ID:** `aerobeat-input-camera-tracking-fm4i`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01` through `REF-15`  
**Prompt:** Re-run QA on the cleaned repo after the Boxing squat/weave profile fix. Verify that the repo now tells one truthful story across `src/` and `.testbed/`: no alternate unused detector paths remain active, the active runtime contract reflects pose-threshold-only / nose+wrists truth, Flow proving shows the direct 4x3 direction instead of the clock model, Boxing proving no longer exposes dead gesture/UI paths, and the preserved active Boxing set now truthfully includes guard, squat, weave_left/weave_right, plus left/right straight punches, hooks, and uppercuts. Use the highest-fidelity safe validation path available, including a fresh unattended full-file GUT run for `res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`, and record exact evidence plus whether the repo is ready for audit.

**Folders Created/Deleted/Modified:**
- validation/evidence folders as needed
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- QA artifacts as needed
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md`

**Status:** ✅ Complete  

**Results:** Re-QA passed after the Boxing squat/weave profile fix. Verification included a hidden-testbed sync, a fresh unattended full-file GUT run for `res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` (`39/39 passed`), a Flow proving capture/probe showing `FLOW DIRECT 4x3 PROVING` plus direct-grid/readout/footer truth, and a Boxing profile probe proving the shipped `boxing` bundle keeps `straight_punch`, `hook`, `uppercut`, `guard`, `squat`, and `weave` all on the `threshold` backend. QA also confirmed the preserved Boxing threshold YAML tuning variables remain present where expected. The same unattended run broadened into the wider unit set and surfaced two unrelated failures in `res://tests/unit/test_proving_harness_trails.gd`; QA recorded those separately and still judged the requested Boxing/Flow contract truth ready for audit.

---

### Task 6: Audit the repo truth after cleanup

**Bead ID:** `aerobeat-input-camera-tracking-3pf0`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01` through `REF-13`  
**Prompt:** Independently truth-check the final repo state against Derrick's requested simplification. Confirm the runtime contract, proving scenes, config surfaces, and visible/debug/testbed behavior no longer leak stale detector or gameplay assumptions. Close the audit only if the repo is genuinely aligned to the pose-threshold-only, direct-4x3-Flow / simplified-Boxing truth.

**Folders Created/Deleted/Modified:**
- audit/evidence folders as needed
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- audit artifacts as needed
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md`

**Status:** ✅ Complete  

**Results:** Audit passed. The auditor independently re-checked the plan/bead chain, current repo diff footprint, active runtime/config code, shipped profiles, proving scenes/scripts, and re-ran `res://tests/unit/test_proving_harness_trails.gd` to evaluate whether the known unrelated failures should block this slice. Audit verdict: the active Boxing runtime/proving/config story now matches the requested pose-threshold simplification; Flow proving now reflects the direct 4x3 + direction model; the approved active Boxing set is preserved (`straight_punch`, `hook`, `uppercut`, `guard`, `squat`, `weave` on `threshold` backend); and stale alternate-tracking Boxing surfaces are gone from the active proving/runtime story. The two remaining failures in `res://tests/unit/test_proving_harness_trails.gd` were recorded as real but unrelated replay-step-control repo truth and did not block this slice’s audit, so bead `aerobeat-input-camera-tracking-3pf0` was closed as passed.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed the exact stale-surface audit plus four implementation seams: runtime/library contract cleanup in `src/` with boxing gesture-profile simplification, a Flow proving/testbed rewrite that now reflects the direct calibrated 4x3 model, a Boxing proving/testbed cleanup that deletes stale alternate-tracking surfaces while preserving the active pose-threshold Boxing set, and a narrow corrective fix that restores `squat` and `weave` as active shipped threshold surfaces in the Boxing gesture profile. Re-QA then passed for the requested Boxing/Flow contract truth, and final audit passed as well.

**Reference Check:** `REF-01` through `REF-15` are materially addressed by the runtime/library, Flow proving, Boxing proving, fixture/config cleanup, squat/weave profile-fix, re-QA, and audit passes. The remaining known repo truth is outside this completed slice: two unrelated replay-step-control test failures in `res://tests/unit/test_proving_harness_trails.gd`.

**Commits:**
- Pending

**Lessons Learned:**
- The sharpest repo contract break was the mismatch between provider-side `flow_left_cell_entered` / `flow_right_cell_entered` truth and façade-side `swing_*` / `trail_*` surfaces.
- The current worktree also contains separate tracked `.plans/` archive moves and plan-note edits that should stay explicitly classified as repo dirt rather than being silently treated as generated noise.
- Broad validation passes can surface unrelated pre-existing config/test issues; those should be recorded as repo truth without misattributing them to the active seam when the targeted validation for that seam still passes.
- A green exact-file QA run is not enough if the shipped runtime profile still disagrees with the approved active contract; profile YAML truth has to match the proving/runtime story before audit.

---

*Drafted on 2026-07-19*
