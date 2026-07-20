# AeroBeat Input Camera Tracking — FlowGridOverlay Warning + Plan Cleanliness Cleanup

**Date:** 2026-07-20  
**Status:** In Progress  
**Last Updated:** 2026-07-20 10:29 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Eliminate the pre-existing `FlowGridOverlay` harness-test orphan / leaked `CanvasItem` warning debt and cleanly commit the remaining dirty plan file(s) so the repo worktree is no longer left dirty by already-finished slices.

---

## Overview

Derrick explicitly asked for two cleanup actions after the completed overlay/boxing pivot slice: first, fix the remaining `FlowGridOverlay` harness-test leakage warnings; second, make sure the previously mentioned uncommitted plan file is committed and pushed so the workspace is not left dirty. This is a narrow cleanup lane in the same repo, not a new product feature seam.

The warning cleanup should stay honest and targeted. We already know the architecture/product slice passed, so the job here is not to re-litigate the design; it is to identify why the harness tests are leaving `FlowGridOverlay` orphan / leaked `CanvasItem` noise behind and fix the lifecycle/teardown seam without hiding real failures. In parallel, we should classify the remaining dirty plan-file edits, confirm they reflect legitimate completed work, and land them in clean commits rather than leaving persistent repo dirt.

Because this is repo hygiene with validation implications, it should still follow the standard research → coder → QA → audit loop, just on a smaller surface.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed overlay/boxing pivot plan with recorded warning debt | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md` |
| `REF-02` | Completed shared calibration plan that still has uncommitted local edits | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md` |
| `REF-03` | Shared proving harness mounting / refreshing FlowGridOverlay | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd` |
| `REF-04` | Shared FlowGridOverlay drawer | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/flow_grid_overlay.gd` |
| `REF-05` | Harness tests where warning debt currently appears | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` |

---

## Tasks

### Task 1: Audit the warning root cause and classify dirty plan edits

**Bead ID:** `aerobeat-input-camera-tracking-m1nh`  
**SubAgent:** `primary` (for `research`)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Audit the current `FlowGridOverlay` orphan / leaked `CanvasItem` warning seam in the proving-harness tests and classify the currently dirty plan-file edits. Identify the exact root cause of the warning, the narrowest truthful fix, and whether the dirty plan diffs are legitimate finished-work documentation that should be committed as-is or need final normalization first. Update this plan with exact findings.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-grid-overlay-warning-and-plan-cleanup.md`

**Status:** ✅ Complete

**Results:**
- Root cause is test-owned lifecycle debt, not a runtime/proving-contract logic bug. `res://scripts/proving_harness.gd` calls `_ensure_overlay_drawers_ready()` unconditionally during `_ready()`. In script-only harness tests created through `_new_harness()` / `_new_base_harness()` (`test_boxing_squat_hover_card_reports_grid_avoidance_truth`, `test_boxing_weave_hover_card_reports_grid_avoidance_truth`, `test_flow_proving_runtime_config_defaults_to_flow_profile_bundle`), there is no real scene `camera_display` and no mounted preview presenter overlay parent at ready time.
- In that state, `_ensure_overlay_drawers_ready()` still executes `FlowGridOverlayScript.new()` and names it `FlowGridOverlay`, but because `camera_display == null` it never parents the node. The resulting unattached `Control` survives as an orphan and produces the exact passing-test warning seen in GUT: `1 Orphans * [FlowGridOverlay:<Control...>(flow_grid_overlay.gd)]`, followed by leaked `CanvasItem` / resource warnings at process exit.
- Evidence: the warning reproduces on script-only harness tests, but not on proving-scene tests that instantiate `boxing_proving.tscn` / `flow_proving.tscn` and therefore provide a real overlay parent. Fresh run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=boxing_squat_hover_card_reports_grid_avoidance_truth -gexit` passed `1/1` but emitted the orphan. Fresh run: `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=proving_scenes_share_grid_truth_panel_and_preview_overlay -gexit` passed `1/1` with no orphan warning.
- Narrowest truthful fix for Task 2: change only `res://scripts/proving_harness.gd` so `FlowGridOverlay` is created lazily only when there is a valid parent surface (`camera_display` or a resolvable preview-presenter overlay parent). Do **not** add blanket warning suppression. Do **not** change `flow_grid_overlay.gd`; its draw/visibility logic is not the source of the leak. This preserves the real contract because runtime scenes still must supply a real parent, while script-only tests stop fabricating an unattached overlay node.
- Dirty plan diff classification:
  - `.plans/2026-07-20-shared-calibration-countdown-and-capture.md` is legitimate finished-work documentation and should be committed as-is. The diff truthfully promotes the plan to `Complete`, records QA/audit evidence, and names landed commits `dc5d10b` and `4c20ded`.
  - `.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md` is also legitimate finished-work documentation and should be committed as-is. The diff truthfully promotes the plan to `Complete`, records QA/audit evidence, and names landed commits `d422283`, `51ce670`, and `c0fba9d` while explicitly preserving the known follow-up warning debt.
