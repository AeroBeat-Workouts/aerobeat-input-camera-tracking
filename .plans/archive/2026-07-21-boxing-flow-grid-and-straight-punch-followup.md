# AeroBeat Input Camera Tracking - Boxing/Flow Grid and Straight-Punch Follow-up

**Date:** 2026-07-21  
**Status:** Complete  
**Last Updated:** 2026-07-21 22:55 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Fix the remaining boxing/flow proving-scene feedback so the calibration grid is sized/aligned truthfully and the left straight-punch inspector no longer reports disabled/tracking-lost state when threshold detection is configured and pose tracking is visibly active.

---

## Overview

This is a fresh follow-up seam in `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking` after the earlier proving-scene cleanup/calibration timing lane completed. Derrick manually synced and reran the boxing proving scene and confirmed calibration now completes, which means the replay-timing fix was directionally correct. But the new screenshots show two remaining truth problems.

First, the calibration grid is still wrong visually: it is not aligned to the actual left/right wrist width, and the cells are not square. That suggests the current grid rendering is still using an incorrect geometry basis or applying non-uniform scaling after calibration. This should be treated as a real grid-truth/rendering seam, not a cosmetic polish pass.

Second, the left straight-punch inspector remains self-contradictory. Derrick’s screenshot shows the YAML is clearly configured with `backend: threshold` for `straight_punch`, but the in-scene inspector still says `Tracking status - disabled` and `Current state - tracking_lost`. That means there is still a remaining state/publication or inspector-mapping bug in the boxing proving harness and/or substrate payload. Because the config surface does not appear disabled, the inspector should not be presenting disabled/no-source truth unless the runtime payload itself is wrong or the harness is reading the wrong field.

The plan keeps these as two explicit seams: (1) grid truth/geometry and (2) straight-punch inspector/runtime truth. We should audit both against the current runtime/config payload first, then land the fixes, then run QA and audit before closure.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Derrick’s latest screenshots showing the YAML threshold config and the contradictory Straight Punch L inspector output | `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/22/image-76e5b6cb.png`, `/home/derrick/.openclaw/workspace/.temp/nerve-uploads/2026/07/22/image-0cf65eb1.png` |
| `REF-02` | Just-completed proving-scene cleanup/calibration timing plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-21-boxing-flow-proving-followups.md` |
| `REF-03` | Current shared proving harness script | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-04` | Current boxing proving harness inspector/debug surface | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-05` | Current detector/calibration runtime payload source | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd` |
| `REF-06` | Current boxing proving scene | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn` |
| `REF-07` | Current boxing gesture config showing threshold backend truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |

---

## Tasks

### Task 1: Audit remaining grid-truth and straight-punch inspector contradictions

**Bead ID:** `aerobeat-input-camera-tracking-kmop`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, audit the remaining proving-scene issues after the prior cleanup lane. Confirm why the calibrated grid is still not aligned to wrist width and why its cells are not square, and confirm why Straight Punch L still reports `disabled` / `tracking_lost` despite `backend: threshold` in the boxing YAML and visible pose tracking in the scene. Determine whether the straight-punch issue is still a harness-mapping bug, a substrate payload bug, a config-bundle bug, or some combination. Update this plan with exact root causes, files/lines, and the narrowest truthful implementation order.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-07-21-boxing-flow-grid-and-straight-punch-followup.md`

**Status:** ✅ Complete

**Results:** Audit complete. Root causes are now narrowed precisely.

