# AeroBeat boxing proving cleanup and warning reduction

**Date:** 2026-06-21  
**Status:** In Progress  
**Last Updated:** 2026-06-21 09:24 EDT  
**Blocked Reason:** None  
**Agent:** `pico`

---

## Goal

Reduce or eliminate the proving-scene resource-leak warnings, Godot UID warnings, and related workspace/repo cleanup noise so the boxing proving path is cleaner and easier to trust during playtesting.

---

## Overview

The threshold-depth punch-family path is now playtest-ready within the prior depth/runtime plan scope, but the latest QA/audit still reported pre-existing orphan/resource-leak warnings and Godot UID warnings during proving-harness runs. Derrick now wants that cleanup handled next.

This cleanup plan will treat three seams separately so we do not blur signal: (1) runtime/test-side resource leak and orphan warnings, (2) UID warning sources and whether they are harmless metadata churn or real asset/project hygiene issues, and (3) workspace/repo cleanup for unrelated dirty state and leftover artifacts that could confuse future validation. The implementation bar is not “silence every warning at any cost”; it is to make the proving-scene workflow materially cleaner while keeping the debug surfaces truthful and not destabilizing the validated depth path.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Prior depth runtime performance/integration plan | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.plans/mediapipe-python/2026-06-20-depth-runtime-performance-then-integration.md` |
| `REF-02` | Boxing proving harness | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scripts/boxing_proving_harness.gd` |
| `REF-03` | Proving/debug truth tests | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd` |
| `REF-04` | Shipped boxing gesture profile | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |

---

## Tasks

### Task 1: Diagnose proving warnings and workspace cleanup scope

**Bead ID:** `aerobeat-input-camera-tracking-fa9j`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`  
**Prompt:** Diagnose the current proving-harness orphan/resource-leak warnings, any Godot UID warnings, and the current repo/workspace dirty state that should be cleaned up for this playtest seam. Identify which warnings are in-scope, which are unrelated, likely root causes, and propose the lowest-risk cleanup order.

**Folders Created/Deleted/Modified:**
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.plans/mediapipe-python/2026-06-21-boxing-proving-cleanup-and-warning-reduction.md`

**Status:** ✅ Complete

**Results:** Diagnosed the current warning surface and separated real cleanup from noise. Evidence from the most recent clean passing proving-harness run (`.testbed/test-results/task62-qa-20260619/gut-proving-harness.log`) shows the stable warning classes are: (1) `37 orphans`, almost all `Control` instances rooted in `boxing_proving_harness.gd` / `proving_harness.gd`, plus one local `PlaybackStateHarness` with five child UI controls; (2) matching shutdown leaks: `37` leaked `CanvasItem` RIDs, `10` leaked dummy texture RIDs, `25` leaked shaped-text RIDs, `1` leaked font RID, `ObjectDB instances leaked at exit`, and `2 resources still in use at exit`; and (3) six GUT addon invalid-UID fallback warnings before tests run. The orphan/root-cause line is narrow and local to the test file in `REF-03`: helper `_new_harness()` returns `boxing_proving_harness.gd.new()` directly, many tests instantiate `ProvingHarnessScript.new()` directly, and `test_playback_step_buttons_only_enable_while_paused()` allocates `Button` / `HSlider` / `Label` nodes without `add_child_autoqfree()` or explicit `queue_free()`. Because `boxing_proving_harness.gd` / `proving_harness.gd` extend `Control`, those unfreed nodes explain the per-test orphan controls and line up with the leaked `CanvasItem` RID count. The UID warnings are real but not owned by this repo’s tracked source: the mounted addon `.testbed/addons/aerobeat-vendor-godot-unit-test` emits six `invalid UID ... using text path instead` warnings because scene files reference stale UID strings that do not match the current `.gd.uid` sidecars (`GutScene.tscn` expects `uid://bw7tukh738kw1` while `GutScene.gd.uid` currently contains `uid://dciujeqjafv4m`, with the same mismatch pattern for `gut_gui.gd`, `ResizeHandle.gd`, `RunExternally.gd`, and `GutRunner.gd`). Since `.testbed/addons/*` are ignored symlink mounts to sibling repos, this is out-of-scope for an owning-repo-only code fix and should be treated as external addon hygiene unless Derrick explicitly widens scope. Current repo dirty state relevant to this seam is small: the active plan file itself is untracked as expected, there is one unrelated modified plan (`.plans/mediapipe-python/2026-06-19-depth-model-research-note.md`), and there is one clearly in-scope stray root file `knee_left_repeat_04_take_01.mp4` that is actually a text fixture-capture log pointing at `.testbed/test-results/task62-qa-20260619/fixture-captures/knee_left/...`, not a real video asset. Lowest-risk cleanup order for Task 2: first fix the local test-owned node lifecycle in `REF-03` so the orphan/RID/resource warnings drop without touching runtime behavior; second remove or relocate the stray root-level fixture-capture log; third decide whether to leave the external GUT UID mismatch documented as out-of-scope or open a separate sibling-repo cleanup slice. Important current-state caveat: a fresh live rerun today of `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gexit` no longer reproduced the earlier clean `38/38` pass and instead hit a stack-overflow recursion between `boxing_proving_harness.gd`, `CameraTrackingPreviewPresenter.gd`, and `MediaPipePythonCameraTrackingBackend.gd`; because this repo’s tracked source is otherwise clean and `.testbed/addons/*` are live sibling mounts, treat that recursion as separate current environment/runtime drift, not as the original orphan/UID cleanup root cause.

