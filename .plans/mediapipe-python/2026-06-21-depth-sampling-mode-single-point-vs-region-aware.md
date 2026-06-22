# AeroBeat depth sampling mode: single-point vs region-aware

**Date:** 2026-06-21  
**Status:** In Progress  
**Last Updated:** 2026-06-22 08:31 EDT  
**Blocked Reason:** None.  
**Agent:** `pico`

---

## Goal

Add a truthful, switchable depth sampling mode so AeroBeat can compare the current single-point wrist/torso depth checks against a region-aware depth reasoning mode centered on the same landmarks.

---

## Overview

The current depth system is useful and honest, but its actual runtime geometry is still single-point sampling: it samples depth at specific wrist/torso landmark pixels and feeds that into threshold logic. Derrick wants the next session to explore a more robust mode that reasons about depth in landmark-centered regions instead of only one pixel, while preserving the ability to switch back to the current single-point path for direct A/B evaluation.

This means the next slice is not just a detector tweak. It touches runtime geometry truth, debug visualization truth, proving-scene evaluation flow, and probably performance tradeoffs. The design must avoid faking ROI behavior in the UI before the runtime really uses those regions, and it must make clear whether a region mode changes the actual depth sampling behavior, the aggregation rule over sampled pixels, or both. The most useful version will let Derrick compare modes on Chip using the same punch-family threshold backend, the same cadence knobs, and the same proving/debug surfaces.

The recommended architecture is to keep the existing contract truthful by naming the current behavior explicitly as `sampling_mode: single_point`, then add a second `sampling_mode: region_aware` path that still answers the same detector-level question (`wrist_closeness = torso_depth - wrist_depth`) but computes `wrist_depth` and `torso_depth` from declared landmark-centered regions instead of one pixel. The detector/runtime boundary should stay stable: detector code should continue consuming `wrist_closeness`, `wrist_depth`, `torso_depth`, cadence metadata, and `sample_geometry`; only the worker/runtime internals decide how those values were produced.

For the new mode, the lowest-risk design is not a generic ROI DSL. It is a tightly scoped `region_geometry` + `aggregation` contract under each punch family's existing `depth.evaluation` block, with mode-specific runtime-reported geometry metadata and unchanged threshold semantics. In other words: same family depth gates, same window scoring, same debug/proving surfaces, but a switchable sampling backend underneath. Debug visuals should continue to draw only the actual runtime-reported geometry; if the runtime still sampled points, draw points, and if it sampled regions, draw the actual region footprint/centers plus the aggregation method that produced the reported depths.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Depth knobs and proving visual debug archive | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/archive/2026-06-21-depth-knobs-and-proving-visual-debug.md` |
| `REF-02` | Depth texture proving archive | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/archive/2026-06-21-expose-depth-map-texture-in-proving.md` |
| `REF-03` | Generalized depth debug viewer archive | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/archive/2026-06-21-generalize-depth-debug-viewer.md` |
| `REF-04` | Boxing proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-05` | Reusable depth debug viewer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/depth_debug_viewer.gd` |
| `REF-06` | Boxing gesture depth config | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-07` | Depth runtime manager | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/depth/depth_runtime_manager.gd` |
| `REF-08` | Depth Python bridge | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/depth/depth_python_runtime_bridge.gd` |
| `REF-09` | Python depth inference worker | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/scripts/depth_runtime_infer.py` |
| `REF-10` | Pose detector substrate | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |

---

## Tasks

### Task 1: Design switchable depth sampling mode contract

**Bead ID:** `aerobeat-input-camera-tracking-64z1`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`  
**Prompt:** Design the lowest-risk truthful contract for switching between the current single-point depth sampling mode and a new region-aware wrist/torso mode. Specify config ownership, runtime geometry semantics, aggregation rules, how debug/proving visuals should represent each mode, and what performance risks/Chip caveats should be called out up front.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-21-depth-sampling-mode-single-point-vs-region-aware.md`

**Status:** ✅ Complete

