# AeroBeat Boxing Hand BBox Straight Punch Detection

**Date:** 2026-06-03
**Status:** In Progress
**Last Updated:** 2026-06-03 20:28 EDT
**Blocked Reason:** None
**Agent:** `pico`

---

## Goal

Add MediaPipe-backed hand bbox tracking and replace the current straight left/right punch detection with a bbox-growth + wrist-velocity state machine that is tunable from repo-owned YAML configs and observable in the boxing proving scene.

---

## Overview

The current straight-punch detection in `aerobeat-input-camera-tracking` is not reliable for a front-facing webcam boxer because monocular pose depth cues are weak and elbow/shoulder angle heuristics become unstable under occlusion. The new approach will keep MediaPipe as the perception backbone, add optional hand landmark tracking for bbox derivation, and detect straight punches using short-window wrist velocity plus positive hand bbox area growth.

Configuration ownership will live in `aerobeat-input-camera-tracking`, which will provide four YAML files under `/assets/`: `boxing.camera_tracking.yaml`, `flow.camera_tracking.yaml`, `boxing.gesture_detection.yaml`, and `flow.gesture_detection.yaml`. `aerobeat-tool-camera-tracking` will consume a tracker-facing config schema passed in by its consumers, while `aerobeat-input-camera-tracking` will own boxing/flow gameplay interpretation and pass the correct tracker config into the tool layer. `aerobeat-tool-camera-gesture-control` can later provide its own configs against the same tracker schema.

The tracker-facing YAML schema will default to `schema: aerobeat/camera_tracking_config`, `version: 1`, and `profile: boxing|flow`. The gesture-facing YAML schema will default to `schema: aerobeat/gesture_detection_config`, `version: 1`, and `profile: boxing|flow`. Tracker config will own pose/hand runtime behavior such as `tracking.pose.enabled`, `tracking.pose.inference_interval_frames`, `tracking.pose.smoothing_style`, `tracking.hands.enabled`, `tracking.hands.landmark_mode`, `tracking.hands.inference_interval_frames`, `tracking.hands.bbox_recompute_interval_frames`, `tracking.hands.bbox.enabled`, `tracking.hands.association.*`, and `tracking.hands.validity.*`. Gesture config will own gameplay interpretation such as `straight_punch.enabled`, `straight_punch.evaluation.*`, `straight_punch.thresholds.*`, `straight_punch.timing.*`, `straight_punch.rearm.*`, and `straight_punch.state_machine.*`. For flow, `straight_punch.enabled` will be `false` and the unused boxing threshold fields do not need to be duplicated in the flow gesture YAML.

The straight-punch detector will use a four-state machine: `ready`, `triggered`, `not_ready`, and `tracking_lost`. `ready -> triggered` requires valid tracking, a fresh hand sample, wrist velocity above threshold, positive bbox area growth above threshold over a configurable short sample window, and the required count of positive growth samples. Entering `triggered` emits the state change event, stores trigger bbox area, and starts the grace timer. `triggered -> not_ready` occurs only when the grace timer expires. `not_ready -> ready` occurs only once the current bbox area drops below the stored trigger bbox area minus any configured epsilon. `any_state -> tracking_lost` occurs when hand tracking becomes invalid. If tracking is lost during `triggered`, the detector enters `tracking_lost`, cancels and resets the grace timer, and clears the stored trigger bbox area. `tracking_lost -> ready` occurs once tracking is reacquired for the configured stable-valid sample count. State changes should be exposed so subscribers such as the proving-scene UI can react to left/right punch state transitions directly.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Boxing gameplay detector owner repo and proving-scene integration point | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` |
| `REF-02` | Camera tracking tool boundary where tracker-facing config and hand bbox outputs must land | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking` |
| `REF-03` | MediaPipe Python vendor layer that must expose hand landmarks / bbox through live preview and playback | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python` |
| `REF-04` | Secondary consumer that will later need its own tracker config against the same schema | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control` |
| `REF-05` | Boxing proving-harness straight left punch fixture folder containing the video and human-verified gold-truth timing YAML | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/punch_left` |
| `REF-06` | Boxing proving-harness straight right punch fixture folder containing the video and human-verified gold-truth timing YAML | `/home/derrick/Documents/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/assets/fixtures/boxing/punch_right` |

Use these IDs in implementation, QA, and audit so cross-repo contract changes stay explicit.

---

## Tasks

### Task 1: Lock the cross-repo contract and YAML filenames

**Bead ID:** `aerobeat-input-camera-tracking-pq6`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`
**Prompt:** Define the cross-repo configuration contract for boxing/flow tracker configs and boxing/flow gesture configs. Lock the four YAML filenames/locations under `/assets/`: `boxing.camera_tracking.yaml`, `flow.camera_tracking.yaml`, `boxing.gesture_detection.yaml`, and `flow.gesture_detection.yaml`. Document schema/version headers, exact field ownership split, default values, and which repo owns parsing/validation for each config layer. Keep this slice documentation/config-contract only so later implementation slices have a stable target. Claim the bead on start and update the plan references if names or boundaries change.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `assets/`
- tracker/gesture config doc locations to be identified during implementation

