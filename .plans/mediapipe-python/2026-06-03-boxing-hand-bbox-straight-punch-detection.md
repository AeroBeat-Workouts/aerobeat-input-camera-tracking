# AeroBeat Boxing Hand BBox Straight Punch Detection

**Date:** 2026-06-03
**Status:** In Progress
**Last Updated:** 2026-06-04 10:15 EDT
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

### Task 0: Audit and repair the repo-local Beads setup before continuing QA

**Bead ID:** `aerobeat-input-camera-tracking-7gy`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Audit why this repo repeatedly reports `bd` / Beads as unavailable or uninitialized (`no beads database found`), repair the repo-local Beads setup in the owner-correct way for this repository, and verify that the existing plan bead IDs can now be claimed/updated normally. Keep the slice narrow: diagnose the current Beads context, initialize or restore the repo-local Beads database if missing, avoid broad workflow changes outside this repo unless required, and document the exact commands, resulting storage mode, and any follow-up caveats. Claim the repair bead on start once the Beads database exists, then update this plan with the truthful result.

**Folders Created/Deleted/Modified:**
- `.beads/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- repo-local Beads metadata/files as required by the repair
- `/.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** Audited the owner repo Beads context and confirmed the repo-local database is healthy at `/.beads/embeddeddolt`; `bd where --json` and `bd context --json` now resolve correctly inside `REF-01` with backend `dolt`, mode `embedded`, and no redirect/worktree confusion. Root cause for the earlier `no beads database found` reports was not a missing Beads setup in this owner repo; it was cross-repo task execution being attempted from dependency repos (`REF-02` / `REF-03` / related consumers) that do not own this plan's bead state, plus multiple later QA retry beads being left `in_progress` in parallel. The smallest truthful repair was to keep this owner repo as the single source of truth and normalize the duplicate retry state rather than initializing new Beads DBs elsewhere.

Exact repair performed in the owner repo:
- claimed `aerobeat-input-camera-tracking-7gy` with `bd update aerobeat-input-camera-tracking-7gy --status in_progress --json`
- verified owner routing with `bd where --json` and `bd context --json`
- confirmed canonical Slice A bead `aerobeat-input-camera-tracking-web` is the intended tracker-contract QA bead and that it is blocked only by this Task 0 repair bead plus already-closed implementation beads
- closed stale/superseded retry beads with explicit reasons so QA state is no longer split across contradictory `in_progress` tasks:
  - `aerobeat-input-camera-tracking-1ow`
  - `aerobeat-input-camera-tracking-aby`
  - `aerobeat-input-camera-tracking-4jf`
  - `aerobeat-input-camera-tracking-gu5`
  - `aerobeat-input-camera-tracking-cpp`

Post-repair Beads state is coherent: only `aerobeat-input-camera-tracking-web` and this repair bead remained `in_progress` during the audit, which makes `aerobeat-input-camera-tracking-web` the clean canonical next Slice A bead once this task closes. Caveat: `bd dep tree` still emits a Dolt auto-push warning (`push to origin/main: ... no common ancestor`), but the local embedded Dolt Beads database is readable/writable and the routing repair itself is complete.

---

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
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/tests/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTracking.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/tests/test_CameraTracking.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/README.md`

**Status:** ✅ Complete

**Results:** Verified the main preview/playback visualization slice was already present in the owner repo from commit `edd416a` (`Add hand bbox preview and playback debug overlays`), which wires normalized per-side hand bbox + landmark overlays into the preview presenter for both live-camera and replay/video-file sessions and exposes presenter-side debug snapshots including bbox preview rects and playback status. In this task pass I added one narrow public-service transport follow-up so non-presenter consumers can inspect the same hand debug payload through `CameraTracking.get_hand_debug_snapshot()`, then covered it with a focused regression test while keeping scope strictly in tracker visualization/debug transport. Validation rerun for this slice: `godot --headless --path .testbed --import --quit-after 1000` ✅; targeted GUT reruns for `test_camera_tracking_exposes_backend_playback_status_through_public_contract`, `test_camera_tracking_exposes_hand_debug_snapshot_through_public_contract`, `test_preview_presenter_exposes_hand_debug_snapshot_and_bbox_preview_rects`, and `test_preview_presenter_exposes_playback_status_alongside_hand_debug_snapshot` ✅. Bead claim was attempted in the tool repo, but `bd` reported `no beads database found`, so the repo could not record the claim/closure state.

---

### Task 6: Replace boxing straight-punch detection with bbox-growth state machine

**Bead ID:** `aerobeat-input-camera-tracking-9go`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`
**Prompt:** Remove the current nonfunctional straight-punch detection path in `aerobeat-input-camera-tracking` and replace it with the agreed four-state machine (`ready`, `triggered`, `not_ready`, `tracking_lost`) driven by wrist velocity and bbox area growth over a configurable short sample window. Use gesture defaults of evaluating only on fresh hand samples, a 4-sample growth window, and a required minimum count of positive growth samples. Store trigger bbox area on `ready -> triggered`, emit state-change events so subscribers can react to left/right punch state changes, hold `triggered` for the configured grace period, rearm only when bbox area retracts below the stored trigger size, and reset into `tracking_lost` when hand tracking becomes invalid. If tracking is lost during `triggered`, enter `tracking_lost`, cancel and reset the grace timer, and clear the stored trigger bbox area. Claim the bead on start and keep left/right ownership tied to the existing pose-tracking association with nearest-wrist fallback when necessary.

