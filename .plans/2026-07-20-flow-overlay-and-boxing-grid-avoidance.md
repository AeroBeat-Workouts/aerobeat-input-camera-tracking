# AeroBeat Input Camera Tracking — Flow Overlay + Boxing Grid Avoidance Pivot

**Date:** 2026-07-20  
**Status:** In Progress  
**Last Updated:** 2026-07-20 09:13 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Align the proving scenes and runtime contract to the calibrated 4x3 grid direction by adding a visible Flow grid overlay locked to the calibration anchor, surfacing live nose/wrist occupancy + 8-way direction truth in the Flow test scene, removing stale Flow squat config/logic, and pivoting Boxing squat/weave avoidance toward the same calibrated nose-grid obstacle model.

---

## Overview

Derrick’s next slice stays in `aerobeat-input-camera-tracking`, but it is a new seam beyond the just-finished calibration work. Both proving scenes should now visibly demonstrate the calibrated 4x3 architecture instead of only implying it through event feeds and right-side boards. That means drawing the same thin-stroke 4x3 cell boundaries directly over the live/fixture video using the existing calibration anchor, while continuing to show the current pose anchors (`nose`, `wrist_left`, `wrist_right`) over the video. On the right side, the debug truth should become more athlete-readable in both scenes: separate `Nose`, `Left Wrist`, and `Right Wrist` sections that report current occupied cell plus the current 8-way word-based direction label instead of older clock-style language.

Flow remains the simpler expression of this direction: the right side primarily focuses on the nose/wrists occupancy + direction truth, and the overlay should make the calibrated 4x3 system directly visible during replay/live testing. There is also a contract cleanup seam inside the Flow profile/runtime: if Flow still carries `squat` as a live gameplay concept in config or runtime truth, that is now explicitly wrong and should be removed cleanly rather than preserved as legacy compatibility. Obstacle avoidance for Flow now belongs to the same calibrated grid vocabulary rather than a special squat gesture lane.

For Boxing, Derrick made two architectural decisions during this turn. First, squat and weave should pivot away from threshold-style gesture detection and become nose-grid avoidance gameplay under the same calibrated 4x3 system. A squat obstacle occupies the full top row (`0, 1, 2, 3`). A left-weave obstacle occupies the left-side columns; a right-weave obstacle occupies the right-side columns. This intentionally broadens “weave” success from a strict body-mechanics gesture to a more permissive “get the nose landmark out of the occupied region” model, allowing beginners to solve it by moving away while preserving the possibility for skilled athletes to express it as a faster true weave. Second, Boxing should also expose the same thin-stroke calibrated 4x3 overlay and the same nose/wrist occupancy UI even where Boxing does not yet use wrist-cell truth as a direct scoring contract. That shared UI is intentional test instrumentation: it gives Derrick a way to visually inspect how fists move through the calibrated cells while preserving the current gesture-based hook/uppercut path, which may inform a later wrist-cell-based improvement pass for hooks and uppercuts even though straight punches still need depth beyond the 4x3 grid.

Because this work mixes scene/UI truth, config cleanup, and gameplay-contract pivoting, execution should be staged carefully: first lock the exact seam map, then land the shared overlay/debug contract across both scenes, then remove stale Flow squat surfaces, then implement and validate the Boxing nose-grid avoidance pivot, followed by QA and audit.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Freshly landed shared calibration session plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md` |
| `REF-02` | Prior repo cleanup plan that aligned Flow/Boxing to the calibrated 4x3 direction | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/archive/2026-07-19-pose-threshold-grid-and-testbed-cleanup.md` |
| `REF-03` | Flow proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn` |
| `REF-04` | Shared proving harness driving Flow truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-05` | Boxing proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-06` | Shared runtime contract and calibration/grid truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-07` | Flow profile/config surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml` |
| `REF-08` | Public config contract notes mentioning current Flow/Boxing surfaces | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md` |
| `REF-09` | Memory note from the direct 4x3 boxing/grid decision thread | `/home/derrick/.openclaw/workspace/memory/2026-06-25-boxing-grid.md` |

