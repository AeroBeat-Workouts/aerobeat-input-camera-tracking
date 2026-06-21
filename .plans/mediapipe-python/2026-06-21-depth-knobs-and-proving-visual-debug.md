# AeroBeat depth knobs and proving visual debug

**Date:** 2026-06-21
**Status:** In Progress
**Last Updated:** 2026-06-21 17:15 EDT
**Blocked Reason:** None
**Agent:** `pico`

---

## Goal

Add configurable depth-performance knobs and proving-scene depth/FPS visualization so Derrick can meaningfully evaluate real-time boxing depth on Chip and later mobile-minded targets.

---

## Overview

The current depth path is now playtest-ready and the cleanup plan is closed, which means the next useful seam is evaluation tooling and performance control. Derrick wants two things in parallel: first, knobs that let the threshold-backed punch families trade quality for performance, especially cadence and possibly effective resolution; second, much stronger proving-scene visibility so we can actually see what the depth system is doing while tuning.

The proving/debug side should make the depth system legible, not just technically present. That means a YAML-driven ability to show the depth texture as a thumbnail in the boxing proving scene, swap it with the normal preview on click for full-screen inspection, and render the actual depth sampling regions around the relevant landmarks while the depth view is active. It also means an optional FPS readout in the proving scene so performance and visual truth can be judged together during live testing on Chip.

The implementation bar is not just "draw something on screen." The knobs and debug surfaces need to stay architecture-clean, truthful, and useful for the threshold backend specifically. If we add a sample cadence knob, it should clearly affect when depth is recomputed versus reused. If we add a resolution/ROI-oriented knob, it must be explicit whether it changes the model input, the sampled output interpretation, or just the proving display. The proving YAML should remain the source of truth for whether these visual debug aids are enabled.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current proving-scene cleanup / latest closure state | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-21-boxing-proving-cleanup-and-warning-reduction.md` |
| `REF-02` | Boxing proving harness script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-03` | Proving harness tests | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` |
| `REF-04` | Boxing gesture threshold/depth config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-05` | Camera tracking provider seam | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/providers/camera_tracking_provider.gd` |
| `REF-06` | Depth runtime manager seam | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/depth/depth_runtime_manager.gd` |

---

## Tasks

### Task 1: Design depth performance knobs and proving-scene visual debug contract

