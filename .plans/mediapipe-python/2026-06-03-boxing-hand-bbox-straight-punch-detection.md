# AeroBeat Boxing Hand BBox Straight Punch Detection

**Date:** 2026-06-03
**Status:** In Progress
**Last Updated:** 2026-06-05 04:22 EDT
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
| `REF-07` | Replay/video owner repo that should provide truthful paused stepping and playback transport primitives | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-video-player` |
| `REF-08` | Godot video vendor dependency under the replay owner that may need lower-level decoder or transport support | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-video` |

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

### Task 10E: Fix remaining landmark preview-space Y mismatch in the boxing proving scene

**Bead ID:** `aerobeat-input-camera-tracking-gx2`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`
**Prompt:** Derrick confirmed the landmark inspector collider layer is still vertically flipped in the boxing proving scene even after the earlier click-target mapping fix. Investigate the remaining preview-space Y mismatch truthfully and repair it. The likely seam is that the input repo testbed is feeding gameplay-space/flipped pose landmarks into a preview-space click/overlay path (for example via `src/tracking_frame_adapter.gd`), but do not assume the exact fix without proving it. Keep the slice focused on making the visible pose skeleton, visible collider debug rings, and click resolution all agree in the boxing proving scene. Claim the bead on start and close it only if the alignment is actually corrected and validated.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `src/tracking_frame_adapter.gd`
- `src/providers/camera_tracking_provider.gd`
- `.testbed/tests/unit/test_tracking_frame_adapter.gd`
- `.testbed/tests/unit/test_camera_tracking_provider.gd`
- `.testbed/tests/unit/test_proving_harness_trails.gd`

**Status:** ✅ Complete

**Results:** Root cause proved: the remaining vertical mismatch was no longer in `.testbed/scripts/landmark_drawer.gd`; it was upstream in the shared owner-repo adapter/provider seam. `src/tracking_frame_adapter.gd` still inverted landmark `y` into bottom-left gameplay space inside the single payload used for both detector math and proving-scene overlays. The tool-owned preview presenter renders MediaPipe landmarks in native top-left preview space, and Task 10A/10B already moved click-target mapping onto that preview-space contract, so the proving scene was still receiving pose landmarks with `y` flipped once too early. That left the visible presenter skeleton correct while the boxing proving scene's landmark drawer / collider debug rings / click resolution path consumed vertically mirrored landmark coordinates.

Narrow repair landed by splitting the adapter output into two explicit spaces instead of hiding gameplay conversion in the shared overlay payload. `src/tracking_frame_adapter.gd` now preserves top-left preview-space `y` in `landmarks_from_tracking_frame()` and exposes a separate `gameplay_landmarks_from_tracking_frame()` helper for the legacy detector path. `src/providers/camera_tracking_provider.gd` now feeds gameplay-space landmarks only into detector/runtime math, while `pose_updated` and `_all_poses` keep preview-space landmarks for proving-scene overlays and inspection. Focused regression coverage was updated in `.testbed/tests/unit/test_tracking_frame_adapter.gd`, `.testbed/tests/unit/test_camera_tracking_provider.gd`, and `.testbed/tests/unit/test_proving_harness_trails.gd`, including a new harness-level proof that `_on_pose_updated()` now drives the real `LandmarkDrawer` hit targets to the same preview-space positions the presenter expects.

Exact validation performed:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_tracking_frame_adapter.gd,res://tests/unit/test_camera_tracking_provider.gd,res://tests/unit/test_landmark_drawer.gd,res://tests/unit/test_proving_harness_trails.gd -gexit` ✅ (`52/52` passed, `241` asserts)
- `godot --headless --path .testbed --script res://scripts/proof_skeleton_overlay.gd` ✅ (boxing proving scene booted through the contract path and rewrote `.artifacts/skeleton-proof/report.json` showing presenter-space landmark positions with top-left `y` semantics)

This keeps gameplay-facing detector math on the old bottom-left normalized contract while making the proving-scene visible skeleton, visible hit-target rings, and click resolution all consume the same preview-space landmark `y`. That leaves Task 10F cleaner because the remaining work can focus on debug-toggle ownership instead of compensating for a hidden mixed-coordinate payload.

---

### Task 10F: Promote proving-scene visual debug toggles into input-owned config

**Bead ID:** `aerobeat-input-camera-tracking-ek1`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Promote the useful proving-scene visual debug toggles out of ad-hoc scene-only exports and into the input repo's owned config path. Derrick wants testbed-only debug controls for things like landmark visibility, trail visibility, hand bbox overlay visibility, landmark hit-target visibility, and landmark hit-target labels to live in `aerobeat-input-camera-tracking` config rather than in `aerobeat-tool-camera-tracking`. Keep this slice scoped to the input repo/testbed config surface and scene wiring; do not widen into tracker-layer config ownership. Claim the bead on start and close it only if the toggles are actually driven from the input-owned config path and the boxing proving scene honors them.

**Folders Created/Deleted/Modified:**
- `assets/`
- `.testbed/`
- `src/config/` if required for input-owned config plumbing

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- input-owned config files and proving-scene/testbed files that consume the new debug booleans
- focused validation artifacts or tests if added

**Status:** ✅ Complete

**Results:** Root cause: the proving-scene visual toggles only lived as scene exports / per-node inspector state (`show_landmarks`, `show_trails`, landmark hit-target booleans, and the boxing bbox drawer), so profile switching never exercised an input-owned source of truth. Approach: added a third repo-owned profile document per input profile (`assets/{boxing,flow}.testbed_debug.yaml` with schema `aerobeat/testbed_debug_config`) and extended `ProfileConfigLoader` / `CameraTrackingConfig` so the selected profile bundle now carries `testbed_debug_path` plus the parsed `testbed_debug` document alongside the tracker and gesture YAMLs. The boxing proving harness now reads that bundle and applies `visuals.show_landmarks`, `visuals.show_trails`, `visuals.show_hand_bbox_overlay`, `visuals.show_landmark_hit_targets`, and `visuals.show_landmark_hit_target_labels` to the inherited overlay toggles and boxing bbox drawer instead of relying on ad-hoc scene-only values.

Files changed: `assets/boxing.testbed_debug.yaml`, `assets/flow.testbed_debug.yaml`, `src/config/profile_config_loader.gd`, `src/config/camera_tracking_config.gd`, `.testbed/scripts/proving_harness.gd`, `.testbed/scripts/boxing_proving_harness.gd`, `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`, `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`, plus regenerated Godot `.uid` companions for touched/new scripts.

Validation: `godot --headless --path .testbed --import --quit-after 1000` ✅; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_camera_tracking_config_profiles.gd -gexit` ✅ (`42/42` passed, `228` asserts; existing boxing harness orphan warnings remained, no new failing tests).

---

### Task 10G: Retire proving_harness public debug exports and repair hand bbox overlay visibility

**Bead ID:** `aerobeat-input-camera-tracking-uvl`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Derrick confirmed the new config-driven landmark hit-target toggle works, but the old public proving-harness exports are still exposed in the scene inspector and the hand bbox overlay is not visibly rendering even when the new boxing testbed debug config sets `visuals.show_hand_bbox_overlay: true`. Clean this up in one focused slice: remove/retire the now-redundant public debug exports from `proving_harness.gd` / scene-facing workflow where they are superseded by input-owned config, and audit/fix the boxing proving hand bbox overlay visibility so the overlay actually renders when enabled. Keep the scope narrow to input-repo testbed/config wiring and the bbox debug drawer path; do not widen into punch-detector tuning. Claim the bead on start and close it only if the inspector clutter is removed and the hand bbox overlay is truthfully working again.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-uvl` with `bd update ... --status in_progress --json`, then kept this slice tightly scoped to the proving-scene config/debug seam. Inspector clutter cleanup: retired the now-redundant public scene exports `show_landmarks` and `show_trails` in `.testbed/scripts/proving_harness.gd` by converting them from `@export` inspector fields into plain runtime vars, and removed the old scene-authored `show_trails = ...` overrides from both proving scenes so the config-backed `assets/{boxing,flow}.testbed_debug.yaml` bundle is the sole control surface for those toggles. Hand bbox overlay root cause: the boxing harness was reparenting `HandBBoxDrawer` to the preview presenter root, but the tool-owned presenter now exposes an explicit overlay layer; that meant the boxing bbox drawer was not guaranteed to live on the active overlay plane even when `visuals.show_hand_bbox_overlay: true` made it visible. The repair now resolves `get_overlay_layer()` when available, reparents the bbox drawer there, reapplies full-rect overlay sizing after reparent, and still pushes live hand + straight-punch snapshots into the drawer. Added focused proof coverage in `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` to verify the bbox drawer reparents into the preview overlay layer, keeps the preview presenter binding, remains full-rect, and receives a non-empty hand snapshot. Exact validation run from repo root: `godot --headless --path .testbed --import --quit-after 1000` ✅; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_proving_harness_trails.gd,res://tests/unit/test_camera_tracking_config_profiles.gd -gexit` ✅ (`43/43` tests passed, `235` asserts). With the redundant exports retired and the bbox drawer now mounted on the presenter's overlay layer, this slice is ready for Cookie to pull and re-check in the boxing proving scene without rerunning broader Task 10 QA.

---

### Task 10H: Remove in-scene profile switching UI and hide leftover proving-node tuning exports

**Bead ID:** `aerobeat-input-camera-tracking-96x`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Derrick does not want in-scene tracking profile UI in the new boxing proving scene, and the proving-node editor surface still exposes tuning vars that should no longer be public. Keep this slice tightly scoped to cleanup only: remove the boxing scene's in-scene profile label/picker and the related profile-switch runtime logic, retire the leftover proving-node exported tuning vars from `proving_harness.gd` while preserving current runtime defaults/config behavior, add focused proof if useful, validate truthfully, update the active plan, and close the bead only if the unwanted profile UI is gone and the editor-facing proving-node surface is meaningfully cleaner.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/scenes/boxing_proving.tscn`
- `.testbed/scenes/flow_proving.tscn`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-96x` with `bd update ... --status in_progress --json` and kept the scope to UI/editor-surface cleanup only. Removed the in-scene boxing profile controls by deleting `ProfileLabel` and `ProfilePicker` from `.testbed/scenes/boxing_proving.tscn`, then removed the matching runtime switching path from `.testbed/scripts/boxing_proving_harness.gd` (`profile_picker` binding, `_profile_switch_in_progress`, `_configure_profile_controls()`, `_on_profile_picker_selected()`, `_apply_selected_profile()`, `_restart_provider_with_selected_profile()`, and the now-unused `PROFILE_FLOW` picker option). The boxing proving harness now stays on its canonical boxing bundle and still shows the resolved tracker/gesture config paths.

Editor-surface cleanup: retired the leftover proving-node tuning exports in `.testbed/scripts/proving_harness.gd` by converting `overlay_visibility_threshold`, `tracking_smoothing_style`, and `gesture_eval_interval_frames` from exported inspector fields into plain runtime vars. Removed the stale scene-authored `tracking_smoothing_style = 1` overrides from both `.testbed/scenes/boxing_proving.tscn` and `.testbed/scenes/flow_proving.tscn` so those hidden runtime values fall back to the script defaults instead of lingering as editable scene data.

Focused proof added in `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`: one test now instantiates `boxing_proving.tscn` and proves `ProfileLabel` / `ProfilePicker` are gone while the config-path fields remain, and another asserts `scene_title` is still editor-exposed but `overlay_visibility_threshold`, `tracking_smoothing_style`, and `gesture_eval_interval_frames` are no longer editor-exposed properties on `proving_harness.gd`.

Validation run from repo root: `godot --headless --path .testbed --import --quit-after 1000` ✅; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` ✅ (`9/9` passed, `67` asserts). The GUT run still emitted the pre-existing orphan / RID leak warnings, but there were no new test failures and the cleanup scope passed truthfully. This slice is ready for Cookie to pull again for the narrower proving-scene cleanup check; no Task 10 end-to-end QA was rerun here.