- **Validation used:** source audit plus targeted repo-local regression coverage. Ran:
  - `bd update aerobeat-input-camera-tracking-kmop --status in_progress --json`
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd,res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit`
  - Result: **119/119 tests passed**. This confirms the existing unit coverage still matches current source truth, but it does **not** automatically reproduce Derrick’s exact live visual complaint, so the findings below are source-truth conclusions backed by targeted tests.

- **Grid root-cause map:**
  1. **Wrong baseline fields / anchor basis** in `src/detectors/pose_detector_substrate.gd:674-717, 1954-1960`.
     - Calibration stores `nose_x` and a single averaged `wrist_span`, but it does **not** persist calibrated `left_wrist.x`, `right_wrist.x`, or a wrist midpoint.
     - Grid reconstruction then uses `left_boundary = nose_x - width/2`, so the grid is centered on the nose instead of the actual wrist pair. If the wrists are not perfectly symmetric around the nose during calibration, the overlay cannot align to the observed left/right wrist width.
  2. **Wrong geometry basis for total width** in `src/detectors/pose_detector_substrate.gd:677, 1944-1948`.
     - `wrist_span` is captured with `PoseMetrics.distance_2d(left_wrist, right_wrist)` and then reused as total grid width.
     - That includes vertical wrist offset, so the grid can become wider than the true horizontal wrist-to-wrist span Derrick expects.
  3. **Wrong square-cell assumption / render-space mismatch** in `src/detectors/pose_detector_substrate.gd:1944-1968` and `.testbed/scripts/flow_grid_overlay.gd:42-70`.
     - Runtime uses one scalar `cell_size` for both X and Y in normalized landmark space.
     - Overlay then maps those normalized coordinates through the preview presenter. Because `x` is width-normalized and `y` is height-normalized, equal normalized deltas are **not** equal on-screen pixels on a 16:9 source, so the cells render rectangular rather than square.
  4. **Scene/harness are only surfacing runtime grid truth, not introducing an extra distortion layer** (`.testbed/scripts/proving_harness.gd:2468-2480`, `.testbed/scenes/boxing_proving.tscn:141-153`).

- **Straight-punch contradiction root-cause map:**
  1. **This is not primarily a harness mapping bug.** The boxing inspector is already prepared to show pose-only truth when `hand_tracking_enabled == false` or `truthful_state` is present (`.testbed/scripts/boxing_proving_harness.gd:1743-1815`).
  2. `assets/boxing.gesture_detection.yaml` does truthfully configure `straight_punch.backend: threshold`.
  3. But `assets/boxing.camera_tracking.yaml:1-53` has `tracking.pose.enabled: true` and **no `tracking.hands` section at all**.
  4. `src/detectors/pose_detector_substrate.gd:1211-1218, 2892-2897` treats missing `tracking.hands.enabled` as **true** via `hands.get("enabled", true)`.
  5. That keeps straight-punch debug on the hand-tracking lane, so `_build_straight_punch_side_debug()` / related truthful-state helpers publish hand-tracking-oriented `tracking_state` / `state` instead of the pose-only fallback Derrick expects (`src/detectors/pose_detector_substrate.gd:930-970, 2508-2562, 2734-2760`).
  6. Net: the contradiction is a **config-bundle omission plus substrate fallback/path-selection bug**, not a boxing-scene-only display issue.

- **Narrow implementation order:**
  1. In calibration/runtime grid code, store calibrated horizontal wrist basis explicitly (`left_wrist_x`, `right_wrist_x`, wrist midpoint, and/or horizontal wrist width) instead of reconstructing width from `nose_x + wrist_span`.
  2. Split flow grid geometry into independent `cell_width` and `cell_height` (or an equivalent aspect-correct rect basis) so runtime math and overlay rendering share a truthful square-in-preview contract.
  3. Update grid debug payload/overlay consumers to render from that explicit rect basis rather than a single scalar `cell_size`.
  4. In boxing profile truth, make hand-vs-pose mode explicit by either declaring `tracking.hands.enabled: false` in `assets/boxing.camera_tracking.yaml` or changing the substrate fallback so omitted boxing hands do not silently opt into hand-tracking semantics.
  5. Leave the boxing harness mostly intact unless the runtime payload contract changes after the substrate fix.

- **Bottom line:**
  - Grid issue = **combination** of wrong baseline fields, wrong width basis, and wrong normalized-square/render-space assumption.
  - Straight-punch issue = **config-bundle omission + substrate fallback/disabled-path selection**, with the harness already able to display truthful pose-only fields once runtime reports the correct mode.

---

### Task 2: Fix calibration grid geometry/alignment truth

**Bead ID:** `aerobeat-input-camera-tracking-rmcr`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`, `REF-06`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, fix the remaining calibration grid-truth seam so the calibrated grid aligns to the intended left/right wrist width basis and renders square cells. Keep the fix truthful to the current calibration/runtime contract rather than applying arbitrary visual offsets. Update this plan with exact files changed, validation, and commit hash; commit/push to `main` by default when ready for QA.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `src/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `.testbed/scripts/flow_grid_overlay.gd`
- `.testbed/scripts/proving_harness.gd`
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `src/detectors/pose_detector_substrate.gd`
- `.plans/2026-07-21-boxing-flow-grid-and-straight-punch-followup.md`

**Status:** ✅ Complete

**Results:** Implemented the narrow grid-truth fix end-to-end.

- **Root cause addressed:** the runtime was centering the grid from `nose_x` and sizing width from a full 2D `wrist_span`, then using one normalized `cell_size` for both axes. That made the grid drift away from true wrist width when wrists were vertically offset and guaranteed non-square rendered cells on a 16:9 source.
- **Runtime fix:** `src/detectors/pose_detector_substrate.gd` now stores `left_wrist_x`, `right_wrist_x`, `wrist_midpoint_x`, and `horizontal_wrist_span` during calibration, derives grid width from the calibrated horizontal wrist basis, and publishes an explicit rect basis (`cell_width`, `cell_height`, width/height/boundaries) for runtime/debug consumers.
- **Overlay/debug fix:** `.testbed/scripts/flow_grid_overlay.gd` now draws from explicit width/height grid geometry instead of assuming a single square normalized `cell_size`. `.testbed/scripts/proving_harness.gd` now surfaces width x height cell truth in the grid summary text.
- **Coverage added/updated:**
  - `.testbed/tests/unit/test_pose_detector_substrate.gd` now verifies horizontal wrist-basis capture, rect-based cell quantization, and aspect-correct grid debug payloads.
  - `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` now verifies the shared overlay snapshot consumes `cell_width` / `cell_height` truth.
- **Validation:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=flow -gexit`
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid -gexit`
  - Result: **11 targeted tests passed** (`6/6` flow substrate + `5/5` grid/proving-harness).
- **Commit:** `b577be3` - `Fix flow calibration grid geometry basis`

---

### Task 3: Fix Straight Punch L disabled/tracking-lost truth mismatch

**Bead ID:** `aerobeat-input-camera-tracking-9c63`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-04`, `REF-05`, `REF-07`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, fix the remaining Straight Punch L inspector contradiction so the inspector no longer reports `Tracking status - disabled` and `Current state - tracking_lost` when the threshold backend is configured and runtime pose tracking is active. Prefer fixing the underlying runtime/debug payload or harness field mapping over surface-only wording changes. Update this plan with exact files changed, validation, and commit hash; commit/push to `main` by default when ready for QA.