**Folders Created/Deleted/Modified:**
- `src/detectors/`
- `src/providers/`
- `.testbed/tests/unit/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `src/detectors/pose_detector_substrate.gd`
- `src/providers/camera_tracking_provider.gd`
- `src/AeroCameraTracking.gd`
- `src/input_provider.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.testbed/tests/unit/test_camera_tracking_provider.gd`
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** The agreed straight-punch slice was already landed in commit `29667f4` (`Implement bbox-growth straight punch state machine`), so this task pass verified and documented that implementation instead of redoing it. That commit removes the old nonfunctional straight-punch path and replaces it with the four-state `ready -> triggered -> not_ready -> ready` / `tracking_lost` machine in `pose_detector_substrate.gd`, driven by per-side tracker-associated hand payloads from `REF-02`, forward wrist velocity, and bbox area growth over the repo-owned gesture config defaults (`fresh_samples_only: true`, `sample_window_size: 4`, `min_positive_growth_samples: 3`). The implementation stores `trigger_bbox_area` on `ready -> triggered`, emits `straight_punch_state_changed` events with state-transition details, holds `triggered` for the configured grace frames, rearms only after bbox area retracts below the stored trigger size minus epsilon, and resets into `tracking_lost` with cleared grace/trigger state when hand tracking becomes invalid during any phase including `triggered`. Signal plumbing was also added so `camera_tracking_provider.gd`, `AeroCameraTracking.gd`, and `input_provider.gd` re-emit the new left/right straight-punch state-change events for subscribers. Fresh repo-local validation rerun in this task pass: `godot --headless --path .testbed --import --quit-after 1000`; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_camera_tracking_provider.gd,res://tests/unit/test_aero_camera_tracking.gd -gexit` ✅ (`37/37` tests passed, `268` asserts). Attempted bead claim via `bd update aerobeat-input-camera-tracking-9go --status in_progress --json`, but this repo currently has no Beads database (`bd` reported `no beads database found`), so claim/closure could not be recorded there.

---

### Task 7: Expose config-driven tuning and state visualization in the boxing proving scene

**Bead ID:** `aerobeat-input-camera-tracking-0ab`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Update the `/.testbed/` boxing proving scene so it can load a selected boxing/flow YAML config path, surface the relevant tracker and gesture tuning values for iteration, and visualize hand bbox state with the agreed color mapping (`ready` yellow, `triggered` green, `not_ready` red, `tracking_lost` dark red). Also expose the key debug values needed for tuning: wrist velocity, bbox area, bbox area growth, tracking validity, current state, grace/reacquire timers where useful, pose smoothing style, pose inference cadence, hand inference cadence, and bbox recompute cadence. Claim the bead on start and document any UI constraints.

**Folders Created/Deleted/Modified:**
- `/.testbed/`
- `/.testbed/scenes/`
- `/.testbed/scripts/`
- `/.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scripts/hand_bbox_state_drawer.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** Verified that this proving-scene tuning/visualization slice was already landed in commit `6832201` (`Add boxing proving bbox tuning surfaces`), then updated this plan entry to reflect the actual implementation and fresh validation. The boxing proving scene now switches between the repo-owned boxing/flow profile bundles, shows the resolved tracker/gesture YAML paths, surfaces tracker tuning (`pose smoothing`, `pose cadence`, `hand cadence`, `bbox recompute cadence`, hand validity budgets) plus straight-punch tuning (`fresh samples only`, sample window, positive-growth count, wrist velocity threshold, bbox growth threshold, grace frames, retract epsilon, reacquire frames), and prints per-hand live debug lines with wrist velocity, bbox area, bbox area growth, tracking validity/state, grace countdown, reacquire progress, and stale-frame counts. Hand bbox overlays are drawn through `.testbed/scripts/hand_bbox_state_drawer.gd` with the agreed state colors: `ready` yellow, `triggered` green, `not_ready` red, and `tracking_lost` dark red. UI constraint: the scene intentionally selects the canonical boxing/flow profile bundle via the profile picker and displays the resolved YAML resource paths; it does not provide an arbitrary filesystem browser for ad-hoc YAML files. Fresh repo-local validation rerun in this task pass: `godot --headless --path .testbed --import --quit-after 1000`; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_camera_tracking_config_profiles.gd,res://tests/unit/test_aero_camera_tracking.gd -gexit` ✅ (`20/20` tests passed, `130` asserts). Attempted bead claim via `bd update aerobeat-input-camera-tracking-0ab --status in_progress --json`, but this repo currently has no Beads database (`bd` reported `no beads database found`), so claim/closure could not be recorded there.

---

### Task 8: Update the left/right straight-punch inspector panels in the boxing proving scene