---

### Task 10I: Investigate and repair bbox overlay invisibility after Derrick's live retest

**Bead ID:** `aerobeat-input-camera-tracking-d3b`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`
**Prompt:** Derrick retested the boxing proving scene on-device and reported that the hand tracking bbox still is not visibly rendering even though the scene config/debug profile has it enabled. Keep this slice narrow and truth-first: trace the proving-scene bbox overlay path end to end (input-owned testbed debug config -> boxing harness visibility toggle -> preview presenter overlay parent -> hand debug snapshot/bbox geometry -> final draw path), identify the real failure seam, implement the smallest durable repair, and validate that enabled bbox overlays actually render/update in the boxing proving scene without widening into punch-threshold tuning. Claim the bead on start and close it only if the visibility bug is genuinely fixed and verified.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/`
- dependency repo files in `REF-02` only if the true root cause is tool-owned

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `assets/boxing.camera_tracking.yaml`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- nondurable probes: `.testbed/scripts/tmp_task10i_profile_probe.gd`, `.testbed/scripts/tmp_task10i_runtime_probe.gd`

**Status:** ✅ Complete

**Results:** Root cause was repo-local config corruption, not a host MediaPipe capability gap: `assets/boxing.camera_tracking.yaml` used tab indentation under `tracking.pose` / `tracking.hands`, so the selected boxing profile loaded as `{"tracking":{"pose":null}}` in Godot. That silently dropped `tracking.hands.enabled`, which let the proving stack fall back to `hand_tracking_enabled = false` even though the debug profile still showed the bbox overlay toggle as enabled, creating the misleading “scene config ignored” symptom. Replacing the tabs with valid YAML space indentation restored the full boxing hand-tracking subtree, and a focused headless runtime probe then showed the proving scene now starts with `active_config.tracking.hands.enabled = true`, `runtime.hand_tracking_enabled = true`, `tracking_frame.hand_tracking.available = true`, `tracking_frame.hand_tracking.enabled = true`, and populated left/right hand bbox payloads from `mediapipe_tasks_hand_landmarker`. Added regression coverage so profile loading now explicitly asserts boxing hands are enabled/bbox-backed, while the existing provider replay/live-start tests continue to prove the boxing bundle forwards hand config into the tracking session. Validation run: `godot --headless --path .testbed --script scripts/tmp_task10i_profile_probe.gd`; `godot --headless --path .testbed --script scripts/tmp_task10i_runtime_probe.gd scenes/boxing_proving.tscn 5000 /tmp/task10i_runtime_probe_after.json`; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gtest=res://tests/unit/test_camera_tracking_provider.gd -gexit` (`14/14` passed, `96` asserts). An attempted run including `test_boxing_proving_harness_profiles_and_debug.gd` still hit a pre-existing unrelated trail-drawer test-double issue (`Control` lacks `update_trails`), so that file was not used as the regression gate for this slice.

---

### Task 10J: Correct the still-malformed boxing profile YAML and clean the boxing proving warning seam

**Bead ID:** `aerobeat-input-camera-tracking-6mz`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Derrick retested after pulling/syncing and confirmed the boxing proving scene still reports `Hand tracking - disabled` while the bbox overlay is expected, plus Godot emits a shadowed `position` warning from `boxing_proving_harness.gd`. Keep this slice narrow and truth-first: verify the actual source and mounted addon copies of `assets/boxing.camera_tracking.yaml`, correct the boxing profile YAML indentation/shape if it is still malformed, fix the identified low-risk warning seam in `boxing_proving_harness.gd`, validate that the boxing proving runtime now sees hand tracking enabled, and update the active plan with the real result. Do not widen into punch-threshold tuning. Claim the bead on start and close it only if the config really loads correctly and the warning seam is addressed.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `assets/`
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `assets/boxing.camera_tracking.yaml`
- `.testbed/scripts/boxing_proving_harness.gd`
- focused tests/probes if needed

**Status:** ✅ Complete

**Results:** The root cause was still-on-disk tab indentation in the owning repo’s `assets/boxing.camera_tracking.yaml`, not a stale testbed mirror or a MediaPipe/runtime capability problem. I re-verified the raw file bytes before fixing them, then overwrote the boxing camera-tracking profile with space-indented YAML so Godot now loads the full `tracking.pose` and `tracking.hands` subtree instead of collapsing boxing to `{"tracking":{"pose":null}}`. I confirmed the mounted addon/testbed path updated through the normal repo path (`.testbed/addons/aerobeat-input-camera-tracking -> /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`) and that the mounted YAML also no longer contains tabs. I also fixed the low-risk warning seam in `.testbed/scripts/boxing_proving_harness.gd` by renaming the local playback `position` variable to `playback_position` inside `_fmt_playback_status()`. Validation was narrow and truth-first: (1) direct byte-level tab scan of source + mounted YAML, (2) headless Godot unit regression run `test_camera_tracking_config_profiles.gd` + `test_camera_tracking_provider.gd` (`14/14` passed, `96` asserts), and (3) a focused headless runtime probe of `res://scenes/boxing_proving.tscn`, which reported `status_label = Boxing harness live`, `active_config.tracking.hands.enabled = true`, `active_config.runtime.hand_tracking_enabled = true`, `tracking_frame.hand_tracking.available = true`, `tracking_frame.hand_tracking.enabled = true`, and live hand bbox payloads from the boxing proving stack. Temporary probe scripts used for this validation were cleaned up after use.

---

### Task 10K: Investigate live proving-scene hand-tracking-disabled state that still reproduces on Derrick's device

**Bead ID:** `aerobeat-input-camera-tracking-b7w`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`
**Prompt:** Derrick retested live on-device after the prior boxing profile and warning fixes, and the boxing proving scene still reports `Hand tracking - disabled` / `tracking_lost` with no bbox overlay visible. Keep this slice tightly anchored to the real live failure, not only headless probes: trace the exact runtime/config/session path that drives the proving-scene hand-tracking status in the live scene, determine why the live scene still disables hands even though earlier focused validation claimed otherwise, and implement the smallest truthful repair. Validate against the real proving-scene state path and update the active plan with what actually happened. Do not widen into punch-threshold tuning. Claim the bead on start and close it only if the live proving-scene hand-tracking-disabled failure is genuinely fixed or the remaining blocker is precisely proven.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `assets/`
- `.testbed/tests/unit/`
- `src/config/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `assets/boxing.camera_tracking.yaml`
- `assets/boxing.gesture_detection.yaml`
- `src/config/profile_config_loader.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`

**Status:** ✅ Complete

**Results:** Traced the live proving-scene hand-tracking-disabled seam through the same startup path the boxing scene uses: `boxing_proving_harness.gd::_build_runtime_config()` sets the boxing profile on `CameraTrackingConfig`, which loads the repo-owned profile bundle via `src/config/profile_config_loader.gd` from `res://addons/aerobeat-input-camera-tracking/assets/{boxing.camera_tracking,boxing.gesture_detection,boxing.testbed_debug}.yaml`; that bundle then feeds `AeroCameraTracking` / `camera_tracking_provider.gd`, and the proving scene’s status + hand bbox drawer consume the resulting `tracking_frame.hand_tracking` / `hands.left|right` state. The real failure was **not** a detector/runtime capability gap: Derrick’s live scene was reading a locally regressed boxing tracker profile with tab-indented YAML in `assets/boxing.camera_tracking.yaml`, which the lightweight in-repo parser silently mis-shaped so the boxing bundle lost the expected `tracking.hands` subtree and the proving UI truthfully fell back to `Hand tracking - disabled` / `tracking_lost` with no bbox overlay. While tracing that seam I also found the matching boxing gesture profile still used tab indentation, so I normalized `assets/boxing.gesture_detection.yaml` too and hardened `ProfileConfigLoader` to reject tab-indented YAML explicitly (`config_tab_indentation`) instead of silently accepting malformed structure again. Focused regression coverage now proves the loader rejects tab-indented profile docs, and a proving-scene runtime-path probe against `res://scenes/boxing_proving.tscn` shows the actual boxing harness now resolves `runtime_bundle.profile=boxing`, `camera_tracking_path=res://addons/aerobeat-input-camera-tracking/assets/boxing.camera_tracking.yaml`, `tracking.pose.enabled=true`, `tracking.hands.enabled=true`, `tracking.hands.landmark_mode=lite`, and `status_label=Boxing harness live` through the same scene/runtime config seam Derrick was using. Temporary probe scripts were cleaned up after validation.

---

### Task 10L: Trace and stop the boxing YAML files from being locally rewritten back into tab-indented form