**Files Created/Deleted/Modified:**
- `/.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `docs/cross-repo-config-contract.md`
- `assets/boxing.camera_tracking.yaml`
- `assets/flow.camera_tracking.yaml`
- `assets/boxing.gesture_detection.yaml`
- `assets/flow.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/docs/tracker-config-schema.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/README.md`

**Status:** ✅ Complete

**Results:** Locked the four canonical YAML asset paths under `assets/`, authored the v1 tracker/gesture ownership contract in `docs/cross-repo-config-contract.md`, and added the tracker-layer schema doc in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/docs/tracker-config-schema.md`. Resolved the remaining flow-profile ambiguity by setting `flow.camera_tracking.yaml` to `tracking.hands.enabled: false` while keeping the hand schema present for future re-enable without renaming files. This means Task 2 now likely needs to be reduced to parser/plumbing work or marked partially satisfied by Task 1.

---

### Task 2: Land the boxing/flow YAML files with approved defaults

**Bead ID:** `aerobeat-input-camera-tracking-dui`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`
**Prompt:** Create the four agreed YAML files in `aerobeat-input-camera-tracking/assets/` with the approved field names and default values. Include `tracking.pose.inference_interval_frames`, `tracking.pose.smoothing_style`, `tracking.hands.*`, and the boxing/flow gesture split where flow uses `straight_punch.enabled: false` without duplicating unused boxing thresholds. Keep this slice to authored config files plus any minimal parsing/plumbing required to load them without yet changing punch behavior. Claim the bead on start.

**Folders Created/Deleted/Modified:**
- `assets/`

**Files Created/Deleted/Modified:**
- `assets/boxing.camera_tracking.yaml`
- `assets/flow.camera_tracking.yaml`
- `assets/boxing.gesture_detection.yaml`
- `assets/flow.gesture_detection.yaml`
- `src/config/profile_config_loader.gd`
- `src/config/camera_tracking_config.gd`
- `src/AeroCameraTracking.gd`
- `src/input_provider.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.testbed/tests/unit/test_aero_camera_tracking.gd`

**Status:** ✅ Complete

**Results:** Completed within the intended narrow slice without changing punch behavior. The four canonical YAML files were authored under `assets/` with the approved v1 tracker/gesture field names and defaults, including `tracking.pose.inference_interval_frames`, `tracking.pose.smoothing_style`, the full `tracking.hands.*` subtree, and the boxing/flow gesture split where `flow.gesture_detection.yaml` sets `straight_punch.enabled: false` without duplicating boxing-only thresholds. Minimal repo-owned loading/plumbing was also landed so the input repo can resolve canonical boxing/flow profile bundle paths, parse/load the YAML documents, validate their schema/version/profile headers, and surface the selected profile bundle through `CameraTrackingConfig` and `AeroCameraTracking` without yet changing detector behavior. Implementation landed across commits `f196346` (YAML + contract docs) and `d29d43a` (profile loader/plumbing/tests). Fresh repo-local validation rerun in this task pass: `godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`; `godot --headless --path .testbed --import`; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd,res://tests/unit/test_aero_camera_tracking.gd -gexit` ✅ (`16/16` tests passed, `96` asserts).