- Exact coder-ready Task 2 file hit list:
  - required code fix: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
  - commit already-finished plan docs as-is: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`
  - keep updating this cleanup plan with coder/QA/audit results: `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-grid-overlay-warning-and-plan-cleanup.md`
- No blocker found for the coder. The seam is narrow and isolated.

---

### Task 2: Fix the FlowGridOverlay harness-test leakage and land the dirty plan updates

**Bead ID:** `aerobeat-input-camera-tracking-72ok`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Implement the narrowest truthful fix for the `FlowGridOverlay` harness-test orphan / leaked `CanvasItem` warning seam, preserving the real runtime/proving contract. Also normalize and commit any legitimate dirty plan-file updates that should have been landed already so the repo worktree returns clean. Update this plan with exact edits/results, run relevant validation, commit/push to `main`, and close the bead when complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/proving_harness.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-shared-calibration-countdown-and-capture.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-grid-overlay-warning-and-plan-cleanup.md`

**Status:** ✅ Complete

**Results:**
- Implemented the narrow fix only in `REF-03` (`.testbed/scripts/proving_harness.gd`). `_ensure_overlay_drawers_ready()` now resolves a real overlay parent first and only instantiates `FlowGridOverlay` when a valid parent exists. The overlay is now lazily parent-gated to either the preview-presenter overlay layer or `camera_display`, so script-only harness tests no longer fabricate an unattached `Control`.
- Preserved the truthful runtime/proving contract. Runtime/scene-backed harnesses still get the same shared overlay behavior once a real parent exists; the fix only removes the test-owned seam where `_ready()` previously created an orphan when `camera_display == null` and no preview overlay parent was mounted.
- Left `.testbed/scripts/flow_grid_overlay.gd` untouched as required; no global warning suppression or broader teardown hacks were added.
- Landed the two legitimate dirty plan files as-is: `REF-02` (`.plans/2026-07-20-shared-calibration-countdown-and-capture.md`) and `REF-01` (`.plans/2026-07-20-flow-overlay-and-boxing-grid-avoidance.md`).
- Validation evidence after the fix:
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=boxing_squat_hover_card_reports_grid_avoidance_truth -gexit` ✅ passed `1/1` with no `FlowGridOverlay` orphan / leaked `CanvasItem` warning.
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=boxing_weave_hover_card_reports_grid_avoidance_truth -gexit` ✅ passed `1/1` with no `FlowGridOverlay` orphan / leaked `CanvasItem` warning.
  - `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=flow_proving_runtime_config_defaults_to_flow_profile_bundle -gexit` ✅ passed `1/1` with no `FlowGridOverlay` orphan / leaked `CanvasItem` warning.
- One non-blocking validation note: an attempted single-command comma-joined `-gunit_test_name=` run executed zero tests because GUT treats that flag as one exact test name, so the proof rests on the three direct targeted runs above.

---

### Task 3: QA the warning cleanup and worktree cleanliness

**Bead ID:** `aerobeat-input-camera-tracking-8nyj`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Verify that the targeted harness tests no longer emit the `FlowGridOverlay` orphan / leaked `CanvasItem` warning and that the intended dirty plan-file updates are committed/pushed so the repo worktree is clean except for any explicitly documented unrelated dirt. Update this plan with exact QA evidence and close the bead when done.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-grid-overlay-warning-and-plan-cleanup.md`

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Audit the cleanup truth

**Bead ID:** `aerobeat-input-camera-tracking-zte4`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently truth-check that the FlowGridOverlay warning cleanup is real and that the repo is no longer dirty from the previously finished plan files. Close the audit only if the warning is actually gone for the targeted tests and the plan-file cleanup is landed truthfully.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/2026-07-20-flow-grid-overlay-warning-and-plan-cleanup.md`

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