**Bead ID:** `aerobeat-input-camera-tracking-xhg`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Derrick retested and observed that the boxing YAML files themselves show up as dirty local changes after running the proving scene, and the dirty diffs reveal tabs being reintroduced into `assets/boxing.camera_tracking.yaml` and `assets/boxing.gesture_detection.yaml`. Keep this slice tightly focused on mutation tracing: identify what codepath/tool/workflow is rewriting or restoring those repo-owned YAML files into tab-indented form, stop that mutation at the owner-correct source, and validate that running the relevant proving-scene path no longer dirties the YAML files. Do not widen into punch-threshold tuning. Claim the bead on start and close it only if the mutation/restoration path is genuinely identified and fixed, or the remaining blocker is precisely proven.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** Traced the apparent YAML “mutation” to an external workflow, not the boxing proving scene runtime. The tab-indented on-disk contents matched the exact blob IDs from git object `ebda3095` (`On main: git-sync:projects/aerobeat/aerobeat-input-camera-tracking`), which is a stash object created by the shared `/home/derrick/.openclaw/workspace/scripts/git-sync` flow at `2026-06-04 16:35`. The local file mtimes (`2026-06-04 16:38`) and byte-exact blob match proved that `git-sync` had restored pre-existing local dirt for `assets/boxing.camera_tracking.yaml` and `assets/boxing.gesture_detection.yaml`; the proving scene itself was not rewriting those repo-owned YAML files. Owner-correct fix for this repo was therefore to remove the restored stale dirt, not to change the proving runtime: I restored both YAMLs back to `HEAD`, leaving the active plan note as the only remaining worktree change. Validation then reran the relevant proving-scene path headlessly with the real boxing scene via `godot --headless --path .testbed --script scripts/capture_fixture_proving.gd -- scenes/boxing_proving.tscn res://assets/fixtures/boxing/punch_left/boxing_guard->punch_left_repeat_04_take_01.mp4 /tmp/task10l-proving-capture 5000`, which reached `status_label = Boxing harness live`, `provider_present = true`, and `camera_streaming = true` while `git diff --name-only -- assets/boxing.camera_tracking.yaml assets/boxing.gesture_detection.yaml` stayed empty before/after the run. Temporary capture output under `/tmp/task10l-proving-capture` was removed after validation. Net truth: no repo runtime code was reintroducing tabs; the dirty YAMLs came from `git-sync` restoring earlier local changes, and the proving-scene path no longer dirties those files once that restored dirt is cleared.

---

### Task 10M: Trace the exact writer that mutates the boxing YAML files during live project load/play

**Bead ID:** `aerobeat-input-camera-tracking-oht`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Derrick now reports that simply loading the Godot project and playing the boxing proving scene causes `assets/boxing.camera_tracking.yaml` and `assets/boxing.gesture_detection.yaml` to change locally. Keep this slice narrowly forensic: instrument/watch those repo-owned YAML files during the real editor/project load + play path, identify the exact writer process/path/workflow that mutates them, and document whether the source is Godot/editor/plugin code, a repo script/helper, or another local workflow layer. If the writer can be stopped safely in-scope, make the smallest owner-correct fix; otherwise return precise evidence for the real mutator. Do not widen into punch-threshold tuning. Claim the bead on start and close it only if the writer is genuinely identified and either fixed or sharply proven.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-oht` and traced the YAMLs under both halves of the reported path. For the live editor load, I launched the real GUI editor on `.testbed` under `strace -ff -yy` and watched every open/write/rename touching `assets/boxing.camera_tracking.yaml` and `assets/boxing.gesture_detection.yaml`. Godot PID `419213` only opened both files `O_RDONLY`; the only observed write mentioning those paths was to `.testbed/.godot/editor/script_editor_cache.cfg-*`, where the editor cached the open tab metadata. No syscall in the editor trace opened either repo YAML with `O_WRONLY`/`O_RDWR`, renamed over them, or wrote to their inodes. For the play/runtime half, I launched `godot --path .testbed scenes/boxing_proving.tscn` under a second `strace`; runtime PID `419453` repeatedly opened both YAMLs `O_RDONLY` and read their contents while the harness reached `CameraTracking contract proving mode active`, `Tracking restored`, and `Boxing harness live`, again with zero write/rename activity against the repo YAMLs. Hashes, mtimes, and `git status` for both files stayed unchanged before/after the traced runs.

That narrows the writer away from Godot/editor/plugin/runtime code for this repro path. The remaining proven mutator is the external local sync workflow: workspace script `/home/derrick/.openclaw/workspace/scripts/git-sync` explicitly stashes dirty tracked+untracked changes, fast-forwards, then restores them via `git stash apply --index` (`git_stash_push()` / `git_stash_apply_and_drop()` in that script). This repo’s latest stash entry is `stash@{2026-06-04 16:35:21 -0400}` with message `On main: git-sync:projects/aerobeat/aerobeat-input-camera-tracking`; its blobs for both boxing YAMLs are tab-indented (`HAS_TAB True`) and therefore match the earlier dirty-file symptom. The repo files are currently clean at `HEAD` (`HAS_TAB False`, no diff), so the smallest owner-correct repair in-scope was to avoid any repo code change and instead sharply document that Godot load/play is not the writer; when dirt reappears, the remaining blocker is external restoration of pre-existing local edits, not project runtime mutation. Temporary trace directories under `/tmp/godot-yaml-trace` and `/tmp/godot-runtime-trace` were removed after capture.

---

### Task 10N: Run a controlled clean-launch-clean-check repro for the boxing YAML reset claim

**Bead ID:** `aerobeat-input-camera-tracking-7i6`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`
**Prompt:** Derrick asked for a controlled repro to distinguish whether playing the boxing proving scene itself resets the boxing YAML files into the bad tab-indented state, or whether the bad state already exists before launch. Keep this slice narrowly procedural: restore the two boxing YAML files to known-good bytes, confirm clean git status before launch, run the real project/scene load + play path, and check git status plus file bytes immediately afterward. Record the exact before/after status and whether the scene run itself re-dirties the files. Do not widen into punch-threshold tuning. Claim the bead on start and close it only after the controlled repro is complete and documented.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- focused repro artifacts only if needed

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- temporary repro artifacts if any

**Status:** ✅ Complete

**Results:** Restored `assets/boxing.camera_tracking.yaml` and `assets/boxing.gesture_detection.yaml` to `HEAD` with `git restore --source=HEAD -- ...`, then captured the controlled pre-launch baseline. Exact pre-launch state for the two target files: `git status --short -- assets/...` returned clean, SHA-256 stayed at `2e288ff79707a07e3205d481d3ce581d21bb2f6c8df299115daf260dcb0de443` (`boxing.camera_tracking.yaml`) and `c6019bb377f27597fe22f3991f75352622754dbe34aec2046206ab63ed646bcb` (`boxing.gesture_detection.yaml`), and `grep` found no tab characters in either file. Repo-wide `git status` was not globally clean because the active plan file was already modified before launch, but the boxing YAML targets themselves were clean.

For the launch path, I stayed narrow and used the closest practical real scene-run entrypoint available from this subagent environment without destructive teardown of the already-open editor session: a fresh one-shot Godot runtime launch of the real proving scene via `godot --path .testbed --scene res://scenes/boxing_proving.tscn --quit-after 600 --log-file <tmp>`. That run reached the expected live markers in stdout/log (`[ProvingHarness][Boxing] CameraTracking contract proving mode active`, `Tracking restored`, `Boxing harness live`) and exited `0`; temporary log files were removed afterward.

Immediate post-launch check was unchanged for the target files: `git status --short -- assets/...` still returned clean, the SHA-256 values were identical to pre-launch, and `grep` again found no tab characters in either YAML. Conclusion: this controlled scene run did **not** re-dirty `assets/boxing.camera_tracking.yaml` or `assets/boxing.gesture_detection.yaml`; the bad tab-indented state was not reproduced by the scene play path used here.

---

### Task 10O: Repair replay-pause debugger truthfulness and frame-step controls

**Bead ID:** `aerobeat-input-camera-tracking-35y.1`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`
**Prompt:** Implement Derrick's new boxing proving-scene debugging feedback in the owner repo. Keep YAML edits outside the Godot editor because we now have a proven editor-side YAML corruption hazard. Repair the paused-replay inspector/debug behavior so straight-punch state-change counters and live debug values do not keep mutating incorrectly while replay is paused; specifically freeze or preserve truthful paused values for latest state-change age/counter semantics, wrist velocity, and bbox area growth when stepping/pausing. Remove the straight-punch inspector line that shows the event payload snapshot. Repair the detected-event window so it can be intentionally scrolled while paused without snapping back to the top, while still auto-scrolling to top when genuinely new live/replay events arrive. Repair pause/resume so replay stepping does not tear down and restart camera tracking on resume. Add explicit paused-only one-frame step backward/forward controls next to the timecode plus matching keyboard left/right-arrow bindings that are disabled while playback is running. Claim the bead on start, keep the slice focused on proving-scene replay/debug UX truthfulness, and leave punch-threshold tuning out of scope unless strictly required by the pause/step repair.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

**Status:** ✅ Complete

**Results:** Implemented the paused-replay truthfulness repairs in the proving harness without touching YAMLs or widening into threshold tuning. `proving_harness.gd` now adds paused-only step-back/step-forward controls beside the timecode, left/right-arrow stepping, shared-inspector freezing for any paused prerecorded target, and replay step-size tracking derived from playback deltas so paused frame stepping stays disabled while playback is running. `boxing_proving_harness.gd` now snapshots boxing debug state on pause, freezes straight-punch age semantics against the pause timestamp, keeps wrist velocity / bbox growth / transition details truthful while paused, removes the `state_change_payload` / “Event payload snapshot” line from the gesture inspector body, and only auto-scrolls the detected-event feed when a genuinely new event is appended. I did not land a deeper pause/resume backend rewrite because the owner repo already pauses replay via `provider.stop(true)` with preserved runtime state (`REF-01`), and the observed reset symptoms were explained by stale live UI reads rather than a newly proven replay-session ownership bug. Added focused regression coverage in `test_boxing_proving_harness_profiles_and_debug.gd` for the removed payload line, paused inspector freeze behavior, and paused-only step button enablement. Validation: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit` (111/111 passing; existing GUT UID/object leak warnings remain). Commits: `2ccf7f6` - `Fix paused boxing replay inspector truthfulness`.

---

### Task 10P: Investigate the remaining straight-punch side-flash under occlusion