---

### Task 3: Expose normalized hand payload fields in the MediaPipe vendor layer

**Bead ID:** `aerobeat-input-camera-tracking-280`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-02`, `REF-03`
**Prompt:** Implement the smallest vendor-layer slice needed to expose optional hand landmarks and bbox geometry/data required by the normalized payload contract. This slice should focus on hand landmark extraction, bbox derivation, bbox landmark mode support (`lite` and `full`), and any vendor-level cadence/staleness constraints that must be surfaced upward. Do not couple this slice to boxing state-machine logic yet. Claim the bead on start and document MediaPipe API limits that affect cadence, mirroring, or interpolation.

**Folders Created/Deleted/Modified:**
- vendor source folders to be identified during implementation

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/src/MediaPipePythonConfig.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/runtime/mediapipe_runtime_probe.py`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/runtime/tests/test_mediapipe_runtime_probe.py`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/.testbed/tests/test_mediapipe_python_backend.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python/README.md`

**Status:** ✅ Complete

**Results:** Verified that the owner-correct vendor slice already landed in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python` as commit `2357784` (`Expose MediaPipe hand landmarks and bbox payloads`), so this task did not require duplicating implementation in the input repo. That vendor commit adds optional raw `hands[]` samples, lite/full hand landmark subset support, derived normalized-frame bbox geometry (`x`, `y`, `width`, `height`, `area`, `coordinate_space`, `area_unit`), runtime config translation for `tracking.hands.*`, and `vendor_hand_tracking` metadata exposing cadence/staleness knobs plus MediaPipe API constraints (no stable per-hand IDs, preview-mirroring is presentation-only, tasks backend runs `HandLandmarker` in `IMAGE` mode, and missing `.task` assets surface `unavailable` instead of fake stale data). Fresh validation rerun against the vendor repo in this task pass: `python3 -m py_compile runtime/mediapipe_runtime_probe.py runtime/tests/test_mediapipe_runtime_probe.py`; `python3 -m unittest runtime.tests.test_mediapipe_runtime_probe` ✅ (`31` tests); `godot --headless --path .testbed --import --quit-after 1000` ✅; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/test_mediapipe_python_backend.gd -gexit` ✅ (`4/4` tests, `74` asserts). Attempted bead claim via `bd update aerobeat-input-camera-tracking-280 --status in_progress`, but this repo currently has no Beads database (`bd` reported `no beads database found`), so claim/closure could not be recorded there.

---

### Task 4: Normalize hand payload and tracker config handling in camera tracking tool

**Bead ID:** `aerobeat-input-camera-tracking-9kz`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-02`, `REF-03`
**Prompt:** Add the tracker-layer support in `aerobeat-tool-camera-tracking` for configurable pose inference cadence, pose smoothing style (`lite_filtered`, `lite_raw`), hand inference cadence, bbox recompute cadence, association rules, and validity/reacquire semantics. Expose a single normalized per-side hand payload including `tracking_valid`, `tracking_state`, `landmark_mode`, `frame_index`, `timestamp_seconds`, `stale_frames`, `association`, `landmarks`, and `bbox` geometry (`x`, `y`, `width`, `height`, `area`) in normalized-frame coordinates with `area_unit: normalized_frame_area`. Keep this slice focused on tracker contract and transport, not boxing gesture interpretation. Claim the bead on start.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/tests/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/tests/test_CameraTracking.gd`
- existing owner-correct implementation verified in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTrackingConfig.gd`
- existing owner-correct implementation verified in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTrackingFrame.gd`
- existing owner-correct implementation verified in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/docs/tracker-config-schema.md`
- existing owner-correct implementation verified in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/README.md`

**Status:** ✅ Complete