**Results:** Research completed on 2026-06-22. Recommended lowest-risk contract:
- Preserve the detector-facing metric contract exactly: `wrist_closeness`, `wrist_depth`, `torso_depth`, cadence/timing fields, and `sample_geometry` remain the stable outputs consumed by `pose_detector_substrate.gd` and proving/debug UI. This avoids detector threshold rewrites while enabling true A/B between sampling modes.
- Add `depth.evaluation.sampling_mode` with exact values `single_point` and `region_aware`. `single_point` means the current truthful behavior: one sampled wrist pixel and one sampled torso pixel. `region_aware` means the runtime computes wrist/torso depths from declared landmark-centered regions and returns the aggregated values through the same fields.
- Keep config ownership inside each family's existing `depth.evaluation` block in `assets/boxing.gesture_detection.yaml`. Do not move this into global runtime config; families already own model/cadence/depth threshold behavior there. Suggested shape:
  - `sampling_mode: single_point | region_aware`
  - `region_geometry:`
    - `wrist_shape: extended_capsule`
    - `wrist_radius_px: <int>`
    - `wrist_extension_toward_elbow_px: <int>`
    - `torso_shape: center_box`
    - `torso_half_width_px: <int>`
    - `torso_half_height_px: <int>`
    - `torso_anchor: shoulder_midpoint | torso_midpoint`
  - `aggregation:`
    - `wrist_depth_stat: median`
    - `torso_depth_stat: median`
    - `trim_fraction: <0..0.49>`
    - `min_valid_samples: <int>`
- Geometry semantics: keep coordinates in resized frame/depth-map pixel space after the worker resizes normalized depth to frame size, because that is what the current worker/debug path already exposes. For `single_point`, runtime reports `actual_geometry_kind: single_pixel_point`. For `region_aware`, runtime should report `actual_geometry_kind: landmark_region`, the resolved region anchors, region footprints in depth-map pixels, sampled pixel count, valid pixel count, and the aggregation rule actually used. Use torso midpoint or shoulder midpoint as the torso anchor, but prefer a torso-centered box over a single shoulder point so the torso reference stays symmetric and more stable under arm motion.
- Aggregation rules: default to median or trimmed median-style behavior, not mean, because monocular depth maps are noisy at edges and along wrists/forearms. Suggested truthful fallback order: if `valid_samples >= min_valid_samples`, use configured stat; otherwise fall back to the mode's declared center sample and mark that fallback explicitly in `sample_geometry`/`sample_metrics` (for example `aggregation_fallback: center_point_due_to_sparse_region`). Do not silently return region mode while behaving like point mode.
- Debug/proving requirements by mode:
  - `single_point`: keep today's point markers and labels; optionally rename `shoulder` to `torso_reference` in surfaced metadata if coder can do so without churn, but not required for this slice.
  - `region_aware`: overlay the real wrist capsule/extended region and torso box, show anchor points, show sampled/valid counts, and show the active aggregation labels (`median`, trim %, fallback reason if any). Continue showing the real depth texture only when `request_runtime_texture` is enabled; never synthesize a region texture.
- Performance/Chip caveats: region mode increases Python-worker postprocess cost and per-frame JSON/debug payload size more than inference cost. Full depth inference dominates overall cost; region aggregation is smaller but still matters on Chip when cadence is `sample_every_n_frames: 1`, especially if runtime texture/debug overlays are enabled. Keep the first implementation CPU-cheap: pixel gather on the already resized depth map, no morphology, no segmentation, no contour search, and no per-pixel export back to Godot.
- Risks called out up front:
  - Current worker names the torso sample `shoulder` in `sample_geometry.actual_samples`, so coder should decide whether to preserve that wire name for compatibility or migrate to a more honest `torso_reference`/`torso_center` label with test updates in the same slice.
  - UI truth depends on runtime truth. The overlay script currently only knows marker points, so region-aware visualization needs new runtime geometry fields before the UI draws anything richer.
  - Existing threshold gates should not change their formulas in this bead; only the sampling source beneath them changes.
- Recommended implementation sequence:
  1. Coder: extend YAML schema + substrate request builder + worker/runtime result schema so both modes exist and runtime-reported geometry is explicit.
  2. Coder: implement region-aware sampling in `scripts/depth_runtime_infer.py` on the resized normalized depth map with median-based aggregation and explicit sparse/fallback reporting.
  3. Coder: update debug/proving overlay + tests so `single_point` draws markers and `region_aware` draws actual footprints/anchors/labels.
  4. QA: compare both modes with the same family thresholds/cadence, verify truthful metadata/visuals, and record whether Chip-side cadence needs relaxing for region mode.
  5. Auditor: verify no fake ROI claims remain, detector-facing metrics stayed stable, and fallback/performance caveats are surfaced honestly.