**Bead ID:** `aerobeat-input-camera-tracking-35y.2`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-06`
**Prompt:** Investigate Derrick's latest replay observation that during a left straight-punch extension the opposite hand can briefly lose tracking, come back under the wrong side label, then return to the correct side. Start from the earlier pose-side-lock repair and determine whether the remaining flash is caused by a still-unlocked association path, stale carry / tracking_lost transitions, wrong-side fallback when only one hand is reacquired, mirrored presentation vs raw side labels, or proving-scene presentation of the normalized payload. Keep this slice diagnosis-first: produce a truthful explanation of what path can still create the observed flash in the current code, and only land the smallest owner-correct repair if the cause is proven in-scope. Claim the bead on start and update this plan with the exact cause, evidence path, and next repair direction.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `REF-02` source/test folders in `aerobeat-tool-camera-tracking`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `REF-02` `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTrackingFrame.gd`
- `REF-02` `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/tests/test_CameraTracking.gd`

**Status:** ✅ Complete

**Results:** Diagnosis first, then a narrow upstream repair. The remaining transient wrong-side flash was **not** a proving-scene lag artifact, mirrored-only presentation mismatch, or downstream `AeroCameraTracking` / detector-side relabeling seam. The real current path was still upstream in `REF-02` `aerobeat-tool-camera-tracking/src/CameraTrackingFrame.gd::_assign_hand_candidates()`: after Task 10C preserved `_pose_side_locked`, the tracker still assigned candidates with a fixed per-side loop (`left` then `right`) in both `prefer_existing_pose_side_binding` and `nearest_wrist_fallback`. When only **one** hand candidate was visible on reacquire, `_nearest_candidate_index()` returned that lone candidate for any non-empty anchor, so the left-side pass could claim it first purely because it was evaluated first, not because it was the nearest surviving locked side. That leaves a real transient seam where the opposite hand can disappear during a left straight extension, return first as the only visible hand sample, briefly populate the wrong normalized side lane, then snap back once both candidates are visible again.

Evidence path: `REF-02` `CameraTrackingFrame.gd::_normalize_hands_by_side()` preserves `_pose_side_locked` through `stale` and `tracking_lost`, but reacquire ownership still flowed through `_assign_hand_candidates()`'s ordered side loop. The new focused regression `REF-02` `.testbed/tests/test_CameraTracking.gd::test_frame_normalization_single_reacquired_candidate_chooses_nearest_locked_side_without_left_bias()` proves the real seam directly: tracked → stale → tracking_lost → one-candidate reacquire with both pose wrists present and only the right-hand sample visible. Before the repair, the left lane could steal that sole candidate because it was visited first; after the repair, the right locked side wins because it is actually nearest.

Landed the smallest owner-correct fix in `REF-02` only: `CameraTrackingFrame.gd` now batches eligible side-assignment requests for each association phase and resolves them by **global nearest distance** instead of hardcoded left-before-right iteration. That keeps the earlier pose-side lock repair intact while removing the remaining single-candidate reacquire bias. No YAMLs were touched; no punch threshold tuning was widened. Validation run from `REF-02` repo root: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/test_CameraTracking.gd -gunit_test_name=single_reacquired_candidate -gexit` ✅ (`1/1` passed, `6` asserts) and `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/test_CameraTracking.gd -gunit_test_name=preserves_pose_side_lock_across_tracking_lost_reacquire -gexit` ✅ (`1/1` passed, `9` asserts). Upstream commit pushed: `38d38b2` - `Fix single-candidate hand reacquire side bias`.

---

### Task 10Q: QA paused replay debugging + side-ownership behavior after the new repairs

**Bead ID:** `aerobeat-input-camera-tracking-35y.3`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`
**Prompt:** After Tasks 10O and 10P complete, verify the boxing proving-scene paused replay debugging flow end to end. Confirm that pausing preserves truthful inspector/debug values, the event payload snapshot line is gone, the detected-event window can be intentionally scrolled while paused without snap-back, pause/resume no longer restarts the tracking session, and paused-only frame-step buttons plus keyboard left/right stepping work as intended. Also validate the latest left/right hand-side ownership behavior against Derrick's observed left-punch replay case and record whether the side-flash is resolved, reproduced with a sharper explanation, or still blocked. Capture exact repro steps and truthful results. Claim the bead on start and leave clear evidence in the plan.

**Folders Created/Deleted/Modified:**
- validation-only use of relevant `.testbed` project(s) and capture artifacts as needed
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/` (gitignored QA probes + reports)

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/task10q_pause_probe.gd` (gitignored)
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/task10q_side_trace.gd` (gitignored)
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/left/pause_probe.json` (gitignored)
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/left/side_trace.json` (gitignored)
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/left/report.json` / `report.md` (gitignored)
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/right/side_trace.json` (gitignored)
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/right/report.json` / `report.md` (gitignored)
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/input-unit-rerun.log` (gitignored)
- `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/tool-single-reacquire.log` / `tool-pose-lock.log` (gitignored)

**Status:** ✅ Complete

**Results:** QA completed with fresh repo-local validation and deterministic proving/replay probes. Artifacts live under `.testbed/test-results/task10q-qa-captures/2026-06-04-211034/` (gitignored).

- **Environment note / repro hazard:** the first focused GUT pass surfaced the known boxing YAML tab-indentation hazard (`assets/boxing.camera_tracking.yaml`, `assets/boxing.gesture_detection.yaml`) in the local checkout. I restored both from `HEAD` outside Godot via `git restore --source=HEAD -- ...` before rerunning. Final tracked repo state was clean.
- **Repo-local unit coverage:** `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` → **11/11 passed** on rerun (`input-unit-rerun.log`). This directly revalidated the paused inspector freeze behavior, the removed `Event payload snapshot` line, and paused-only playback-step button enablement.
- **Upstream side-ownership regression coverage:** in `REF-02`, `test_frame_normalization_single_reacquired_candidate_chooses_nearest_locked_side_without_left_bias` and `test_frame_normalization_preserves_pose_side_lock_across_tracking_lost_reacquire` both passed (`tool-single-reacquire.log`, `tool-pose-lock.log`).
- **Deterministic proving captures:** reran `capture_fixture_proving.gd` against `REF-05` left/right boxing fixtures. JSON/Markdown reports were produced under `left/` and `right/`; headless screenshots failed under the dummy renderer (`Parameter "t" is null`) but the replay/state reports were still written truthfully.
- **Paused replay debugger truthfulness / removed payload line / manual scroll / pause-resume behavior / paused-only stepping:** the left-fixture pause probe (`left/pause_probe.json`) showed:
  - while replay was **playing**, step buttons were disabled
  - after toggling to **paused**, step buttons became enabled and the inspector body stayed frozen/truthful
  - paused replay time/frame stayed fixed at **0.8s / frame 60** across a 600 ms wait (`paused_time_initial == paused_time_after_wait`, `paused_frame_index_initial == paused_frame_index_after_wait`)
  - the inspector body stayed byte-stable while paused and did **not** contain `Event payload snapshot`
  - the detected-event panel manual scroll position stayed fixed while paused (`scroll_before == scroll_after == 628.0`), so it did not snap back to the top
  - paused button + keyboard stepping changed the paused playback cursor, and those controls were only enabled in the paused state
  - after resume, playback continued forward from the stepped paused position (`3.066...s -> 4.233...s`) instead of jumping back to startup, which matches the intended “no stale restart-looking debug state” behavior
- **Specific left-punch wrong-side-flash concern:** fresh side traces (`left/side_trace.json`, `right/side_trace.json`) plus the upstream regression tests give materially stronger evidence that the single-candidate reacquire bias is fixed. In the left replay trace, there were **no valid samples** where the normalized **left** lane was reassigned to a valid **right-labeled** source. The only non-left `source_label` cases for the left lane were blank/invalid frames during a brief `tracking_lost` gap at **3669 / 3691 / 3734 ms**, followed by correct left-lane reacquire by **3756 ms**. That means the earlier brief wrong-side flash now appears **resolved at the normalized hand-ownership layer**. If Derrick still sees a visible flash in a separate UI path, the stronger remaining explanation is raw-handedness/debug-label presentation or another display seam, not the old upstream left-bias reacquire bug.
- **Out-of-scope but relevant truth:** the left/right proving captures still produced only `guard_*` events rather than matching all gold punch windows. I did **not** widen into threshold tuning; for this QA slice, the trustworthy pass/fail evidence for side ownership came from the paused replay probe, the side traces, and the focused upstream ownership tests.

---

### Task 10R: Design truthful paused replay stepping across video + camera-tracking ownership layers