---

## Tasks

### Task 1: Audit exact Flow/Boxing overlay + Flow squat + Boxing avoidance seams before implementation

**Bead ID:** `aerobeat-input-camera-tracking-6svd`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Audit the exact repo-owned seams for this pivot before implementation. Return a coder-ready hit list covering: (1) where the Flow video/preview overlay should render the calibrated 4x3 cell boundaries and which existing calibration anchor/runtime fields it should trust, (2) how current Flow right-side debug truth is surfaced and where to replace/add the `Nose` / `Left Wrist` / `Right Wrist` occupied-cell + 8-way direction sections, (3) all remaining Flow `squat` config/runtime/test/doc surfaces that must be removed cleanly with no legacy shim, and (4) all current Boxing squat/weave threshold-driven surfaces that must be retired or rewritten for the new nose-grid avoidance contract. Distinguish shared-runtime ownership vs proving-harness ownership vs scene-layout ownership.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`

**Status:** ✅ Complete

**Results:** Audit complete. Exact repo-owned seams are now locked for implementation.

**Coder-ready hit list**

1. **Overlay seam: render the same thin-stroke calibrated 4x3 boundaries in both proving scenes over the preview/video surface, not in a detached right-side chart.**
   - Existing overlay parent seam already exists in the shared proving harness preview path: `REF-04` mounts `_preview_presenter` in `_ensure_contract_preview_surface()` and reparents overlay drawers in `_sync_overlay_drawers_to_preview_presenter()`.
   - Existing live/replay overlay children already hang under each scene’s `CameraDisplay` via `LandmarkDrawer` in `REF-03` and the Boxing scene. The new grid overlay should join this same overlay family instead of inventing a separate rendering path.
   - For prerecorded/live preview parity, the new overlay drawer should follow the same preview-presenter contract used by `landmark_drawer.gd` / `depth_debug_viewer.gd`: if `get_overlay_layer()` exists, attach there; otherwise attach to the preview presenter/control that owns preview-space mapping.
   - Shared runtime truth to trust for grid math already lives in `REF-06`:
     - `baseline.nose_x` + `baseline.shoulder_center_y` are the current grid anchor source (`_build_flow_side_debug()`, `_flow_cell_index_from_position()`).
     - `baseline.wrist_span` drives `_get_flow_cell_size()`.
     - `FLOW_GRID_COLUMNS = 4`, `FLOW_GRID_ROWS = 3` are already canonical.
     - Current grid placement math is: `left_boundary = nose_x - cell_size * 2.0`, `top_boundary = shoulder_center_y + cell_size * 1.5`, then 4 columns x 3 rows.
   - Implementation note: the overlay drawer should not recompute alternate calibration math in scene code. It should consume shared runtime debug/baseline fields or a new shared helper returned from `pose_detector_substrate.gd` so Flow and Boxing stay identical.

2. **Current right-side Flow truth is chart-only; current right-side Boxing truth is tile/hover-card driven. Add the new Nose / Left Wrist / Right Wrist occupied-cell + 8-way direction sections there, not in a separate left-column-only summary.**
   - Flow right-side truth today:
     - `REF-03` right column is the `BoardPanel/BoardGrid` with four cards: `LeftPlacementChart`, `RightPlacementChart`, `LeftDirectionChart`, `RightDirectionChart`.
     - `REF-04` updates those cards through `_refresh_flow_ring_board()` using `gesture_debug.flow.left/right.current_cell/current_direction`.
     - Flow text truth also exists in `REF-04` under `_build_flow_signal_text()`, `_build_metrics_text()`, and `_build_summary_text()`, but the scene currently exposes the chart board as the visible right-side truth.
   - Boxing right-side truth today:
     - The Boxing scene only declares an empty `BoardGrid`; `REF-05` populates it dynamically via `_build_tile_grid_if_needed()` from `TILE_CONFIGS`.
     - Detailed truth is surfaced through hover cards / inspector bodies built by `_build_hover_card_model()`, `_build_guard_hover_card_model()`, `_build_squat_hover_card_model()`, `_build_weave_hover_card_model()`, plus left-column `QuickStats` text from the inherited proving harness.
   - Recommended seam for the new shared sections:
     - **Scene-layout ownership:** add a shared right-side occupancy panel slot to both scenes near the existing right-side board area. For Flow it should replace or sit above the current four-card wrist-only chart layout. For Boxing it should be inserted into `RightColumn` above the gesture tile board so punch/guard tiles remain intact.
     - **Proving-harness ownership:** build/update the actual section text/cards in shared harness code so both scenes consume the same formatting and labels.
     - **Shared-runtime ownership:** provide detector-owned current occupied cell + current 8-way direction for `nose`, `left_wrist`, and `right_wrist` so the proving harness does not derive gameplay truth ad hoc.
   - Direction wording note: current Flow chart labels in `flow_ring_chart.gd` are already word-based (`up`, `down`, `left`, `right`, `up-left`, etc.), so the new sections should reuse the same vocabulary instead of introducing clock terminology.

3. **Flow squat must be removed cleanly everywhere it still survives. No legacy shim.**
   - Config surfaces to delete/replace:
     - `REF-07` `assets/flow.gesture_detection.yaml` currently still defines `squat.backend: threshold` plus threshold values. Remove the `squat` family entirely.
   - Runtime surfaces to delete/replace in `REF-06`:
     - global squat defaults / helpers,
     - shared gesture state slot `states.squat` in `_reset_gesture_state()` if it is no longer part of shared public truth for active profiles,
     - `_build_gesture_debug_state()` entry for `squat`,
     - `_build_squat_debug_state()`,
     - `_process_squat()`,
     - `_get_squat_config()`,
     - and any recalibration reset path that explicitly preserves/zeros squat-only public truth as a first-class surface (`height_ratio`, `height_state`, `squat_depth`) when that truth only served the retired Flow squat contract.
   - Doc/test surfaces to delete/replace:
     - `REF-08` `docs/cross-repo-config-contract.md` currently says Flow is `flow.backend: threshold` with `stance/cell_transition/direction`, while the actual asset is still squat-based. This doc must be reconciled to the post-cleanup truth.
     - `test_pose_detector_substrate.gd`:
       - `test_squat_uses_yaml_thresholds_and_surfaces_debug_truth()`
       - `test_request_athlete_recalibration_clears_baseline_and_squat_truth_until_recalibrated()`
     - `test_boxing_proving_harness_profiles_and_debug.gd` fake provider/debug scaffolding currently injects a `gesture_debug.squat` branch in `FakeAthleteRecalibrateProvider.get_detector_state()`.
   - Important nuance: Flow still needs the shared athlete calibration baseline itself. Only the Flow squat gameplay/debug contract should be removed.

4. **Boxing squat/weave threshold-driven surfaces that must be retired or rewritten for nose-grid avoidance.**
   - Config surfaces in `assets/boxing.gesture_detection.yaml`:
     - `squat.threshold.thresholds.enter_height_ratio_max`
     - `squat.threshold.thresholds.exit_height_ratio_min`
     - `weave.threshold.thresholds.enter_head_lateral_offset_min`
     - `weave.threshold.thresholds.enter_relative_head_hip_offset_min`
     - `weave.threshold.thresholds.enter_head_drop_ratio_min`
     - `weave.threshold.thresholds.exit_head_lateral_offset_max`
     - `weave.threshold.thresholds.exit_relative_head_hip_offset_max`
     - These should be replaced by the new nose-grid avoidance contract, not left as hidden dead config.
   - Runtime surfaces in `REF-06` to rewrite:
     - `_process_squat()` currently toggles `states.squat` from torso-height ratio. Replace with nose occupancy vs top-row obstacle logic.
     - `_process_weave()` currently toggles `states.weave_left/right` from head/hip/drop thresholds. Replace with nose occupancy vs left-column/right-column obstacle logic.
     - `_build_squat_debug_state()` and `_build_weave_debug_state()` currently publish threshold-centric truth; replace with obstacle/cell occupancy truth.
     - measurement dependencies that only fed the retired Boxing squat/weave contract (`height_ratio`, `height_state`, `squat_depth`, `head_lateral_offset`, `hip_lateral_offset`, `head_drop_ratio`) may still exist if other debug uses need them, but they should stop being presented as Boxing squat/weave canonical truth.
   - Boxing proving harness / UI surfaces in `REF-05` to rewrite:
     - `TILE_CONFIGS` still includes `squat` and `weave` cards; those cards can remain, but their hover/inspector content must teach the new nose-grid avoidance truth instead of threshold truth.
     - `SQUAT_REQUIREMENT_ROWS` and `WEAVE_REQUIREMENT_ROWS` are fully threshold-era and must be replaced.
     - `_build_squat_hover_card_model()`, `_build_weave_hover_card_model()`, `_build_squat_requirement_row()`, `_build_weave_requirement_row()` must be rewritten around occupied cells / obstacle regions / nose location / release state.
     - `_build_boxing_signal_text()` and inherited metrics/summary surfaces currently print `squat depth`, `head drop`, `lateral body/head/hip` as body-state truth; these sections must pivot to nose cell occupancy / obstacle region truth for squat/weave while keeping punch/guard diagnostics.
   - Tests/docs to rewrite:
     - `test_pose_detector_substrate.gd` threshold-era squat/weave tests,
     - `test_camera_tracking_config_profiles.gd` boxing assertions that expect `squat.backend == threshold` and `weave.backend == threshold`,
     - `test_boxing_proving_harness_profiles_and_debug.gd` squat/weave hover-card assertions and fixture text that mention height-ratio or head-offset thresholds,
     - `docs/cross-repo-config-contract.md` Boxing schema section that still documents threshold squat/weave.

5. **Ownership boundary for implementation.**
   - **Shared-runtime ownership (`src/detectors/pose_detector_substrate.gd`):** canonical 4x3 grid geometry, canonical occupied-cell computation for `nose`, `left_wrist`, and `right_wrist`, canonical current 8-way direction computation for those tracked landmarks, canonical Boxing squat/weave obstacle-region evaluation using nose occupancy, and detector-owned public debug/state payloads.
   - **Proving-harness ownership (`.testbed/scripts/proving_harness.gd`, `.testbed/scripts/boxing_proving_harness.gd`, plus likely one new shared overlay drawer):** rendering the thin-stroke overlay from detector-owned geometry, formatting Nose / Left Wrist / Right Wrist occupied-cell + direction UI, retaining Boxing punch/guard-specific tiles, and shared word-label formatting.
   - **Scene-layout ownership (`.testbed/scenes/*.tscn`):** declaring where the overlay control and right-side occupancy panel live, with minimal layout/styling only and no duplicated detector math.

**Files inspected during the audit**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/flow_ring_chart.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_camera_tracking_config_profiles.gd`

**Modified files:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`

**Ambiguity / blockers:**
- No blocker for implementation.
- One implementation choice remains for the coder, but not a product ambiguity: whether the new shared right-side Nose / Left Wrist / Right Wrist truth is best represented as a new text/card panel or by expanding/replacing the existing Flow chart board cards. The product truth is clear either way; the important constraint is that both scenes expose the same occupancy/direction truth and Boxing keeps its existing punch/guard surfaces.

---

### Task 2: Land the shared calibrated 4x3 overlay-on-video and right-side occupancy/direction truth in both proving scenes

**Bead ID:** `aerobeat-input-camera-tracking-3auy`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Implement the proving-scene update so the calibrated 4x3 architecture becomes directly visible in both Flow and Boxing. Draw the same thin-stroke 4x3 grid overlay over the live/fixture video using the current shared calibration anchor/runtime truth, while continuing to show the pose-anchor overlay for nose and wrists. On the right side, add distinct `Nose`, `Left Wrist`, and `Right Wrist` sections that report current occupied cell and the current 8-way word-based direction label. Keep shared logic in the proving harness/runtime rather than scene-local duplication, and use the scenes mostly for layout/styling. Boxing should retain its punch/guard-specific debug surfaces in addition to the shared nose/wrist cell instrumentation. Update or add tests that prove the new overlay/debug surfaces are wired to shared truth.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/flow_grid_overlay.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`

**Status:** ✅ Complete

**Results:** Implemented one shared detector-to-harness seam for the calibrated 4x3 proving truth. `pose_detector_substrate.gd` now surfaces canonical grid geometry plus detector-owned `nose`, `left_wrist`, and `right_wrist` occupied-cell/direction state under `gesture_debug.flow`, while keeping the existing wrist flow event contract intact. `proving_harness.gd` now owns the shared overlay + right-side truth formatting, with a new `flow_grid_overlay.gd` drawer mounted through the preview presenter's overlay layer so both Flow and Boxing render the same thin-stroke calibrated 4x3 grid directly over video. `flow_proving.tscn` and `boxing_proving.tscn` now both expose the shared right-side `Nose` / `Left Wrist` / `Right Wrist` occupancy + 8-way direction panel, and Boxing keeps its existing punch/guard tile board underneath. Added proving/runtime tests covering the new shared runtime payload and the shared scene overlay/panel wiring. Validated with targeted GUT runs for `test_pose_detector_substrate.gd` and the new proving-harness scene test.

---

### Task 3: Remove stale Flow squat config/runtime/doc truth

**Bead ID:** `aerobeat-input-camera-tracking-emm4`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Remove Flow `squat` as a live contract surface anywhere it still survives in repo-owned config, runtime, tests, or docs. Do not preserve a legacy compatibility shim. Keep the resulting Flow contract truthful to the calibrated 4x3 cell model and update tests/docs accordingly.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml`
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md`
- related Flow tests/docs to be confirmed by Task 1
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Pivot Boxing squat/weave to calibrated nose-grid obstacle avoidance

**Bead ID:** `aerobeat-input-camera-tracking-u37t`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-05`, `REF-06`, `REF-08`, `REF-09`  
**Prompt:** Replace the current Boxing squat/weave canonical path with the newly approved calibrated nose-grid obstacle-avoidance model. Squat should resolve as the nose avoiding an obstacle occupying the full top row (`0,1,2,3`). Left weave should resolve as avoiding the left-side occupied columns; right weave should resolve as avoiding the right-side occupied columns. Keep the runtime/proving truth explicit that this is intentionally a permissive avoidance solution rather than a strictly enforced body-mechanics gesture. Retire threshold-style squat/weave canonical surfaces cleanly and update tests/debug/docs so the repo teaches the new truth.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- exact Boxing runtime/config/test/doc surfaces to be confirmed by Task 1
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml`
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd`
- likely `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/docs/cross-repo-config-contract.md`
- likely affected tests under `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: QA the Flow overlay + Flow cleanup + Boxing avoidance pivot

**Bead ID:** `aerobeat-input-camera-tracking-ko33`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Verify the landed Flow and Boxing changes at the highest-fidelity repo-local level available. Confirm the Flow video overlay locks to the calibration anchor, the nose/wrist occupancy + 8-way direction panels stay truthful, Flow no longer exposes squat as a live contract surface, and Boxing squat/weave now resolve via the calibrated nose-grid avoidance model rather than the retired threshold-gesture path. Use repo-local tests plus direct source/scene/config truth checks.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Audit the repo-visible truth after the pivot

**Bead ID:** `aerobeat-input-camera-tracking-wvko`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`, `REF-09`  
**Prompt:** Independently truth-check the repo after the Flow overlay and Boxing avoidance pivot lands. Verify the proving scene, runtime, config, tests, and docs all agree on the calibrated 4x3 direction, that Flow squat is gone as current truth, and that Boxing squat/weave are now explicitly nose-grid avoidance mechanics rather than retained threshold gestures. Close the audit only if the repo-visible truth really matches the new architecture.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`

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