**Bead ID:** `aerobeat-input-camera-tracking-cxj`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Update the existing boxing proving-scene gesture inspector behavior so clicking the left or right straight-punch gesture icons opens a panel that reflects the new detection method instead of the old one. The panel should show the live values and state inputs that now determine left/right straight-punch status, including at minimum current state, wrist velocity, bbox area, bbox area growth, fresh-sample validity, grace timer state, and any stored trigger bbox value or rearm-relevant data needed to understand why the gesture is or is not active. Claim the bead on start and keep the inspector wiring aligned with the new state-change event model.

**Folders Created/Deleted/Modified:**
- `/.testbed/scripts/`
- `/.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `/.testbed/scripts/boxing_proving_harness.gd`
- `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

**Status:** ✅ Complete

**Results:** Updated the boxing proving-scene straight-punch inspector slice in `.testbed/scripts/boxing_proving_harness.gd` so the left/right punch tiles now keep their shared inspector and hover-card data wired to the new `straight_punch_state_changed` provider signal instead of relying only on the old polling path. The inspector/hover model now includes the latest state-change summary plus an event-payload snapshot alongside the live state-machine inputs already sourced from `gesture_debug.straight_punch`, so clicking either straight-punch icon shows current state, tracking/fresh-sample validity, wrist velocity, bbox area, bbox growth, positive-growth history, grace timer, stored trigger bbox, rearm status, and reacquire progress with immediate refresh when the state-machine transitions. Added focused unit coverage in `/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` to prove both the richer inspector body and the fallback merge from cached state-change signal payloads. Repo-local validation for this slice: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` ✅ (`5/5` passed, `40` asserts). Attempted bead claim with `bd update aerobeat-input-camera-tracking-cxj --status in_progress --json`, but this repo still has no Beads database configured (`bd` returned `no beads database found`), so no Beads claim was recorded.

---

### Task 9: QA the tracker contract in isolation before boxing validation

**Bead ID:** `aerobeat-input-camera-tracking-web`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Verify the tracker contract before boxing gameplay validation. Confirm the normalized hand payload is present and stable, preview/playback visualization works, mirrored camera behavior keeps hand and pose aligned, lite vs full landmark mode both produce sane bbox outputs, flow can disable unnecessary hand work cleanly, and the tracker contract remains consumable by `aerobeat-tool-camera-gesture-control` without breaking unchanged consumer behavior. Use the proving-harness fixture videos in `REF-05` and `REF-06` where useful to validate deterministic playback behavior before moving to boxing gesture validation. Capture any cadence, staleness, interpolation, or association regressions. Claim the bead on start and leave clear repro steps in the bead/plan results.

**Folders Created/Deleted/Modified:**
- `.testbed/test-results/task9-qa-captures/2026-06-04-062207/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/test-results/task9-qa-captures/2026-06-04-062207/left/godot.log`
- `.testbed/test-results/task9-qa-captures/2026-06-04-062207/left/report.json`
- `.testbed/test-results/task9-qa-captures/2026-06-04-062207/left/report.md`
- `.testbed/test-results/task9-qa-captures/2026-06-04-062207/right/godot.log`
- `.testbed/test-results/task9-qa-captures/2026-06-04-062207/right/report.json`
- `.testbed/test-results/task9-qa-captures/2026-06-04-062207/right/report.md`

**Status:** ✅ Complete

**Results:** Re-claimed the bead with `bd update aerobeat-input-camera-tracking-web --status in_progress --json` and then QA’d the tracker contract across the owner repo plus its tool/vendor consumers. Repo-local contract coverage passed with `cd /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking && cd .testbed && godotenv addons install && cd .. && godot --headless --path .testbed --import && godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd,res://tests/unit/test_tracking_frame_adapter.gd,res://tests/unit/test_proving_harness_trails.gd,res://tests/unit/test_aero_camera_tracking.gd -gexit` ✅ (`58/58` passed, `296` asserts). This covered normalized hand payload consumption, mirrored `preview_transform.flip_horizontal` handling, replay/playback proving harness behavior, and the flow-profile startup path. Tool-level tracker contract coverage passed with `cd /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking && cd .testbed && godotenv addons install && cd .. && godot --headless --path .testbed --import && godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/test_CameraTracking.gd -gexit` ✅ (`28/28` passed, `272` asserts), including hand-frame normalization, stale-hand carry/reacquire behavior, preview-surface attach/detach, preview presenter bbox mapping, and playback status exposure. Consumer compatibility stayed intact with `cd /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-gesture-control && cd .testbed && godotenv addons install && cd .. && godot --headless --path .testbed --import && godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/test_camera_gesture_controller.gd,res://tests/test_camera_gesture_session_reuse.gd -gexit` ✅ (`13/13` passed, `62` asserts), which confirms unchanged `aerobeat-tool-camera-gesture-control` camera-tracking boundary behavior. Vendor lite/full bbox coverage passed with `cd /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-mediapipe-python && python3 -m unittest runtime.tests.test_mediapipe_runtime_probe` ✅ (`32` tests), including `test_tasks_hand_path_emits_lite_bbox_payload_when_model_is_available` and `test_fixture_hands_are_normalized_with_full_landmark_mode`. Deterministic proving-harness playback also passed against the local copies of `REF-05` and `REF-06` using `AEROBEAT_CAMERA_TRACKING_SOURCE="$PWD/.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4" godot --headless --path .testbed --script res://scripts/capture_fixture_proving.gd -- res://scenes/boxing_proving.tscn "$PWD/.testbed/assets/fixtures/boxing/punch_left" "$PWD/.testbed/test-results/task9-qa-captures/2026-06-04-062207/left" 7000` and the matching right-side command for `punch_right`; both captures reported `camera_streaming=true` and `camera_has_texture=true`. The left capture yielded `958` timeline states / `6` events and the right capture yielded `946` timeline states / `9` events. Latest straight-punch debug snapshots showed sane normalized bbox output in lite mode with no stale-frame regression at capture end: left fixture `left state=tracked valid=true stale=0 assoc_method=prefer_existing_pose_side_binding source_label=right bbox_area=0.003728`, right fixture `left state=tracked valid=true stale=0 ... source_label=left bbox_area=0.003892` and `right state=tracked valid=true stale=0 ... source_label=right bbox_area=0.004153`. That association evidence, together with the mirrored preview-transform tests, indicates mirrored camera presentation still keeps hand/pose alignment consumable upstream even when MediaPipe’s raw handedness labels stay camera-native. No cadence, staleness, interpolation, or association regressions were reproduced in Task 9 scope; the only non-blocking noise observed was pre-existing Godot UID/object-leak warnings during the gesture-control suite, but the assertions and contract behavior still passed truthfully. Flow-mode hand disable remains correctly owned by `assets/flow.camera_tracking.yaml` (`tracking.hands.enabled: false`) and the flow startup tests passed, so unnecessary hand work can still be disabled cleanly before boxing validation.