### Task 2: Implement warning/cleanup fixes

**Bead ID:** `aerobeat-input-camera-tracking-hulm`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Implement the approved cleanup fixes for the proving-scene warnings and workspace hygiene. Preserve the validated threshold-depth boxing path, keep proving/debug truth intact, and prefer removing root causes over suppressing warnings.

**Folders Created/Deleted/Modified:**
- `.testbed/tests/unit/`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/knee_left/`
- `.plans/mediapipe-python/`

**Files Created/Deleted/Modified:**
- `.testbed/tests/unit/test_boxing_proving_harness_profiles_and_debug.gd`
- `.testbed/test-results/task62-qa-20260619/fixture-captures/knee_left/proving-session.log` (relocated from stray repo-root text artifact)
- `knee_left_repeat_04_take_01.mp4` (removed from repo root by relocation into fixture-capture results)
- `.plans/mediapipe-python/2026-06-21-boxing-proving-cleanup-and-warning-reduction.md`

**Status:** ✅ Complete

**Results:** Fixed the local test-owned lifecycle seam in `REF-03` without touching runtime boxing logic. `_new_harness()` now adds boxed harness instances through `add_child_autoqfree(...)`, and new helpers `_new_base_harness()` / `_new_playback_harness()` route previously direct `ProvingHarnessScript.new()` / `PlaybackStateHarness.new()` allocations through the same GUT-owned cleanup path. The playback-controls test now also registers its temporary `Button`, `HSlider`, and `Label` nodes with `add_child_autoqfree(...)` instead of leaking unattached `Control` instances. For repo hygiene, the stray root-level `knee_left_repeat_04_take_01.mp4` text log was relocated to `.testbed/test-results/task62-qa-20260619/fixture-captures/knee_left/proving-session.log`, removing the confusing fake-`.mp4` artifact from repo root while preserving the captured session note in the test-results area. Targeted validation on this machine passed for the touched seams: `test_proving_harness_runtime_tuning_fields_are_hidden_from_editor_surface`, `test_boxing_proving_runtime_config_loads_selected_flow_profile_bundle`, and `test_playback_step_buttons_only_enable_while_paused` all passed headless via GUT after the lifecycle fixes, with no local orphan/resource-leak summary emitted in those runs. A full-file rerun remains blocked by the previously diagnosed recursion/stack-overflow loop between `boxing_proving_harness.gd`, `CameraTrackingPreviewPresenter.gd`, and `MediaPipePythonCameraTrackingBackend.gd`; that blocker reproduced unchanged during this task and is documented as separate from the local leak cleanup seam. The out-of-scope sibling-addon UID warnings still appear at GUT startup and were intentionally not modified in this owning-repo pass.

### Task 3: QA cleanup fixes

**Bead ID:** `aerobeat-input-camera-tracking-9w7n`  
**SubAgent:** `primary`  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify that the cleanup fixes actually reduce or eliminate the proving warnings/UID issues in scope, that workspace/repo hygiene is improved, and that the boxing proving threshold-depth path still passes the relevant validation.

**Folders Created/Deleted/Modified:**
- runtime / proving / tests / repo hygiene files touched by implementation

**Files Created/Deleted/Modified:**
- runtime / proving / tests / project metadata / cleanup artifacts touched by implementation

**Status:** ✅ Complete

**Results:** Independently re-verified the cleanup seam with targeted headless GUT runs against `REF-03` on this machine: `test_proving_harness_runtime_tuning_fields_are_hidden_from_editor_surface`, `test_boxing_proving_runtime_config_loads_selected_flow_profile_bundle`, and `test_playback_step_buttons_only_enable_while_paused` each passed via `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gtest=res://tests/unit/test_boxing_proving_harness_profiles_and_debug.gd -gunit_test_name=... -gexit`. QA specifically re-checked the output for local leak markers (`orphans`, `ObjectDB instances leaked at exit`, `resources still in use at exit`, and generic `leaked` summaries) and none appeared in those targeted runs, which supports that the local test-owned node lifecycle cleanup in `REF-03` worked for the touched seams. Repo hygiene also improved as intended: the confusing root-level fake artifact `knee_left_repeat_04_take_01.mp4` is no longer present, while the relocated capture note exists at `.testbed/test-results/task62-qa-20260619/fixture-captures/knee_left/proving-session.log`. Remaining warnings are now clearly separable: the six invalid-UID startup warnings still come from the mounted sibling addon `res://addons/aerobeat-vendor-godot-unit-test/...` and remain out-of-scope for this owning-repo cleanup; the playback-controls targeted test still emits the existing truthful runtime warning `Replay start requested without a source path`, but the test passes and no longer leaks controls/resources; and a full-file rerun of `REF-03` is still not a reliable clean validation path here because a bounded 45s attempt never reached a GUT summary after entering the boxing proving path, so the known separate recursion/full-run blocker should remain tracked independently from this cleanup bead. On the evidence available, the validated boxing threshold-depth proving path remains intact for the targeted checks and Task 4 audit should proceed with the caveat that it should rely on targeted evidence plus truthful characterization of the still-outstanding addon UID noise and full-file-run blocker.