**Bead ID:** `aerobeat-input-camera-tracking-5cdg`
**SubAgent:** `primary`
**Role:** `research`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Design the lowest-risk config and UI contract for: (a) threshold-backend depth cadence / quality knobs, including sample frequency and any feasible resolution-related control, and (b) boxing proving-scene depth debug visuals, including a YAML-gated depth thumbnail, preview/depth swap interaction, sampled depth-range overlays around landmarks, and optional FPS display. Be explicit about what belongs in gesture YAML versus proving YAML, what is runtime-truth versus display-only, and any mobile/performance caveats.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-21-depth-knobs-and-proving-visual-debug.md`

**Status:** ✅ Complete

**Results:** Recommended the lowest-risk split as follows.
- **Gesture YAML owns runtime truth** for threshold-family depth behavior because those fields change detector semantics. Keep the existing `depth.enabled`, `model.artifact_path`, ROI/window/threshold fields, and add `depth.evaluation.sample_every_n_frames` (default `1`) so runtime can skip fresh depth inference on intermediate frames and reuse the last good sample. Optionally add `depth.evaluation.max_sample_age_ms` (default `window_ms`) so reused depth fails closed once it is too old for the punch window.
- **Do not add a generic runtime resolution knob yet.** Current truth from `REF-05`/`REF-06` and the Python bridge is that the bridge ignores YAML `model_input_size`, runs at model-native shape, samples only shoulder+wrist point depths, and does not persist a usable debug depth map. Exposing a live "depth resolution" knob now would be misleading. If later needed, make future controls explicit as either `model.artifact_path` / model variant selection (real runtime perf/quality change) or `display_depth_map_downscale` (debug-only display cost), not a fake inference-size slider.
- **Proving YAML owns presentation/debug affordances only.** Add a `visuals.depth_debug` block to `boxing.testbed_debug.yaml` with booleans/settings such as `enabled`, `thumbnail_visible`, `swap_click_enabled`, `hover_hint_visible`, `sampling_regions_visible`, `fps_visible`, `thumbnail_corner`, `thumbnail_width_px`, and `thumbnail_margin_px`.
- **Recommended UI contract:** when `depth_debug.enabled && thumbnail_visible` and a current depth map exists, show a bottom-right depth thumbnail over the normal preview. If `hover_hint_visible`, hovering the thumbnail shows a subtle "Click to inspect depth" affordance. Clicking swaps the main view between preview and depth; clicking again swaps back. While the main view is depth and `sampling_regions_visible`, render truthful overlays for what runtime actually sampled. Today that means shoulder/torso and wrist sample points unless Task 2 also upgrades runtime sampling to true ROI/forearm-extended sampling; only then should Task 3 draw boxes/regions matching `wrist_roi_radius_px`, `wrist_to_elbow_extension_px`, and `torso_roi_radius_px`.
- **FPS contract:** optional proving-only display, labeled honestly as preview/debug cadence unless Task 2 also surfaces a dedicated depth-inference FPS or ms metric. Do not imply it is raw model FPS if it is really scene refresh or preview cadence.
- **Task 2 prerequisite truth:** current runtime returns `normalized_depth_map = None`, ignores ROI radius/extension fields during actual inference, and only uses them in config/debug text. Task 2 should first add sample cadence/reuse semantics plus retained runtime debug payload for latest normalized depth map, frame/depth-map sizes, and actual sample geometry metadata.
- **Task 3 dependency:** build the thumbnail/swap/overlay UI on the surfaced runtime debug state from Task 2, not on fabricated or duplicated sampling math in the proving harness.
- **Mobile/perf caveat:** cadence/reuse is the safest first knob because it directly reduces Python/model work without changing pose/hand cadence or detector thresholds. Debug thumbnail/FPS affordances are proving-only and should default off for low-end/mobile-minded targets; full-screen depth view plus per-frame texture upload/overlay work should stay YAML-gated and non-shipping.

### Task 2: Implement depth cadence/quality knobs for threshold-backed boxing families

**Bead ID:** `aerobeat-input-camera-tracking-cw5a`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-04`, `REF-05`, `REF-06`
**Prompt:** Implement the approved depth-performance knobs for threshold-backed boxing families. At minimum, support YAML-configurable depth cadence/sampling frequency; add a resolution-related knob only if it can be done truthfully and architecture-cleanly. Preserve current threshold behavior, debug truth, and playtest viability.

**Folders Created/Deleted/Modified:**
- `assets/`
- `src/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `assets/boxing.gesture_detection.yaml`
- `scripts/depth_runtime_infer.py`
- `src/depth/depth_python_runtime_bridge.gd`
- `src/depth/depth_runtime_manager.gd`
- `src/depth/depth_runtime_types.gd`
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/tests/unit/test_depth_runtime_manager.gd`

**Status:** ✅ Complete

**Results:** Landed truthful runtime depth cadence/reuse knobs for threshold-backed boxing families via gesture YAML `depth.evaluation.sample_every_n_frames` and `depth.evaluation.max_sample_age_ms`, with family window fallback wired through the detector request path. Fresh depth inference now only runs on scheduled eligible frames; intermediate frames reuse the last successful sample with `sample_source: cached_reuse`, and reused samples become unavailable with `cached_sample_expired` once they exceed `max_sample_age_ms`. Also surfaced retained runtime debug payload needed for Task 3 without faking data: `frame_size`, `depth_map_size`, `last_timing_ms`, cadence settings/ages, and truthful point-sample geometry metadata (`actual_geometry_kind: single_pixel_point`) for shoulder/wrist sampling. `normalized_depth_map` remains intentionally unsurfaced (`null`) in this slice because the current runtime still does not expose a real depth texture payload. Validation: `python3 -m py_compile scripts/depth_runtime_infer.py` plus `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_depth_runtime_manager.gd -gexit` passed 12/12, including real ONNX/OpenVINO preview inference and new cadence expiry coverage.