---

### Task 10: QA boxing straight-punch behavior end to end

**Bead ID:** `aerobeat-input-camera-tracking-35y`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-06`
**Prompt:** Verify boxing straight-punch behavior end to end. Use the proving-harness straight left and straight right punch fixture folders plus their human-verified gold-truth timing YAMLs from `REF-05` and `REF-06` as the primary deterministic validation path. Confirm left/right straights trigger via wrist velocity + bbox growth, compare detected trigger windows against the expected gold-truth timing windows, confirm trigger, grace hold, rearm, loss, and reacquire behavior, and confirm the proving scene loads YAML presets correctly, reflects state/event changes, and that the clickable left/right straight-punch inspector panels show the new live decision inputs correctly. Capture clear repro steps, threshold observations, any mismatches versus gold truth, and any remaining tuning gaps. Claim the bead on start and leave clear repro steps in the bead/plan results.

**Folders Created/Deleted/Modified:**
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/left/report.json`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/left/report.md`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/right/report.json`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/right/report.md`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/left/inspector_probe.json`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/right/inspector_probe.json`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/left/straight_punch_trace.json`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/right/straight_punch_trace.json`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/task10_inspector_probe.gd`
- `.testbed/test-results/task10-qa-captures/2026-06-04-063854/task10_straight_punch_trace.gd`

**Status:** ❌ Failed

**Results:** Re-claimed the owner-repo bead with `bd update aerobeat-input-camera-tracking-35y --status in_progress --json` and then ran deterministic boxing QA against the local copies of `REF-05` and `REF-06`. Exact repro commands used:

1. `cd /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking && cd .testbed && godotenv addons install && cd ..`
2. `AEROBEAT_CAMERA_TRACKING_SOURCE="$PWD/.testbed/assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4" godot --headless --path .testbed --script res://scripts/capture_fixture_proving.gd -- res://scenes/boxing_proving.tscn "$PWD/.testbed/assets/fixtures/boxing/punch_left" "$PWD/.testbed/test-results/task10-qa-captures/2026-06-04-063854/left" 7000`
3. `AEROBEAT_CAMERA_TRACKING_SOURCE="$PWD/.testbed/assets/fixtures/boxing/punch_right/boxing_guard->punch_right_repeat_04_take_01.mp4" godot --headless --path .testbed --script res://scripts/capture_fixture_proving.gd -- res://scenes/boxing_proving.tscn "$PWD/.testbed/assets/fixtures/boxing/punch_right" "$PWD/.testbed/test-results/task10-qa-captures/2026-06-04-063854/right" 7000`
4. `AEROBEAT_CAMERA_TRACKING_SOURCE=.../punch_left/...mp4 godot --headless --path .testbed --script .testbed/test-results/task10-qa-captures/2026-06-04-063854/task10_inspector_probe.gd -- res://scenes/boxing_proving.tscn "$PWD/.testbed/assets/fixtures/boxing/punch_left" "$PWD/.testbed/test-results/task10-qa-captures/2026-06-04-063854/left/inspector_probe.json" 7000`
5. `AEROBEAT_CAMERA_TRACKING_SOURCE=.../punch_right/...mp4 godot --headless --path .testbed --script .testbed/test-results/task10-qa-captures/2026-06-04-063854/task10_inspector_probe.gd -- res://scenes/boxing_proving.tscn "$PWD/.testbed/assets/fixtures/boxing/punch_right" "$PWD/.testbed/test-results/task10-qa-captures/2026-06-04-063854/right/inspector_probe.json" 7000`
6. `AEROBEAT_CAMERA_TRACKING_SOURCE=.../punch_left/...mp4 godot --headless --path .testbed --script .testbed/test-results/task10-qa-captures/2026-06-04-063854/task10_straight_punch_trace.gd -- res://scenes/boxing_proving.tscn "$PWD/.testbed/assets/fixtures/boxing/punch_left" "$PWD/.testbed/test-results/task10-qa-captures/2026-06-04-063854/left/straight_punch_trace.json" 7000`
7. `AEROBEAT_CAMERA_TRACKING_SOURCE=.../punch_right/...mp4 godot --headless --path .testbed --script .testbed/test-results/task10-qa-captures/2026-06-04-063854/task10_straight_punch_trace.gd -- res://scenes/boxing_proving.tscn "$PWD/.testbed/assets/fixtures/boxing/punch_right" "$PWD/.testbed/test-results/task10-qa-captures/2026-06-04-063854/right/straight_punch_trace.json" 7000`