**Bead ID:** `aerobeat-input-camera-tracking-35y.4`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-02`, `REF-07`, `REF-08`
**Prompt:** Design the owner-correct replay stepping solution for boxing proving replay. Start from the current truthful diagnosis: the proving harness only performs paused timestamp seeks, not actual one-frame stepping. Audit the current replay stack across `aerobeat-tool-video-player`, `aerobeat-vendor-godot-video`, and `aerobeat-tool-camera-tracking` to determine what transport/control surface exists today, whether Godot/.ogv can support exact decoded-frame stepping in this stack, and where the new primitive must live. Produce a sharp design for a real solution rather than a proving-harness approximation, including API shape, ownership boundaries, fallback behavior if exact frame stepping is impossible for some sources, and the validation seam. Claim the bead on start and stop once the plan is updated with the proven design and the next narrow implementation slices.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** Completed the cross-repo replay transport audit and locked the owner-correct design for truthful paused replay stepping.

Audit findings by layer:
- `REF-01` proving harness is still only doing paused timestamp nudges, not frame stepping. Evidence path: `.testbed/scripts/proving_harness.gd::_request_playback_frame_step()` computes `target_sec = current_time_sec +/- _playback_frame_step_seconds()`, calls `_playback_controller_seek(target_sec)`, then pauses again. No frame index or decoder-owned step primitive is involved.
- `REF-01` replay wrapper still restarts the tracking lane for pause/seek. Evidence path: `src/AeroCameraTracking.gd::pause_replay_playback()` calls `provider.stop(true)`, `seek_replay_playback(seconds)` mutates `_replay_position_sec` / `_replay_loop_origin_sec` and immediately calls `play_replay_playback()`, while `set_replay_playback_transport_request()` and `get_replay_playback_backend()` are still stubs. This proves the current owner repo has no real replay transport delegation yet.
- `REF-02` camera-tracking tool currently exposes **status only**, not replay transport. Evidence path: `src/CameraTrackingBackend.gd` only defines `get_playback_status()`, `src/CameraTracking.gd` only mirrors that dictionary via `get_playback_status()`, and `src/CameraTrackingPreviewPresenter.gd::get_playback_status_snapshot()` only reads the passive status surface. There are no public `play/pause/seek/step/frame-index` methods in the tool repo today.
- `REF-07` video owner stack currently owns generic lifecycle + time seek, but no frame-addressed transport. Evidence path: `src/AeroVideoPlayerBackend.gd` only defines `load/play/pause/stop/unload/seek/set_loop/set_rate/set_fit_mode/set_audio_level`, and `src/AeroVideoPlayerManager.gd` only forwards those methods. There is no `step_frames`, `seek_frame`, `get_transport_capabilities`, or frame cursor/status contract.
- `REF-08` Godot video vendor is currently a timestamp-seek backend only. Evidence path: `src/AeroGodotVideoBackend.gd` implements playback via Godot `VideoStreamPlayer` / `VideoStreamTheora`, mutates `paused` and `stream_position`, and reports position/duration state; there is no decoded-frame callback, frame index, reverse-step, or seek-by-frame primitive in this backend surface. The verified media target in this repo is `.ogv`, and the implementation only proves Godot built-in `.ogv` play/pause/seek-by-time.

Design conclusion / exactness contract:
- The **primitive must live first in the video owner stack** (`REF-07` facade + `REF-08` vendor backend surface), because decoded media transport ownership belongs there, not in the boxing proving harness and not in `REF-02` camera-tracking UI code.
- `REF-02` should then expose that transport upward as camera-tracking replay ownership, but must not invent its own fake frame step by restarting sessions around timestamp seeks.
- Current Godot built-in `.ogv` in this stack **cannot truthfully promise exact decoded-frame stepping or exact reverse stepping**. The present backend only proves time seeks (`stream_position`) and paused/play state. So the contract must advertise capability tiers instead of pretending every backend can do exact frame stepping.

Locked transport design:
1. **New video-owner transport contract in `REF-07`:**
   - extend `AeroVideoPlayerBackend.gd` and `AeroVideoPlayerManager.gd` with replay-transport primitives:
     - `get_transport_capabilities(slot_name := "") -> Dictionary`
     - `get_transport_status(slot_name := "") -> Dictionary`
     - `step_frames(delta_frames: int, slot_name := "") -> Dictionary`
     - `seek_to_frame(frame_index: int, slot_name := "") -> Dictionary`
   - `get_transport_status()` should carry a stable frame-cursor payload when the backend can prove it, e.g.:
     - `transport_mode`: `exact_decoded_frame` | `exact_owned_frame_index` | `approx_time_seek`
     - `can_step_forward`, `can_step_backward`, `can_seek_frame`
     - `frame_index` (nullable/absent when unprovable)
     - `frame_count` (nullable/absent when unprovable)
     - `nominal_fps` / `frame_duration_sec` when known
     - `paused`, `position_sec`, `duration_sec`, `source`
     - `exactness_note` / `limitation_code`
   - `step_frames()` and `seek_to_frame()` must return an explicit failure code when exact frame addressing is unavailable instead of silently converting into timestamp seeks.

2. **Capability tiers are explicit and truthful:**
   - `exact_decoded_frame`: backend owns a real decoded-frame cursor and can step to adjacent decoded frames exactly.
   - `exact_owned_frame_index`: backend cannot prove decoder-native stepping but does own a stable frame index contract (for example a vendor-owned indexed frame source/cache) and can step that index exactly.
   - `approx_time_seek`: backend can only move by timestamp. This is the truthful status of the current `REF-08` Godot `.ogv` path.

3. **`REF-08` Godot vendor behavior for current `.ogv`:**
   - in the current implementation slice, `AeroGodotVideoBackend` should report `transport_mode = approx_time_seek`, `can_seek_frame = false`, `can_step_forward = false`, and `can_step_backward = false` for exact frame stepping.
   - If Derrick later wants exact frame stepping for `.ogv`, that requires a **different lower-level vendor implementation** than the current `VideoStreamPlayer` + `VideoStreamTheora` path (for example a vendor-owned indexed/frame-cached replay path). It is not something the current Godot built-in backend can honestly fake.

4. **Camera-tracking ownership in `REF-02`:**
   - add a public replay-transport surface to `CameraTrackingBackend.gd` / `CameraTracking.gd` that mirrors the video-owner contract instead of only surfacing passive playback status:
     - `get_replay_transport_capabilities()`
     - `get_replay_transport_status()`
     - `step_replay_frames(delta_frames: int)`
     - `seek_replay_to_frame(frame_index: int)`
   - `get_playback_status()` can remain as the lightweight status snapshot, but frame-addressed replay must move to the new explicit transport methods.
   - `AeroCameraTracking.gd` should stop using `pause_replay_playback() -> provider.stop(true)` plus `seek_replay_playback() -> play_replay_playback()` as its paused-step mechanism. Instead it should delegate to the real replay transport when available and preserve one loaded paused session/cursor.

5. **Fallback behavior / UI contract:**
   - if the active replay transport reports `approx_time_seek`, the boxing proving scene must not present left/right arrows as truthful one-frame controls. It may either disable exact step controls or relabel them as non-exact time nudges, but it must not overclaim frame stepping.
   - exact paused frame stepping UI should only be enabled when `can_step_forward` / `can_step_backward` are true from the public transport capability surface.

Key blocker discovered and documented sharply:
- Full **video + tracking** truth will still require a matching frame-addressed replay seam below the camera-tracking service. The present replay/tracking vendor path outside this three-repo audit still starts replay by timestamp (`start_time_sec`) and, in the Python runtime, rewinds via OpenCV `CAP_PROP_POS_MSEC`, not by owned frame index. So `10S/10T` can and should fix the public owner layers first, but literal end-to-end tracking-frame exactness remains blocked until the underlying tracking vendor path also grows a compatible frame-index transport or the replay source owner is unified beneath both presentation and tracking. This is the real blocker; the proving harness should not keep papering over it.

Concrete next seams:
- **Task 10S (`REF-07` + `REF-08`):** land the new replay-transport contract in the video owner stack, including manager/backend API additions, transport capability/status payloads, and a truthful `approx_time_seek` capability implementation in `AeroGodotVideoBackend` for current `.ogv`. Add focused tests proving the manager exposes the new contract and that the Godot backend explicitly refuses exact frame step/seek-by-frame instead of silently time-seeking.
- **Task 10T (`REF-02`):** expose that transport upward through camera-tracking ownership, replace the current `AeroCameraTracking` paused-step restart/seek approximation with delegation to the new replay transport, preserve paused loaded-session identity, and make the public camera-tracking replay API capability-driven. If exact frame addressing is still unavailable from the active transport, `REF-02` should surface that truthfully so `REF-01` can disable or relabel exact step UI instead of faking it.

Validation strategy:
- `REF-07` unit tests: contract round-trip for `get_transport_capabilities`, `get_transport_status`, `step_frames`, and `seek_to_frame`; explicit unsupported-result assertions for non-exact backends.
- `REF-08` proving/tests: current `.ogv` backend reports `approx_time_seek` and exact-step unsupported codes while preserving honest pause/play/seek-by-time behavior.
- `REF-02` unit tests: paused replay step no longer tears down/restarts the tracking session just to emulate a step; capability/status passthrough is truthful; playback status stays stable across pause/resume when the transport is merely paused.
- Later end-to-end QA (`10U`) should assert either exact frame-index deltas when the active transport can prove them, or explicit documented fallback behavior when it cannot.

---

### Task 10S: Implement truthful replay-step transport in the video owner stack

**Bead ID:** `aerobeat-input-camera-tracking-35y.5`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-07`, `REF-08`
**Prompt:** Implement the owner-correct replay stepping primitive in `aerobeat-tool-video-player` and `aerobeat-vendor-godot-video` if the design proves that lower-level video transport changes are required. The goal is a truthful paused-step capability that advances or rewinds by decoded frame/owned frame index rather than timestamp approximation, or the strongest truthful exactness contract the stack can support if literal decoded-frame stepping is impossible for some formats. Keep this slice in the video owner layers only; do not patch the proving harness to fake it. Claim the bead on start, add focused regression coverage, and document any source-format limitations explicitly.

**Folders Created/Deleted/Modified:**
- owner-correct source/test folders in `REF-07` and `REF-08`

**Files Created/Deleted/Modified:**
- replay/video transport files to be identified during implementation
- focused tests/probes/docs in `REF-07` / `REF-08`
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** Claimed bead `aerobeat-input-camera-tracking-35y.5` with `bd update aerobeat-input-camera-tracking-35y.5 --status in_progress --json`, then kept the implementation slice strictly inside the two video owner repos from `REF-07` and `REF-08`. The landed contract makes replay transport exactness explicit instead of pretending time seek equals frame stepping.

What landed in `REF-07` (`/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-video-player`):
- `src/AeroVideoPlayerBackend.gd` — added the shared transport vocabulary (`exact_decoded_frame`, `exact_owned_frame_index`, `approx_time_seek`), plus default `get_transport_capabilities()`, `get_transport_status()`, `step_frames(...)`, and `seek_to_frame(...)` surfaces with explicit transport-unsupported failures.
- `src/AeroVideoPlayerFakeBackend.gd` — taught the fake owner backend to report `exact_owned_frame_index` truthfully, track a synthetic owned frame index from `fps_hint`/`nominal_fps`, and support exact `step_frames(...)` / `seek_to_frame(...)` for regression coverage.
- `src/AeroVideoPlayerManager.gd` — exposed the new transport APIs on the stable public facade, surfaced backend capability/status payloads per slot, and treated transport refusal as a non-fatal slot error (`last_error` + `slot_error_raised`) rather than poisoning playback state.
- `.testbed/tests/test_AeroVideoPlayerManager.gd` — added focused coverage that proves the fake backend advertises and executes exact owned-frame stepping, and that an injected real Godot backend reports `approx_time_seek` while refusing exact frame stepping/seek-by-frame without leaving READY state.
- `.testbed/tests/test_example.gd`, `README.md`, and `plugin.cfg` — updated repo docs/version assertions to match the new transport contract.
- `.testbed/assets/videos/calm_blue_sea_1.ogv` — replaced a broken cross-repo symlink with the repo-local real sample file from `REF-08` so the owner repo's existing proving tests remain truthful and self-contained.

What landed in `REF-08` (`/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-video`):
- `src/AeroGodotVideoBackend.gd` — added truthful transport capability/status reporting for the current built-in Godot `.ogv` path, surfaced informational fps/frame-duration metadata when available, and made `step_frames(...)` / `seek_to_frame(...)` fail explicitly with `backend_transport_unsupported` instead of silently time-seeking.
- `src/AeroGodotVideoBackendFactory.gd` — bumped the factory version for the new contract.
- `.testbed/tests/test_AeroGodotVideoBackendFactory.gd` — added focused regression coverage proving the real backend advertises `approx_time_seek`, leaves `frame_index` unknown, and refuses exact frame-addressed operations without moving playback time.
- `README.md` — documented the truthful transport tier and the explicit `.ogv` limitation.

Exact validation performed:
- `cd /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-vendor-godot-video && godot --headless --path .testbed --import && godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` ✅ (`19/19` tests passed, `190` asserts)
- `cd /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-video-player && godot --headless --path .testbed --import && godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` ✅ (`20/20` tests passed, `209` asserts)

Commits pushed:
- `REF-07`: `8dfbf89` — `Add truthful video transport contract`
- `REF-08`: `67ebe03` — `Report truthful Godot video transport capabilities`

Limitations left explicit on purpose:
- The current built-in Godot `.ogv` owner path still only supports `approx_time_seek`; it does **not** expose literal decoded-frame stepping or a trustworthy current frame index, and the new API now says so plainly.
- This slice does **not** yet expose the new transport contract through camera-tracking replay ownership (`10T`), so end-to-end boxing replay stepping remains blocked on the next owner layer.

---

### Task 10T: Expose truthful replay stepping through camera-tracking replay ownership