### Task 4: Audit cleanup fixes and playtest hygiene

**Bead ID:** `aerobeat-input-camera-tracking-07ml`  
**SubAgent:** `primary`  
**Role:** `auditor`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently audit that the proving-scene warning cleanup is real, that remaining warnings are truthfully characterized, that workspace hygiene is acceptable, and that the boxing proving setup remains playtest-ready after cleanup.

**Folders Created/Deleted/Modified:**
- runtime / proving / tests / repo hygiene files touched by implementation
- `.testbed/test-results/task4-audit-20260621/`

**Files Created/Deleted/Modified:**
- runtime / proving / tests / project metadata / cleanup artifacts touched by implementation
- `.testbed/test-results/task4-audit-20260621/tuning_fields.log`
- `.testbed/test-results/task4-audit-20260621/selected_flow_bundle.log`
- `.testbed/test-results/task4-audit-20260621/playback_step_buttons.log`
- `.testbed/test-results/task4-audit-20260621/full_file_bounded_45s.log`
- `.plans/mediapipe-python/2026-06-21-boxing-proving-cleanup-and-warning-reduction.md`

**Status:** ✅ Complete

**Results:** Independent audit passes for the narrow cleanup seam, with strict caveats preserved. I audited the actual code delta in `REF-03` and confirmed the fix is genuine local lifecycle cleanup rather than warning suppression: `_new_harness()` now routes `boxing_proving_harness.gd` instances through `add_child_autoqfree(...)`, new helpers `_new_base_harness()` / `_new_playback_harness()` do the same for direct `ProvingHarnessScript.new()` / `PlaybackStateHarness.new()` allocations, and the playback-controls test now registers its temporary `Button`, `HSlider`, and `Label` nodes plus step buttons with GUT-owned auto-free cleanup. Independent targeted validation reproduced the three claimed passes via headless GUT on this machine: `test_proving_harness_runtime_tuning_fields_are_hidden_from_editor_surface`, `test_boxing_proving_runtime_config_loads_selected_flow_profile_bundle`, and `test_playback_step_buttons_only_enable_while_paused`. I saved fresh audit logs under `.testbed/test-results/task4-audit-20260621/` and scanned them for the prior local leak markers (`orphans`, `ObjectDB instances leaked at exit`, `resources still in use at exit`, generic `leaked` summaries); none appeared in the targeted runs, which is strong evidence that the touched local leak seam is actually cleaned up. The playback-controls targeted test still truthfully emits `Replay start requested without a source path`, but it passes and no longer emits local orphan/resource-leak summaries, so that warning remains separate from the leak cleanup claim. Workspace hygiene also checks out: the confusing root-level fake artifact `knee_left_repeat_04_take_01.mp4` is absent, and the relocated capture note exists at `.testbed/test-results/task62-qa-20260619/fixture-captures/knee_left/proving-session.log` with the expected proving-session text content. Remaining warnings are only partially reproducible but are still truthfully bounded as follows: the six invalid-UID startup warnings are independently reproducible and clearly come from the mounted sibling addon `res://addons/aerobeat-vendor-godot-unit-test/...`, so they remain out-of-scope addon hygiene rather than an owning-repo cleanup miss; a bounded 45-second full-file rerun of `REF-03` again failed to reach a GUT summary, so full-file proving-harness validation remains non-viable as a clean truth source on this machine. I did not independently reproduce the previously reported recursion/stack-overflow trace during this audit pass, so the strongest truthful statement is narrower: the full-file path is still blocked/non-reliable here, and this cleanup plan should be called complete only for the targeted warning-reduction seam, not as a claim that the entire proving-harness file now reruns cleanly end-to-end. On that bounded evidence, the boxing threshold-depth proving setup remains playtest-ready for the validated targeted path after cleanup, and the cleanup plan can be marked complete as long as the still-noisy addon UID warnings and the separate full-file validation blocker stay explicitly documented.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Completed the proving-scene warning-cleanup seam for the boxing threshold-depth path without overstating the broader proving-harness state. Local test-owned lifecycle leaks in `REF-03` were genuinely cleaned up, the stray root fake-`.mp4` artifact was removed from repo root by relocation into test-results, targeted proving-harness validation still passes for the touched seams, and the remaining warning surface is now truthfully bounded to sibling-addon UID noise plus a separate full-file validation blocker.

**Reference Check:** `REF-02` and `REF-03` were satisfied for the scoped cleanup seam: the audited test-owned allocations now flow through GUT cleanup, targeted GUT passes still exercise the boxing proving/runtime-config and playback-control seams, and no local orphan/resource-leak summaries appeared in the fresh targeted audit logs. `REF-04` remains satisfied for the playtest-ready boxing path through the targeted runtime-config validation. Deliberate caveat: this plan does **not** claim that the entire `REF-03` file now reruns cleanly end-to-end; only the targeted cleanup seam is verified complete.

**Commits:**
- `10908b2` - Fix proving harness test cleanup leaks
- `3d0011f` - docs: record QA for boxing proving cleanup

**Lessons Learned:** For proving-harness cleanup work, targeted validation plus strict warning categorization is the trustworthy evidence path when the full-file run is not currently stable. Mounted sibling addons must be called out separately from owning-repo cleanup so we do not hide real progress behind external UID noise or over-claim end-to-end stability.

---

*Created on 2026-06-21*