Truthful outcome: the proving scene did load the expected boxing presets (`Tracker YAML: res://assets/boxing.camera_tracking.yaml`, `Gesture YAML: res://assets/boxing.gesture_detection.yaml`) and the clickable straight-punch inspector model is wired to the new live decision inputs as intended. The inspector probe files show both left/right panels exposing current state, hand tracking validity, fresh-sample validity, latest state-change summary, event payload snapshot, wrist velocity, bbox area, bbox growth, positive-growth sample count, growth window bbox areas, grace timer, stored trigger bbox area, rearm status, and reacquire progress. However, the end-to-end punch behavior itself failed against gold truth.

Deterministic fixture findings vs gold truth:
- Left fixture (`REF-05`): expected `4` left-punch trigger windows, observed `0`; false negatives `4/4`; false positives `0`. `report.json` / `straight_punch_trace.json` never recorded `left.state=triggered` or `left.state=not_ready`; sampled state stayed `ready` for the entire target side after tracker startup.
- Right fixture (`REF-06`): expected `4` right-punch trigger windows, observed `0`; false negatives `4/4`; false positives `0`. `report.json` / `straight_punch_trace.json` never recorded `right.state=triggered` or `right.state=not_ready`; sampled target-side state alternated between `ready` and brief `tracking_lost` pulses but never triggered.
- Combined hit/miss count: `0/8` expected straight-punch windows hit, `8/8` missed, `0` spurious straight-punch activations on the opposite side.

Timing / threshold observations:
- Tracker startup itself misses the first gold windows in both fixtures. The fixture capture report shows `provider_started` at `1425ms` for `punch_left` and `1347ms` for `punch_right`, while the first gold punch windows are `1150-1300ms` (left) and `400-600ms` (right). Those first punches are therefore unobservable in this headless proving pass even before considering detector thresholds.
- Later gold windows still miss completely. In the left trace, the best in-window samples reached wrist velocity but not the area-growth count gate: window 2 best sample at fixture `2515ms` had `wrist_velocity=8.756`, `bbox_area_growth=0.000220`, `positive_growth_samples=1`; window 3 best at `3658ms` had `wrist_velocity=3.847`, `bbox_area_growth=0.000160`, `positive_growth_samples=1`; window 4 best at `4907ms` had `wrist_velocity=0.153`, `bbox_area_growth=0.000606`, `positive_growth_samples=1`.
- The left trace did hit both scalar thresholds simultaneously once overall (`4534ms`: `wrist_velocity=1.076`, `bbox_area_growth=0.006265`), but it still only accumulated `positive_growth_samples=1`, so the detector remained `ready` and never crossed into `triggered`.
- In the right trace, no sample satisfied both scalar thresholds at once. Best gold-window samples stayed far below the configured area-growth/count gates (for example window 4 best at `4883ms`: `wrist_velocity=0.529`, `bbox_area_growth=-0.000323`, `positive_growth_samples=0`).

Grace / rearm / loss / reacquire observations:
- `triggered` grace hold and `not_ready -> ready` rearm could not be validated truthfully because neither fixture ever entered `triggered`.
- Loss/reacquire behavior did occur on the non-dominant or unstable hand paths. Example transitions captured in the traces: left-fixture right hand `ready -> tracking_lost -> ready` at approximately `2429ms -> 2484ms`, `4030ms -> 4142ms`, `4175ms -> 4290ms`, and `4534ms -> 4605ms`; right-fixture target hand `tracking_lost -> ready` at startup (`1455ms -> 1497ms`) plus repeated `ready -> tracking_lost -> ready` pulses around `2633-2680ms`, `2725-2836ms`, `2882-2929ms`, and `4423-4628ms`.
- Those reacquire transitions demonstrate the `tracking_lost -> ready` path is alive, but because no trigger ever happened they do not prove the required triggered-loss reset behavior from `REF-01`.