**Bead ID:** `aerobeat-input-camera-tracking-35y.6`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-02`, `REF-07`, `REF-08`
**Prompt:** After the video-owner primitive exists, expose that truthful paused-step capability through `aerobeat-tool-camera-tracking` and the camera-tracking replay surface consumed by the proving scene. Replace the current timestamp-seek approximation path with the new replay-step transport while preserving pause/play/seek behavior for existing consumers. Keep this slice focused on replay ownership boundaries and public camera-tracking transport, not proving-scene-only hacks. Claim the bead on start, add focused regression coverage, and update the plan with the exact public API and validation.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/tests/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTrackingBackend.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTracking.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/src/CameraTrackingPreviewPresenter.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/.testbed/tests/test_CameraTracking.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** Landed the camera-tracking replay transport exposure layer in `REF-02` without widening into consumer migration. `CameraTrackingBackend.gd` now defines the public replay transport vocabulary/result shape plus a truthful `approx_time_seek` fallback derived from existing replay playback status. `CameraTracking.gd` now exposes `get_replay_transport_capabilities()`, `get_replay_transport_status()`, `step_replay_frames(...)`, and `seek_replay_to_frame(...)`, delegates exact transports when a backend overrides them, and keeps unchanged consumers on the existing playback-status seam. `CameraTrackingPreviewPresenter.gd` now mirrors replay transport capability/status snapshots for downstream debug/proving UIs, and `test_CameraTracking.gd` adds regression coverage for both the derived approximate fallback and an exact delegated fake transport while preserving the existing vendor replay/start-stop proof. Validation: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-camera-tracking` (35/35 passing). Commit: `a3fb78c` (`Expose truthful replay transport through camera tracking`) pushed to `origin/main` in `REF-02`. Limitation left explicit for `10V`: the current shipped MediaPipe replay path still only proves `transport_mode=approx_time_seek`, so proving-scene consumers must use the new capability/status surface to disable or relabel exact frame-step UX instead of assuming exact stepping exists.

---

### Task 10V: Migrate aerobeat-input-camera-tracking proving/testbed consumers to the new replay transport model

**Bead ID:** `aerobeat-input-camera-tracking-35y.8`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-07`, `REF-08`
**Prompt:** After camera-tracking exposes the new replay transport, update the `aerobeat-input-camera-tracking` testbed/proving scene consumers to use the new transport/capability model instead of the old paused timestamp-seek path. The boxing proving scene UI should reflect the truth: enable real frame-step controls only when the replay source reports an exact supported stepping tier, and otherwise show the explicit fallback/unsupported behavior rather than pretending exact frame stepping exists. Use `godotenv-sync` for refresh/sync work instead of the plain `godotenv` CLI to avoid UID/churn noise. Keep YAML edits outside Godot. Claim the bead on start, add focused proof, and update this plan with exact files, validation, and commits.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.testbed/scenes/`
- `.testbed/scripts/`
- `.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_proving_harness_trails.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`

**Status:** ✅ Complete

**Results:** Migrated the proving/testbed replay consumer to the truthful replay transport surface from `REF-02` without widening into deeper vendor exactness work. `proving_harness.gd` now reads replay transport capabilities/status from the active tracking session, keeps play/pause/time-seek behavior unchanged for normal replay use, and only enables paused left/right frame-step controls when the transport honestly reports `transport_mode=exact_owned_frame_index` plus per-direction step support. When the active replay path is still the shipped approximate MediaPipe/Godot flow (`transport_mode=approx_time_seek`), the step buttons stay disabled and the boxing/proving UI now shows an explicit fallback message instead of pretending timestamp seeks are exact frame steps. Focused proof landed in `test_proving_harness_trails.gd` for both the approximate fallback and an exact delegated fake transport, and `test_boxing_proving_harness_profiles_and_debug.gd` was updated so its paused-button expectation now seeds exact transport support explicitly instead of relying on the old paused-only assumption. Validation: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gselect=test_proving_harness_trails.gd -gexit` (35/35 passing) and `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gselect=test_boxing_proving_harness_profiles_and_debug.gd -gexit` (11/11 passing). A broader all-unit run still hit the pre-existing flaky preview JPEG load error in `test_boxing_proving_scene_no_longer_has_in_scene_profile_picker_controls`, unrelated to this transport slice. Commit: `11c2bfb` (`Truthfully gate replay frame stepping in proving harness`). Remaining limitation: the current shipped MediaPipe replay path still reports `approx_time_seek`, so the truthful UX for this slice is disabled exact-step controls plus explicit fallback messaging until a lower layer can prove exact frame-addressed replay.

---

### Task 10U: QA truthful frame stepping end to end in boxing proving replay

**Bead ID:** `aerobeat-input-camera-tracking-35y.7`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-02`, `REF-05`, `REF-06`, `REF-07`, `REF-08`
**Prompt:** Verify the new replay stepping behavior end to end in boxing proving replay. Confirm whether paused left/right stepping now advances and rewinds by truthful single-frame increments for the relevant replay sources, or else verify the exact documented fallback behavior if the stack cannot provide literal decoded-frame stepping for some sources. Capture exact repro steps, observed frame/time/index behavior, and any remaining source-format caveats. Claim the bead on start and leave clear evidence in the plan.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/`
- validation-only use of relevant testbed/project repos and capture artifacts as needed

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/task10u-summary.md`
- `.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/task10u-summary.json`
- `.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/boxing_replay_transport_playback_state_probe.json`
- `.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/boxing_replay_transport_probe_rerun.gd`

**Status:** ✅ Complete

**Results:** This bead opened as a real QA failure on 2026-06-04, but a focused rerun after Task 10Y (`7888e78`, documented in follow-up plan commit `c8cd691`) now clears the replay-transport QA slice truthfully.

Latest rerun steps (2026-06-05): (1) `bd update aerobeat-input-camera-tracking-35y.7 --status in_progress --json`; (2) `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`; (3) `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd,res://tests/unit/test_aero_camera_tracking.gd -gexit` ✅ (`62/62` passing, `349` asserts; only existing orphan/RID leak noise remained); (4) focused runtime probe `godot --headless --path .testbed --script ../.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/boxing_replay_transport_probe_rerun.gd`, which refreshed `.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/task10u-summary.md`, `.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/task10u-summary.json`, and `.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/boxing_replay_transport_playback_state_probe.json`.

Observed boxing proving truth from the shipped replay path (`REF-02`, `REF-07`, `REF-08`) remains intentionally approx-only and is now surfaced honestly end to end: `transport_mode=approx_time_seek`, `can_step_forward=false`, `can_step_backward=false`, `can_seek_frame=false`, `frame_index=null`, `frame_count=null`, `limitation_code=backend_transport_unsupported`. The boxing proving scene still consumes that capability/status surface truthfully: the step UI rendered `Frame step unavailable (approx_time_seek). This backend exposes replay time/paused status for video-file sessions but does not prove exact frame-addressed stepping.`, both step buttons stayed disabled, and a direct step request returned `backend_transport_unsupported` with `step_replay_frames requires exact frame-addressed replay transport, but this backend only supports approx_time_seek.` That means the shipped replay path is now honest about the fallback/unsupported exact-step seam instead of pretending single-frame stepping exists.

The previously blocking normal transport behavior now passes in the headless boxing-scene probe:
- pause held truthfully at `current_time_sec≈1.4667` with controller `state=paused` and transport `paused=true`
- hold while paused stayed fixed at the same `≈1.4667s`
- seek while paused jumped to `current_time_sec=4.6` and remained truthfully paused (`state=paused`, `paused=true`) both immediately and after settle
- resume resumed from the new seek target, advancing from `4.6s` to `5.4s` with controller `state=playing` and transport `paused=false`

Current QA truth from the refreshed probe artifacts:
- `scene_consumes_transport_surface=true`
- `exact_step_ui_truthful_for_shipped_path=true`
- `pause_persists_in_headless_boxing_probe=true`
- `seek_while_paused_preserves_pause=true`
- `resume_restores_playback=true`
- `shipped_path_exact_support_proven_end_to_end=false`

Final QA truth: this now **does** satisfy the current replay-transport plan slice for wrap-up. The bar was not to magically prove exact decoded-frame stepping on real shipped `.ogv`/MediaPipe replay sources; it was to use the new replay transport functionality truthfully. The boxing proving scene now does that: it reports the shipped path as `approx_time_seek` with disabled exact step controls, and its normal play/pause/time-seek behavior is now truthful end to end on that shipped path.

---

### Task 10W: Repair boxing proving replay pause-hold behavior after transport migration

**Bead ID:** `aerobeat-input-camera-tracking-35y.9`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-07`, `REF-08`
**Prompt:** QA proved that the boxing proving scene now consumes the new replay transport truthfully, but end-to-end in-scene pause does not hold the controller in a paused state on the shipped replay path even though lower-layer pause semantics still pass in isolation. Repair that boxing-scene replay pause-hold seam without reintroducing fake frame-step assumptions. Keep the slice focused on the consumer/transport integration path that leaves replay effectively playing after an in-scene pause request. Use `godotenv-sync` for any refresh work, keep YAML edits outside Godot, add focused proof, and update this plan with the exact root cause, validation, and commits.

**Folders Created/Deleted/Modified:**
- `.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_proving_harness_trails.gd`
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`

**Status:** ✅ Complete

**Results:** Root cause proved to be in the proving consumer (`REF-01`), not the lower replay owners (`REF-02`, `REF-07`, `REF-08`). After the transport migration, `_refresh_playback_status(true)` still flows back through `_load_playback_source_if_needed()`, whose autoplay branch will resume any loaded replay that is “not playing.” A manual in-scene pause correctly drove the singleton/session into paused state, but the proving harness could immediately re-arm playback during its own post-pause refresh path, so end-to-end boxing replay looked like it never stayed paused even though owner-layer pause preservation tests still passed in isolation. The repair stayed tightly on that consumer seam: `proving_harness.gd` now tracks a `_playback_pause_hold` latch set by manual pause and cleared on explicit play or fresh source/visibility reloads, and the autoplay branch now honors that latch instead of auto-resuming a user-paused replay. Added focused proof in `test_proving_harness_trails.gd::test_replay_pause_hold_blocks_refresh_autoplay_after_user_pause`, which forces the exact stale-autoplay condition and verifies a post-pause refresh leaves the replay controller paused. Validation: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit` → 114/114 passing (existing GUT orphan/RID leak warnings unchanged). Commits: `c74b042` - `Hold proving replay pause across transport refresh`. Remaining limitation: this only fixes pause-hold at the proving consumer seam; the shipped replay path still truthfully reports `approx_time_seek`, so exact frame stepping remains unavailable until a lower owner can prove it.

---

### Task 10X: Repair remaining shipped replay pause-state reporting seam in boxing proving flow

**Bead ID:** `aerobeat-input-camera-tracking-35y.10`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-07`, `REF-08`
**Prompt:** QA rerun after Task 10W proved that the boxing proving scene now reports replay transport fallback truthfully, but the shipped replay path still does not hold/report a paused state end to end: after in-scene pause, controller and transport status still say `state=playing` / `paused=false` even while time appears held. Diagnose and repair that remaining shipped replay pause-state seam without widening into exact-frame transport work. Keep scope tightly on the consumer/owner integration path that leaves scene-visible playback state inconsistent with actual held replay state. Use `godotenv-sync` for refresh if needed, keep YAML edits outside Godot, add focused proof, and update this plan with the exact root cause, validation, commits, and any remaining limitation.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- `.testbed/`
- `src/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.plans/mediapipe-python/artifacts/task10x-replay-pause-state-repair/boxing_replay_pause_state_probe.gd`
- `.plans/mediapipe-python/artifacts/task10x-replay-pause-state-repair/boxing_replay_pause_state_probe.json`
- `.plans/mediapipe-python/artifacts/task10x-replay-pause-state-repair/task10x-summary.json`
- `.plans/mediapipe-python/artifacts/task10x-replay-pause-state-repair/task10x-summary.md`
- `.testbed/tests/unit/test_aero_camera_tracking.gd`
- `src/AeroCameraTracking.gd`