**Folders Created/Deleted/Modified:**
- `.testbed/`
- `assets/`
- `src/`
- `.plans/`

**Files Created/Deleted/Modified:**
- `assets/boxing.camera_tracking.yaml`
- `src/detectors/pose_detector_substrate.gd`
- `.testbed/tests/unit/test_camera_tracking_config_profiles.gd`
- `.testbed/tests/unit/test_pose_detector_substrate.gd`
- `.plans/2026-07-21-boxing-flow-grid-and-straight-punch-followup.md`

**Status:** ✅ Complete

**Results:** Root cause matched the audit lane: the boxing tracker profile enabled pose but omitted `tracking.hands`, while the substrate fallback treated missing hands config as enabled and kept straight-punch debug on the hand-tracking lane. I made the shipped boxing tracker bundle truthful by explicitly setting `tracking.hands.enabled: false` in `assets/boxing.camera_tracking.yaml`, and I hardened `src/detectors/pose_detector_substrate.gd` so a boxing tracker document with pose enabled but no hands stanza still falls back to pose-only truth instead of fake hand-tracking-disabled/tracking-lost truth. Added explicit coverage for both seams: the canonical boxing profile bundle test now asserts hands are disabled, and a new substrate regression proves the missing-hands-config boxing path stays pose-only and emits `ready` from pose samples. Validation passed with `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd,res://tests/unit/test_pose_detector_substrate.gd -gexit` (85/85) plus `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_boxing_pose_only_hand_debug_line_uses_pose_fallback_truth -gexit` (1/1). Commit: `379c34d` - `Fix boxing straight-punch pose-only hand-tracking truth`. Caveat: this slice proves repo-local runtime/config/harness truth, but I did not do a fresh manual live/replay scene run here.