**Results:** Verified the approved Task 4 tracker-contract slice was already present in the owner repo from commit `e0a2cbd` (`Add normalized hand tracker payload contract`), which added the tracker-layer config normalization and per-side hand transport contract in `CameraTrackingConfig.gd` and `CameraTrackingFrame.gd`, documented it in `docs/tracker-config-schema.md`, and covered it with repo-local tests. In this task pass I added one focused regression test in `test_CameraTracking.gd` to prove `tracking.hands.association.prefer_existing_pose_side_binding` wins before `nearest_wrist_fallback` when pose wrists cross between frames, which keeps Task 4's association semantics explicitly guarded. Validation rerun for this slice: `godot --headless --path .testbed --import --quit-after 1000` ✅; targeted GUT reruns for `test_config_normalization_adds_tracker_pose_and_hand_defaults`, `test_frame_normalization_builds_per_side_hand_payload_from_vendor_samples`, `test_frame_normalization_prefers_existing_pose_side_binding_before_wrist_fallback`, and `test_frame_normalization_carries_stale_hands_until_validity_budget_expires` ✅. A broad full-file rerun still shows one unrelated pre-existing replay assertion failure in `test_registered_vendor_backend_change_surfaces_truthful_restart_into_replay_and_public_stop` (`frame_size` expected `960x540`, got `0x0`), so I kept Task 4 validation scoped to the tracker-contract tests instead of widening into later replay work. Attempted bead lookup/claim in the tool repo, but `bd` reported `no beads database found`, so bead state could not be recorded there.

---

### Task 5: Add live preview and playback bbox visualization in the tracking stack

**Bead ID:** `aerobeat-input-camera-tracking-jtf`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-02`, `REF-03`
**Prompt:** Wire the new hand payload into the live preview and recording playback paths exposed by the camera tracking stack so bbox geometry, landmark mode, and validity can be observed before boxing-specific gesture logic is layered on top. Keep this slice strictly about visualization and debug transport in the tracking stack. Claim the bead on start.

**Folders Created/Deleted/Modified:**
- preview/playback visualization folders to be identified during implementation

**Files Created/Deleted/Modified:**
- live preview / playback visualization files

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Replace boxing straight-punch detection with bbox-growth state machine

**Bead ID:** `aerobeat-input-camera-tracking-9go`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`
**Prompt:** Remove the current nonfunctional straight-punch detection path in `aerobeat-input-camera-tracking` and replace it with the agreed four-state machine (`ready`, `triggered`, `not_ready`, `tracking_lost`) driven by wrist velocity and bbox area growth over a configurable short sample window. Use gesture defaults of evaluating only on fresh hand samples, a 4-sample growth window, and a required minimum count of positive growth samples. Store trigger bbox area on `ready -> triggered`, emit state-change events so subscribers can react to left/right punch state changes, hold `triggered` for the configured grace period, rearm only when bbox area retracts below the stored trigger size, and reset into `tracking_lost` when hand tracking becomes invalid. If tracking is lost during `triggered`, enter `tracking_lost`, cancel and reset the grace timer, and clear the stored trigger bbox area. Claim the bead on start and keep left/right ownership tied to the existing pose-tracking association with nearest-wrist fallback when necessary.

**Folders Created/Deleted/Modified:**
- boxing gesture detection source folders to be identified during implementation

**Files Created/Deleted/Modified:**
- boxing gesture detection/runtime files in `aerobeat-input-camera-tracking`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 7: Expose config-driven tuning and state visualization in the boxing proving scene

**Bead ID:** `aerobeat-input-camera-tracking-0ab`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Update the `/.testbed/` boxing proving scene so it can load a selected boxing/flow YAML config path, surface the relevant tracker and gesture tuning values for iteration, and visualize hand bbox state with the agreed color mapping (`ready` yellow, `triggered` green, `not_ready` red, `tracking_lost` dark red). Also expose the key debug values needed for tuning: wrist velocity, bbox area, bbox area growth, tracking validity, current state, grace/reacquire timers where useful, pose smoothing style, pose inference cadence, hand inference cadence, and bbox recompute cadence. Claim the bead on start and document any UI constraints.

**Folders Created/Deleted/Modified:**
- `/.testbed/`
- boxing proving-scene UI folders to be identified during implementation

**Files Created/Deleted/Modified:**
- boxing proving-scene files in `aerobeat-input-camera-tracking/.testbed/`
- boxing/flow YAML path/config loader files

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 8: Update the left/right straight-punch inspector panels in the boxing proving scene