### Task 3: Implement proving-scene depth thumbnail, swap view, range overlays, and FPS display

**Bead ID:** `aerobeat-input-camera-tracking-mee3`
**SubAgent:** `primary`
**Role:** `coder`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`
**Prompt:** Implement the boxing proving-scene visual debug features behind YAML booleans/settings: depth-map thumbnail in the bottom-right of the preview, hover full-screen affordance, click-to-swap preview/depth view and back, visible depth sampling regions around relevant landmarks while depth view is active, and optional FPS display in the proving scene. Keep the depth texture/debug surfaces truthful to the runtime and do not break current proving behavior.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `assets/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/boxing_proving_harness.gd`
- `.testbed/scripts/depth_sample_debug_overlay.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `assets/boxing.testbed_debug.yaml`
- `.plans/mediapipe-python/2026-06-21-depth-knobs-and-proving-visual-debug.md`

**Status:** ✅ Complete

**Results:** Landed a truthful proving-only depth debug layer driven by `assets/boxing.testbed_debug.yaml` under `visuals.depth_debug`. The boxing proving harness now creates a bottom-right depth debug card/thumbnail area, a top-right white preview/depth-timing readout, and a dedicated overlay that draws runtime-reported sample points from `sample_metrics.sample_geometry.actual_samples`. Because Task 2 still surfaces `normalized_depth_map: null`, the default boxing experience honestly renders an unavailable-state card (`Depth texture unavailable / Using sampled debug state only`) plus live timing/cadence/frame/depth-map metadata instead of inventing a fake grayscale map. The harness also supports future truthful swap behavior: if the runtime ever provides a real `Texture2D`/`Image` depth map, clicking the thumbnail swaps the main preview to that texture and the card flips to show the preview thumbnail, with hover hint text gated by YAML. Validation for this slice was focused and passed: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=depth_debug -gexit` passed 2/2, covering truthful unavailable-state behavior and real-texture swap plumbing; `... -gunit_test_name=applies_boxing_testbed_debug_yaml -gexit` passed 1/1, proving the boxing testbed YAML now drives the new visual config. This intentionally stops short of drawing ROI/range boxes because runtime truth is still `actual_geometry_kind: single_pixel_point`; only the actual shoulder/wrist sample points are drawn.

### Task 4: QA performance knobs and proving visual debug

**Bead ID:** `aerobeat-input-camera-tracking-2o2h`
**SubAgent:** `primary`
**Role:** `qa`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`
**Prompt:** Independently verify that the new depth knobs and proving-scene visual debug features work as claimed, remain truthful, and are actually useful for evaluating performance/value on Chip. Confirm boxing threshold-depth behavior still works, the new YAML toggles apply correctly, and the debug visuals/FPS display do not introduce regressions.

**Folders Created/Deleted/Modified:**
- config / proving / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- config / proving / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

### Task 5: Audit final evaluation readiness for Chip playtesting and future mobile direction

**Bead ID:** `aerobeat-input-camera-tracking-f4z1`
**SubAgent:** `primary`
**Role:** `auditor`
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-06`
**Prompt:** Independently audit that the new depth knobs and proving-scene debug tools are truly landed, truthful, and sufficient to evaluate the depth system's real value/performance on Chip. Also record the truthful limits of the current desktop depth path relative to likely future mobile deployment.

**Folders Created/Deleted/Modified:**
- config / proving / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- config / proving / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Created on 2026-06-21*