Proving-scene / artifact notes:
- `report.md` quick-stats sections confirm the boxing preset bundle and the expected straight-punch tuning values were loaded (`fresh samples only=true`, `sample window size=4`, `positive growth samples=2`, `min wrist velocity=0.180`, `min bbox area growth=0.006`, `triggered grace frames=3`, `bbox retract epsilon=0.003`, `lost reacquire stable frames=2`).
- Headless report generation still captured `camera_streaming=true` and `camera_has_texture=true`, but Godot dummy rendering could not save `proving.png` in this environment (`failed to capture screenshot image ... texture_2d_get null`). One right-trace pass also logged a transient preview-frame image load error under Godot app userdata. Those were non-fatal artifact issues, not the cause of the punch misses.

Result: Task 10 is a real QA failure and should not advance to audit yet. The blocking gap is that end-to-end straight-punch detection does not match the gold-truth fixture windows at all, so the bead must remain open for tuning/fix work before Task 11 can be started.

---

### Task 10A: Repair boxing proving skeleton-node inspector collider alignment

**Bead ID:** `aerobeat-input-camera-tracking-zym`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Repair the boxing proving-scene inspector hitboxes/colliders for the clickable MediaPipe skeleton nodes so the invisible click targets line up with the visible tracked nodes/skeleton. Derrick observed that the collider layer appears vertically flipped relative to the rendered skeleton, which makes in-scene node inspection misleading during punch debugging. Audit the scene/script path that creates or positions those click targets, identify whether the Y-axis is mirrored/flipped or otherwise transformed inconsistently with the visible tracker overlay, implement the smallest truthful fix, and verify in the testbed that clicking the visible nodes now opens the expected inspector details. Claim the bead on start and close it only if the alignment is actually corrected.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/scripts/landmark_drawer.gd`
- `.testbed/tests/unit/test_landmark_drawer.gd`

**Status:** ✅ Complete

**Results:** Root cause was a coordinate-space mismatch in the proving-scene landmark click layer: `.testbed/scripts/landmark_drawer.gd` still treated normalized landmark `y` as bottom-left gameplay space and flipped it with `1.0 - y`, while the visible skeleton/MediaPipe overlay rendered by the tool-owned preview presenter already uses MediaPipe's native top-left normalized preview space (`y` grows downward). That left the invisible landmark hit targets vertically mirrored relative to the visible nodes/skeleton and made node inspection misleading.

Smallest truthful fix landed in the owner repo:
- `.testbed/scripts/landmark_drawer.gd` — removed the incorrect fallback Y inversion so hit targets now map `y` directly into preview screen space, matching the presenter/rendered overlay contract.
- `.testbed/tests/unit/test_landmark_drawer.gd` — updated the mapping expectation to top-left normalized preview space and added a focused regression proving clicks resolve through the presenter mapping when available.

Exact validation used:
- `godot --headless --path .testbed --import --quit-after 1000`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_landmark_drawer.gd,res://tests/unit/test_proving_harness_trails.gd -gexit`
- Result: ✅ `36/36` tests passed, `150` asserts.

This validation covered both the repaired landmark click mapping and the proving-harness presenter reparent/binding path that routes overlay drawers through the tool-owned preview presenter. No punch-detector tuning was attempted in this slice. With the collider/click-target coordinate mismatch removed, Task 10 blocker `aerobeat-input-camera-tracking-35y` is now one step cleaner to resume because visible skeleton-node inspection in the boxing proving scene should no longer be vertically misleading.

---

### Task 10B: Expose landmark inspector colliders in the boxing proving scene and clean warning noise

**Bead ID:** `aerobeat-input-camera-tracking-pye`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Derrick still cannot trust the in-scene landmark click mapping visually, and the proving-scene/dev scripts are emitting warning noise during debugging. Make the landmark inspector colliders/hit targets visibly renderable in the boxing proving scene so Derrick can see where the click targets actually are while debugging, and clean up the currently observed warning noise in the same scene/script path where doing so is straightforward. The observed warnings include unused parameter/name-style issues and a Control variable-shadowing warning visible in the provided screenshot. Keep this slice focused on debug visibility plus low-risk warning cleanup; do not widen into punch-detector tuning. Claim the bead on start and close it only if the collider visualization is usable and the targeted warning noise is addressed.

**Folders Created/Deleted/Modified:**
- `.testbed/scenes/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scripts/hand_bbox_state_drawer.gd`
- `.testbed/scripts/landmark_drawer.gd`
- `.testbed/scripts/proof_skeleton_overlay.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_landmark_drawer.gd`

**Status:** ✅ Complete

**Results:** Root cause was that the proving-scene landmark inspection layer still had invisible click targets even after Task 10A fixed their Y mapping, so Derrick still had no direct in-scene proof that the hit circles and visible landmark overlay matched. I kept this slice narrow by making the same `LandmarkDrawer` overlay able to render its click radii directly in the boxing proving scene, then cleaning the exact warning noise called out in the screenshot without changing punch-detector behavior.