**Bead ID:** `aerobeat-input-camera-tracking-cxj`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Update the existing boxing proving-scene gesture inspector behavior so clicking the left or right straight-punch gesture icons opens a panel that reflects the new detection method instead of the old one. The panel should show the live values and state inputs that now determine left/right straight-punch status, including at minimum current state, wrist velocity, bbox area, bbox area growth, fresh-sample validity, grace timer state, and any stored trigger bbox value or rearm-relevant data needed to understand why the gesture is or is not active. Claim the bead on start and keep the inspector wiring aligned with the new state-change event model.

**Folders Created/Deleted/Modified:**
- `/.testbed/`
- boxing proving-scene gesture inspector UI folders to be identified during implementation

**Files Created/Deleted/Modified:**
- left/right straight-punch inspector panel files in `aerobeat-input-camera-tracking/.testbed/`
- related proving-scene gesture inspector wiring files

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 9: QA the tracker contract in isolation before boxing validation

**Bead ID:** `aerobeat-input-camera-tracking-web`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Verify the tracker contract before boxing gameplay validation. Confirm the normalized hand payload is present and stable, preview/playback visualization works, mirrored camera behavior keeps hand and pose aligned, lite vs full landmark mode both produce sane bbox outputs, flow can disable unnecessary hand work cleanly, and the tracker contract remains consumable by `aerobeat-tool-camera-gesture-control` without breaking unchanged consumer behavior. Use the proving-harness fixture videos in `REF-05` and `REF-06` where useful to validate deterministic playback behavior before moving to boxing gesture validation. Capture any cadence, staleness, interpolation, or association regressions. Claim the bead on start and leave clear repro steps in the bead/plan results.

**Folders Created/Deleted/Modified:**
- validation artifacts / notes locations to be identified during QA

**Files Created/Deleted/Modified:**
- plan results section
- repo-local validation notes or artifacts generated during QA

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 10: QA boxing straight-punch behavior end to end

**Bead ID:** `aerobeat-input-camera-tracking-35y`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-06`
**Prompt:** Verify boxing straight-punch behavior end to end. Use the proving-harness straight left and straight right punch fixture folders plus their human-verified gold-truth timing YAMLs from `REF-05` and `REF-06` as the primary deterministic validation path. Confirm left/right straights trigger via wrist velocity + bbox growth, compare detected trigger windows against the expected gold-truth timing windows, confirm trigger, grace hold, rearm, loss, and reacquire behavior, and confirm the proving scene loads YAML presets correctly, reflects state/event changes, and that the clickable left/right straight-punch inspector panels show the new live decision inputs correctly. Capture clear repro steps, threshold observations, any mismatches versus gold truth, and any remaining tuning gaps. Claim the bead on start and leave clear repro steps in the bead/plan results.

**Folders Created/Deleted/Modified:**
- validation artifacts / notes locations to be identified during QA

**Files Created/Deleted/Modified:**
- plan results section
- repo-local validation notes or artifacts generated during QA

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 11: Independently audit cross-repo contract, behavior, and final readiness

**Bead ID:** `aerobeat-input-camera-tracking-ej7`
**SubAgent:** `primary`
**Role:** `auditor`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Perform an independent audit of the landed changes across the input, tool, and vendor repos. Confirm the implementation matches the approved state-machine behavior, the config ownership split is correct, the four YAML files exist in the owning repo, the tracker schema is documented in the tool repo, tracker QA passed before boxing QA, the proving-scene/debug behavior matches the agreed design, and the boxing QA used the `REF-05` and `REF-06` fixture folders plus gold-truth timing YAMLs as intended. Close only the beads that are fully done; if anything is missing or ambiguous, report the gap and keep the work open.

**Folders Created/Deleted/Modified:**
- plan + audit evidence locations to be identified during audit

**Files Created/Deleted/Modified:**
- final plan results
- audit notes/artifacts if generated

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ In Progress

**What We Built:** Execution started. Beads created, dependency order linked, and implementation is beginning from the contract/YAML slices.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Drafted on 2026-06-03*