---

### Task 4: QA grid truth and straight-punch inspector truth

**Bead ID:** `aerobeat-input-camera-tracking-9ufh`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, independently verify that the calibrated grid now aligns to the intended wrist-width basis with square cells and that Straight Punch L no longer lies about disabled/tracking-lost status under the threshold backend configuration. Re-run the strongest repo-local validation available and be honest about any manual/live boundary.

**Folders Created/Deleted/Modified:**
- verification-only as needed

**Files Created/Deleted/Modified:**
- `.plans/2026-07-21-boxing-flow-grid-and-straight-punch-followup.md`

**Status:** ✅ Complete

**Results:** QA reran the strongest repo-local verification I could perform headlessly and the slice passed.

- **Bead claim:** `bd update aerobeat-input-camera-tracking-9ufh --status in_progress --json`
- **Commands run:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=flow -gexit`
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid -gexit`
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd,res://tests/unit/test_pose_detector_substrate.gd -gexit`
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_boxing_pose_only_hand_debug_line_uses_pose_fallback_truth -gexit`
- **Command results:**
  - Flow substrate slice: **6/6 passed** (`67` asserts)
  - Grid/proving-harness slice: **5/5 passed** (`84` asserts)
  - Config + substrate regression slice: **85/85 passed** (`1031` asserts)
  - Focused boxing pose-only proving-harness truth: **1/1 passed** (`9` asserts)
- **What this proves:**
  1. calibrated flow/grid truth now stores and consumes the left/right horizontal wrist basis rather than reconstructing from the old nose-centered scalar span path
  2. grid runtime/debug payload and overlay consumers now agree on explicit rect geometry (`cell_width` / `cell_height`) rather than fake scalar-cell geometry
  3. Straight Punch L pose-only truth remains active under the threshold backend instead of surfacing `disabled` / `tracking_lost` from the missing-hands path when pose tracking is live
  4. the shipped boxing bundle explicitly sets `tracking.hands.enabled: false`, and the substrate regression still covers the missing-hands fallback path so pose-only truth remains honest even if that stanza is omitted
  5. related proving-harness / substrate / config coverage did not regress in this lane
- **Caveat / boundary:** this QA pass was strong repo-local automated verification only. I did **not** perform a fresh interactive/live GUI proving-scene run against camera or replay in this lane, so visual live-scene confirmation still belongs to a manual served-scene pass if Derrick wants one.
- **QA verdict:** **PASS** for repo-local truth of the boxing grid-geometry and straight-punch inspector follow-up slice.

---

### Task 5: Audit final closure truth

**Bead ID:** `aerobeat-input-camera-tracking-6i92`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking`, independently audit the final state against Derrick’s screenshots and current repo truth. Confirm the fixes are truthful rather than presentational, confirm git/commit/push truth, and close only if the lane is genuinely done.

**Folders Created/Deleted/Modified:**
- audit-only as needed

**Files Created/Deleted/Modified:**
- `.plans/2026-07-21-boxing-flow-grid-and-straight-punch-followup.md`

**Status:** ✅ Complete

**Results:** Independent audit passed. The lane looks truthfully fixed, not cosmetically papered over.

- **Reference check against Derrick’s screenshots (`REF-01`):**
  - Screenshot 1 shows `straight_punch.backend: threshold` with pose-only timing fields, so the old inspector output claiming `Tracking status - disabled` / `source=none` was genuinely contradictory.
  - Screenshot 2 shows the exact contradiction on `Straight Punch L`: `Current state - tracking_lost` plus `Tracking status - disabled` despite the threshold config.
  - Current repo truth now matches the intended semantics: `assets/boxing.camera_tracking.yaml` explicitly sets `tracking.hands.enabled: false`, and `src/detectors/pose_detector_substrate.gd` now routes boxing straight-punch truth through pose-only behavior when hands are omitted/disabled instead of silently taking the hand-tracking-disabled lane.