What landed:
- `.testbed/scripts/landmark_drawer.gd` — added a debug hit-target rendering mode for the existing inspector collider layer. The drawer can now surface each clickable landmark target as a translucent cyan circle with a bright center dot and optional `#id` label, while still using the exact same presenter/fallback coordinate mapping as click detection. I also factored the mapped collider state into `get_hit_target_snapshot()` so the visual debug path and click path share one source of truth.
- `.testbed/scenes/boxing_proving.tscn` — enabled `show_debug_hit_targets=true` and `show_debug_hit_target_labels=true` on the boxing proving scene’s `LandmarkDrawer`, so Derrick should now see the collider rings directly over the camera preview in that scene without needing extra toggles.
- `.testbed/tests/unit/test_landmark_drawer.gd` — expanded focused coverage to assert the debug hit-target snapshot centers/radius in plain normalized space and when routed through the preview presenter mapping.

Warning cleanup completed in-scope:
- `.testbed/scripts/proving_harness.gd` — renamed `_stop_everything(reason)` to `_stop_everything(_reason)` to truthfully mark the parameter unused.
- `.testbed/scripts/boxing_proving_harness.gd` — renamed `_build_punch_requirement_row(..., side)` to `_build_punch_requirement_row(..., _side)` to clear the unused-parameter warning without widening the helper.
- `.testbed/scripts/proof_skeleton_overlay.gd` — renamed the local `position` variable to `screen_position` so it no longer shadows `Control.position`.
- `.testbed/scripts/hand_bbox_state_drawer.gd` — typed the loop as `for side: String in ["left", "right"]:` to remove the static-type warning on the iterator.

Exact validation used:
- `cd /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking && cd .testbed && godotenv addons install && cd ..`
- `godot --headless --path .testbed --import`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_landmark_drawer.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_proving_harness_trails.gd -gexit` ✅ (`43/43` passed, `198` asserts)
- `godot --headless --path .testbed --script res://scripts/proof_skeleton_overlay.gd` ✅ (scene booted in boxing proving mode and wrote `.artifacts/skeleton-proof/report.json` with mapped screen-landmark positions through the real proving-scene presenter path)

Validation note: Godot still emitted the pre-existing dummy-renderer leak/object cleanup warnings on test exit, and the proof script still only writes the JSON landmark-position report rather than PNGs in this environment, so I did not overclaim a rendered screenshot artifact. The collider visualization itself is enabled in the actual boxing proving scene file and shares the same click-mapping function covered by the focused drawer tests, which is the truthful usability threshold for this slice.

---

### Task 10C0: Investigate the hand side re-association hypothesis against the real code path

**Bead ID:** `aerobeat-input-camera-tracking-qtp`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Before attempting a repair, investigate Derrick's current hand-side swap hypothesis against the real code path. Audit the owner repo, tool-layer normalized hand payload path, and any relevant vendor behavior to determine whether the observed left/right swap after occlusion is actually caused by the current nearest-wrist fallback / re-acquire logic, or by some other ownership/association path. Keep this slice investigation-only: produce a truthful diagnosis of where side ownership is decided, when fallback is entered, what conditions preserve existing pose-side truth, and whether the current code can plausibly create the exact observed swap. Claim the bead on start and stop after updating the plan with findings plus a recommended narrow repair direction.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- source/test folders only if tiny diagnostic coverage is needed

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- focused diagnostic notes/tests if added

**Status:** ✅ Complete

**Results:** Investigation complete. The nearest-wrist hypothesis is **partially confirmed, but the sharper fault line is that the tracker does not actually preserve pose-side truth at all** once it has a prior hand sample. Real ownership/reacquire decisions live upstream in `aerobeat-tool-camera-tracking/src/CameraTrackingFrame.gd`, not in this owner repo: `_normalize_hands_by_side()` calls `_assign_hand_candidates()`, which first runs `prefer_existing_pose_side_binding` by matching each side to the **nearest previous hand anchor** via `_hand_payload_anchor()` / `_nearest_candidate_index()`, and only then falls back to pose wrists via `_extract_pose_wrists()` + `_nearest_candidate_index()`. That means `prefer_existing_pose_side_binding` is a misleading name today: it preserves prior spatial continuity, not pose-derived left/right truth. When stale carry expires, `_normalize_hands_by_side()` emits `tracking_lost` from an empty payload template, so the next frame no longer has landmarks/bbox for `_hand_payload_anchor()` and the old binding is discarded; reacquire then re-guesses from `nearest_wrist_fallback` even if the recovered hand detections are still crossed/occluded relative to the pose wrists. Because vendor handedness labels are only copied into `association.source_label` and never trusted for durable ownership (`aerobeat-tool-camera-tracking/docs/tracker-config-schema.md`, `CameraTrackingFrame.gd::_association_from_candidate()`), the real code can plausibly produce Derrick’s exact observed post-occlusion swap: valid pose wrists remain visible, previous lane binding times out, and the next assignment is rebuilt from nearest current wrist proximity instead of a pose-side-stable identity rule. Downstream owner code (`src/detectors/pose_detector_substrate.gd::_get_tracking_hand_payload()` / `_process_straight_punch()`) only consumes `hands.left` / `hands.right` and their `tracking_state`/`association`; it does not reassign sides again. Recommended narrow repair direction for Task 10C: fix the tracker-layer ownership logic in `aerobeat-tool-camera-tracking/src/CameraTrackingFrame.gd` so that when pose wrists are present, side binding is anchored to pose-side truth (or an explicit durable side lock derived from it) across stale/reacquire transitions, instead of treating prior hand-anchor proximity as the primary `existing binding` rule and nearest-wrist as a full re-guess after `tracking_lost`.