**Status:** ✅ Complete

**Results:** Root cause was a stale replay-status seam at the input-owner wrapper in `REF-01`, not a new transport-capability issue in `REF-02` / `REF-07` / `REF-08`. `AeroCameraTracking` refreshes its public replay status from `CameraTracking.get_playback_status()`, but `CameraTracking` only refreshes backend playback/transport snapshots while its state is `running`; once the shipped replay pause path stops the session while preserving runtime state, the tracking-session contract can keep returning the last cached `state=playing` / `paused=false` snapshot even though time is now held. That meant the proving scene could honestly show `approx_time_seek` transport fallback after Task 10W while still publishing a false playing-state snapshot after in-scene pause.

The repair stayed tightly on the consumer integration seam in `REF-01`. `src/AeroCameraTracking.gd` now (1) preserves a local paused replay truth when the wrapper is already paused, the replay is still loaded, and the tracking session is no longer actively running replay even if the stale cached status still says `playing`; and (2) exposes wrapper-owned `get_replay_transport_capabilities()` / `get_replay_transport_status()` so proving consumers prefer the wrapper’s corrected paused/position truth while still preserving the lower-layer truthful fallback/capability model (`transport_mode=approx_time_seek`, `limitation_code=backend_transport_unsupported`, no fake exact stepping). Focused proof landed in `.testbed/tests/unit/test_aero_camera_tracking.gd::test_aero_camera_tracking_pause_preserves_paused_public_state_when_tracking_session_status_stays_stale_playing`, which reproduces the exact shipped seam with an idle tracking session that still reports cached `playing` status and proves both public controller state and replay transport status stay paused.

Validation rerun for this slice:
- `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` ✅
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_aero_camera_tracking.gd -gexit` ✅ (`14/14` tests, `87` asserts)
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_proving_harness_trails.gd -gexit` ✅ (`36/36` tests, `168` asserts)
- `godot --headless --path .testbed --script ../.plans/mediapipe-python/artifacts/task10u-replay-transport-qa/boxing_replay_transport_probe_rerun.gd` ✅; copied focused evidence into `.plans/mediapipe-python/artifacts/task10x-replay-pause-state-repair/`. The headless probe now shows the original blocker repaired: paused controller state and paused transport status both hold truthfully at `1.4333s` (`state=paused`, `paused=true`) while fallback transport reporting remains `approx_time_seek`.

Commits for this slice: `1664cd1` (`Fix replay pause-state reporting seam`) landed the wrapper fix, regression test, and Task 10X probe artifacts; `c18ebd4` (`Document Task 10X replay pause-state repair`) finalized the plan record for this slice.

Remaining limitation: this slice intentionally did **not** widen into paused-seek/resume semantics. The same headless probe still shows `seek_replay_playback()` re-enters play on the shipped approx-time path, so `seek_while_paused_preserves_pause` and the subsequent `resume_restores_playback` truth checks remain false. That is a separate replay-seek behavior seam beyond this pause-state reporting repair.

---

### Task 10Y: Repair shipped approx-time paused-seek/resume semantics in boxing proving replay

**Bead ID:** `aerobeat-input-camera-tracking-35y.11`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-07`, `REF-08`
**Prompt:** After Task 10X, the shipped replay path now reports paused state truthfully while held, but QA evidence still shows that paused seek on the `approx_time_seek` path re-enters play and leaves no truthful paused state for subsequent resume. Repair the shipped approx-time paused-seek/resume semantics without pretending exact frame stepping exists. Keep scope tightly on the consumer/owner integration path for pause → seek while paused → resume behavior, preserve the truthful fallback transport model, use `godotenv-sync` for any refresh work, keep YAML edits outside Godot, add focused proof, and update this plan with the exact root cause, validation, commits, and any remaining limitation.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/tests/unit/test_aero_camera_tracking.gd`
- `src/AeroCameraTracking.gd`

**Status:** ✅ Complete

**Results:** Root cause confirmed in the owner/input wrapper from `REF-01`: `AeroCameraTracking.seek_replay_playback()` always delegated to `play_replay_playback()` after updating `_replay_position_sec` and `_replay_loop_origin_sec`. On the shipped `approx_time_seek` fallback path, a paused seek therefore always restarted replay and exposed a stale/playing transport surface instead of preserving truthful paused semantics for the subsequent resume seam.

Fix landed narrowly in `src/AeroCameraTracking.gd`: the wrapper now records whether replay was already playing before the seek, restarts the replay at the new approx-time position as before, and immediately re-applies `pause_replay_playback()` when the seek originated from a paused state. That preserves the existing truthful fallback transport/capability model, keeps `approx_time_seek` honest about not being exact frame stepping, and makes the next resume use the newly-seeked `start_time_sec` / `loop_start_time_sec` rather than the pre-seek hold position.

Focused proof landed in `.testbed/tests/unit/test_aero_camera_tracking.gd` via `PausedSeekResumeTrackingSession` plus `test_aero_camera_tracking_paused_approx_seek_stays_truthfully_paused_and_resume_uses_new_position()`. The regression reproduces the stale-playing approx-time transport seam, verifies that pause → seek while paused still reports `state=paused` / `paused=true` at the new position, and then verifies that a later resume restarts from that new position.

Validation:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_aero_camera_tracking.gd -gexit` ✅ (`15/15` tests, `104` asserts)
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` ✅ (`117/117` tests, `710` asserts; pre-existing orphan/RID leak warnings still present in testbed shutdown)

Commits for this slice: `7888e78` (`Fix paused replay seek resume seam`).

Remaining limitation: this slice keeps the current fallback transport honest but does not invent exact stepping. Paused seek on `approx_time_seek` now remains truthfully paused and resumes from the seek target, but seek precision is still bounded by the existing approximate time-based replay transport in the owner/tool/video layers.

---

### Task 10Z: Diagnose and repair the straight-punch gold-truth mismatch after replay-transport completion

**Bead ID:** `aerobeat-input-camera-tracking-35y.12`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-02`, `REF-05`, `REF-06`
**Prompt:** The replay-transport slice is now truthful, so return to the older unresolved blocker from Task 10: end-to-end straight-punch detection still misses all gold-truth windows on the left/right fixture replays. Start from the existing QA evidence and traces in `.testbed/test-results/task10-qa-captures/2026-06-04-063854/`. Diagnose the narrowest real cause or first dominant cause among startup timing, positive-growth count accumulation, bbox growth thresholds, fresh-sample gating, and/or replay-cadence interactions. Implement only the smallest owner-correct repair or tuning seam you can prove against the fixtures, then update this plan with exact evidence, validation, commits, and any remaining mismatch. Keep YAML edits outside Godot and use `godotenv-sync` if refresh work is needed.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.testbed/test-results/`
- owner-correct source/test folders in `REF-01` / `REF-02` only if proven necessary

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- `.testbed/test-results/task10z-fresh-sample-rerun/left/straight_punch_trace.json`
- `.testbed/test-results/task10z-fresh-sample-rerun/right/straight_punch_trace.json`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `src/detectors/pose_detector_substrate.gd`

**Status:** ⚠️ Partial

**Results:** Claimed the bead with `bd update aerobeat-input-camera-tracking-35y.12 --status in_progress --json` and started from the failing QA evidence in `.testbed/test-results/task10-qa-captures/2026-06-04-063854/`.

Exact evidence gathered:
- The original straight-punch traces still never reached `triggered`, and the per-side debug topped out at `positive_growth_samples=1`.
- The proving-report state timelines showed the pose-side forward-velocity signal *did* spike inside the later gold windows, which ruled out replay transport as the current blocker:
  - left fixture: `9.32 @ 2586ms`, `3.96 @ 3741ms`, `7.81 @ 5019ms`
  - right fixture: `2.51 @ 1880ms`, `2.31 @ 3190ms`, `17.17 @ 4582ms`
- That exposed a truth bug in `REF-01`: `_is_fresh_tracking_hand_sample()` treated any `tracking_state == "tracked"` payload as fresh, even if the underlying hand observation had not advanced. Under replay cadence, duplicate tracked payloads were therefore appended as new straight-punch history.

Landed repair:
- `src/detectors/pose_detector_substrate.gd`: straight-punch fresh-sample gating now requires an advanced hand observation (`frame_index`, `timestamp_seconds`, or a last-resort bbox-area change fallback) before bbox-growth history is updated.
- `.testbed/tests/unit/test_pose_detector_substrate.gd`: added `test_straight_punch_dedupes_replayed_tracked_samples_until_hand_frame_advances()` and extended the test hand-payload helper so duplicate replay samples can be proven non-fresh.