Concrete next seam for implementation:
- Task 2 should keep `wrist_closeness` and family threshold logic untouched while adding only mode/config/runtime geometry plumbing plus region aggregation.
- Task 3 should consume the runtime's new `sample_geometry` shape directly instead of inferring regions from config alone.

### Task 2: Implement switchable runtime sampling modes

**Bead ID:** `aerobeat-input-camera-tracking-qah2`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-06`, `REF-07`, `REF-08`, `REF-09`, `REF-10`  
**Prompt:** Implement the switchable runtime sampling mode contract: preserve current single-point behavior as one mode, add a truthful region-aware wrist/torso mode, surface the actual active sample geometry/aggregation metadata, and keep threshold behavior/debug truth intact.

**Folders Created/Deleted/Modified:**
- `assets/`
- `src/`
- `scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- config / runtime / detector / worker / tests / plan files touched by implementation

**Status:** ✅ Complete

**Results:** Completed on 2026-06-22. Added `depth.evaluation.sampling_mode` with exact runtime values `single_point` and `region_aware`, plus nested `region_geometry` and `aggregation` blocks in `assets/boxing.gesture_detection.yaml` for the boxing depth families. Kept detector-facing outputs and threshold/window scoring untouched: the worker still returns `wrist_closeness`, `wrist_depth`, `torso_depth`, timing, and `sample_geometry`, with `single_point` preserving the current center-point behavior. Implemented `region_aware` sampling on the resized normalized depth map in `scripts/depth_runtime_infer.py` using a wrist elbow-directed capsule and a torso-centered box, then surfaced explicit runtime metadata for `sampling_mode`, `region_anchors`, `actual_regions`, requested geometry, aggregation stats, and center-point fallback reasons. Preserved metadata truth through `src/depth/depth_runtime_manager.gd` normalization, exercised request/config plumbing via `test_pose_detector_substrate.gd`, and validated the runtime seam with `test_depth_runtime_manager.gd` plus Python syntax compilation.

### Task 3: Implement proving/debug visualization for active sampling mode

**Bead ID:** `aerobeat-input-camera-tracking-k5t0`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, `REF-07`, `REF-10`  
**Prompt:** Update the proving/debug viewer flow so it truthfully visualizes whichever sampling mode is active: point samples for single-point mode and actual landmark-centered region geometry for region-aware mode. Preserve depth texture, thumbnail/swap, and timing/debug behavior.

**Folders Created/Deleted/Modified:**
- `.testbed/scripts/`
- `.testbed/tests/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- proving/debug viewer / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Ready for implementation. Task 2 now supplies the concrete runtime seam the overlay should consume directly: `sample_metrics.sample_geometry.sampling_mode`, `region_anchors`, `actual_regions.wrist`, `actual_regions.torso`, and `aggregation` (including fallback flags/reasons). For `single_point`, draw only the runtime-reported point samples; for `region_aware`, draw the reported wrist capsule/extension endpoint and torso box from runtime metadata, plus sampled/valid counts and aggregation/fallback labels. Do not reconstruct geometry from config when runtime metadata is present.

### Task 4: QA single-point vs region-aware evaluation path

**Bead ID:** `aerobeat-input-camera-tracking-42rg`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-10`  
**Prompt:** Independently verify that both sampling modes work as claimed, that proving/debug visuals match real runtime behavior, and that the mode switch is useful for Chip-side A/B evaluation without introducing fake geometry or regressions.

**Folders Created/Deleted/Modified:**
- proving / runtime / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- proving / runtime / tests / plan files touched by implementation

**Status:** ⏳ Pending

**Results:** Pending.

### Task 5: Audit next-step readiness for Chip and future mobile-minded work

**Bead ID:** `aerobeat-input-camera-tracking-562g`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-09`, `REF-10`  
**Prompt:** Independently audit that the switchable sampling-mode work is truthful, useful for Chip comparison between single-point and region-aware depth reasoning, and honest about remaining mobile/performance caveats.

**Folders Created/Deleted/Modified:**
- proving / runtime / tests / plan files touched by implementation

**Files Created/Deleted/Modified:**
- proving / runtime / tests / plan files touched by implementation

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