---

### Task 10C: Repair hand side re-association after occlusion in the boxing proving scene

**Bead ID:** `aerobeat-input-camera-tracking-1pl`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`
**Prompt:** Investigate and repair the boxing-scene hand side re-association bug Derrick observed: after a left straight punch occludes/crosses near the right hand, the tracked hand ownership returns swapped (`L` and `R` reverse) even though the pose skeleton/wrists remain valid. Audit the current side-binding / nearest-wrist fallback logic across the owner repo and tool-layer normalized hand payload path, confirm whether the re-acquire path is incorrectly guessing nearest wrist instead of preserving pose-side truth when pose wrists are still valid, and implement the smallest truthful fix. Keep the slice focused on hand-side ownership/reacquire semantics and the evidence path needed to verify that left/right do not swap under the observed occlusion case. Claim the bead on start and close it only if the swapped-side repro is actually addressed.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`
- dependency-repo source/test files if owner-correct changes are required in `REF-02` or `REF-03`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- owner/tool/vendor files that implement hand side association/reacquire logic
- focused validation artifacts or tests if added

**Status:** ✅ Complete

**Results:** Claimed the bead with `bd update aerobeat-input-camera-tracking-1pl --status in_progress --json`, then landed the owner-correct tracker repair upstream in `REF-02` (`/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTrackingFrame.gd`). The actual fault was that `prefer_existing_pose_side_binding` was preserving the previous hand sample's screen-space anchor, not a durable pose-side lock. Once stale carry expired, `tracking_lost` dropped the old landmarks/bbox, so reacquire had no persistent side memory and rebuilt ownership from fresh wrist proximity. The repair now persists a private `_pose_side_locked` flag whenever a side is associated while pose wrists are available, carries that lock through `stale` and `tracking_lost`, and changes `_assign_hand_candidates()` so locked sides prefer the **current pose wrist anchor for that same side** before any old hand-anchor continuity. That keeps crossed-hand reacquire aligned to pose-side truth instead of re-guessing from stale screen position. Added focused proof coverage in `REF-02` testbed: `test_frame_normalization_preserves_pose_side_lock_across_tracking_lost_reacquire()` drives tracked → stale → tracking_lost → crossed-hand reacquire and proves the reacquired left/right lanes stay attached to their crossed pose wrists using `prefer_existing_pose_side_binding`. Validation run from `REF-02` repo root: `godot --headless --path .testbed --import` and `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` → 32/32 tests passed. This makes Task 10 blocker `aerobeat-input-camera-tracking-35y` cleaner to rerun because the upstream `hands.left/right` payload should now keep ownership stable across the investigated occlusion/reacquire seam.

---

### Task 10D: Clean obvious workspace noise in `aerobeat-input-camera-tracking`

**Bead ID:** `aerobeat-input-camera-tracking-qli`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Clean obvious repo/worktree noise in `aerobeat-input-camera-tracking` without touching the active detector repair logic. Focus on safe housekeeping only: generated/untracked clutter, duplicate stray fixture copies at repo root if they are clearly non-canonical, nested accidental testbed artifacts, and similar workspace noise that makes the repo harder to reason about. Preserve meaningful QA artifacts, plan evidence, and user-authored fixture sources. If cleanup requires `.gitignore` or other tiny repo-hygiene fixes, keep them narrow and truthful. Claim the bead on start and close it only if the workspace is materially cleaner without deleting important evidence.

**Folders Created/Deleted/Modified:**
- repo root / `.testbed/` / support files as needed for safe cleanup

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- repo hygiene files and obvious generated clutter paths if cleanup lands

**Status:** ✅ Complete

**Results:** Cleanup completed in a separate owner-repo housekeeping slice without touching the active tracker repair logic. Safe workspace-noise cleanup removed the accidental nested scratch dir `.testbed/.testbed/`, stray generated `.uid` files (`.testbed/scripts/hand_bbox_state_drawer.gd.uid`, `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd.uid`, `.testbed/tests/unit/test_camera_tracking_config_profiles.gd.uid`, and `src/config/profile_config_loader.gd.uid`), and non-canonical root clutter copies `punch_left_repeat_04_take_01.{mp4,yaml}` / `punch_right_repeat_04_take_01.{mp4,yaml}`. Canonical fixtures under `.testbed/assets/fixtures/boxing/{punch_left,punch_right}/` and existing QA/test-result evidence under `.testbed/test-results/` were preserved. Repo hygiene was tightened narrowly by adding `.testbed/.testbed/` to `.gitignore` so the accidental nested testbed scratch path stays out of future status noise. Before cleanup the repo had the active tracked changes plus 9 untracked noise paths; after cleanup the untracked noise paths were gone and the only new tracked housekeeping change was `.gitignore`. This leaves the owner repo materially cleaner for Derrick’s Cookie retests without deleting meaningful evidence.

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