- **Why this is a real fix, not a presentational-only change:**
  1. **Grid truth** changed in runtime calibration/storage and quantization (`REF-05`), not just UI text. The substrate now stores calibrated `left_wrist_x`, `right_wrist_x`, `wrist_midpoint_x`, and `horizontal_wrist_span`; grid width comes from the horizontal wrist basis instead of nose-centered 2D wrist distance; grid geometry is published as explicit `cell_width` + `cell_height` rect truth.
  2. **Grid rendering** changed in overlay consumption (`REF-03` / shared overlay path), so the proving overlay now draws from the rect payload instead of a fake single normalized square cell. That directly addresses Derrick’s reported wrist-width alignment and non-square-cell problem.
  3. **Straight-punch truth** changed in shipped config plus runtime branching (`REF-05`, `REF-07`), not just inspector wording. The boxing bundle now declares pose-only hands-disabled truth, and the substrate fallback no longer lies when the hands stanza is missing.
- **Independent validation rerun:**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=flow -gexit` → **6/6 passed**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=grid -gexit` → **5/5 passed**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_camera_tracking_config_profiles.gd,res://tests/unit/test_pose_detector_substrate.gd -gexit` → **85/85 passed**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=test_boxing_straight_punch_missing_hands_config_falls_back_to_pose_only_truth -gexit` → **1/1 passed**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=test_straight_punch_pose_only_debug_surfaces_truthful_tracking_state -gexit` → **1/1 passed**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=test_calibration_stores_horizontal_wrist_basis_for_flow_grid -gexit` → **1/1 passed**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_pose_detector_substrate.gd -gunit_test_name=test_flow_debug_surfaces_shared_grid_and_nose_wrist_truth -gexit` → **1/1 passed**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_boxing_pose_only_hand_debug_line_uses_pose_fallback_truth -gexit` → **1/1 passed**
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=test_proving_scenes_share_grid_truth_panel_and_preview_overlay -gexit` → **1/1 passed**
- **Git / commit / push truth:**
  - `git log` confirms the landed sequence on `main` / `origin/main`: `b577be3` (grid runtime/overlay fix), `31955ee` (plan update), `379c34d` (straight-punch truth fix), `b08960e` (plan update).
  - `git branch -r --contains <commit>` confirms all four commits are contained by `origin/main`.
  - Current dirt is limited to plan files (`.plans/2026-07-21-boxing-flow-grid-and-straight-punch-followup.md` from this audit and `.plans/2026-07-21-boxing-flow-proving-followups.md` already modified in the working tree); no uncommitted source/config/test drift was introduced by the audit run.
- **Verdict / closure reasoning:** the remaining defects Derrick reported are addressed at the runtime/config/overlay truth layers, the headless proving/config/substrate coverage agrees, QA already passed, and git/push state is real. This bead is ready to close.
- **Remaining caveat:** I did **not** independently perform a fresh interactive GUI/manual proving-scene run with live camera or replay in this audit pass. The strongest evidence here is repo-local source truth plus headless proving-harness/config/substrate verification. So the closure is strong for code/config/runtime truth, with manual visual reconfirmation still external to this audit pass.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Closed the boxing follow-up slice by fixing the flow grid’s runtime geometry basis and the straight-punch inspector/runtime truth path. The grid now derives from calibrated horizontal wrist geometry with explicit rect cell dimensions, and the boxing straight-punch path now truthfully reports pose-only threshold behavior instead of fake disabled/hand-source-none state.

**Reference Check:** `REF-01` contradiction resolved at runtime/config truth; `REF-03`, `REF-04`, and `REF-05` now agree on shared grid and straight-punch debug payload semantics; `REF-07` now explicitly encodes the boxing hands-disabled pose-only profile expected by Derrick’s screenshot.

**Commits:**
- `b577be3` - Fix flow calibration grid geometry basis
- `31955ee` - Update follow-up plan with grid fix results
- `379c34d` - Fix boxing straight-punch pose-only hand-tracking truth
- `b08960e` - Update straight-punch follow-up plan with landed commit hash

**Lessons Learned:** When proving-scene debug contradicts config, audit the runtime branch-selection inputs first. The real bug here was split across baseline geometry truth and omitted config/fallback semantics, not just the visible inspector text.

---

*Started on 2026-07-21*