Validation:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit` ✅ (`18/18` passed)
- `/home/derrick/.openclaw/workspace/scripts/godotenv-sync --repo /home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` ✅
- Reran the focused straight-punch traces into `.testbed/test-results/task10z-fresh-sample-rerun/left/straight_punch_trace.json` and `.testbed/test-results/task10z-fresh-sample-rerun/right/straight_punch_trace.json` ✅

Post-fix truth:
- The fresh-sample seam is now owner-correct, but the fixture replays still miss every gold window end to end.
- The rerun traces still top out at `positive_growth_samples=1`, and the target-side bbox growth remains far below the current YAML threshold (`0.006`):
  - left later-window max growths ≈ `0.000187`, `0.000147`, `0.000385`
  - right later-window max growths ≈ `0.000157`, `0.000148`, `0.001152`
- The remaining blocker is now narrower and clearer: replay cadence no longer lies about hand-sample freshness, but the current trigger still depends on same-sample hand-growth + instantaneous wrist-velocity coincidence that these fixture replays do not reliably produce. The next seam is still-open velocity/growth windowing or tuning, not replay transport.

Commits:
- `1b77be0` — `Fix straight-punch fresh sample truth gating`

Remaining mismatch: no `punch_left` / `punch_right` event lands inside the gold windows yet, so Task 10Z is not audit-ready.

---

### Task 10AA: Repair straight-punch trigger windowing/tuning against replay fixture magnitudes

**Bead ID:** `aerobeat-input-camera-tracking-35y.13`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-01`, `REF-05`, `REF-06`
**Prompt:** After Task 10Z fixed fresh-sample truth, the remaining dominant blocker is that the trigger still requires same-sample hand-growth plus instantaneous wrist-velocity coincidence, while replay-fixture bbox growth magnitudes remain far below the current YAML threshold. Starting from the fresh-sample rerun traces under `.testbed/test-results/task10z-fresh-sample-rerun/`, implement the smallest owner-correct windowing and/or threshold tuning seam that can be proved against the replay fixtures without widening into unrelated transport work. Keep YAML edits outside Godot, use `godotenv-sync` if refresh work is needed, add focused proof/tests/probes, and update this plan with exact evidence, validation, commits, and any remaining mismatch.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `.testbed/test-results/`
- `assets/` and detector/test folders in `REF-01` only if proven necessary

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- focused detector/tuning/probe files to be identified during implementation

**Status:** ✅ Complete

**Results:** Landed the smallest owner-correct implementation slice that the replay fixtures actually proved: (1) `REF-01` now keeps a recent positive bbox-growth peak alongside the existing recent wrist-velocity peak so a fresh tracked sample can trigger when growth and velocity land on adjacent replayed hand samples instead of requiring same-sample coincidence; (2) the replay/live provider path now reconfigures the detector substrate against the active runtime config before processing, which fixed the proving path silently running with the baked-in `0.006 / 2` straight-punch defaults after `_ready()` constructed the substrate too early; and (3) the boxing profile YAML was normalized/fixed in-owner (`assets/boxing.gesture_detection.yaml` tuned to `min_positive_growth_samples: 1` and `min_bbox_area_growth: 0.00014`, `assets/boxing.camera_tracking.yaml` indentation repaired so the selected profile bundle loads truthfully during replay). Focused proof: `.testbed/tests/unit/test_pose_detector_substrate.gd` now includes a regression that only passes when recent bbox-growth peak carryover can trigger on a later high-velocity fresh hand sample; `res://tests/unit/test_camera_tracking_config_profiles.gd` re-passed after the profile-YAML repair. Replay evidence was regenerated at `.testbed/test-results/task10aa-windowing-rerun-2026-06-05-providerfix/` using `capture_fixture_proving.gd` plus `task10_straight_punch_trace.gd`. Exact outcome from that rerun: the live replay path finally consumed the tuned boxing profile (`min_bbox_area_growth: 0.00014`, `min_positive_growth_samples: 1` visible in the trace debug), and gold-truth mismatch improved from zero straight-punch detections to one in-window left hit (`left` event at `4848ms` inside the `4833-5088ms` gold window). Remaining mismatch is explicit and still unresolved: left windows `1150-1300`, `2150-2650`, `3333-3833` still missed; right windows `400-600`, `1700-2000`, `3100-3400`, `4400-4900` still missed; replay also emitted false-positive out-of-window punches (`left`: `2774`, `2926`, `4260`, `5985`, `6455`, `6560`, `6675`; `right`: `1367`, `4203`, `5023`). Trace inspection shows the next blocker is no longer raw threshold ownership: several gold windows are spent in `not_ready` / `tracking_lost`, and some velocity/growth peaks still fail to overlap inside the current ready/rearm lifecycle even with the new carry window. Validation run during this slice:
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gexit`
- `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd -gexit`
- replay capture + trace rerun under `.testbed/test-results/task10aa-windowing-rerun-2026-06-05-providerfix/` for both `punch_left` and `punch_right` fixtures.

---

### Task 10AB: Research Godot replay stepping fallback truth for near-frame time seeks

**Bead ID:** `aerobeat-input-camera-tracking-575`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-01`, `REF-02`, `REF-07`, `REF-08`
**Prompt:** Research whether the current Godot video playback path used by this work can truthfully support any acceptable next/previous-step fallback short of exact frame stepping. Be explicit about what the current built-in Godot `.ogv` backend exposes (time seek precision, pause/play semantics, frame index visibility, minimum seek granularity if any), whether a tiny time nudge such as 0.1ms is actually meaningful or just rounded/decoder-limited noise, and whether `aerobeat-input-camera-tracking` could honestly offer a "smallest available time step" UX instead of exact frame stepping. Use real upstream/local docs and code paths where possible, distinguish what is proven versus assumed, and recommend the narrowest truthful next move.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`
- research artifacts only if needed

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-03-boxing-hand-bbox-straight-punch-detection.md`
- optional nondurable research notes/artifacts if needed

**Status:** ✅ Complete

**Results:** Research completed against the real owner stack plus upstream Godot 4.6.2/Theora evidence. Proven facts: the current shipped AeroBeat replay path is still the built-in Godot `.ogv` path surfaced through `REF-07`/`REF-08`, and the owner code only exposes/plays with seconds-based transport (`paused`, `stream_position`, `play`, `stop`, `is_playing`, position/duration snapshots). `REF-08` explicitly reports `transport_mode=approx_time_seek`, `can_step_forward=false`, `can_step_backward=false`, `can_seek_frame=false`, `frame_index=null`, `frame_count=null`, and refuses `step_frames()` / `seek_to_frame()` instead of faking success. `REF-01` / `REF-02` only forward that truth upward. Upstream Godot 4.6-stable source proves Theora seek now exists by time, but it is not frame-addressed: `VideoStreamPlaybackTheora::seek()` takes a float seconds target, computes `video_frame = int64_t(p_time / frame_duration)`, backtracks toward a prior keyframe window, then decodes forward until it passes the requested time. The same source keeps frame counters internal and does not expose a public frame index on `VideoStreamPlayer`; docs still only expose seconds-based `stream_position`, pause/play/stop, and note that `is_playing()` stays true while paused, `play()` does not unpause, and `stop()` resets position without making frame 0 the current displayed frame. Proven consequence: a 0.1 ms nudge is not a truthful stepping primitive here for visual replay, because visible seek behavior is bounded by decoded frame timing plus keyframe/backtracking behavior, not by arbitrary sub-millisecond caller precision. Additional important limit: the Aero vendor backend's `nominal_fps` / `frame_duration_sec` are only informational metadata derived from source `fps_hint`, not decoder-proven exact frame timing, so they are useful hints but not a trustworthy exact-step contract. Recommendation: do not market this backend as supporting a “smallest available time step” or next/previous frame fallback. The narrow truthful fallback, if Derrick still wants a manual nudge affordance, is to label it explicitly as an approximate time nudge (for example, “Jump by nominal frame time (approx)” or plain millisecond nudge) and only when an FPS hint exists, with copy that it may land on the same decoded frame or skip based on codec/keyframe behavior. Otherwise keep exact-step UI disabled for the current `.ogv` stack until a lower owner can prove exact frame-addressed transport.

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

**Status:** ⚠️ Partial

**What We Built:** Landed the cross-repo boxing hand-bbox straight-punch foundation across the vendor/tool/input stack, then iterated on proving-scene observability and ownership correctness. The current state includes: vendor hand bbox payload exposure, tool-layer normalized hand payload + bbox preview support, input-layer bbox straight-punch state-machine wiring, tracker-contract QA pass, visible proving-scene collider debug rings, input-owned proving-scene debug config, preview-space vs gameplay-space landmark separation, the upstream pose-side hand lock repair across occlusion/reacquire, and explicit parser guards against tab-indented boxing profile regressions. Late-session tracing narrowed the YAML-reset suspicion: Godot/editor load+play was proven read-only for the boxing YAMLs, and a controlled clean launch of the boxing proving scene did not re-dirty them. The remaining blockers are (1) the wider external workflow that can restore pre-existing dirty local YAML state around Derrick's real retest loop, and (2) the replay stack still lacking a truthful decoded-frame stepping primitive; the current paused step UI is only a timestamp-seek approximation and should be replaced in the owner video/camera-tracking layers.

**Reference Check:** `REF-01` / `REF-02` / `REF-03` implementation slices landed; `REF-05` / `REF-06` fixture-based straight-punch QA is still the outstanding truth gate. Task 10K closed the live `Hand tracking - disabled` seam by restoring the boxing profile path and adding a parser guard against tab-indented regressions. Tasks 10L–10N then proved that clean Godot load/play does not itself rewrite the boxing YAMLs; the unresolved blocker is reproducing and stopping the wider local workflow that reintroduces dirty tab-indented YAML before some retests.

**Commits:**
- `2357784` (`REF-03`) - Expose MediaPipe hand landmarks and bbox payloads
- `edd416a` (`REF-02`) - Add hand bbox preview and playback debug overlays
- `62c7d1b` (`REF-02`) - Preserve pose-side hand locks across reacquire
- `29ca851` (`REF-01`) - Fix boxing proving scene debug surfaces
- `5468857` (`REF-01`) - Separate preview and gameplay landmark spaces
- `9915421` (`REF-01`) - Promote proving scene debug toggles into config
- `2043b6a` (`REF-01`) - Fix proving scene bbox overlay wiring
- `f5ba8fc` (`REF-01`) - Remove proving profile picker and hide tuning exports
- `fdcd1d8` (`REF-01`) - modified testbed defaults
- `cb50ea7` (`REF-01`) - Fix boxing proving warning seam
- `3d5ce09` (`REF-01`) - Guard boxing profile YAML indentation
- `4e4bc9b` (`REF-01`) - Document boxing YAML writer trace

**Lessons Learned:** A new concrete root cause was discovered after the last trace wave: Godot editor interaction with these repo-owned YAML files is itself unsafe because merely opening them in the editor can normalize whitespace and corrupt tab/space structure. For this workstream, YAML edits should be treated as text-editor-outside-Godot only. The hardest bugs here were seam bugs, not detector-threshold bugs: Beads ownership had to stay in the owner repo, preview-space vs gameplay-space landmark coordinates needed to be split explicitly, and hand ownership had to preserve pose-side truth across reacquire instead of relying on stale anchor continuity. Late in the slice, the YAML-reset suspicion also turned out to be a workflow-state problem more than a scene-runtime problem: clean Godot load/play was reproducibly read-only, while external sync/restore steps can resurrect old dirty YAML. The remaining work should start from Derrick's exact retest workflow evidence instead of further speculative detector changes.

---

*Drafted on 2026-06-03*